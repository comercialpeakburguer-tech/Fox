<?php

namespace App\CentralLogics;

use Illuminate\Support\Facades\Http;

class FoxGoCnpjValidationLogic
{
    public static function validateAndConsult(?string $rawCnpj): array
    {
        $cnpj = self::onlyDigits($rawCnpj);

        if (!self::isValidCnpj($cnpj)) {
            return [
                'ok' => false,
                'source' => 'local',
                'cnpj' => $cnpj,
                'status' => 'invalid_format',
                'message' => 'Informe um CNPJ válido da loja.',
            ];
        }

        // 1) Se tiver Serpro configurado, ele é prioridade oficial.
        $serpro = self::consultSerpro($cnpj);
        if ($serpro !== null) {
            return $serpro;
        }

        // 2) Fallback gratuito público: BrasilAPI.
        $brasilApi = self::consultBrasilApi($cnpj);
        if ($brasilApi !== null) {
            return $brasilApi;
        }

        // 3) Fallback gratuito público: Minha Receita.
        $minhaReceita = self::consultMinhaReceita($cnpj);
        if ($minhaReceita !== null) {
            return $minhaReceita;
        }

        // 4) Se APIs gratuitas estiverem fora, não trava cadastro por falha externa.
        return [
            'ok' => true,
            'source' => 'local',
            'cnpj' => $cnpj,
            'status' => 'pending_public_validation',
            'message' => 'CNPJ válido pelo dígito verificador. Consulta pública indisponível no momento.',
        ];
    }

    private static function consultBrasilApi(string $cnpj): ?array
    {
        try {
            $response = Http::timeout(8)
                ->acceptJson()
                ->get('https://brasilapi.com.br/api/cnpj/v1/' . $cnpj);

            if ($response->status() === 404 || $response->status() === 400) {
                return [
                    'ok' => false,
                    'source' => 'brasilapi',
                    'cnpj' => $cnpj,
                    'status' => 'not_found',
                    'message' => 'CNPJ não encontrado na consulta pública.',
                    'http_status' => $response->status(),
                ];
            }

            if (!$response->successful()) {
                return null;
            }

            $data = $response->json();
            if (!is_array($data)) {
                return null;
            }

            $situacaoRaw = $data['descricao_situacao_cadastral']
                ?? $data['situacao_cadastral']
                ?? $data['situacao']
                ?? null;

            $situacao = self::normalizeSituacao($situacaoRaw);
            $ok = $situacao === 'ATIVA';

            return [
                'ok' => $ok,
                'source' => 'brasilapi',
                'cnpj' => $cnpj,
                'status' => $ok ? 'active_regular' : 'not_active',
                'message' => $ok ? 'CNPJ ativo.' : 'CNPJ não está ativo: ' . ($situacao ?: 'situação não identificada'),
                'situacao_cadastral' => $situacao,
                'razao_social' => $data['razao_social'] ?? null,
                'nome_fantasia' => $data['nome_fantasia'] ?? null,
                'data_inicio_atividade' => $data['data_inicio_atividade'] ?? null,
                'cnae_fiscal' => $data['cnae_fiscal'] ?? null,
                'cnae_fiscal_descricao' => $data['cnae_fiscal_descricao'] ?? null,
                'municipio' => $data['municipio'] ?? null,
                'uf' => $data['uf'] ?? null,
                'cep' => $data['cep'] ?? null,
                'raw' => $data,
            ];
        } catch (\Throwable $e) {
            info('FoxGoCnpjValidation: BrasilAPI falhou cnpj=' . $cnpj . ' erro=' . $e->getMessage());
            return null;
        }
    }

    private static function consultMinhaReceita(string $cnpj): ?array
    {
        try {
            $response = Http::timeout(8)
                ->acceptJson()
                ->get('https://minhareceita.org/' . $cnpj);

            if ($response->status() === 404 || $response->status() === 400) {
                return [
                    'ok' => false,
                    'source' => 'minhareceita',
                    'cnpj' => $cnpj,
                    'status' => 'not_found',
                    'message' => 'CNPJ não encontrado na consulta pública.',
                    'http_status' => $response->status(),
                ];
            }

            if (!$response->successful()) {
                return null;
            }

            $data = $response->json();
            if (!is_array($data)) {
                return null;
            }

            $situacaoRaw = $data['descricao_situacao_cadastral']
                ?? $data['situacao_cadastral']
                ?? $data['situacao']
                ?? null;

            $situacao = self::normalizeSituacao($situacaoRaw);
            $ok = $situacao === 'ATIVA';

            return [
                'ok' => $ok,
                'source' => 'minhareceita',
                'cnpj' => $cnpj,
                'status' => $ok ? 'active_regular' : 'not_active',
                'message' => $ok ? 'CNPJ ativo.' : 'CNPJ não está ativo: ' . ($situacao ?: 'situação não identificada'),
                'situacao_cadastral' => $situacao,
                'razao_social' => $data['razao_social'] ?? null,
                'nome_fantasia' => $data['nome_fantasia'] ?? null,
                'data_inicio_atividade' => $data['data_inicio_atividade'] ?? null,
                'cnae_fiscal' => $data['cnae_fiscal'] ?? null,
                'cnae_fiscal_descricao' => $data['cnae_fiscal_descricao'] ?? null,
                'municipio' => $data['municipio'] ?? null,
                'uf' => $data['uf'] ?? null,
                'cep' => $data['cep'] ?? null,
                'raw' => $data,
            ];
        } catch (\Throwable $e) {
            info('FoxGoCnpjValidation: MinhaReceita falhou cnpj=' . $cnpj . ' erro=' . $e->getMessage());
            return null;
        }
    }

