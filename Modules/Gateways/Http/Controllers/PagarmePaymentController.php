<?php

namespace Modules\Gateways\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Modules\Gateways\Entities\PaymentRequest;

class PagarmePaymentController extends Controller
{
    private function configValues(): array
    {
        $config = DB::table('addon_settings')
            ->where('key_name', 'pagarme')
            ->where('settings_type', 'payment_config')
            ->first();

        if (!$config) {
            return [null, null, []];
        }

        $mode = $config->mode === 'live' ? 'live' : 'test';
        $values = json_decode($mode === 'live' ? ($config->live_values ?: '{}') : ($config->test_values ?: '{}'), true);

        return [$config, $mode, is_array($values) ? $values : []];
    }

    private function onlyDigits($value): string
    {
        return preg_replace('/\D+/', '', (string) $value);
    }

    private function payerData(PaymentRequest $paymentData): array
    {
        $payer = json_decode($paymentData->payer_information ?: '{}', true);
        $payer = is_array($payer) ? $payer : [];

        $name = trim((string) (
            data_get($payer, 'name')
            ?: trim((string) data_get($payer, 'f_name') . ' ' . (string) data_get($payer, 'l_name'))
            ?: 'Cliente Fox GO'
        ));

        $email = (string) (
            data_get($payer, 'email')
            ?: 'contato@foxgodelivery.com.br'
        );

        $document = $this->onlyDigits(
            data_get($payer, 'document')
            ?: data_get($payer, 'cpf')
            ?: data_get($payer, 'cnpj')
            ?: ''
        );

        $phone = $this->onlyDigits(
            data_get($payer, 'phone')
            ?: data_get($payer, 'mobile')
            ?: ''
        );

        $customer = [
            'name' => $name,
            'email' => $email,
            'type' => strlen($document) === 14 ? 'company' : 'individual',
        ];

        if ($document !== '') {
            $customer['document'] = $document;
        }

        if (strlen($phone) >= 10) {
            $area = substr($phone, 0, 2);
            $number = substr($phone, 2);

            $customer['phones'] = [
                'mobile_phone' => [
                    'country_code' => '55',
                    'area_code' => $area,
                    'number' => $number,
                ],
            ];
        }

        return $customer;
    }

