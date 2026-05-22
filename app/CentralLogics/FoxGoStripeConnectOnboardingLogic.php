<?php

namespace App\CentralLogics;

use App\Models\Store;
use App\Models\Vendor;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class FoxGoStripeConnectOnboardingLogic
{
    public static function getStripeConfig(): array
    {
        $row = DB::table('addon_settings')->where('key_name', 'stripe')->first();

        if (!$row) {
            throw new \RuntimeException('Configuração Stripe não encontrada.');
        }

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

    public static function ensureExpressAccountForStore(Store $store): Vendor
    {
        $vendor = Vendor::findOrFail($store->vendor_id);
        $config = self::getStripeConfig();

        if (empty($vendor->stripe_account_id)) {
            $payload = self::buildCreateAccountPayload($store, $vendor);

            $response = Http::asForm()
                ->withBasicAuth($config['secret_key'], '')
                ->post('https://api.stripe.com/v1/accounts', $payload);

            $data = $response->json();

            if (!$response->successful() || empty($data['id'])) {
                info('FoxGoStripeConnectOnboarding: create com prefill falhou; tentando create mínimo ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));

                $response = Http::asForm()
                    ->withBasicAuth($config['secret_key'], '')
                    ->post('https://api.stripe.com/v1/accounts', self::buildMinimalCreateAccountPayload($store, $vendor));

                $data = $response->json();
            }

            if (!$response->successful() || empty($data['id'])) {
                info('FoxGoStripeConnectOnboarding: erro ao criar conta Express ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
                throw new \RuntimeException('Não foi possível criar a conta de recebimento da loja.');
            }

            $vendor->stripe_account_id = $data['id'];
            $vendor->stripe_connect_status = 'onboarding';
            $vendor->stripe_charges_enabled = !empty($data['charges_enabled']) ? 1 : 0;
            $vendor->stripe_payouts_enabled = !empty($data['payouts_enabled']) ? 1 : 0;
            $vendor->stripe_details_submitted = !empty($data['details_submitted']) ? 1 : 0;
            $vendor->stripe_requirements_due = json_encode($data['requirements']['currently_due'] ?? [], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
            $vendor->save();
        }

        // Fox GO - prefill posterior é complementar. Nunca deve bloquear a abertura da verificação.
        try {
            self::prefillAccountFromStore($store);
        } catch (\Throwable $e) {
            info('FoxGoStripeConnectOnboarding: prefill complementar ignorado store_id=' . $store->id . ' erro=' . $e->getMessage());
        }

        return Vendor::findOrFail($store->vendor_id);
    }

    public static function createAccountSession(Store $store): array
    {
        $vendor = self::ensureExpressAccountForStore($store);
        $config = self::getStripeConfig();

        self::refreshAccountStatus($store);
        $vendor = Vendor::findOrFail($store->vendor_id);

        $response = Http::asForm()
            ->withBasicAuth($config['secret_key'], '')
            ->post('https://api.stripe.com/v1/account_sessions', [
                'account' => $vendor->stripe_account_id,
                'components[account_onboarding][enabled]' => 'true',
            ]);

        $data = $response->json();

        if (!$response->successful() || empty($data['client_secret'])) {
            info('FoxGoStripeConnectOnboarding: erro account_session vendor_id=' . $vendor->id . ' ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
            throw new \RuntimeException('Não foi possível iniciar a verificação de recebimento.');
        }

        return [
            'client_secret' => $data['client_secret'],
            'published_key' => $config['published_key'],
            'stripe_account_id' => $vendor->stripe_account_id,
        ];
    }

    public static function prefillAccountFromStore(Store $store): void
    {
        $vendor = Vendor::findOrFail($store->vendor_id);

        if (empty($vendor->stripe_account_id)) {
            return;
        }

        $config = self::getStripeConfig();

        $currentResponse = Http::withBasicAuth($config['secret_key'], '')
            ->get('https://api.stripe.com/v1/accounts/' . $vendor->stripe_account_id);

        $currentData = $currentResponse->json();

        if ($currentResponse->successful()) {
            $currentlyDue = $currentData['requirements']['currently_due'] ?? [];
            $errors = $currentData['requirements']['errors'] ?? [];

            if (
                !empty($currentData['charges_enabled']) &&
                !empty($currentData['payouts_enabled']) &&
                !empty($currentData['details_submitted']) &&
                count($currentlyDue) === 0 &&
                count($errors) === 0
            ) {
                return;
            }
        }

        $payload = self::buildPrefillPayload($store, $vendor);

        if (count($payload) === 0) {
            return;
        }

        $response = Http::asForm()
            ->withBasicAuth($config['secret_key'], '')
            ->post('https://api.stripe.com/v1/accounts/' . $vendor->stripe_account_id, $payload);

        $data = $response->json();

        if (!$response->successful()) {
            info('FoxGoStripeConnectOnboarding: erro prefill account vendor_id=' . $vendor->id . ' ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
            throw new \RuntimeException('Não foi possível pré-preencher a conta de recebimento.');
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
            info('FoxGoStripeConnectOnboarding: erro refresh account vendor_id=' . $vendor->id . ' ' . json_encode($data, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES));
            return $vendor;
        }

        $charges = !empty($data['charges_enabled']) ? 1 : 0;
        $payouts = !empty($data['payouts_enabled']) ? 1 : 0;
        $details = !empty($data['details_submitted']) ? 1 : 0;
        $due = $data['requirements']['currently_due'] ?? [];

        $vendor->stripe_charges_enabled = $charges;
        $vendor->stripe_payouts_enabled = $payouts;
        $vendor->stripe_details_submitted = $details;
        $vendor->stripe_requirements_due = json_encode($due, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
        $vendor->stripe_connect_status = ($charges && $payouts && $details && count($due) === 0) ? 'active' : 'onboarding';

        if ($vendor->stripe_connect_status === 'active' && empty($vendor->stripe_onboarding_completed_at)) {
            $vendor->stripe_onboarding_completed_at = now();
        }
        FoxGoStripeConnectStatusFormatter::applyToVendor($vendor, $data);

        $vendor->save();

        return $vendor;
    }

    private static function buildMinimalCreateAccountPayload(Store $store, Vendor $vendor): array
    {
        return [
            'type' => 'express',
            'country' => 'BR',
            'business_type' => 'individual',
            'capabilities[card_payments][requested]' => 'true',
            'capabilities[transfers][requested]' => 'true',
            'email' => $vendor->email,
            'business_profile[name]' => $store->name,
            'business_profile[url]' => url('/'),
            'business_profile[product_description]' => 'Loja parceira cadastrada para vender pela plataforma Fox GO.',
            'business_profile[mcc]' => self::resolveMcc($store),
            'metadata[foxgo_vendor_id]' => (string) $vendor->id,
            'metadata[foxgo_store_id]' => (string) $store->id,
            'metadata[foxgo_source]' => 'vendor_apply',
        ];
    }

    private static function buildCreateAccountPayload(Store $store, Vendor $vendor): array
    {
        return array_merge(
            self::buildMinimalCreateAccountPayload($store, $vendor),
            self::buildPrefillPayload($store, $vendor)
        );
    }

    private static function buildPrefillPayload(Store $store, Vendor $vendor): array
    {
        $fields = self::receivingFields($store);
        [$firstName, $lastName] = self::splitName(trim(($vendor->f_name ?? '') . ' ' . ($vendor->l_name ?? '')));

        $cpf = self::onlyDigits($fields['foxgo_representative_cpf'] ?? '');
        $dob = self::dobParts($fields['foxgo_representative_birth_date'] ?? null);
        $phone = self::normalizeBrazilPhone($vendor->phone ?: $store->phone);

        $payload = [
            'individual[first_name]' => $firstName,
            'individual[last_name]' => $lastName,
            'individual[email]' => $vendor->email ?: $store->email,
            'business_profile[mcc]' => self::resolveMcc($store),
            'metadata[foxgo_prefill_version]' => '20260510_2',
        ];

        if ($phone) {
            $payload['individual[phone]'] = $phone;
        }

        if (strlen($cpf) === 11) {
            $payload['individual[id_number]'] = $cpf;
        }

        if ($dob) {
            $payload['individual[dob][day]'] = (string) $dob['day'];
            $payload['individual[dob][month]'] = (string) $dob['month'];
            $payload['individual[dob][year]'] = (string) $dob['year'];
        }

        if (!empty($fields['foxgo_representative_address_line1'])) {
            $payload['individual[address][line1]'] = $fields['foxgo_representative_address_line1'];
        }

        if (!empty($fields['foxgo_representative_address_city'])) {
            $payload['individual[address][city]'] = $fields['foxgo_representative_address_city'];
        }

        if (!empty($fields['foxgo_representative_address_state'])) {
            $payload['individual[address][state]'] = strtoupper($fields['foxgo_representative_address_state']);
        }

        if (!empty($fields['foxgo_representative_address_postal_code'])) {
            $payload['individual[address][postal_code]'] = self::onlyDigits($fields['foxgo_representative_address_postal_code']);
        }

        if (!empty($fields['foxgo_political_exposure_none'])) {
            $payload['individual[political_exposure]'] = 'none';
        }

        $monthlyRevenue = self::moneyToCents($fields['foxgo_monthly_estimated_revenue'] ?? null);
        if ($monthlyRevenue > 0) {
            $payload['business_profile[monthly_estimated_revenue][amount]'] = (string) $monthlyRevenue;
            $payload['business_profile[monthly_estimated_revenue][currency]'] = 'brl';
        }

        return array_filter($payload, function ($value) {
            return $value !== null && $value !== '';
        });
    }

    private static function receivingFields(Store $store): array
    {
        $receiving = DB::table('disbursement_withdrawal_methods')
            ->where('store_id', $store->id)
            ->where('is_default', 1)
            ->latest('id')
            ->first();

        if (!$receiving || empty($receiving->method_fields)) {
            return [];
        }

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

        if (strlen($digits) === 10 || strlen($digits) === 11) {
            return '+55' . $digits;
        }

        if (str_starts_with($digits, '55') && (strlen($digits) === 12 || strlen($digits) === 13)) {
            return '+' . $digits;
        }

        return null;
    }

    private static function splitName(string $name): array
    {
        $name = trim(preg_replace('/\s+/', ' ', $name));

        if ($name === '') {
            return ['Responsável', 'Fox GO'];
        }

        $parts = explode(' ', $name);

        if (count($parts) === 1) {
            return [$parts[0], $parts[0]];
        }

        $first = array_shift($parts);
        $last = implode(' ', $parts);

        return [$first, $last ?: $first];
    }

    private static function dobParts(?string $date): ?array
    {
        if (!$date) {
            return null;
        }

        try {
            $dt = new \DateTime($date);

            return [
                'day' => (int) $dt->format('d'),
                'month' => (int) $dt->format('m'),
                'year' => (int) $dt->format('Y'),
            ];
        } catch (\Throwable $e) {
            return null;
        }
    }

    private static function moneyToCents($value): int
    {
        if ($value === null || $value === '') {
            return 0;
        }

        $value = str_replace(['R$', ' ', '.'], '', (string) $value);
        $value = str_replace(',', '.', $value);

        if (!is_numeric($value)) {
            return 0;
        }

        return (int) round(((float) $value) * 100);
    }
}