    private static function consultSerpro(string $cnpj): ?array
    {
        $consumerKey = env('SERPRO_CNPJ_CONSUMER_KEY');
        $consumerSecret = env('SERPRO_CNPJ_CONSUMER_SECRET');
        $baseUrl = rtrim((string) env('SERPRO_CNPJ_BASE_URL'), '/');

        if (!$consumerKey || !$consumerSecret || !$baseUrl) {
            return null;
        }

        try {
            $tokenResponse = Http::asForm()
                ->timeout(8)
                ->withBasicAuth($consumerKey, $consumerSecret)
                ->post('https://gateway.apiserpro.serpro.gov.br/token', [
                    'grant_type' => 'client_credentials',
                ]);

            $tokenData = $tokenResponse->json();

            if (!$tokenResponse->successful() || empty($tokenData['access_token'])) {
                return null;
            }

            $response = Http::timeout(8)
                ->withToken($tokenData['access_token'])
                ->acceptJson()
                ->get($baseUrl . '/basica/' . $cnpj);

            if (!$response->successful()) {
                return null;
            }

            $data = $response->json();
            $codigo = (string)($data['situacao_cadastral']['codigo'] ?? '');
            $ok = $codigo === '2';

            return [
                'ok' => $ok,
                'source' => 'serpro',
                'cnpj' => $cnpj,
                'status' => $ok ? 'active_regular' : 'not_active',
                'message' => $ok ? 'CNPJ ativo e regular.' : 'CNPJ não está ativo/regular: ' . self::situacaoDescricao($codigo),
                'situacao_cadastral_codigo' => $codigo,
                'situacao_cadastral' => self::situacaoDescricao($codigo),
                'raw' => $data,
            ];
        } catch (\Throwable $e) {
            info('FoxGoCnpjValidation: Serpro falhou cnpj=' . $cnpj . ' erro=' . $e->getMessage());
            return null;
        }
    }

    public static function onlyDigits(?string $value): string
    {
        return preg_replace('/\D+/', '', (string) $value);
    }

    public static function isValidCnpj(?string $cnpj): bool
    {
        $cnpj = self::onlyDigits($cnpj);

        if (strlen($cnpj) !== 14) return false;
        if (preg_match('/^(\d)\1{13}$/', $cnpj)) return false;

        $weights1 = [5,4,3,2,9,8,7,6,5,4,3,2];
        $weights2 = [6,5,4,3,2,9,8,7,6,5,4,3,2];

        $sum = 0;
        for ($i = 0; $i < 12; $i++) $sum += intval($cnpj[$i]) * $weights1[$i];
        $rest = $sum % 11;
        $digit1 = $rest < 2 ? 0 : 11 - $rest;

        if (intval($cnpj[12]) !== $digit1) return false;

        $sum = 0;
        for ($i = 0; $i < 13; $i++) $sum += intval($cnpj[$i]) * $weights2[$i];
        $rest = $sum % 11;
        $digit2 = $rest < 2 ? 0 : 11 - $rest;

        return intval($cnpj[13]) === $digit2;
    }

    private static function normalizeSituacao($value): ?string
    {
        if ($value === null || $value === '') return null;

        if (is_numeric($value)) {
            return self::situacaoDescricao((string) $value);
        }

        $value = strtoupper(trim((string) $value));

        $map = [
            '1' => 'NULA',
            '2' => 'ATIVA',
            '3' => 'SUSPENSA',
            '4' => 'INAPTA',
            '5' => 'ATIVA NAO REGULAR',
            '8' => 'BAIXADA',
            'ATIVA' => 'ATIVA',
            'NULA' => 'NULA',
            'SUSPENSA' => 'SUSPENSA',
            'INAPTA' => 'INAPTA',
            'BAIXADA' => 'BAIXADA',
            'ATIVA NÃO REGULAR' => 'ATIVA NAO REGULAR',
            'ATIVA NAO REGULAR' => 'ATIVA NAO REGULAR',
        ];

        return $map[$value] ?? $value;
    }

    public static function situacaoDescricao(string $codigo): string
    {
        return [
            '1' => 'NULA',
            '2' => 'ATIVA',
            '3' => 'SUSPENSA',
            '4' => 'INAPTA',
            '5' => 'ATIVA NAO REGULAR',
            '8' => 'BAIXADA',
        ][$codigo] ?? 'DESCONHECIDA';
    }
}