    private function documentFormHtml(PaymentRequest $paymentData, string $message = '')
    {
        $amount = number_format((float) $paymentData->payment_amount, 2, ',', '.');
        $paymentId = htmlspecialchars((string) $paymentData->id, ENT_QUOTES, 'UTF-8');
        $messageHtml = $message !== '' ? '<div class="alert">' . htmlspecialchars($message, ENT_QUOTES, 'UTF-8') . '</div>' : '';

        $html = '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">';
        $html .= '<title>Pix Fox GO</title>';
        $html .= '<style>
            body{font-family:Arial,sans-serif;background:#f7f7f7;margin:0;padding:24px;color:#222}
            .card{max-width:520px;margin:0 auto;background:#fff;border-radius:16px;padding:24px;box-shadow:0 8px 30px rgba(0,0,0,.08)}
            h1{font-size:22px;margin:0 0 8px}
            .brand{font-size:14px;color:#555;margin-bottom:16px}
            .amount{font-size:28px;font-weight:700;margin:12px 0 20px}
            label{display:block;font-size:14px;font-weight:700;margin:16px 0 8px}
            input{width:100%;box-sizing:border-box;border:1px solid #d8d8d8;border-radius:10px;padding:14px;font-size:16px}
            .hint{font-size:13px;color:#666;line-height:1.45;margin-top:10px}
            .alert{background:#fff3cd;border:1px solid #ffe69c;color:#664d03;border-radius:10px;padding:12px;font-size:14px;margin:14px 0}
            .btn{width:100%;border:0;background:#039b53;color:#fff;border-radius:10px;padding:15px;margin-top:18px;font-size:16px;font-weight:700;cursor:pointer}
        </style>';
        $html .= '</head><body><div class="card">';
        $html .= '<h1>Finalizar pagamento Pix</h1>';
        $html .= '<div class="brand">Fox GO</div>';
        $html .= '<div class="amount">R$ ' . $amount . '</div>';
        $html .= $messageHtml;
        $html .= '<form method="POST" action="/payment/pagarme/pay">';
        $html .= '<input type="hidden" name="payment_id" value="' . $paymentId . '">';
        $html .= '<label for="foxgo_document">CPF ou CNPJ do pagador</label>';
        $html .= '<input id="foxgo_document" name="foxgo_document" inputmode="numeric" autocomplete="off" placeholder="Digite somente números" required>';
        $html .= '<div class="hint">Precisamos desse documento para gerar o Pix com segurança. O pagamento continua dentro da Fox GO.</div>';
        $html .= '<button class="btn" type="submit">Continuar para o Pix</button>';
        $html .= '</form>';
        $html .= '</div></body></html>';

        return response($html, 200)->header('Content-Type', 'text/html; charset=UTF-8');
    }
    public function payment(Request $request)
    {
        $request->validate([
            'payment_id' => 'required|uuid',
        ]);

        [$config, $mode, $values] = $this->configValues();

        if (!$config || empty($values['secret_key'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Pagamento Pix indisponível no momento.',
            ], 422);
        }

        $foxgoTestSecret = (string) $request->query('foxgo_test_secret', '');
        $expectedTestSecret = (string) ($values['webhook_secret'] ?? '');
        $isInternalTest = $expectedTestSecret !== '' && $foxgoTestSecret !== '' && hash_equals($expectedTestSecret, $foxgoTestSecret);

        if ((int)($values['status'] ?? 0) !== 1 && !$isInternalTest) {
            return response()->json([
                'status' => 'error',
                'message' => 'Pagamento Pix ainda não está disponível.',
            ], 422);
        }

        $paymentData = PaymentRequest::where('id', $request->payment_id)
            ->where('is_paid', 0)
            ->first();

        if (!$paymentData) {
            return response()->json([
                'status' => 'error',
                'message' => 'Payment request não encontrada ou já paga.',
            ], 404);
        }

        // FOXGO_DOCUMENT_REQUIRED_BEGIN
        $payerRaw = json_decode($paymentData->payer_information ?: '{}', true);
        $payerRaw = is_array($payerRaw) ? $payerRaw : [];

        $currentDocument = $this->onlyDigits(
            data_get($payerRaw, 'document')
            ?: data_get($payerRaw, 'cpf')
            ?: data_get($payerRaw, 'cnpj')
            ?: ''
        );

        $submittedDocument = $this->onlyDigits($request->input('foxgo_document', ''));

        if ($currentDocument === '') {
            if ($submittedDocument === '') {
                return $this->documentFormHtml($paymentData);
            }

            if (!in_array(strlen($submittedDocument), [11, 14], true)) {
                return $this->documentFormHtml($paymentData, 'Informe um CPF com 11 dígitos ou CNPJ com 14 dígitos.');
            }

            $payerRaw['document'] = $submittedDocument;

            if (strlen($submittedDocument) === 11) {
                $payerRaw['cpf'] = $submittedDocument;
            } else {
                $payerRaw['cnpj'] = $submittedDocument;
            }

            DB::table('payment_requests')
                ->where('id', $paymentData->id)
                ->update([
                    'payer_information' => json_encode($payerRaw, JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES),
                    'transaction_id' => null,
                    'updated_at' => now(),
                ]);

            $paymentData = PaymentRequest::where('id', $paymentData->id)->first();
        }
        // FOXGO_DOCUMENT_REQUIRED_END
        $amountCents = (int) round(((float) $paymentData->payment_amount) * 100);

        if ($amountCents <= 0) {
            return response()->json([
                'status' => 'error',
                'message' => 'Valor inválido para Pix.',
            ], 422);
        }

        $code = 'foxgo_pr_' . str_replace('-', '', $paymentData->id);

        $payload = [
            'code' => $code,
            'closed' => true,
            'items' => [
                [
                    'amount' => $amountCents,
                    'description' => 'Pedido Fox GO',
                    'quantity' => 1,
                    'code' => 'foxgo_payment',
                ],
            ],
            'customer' => $this->payerData($paymentData),
            'payments' => [
                [
                    'payment_method' => 'pix',
                    'pix' => [
                        'expires_in' => 3600,
                    ],
                ],
            ],
            'metadata' => [
                'foxgo_payment_request_id' => $paymentData->id,
                'foxgo_gateway' => 'pagarme',
                'foxgo_mode' => $mode,
            ],
        ];

        $response = Http::withBasicAuth((string) $values['secret_key'], '')
            ->acceptJson()
            ->asJson()
            ->withHeaders([
                'Idempotency-Key' => 'foxgo-pagarme-' . $paymentData->id,
            ])
            ->post('https://api.pagar.me/core/v5/orders', $payload);

        $json = $response->json();

        if (!$response->successful()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Não foi possível gerar o Pix agora.',
                'http_status' => $response->status(),
                'pagarme_response' => $json ?: $response->body(),
            ], 422);
        }

        $orderId = data_get($json, 'id');
        $chargeId = data_get($json, 'charges.0.id');
        $qrCode = data_get($json, 'charges.0.last_transaction.qr_code');
        $qrCodeUrl = data_get($json, 'charges.0.last_transaction.qr_code_url');
        $expiresAt = data_get($json, 'charges.0.last_transaction.expires_at');

        DB::table('payment_requests')
            ->where('id', $paymentData->id)
            ->update([
                'transaction_id' => $chargeId ?: $orderId,
                'updated_at' => now(),
            ]);

        $safeQr = htmlspecialchars((string) $qrCode, ENT_QUOTES, 'UTF-8');
        $safeQrUrl = htmlspecialchars((string) $qrCodeUrl, ENT_QUOTES, 'UTF-8');
        $safeAmount = number_format($amountCents / 100, 2, ',', '.');
        $safePaymentId = htmlspecialchars((string) $paymentData->id, ENT_QUOTES, 'UTF-8');

        $html = '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">';
        $html .= '<title>Pix Fox GO</title>';
        $html .= '<style>body{font-family:Arial,sans-serif;background:#f7f7f7;margin:0;padding:24px;color:#222}.card{max-width:520px;margin:0 auto;background:#fff;border-radius:16px;padding:24px;box-shadow:0 8px 30px rgba(0,0,0,.08)}h1{font-size:22px;margin:0 0 12px}.amount{font-size:26px;font-weight:700;margin:12px 0}.qr{display:block;max-width:260px;width:100%;margin:18px auto}.copy{width:100%;min-height:120px;border:1px solid #ddd;border-radius:10px;padding:12px;font-size:14px}.info{font-size:14px;color:#555;line-height:1.5}.btn{display:block;text-align:center;background:#111;color:#fff;text-decoration:none;border-radius:10px;padding:14px;margin-top:16px}</style>';
        $html .= '</head><body><div class="card">';
        $html .= '<h1>Pagamento via Pix</h1>';
        $html .= '<div class="info">Fox GO</div>';
        $html .= '<div class="amount">R$ ' . $safeAmount . '</div>';

        if ($safeQrUrl !== '') {
            $html .= '<img class="qr" src="' . $safeQrUrl . '" alt="QR Code Pix">';
        }

        if ($safeQr !== '') {
            $html .= '<p class="info"><strong>Pix copia e cola:</strong></p>';
            $html .= '<textarea class="copy" readonly onclick="this.select()">' . $safeQr . '</textarea>';
        } else {
            $html .= '<p class="info">Pix criado, mas o QR Code não veio na resposta esperada. Tente novamente em instantes ou fale com o suporte Fox GO.</p>';
        }

        if ($expiresAt) {
            $html .= '<p class="info">Expira em: ' . htmlspecialchars((string) $expiresAt, ENT_QUOTES, 'UTF-8') . '</p>';
        }

        $html .= '<p id="foxgo-payment-status" class="info">Após o pagamento, a confirmação será feita automaticamente.</p>';
        $html .= '<script>
(function(){
    var paymentId = "' . $safePaymentId . '";
    var statusEl = document.getElementById("foxgo-payment-status");
    var attempts = 0;

    function setStatus(text) {
        if (statusEl) {
            statusEl.textContent = text;
        }
    }

    async function checkPaymentStatus() {
        attempts++;

        try {
            var response = await fetch("/payment/pagarme/status?payment_id=" + encodeURIComponent(paymentId), {
                headers: {"Accept": "application/json"},
                cache: "no-store"
            });

            if (!response.ok) {
                return;
            }

            var data = await response.json();

            if (data && data.paid === true) {
                setStatus("Pagamento confirmado. Voltando para a Fox GO...");
                setTimeout(function(){
                    window.location.href = data.redirect_url || "https://www.foxgodelivery.com.br";
                }, 1200);
                return;
            }

            if (attempts >= 2) {
                setStatus("Aguardando confirmação automática do pagamento...");
            }
        } catch (e) {
            if (attempts >= 3) {
                setStatus("Aguardando confirmação automática do pagamento...");
            }
        }

        setTimeout(checkPaymentStatus, 4000);
    }

    setTimeout(checkPaymentStatus, 3000);
})();
</script>';
        $html .= '<a class="btn" href="https://www.foxgodelivery.com.br">Voltar para Fox GO</a>';
        $html .= '</div></body></html>';

        return response($html, 200)->header('Content-Type', 'text/html; charset=UTF-8');
    }

    public function status(Request $request): JsonResponse
    {
        $paymentId = (string) $request->query('payment_id', '');

        if ($paymentId === '') {
            return response()->json([
                'paid' => false,
                'error' => 'payment_id_required',
            ], 422);
        }

        $paymentData = PaymentRequest::where('id', $paymentId)->first();

        if (!$paymentData) {
            return response()->json([
                'paid' => false,
                'error' => 'payment_not_found',
            ], 404);
        }

        if ((int) $paymentData->is_paid === 1) {
            return response()->json([
                'paid' => true,
                'redirect_url' => 'https://www.foxgodelivery.com.br',
            ], 200);
        }

        $transactionId = (string) $paymentData->transaction_id;

        if ($transactionId !== '' && str_starts_with($transactionId, 'ch_')) {
            [$config, $mode, $values] = $this->configValues();
            $secretKey = (string) ($values['secret_key'] ?? '');

            if ($secretKey !== '') {
                $response = Http::withBasicAuth($secretKey, '')
                    ->acceptJson()
                    ->timeout(20)
                    ->get("https://api.pagar.me/core/v5/charges/{$transactionId}");

                $json = $response->json();

                if ($response->successful() && data_get($json, 'status') === 'paid') {
                    DB::table('payment_requests')
                        ->where('id', $paymentData->id)
                        ->update([
                            'payment_method' => 'pagarme',
                            'is_paid' => 1,
                            'transaction_id' => $transactionId,
                            'updated_at' => now(),
                        ]);

                    $paymentData = PaymentRequest::where('id', $paymentData->id)->first();

                    if ($paymentData && function_exists($paymentData->success_hook)) {
                        call_user_func($paymentData->success_hook, $paymentData);
                    }

                    return response()->json([
                        'paid' => true,
                        'redirect_url' => 'https://www.foxgodelivery.com.br',
                    ], 200);
                }
            }
        }

        return response()->json([
            'paid' => false,
            'redirect_url' => 'https://www.foxgodelivery.com.br',
        ], 200);
    }
    public function webhook(Request $request): JsonResponse
    {
        $secret = (string) $request->query('secret', '');

        [$config, $mode, $values] = $this->configValues();

        if (!$config) {
            return response()->json([
                'received' => false,
                'gateway' => 'pagarme',
                'error' => 'pagarme_config_missing',
            ], 404);
        }

        $expectedSecret = (string) ($values['webhook_secret'] ?? '');

        if ($expectedSecret === '' || $secret === '' || !hash_equals($expectedSecret, $secret)) {
            return response()->json([
                'received' => false,
                'gateway' => 'pagarme',
                'error' => 'invalid_webhook_secret',
            ], 403);
        }

        $payload = $request->all();

        $eventType = data_get($payload, 'type')
            ?? data_get($payload, 'event')
            ?? data_get($payload, 'event_type')
            ?? 'unknown';

        $paymentId = data_get($payload, 'data.metadata.foxgo_payment_request_id')
            ?? data_get($payload, 'data.order.metadata.foxgo_payment_request_id')
            ?? data_get($payload, 'metadata.foxgo_payment_request_id');

        $orderCode = data_get($payload, 'data.code')
            ?? data_get($payload, 'data.order.code')
            ?? '';

        if (!$paymentId && is_string($orderCode) && str_starts_with($orderCode, 'foxgo_pr_')) {
            $compact = substr($orderCode, strlen('foxgo_pr_'));

            if (strlen($compact) === 32) {
                $paymentId = substr($compact, 0, 8) . '-' .
                    substr($compact, 8, 4) . '-' .
                    substr($compact, 12, 4) . '-' .
                    substr($compact, 16, 4) . '-' .
                    substr($compact, 20);
            }
        }

        $transactionId = data_get($payload, 'data.id')
            ?? data_get($payload, 'data.charge.id')
            ?? data_get($payload, 'data.charges.0.id')
            ?? data_get($payload, 'data.order.id')
            ?? null;

        $paidEvents = ['charge.paid', 'order.paid'];

        if ($paymentId && in_array($eventType, $paidEvents, true)) {
            $paymentData = PaymentRequest::where('id', $paymentId)->first();

            if ($paymentData && (int) $paymentData->is_paid === 0) {
                DB::table('payment_requests')
                    ->where('id', $paymentId)
                    ->update([
                        'payment_method' => 'pagarme',
                        'is_paid' => 1,
                        'transaction_id' => $transactionId ?: $paymentData->transaction_id,
                        'updated_at' => now(),
                    ]);

                $paymentData = PaymentRequest::where('id', $paymentId)->first();

                if ($paymentData && function_exists($paymentData->success_hook)) {
                    call_user_func($paymentData->success_hook, $paymentData);
                }
            }
        }

        return response()->json([
            'received' => true,
            'gateway' => 'pagarme',
            'mode' => $mode,
            'event' => $eventType,
            'payment_id' => $paymentId,
        ], 200);
    }
}