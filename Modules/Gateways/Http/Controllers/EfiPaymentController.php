<?php

namespace Modules\Gateways\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;
use Modules\Gateways\Entities\PaymentRequest;

class EfiPaymentController extends Controller
{
    private function configValues(Request $request): array
    {
        $config = DB::table('addon_settings')
            ->where('key_name', 'efi')
            ->where('settings_type', 'payment_config')
            ->first();

        if (!$config) {
            return [null, 'test', []];
        }

        $live = json_decode($config->live_values ?: '{}', true);
        $test = json_decode($config->test_values ?: '{}', true);
        $live = is_array($live) ? $live : [];
        $test = is_array($test) ? $test : [];

        $requestedTest = $request->query('foxgo_efi_env') === 'test';
        $testSecret = (string) $request->query('foxgo_test_secret', '');
        $expectedTestSecret = (string) ($test['webhook_secret'] ?? '');

        if ($requestedTest && $testSecret !== '' && $expectedTestSecret !== '' && hash_equals($expectedTestSecret, $testSecret)) {
            return [$config, 'test', $test];
        }

        $mode = $config->mode === 'live' ? 'live' : 'test';
        return [$config, $mode, $mode === 'live' ? $live : $test];
    }

    private function baseUrl(string $mode): string
    {
        return $mode === 'live'
            ? 'https://pix.api.efipay.com.br'
            : 'https://pix-h.api.efipay.com.br';
    }

    private function onlyDigits($value): string
    {
        return preg_replace('/\D+/', '', (string) $value);
    }

    private function efiRequest(string $method, string $url, string $certPath, array $headers = [], $body = null): array
    {
        $ch = curl_init();

        $opts = [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_SSLCERT => $certPath,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_ENCODING => '',
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
        ];

        if ($body !== null) {
            $opts[CURLOPT_POSTFIELDS] = is_string($body)
                ? $body
                : json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }

        curl_setopt_array($ch, $opts);

        $response = curl_exec($ch);
        $error = curl_error($ch);
        $http = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        curl_close($ch);

        return [$http, $response, $error];
    }

    private function token(string $mode, array $values): ?string
    {
        $clientId = (string) ($values['client_id'] ?? '');
        $clientSecret = (string) ($values['client_secret'] ?? '');
        $certPath = (string) ($values['certificate_path'] ?? '');

        if ($clientId === '' || $clientSecret === '' || $certPath === '' || !file_exists($certPath)) {
            return null;
        }

        [$http, $response, $error] = $this->efiRequest(
            'POST',
            $this->baseUrl($mode) . '/oauth/token',
            $certPath,
            [
                'Authorization: Basic ' . base64_encode($clientId . ':' . $clientSecret),
                'Content-Type: application/json',
                'Accept-Encoding: identity',
            ],
            ['grant_type' => 'client_credentials']
        );

        if ($error || $http < 200 || $http >= 300) {
            return null;
        }

        $json = json_decode($response ?: '{}', true);

        return is_array($json) ? ($json['access_token'] ?? null) : null;
    }

    private function payerDocument(PaymentRequest $paymentData): array
    {
        $payer = json_decode($paymentData->payer_information ?: '{}', true);
        $payer = is_array($payer) ? $payer : [];

        $document = $this->onlyDigits(
            data_get($payer, 'document')
            ?: data_get($payer, 'cpf')
            ?: data_get($payer, 'cnpj')
            ?: ''
        );

        $name = trim((string) (
            data_get($payer, 'name')
            ?: trim((string) data_get($payer, 'f_name') . ' ' . (string) data_get($payer, 'l_name'))
            ?: 'Cliente Fox GO'
        ));

        return [$document, $name, $payer];
    }

