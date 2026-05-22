@extends('layouts.admin.app')

@section('title', 'Novo caso de suporte')

@section('content')
@php
    $foxGoDepartments = $departments ?? $supportDepartments ?? collect();
@endphp

<div class="content container-fluid">
    <div class="page-header">
        <h1 class="page-header-title">Novo caso de suporte</h1>
        <p class="mb-0 text-muted">Criação operacional com pedido obrigatório, motivo e assunto.</p>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger">
            <strong>Corrija os campos abaixo:</strong>
            <ul class="mb-0 mt-2">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="card mb-3">
        <div class="card-header">
            <h5 class="mb-0">Buscar pedido</h5>
        </div>
        <div class="card-body">
            <form method="get" action="{{ route('admin.support.cases.create') }}">
                <div class="row align-items-end">
                    <div class="col-md-8">
                        <label class="form-label">Número do pedido</label>
                        <input type="text"
                               name="order_search"
                               value="{{ $orderSearch ?? request('order_search') }}"
                               class="form-control"
                               placeholder="Exemplo: 100002">
                        <small class="text-muted">
                            Sem busca, a lista mostra pedidos de hoje e ontem. Com busca, localiza pelo número exato do pedido.
                        </small>
                    </div>
                    <div class="col-md-4 mt-2">
                        <button type="submit" class="btn btn-primary w-100">Buscar pedido</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <form method="post" action="{{ route('admin.support.cases.store') }}">
        <input type="hidden" name="status" value="open">
        @csrf

        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Dados do caso</h5>
            </div>

            <div class="card-body">
                <div class="row">
                    <div class="col-md-12 mb-3">
                        <label class="form-label">Pedido vinculado <span class="text-danger">*</span></label>
                        <select name="order_id" class="form-control" required>
                            <option value="">Selecione um pedido</option>
                            @foreach (($recentOrders ?? []) as $order)
                                <option value="{{ $order->id }}"
                                    {{ (string) old('order_id', request('order_search')) === (string) $order->id ? 'selected' : '' }}>
                                    #{{ $order->id }}
                                    —
                                    {{ $order->created_at }}
                                    —
                                    {{ $order->store_name ?: ('Loja #' . ($order->store_id ?? '-')) }}
                                    —
                                    Status: {{ $order->order_status ?? '-' }}
                                    /
                                    Pagamento: {{ $order->payment_status ?? '-' }}
                                    —
                                    R$ {{ number_format((float) ($order->order_amount ?? 0), 2, ',', '.') }}
                                </option>
                            @endforeach
                        </select>
                        <small class="text-muted">O caso só pode ser criado com pedido vinculado.</small>
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label">Setor responsável <span class="text-danger">*</span></label>
                        <select name="department_id" class="form-control" required>
                            <option value="">Selecione o setor</option>
                            @foreach ($foxGoDepartments as $department)
                                <option value="{{ $department->id }}"
                                    {{ (string) old('department_id') === (string) $department->id ? 'selected' : '' }}>
                                    {{ $department->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label">Prioridade <span class="text-danger">*</span></label>
                        <select name="priority" class="form-control" required>
                            <option value="low" {{ old('priority', 'low') === 'low' ? 'selected' : '' }}>Baixa</option>
                            <option value="normal" {{ old('priority') === 'normal' ? 'selected' : '' }}>Normal</option>
                            <option value="high" {{ old('priority') === 'high' ? 'selected' : '' }}>Alta</option>
                            <option value="urgent" {{ old('priority') === 'urgent' ? 'selected' : '' }}>Urgente</option>
                        </select>
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label">Motivo <span class="text-danger">*</span></label>
                        <input type="text"
                               name="reason"
                               value="{{ old('reason') }}"
                               class="form-control"
                               required
                               maxlength="255"
                               placeholder="Exemplo: Reembolso, atraso, cobrança, repasse">
                    </div>

                    <div class="col-md-6 mb-3">
                        <label class="form-label">Assunto <span class="text-danger">*</span></label>
                        <input type="text"
                               name="subject"
                               value="{{ old('subject') }}"
                               class="form-control"
                               required
                               maxlength="255"
                               placeholder="Resumo curto do problema">
                    </div>

                    <div class="col-md-12 mb-3">
                        <label class="form-label">Descrição <span class="text-danger">*</span></label>
                        <textarea name="description"
                                  class="form-control"
                                  rows="5"
                                  placeholder="Detalhe o que aconteceu no pedido" required>{{ old('description') }}</textarea>
                    </div>
                </div>
            </div>

            <div class="card-footer d-flex justify-content-end">
                <a href="{{ route('admin.support.cases') }}" class="btn btn-secondary mr-2">Voltar</a>
                <button type="submit" class="btn btn-primary">Criar caso</button>
            </div>
        </div>
    </form>
</div>
@endsection