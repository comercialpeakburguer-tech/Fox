@extends('layouts.vendor.app')

@section('title', 'Meu Catálogo')

@section('content')
<div class="content container-fluid">
    <div class="page-header">
        <h1 class="page-header-title">
            <span>Meu Catálogo</span>
        </h1>
        <p class="mb-0 text-muted">
            Organize categorias, subcategorias e marcas/linhas próprias da sua loja.
        </p>
    </div>

    <div class="row g-3">
        <div class="col-lg-4">
            <div class="card h-100">
                <div class="card-header"><h5 class="card-title mb-0">Nova categoria da loja</h5></div>
                <div class="card-body">
                    <form action="{{ route('vendor.foxgo-catalog.category.store') }}" method="post">
                        @csrf
                        <input type="hidden" name="parent_id" value="0">
                        <div class="form-group">
                            <label class="input-label">Nome da categoria</label>
                            <input type="text" name="name" class="form-control" maxlength="191" required placeholder="Ex.: Hambúrgueres, Bebidas, Combos">
                        </div>
                        <div class="btn--container justify-content-end">
                            <button type="submit" class="btn btn--primary">Adicionar categoria</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card h-100">
                <div class="card-header"><h5 class="card-title mb-0">Nova subcategoria</h5></div>
                <div class="card-body">
                    <form action="{{ route('vendor.foxgo-catalog.category.store') }}" method="post">
                        @csrf
                        <div class="form-group">
                            <label class="input-label">Categoria principal</label>
                            <select name="parent_id" class="form-control" required>
                                <option value="" selected disabled>Selecione</option>
                                @foreach($categories as $parent)
                                    <option value="{{ $parent->id }}">{{ $parent->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="input-label">Nome da subcategoria</label>
                            <input type="text" name="name" class="form-control" maxlength="191" required placeholder="Ex.: Artesanais, Refrigerantes, Porções">
                        </div>
                        <div class="btn--container justify-content-end">
                            <button type="submit" class="btn btn--primary">Adicionar subcategoria</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card h-100">
                <div class="card-header"><h5 class="card-title mb-0">Nova marca/linha da loja</h5></div>
                <div class="card-body">
                    <form action="{{ route('vendor.foxgo-catalog.brand.store') }}" method="post">
                        @csrf
                        <div class="form-group">
                            <label class="input-label">Nome da marca ou linha</label>
                            <input type="text" name="name" class="form-control" maxlength="191" required placeholder="Ex.: Coca-Cola, Linha artesanal">
                        </div>
                        <div class="btn--container justify-content-end">
                            <button type="submit" class="btn btn--primary">Adicionar marca/linha</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-3 mt-2">
        <div class="col-lg-4">
            <div class="card">
                <div class="card-header py-2"><h5 class="card-title mb-0">Categorias <span class="badge badge-soft-dark ml-1">{{ $categories->count() }}</span></h5></div>
                <div class="table-responsive">
                    <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                        <thead class="thead-light"><tr><th>Nome</th><th>Status</th><th class="text-center">Ação</th></tr></thead>
                        <tbody>
                        @forelse($categories as $category)
                            <tr>
                                <td>
                                    <form action="{{ route('vendor.foxgo-catalog.category.update', $category->id) }}" method="post" class="d-flex">
                                        @csrf
                                        <input type="hidden" name="parent_id" value="0">
                                        <input type="text" name="name" class="form-control form-control-sm" value="{{ $category->name }}" required>
                                        <button class="btn btn-sm btn--primary ml-1" type="submit">Salvar</button>
                                    </form>
                                </td>
                                <td><span class="badge {{ $category->is_enabled ? 'badge-soft-success' : 'badge-soft-danger' }}">{{ $category->is_enabled ? 'Ativa' : 'Inativa' }}</span></td>
                                <td>
                                    <div class="btn--container justify-content-center">
                                        <a class="btn btn-sm action-btn btn-outline-info" href="{{ route('vendor.foxgo-catalog.category.status', [$category->id, $category->is_enabled ? 0 : 1]) }}">Status</a>
                                        <form action="{{ route('vendor.foxgo-catalog.category.delete', $category->id) }}" method="post">@csrf @method('delete')<button type="submit" class="btn btn-sm action-btn btn-outline-danger">Excluir</button></form>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr><td colspan="3" class="text-center text-muted">Nenhuma categoria criada.</td></tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card">
                <div class="card-header py-2"><h5 class="card-title mb-0">Subcategorias <span class="badge badge-soft-dark ml-1">{{ $subcategories->count() }}</span></h5></div>
                <div class="table-responsive">
                    <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                        <thead class="thead-light"><tr><th>Subcategoria</th><th>Categoria</th><th class="text-center">Ação</th></tr></thead>
                        <tbody>
                        @forelse($subcategories as $subcategory)
                            <tr>
                                <td>{{ $subcategory->name }}</td>
                                <td>{{ $parentNames[$subcategory->parent_id] ?? 'Categoria removida' }}</td>
                                <td>
                                    <div class="btn--container justify-content-center">
                                        <a class="btn btn-sm action-btn btn-outline-info" href="{{ route('vendor.foxgo-catalog.category.status', [$subcategory->id, $subcategory->is_enabled ? 0 : 1]) }}">Status</a>
                                        <form action="{{ route('vendor.foxgo-catalog.category.delete', $subcategory->id) }}" method="post">@csrf @method('delete')<button type="submit" class="btn btn-sm action-btn btn-outline-danger">Excluir</button></form>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr><td colspan="3" class="text-center text-muted">Nenhuma subcategoria criada.</td></tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="card">
                <div class="card-header py-2"><h5 class="card-title mb-0">Marcas/linhas <span class="badge badge-soft-dark ml-1">{{ $brands->count() }}</span></h5></div>
                <div class="table-responsive">
                    <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                        <thead class="thead-light"><tr><th>Nome</th><th>Status</th><th class="text-center">Ação</th></tr></thead>
                        <tbody>
                        @forelse($brands as $brand)
                            <tr>
                                <td>
                                    <form action="{{ route('vendor.foxgo-catalog.brand.update', $brand->id) }}" method="post" class="d-flex">
                                        @csrf
                                        <input type="text" name="name" class="form-control form-control-sm" value="{{ $brand->name }}" required>
                                        <button class="btn btn-sm btn--primary ml-1" type="submit">Salvar</button>
                                    </form>
                                </td>
                                <td><span class="badge {{ $brand->is_enabled ? 'badge-soft-success' : 'badge-soft-danger' }}">{{ $brand->is_enabled ? 'Ativa' : 'Inativa' }}</span></td>
                                <td>
                                    <div class="btn--container justify-content-center">
                                        <a class="btn btn-sm action-btn btn-outline-info" href="{{ route('vendor.foxgo-catalog.brand.status', [$brand->id, $brand->is_enabled ? 0 : 1]) }}">Status</a>
                                        <form action="{{ route('vendor.foxgo-catalog.brand.delete', $brand->id) }}" method="post">@csrf @method('delete')<button type="submit" class="btn btn-sm action-btn btn-outline-danger">Excluir</button></form>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr><td colspan="3" class="text-center text-muted">Nenhuma marca/linha criada.</td></tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
