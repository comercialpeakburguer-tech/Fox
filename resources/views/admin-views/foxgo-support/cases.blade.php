@extends('layouts.admin.app')

@section('title', 'Casos da Central de Suporte')

@section('content')
    <div class="content container-fluid">
        <div class="page-header">
            <div class="d-flex flex-wrap justify-content-between align-items-center">
                <div>
                    <h1 class="page-header-title mb-1">Casos da Central de Suporte</h1>
                    <p class="text-muted mb-0">
                        Listagem operacional da Central de Suporte. Esta tela organiza casos por setor, status, prioridade, pedido, cliente, loja e responsável.
                    </p>
                </div>
                <div class="mt-2 mt-sm-0">
                    <a href="{{ route('admin.support.cases.create') }}" class="btn btn--primary mr-2">
                        Novo caso
                    </a>
                    <a href="{{ route('admin.support.index') }}" class="btn btn--secondary">
                        Visão geral
                    </a>
                </div>
            </div>
        </div>

        <div class="card mb-4">
            <div class="card-body">
                <form method="GET" action="{{ route('admin.support.cases') }}">
                    <div class="row g-3 align-items-end">
                        <div class="col-md-3">
                            <label class="form-label">Setor</label>
                            <select name="department_id" class="form-control">
                                <option value="">Todos os setores</option>
                                @foreach($departments as $department)
                                    <option value="{{ $department->id }}" {{ (string) request('department_id') === (string) $department->id ? 'selected' : '' }}>
                                        {{ $department->name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <div class="col-md-3">
                            <label class="form-label">Status</label>
                            <select name="status" class="form-control">
                                <option value="">Todos os status</option>
                                @foreach($statuses as $value => $label)
                                    <option value="{{ $value }}" {{ request('status') === $value ? 'selected' : '' }}>
                                        {{ $label }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <div class="col-md-3">
                            <label class="form-label">Prioridade</label>
                            <select name="priority" class="form-control">
                                <option value="">Todas as prioridades</option>
                                @foreach($priorities as $value => $label)
                                    <option value="{{ $value }}" {{ request('priority') === $value ? 'selected' : '' }}>
                                        {{ $label }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <div class="col-md-3">
                            <label class="form-label">Buscar</label>
                            <input type="text" name="search" value="{{ request('search') }}" class="form-control" placeholder="Protocolo, pedido, assunto ou motivo">
                        </div>

                        <div class="col-12 d-flex justify-content-end gap-2">
                            <a href="{{ route('admin.support.cases') }}" class="btn btn--secondary">
                                Limpar
                            </a>
                            <button type="submit" class="btn btn--primary">
                                Filtrar
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-header d-flex flex-wrap justify-content-between align-items-center">
                <h4 class="card-title mb-0">Lista de casos</h4>
                <span class="badge badge-soft-info">
                    Total filtrado: {{ $cases->total() }}
                </span>
            </div>

            <div class="table-responsive">
                <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                    <thead class="thead-light">
                        <tr>
                            <th>Protocolo</th>
                            <th>Setor</th>
                            <th>Pedido</th>
                            <th>Cliente</th>
                            <th>Loja</th>
                            <th>Entregador</th>
                            <th>Status</th>
                            <th>Prioridade</th>
                            <th>Responsável</th>
                            <th>Criado em</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($cases as $case)
                            <tr>
                                <td>
                                    <a href="{{ route('admin.support.cases.show', $case->id) }}" class="font-weight-bold">
                                        {{ $case->protocol }}
                                    </a>
                                    @if($case->subject)
                                        <div class="text-muted small">{{ $case->subject }}</div>
                                    @endif
                                </td>
                                <td>{{ optional($case->department)->name ?? 'Sem setor' }}</td>
                                <td>
                                    @if($case->order_id)
                                        #{{ $case->order_id }}
                                    @else
                                        —
                                    @endif
                                </td>
                                <td>{{ optional($case->customer)->f_name ?? optional($case->customer)->name ?? '—' }}</td>
                                <td>{{ optional($case->store)->name ?? '—' }}</td>
                                <td>{{ optional($case->deliveryMan)->f_name ?? optional($case->deliveryMan)->name ?? '—' }}</td>
                                <td>
                                    <span class="badge badge-soft-warning">
                                        {{ $statuses[$case->status] ?? ucfirst(str_replace('_', ' ', $case->status)) }}
                                    </span>
                                </td>
                                <td>
                                    <span class="badge badge-soft-primary">
                                        {{ $priorities[$case->priority] ?? ucfirst(str_replace('_', ' ', $case->priority)) }}
                                    </span>
                                </td>
                                <td>{{ optional($case->assignedAdmin)->f_name ?? optional($case->assignedAdmin)->name ?? '—' }}</td>
                                <td>{{ optional($case->created_at)->format('d/m/Y H:i') ?? '—' }}</td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="10">
                                    <div class="text-center text-muted py-5">
                                        Nenhum caso encontrado. A base da Central de Suporte está pronta, mas ainda não há casos abertos.
                                    </div>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            @if($cases->hasPages())
                <div class="card-footer">
                    {{ $cases->links() }}
                </div>
            @endif
        </div>

        <div class="alert alert-info mt-4">
            <strong>Central de Suporte operacional interna:</strong> criação de caso, filtros, detalhe, status, comentários internos, evidências, histórico, transferência de setor, conversa nativa com cliente e Nina Atendente estão ativos. Reembolso, gateway de pagamento, Pagar.me e Repasses continuam sem execução automática nesta etapa.
        </div>
    </div>
@endsection
