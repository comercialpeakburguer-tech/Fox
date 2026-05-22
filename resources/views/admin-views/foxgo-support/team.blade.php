@extends('layouts.admin.app')

@section('title', 'Equipe da Central de Suporte')

@section('content')
    <div class="content container-fluid">
        <div class="page-header">
            <div class="d-flex flex-wrap justify-content-between align-items-center">
                <div>
                    <h1 class="page-header-title mb-1">Equipe da Central de Suporte</h1>
                    <p class="text-muted mb-0">
                        Vincule funcionários/admins aos setores da Central. Esta etapa não altera reembolso, repasses ou financeiro.
                    </p>
                </div>

                <div class="mt-2 mt-sm-0">
                    <a href="{{ route('admin.support.index') }}" class="btn btn--secondary">
                        Visão geral
                    </a>
                    <a href="{{ route('admin.support.cases') }}" class="btn btn--primary">
                        Casos
                    </a>
                </div>
            </div>
        </div>

        <div class="alert alert-info">
            <strong>Regra Fox GO:</strong>
            cada setor deve ter funcionários específicos. Master admin continua com visão total. Funcionário comum será filtrado pelo setor em etapa seguinte.
        </div>

        <div class="card mb-4">
            <div class="card-header">
                <h4 class="card-title mb-0">Vincular funcionário a setor</h4>
            </div>

            <div class="card-body">
                <form method="POST" action="{{ route('admin.support.team.assign') }}">
                    @csrf

                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label">Funcionário/Admin *</label>
                            <select name="admin_id" class="form-control" required>
                                <option value="">Selecionar funcionário</option>
                                @foreach($admins as $admin)
                                    <option value="{{ $admin->id }}">
                                        #{{ $admin->id }} - {{ trim(($admin->f_name ?? '') . ' ' . ($admin->l_name ?? '')) ?: $admin->email }}
                                        {{ (int) $admin->role_id === 1 ? '(Master admin)' : '' }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <div class="col-md-4">
                            <label class="form-label">Setor *</label>
                            <select name="department_id" class="form-control" required>
                                <option value="">Selecionar setor</option>
                                @foreach($departments as $department)
                                    <option value="{{ $department->id }}">
                                        {{ $department->name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <div class="col-md-4">
                            <label class="form-label">Função no setor</label>
                            <select name="role_in_department" class="form-control">
                                <option value="atendente">Atendente</option>
                                <option value="analista">Analista</option>
                                <option value="supervisor">Supervisor</option>
                                <option value="financeiro">Financeiro</option>
                                <option value="seguranca">Segurança</option>
                            </select>
                        </div>

                        <div class="col-12">
                            <label class="form-label d-block">Permissões sensíveis do setor</label>

                            <label class="mr-4">
                                <input type="checkbox" name="can_view_financial_context" value="1">
                                Pode ver contexto financeiro
                            </label>

                            <label class="mr-4">
                                <input type="checkbox" name="can_handle_refund" value="1">
                                Pode tratar reembolso
                            </label>

                            <label class="mr-4">
                                <input type="checkbox" name="can_handle_repasses" value="1">
                                Pode tratar repasses
                            </label>

                            <p class="text-muted mt-2 mb-0">
                                Essas permissões são preparatórias. Elas ainda não executam ação financeira.
                            </p>
                        </div>
                    </div>

                    <div class="d-flex justify-content-end mt-4">
                        <button type="submit" class="btn btn--primary">
                            Vincular ao setor
                        </button>
                    </div>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="card-title mb-0">Vínculos atuais</h4>
                <span class="badge badge-soft-info">Total: {{ $assignments->count() }}</span>
            </div>

            <div class="table-responsive">
                <table class="table table-borderless table-thead-bordered table-nowrap table-align-middle card-table">
                    <thead class="thead-light">
                        <tr>
                            <th>Funcionário</th>
                            <th>Setor</th>
                            <th>Função</th>
                            <th>Financeiro</th>
                            <th>Reembolso</th>
                            <th>Repasses</th>
                            <th>Status</th>
                            <th class="text-center">Ação</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($assignments as $assignment)
                            <tr>
                                <td>
                                    <strong>
                                        {{ trim((optional($assignment->admin)->f_name ?? '') . ' ' . (optional($assignment->admin)->l_name ?? '')) ?: optional($assignment->admin)->email }}
                                    </strong>
                                    <div class="text-muted small">Admin ID: {{ $assignment->admin_id }}</div>
                                </td>
                                <td>{{ optional($assignment->department)->name ?? '—' }}</td>
                                <td>{{ ucfirst($assignment->role_in_department ?? 'atendente') }}</td>
                                <td>{{ $assignment->can_view_financial_context ? 'Sim' : 'Não' }}</td>
                                <td>{{ $assignment->can_handle_refund ? 'Sim' : 'Não' }}</td>
                                <td>{{ $assignment->can_handle_repasses ? 'Sim' : 'Não' }}</td>
                                <td>{{ $assignment->is_active ? 'Ativo' : 'Inativo' }}</td>
                                <td class="text-center">
                                    <form method="POST" action="{{ route('admin.support.team.toggle', $assignment->id) }}">
                                        @csrf
                                        <button type="submit" class="btn btn-sm btn-outline-primary">
                                            {{ $assignment->is_active ? 'Desativar' : 'Ativar' }}
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="8" class="text-center text-muted py-4">
                                    Nenhum funcionário vinculado a setor ainda.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
@endsection
