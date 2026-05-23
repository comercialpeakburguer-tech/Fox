{{-- Fox GO V3.9 - Loja Verificada --}}
@php
    $foxgoStoreVerified = (bool) ($store->is_verified ?? false);
    $foxgoVerifiedAt = $store->verified_at ?? null;
@endphp

<div class="card mb-20 border-0 shadow--card-2">
    <div class="card-body p-3 p-sm-4">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
            <div>
                <h4 class="mb-1 d-flex align-items-center gap-2">
                    <span>Fox GO - Loja Verificada</span>
                    @if($foxgoStoreVerified)
                        <span class="badge badge-soft-success">Verificada</span>
                    @else
                        <span class="badge badge-soft-warning">Não verificada</span>
                    @endif
                </h4>

                <p class="text-muted mb-0">
                    Esse selo alimenta a credibilidade da loja nos apps e nos Reels.
                </p>

                @if($foxgoStoreVerified && $foxgoVerifiedAt)
                    <small class="text-success d-block mt-1">
                        Verificada em {{ \App\CentralLogics\Helpers::time_date_format($foxgoVerifiedAt) }}
                    </small>
                @endif
            </div>

            <form action="{{ route('admin.foxgo-v39.store.verification', $store->id) }}" method="post" class="m-0">
                @csrf
                <input type="hidden" name="is_verified" value="{{ $foxgoStoreVerified ? 0 : 1 }}">
                <button type="submit" class="btn {{ $foxgoStoreVerified ? 'btn-outline-danger' : 'btn--primary' }}">
                    {{ $foxgoStoreVerified ? 'Remover verificação' : 'Marcar como verificada' }}
                </button>
            </form>
        </div>
    </div>
</div>
