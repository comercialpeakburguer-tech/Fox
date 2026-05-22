@extends('layouts.landing.app')

@section('title', 'Verificação de recebimento')

@push('css_or_js')
    <script src="https://connect-js.stripe.com/v1.0/connect.js"></script>
    <style>
        .foxgo-connect-wrap {
            max-width: 980px;
            margin: 32px auto;
            padding: 0 16px;
        }
        .foxgo-connect-card {
            background: #fff;
            border-radius: 18px;
            box-shadow: 0 10px 35px rgba(15, 23, 42, .10);
            overflow: hidden;
            border: 1px solid rgba(15, 23, 42, .08);
        }
        .foxgo-connect-header {
            padding: 28px;
            background: linear-gradient(135deg, #111827, #1f2937);
            color: #fff;
        }
        .foxgo-connect-header h3 {
            color: #fff;
            margin-bottom: 8px;
            font-weight: 700;
        }
        .foxgo-connect-body {
            padding: 28px;
        }
        .foxgo-connect-muted {
            color: #64748b;
        }
        .foxgo-connect-status {
            padding: 14px 16px;
            border-radius: 12px;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            margin-bottom: 18px;
        }
        #foxgo-connect-container {
            min-height: 520px;
        }
        .foxgo-connect-actions {
            display: flex;
            gap: 12px;
            justify-content: flex-end;
            padding-top: 18px;
        }
    </style>
@endpush

@section('content')
    <div class="foxgo-connect-wrap">
        <div class="foxgo-connect-card">
            <div class="foxgo-connect-header">
                <h3>Verificação de recebimento Fox GO</h3>
                <p class="mb-0">
                    Conclua a verificação para sua loja receber os repasses automaticamente pela Fox GO.
                </p>
            </div>

            <div class="foxgo-connect-body">
                <div class="foxgo-connect-status" id="foxgo-connect-status">
                    Preparando ambiente seguro de verificação...
                </div>

                <p class="foxgo-connect-muted">
                    Loja: <strong>{{ $store->name }}</strong>
                </p>

                <div id="foxgo-connect-container"></div>

                <div class="foxgo-connect-actions">
                    <button type="button" class="btn btn-primary" id="foxgo-connect-continue" disabled>
                        Continuar cadastro
                    </button>
                </div>
            </div>
        </div>
    </div>
@endsection

@push('script_2')
<script>
(function () {
    const storeId = @json($store_id);
    const businessPlan = @json($business_plan);
    const csrfToken = @json(csrf_token());
    const sessionUrl = @json(route('restaurant.connect_account_session'));
    const statusUrl = @json(route('restaurant.connect_status'));
    const statusEl = document.getElementById('foxgo-connect-status');
    const continueBtn = document.getElementById('foxgo-connect-continue');
    const container = document.getElementById('foxgo-connect-container');

    function setStatus(message) {
        if (statusEl) statusEl.innerText = message;
    }

    async function postJson(url, payload) {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-TOKEN': csrfToken
            },
            body: JSON.stringify(payload)
        });

        const data = await response.json().catch(function () { return {}; });

        if (!response.ok) {
            throw new Error(data.message || 'Falha na comunicação com o servidor.');
        }

        return data;
    }

    async function refreshStatus() {
        setStatus('Confirmando status da verificação...');

        const data = await postJson(statusUrl, {
            store_id: storeId,
            business_plan: businessPlan
        });

        if (data.status === 'active') {
            setStatus('Verificação concluída. Sua loja está pronta para receber repasses automáticos.');
        } else {
            setStatus('Verificação enviada. Caso a Stripe solicite documentos adicionais, a Fox GO vai manter a loja em análise até concluir.');
        }

        continueBtn.disabled = false;
        continueBtn.onclick = function () {
            window.location.href = data.redirect_url;
        };
    }

    async function init() {
        try {
            const data = await postJson(sessionUrl, { store_id: storeId });

            setStatus('Ambiente seguro carregado. Complete a verificação abaixo.');

            const stripeConnectInstance = StripeConnect.init({
                publishableKey: data.published_key,
                fetchClientSecret: async function () {
                    return data.client_secret;
                },
                appearance: {
                    overlays: 'dialog'
                },
                locale: 'pt-BR'
            });

            const onboarding = stripeConnectInstance.create('account-onboarding');

            onboarding.setOnExit(function () {
                refreshStatus().catch(function (error) {
                    setStatus(error.message || 'Não foi possível confirmar a verificação agora.');
                });
            });

            container.appendChild(onboarding);
        } catch (error) {
            setStatus(error.message || 'Não foi possível iniciar a verificação de recebimento.');
        }
    }

    init();
})();
</script>
@endpush