    private function txid(PaymentRequest $paymentData): string
    {
        if (!empty($paymentData->transaction_id)) {
            return preg_replace('/[^A-Za-z0-9]/', '', (string) $paymentData->transaction_id);
        }

        return 'FG' . substr(str_replace('-', '', (string) $paymentData->id), 0, 30);
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
        $html .= '<form method="POST" action="/payment/efi/pay">';
        $html .= csrf_field();
        $html .= '<input type="hidden" name="payment_id" value="' . $paymentId . '">';
        $html .= '<label for="foxgo_document">CPF ou CNPJ do pagador</label>';
        $html .= '<input id="foxgo_document" name="foxgo_document" inputmode="numeric" autocomplete="off" placeholder="Digite somente números" required>';
        $html .= '<div class="hint">Precisamos desse documento para gerar o Pix com segurança. O pagamento continua dentro da Fox GO.</div>';
        $html .= '<button class="btn" type="submit">Continuar para o Pix</button>';
        $html .= '</form>';
        $html .= '</div></body></html>';

        return response($html, 200)->header('Content-Type', 'text/html; charset=UTF-8');
    }

    private function pixHtml(PaymentRequest $paymentData, array $qrData, string $message = '')
    {
        $paymentId = htmlspecialchars((string) $paymentData->id, ENT_QUOTES, 'UTF-8');
        $amount = number_format((float) $paymentData->payment_amount, 2, ',', '.');

        $qrTextRaw = (string) ($qrData['qrcode'] ?? '');
        $qrText = htmlspecialchars($qrTextRaw, ENT_QUOTES, 'UTF-8');

        $img = (string) ($qrData['imagemQrcode'] ?? '');
        if ($img !== '' && !str_starts_with($img, 'data:image')) {
            $img = 'data:image/png;base64,' . $img;
        }
        $imgHtml = $img !== '' ? '<img class="qr" src="' . htmlspecialchars($img, ENT_QUOTES, 'UTF-8') . '" alt="QR Code Pix">' : '';

        $statusUrl = '/payment/efi/status?payment_id=' . rawurlencode((string) $paymentData->id);
        $messageHtml = $message !== '' ? '<div class="alert">' . htmlspecialchars($message, ENT_QUOTES, 'UTF-8') . '</div>' : '';

        $html = '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">';
        $html .= '<title>Pix Fox GO</title>';
        $html .= '<style>
            body{font-family:Arial,sans-serif;background:#f7f7f7;margin:0;padding:24px;color:#222}
            .card{max-width:560px;margin:0 auto;background:#fff;border-radius:16px;padding:24px;box-shadow:0 8px 30px rgba(0,0,0,.08);text-align:center}
            h1{font-size:22px;margin:0 0 8px}
            .brand{font-size:14px;color:#555;margin-bottom:12px}
            .amount{font-size:28px;font-weight:700;margin:12px 0 20px}
            .qr{width:260px;max-width:100%;height:auto;margin:8px auto 16px;display:block}
            textarea{width:100%;height:120px;box-sizing:border-box;border:1px solid #d8d8d8;border-radius:10px;padding:12px;font-size:13px}
            .btn{display:block;text-decoration:none;width:100%;box-sizing:border-box;border:0;background:#039b53;color:#fff;border-radius:10px;padding:15px;margin-top:14px;font-size:16px;font-weight:700;cursor:pointer}
            .btn2{background:#333}
            .hint{font-size:13px;color:#666;line-height:1.45;margin-top:10px}
            .alert{background:#fff3cd;border:1px solid #ffe69c;color:#664d03;border-radius:10px;padding:12px;font-size:14px;margin:14px 0;text-align:left}
        </style>';
        $html .= '</head><body><div class="card">';
        $html .= '<h1>Pagamento Pix Fox GO</h1>';
        $html .= '<div class="brand">Escaneie o QR Code ou copie o Pix copia e cola</div>';
        $html .= '<div class="amount">R$ ' . $amount . '</div>';
        $html .= $messageHtml;
        $html .= $imgHtml;
        $html .= '<textarea id="pixcode" readonly>' . $qrText . '</textarea>';
        $html .= '<button class="btn" onclick="navigator.clipboard.writeText(document.getElementById(\'pixcode\').value).then(()=>alert(\'Pix copiado!\'))">Copiar Pix</button>';
        $html .= '<a class="btn btn2" href="' . htmlspecialchars($statusUrl, ENT_QUOTES, 'UTF-8') . '">Já paguei / verificar pagamento</a>';
        $html .= '<div class="hint">Após pagar, toque em verificar pagamento. A confirmação automática também pode chegar pelo webhook.</div>';
        $html .= '</div></body></html>';

        return response($html, 200)->header('Content-Type', 'text/html; charset=UTF-8');
    }

    private function finishPaid(PaymentRequest $paymentData, string $txid)
    {
        DB::table('payment_requests')
            ->where('id', $paymentData->id)
            ->update([
                'is_paid' => 1,
                'transaction_id' => $txid,
                'payment_method' => 'efi',
                'updated_at' => now(),
            ]);

        if (!empty($paymentData->success_hook) && filter_var($paymentData->success_hook, FILTER_VALIDATE_URL)) {
            return redirect()->away($paymentData->success_hook);
        }

        if (!empty($paymentData->gateway_callback_url) && filter_var($paymentData->gateway_callback_url, FILTER_VALIDATE_URL)) {
            $separator = str_contains($paymentData->gateway_callback_url, '?') ? '&' : '?';
            return redirect()->away($paymentData->gateway_callback_url . $separator . http_build_query([
                'payment_id' => $paymentData->id,
                'status' => 'success',
                'transaction_id' => $txid,
            ]));
        }

        return response('<h2>Pagamento aprovado na Fox GO.</h2>', 200);
    }

    public function payment(Request $request)
    {
        $request->validate([
            'payment_id' => 'required|uuid',
        ]);

        [$config, $mode, $values] = $this->configValues($request);

        $testSecret = (string) $request->query('foxgo_test_secret', '');
        $expectedSecret = (string) ($values['webhook_secret'] ?? '');
        $isInternalTest = $testSecret !== '' && $expectedSecret !== '' && hash_equals($expectedSecret, $testSecret);

        if (!$config || empty($values['client_id']) || empty($values['client_secret']) || empty($values['certificate_path']) || empty($values['pix_key'])) {
            return response()->json(['status' => 'error', 'message' => 'Efí Pix indisponível no momento.'], 422);
        }

        if ((int)($values['status'] ?? 0) !== 1 && !$isInternalTest) {
            return response()->json(['status' => 'error', 'message' => 'Efí Pix ainda não está ativo.'], 422);
        }

        $paymentData = PaymentRequest::where('id', $request->payment_id)
            ->where('is_paid', 0)
            ->first();

        if (!$paymentData) {
            return response()->json(['status' => 'error', 'message' => 'Payment request não encontrada ou já paga.'], 404);
        }

        [$document, $name, $payerRaw] = $this->payerDocument($paymentData);
        $submittedDocument = $this->onlyDigits($request->input('foxgo_document', ''));

        if ($document === '') {
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
                    'payer_information' => json_encode($payerRaw, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                    'transaction_id' => null,
                    'payment_method' => 'efi',
                    'updated_at' => now(),
                ]);

            $paymentData = PaymentRequest::where('id', $paymentData->id)->first();
            [$document, $name] = $this->payerDocument($paymentData);
        }

        $amount = number_format((float) $paymentData->payment_amount, 2, '.', '');
        if ((float) $amount <= 0) {
            return response()->json(['status' => 'error', 'message' => 'Valor inválido para Pix.'], 422);
        }

        $token = $this->token($mode, $values);
        if (!$token) {
            return response()->json(['status' => 'error', 'message' => 'Falha ao autenticar na Efí.'], 422);
        }

        $txid = $this->txid($paymentData);

        $debtor = strlen($document) === 14
            ? ['cnpj' => $document, 'nome' => $name]
            : ['cpf' => $document, 'nome' => $name];

        $payload = [
            'calendario' => ['expiracao' => 3600],
            'devedor' => $debtor,
            'valor' => ['original' => $amount],
            'chave' => (string) $values['pix_key'],
            'solicitacaoPagador' => 'Pedido Fox GO',
        ];

        [$httpCob, $cobResp, $cobErr] = $this->efiRequest(
            'PUT',
            $this->baseUrl($mode) . '/v2/cob/' . $txid,
            (string) $values['certificate_path'],
            [
                'Authorization: Bearer ' . $token,
                'Content-Type: application/json',
                'Accept-Encoding: identity',
            ],
            $payload
        );

        $cob = json_decode($cobResp ?: '{}', true);
        $locId = is_array($cob) ? data_get($cob, 'loc.id') : null;

        if ($cobErr || $httpCob < 200 || $httpCob >= 300 || !$locId) {
            
        // Fox GO Efí: reaproveita cobrança Pix existente quando a criação falhar por conflito/txid já criado.
        // A Efí pode criar a cobrança e, em nova tentativa, retornar 409. Nesse caso, buscamos a cobrança e o QR pelo txid salvo.
        try {
            if (!empty($txid ?? null) && !empty($accessToken ?? null) && !empty($certificatePath ?? null) && !empty($baseUrl ?? null)) {
                $reuseCob = curl_init();
                curl_setopt_array($reuseCob, [
                    CURLOPT_URL => rtrim($baseUrl, '/') . '/v2/cob/' . rawurlencode((string) $txid),
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_CUSTOMREQUEST => 'GET',
                    CURLOPT_HTTPHEADER => [
                        'Authorization: Bearer ' . $accessToken,
                        'Content-Type: application/json',
                    ],
                    CURLOPT_SSLCERT => $certificatePath,
                    CURLOPT_TIMEOUT => 30,
                ]);

                $reuseCobRaw = curl_exec($reuseCob);
                $reuseCobError = curl_error($reuseCob);
                $reuseCobHttp = curl_getinfo($reuseCob, CURLINFO_HTTP_CODE);
                curl_close($reuseCob);

                $reuseCobJson = json_decode($reuseCobRaw ?: '{}', true);

                if (!$reuseCobError && $reuseCobHttp >= 200 && $reuseCobHttp < 300 && is_array($reuseCobJson)) {
                    $reuseLocId = $reuseCobJson['loc']['id'] ?? null;

                    if ($reuseLocId) {
                        $reuseQr = curl_init();
                        curl_setopt_array($reuseQr, [
                            CURLOPT_URL => rtrim($baseUrl, '/') . '/v2/loc/' . rawurlencode((string) $reuseLocId) . '/qrcode',
                            CURLOPT_RETURNTRANSFER => true,
                            CURLOPT_CUSTOMREQUEST => 'GET',
                            CURLOPT_HTTPHEADER => [
                                'Authorization: Bearer ' . $accessToken,
                                'Content-Type: application/json',
                            ],
                            CURLOPT_SSLCERT => $certificatePath,
                            CURLOPT_TIMEOUT => 30,
                        ]);

                        $reuseQrRaw = curl_exec($reuseQr);
                        $reuseQrError = curl_error($reuseQr);
                        $reuseQrHttp = curl_getinfo($reuseQr, CURLINFO_HTTP_CODE);
                        curl_close($reuseQr);

                        $reuseQrJson = json_decode($reuseQrRaw ?: '{}', true);

                        if (!$reuseQrError && $reuseQrHttp >= 200 && $reuseQrHttp < 300 && is_array($reuseQrJson) && (!empty($reuseQrJson['qrcode']) || !empty($reuseQrJson['imagemQrcode']))) {
                            \Illuminate\Support\Facades\DB::table('payment_requests')
                                ->where('id', $paymentData->id)
                                ->update([
                                    'transaction_id' => $txid,
                                    'updated_at' => now(),
                                ]);

                            $qr = [
                                'qrcode' => $reuseQrJson['qrcode'] ?? null,
                                'imagemQrcode' => $reuseQrJson['imagemQrcode'] ?? null,
                                'txid' => $txid,
                                'loc_id' => $reuseLocId,
                                'status' => $reuseCobJson['status'] ?? null,
                                'reused_existing_charge' => true,
                            ];

                            return $this->pixHtml($paymentData, $qr);
                        }
                    }
                }
            }
        } catch (\Throwable $e) {
            info('Fox GO Efí Pix reuse existing charge failed: ' . $e->getMessage());
        }

return response()->json([
                'status' => 'error',
                'message' => 'Não foi possível gerar o Pix Efí agora.',
                'http_status' => $httpCob,
            ], 422);
        }

        DB::table('payment_requests')
            ->where('id', $paymentData->id)
            ->update([
                'transaction_id' => $txid,
                'payment_method' => 'efi',
                'updated_at' => now(),
            ]);

        [$httpQr, $qrResp, $qrErr] = $this->efiRequest(
            'GET',
            $this->baseUrl($mode) . '/v2/loc/' . $locId . '/qrcode',
            (string) $values['certificate_path'],
            [
                'Authorization: Bearer ' . $token,
                'Content-Type: application/json',
                'Accept-Encoding: identity',
            ]
        );

        $qr = json_decode($qrResp ?: '{}', true);

        if ($qrErr || $httpQr < 200 || $httpQr >= 300 || empty($qr['qrcode'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Pix Efí criado, mas QR Code não foi gerado.',
                'http_status' => $httpQr,
            ], 422);
        }

        return $this->pixHtml($paymentData, $qr);
    }

    public function status(Request $request)
    {
        $paymentId = (string) $request->query('payment_id', $request->input('payment_id', ''));

        if ($paymentId === '') {
            return response()->json(['status' => 'error', 'message' => 'Pagamento não informado.'], 400);
        }

        $paymentData = \App\Models\PaymentRequest::where('id', $paymentId)->first();

        if (!$paymentData) {
            return response()->json(['status' => 'error', 'message' => 'Pagamento não encontrado.'], 404);
        }

        if ((int) $paymentData->is_paid !== 1 && !empty($paymentData->transaction_id)) {
            try {
                $config = \Illuminate\Support\Facades\DB::table('addon_settings')
                    ->where('key_name', 'efi')
                    ->where('settings_type', 'payment_config')
                    ->first();

                if ($config) {
                    $mode = ($config->mode ?? 'test') === 'live' ? 'live' : 'test';
                    $values = json_decode($mode === 'live' ? ($config->live_values ?: '{}') : ($config->test_values ?: '{}'), true);
                    $values = is_array($values) ? $values : [];

                    $clientId = (string) ($values['client_id'] ?? '');
                    $clientSecret = (string) ($values['client_secret'] ?? '');
                    $certPath = (string) ($values['certificate_path'] ?? '');

                    $baseUrl = $mode === 'live'
                        ? 'https://pix.api.efipay.com.br'
                        : 'https://pix-h.api.efipay.com.br';

                    if ($clientId !== '' && $clientSecret !== '' && $certPath !== '' && file_exists($certPath) && is_readable($certPath)) {
                        $ch = curl_init();
                        curl_setopt_array($ch, [
                            CURLOPT_URL => $baseUrl . '/oauth/token',
                            CURLOPT_RETURNTRANSFER => true,
                            CURLOPT_TIMEOUT => 30,
                            CURLOPT_CUSTOMREQUEST => 'POST',
                            CURLOPT_SSLCERT => $certPath,
                            CURLOPT_HTTPHEADER => [
                                'Authorization: Basic ' . base64_encode($clientId . ':' . $clientSecret),
                                'Content-Type: application/json',
                                'Accept-Encoding: identity',
                            ],
                            CURLOPT_POSTFIELDS => json_encode(['grant_type' => 'client_credentials']),
                        ]);

                        $tokenResponse = curl_exec($ch);
                        $tokenError = curl_error($ch);
                        $tokenHttp = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                        curl_close($ch);

                        $tokenJson = json_decode($tokenResponse ?: '{}', true);
                        $accessToken = (!$tokenError && $tokenHttp >= 200 && $tokenHttp < 300 && !empty($tokenJson['access_token']))
                            ? (string) $tokenJson['access_token']
                            : '';

                        if ($accessToken !== '') {
                            $ch = curl_init();
                            curl_setopt_array($ch, [
                                CURLOPT_URL => $baseUrl . '/v2/cob/' . rawurlencode((string) $paymentData->transaction_id),
                                CURLOPT_RETURNTRANSFER => true,
                                CURLOPT_TIMEOUT => 30,
                                CURLOPT_CUSTOMREQUEST => 'GET',
                                CURLOPT_SSLCERT => $certPath,
                                CURLOPT_HTTPHEADER => [
                                    'Authorization: Bearer ' . $accessToken,
                                    'Content-Type: application/json',
                                    'Accept-Encoding: identity',
                                ],
                            ]);

                            $chargeResponse = curl_exec($ch);
                            $chargeError = curl_error($ch);
                            $chargeHttp = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                            curl_close($ch);

                            $chargeJson = json_decode($chargeResponse ?: '{}', true);
                            $efiStatus = strtoupper((string) ($chargeJson['status'] ?? ''));

                            if (!$chargeError && $chargeHttp >= 200 && $chargeHttp < 300 && ($efiStatus === 'CONCLUIDA' || !empty($chargeJson['pix']))) {
                                \App\Models\PaymentRequest::where('id', $paymentData->id)->update([
                                    'is_paid' => 1,
                                    'updated_at' => now(),
                                ]);

                                $paymentData = \App\Models\PaymentRequest::where('id', $paymentId)->first();
                            }
                        }
                    }
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::warning('Fox GO Efí status check failed', [
                    'payment_id' => $paymentId,
                    'message' => $e->getMessage(),
                ]);
            }
        }

        if ((int) $paymentData->is_paid !== 1) {
            if ($request->query('ajax') || $request->expectsJson()) {
                return response()->json([
                    'status' => 'pending',
                    'paid' => false,
                    'message' => 'Pagamento ainda não confirmado pela Efí.',
                ]);
            }

            return response('Pagamento ainda não confirmado pela Efí. Aguarde alguns segundos e tente novamente.', 202);
        }

        $shouldRunSuccessHook = true;

        if (($paymentData->attribute ?? null) === 'order' && !empty($paymentData->attribute_id)) {
            $order = \Illuminate\Support\Facades\DB::table('orders')
                ->where('id', $paymentData->attribute_id)
                ->first();

            if ($order && $order->payment_status === 'paid' && !in_array($order->order_status, ['failed', 'canceled', 'cancelled'], true)) {
                $shouldRunSuccessHook = false;
            }
        }

        if ($shouldRunSuccessHook && !empty($paymentData->success_hook) && function_exists($paymentData->success_hook)) {
            call_user_func($paymentData->success_hook, $paymentData);
        }

        $paymentData = \App\Models\PaymentRequest::where('id', $paymentId)->first();

        $redirectUrl = $paymentData->external_redirect_link ?: url('/');
        $tokenString = 'payment_id=' . $paymentData->id . '&&transaction_reference=' . ($paymentData->transaction_id ?? '');
        $separator = str_contains($redirectUrl, '?') ? '&' : '?';
        $finalUrl = $redirectUrl . $separator . 'flag=success&token=' . base64_encode($tokenString);

        if ($request->query('ajax') || $request->expectsJson()) {
            return response()->json([
                'status' => 'paid',
                'paid' => true,
                'redirect_url' => $finalUrl,
            ]);
        }

        return redirect()->to($finalUrl);
    }





    public function webhook(Request $request)
    {
        $config = DB::table('addon_settings')
            ->where('key_name', 'efi')
            ->where('settings_type', 'payment_config')
            ->first();

        if (!$config) {
            return response()->json(['status' => 'error', 'message' => 'Efí não configurada.'], 404);
        }

        $live = json_decode($config->live_values ?: '{}', true);
        $test = json_decode($config->test_values ?: '{}', true);
        $live = is_array($live) ? $live : [];
        $test = is_array($test) ? $test : [];

        $providedSecret = (string) (
            $request->query('foxgo_secret')
            ?: $request->header('X-Foxgo-Efi-Webhook-Secret')
            ?: ''
        );

        $allowedSecrets = array_values(array_filter([
            (string) ($live['webhook_secret'] ?? ''),
            (string) ($test['webhook_secret'] ?? ''),
        ]));

        $authorized = false;

        foreach ($allowedSecrets as $secret) {
            if ($providedSecret !== '' && hash_equals($secret, $providedSecret)) {
                $authorized = true;
                break;
            }
        }

        if (!$authorized) {
            return response()->json(['status' => 'error', 'message' => 'Webhook não autorizado.'], 403);
        }

        $payload = $request->all();

        $txids = [];

        array_walk_recursive($payload, function ($value, $key) use (&$txids) {
            if ($key === 'txid' && is_string($value) && $value !== '') {
                $txids[] = preg_replace('/[^A-Za-z0-9]/', '', $value);
            }
        });

        $txids = array_values(array_unique(array_filter($txids)));
        $updated = 0;

        foreach ($txids as $txid) {
            $updated += DB::table('payment_requests')
                ->where('transaction_id', $txid)
                ->where('payment_method', 'efi')
                ->update([
                    'is_paid' => 1,
                    'updated_at' => now(),
                ]);
        }

        return response()->json([
            'status' => 'ok',
            'received_txids' => count($txids),
            'updated_payments' => $updated,
        ]);
    }
}
