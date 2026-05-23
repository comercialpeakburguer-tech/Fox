@extends('layouts.vendor.app')

@section('title', 'Reels Fox GO')

@section('content')
<div class="content container-fluid">
    <div class="page-header">
        <h1 class="page-header-title">Reels Fox GO</h1>
        <p class="mb-0 text-muted">
            Crie vídeos curtos da sua loja/produto para aparecer no app cliente e nas áreas de descoberta.
        </p>
    </div>

    <div class="card mb-4">
        <div class="card-header">
            <h5 class="card-title mb-0">Novo Reel</h5>
        </div>
        <div class="card-body">
            <form action="{{ route('vendor.foxgo-catalog.reels.store') }}" method="post" enctype="multipart/form-data">
                @csrf
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="input-label">Produto opcional</label>
                        <select name="item_id" class="form-control">
                            <option value="">Sem produto vinculado</option>
                            @foreach($items as $item)
                                <option value="{{ $item->id }}">{{ $item->name }} — #{{ $item->id }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label class="input-label">Título</label>
                        <input type="text" name="title" class="form-control" maxlength="191" placeholder="Ex.: Combo especial de hoje">
                    </div>

                    <div class="col-md-2">
                        <label class="input-label">Ordem</label>
                        <input type="number" name="sort_order" class="form-control" value="0" min="0">
                    </div>

                    <div class="col-md-2">
                        <label class="input-label">Status</label>
                        <select name="status" class="form-control">
                            <option value="1">Ativo</option>
                            <option value="0">Inativo</option>
                        </select>
                    </div>

                    <div class="col-md-6">
                        <label class="input-label">Link do vídeo</label>
                        <input type="text" name="video_link" class="form-control" placeholder="https://...">
                        <small class="text-muted">Use link externo ou envie arquivo de vídeo abaixo.</small>
                    </div>

                    <div class="col-md-3">
                        <label class="input-label">Thumbnail</label>
                        <input type="file" name="thumbnail" class="form-control" accept="image/*">
                    </div>

                    <div class="col-md-3">
                        <label class="input-label">Vídeo</label>
                        <input type="file" name="video" class="form-control" accept="video/mp4,video/webm,video/quicktime">
                    </div>

                    <div class="col-12">
                        <label class="input-label">Descrição</label>
                        <textarea name="description" class="form-control" rows="2" placeholder="Descrição opcional do Reel"></textarea>
                    </div>

                    <div class="col-12">
                        <button class="btn btn--primary" type="submit">Salvar Reel</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <div class="card">
        <div class="card-header">
            <h5 class="card-title mb-0">Meus Reels</h5>
        </div>

        <div class="table-responsive">
            <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Prévia</th>
                        <th>Título</th>
                        <th>Produto</th>
                        <th>Status</th>
                        <th class="text-right">Ações</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($reels as $reel)
                        <tr>
                            <td>#{{ $reel->id }}</td>
                            <td>
                                @if($reel->thumbnail_full_url)
                                    <img src="{{ $reel->thumbnail_full_url }}" style="width:64px;height:64px;object-fit:cover;border-radius:8px;" alt="thumbnail">
                                @else
                                    <span class="badge badge-soft-secondary">Sem imagem</span>
                                @endif
                            </td>
                            <td>
                                <strong>{{ $reel->title ?? 'Sem título' }}</strong>
                                @if($reel->video_link)
                                    <br><small><a href="{{ $reel->video_link }}" target="_blank">Ver link</a></small>
                                @elseif($reel->video_full_url)
                                    <br><small><a href="{{ $reel->video_full_url }}" target="_blank">Ver vídeo</a></small>
                                @endif
                            </td>
                            <td>{{ $reel->item?->name ?? 'Sem produto' }}</td>
                            <td>
                                <span class="badge {{ $reel->status ? 'badge-soft-success' : 'badge-soft-danger' }}">
                                    {{ $reel->status ? 'Ativo' : 'Inativo' }}
                                </span>
                            </td>
                            <td class="text-right">
                                <form action="{{ route('vendor.foxgo-catalog.reels.status', $reel->id) }}" method="post" class="d-inline">
                                    @csrf
                                    <input type="hidden" name="status" value="{{ $reel->status ? 0 : 1 }}">
                                    <button class="btn btn-sm btn-outline-primary" type="submit">
                                        {{ $reel->status ? 'Desativar' : 'Ativar' }}
                                    </button>
                                </form>

                                <form action="{{ route('vendor.foxgo-catalog.reels.destroy', $reel->id) }}" method="post" class="d-inline" onsubmit="return confirm('Apagar este Reel?')">
                                    @csrf
                                    @method('DELETE')
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Apagar</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="text-center text-muted py-4">Nenhum Reel cadastrado ainda.</td>
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
@endsection
