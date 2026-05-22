@extends('layouts.admin.app')

@section('title', 'Corrigir verificação Stripe')

@section('content')
    <div class="content container-fluid">
        <div class="page-header">
            <h1 class="page-header-title">
                Corrigir verificação Stripe Connect
            </h1>
            <p class="mb-0">
                Loja #{{ $store->id }} — {{ $store->name }}
            </p>
        </div>

        @php
            $requirements = $stripePayload['requirements'] ?? [];
            $foxgoStripeErrors = $requirements['errors'] ?? [];
            $currentlyDue = $requirements['currently_due'] ?? [];
            $pastDue = $requirements['past_due'] ?? [];
            $disabledReason = $requirements['disabled_reason'] ?? null;

            $birthDate = old('birth_date', $receivingFields['foxgo_representative_birth_date'] ?? '');
            $cpf = old('cpf', $receivingFields['foxgo_representative_cpf'] ?? '');
            $addressLine1 = old('address_line1', $receivingFields['foxgo_representative_address_line1'] ?? '');
            $addressCity = old('address_city', $receivingFields['foxgo_representative_address_city'] ?? '');
            $addressState = old('address_state', $receivingFields['foxgo_representative_address_state'] ?? '');
            $addressPostalCode = old('address_postal_code', $receivingFields['foxgo_representative_address_postal_code'] ?? '');
        @endphp

        <div class="alert alert-warning">
            <strong>⚠️ Status atual:</strong>
            @if(($vendor->stripe_connect_status ?? null) === 'pending_verification')
                Em análise pela Stripe
            @elseif(($vendor->stripe_connect_status ?? null) === 'verification_error')
                Documento/identidade reprovado
            @elseif(($vendor->stripe_connect_status ?? null) === 'active')
                Ativo/liberado
            @else
                Verificação pendente
            @endif<br>
            <strong>Conta Stripe:</strong> {{ $vendor->stripe_account_id }}<br>

            @if($disabledReason)
                <strong>Situação:</strong>
                @if($disabledReason === 'requirements.pending_verification')
                    Documento enviado e aguardando análise da Stripe.
                @elseif($disabledReason === 'requirements.past_due')
                    Ação vencida: a Stripe ainda precisa de correção/documento.
                @else
                    {{ $disabledReason }}
                @endif
                <br>
            @endif

            @if(!empty($currentlyDue))
                <strong>Pendente:</strong> {{ implode(', ', $currentlyDue) }}<br>
            @endif

            @if(!empty($pastDue))
                <strong>Vencido:</strong> {{ implode(', ', $pastDue) }}<br>
            @endif

            @if(!empty($foxgoStripeErrors))
                @foreach($foxgoStripeErrors as $error)
                    <strong>Motivo:</strong>
                    @if(($error['code'] ?? null) === 'verification_failed_keyed_identity')
                        Documento/identidade reprovado pela Stripe. Os dados digitados não bateram com a verificação. Corrija nome, CPF/documento, data de nascimento, endereço e envie documento válido.
                    @else
                        {{ $error['reason'] ?? $error['code'] ?? 'Erro de verificação Stripe.' }}
                    @endif
                    <br>
                @endforeach
            @endif
        </div>

        
        <form action="{{ route('admin.store.foxgo-stripe-verification-refresh', $store->id) }}" method="POST" class="mb-3">
            @csrf
            <button type="submit" class="btn btn-outline-primary">
                Atualizar status Stripe
            </button>
            <small class="ml-2 text-muted">
                Consulta a Stripe agora e atualiza este painel.
            </small>
        </form>

        <div class="card">
            <div class="card-body">
                <form action="{{ route('admin.store.foxgo-stripe-verification-submit', $store->id) }}" method="POST" enctype="multipart/form-data">
                    @csrf

                    <h4 class="mb-3">Dados do responsável legal</h4>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label>Nome</label>
                            <input type="text" name="first_name" class="form-control" value="{{ old('first_name', $vendor->f_name) }}" required>
                        </div>

                        <div class="col-md-6 mb-3">
                            <label>Sobrenome</label>
                            <input type="text" name="last_name" class="form-control" value="{{ old('last_name', $vendor->l_name) }}" required>
                        </div>

                        <div class="col-md-4 mb-3">
                            <label>CPF/documento</label>
                            <input type="text" name="cpf" class="form-control" value="{{ $cpf }}" required>
                        </div>

                        <div class="col-md-4 mb-3">
                            <label>Data de nascimento</label>
                            <input type="date" name="birth_date" class="form-control" value="{{ $birthDate }}" required>
                        </div>

                        <div class="col-md-4 mb-3">
                            <label>Telefone</label>
                            <input type="text" name="phone" class="form-control" value="{{ old('phone', $vendor->phone) }}" required>
                        </div>

                        <div class="col-md-6 mb-3">
                            <label>Endereço</label>
                            <input type="text" name="address_line1" class="form-control" value="{{ $addressLine1 }}" required>
                        </div>

                        <div class="col-md-3 mb-3">
                            <label>Cidade</label>
                            <input type="text" name="address_city" class="form-control" value="{{ $addressCity }}" required>
                        </div>

                        <div class="col-md-1 mb-3">
                            <label>UF</label>
                            <input type="text" name="address_state" class="form-control" value="{{ $addressState }}" maxlength="2" required>
                        </div>

                        <div class="col-md-2 mb-3">
                            <label>CEP</label>
                            <input type="text" name="address_postal_code" class="form-control" value="{{ $addressPostalCode }}" required>
                        </div>
                    </div>

                    <hr>

                    <h4 class="mb-3">Documento oficial</h4>

                    <div class="alert alert-info">
                        Envie documento real, legível e compatível com os dados acima. Em produção, os dados precisam bater exatamente com o responsável legal.
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label>Documento — frente</label>
                            <input type="file" name="document_front" class="form-control" accept=".jpg,.jpeg,.png,.pdf" required>
                        </div>

                        <div class="col-md-6 mb-3">
                            <label>Documento — verso, se houver</label>
                            <input type="file" name="document_back" class="form-control" accept=".jpg,.jpeg,.png,.pdf">
                        </div>
                    </div>

                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn--primary">
                            Reenviar para Stripe
                        </button>

                        <a href="{{ route('admin.store.pending-requests') }}" class="btn btn--secondary">
                            Voltar
                        </a>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection
