@extends('layouts.admin.app')

@section('title', 'Central de Suporte')

@section('content')
    <div class="content container-fluid">
        <div class="page-header">
            <div class="d-flex flex-wrap justify-content-between align-items-center">
                <div>
                    <h1 class="page-header-title mb-1">Central de Suporte Fox GO</h1>
                    <p class="text-muted mb-0">
                        Base operacional separada por setores, com casos, pedido vinculado, histórico, conversa nativa e Nina Atendente com aprovação humana.
                    </p>
                </div>
                <div class="mt-2 mt-sm-0">
                    <a href="{{ route('admin.support.cases') }}" class="btn btn--primary">
                        Ver casos
                    </a>
                    <a href="{{ route('admin.support.cases.create') }}" class="btn btn--secondary ml-2">Novo caso</a>
                    <a href="{{ route('admin.support.team') }}" class="btn btn-outline-primary ml-2">Equipe</a>
                    <span class="badge badge-soft-success p-2 ml-2">Operação interna ativa</span>
                </div>
            </div>
        </div>

        <div class="row g-3 mb-4">
            <div class="col-sm-6 col-lg-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h6 class="text-muted mb-2">Total de casos</h6>
                        <h2 class="mb-0">{{ $stats['total_cases'] }}</h2>
                    </div>
                </div>
            </div>

            <div class="col-sm-6 col-lg-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h6 class="text-muted mb-2">Casos em aberto</h6>
                        <h2 class="mb-0">{{ $stats['open_cases'] }}</h2>
                    </div>
                </div>
            </div>

            <div class="col-sm-6 col-lg-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h6 class="text-muted mb-2">Central de Reembolsos</h6>
                        <h2 class="mb-0">{{ $stats['refund_cases'] }}</h2>
                    </div>
                </div>
            </div>

            <div class="col-sm-6 col-lg-3">
                <div class="card h-100">
                    <div class="card-body">
                        <h6 class="text-muted mb-2">Segurança / Emergência</h6>
                        <h2 class="mb-0">{{ $stats['emergency_cases'] }}</h2>
                    </div>
                </div>
            </div>
        </div>

        <div class="card mb-4">
            <div class="card-header">
                <h4 class="card-title mb-0">Setores da Central de Suporte</h4>
            </div>
            <div class="card-body">
                <div class="row g-3">
                    @foreach($departments as $department)
                        <div class="col-md-6 col-xl-4">
                            <div class="border rounded p-3 h-100 bg-white">
                                <div class="d-flex justify-content-between align-items-start mb-2">
                                    <div>
                                        <h5 class="mb-1">{{ $department->name }}</h5>
                                        <small class="text-muted">{{ $department->slug }}</small>
                                    </div>

                                    @if($department->is_active)
                                        <span class="badge badge-soft-success">Ativo</span>
                                    @else
                                        <span class="badge badge-soft-danger">Inativo</span>
                                    @endif
                                </div>

                                <p class="text-muted mb-3">{{ $department->description }}</p>

                                <div class="d-flex flex-wrap gap-2">
                                    <span class="badge badge-soft-primary">
                                        Total: {{ $department->total_cases_count }}
                                    </span>
                                    <span class="badge badge-soft-warning">
                                        Abertos: {{ $department->open_cases_count }}
                                    </span>
                                    <span class="badge badge-soft-danger">
                                        Urgentes: {{ $department->urgent_cases_count }}
                                    </span>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>

                @if($departments->isEmpty())
                    <div class="text-center text-muted py-5">
                        Nenhum setor de suporte cadastrado.
                    </div>
                @endif
            </div>
        </div>

        <div class="alert alert-info">
            <strong>Central de Suporte operacional interna:</strong> visão geral, listagem de casos, filtros por setor, criação de caso com pedido vinculado, status operacional, comentário interno, evidências, histórico, transferência de setor, conversa nativa com cliente e Nina Atendente com aprovação humana estão ativos. Reembolso, gateway de pagamento, Pagar.me e Repasses continuam sem execução automática nesta etapa.
        </div>
    </div>
@endsection
