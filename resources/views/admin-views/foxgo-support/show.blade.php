@extends('layouts.admin.app')

@section('title', 'Detalhe do Caso de Suporte')

@section('content')
    <div class="content container-fluid">
        <style>
            .foxgo-support-case-layout {
                align-items: flex-start;
            }

            .foxgo-support-case-layout > .col-lg-4 {
                position: sticky;
                top: 88px;
                max-height: calc(100vh - 104px);
                overflow-y: auto;
                padding-bottom: 16px;
            }

            .foxgo-support-case-layout .card {
                border: 1px solid #e8edf3;
                border-radius: 12px;
                box-shadow: 0 4px 14px rgba(15, 23, 42, 0.04);
            }

            .foxgo-support-case-layout .card-header {
                background: #fff;
                border-bottom: 1px solid #edf2f7;
                padding: .85rem 1rem;
            }

            .foxgo-support-case-layout .card-body {
                padding: 1rem;
            }

            .foxgo-support-case-layout .btn {
                border-radius: 8px;
                font-weight: 600;
            }

            .foxgo-support-case-layout textarea.form-control {
                min-height: 92px;
            }

            .foxgo-support-case-layout .alert {
                border-radius: 8px;
            }

            .foxgo-support-history-card .card-body {
                max-height: 560px;
                overflow-y: auto;
            }

            .foxgo-support-history-card .border,
            .foxgo-support-history-card .card-body > div {
                border-radius: 8px;
            }

            .foxgo-support-action-note {
                background: #e9fbf8;
                border: 1px solid #baf2e8;
                color: #075e55;
                border-radius: 10px;
                padding: .75rem 1rem;
                margin-bottom: 1rem;
                font-size: 13px;
                font-weight: 600;
            }

            @media (max-width: 991.98px) {
                .foxgo-support-case-layout > .col-lg-4 {
                    position: static;
                    max-height: none;
                    overflow: visible;
                }
            }
        </style>

        <div class="page-header">
            <div class="d-flex flex-wrap justify-content-between align-items-center">
                <div>
                    <h1 class="page-header-title mb-1">
                        Caso {{ $supportCase->protocol }}
                    </h1>
                    <p class="text-muted mb-0">
                        Detalhe operacional do caso. Comentários internos, evidências, transferência de setor, conversa nativa e Nina Atendente estão disponíveis conforme permissão.
                    </p>
                </div>

                <div class="mt-2 mt-sm-0">
                    <a href="{{ route('admin.support.cases') }}" class="btn btn--secondary">
                        Voltar para casos
                    </a>
                </div>
            </div>
        </div>

        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h6 class="text-muted mb-2">Setor atual</h6>
                        <h4 class="mb-0">{{ optional($supportCase->department)->name ?? 'Sem setor' }}</h4>
                        <small class="text-muted">{{ optional($supportCase->department)->slug ?? '—' }}</small>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h6 class="text-muted mb-2">Status</h6>
                        <span class="badge badge-soft-warning p-2">
                            {{ [
                                'open' => 'Aberto',
                                'resolved' => 'Resolvido',
                                'closed' => 'Fechado',
                                'encaminhado' => 'Encaminhado',
                                'em_atendimento' => 'Em atendimento',
                                'em_analise_reembolso' => 'Em análise de reembolso',
                            ][$supportCase->status] ?? ucfirst(str_replace('_', ' ', $supportCase->status)) }}
                        </span>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h6 class="text-muted mb-2">Prioridade</h6>
                        <span class="badge badge-soft-primary p-2">
                            {{ [
                                'low' => 'Baixa',
                                'normal' => 'Normal',
                                'medium' => 'Média',
                                'high' => 'Alta',
                                'urgent' => 'Urgente',
                            ][$supportCase->priority] ?? ucfirst(str_replace('_', ' ', $supportCase->priority)) }}
                        </span>
                    </div>
                </div>
            </div>

            <div class="col-md-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h6 class="text-muted mb-2">SLA</h6>
                        <h5 class="mb-0">
                            {{ optional($supportCase->sla_due_at)->format('d/m/Y H:i') ?? 'Sem prazo' }}
                        </h5>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-3 foxgo-support-case-layout">
            <div class="col-lg-8">
                <div class="card mb-4">
                    <div class="card-header">
                        <h4 class="card-title mb-0">Informações do caso</h4>
                    </div>
                    <div class="card-body">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <h6 class="text-muted">Protocolo</h6>
                                <p class="mb-3">{{ $supportCase->protocol }}</p>
                            </div>

                            <div class="col-md-6">
                                <h6 class="text-muted">Motivo</h6>
                                <p class="mb-3">{{ $supportCase->reason ?? '—' }}</p>
                            </div>

                            <div class="col-12">
                                <h6 class="text-muted">Assunto</h6>
                                <p class="mb-3">{{ $supportCase->subject ?? '—' }}</p>
                            </div>

                            <div class="col-12">
                                <h6 class="text-muted">Descrição</h6>
                                <p class="mb-0">{{ $supportCase->description ?? '—' }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                @if($supportCase->order)
                    <div class="card mb-4">
                        <div class="card-header">
                            <h4 class="card-title mb-0">Resumo do pedido vinculado</h4>
                        </div>

                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-4">
                                    <h6 class="text-muted">Pedido</h6>
                                    <p class="mb-3">#{{ $supportCase->order->id }}</p>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Status do pedido</h6>
                                    <span class="badge badge-soft-info">
                                        {{ ucfirst(str_replace('_', ' ', $supportCase->order->order_status ?? '—')) }}
                                    </span>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Status do pagamento</h6>
                                    <span class="badge badge-soft-success">
                                        {{ ucfirst(str_replace('_', ' ', $supportCase->order->payment_status ?? '—')) }}
                                    </span>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Método de pagamento</h6>
                                    <p class="mb-3">{{ $supportCase->order->payment_method ?? '—' }}</p>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Valor do pedido</h6>
                                    <p class="mb-3">R$ {{ number_format((float) ($supportCase->order->order_amount ?? 0), 2, ',', '.') }}</p>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Taxa de entrega</h6>
                                    <p class="mb-3">R$ {{ number_format((float) ($supportCase->order->delivery_charge ?? 0), 2, ',', '.') }}</p>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Cliente ID</h6>
                                    <p class="mb-3">{{ $supportCase->order->user_id ?? '—' }}</p>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Loja ID</h6>
                                    <p class="mb-3">{{ $supportCase->order->store_id ?? '—' }}</p>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Entregador ID</h6>
                                    <p class="mb-3">{{ $supportCase->order->delivery_man_id ?? '—' }}</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    {{-- FOXGO_FINANCIAL_CONTEXT_PERMISSION --}}
                    @if($supportPermissions['can_view_financial_context'] ?? false)
                    <div class="card mb-4">
                        <div class="card-header">
                            <h4 class="card-title mb-0">Pagamentos / Repasses do pedido</h4>
                                <small class="text-muted d-block mt-1">Área informativa protegida por permissão. Não executa ação financeira.</small>
                        </div>

                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <h6 class="text-muted">Gateway / ID do pagamento</h6>
                                    <p class="mb-3">{{ $supportCase->order->stripe_payment_intent_id ?? '—' }}</p>
                                </div>

                                <div class="col-md-6">
                                    <h6 class="text-muted">ID da cobrança</h6>
                                    <p class="mb-3">{{ $supportCase->order->stripe_charge_id ?? '—' }}</p>
                                </div>

                                <div class="col-md-6">
                                    <h6 class="text-muted">Repasse / Split</h6>
                                    @if($supportCase->order->stripe_transfer_id)
                                        <span class="badge badge-soft-success mb-2">Split criado</span>
                                        <p class="mb-3">{{ $supportCase->order->stripe_transfer_id }}</p>
                                    @else
                                        <span class="badge badge-soft-warning mb-3">Sem split registrado</span>
                                    @endif
                                </div>

                                <div class="col-md-6">
                                    <h6 class="text-muted">Taxa Fox GO / Application fee</h6>
                                    <p class="mb-3">
                                        @if(!is_null($supportCase->order->stripe_application_fee_amount))
                                            R$ {{ number_format((float) $supportCase->order->stripe_application_fee_amount, 2, ',', '.') }}
                                            {{ strtoupper($supportCase->order->stripe_currency ?? '') }}
                                        @else
                                            —
                                        @endif
                                    </p>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Ledger interno</h6>
                                    @if($orderTransaction)
                                        <span class="badge badge-soft-success">Criado</span>
                                    @else
                                        <span class="badge badge-soft-warning">Não encontrado</span>
                                    @endif
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Valor da loja</h6>
                                    <p class="mb-3">
                                        @if($orderTransaction)
                                            R$ {{ number_format((float) $orderTransaction->store_amount, 2, ',', '.') }}
                                        @else
                                            —
                                        @endif
                                    </p>
                                </div>

                                <div class="col-md-4">
                                    <h6 class="text-muted">Comissão admin</h6>
                                    <p class="mb-3">
                                        @if($orderTransaction)
                                            R$ {{ number_format((float) $orderTransaction->admin_commission, 2, ',', '.') }}
                                        @else
                                            —
                                        @endif
                                    </p>
                                </div>
                            </div>

                            <div class="alert alert-warning mt-3 mb-0">
                                Esta área é somente informativa. Ela não executa reembolso, reversão de transfer, desconto de repasse ou qualquer ação financeira.
                            </div>
                        </div>
                    </div>
                    @else
                        <div class="alert alert-warning mb-4">
                            Contexto financeiro, pagamentos e repasses ocultos para este funcionário/setor.
                        </div>
                    @endif
                @endif

                <div class="card mb-4">
                                    {{-- Fox GO Fase 12 - historico visual --}}
                <div class="card mb-4 foxgo-case-timeline-card">
                    <div class="card-header d-flex justify-content-between align-items-center flex-wrap">
                        <h4 class="card-title mb-0">Histórico de ações</h4>
                        <small class="text-muted">
                            {{ $supportCase->actions->count() }} registro(s)
                        </small>
                    </div>

                    <div class="card-body">
                        @php
                            $foxGoActionLabels = [
                                'case_created_internal' => 'Caso criado',
                                'internal_test_created' => 'Teste interno',
                                'case_resolved' => 'Caso resolvido',
                                'case_closed' => 'Caso fechado',
                                'case_reopened' => 'Caso reaberto',
                                'case_status_updated' => 'Status atualizado',
                                'internal_note' => 'Comentário interno',
                                    'nina_guidance' => 'Nina Atendente',
                                'nina_customer_message_sent' => 'Mensagem da Nina enviada',
                                'evidence_added' => 'Evidência adicionada',
                                'department_transfer' => 'Transferência de setor',
                            ];

                            $foxGoActionBadges = [
                                'case_created_internal' => 'badge-primary',
                                'internal_test_created' => 'badge-secondary',
                                'case_resolved' => 'badge-success',
                                'case_closed' => 'badge-dark',
                                'case_reopened' => 'badge-warning',
                                'case_status_updated' => 'badge-info',
                                'internal_note' => 'badge-info',
                                'evidence_added' => 'badge-success',
                                'department_transfer' => 'badge-warning',
                                'nina_customer_message_sent' => 'badge-success',
                            ];
                        @endphp

                        @forelse($supportCase->actions->sortByDesc('id') as $action)
                            @php
                                $foxGoActionType = (string) ($action->action_type ?? 'acao');
                                $foxGoActionLabel = $foxGoActionLabels[$foxGoActionType] ?? ucwords(str_replace('_', ' ', $foxGoActionType));
                                $foxGoBadgeClass = $foxGoActionBadges[$foxGoActionType] ?? 'badge-secondary';
                                $foxGoOldValue = $action->old_value;
                                $foxGoNewValue = $action->new_value;
                            @endphp

                            <div class="border rounded p-3 mb-3 bg-white">
                                <div class="d-flex justify-content-between flex-wrap align-items-start">
                                    <div class="mb-2">
                                        <span class="badge {{ $foxGoBadgeClass }} mb-2">
                                            {{ $foxGoActionLabel }}
                                        </span>

                                        <div class="small text-muted">
                                            Tipo técnico:
                                            <code>{{ $foxGoActionType }}</code>
                                        </div>
                                    </div>

                                    <small class="text-muted">
                                        {{ optional($action->created_at)->format('d/m/Y H:i') ?? '—' }}
                                    </small>
                                </div>

                                @if($action->description)
                                    <p class="mb-2">
                                        {{ $action->description }}
                                    </p>
                                @else
                                    <p class="text-muted mb-2">
                                        Sem descrição registrada.
                                    </p>
                                @endif

                                @if($foxGoOldValue !== null || $foxGoNewValue !== null)
                                    <div class="small mb-2">
                                        <span class="text-muted">Alteração:</span>
                                        <span class="badge badge-light">
                                            {{ $foxGoOldValue !== null && $foxGoOldValue !== '' ? $foxGoOldValue : '—' }}
                                        </span>
                                        <span class="mx-1">→</span>
                                        <span class="badge badge-light">
                                            {{ $foxGoNewValue !== null && $foxGoNewValue !== '' ? $foxGoNewValue : '—' }}
                                        </span>
                                    </div>
                                @endif

                                <div class="small text-muted">
                                    Admin ID: {{ $action->admin_id ?? '—' }}
                                    |
                                    Departamento ID: {{ $action->department_id ?? '—' }}
                                </div>

                                @if($foxGoActionType === 'internal_note')
                                    <div class="alert alert-info mt-3 mb-0 py-2">
                                        Comentário interno. Não enviado ao cliente, loja ou entregador.
                                    </div>
                                @endif

                                @if(in_array($foxGoActionType, ['case_resolved', 'case_closed', 'case_reopened', 'case_status_updated'], true))
                                    <div class="alert alert-warning mt-3 mb-0 py-2">
                                        Ação operacional de status. Não executa reembolso, Pagar.me ou gateway de pagamento ou repasses.
                                    </div>
                                @endif
                            </div>
                        @empty
                            <div class="text-center text-muted py-4">
                                Nenhuma ação registrada neste caso.
                            </div>
                        @endforelse
                    </div>
                </div>
<div class="card-header">
                        <h4 class="card-title mb-0">Evidências anexadas</h4>
                    </div>

                    <div class="card-body">
                        @forelse($supportCase->evidences->sortByDesc('id') as $evidence)
                            <div class="border rounded p-3 mb-3">
                                <div class="d-flex justify-content-between flex-wrap">
                                    <div>
                                        <strong>{{ ucfirst(str_replace('_', ' ', $evidence->evidence_type ?? 'geral')) }}</strong>

                                        @if($evidence->note)
                                            <p class="text-muted mb-1">{{ $evidence->note }}</p>
                                        @endif

                                        @if($evidence->file)
                                            <a href="{{ asset('storage/app/public/' . $evidence->file) }}" target="_blank" class="small">
                                                Abrir anexo
                                            </a>
                                        @else
                                            <div class="small text-muted">Sem arquivo anexado</div>
                                        @endif
                                    </div>

                                    <small class="text-muted">
                                        {{ optional($evidence->created_at)->format('d/m/Y H:i') ?? '—' }}
                                    </small>
                                </div>
                            </div>
                        @empty
                            <div class="text-center text-muted py-4">
                                Nenhuma evidência anexada neste caso.
                            </div>
                        @endforelse
                    </div>
                </div>

                <div class="card mb-4 foxgo-support-history-card"><div class="card-header">
                        <h4 class="card-title mb-0">Histórico de transferências</h4>
                    </div>

                    <div class="card-body">
                        @forelse($supportCase->transfers->sortByDesc('id') as $transfer)
                            <div class="border rounded p-3 mb-3">
                                <div class="d-flex justify-content-between flex-wrap">
                                    <div>
                                        <strong>
                                            {{ optional($transfer->fromDepartment)->name ?? 'Sem origem' }}
                                            →
                                            {{ optional($transfer->toDepartment)->name ?? 'Sem destino' }}
                                        </strong>

                                        <p class="text-muted mb-1">
                                            Motivo: {{ $transfer->reason ?? '—' }}
                                        </p>

                                        @if($transfer->internal_note)
                                            <p class="mb-1">{{ $transfer->internal_note }}</p>
                                        @endif

                                        <div class="small text-muted">
                                            Status: {{ $transfer->status_before ?? '—' }} → {{ $transfer->status_after ?? '—' }}
                                        </div>
                                    </div>

                                    <small class="text-muted">
                                        {{ optional($transfer->created_at)->format('d/m/Y H:i') ?? '—' }}
                                    </small>
                                </div>
                            </div>
                        @empty
                            <div class="text-center text-muted py-4">
                                Nenhuma transferência registrada neste caso.
                            </div>
                        @endforelse
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="card mb-4">
                    <div class="card-header">
                        <h4 class="card-title mb-0">Vínculos operacionais</h4>
                    </div>

                    
                
                                    <div class="foxgo-support-action-note">
                        Ações operacionais do caso. Nada aqui executa reembolso, Pagar.me, repasse ou alteração financeira automática.
                    </div>
{{-- Fox GO V2C - conversa nativa cliente --}}
                <div class="card mb-3 foxgo-native-conversation-card">
                    <div class="card-header">
                        <h4 class="card-title mb-0">Conversa nativa do cliente</h4>
                    </div>
                    <div class="card-body">
                        <p class="text-muted mb-3">
                            Vincula este caso ao chat nativo do 6amMart/Fox GO.
                            Esta ação não envia mensagem automática e não altera pedido, Pagar.me ou gateway de pagamento, reembolso ou repasses.
                        </p>

                        @if($supportCase->conversation_id)
                            <div class="alert alert-success mb-3">
                                Conversa vinculada:
                                <strong>#{{ $supportCase->conversation_id }}</strong>
                            </div>

                            {{-- Fox GO V2D - link direto conversa nativa --}}
                            @php
                                $foxgoNativeConversation = \App\Models\Conversation::find($supportCase->conversation_id);
                                $foxgoNativeConversationUserId = null;

                                if ($foxgoNativeConversation) {
                                    $foxgoNativeConversationUserId = ((int) $foxgoNativeConversation->sender_id === 0)
                                        ? $foxgoNativeConversation->receiver_id
                                        : $foxgoNativeConversation->sender_id;
                                }
                            @endphp

                            <a
                                href="{{ route('admin.message.list', ['conversation' => $supportCase->conversation_id, 'user' => $foxgoNativeConversationUserId]) }}"
                                class="btn btn--primary btn-block"
                                target="_blank"
                            >
                                Abrir conversa nativa
                            </a>
                        @elseif($supportCase->customer_id)
                            <form method="POST" action="{{ route('admin.support.cases.conversation.customer', $supportCase->id) }}">
                                @csrf
                                <button type="submit" class="btn btn--primary btn-block">
                                    Criar/Vincular conversa com cliente
                                </button>
                            </form>
                        @else
                            <div class="alert alert-warning mb-0">
                                Este caso não possui cliente vinculado.
                            </div>
                        @endif
                    </div>
                </div>


                {{-- Fox GO V3B/V3E - Nina Atendente IA real com aprovação humana --}}
<div class="card mb-3 foxgo-nina-card">
    <div class="card-header">
        <h4 class="card-title mb-0">Nina Atendente</h4>
    </div>

    <div class="card-body">
        <p class="text-muted mb-3">
            A Nina Atendente analisa o caso, pedido, histórico, evidências e conversa vinculada para gerar uma resposta pronta ao cliente.
            A mensagem só é enviada após revisão e aprovação humana. A Nina não executa reembolso, estorno, repasse, Pagar.me, gateway de pagamento, cancelamento ou alteração de pedido.
        </p>

        <form id="foxgo-nina-guidance-form"
              method="POST"
              action="{{ route('admin.support.cases.nina.guidance', $supportCase->id) }}">
            @csrf

            <button type="submit" class="btn btn--primary btn-block">
                Gerar resposta da Nina
            </button>

            <small class="text-muted d-block mt-2">
                A Nina gera orientação interna e uma resposta sugerida para o cliente. Nenhuma mensagem é enviada automaticamente.
            </small>
        </form>

        @php
            $foxgoLatestNinaAction = \Illuminate\Support\Facades\DB::table('foxgo_support_case_actions')
                ->where('case_id', $supportCase->id)
                ->where('action_type', 'nina_guidance')
                ->orderByDesc('id')
                ->first();

            $foxgoNinaSuggestedCustomerMessage = '';

            if ($foxgoLatestNinaAction && !empty($foxgoLatestNinaAction->description)) {
                $foxgoNinaText = str_replace("\r", '', (string) $foxgoLatestNinaAction->description);

                $foxgoPatterns = [
                    '/###RESPOSTA_CLIENTE###(.*?)###FIM_RESPOSTA_CLIENTE###/isu',
                    '/6\.\s*(?:\*\*)?\s*RESPOSTA\s+PRONTA\s+PARA\s+O\s+CLIENTE\s*(?:\*\*)?\s*[:\-]?\s*(.+)$/isu',
                    '/6\.\s*(?:\*\*)?\s*Resposta\s+sugerida\s+para\s+o\s+atendente\s+copiar(?:,\s*se\s*fizer\s+sentido)?\s*(?:\*\*)?\s*[:\-]?\s*(.+)$/isu',
                ];

                foreach ($foxgoPatterns as $foxgoPattern) {
                    if (preg_match($foxgoPattern, $foxgoNinaText, $foxgoMatch)) {
                        $foxgoNinaSuggestedCustomerMessage = trim($foxgoMatch[1] ?? '');
                        break;
                    }
                }

                $foxgoNinaSuggestedCustomerMessage = preg_replace('/^\s*["“”\'`]+|["“”\'`]+\s*$/u', '', $foxgoNinaSuggestedCustomerMessage);
                $foxgoNinaSuggestedCustomerMessage = preg_replace('/\*\*/u', '', $foxgoNinaSuggestedCustomerMessage);
                $foxgoNinaSuggestedCustomerMessage = preg_replace('/^\s*[-•]\s*/u', '', $foxgoNinaSuggestedCustomerMessage);
                $foxgoNinaSuggestedCustomerMessage = trim($foxgoNinaSuggestedCustomerMessage);

                if (mb_strlen($foxgoNinaSuggestedCustomerMessage) > 1500) {
                    $foxgoNinaSuggestedCustomerMessage = mb_substr($foxgoNinaSuggestedCustomerMessage, 0, 1500);
                }
            }
        @endphp

        <hr>

        @if($supportCase->conversation_id)
            <form id="foxgo-nina-send-customer-form"
                  method="POST"
                  action="{{ route('admin.support.cases.nina.send-customer', $supportCase->id) }}">
                @csrf

                <div class="form-group">
                    <label for="foxgo_nina_customer_message" class="title-color font-weight-bold">
                        Resposta sugerida pela Nina para o cliente
                    </label>

                    <textarea id="foxgo_nina_customer_message"
                              name="nina_customer_message"
                              class="form-control"
                              rows="6"
                              maxlength="1500"
                              required
                              placeholder="Clique em Gerar resposta da Nina para preencher este campo automaticamente. Revise antes de enviar ao cliente.">{{ old('nina_customer_message', $foxgoNinaSuggestedCustomerMessage) }}</textarea>

                    <small class="text-muted">
                        Este é o texto exato que será enviado no chat nativo do cliente após aprovação humana.
                    </small>
                </div>

                <label class="d-flex align-items-start gap-2 mb-3" for="foxgo_nina_customer_approved">
                    <input type="checkbox"
                           id="foxgo_nina_customer_approved"
                           name="nina_customer_approved"
                           value="1"
                           class="mt-1"
                           required>

                    <span class="text-muted">
                        Revisei a resposta da Nina e confirmo que ela não promete reembolso, estorno, repasse, cancelamento aprovado, culpa de terceiros, Pagar.me, gateway de pagamento ou ação financeira.
                    </span>
                </label>

                <button type="submit" class="btn btn--primary btn-block">
                    Enviar resposta sugerida pela Nina ao cliente
                </button>
            </form>
        @else
            <div class="alert alert-warning mb-0">
                Para enviar resposta da Nina ao cliente, primeiro vincule a conversa nativa do cliente ao caso.
            </div>
        @endif
    </div>
</div>
{{-- Fox GO Fase 11 - comentario interno --}}
                <div class="card mb-3 foxgo-internal-note-card">
                    <div class="card-header">
                        <h4 class="card-title mb-0">Comentário interno</h4>
                    </div>
                    <div class="card-body">
                        <p class="text-muted mb-3">
                            Registre uma observação interna no histórico do caso.
                            Esta ação não envia mensagem ao cliente, loja ou entregador e não executa reembolso, Pagar.me ou gateway de pagamento ou repasses.
                        </p>

                        <form method="POST" action="{{ route('admin.support.cases.internal-note', $supportCase->id) }}">
                            @csrf

                            <div class="form-group">
                                <label>Comentário interno <span class="text-danger">*</span></label>
                                <textarea name="internal_note"
                                          class="form-control"
                                          rows="4"
                                          required
                                          placeholder="Digite uma observação interna para a equipe."></textarea>
                            </div>

                            <button type="submit" class="btn btn--primary btn-block">
                                Salvar comentário interno
                            </button>
                        </form>
                    </div>
                </div>
<div class="card-body">
                        <div class="mb-3">
                            <h6 class="text-muted">Pedido</h6>
                            <p class="mb-0">
                                @if($supportCase->order_id)
                                    #{{ $supportCase->order_id }}
                                @else
                                    —
                                @endif
                            </p>
                        </div>

                        <div class="mb-3">
                            <h6 class="text-muted">Cliente</h6>
                            <p class="mb-0">
                                {{ optional($supportCase->customer)->f_name ?? optional($supportCase->customer)->name ?? '—' }}
                            </p>
                        </div>

                        <div class="mb-3">
                            <h6 class="text-muted">Loja</h6>
                            <p class="mb-0">
                                {{ optional($supportCase->store)->name ?? '—' }}
                            </p>
                        </div>

                        <div class="mb-3">
                            <h6 class="text-muted">Entregador</h6>
                            <p class="mb-0">
                                {{ optional($supportCase->deliveryMan)->f_name ?? optional($supportCase->deliveryMan)->name ?? '—' }}
                            </p>
                        </div>

                        <div class="mb-3">
                            <h6 class="text-muted">Conversa</h6>
                            <p class="mb-0">
                                @if($supportCase->conversation_id)
                                    #{{ $supportCase->conversation_id }}
                                @else
                                    —
                                @endif
                            </p>
                        </div>

                        <div>
                            <h6 class="text-muted">Responsável</h6>
                            <p class="mb-0">
                                {{ optional($supportCase->assignedAdmin)->f_name ?? optional($supportCase->assignedAdmin)->name ?? '—' }}
                            </p>
                        </div>
                    </div>
                </div>

                
                {{-- Fox GO Fase 10 - status operacional do caso --}}
                <div class="card mb-3 foxgo-case-status-card">
                    <div class="card-header">
                        <h4 class="card-title mb-0">Ações do caso</h4>
                    </div>
                    <div class="card-body">
                        <p class="text-muted mb-3">
                            Atualize o status operacional do caso com observação interna obrigatória.
                            Esta ação não executa reembolso, Pagar.me ou gateway de pagamento ou repasses.
                        </p>

                        <form method="POST" action="{{ route('admin.support.cases.status', $supportCase->id) }}">
                            @csrf

                            <div class="form-group">
                                <label>Ação <span class="text-danger">*</span></label>
                                <select name="target_status" class="form-control" required>
                                    @if(in_array($supportCase->status, ['resolved', 'closed'], true))
                                        <option value="open">Reabrir caso</option>
                                    @else
                                        <option value="resolved">Resolver caso</option>
                                        <option value="closed">Fechar caso</option>
                                    @endif
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Observação interna <span class="text-danger">*</span></label>
                                <textarea name="internal_note"
                                          class="form-control"
                                          rows="4"
                                          required
                                          placeholder="Explique a decisão tomada, orientação dada ou motivo da reabertura/fechamento."></textarea>
                            </div>

                            <button type="submit" class="btn btn--primary btn-block">
                                Salvar status do caso
                            </button>
                        </form>
                    </div>
                </div>
<div class="card mb-4">
                    <div class="card-header">
                        <h4 class="card-title mb-0">Adicionar evidência</h4>
                    </div>

                    <div class="card-body">
                        <form method="POST" action="{{ route('admin.support.cases.evidence', $supportCase->id) }}" enctype="multipart/form-data">
                            @csrf

                            <div class="form-group">
                                <label>Tipo da evidência</label>
                                <select name="evidence_type" class="form-control">
                                    <option value="geral">Geral</option>
                                    <option value="foto">Foto</option>
                                    <option value="print">Print / captura de tela</option>
                                    <option value="documento">Documento</option>
                                    <option value="observacao">Observação interna</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Anexo opcional</label>
                                <input type="file" name="evidence_file" class="form-control" accept=".jpg,.jpeg,.png,.webp,.pdf,.txt">
                                <small class="text-muted">Aceita imagem, PDF ou TXT. Limite: 10 MB.</small>
                            </div>

                            <div class="form-group">
                                <label>Observação interna</label>
                                <textarea name="note" class="form-control" rows="4" placeholder="Descreva a evidência, contexto, informação do cliente, loja ou entregador."></textarea>
                            </div>

                            <button type="submit" class="btn btn--primary btn-block">
                                Salvar evidência
                            </button>
                        </form>
                    </div>
                </div>

                <div class="card mb-4">
                    <div class="card-header">
                        <h4 class="card-title mb-0">Transferir setor</h4>
                    </div>

                    <div class="card-body">
                        <form method="POST" action="{{ route('admin.support.cases.transfer', $supportCase->id) }}">
                            @csrf

                            <div class="form-group">
                                <label>Setor de destino</label>
                                <select name="to_department_id" class="form-control" required>
                                    <option value="">Selecionar setor</option>
                                    @foreach($departments as $department)
                                        <option value="{{ $department->id }}" {{ $supportCase->current_department_id == $department->id ? 'disabled' : '' }}>
                                            {{ $department->name }}
                                            {{ $supportCase->current_department_id == $department->id ? '(setor atual)' : '' }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Motivo</label>
                                <input type="text" name="reason" class="form-control" placeholder="Ex: análise de reembolso, financeiro, segurança">
                            </div>

                            <div class="form-group">
                                <label>Observação interna</label>
                                <textarea name="internal_note" class="form-control" rows="4" placeholder="Explique por que o caso está sendo transferido. Esta observação é interna."></textarea>
                            </div>

                            <button type="submit" class="btn btn--primary btn-block">
                                Transferir caso
                            </button>
                        </form>
                    </div>
                </div>

                <div class="alert alert-info">
                    <strong>Central de Suporte operacional interna:</strong> caso com pedido vinculado, status operacional, comentário interno, evidências, histórico visual, transferência de setor, trava por setor, conversa nativa com cliente e Nina Atendente com aprovação humana estão ativos. Reembolso, gateway de pagamento, Pagar.me e Repasses continuam sem execução automática nesta etapa.
                </div>
            </div>
        </div>
    </div>
@endsection
