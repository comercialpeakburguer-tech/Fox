<?php

namespace App\CentralLogics;

use App\Models\Store;
use App\Models\Vendor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class FoxGoStripeConnectApiOnboardingLogic
{
    public static function syncAfterStoreCreated(Store $store, Request $request): Vendor
    {
        $vendor = Vendor::findOrFail($store->vendor_id);

        if (!empty($vendor->stripe_account_id)) {
            self::ensureExternalAccount($store);
            return self::refreshAccountStatus($store);
        }

        try {
            $config = self::getStripeConfig();
            $payload = self::buildAccountPayload($store, $vendor, $request);

            $response = Http::asForm()
                ->withBasicAuth($config['secret_key'], '')
                ->post('https://api.stripe.com/v1/accounts', $payload);

            $data = $response->json();

            if (!$response->successful() || empty($data['id'])) {
                $vendor->stripe_connect_status = 'api_onboarding_error';
                $vendor->stripe_requirements_due = json_encode([
                    'stripe_error' => $data['error']['message'] ?? $response->body(),
                ], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
                $vendor->save();

                info('FoxGoStripeConnectApiOnboarding: create account error vendor_id=' . $vendor->id . ' ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
                return $vendor;
            }

            $vendor->stripe_account_id = $data['id'];
            $vendor->stripe_connect_status = 'onboarding';
            $vendor->stripe_charges_enabled = !empty($data['charges_enabled']) ? 1 : 0;
            $vendor->stripe_payouts_enabled = !empty($data['payouts_enabled']) ? 1 : 0;
            $vendor->stripe_details_submitted = !empty($data['details_submitted']) ? 1 : 0;
            $vendor->stripe_requirements_due = json_encode($data['requirements']['currently_due'] ?? [], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
            $vendor->save();

            self::ensureExternalAccount($store);

            return self::refreshAccountStatus($store);
        } catch (\Throwable $e) {
            $vendor->stripe_connect_status = 'api_onboarding_error';
            $vendor->stripe_requirements_due = json_encode(['foxgo_error' => $e->getMessage()], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
            $vendor->save();

            info('FoxGoStripeConnectApiOnboarding: exception vendor_id=' . $vendor->id . ' erro=' . $e->getMessage());
            return $vendor;
        }
    }

    public static function refreshAccountStatus(Store $store): Vendor
    {
        $vendor = Vendor::findOrFail($store->vendor_id);

        if (empty($vendor->stripe_account_id)) {
            return $vendor;
        }

        $config = self::getStripeConfig();

        $response = Http::withBasicAuth($config['secret_key'], '')
            ->get('https://api.stripe.com/v1/accounts/' . $vendor->stripe_account_id);

        $data = $response->json();

        if (!$response->successful()) {
            return $vendor;
        }

        $due = $data['requirements']['currently_due'] ?? [];
        $errors = $data['requirements']['errors'] ?? [];

        $vendor->stripe_charges_enabled = !empty($data['charges_enabled']) ? 1 : 0;
        $vendor->stripe_payouts_enabled = !empty($data['payouts_enabled']) ? 1 : 0;
        $vendor->stripe_details_submitted = !empty($data['details_submitted']) ? 1 : 0;
        $vendor->stripe_requirements_due = json_encode($due, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
        $vendor->stripe_connect_status = ($vendor->stripe_charges_enabled && $vendor->stripe_payouts_enabled && $vendor->stripe_details_submitted && count($due) === 0 && count($errors) === 0) ? 'active' : 'onboarding';

        if ($vendor->stripe_connect_status === 'active' && empty($vendor->stripe_onboarding_completed_at)) {
            $vendor->stripe_onboarding_completed_at = now();
        }
        FoxGoStripeConnectStatusFormatter::applyToVendor($vendor, $data);

        $vendor->save();

        return $vendor;
    }

    private static function buildAccountPayload(Store $store, Vendor $vendor, Request $request): array
    {
        $fields = self::receivingFields($store);
        [$firstName, $lastName] = self::splitName(trim(($vendor->f_name ?? '') . ' ' . ($vendor->l_name ?? '')));

        $payload = [
            'type' => 'custom',
            'country' => 'BR',
            'business_type' => 'individual',
            'capabilities[card_payments][requested]' => 'true',
            'capabilities[transfers][requested]' => 'true',
            'email' => $vendor->email,
            'business_profile[name]' => $store->name,
            'business_profile[url]' => url('/'),
            'business_profile[product_description]' => 'Loja parceira cadastrada para vender pela plataforma Fox GO.',
            'business_profile[mcc]' => self::resolveMcc($store),
            'individual[first_name]' => $firstName,
            'individual[last_name]' => $lastName,
            'individual[email]' => $vendor->email ?: $store->email,
            'metadata[foxgo_vendor_id]' => (string) $vendor->id,
            'metadata[foxgo_store_id]' => (string) $store->id,
            'metadata[foxgo_source]' => 'api_onboarding_vendor_apply',
        ];

        $phone = self::normalizeBrazilPhone($vendor->phone ?: $store->phone);
        if ($phone) $payload['individual[phone]'] = $phone;

        $cpf = self::onlyDigits($fields['foxgo_representative_cpf'] ?? '');
        if (strlen($cpf) === 11) $payload['individual[id_number]'] = $cpf;

        $dob = self::dobParts($fields['foxgo_representative_birth_date'] ?? null);
        if ($dob) {
            $payload['individual[dob][day]'] = (string) $dob['day'];
            $payload['individual[dob][month]'] = (string) $dob['month'];
            $payload['individual[dob][year]'] = (string) $dob['year'];
        }

        if (!empty($fields['foxgo_representative_address_line1'])) $payload['individual[address][line1]'] = $fields['foxgo_representative_address_line1'];
        if (!empty($fields['foxgo_representative_address_city'])) $payload['individual[address][city]'] = $fields['foxgo_representative_address_city'];
        if (!empty($fields['foxgo_representative_address_state'])) $payload['individual[address][state]'] = strtoupper($fields['foxgo_representative_address_state']);
        if (!empty($fields['foxgo_representative_address_postal_code'])) $payload['individual[address][postal_code]'] = self::onlyDigits($fields['foxgo_representative_address_postal_code']);

        $payload['individual[political_exposure]'] = (($fields['foxgo_political_exposure'] ?? 'none') === 'existing') ? 'existing' : 'none';

        $monthlyRevenue = self::moneyToCents($fields['foxgo_monthly_estimated_revenue'] ?? null);
        if ($monthlyRevenue > 0) {
            $payload['business_profile[monthly_estimated_revenue][amount]'] = (string) $monthlyRevenue;
            $payload['business_profile[monthly_estimated_revenue][currency]'] = 'brl';
        }

        if (!empty($fields['foxgo_stripe_terms_accepted'])) {
            $payload['tos_acceptance[date]'] = (string) time();
            $payload['tos_acceptance[ip]'] = $request->ip();
            $payload['tos_acceptance[user_agent]'] = substr((string) $request->userAgent(), 0, 500);
        }

        return array_filter($payload, fn($v) => $v !== null && $v !== '');
    }


    // Fox GO - external account real BR live ready
    public static function ensureExternalAccount(Store $store): void
    {
        $vendor = Vendor::findOrFail($store->vendor_id);

        if (empty($vendor->stripe_account_id)) {
            return;
        }

        $config = self::getStripeConfig();

        $accountResponse = Http::withBasicAuth($config['secret_key'], '')
            ->get('https://api.stripe.com/v1/accounts/' . $vendor->stripe_account_id);

        $account = $accountResponse->json();
        $currentlyDue = $account['requirements']['currently_due'] ?? [];

        if ($accountResponse->successful() && !in_array('external_account', $currentlyDue, true)) {
            return;
        }

        $fields = self::receivingFields($store);

        $bankCode = str_pad(self::onlyDigits($fields['codigo_banco'] ?? ''), 3, '0', STR_PAD_LEFT);
        $branchCode = str_pad(self::onlyDigits($fields['agencia'] ?? ''), 4, '0', STR_PAD_LEFT);
        $accountNumber = self::onlyDigits(($fields['conta'] ?? '') . ($fields['digito'] ?? ''));
        $holderName = trim((string)($fields['titular'] ?? ''));
        $holderDocument = self::onlyDigits($fields['documento_titular'] ?? '');
        $holderType = strlen($holderDocument) === 14 ? 'company' : 'individual';

        if (strlen($bankCode) !== 3 || strlen($branchCode) !== 4 || strlen($accountNumber) < 3 || $holderName === '') {
            $vendor->stripe_connect_status = 'onboarding';
            $vendor->stripe_requirements_due = json_encode([
                'external_account',
                'foxgo_bank_data_missing_or_invalid'
            ], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
            $vendor->save();

            info('FoxGoStripeConnectApiOnboarding: dados bancarios insuficientes store_id=' . $store->id);
            return;
        }

        // Fox GO - em modo teste Stripe exige conta bancária de teste.
        // Mantemos os dados reais salvos no cadastro Fox GO, mas no sandbox enviamos 0001234 para a Stripe.
        // Em live, o número real da conta é enviado sem substituição.
        $stripeAccountNumber = $accountNumber;
        if (($config['mode'] ?? 'test') === 'test') {
            $stripeAccountNumber = '0001234';
        }

        $response = Http::asForm()
            ->withBasicAuth($config['secret_key'], '')
            ->post('https://api.stripe.com/v1/accounts/' . $vendor->stripe_account_id . '/external_accounts', [
                'external_account[object]' => 'bank_account',
                'external_account[country]' => 'BR',
                'external_account[currency]' => 'brl',
                'external_account[routing_number]' => $bankCode . $branchCode,
                'external_account[account_number]' => $stripeAccountNumber,
                'external_account[account_holder_name]' => $holderName,
                'external_account[account_holder_type]' => $holderType,
                'default_for_currency' => 'true',
                'metadata[foxgo_store_id]' => (string) $store->id,
                'metadata[foxgo_vendor_id]' => (string) $vendor->id,
            ]);

        $data = $response->json();

        if (!$response->successful()) {
            $vendor->stripe_connect_status = 'onboarding';
            $vendor->stripe_requirements_due = json_encode([
                'external_account',
                'stripe_error' => $data['error']['message'] ?? $response->body(),
            ], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
            $vendor->save();

            info('FoxGoStripeConnectApiOnboarding: erro external_account store_id=' . $store->id . ' ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
            return;
        }

        info('FoxGoStripeConnectApiOnboarding: external_account OK store_id=' . $store->id . ' external_id=' . ($data['id'] ?? 'null'));
    }


    // Fox GO - documento do responsável via Stripe Files API
    public static function ensureIdentityDocument(Store $store, ?Request $request = null): void
    {
        if (!$request) {
            return;
        }

        $vendor = Vendor::findOrFail($store->vendor_id);

        if (empty($vendor->stripe_account_id)) {
            return;
        }

        if (!$request->hasFile('foxgo_identity_document_front')) {
            return;
        }

        $config = self::getStripeConfig();

        $frontFileId = self::uploadIdentityDocumentFile(
            $vendor->stripe_account_id,
            $request->file('foxgo_identity_document_front'),
            $config['secret_key']
        );

        $payload = [
            'individual[verification][document][front]' => $frontFileId,
        ];

        if ($request->hasFile('foxgo_identity_document_back')) {
            $backFileId = self::uploadIdentityDocumentFile(
                $vendor->stripe_account_id,
                $request->file('foxgo_identity_document_back'),
                $config['secret_key']
            );

            if ($backFileId) {
                $payload['individual[verification][document][back]'] = $backFileId;
            }
        }

        $response = Http::asForm()
            ->withBasicAuth($config['secret_key'], '')
            ->post('https://api.stripe.com/v1/accounts/' . $vendor->stripe_account_id, $payload);

        $data = $response->json();

        if (!$response->successful()) {
            $vendor->stripe_connect_status = 'onboarding';
            $vendor->stripe_requirements_due = json_encode([
                'individual.verification.document',
                'stripe_error' => $data['error']['message'] ?? $response->body(),
            ], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
            $vendor->save();

            info('FoxGoStripeConnectApiOnboarding: erro identity_document store_id=' . $store->id . ' ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
            return;
        }

        self::saveReceivingField($store, [
            'foxgo_identity_document_uploaded' => 1,
            'foxgo_identity_document_uploaded_at' => now()->toDateTimeString(),
        ]);

        info('FoxGoStripeConnectApiOnboarding: identity_document OK store_id=' . $store->id);
    }

    private static function uploadIdentityDocumentFile(string $stripeAccountId, $uploadedFile, string $secretKey): ?string
    {
        if (!$uploadedFile) {
            return null;
        }

        $path = $uploadedFile->getRealPath();

        if (!$path || !is_file($path)) {
            throw new \RuntimeException('Arquivo de documento inválido.');
        }

        $handle = fopen($path, 'r');

        if (!$handle) {
            throw new \RuntimeException('Não foi possível abrir o arquivo de documento.');
        }

        try {
            $response = Http::withBasicAuth($secretKey, '')
                ->withHeaders([
                    'Stripe-Account' => $stripeAccountId,
                ])
                ->attach(
                    'file',
                    $handle,
                    $uploadedFile->getClientOriginalName() ?: 'documento-responsavel.' . $uploadedFile->getClientOriginalExtension()
                )
                ->post('https://files.stripe.com/v1/files', [
                    'purpose' => 'identity_document',
                ]);

            $data = $response->json();

            if (!$response->successful() || empty($data['id'])) {
                throw new \RuntimeException($data['error']['message'] ?? 'Falha ao enviar documento para Stripe.');
            }

            return $data['id'];
        } finally {
            if (is_resource($handle)) {
                fclose($handle);
            }
        }
    }

    private static function saveReceivingField(Store $store, array $newFields): void
    {
        $receiving = DB::table('disbursement_withdrawal_methods')
            ->where('store_id', $store->id)
            ->where('is_default', 1)
            ->latest('id')
            ->first();

        if (!$receiving) {
            return;
        }

        $fields = json_decode($receiving->method_fields ?: '{}', true);
        $fields = is_array($fields) ? $fields : [];
        $fields = array_merge($fields, $newFields);

        DB::table('disbursement_withdrawal_methods')
            ->where('id', $receiving->id)
            ->update([
                'method_fields' => json_encode($fields, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),
                'updated_at' => now(),
            ]);
    }

    private static function getStripeConfig(): array
    {
        $row = DB::table('addon_settings')->where('key_name', 'stripe')->first();
        if (!$row) throw new \RuntimeException('Configuração Stripe não encontrada.');

        $mode = $row->mode ?: 'test';
        $values = json_decode($mode === 'live' ? ($row->live_values ?: '{}') : ($row->test_values ?: '{}'), true);

        if (!is_array($values) || empty($values['api_key']) || empty($values['published_key'])) {
            $values = json_decode($row->test_values ?: '{}', true);
        }

        if (!is_array($values) || empty($values['api_key']) || empty($values['published_key'])) {
            throw new \RuntimeException('Chaves Stripe vazias ou inválidas.');
        }

        return [
            'mode' => $mode,
            'secret_key' => $values['api_key'],
            'published_key' => $values['published_key'],
        ];
    }

    private static function receivingFields(Store $store): array
    {
        $receiving = DB::table('disbursement_withdrawal_methods')
            ->where('store_id', $store->id)
            ->where('is_default', 1)
            ->latest('id')
            ->first();

        if (!$receiving || empty($receiving->method_fields)) return [];

        $decoded = json_decode($receiving->method_fields, true);
        return is_array($decoded) ? $decoded : [];
    }

    private static function resolveMcc(Store $store): string
    {
        $moduleType = strtolower((string) DB::table('modules')->where('id', $store->module_id)->value('module_type'));
        if (str_contains($moduleType, 'grocery')) return '5411';
        if (str_contains($moduleType, 'pharmacy')) return '5912';
        if (str_contains($moduleType, 'parcel')) return '4215';
        return '5812';
    }

    private static function onlyDigits(?string $value): string
    {
        return preg_replace('/\D+/', '', (string) $value);
    }

    private static function normalizeBrazilPhone(?string $value): ?string
    {
        $digits = self::onlyDigits($value);
        if (strlen($digits) === 10 || strlen($digits) === 11) return '+55' . $digits;
        if (str_starts_with($digits, '55') && (strlen($digits) === 12 || strlen($digits) === 13)) return '+' . $digits;
        return null;
    }

    private static function splitName(string $name): array
    {
        $name = trim(preg_replace('/\s+/', ' ', $name));
        if ($name === '') return ['Responsável', 'Fox GO'];
        $parts = explode(' ', $name);
        if (count($parts) === 1) return [$parts[0], $parts[0]];
        $first = array_shift($parts);
        return [$first, implode(' ', $parts) ?: $first];
    }

    private static function dobParts(?string $date): ?array
    {
        if (!$date) return null;
        try {
            $dt = new \DateTime($date);
            return ['day' => (int) $dt->format('d'), 'month' => (int) $dt->format('m'), 'year' => (int) $dt->format('Y')];
        } catch (\Throwable $e) {
            return null;
        }
    }

    private static function moneyToCents($value): int
    {
        if ($value === null || $value === '') return 0;
        $value = str_replace(['R$', ' ', '.'], '', (string) $value);
        $value = str_replace(',', '.', $value);
        return is_numeric($value) ? (int) round(((float) $value) * 100) : 0;
    }
}
