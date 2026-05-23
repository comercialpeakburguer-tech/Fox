@extends('layouts.admin.app')

@section('title', 'Fox GO V3.9')

@section('content')
<div class="content container-fluid">
    <div class="page-header">
        <div class="d-flex flex-wrap justify-content-between align-items-center">
            <div>
                <h1 class="page-header-title mb-1">Central Fox GO V3.9</h1>
                <p class="text-muted mb-0">Painel de auditoria e configuração das funções novas que alimentam os apps.</p>
            </div>
            <div class="mt-2 mt-sm-0">
                <span class="badge badge-soft-success p-2">Backend/API ativo</span>
            </div>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-sm-6 col-lg-3">
            <div class="card h-100">
                <div class="card-body">
                    <h6 class="text-muted">Reels cadastrados</h6>
                    <h2 class="mb-0">{{ $stats['reels_total'] }}</h2>
                    <small class="text-success">{{ $stats['reels_active'] }} ativos</small>
                </div>
            </div>
        </div>

        <div class="col-sm-6 col-lg-3">
            <div class="card h-100">
                <div class="card-body">
                    <h6 class="text-muted">Lojas verificadas</h6>
                    <h2 class="mb-0">{{ $stats['verified_stores'] }}</h2>
                    <small class="text-muted">Selo usado nos apps</small>
                </div>
            </div>
        </div>

        <div class="col-sm-6 col-lg-3">
            <div class="card h-100">
                <div class="card-body">
                    <h6 class="text-muted">Produtos em baixo estoque</h6>
                    <h2 class="mb-0">{{ $stats['low_stock_items'] }}</h2>
                    <small class="text-muted">Baseado no limite por item</small>
                </div>
            </div>
        </div>

        <div class="col-sm-6 col-lg-3">
            <div class="card h-100">
                <div class="card-body">
                    <h6 class="text-muted">Status da V3.9</h6>
                    <h2 class="mb-0">OK</h2>
                    <small class="text-success">Banco + rotas carregando</small>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-lg-6">
            <div class="card h-100">
                <div class="card-header">
                    <h4 class="card-title mb-0">Banco e colunas</h4>
                </div>
                <div class="card-body">
                    @foreach($tables as $name => $ok)
                        <div class="d-flex justify-content-between border-bottom py-2">
                            <span>{{ $name }}</span>
                            <span class="badge {{ $ok ? 'badge-soft-success' : 'badge-soft-danger' }}">{{ $ok ? 'OK' : 'Falta' }}</span>
                        </div>
                    @endforeach

                    <hr>

                    @foreach($columns as $name => $ok)
                        <div class="d-flex justify-content-between border-bottom py-2">
                            <span>{{ $name }}</span>
                            <span class="badge {{ $ok ? 'badge-soft-success' : 'badge-soft-danger' }}">{{ $ok ? 'OK' : 'Falta' }}</span>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>

        <div class="col-lg-6">
            <div class="card h-100">
                <div class="card-header">
                    <h4 class="card-title mb-0">Rotas/API usadas pelos apps</h4>
                </div>
                <div class="card-body">
                    @foreach($apiRoutes as $name => $ok)
                        <div class="d-flex justify-content-between border-bottom py-2">
                            <span>{{ $name }}</span>
                            <span class="badge {{ $ok ? 'badge-soft-success' : 'badge-soft-danger' }}">{{ $ok ? 'Ativa' : 'Falta' }}</span>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>
    </div>

    <div class="card mb-4">
        <div class="card-header">
            <h4 class="card-title mb-0">Criar Reel por link</h4>
        </div>
        <div class="card-body">
            <form action="{{ route('admin.foxgo-v39.reels.store') }}" method="post">
                @csrf
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label">Loja</label>
                        <select name="store_id" class="form-control" required>
                            <option value="">Selecione</option>
                            @foreach($stores as $store)
                                <option value="{{ $store->id }}">{{ $store->name }} {{ $store->is_verified ? '✅' : '' }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div class="col-md-3">
                        <label class="form-label">ID do produto opcional</label>
                        <input type="number" name="item_id" class="form-control" placeholder="Ex: 10">
                    </div>

                    <div class="col-md-3">
                        <label class="form-label">Título</label>
                        <input type="text" name="title" class="form-control" placeholder="Ex: Promoção do dia">
                    </div>

                    <div class="col-md-2">
                        <label class="form-label">Ordem</label>
                        <input type="number" name="sort_order" class="form-control" value="0">
                    </div>

                    <div class="col-md-8">
                        <label class="form-label">Link do vídeo</label>
                        <input type="text" name="video_link" class="form-control" required placeholder="https://...">
                    </div>

                    <div class="col-md-2">
                        <label class="form-label">Status</label>
                        <select name="status" class="form-control">
                            <option value="1">Ativo</option>
                            <option value="0">Inativo</option>
                        </select>
                    </div>

                    <div class="col-md-2 d-flex align-items-end">
                        <button class="btn btn--primary w-100" type="submit">Salvar Reel</button>
                    </div>

                    <div class="col-12">
                        <label class="form-label">Descrição opcional</label>
                        <textarea name="description" class="form-control" rows="2"></textarea>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-lg-7">
            <div class="card h-100">
                <div class="card-header">
                    <h4 class="card-title mb-0">Reels cadastrados</h4>
                </div>
                <div class="table-responsive">
                    <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Loja</th>
                                <th>Título</th>
                                <th>Status</th>
                                <th class="text-right">Ações</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($reels as $reel)
                                <tr>
                                    <td>#{{ $reel->id }}</td>
                                    <td>{{ $reel->store?->name ?? 'Sem loja' }}</td>
                                    <td>{{ $reel->title ?? 'Sem título' }}</td>
                                    <td>
                                        <span class="badge {{ $reel->status ? 'badge-soft-success' : 'badge-soft-danger' }}">
                                            {{ $reel->status ? 'Ativo' : 'Inativo' }}
                                        </span>
                                    </td>
                                    <td class="text-right">
                                        <form action="{{ route('admin.foxgo-v39.reels.status', $reel->id) }}" method="post" class="d-inline">
                                            @csrf
                                            <input type="hidden" name="status" value="{{ $reel->status ? 0 : 1 }}">
                                            <button class="btn btn-sm btn-outline-primary" type="submit">
                                                {{ $reel->status ? 'Desativar' : 'Ativar' }}
                                            </button>
                                        </form>

                                        <form action="{{ route('admin.foxgo-v39.reels.destroy', $reel->id) }}" method="post" class="d-inline" onsubmit="return confirm('Remover este Reel?')">
                                            @csrf
                                            @method('DELETE')
                                            <button class="btn btn-sm btn-outline-danger" type="submit">Apagar</button>
                                        </form>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="text-center text-muted py-4">Nenhum Reel cadastrado ainda.</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                <div class="card-footer">
                    {{ $reels->links() }}
                </div>
            </div>
        </div>

        <div class="col-lg-5">
            <div class="card h-100">
                <div class="card-header">
                    <h4 class="card-title mb-0">Loja verificada</h4>
                </div>
                <div class="card-body">
                    <p class="text-muted">Marque uma loja como verificada para alimentar selo/credibilidade nos apps.</p>

                    @foreach($stores->take(60) as $store)
                        <div class="d-flex justify-content-between align-items-center border-bottom py-2">
                            <div>
                                <strong>{{ $store->name }}</strong>
                                <br>
                                <small class="text-muted">ID {{ $store->id }}</small>
                            </div>

                            <form action="{{ route('admin.foxgo-v39.store.verification', $store->id) }}" method="post">
                                @csrf
                                <input type="hidden" name="is_verified" value="{{ $store->is_verified ? 0 : 1 }}">
                                <button class="btn btn-sm {{ $store->is_verified ? 'btn-outline-danger' : 'btn-outline-success' }}" type="submit">
                                    {{ $store->is_verified ? 'Remover selo' : 'Verificar' }}
                                </button>
                            </form>
                        </div>
                    @endforeach

                    @if($stores->isEmpty())
                        <div class="text-center text-muted py-4">Nenhuma loja encontrada.</div>
                    @endif
                </div>
            </div>
        </div>
    </div>

    <div class="alert alert-info">
        <strong>Resumo para leigos:</strong> esta tela é a central da atualização. Ela mostra se a base técnica está ativa e permite começar a configurar Reels e lojas verificadas. A próxima etapa é ligar os campos de vídeo/estoque baixo diretamente nas telas de produto e depois sincronizar os 3 apps.
    </div>
</div>
@endsection
