@php($foxgoModuleType = Config::get('module.current_module_type'))
@if(in_array($foxgoModuleType, ['grocery', 'pharmacy', 'ecommerce', 'parcel']))
    @php($foxgoLogisticsProfile = isset($product) && $product?->id ? \App\Models\FoxGoItemLogisticsProfile::where('item_id', $product->id)->first() : null)

    <div class="card mt-3 foxgo-logistics-profile-card">
        <div class="card-header border-0 pb-0">
            <h5 class="card-title mb-1">Logística Fox GO</h5>
            <p class="mb-0 text-muted">
                Configure peso, volume e veículo permitido para o motor inteligente de entrega.
            </p>
        </div>

        <div class="card-body">
            @if($foxgoModuleType === 'grocery')
                <div class="alert alert-warning mb-3">
                    Mercado: estes dados serão usados para calcular peso da compra e decidir Moto, Carro, Utilitário ou Van. A quantidade de sacolas será informada pela loja antes de marcar o pedido como pronto.
                </div>
            @elseif($foxgoModuleType === 'pharmacy')
                <div class="alert alert-info mb-3">
                    Farmácia: use estes campos quando o produto tiver peso, volume ou restrição logística relevante.
                </div>
            @elseif($foxgoModuleType === 'ecommerce')
                <div class="alert alert-info mb-3">
                    Compras: use estes campos para produtos com peso/volume que impactam o tipo de veículo.
                </div>
            @elseif($foxgoModuleType === 'parcel')
                <div class="alert alert-info mb-3">
                    Entregas: estes dados ajudam a classificar o tipo de transporte necessário.
                </div>
            @endif

            <div class="row g-3">
                <div class="col-md-3">
                    <label class="form-label">Peso do item (kg)</label>
                    <input type="number" step="0.001" min="0" class="form-control"
                           name="foxgo_logistics_weight_kg"
                           value="{{ old('foxgo_logistics_weight_kg', data_get($foxgoLogisticsProfile, 'weight_kg')) }}"
                           placeholder="Ex: 1.000">
                </div>

                <div class="col-md-3">
                    <label class="form-label">Volume</label>
                    @php($currentVolume = old('foxgo_volume_label', data_get($foxgoLogisticsProfile, 'volume_label')))
                    <select name="foxgo_volume_label" class="form-control">
                        <option value="">Selecionar</option>
                        <option value="small" {{ $currentVolume === 'small' ? 'selected' : '' }}>Pequeno</option>
                        <option value="medium" {{ $currentVolume === 'medium' ? 'selected' : '' }}>Médio</option>
                        <option value="large" {{ $currentVolume === 'large' ? 'selected' : '' }}>Grande</option>
                        <option value="bulky" {{ $currentVolume === 'bulky' ? 'selected' : '' }}>Volumoso</option>
                    </select>
                </div>

                <div class="col-md-2">
                    <label class="form-label">Comprimento (cm)</label>
                    <input type="number" step="0.01" min="0" class="form-control"
                           name="foxgo_length_cm"
                           value="{{ old('foxgo_length_cm', data_get($foxgoLogisticsProfile, 'length_cm')) }}">
                </div>

                <div class="col-md-2">
                    <label class="form-label">Largura (cm)</label>
                    <input type="number" step="0.01" min="0" class="form-control"
                           name="foxgo_width_cm"
                           value="{{ old('foxgo_width_cm', data_get($foxgoLogisticsProfile, 'width_cm')) }}">
                </div>

                <div class="col-md-2">
                    <label class="form-label">Altura (cm)</label>
                    <input type="number" step="0.01" min="0" class="form-control"
                           name="foxgo_height_cm"
                           value="{{ old('foxgo_height_cm', data_get($foxgoLogisticsProfile, 'height_cm')) }}">
                </div>
            </div>

            <hr>

            <div class="row g-3">
                @foreach([
                    'foxgo_bike_allowed' => 'Permite Bike',
                    'foxgo_motorcycle_allowed' => 'Permite Moto',
                    'foxgo_car_required' => 'Exige Carro',
                    'foxgo_utility_required' => 'Exige Utilitário',
                    'foxgo_van_required' => 'Exige Van',
                    'foxgo_manual_review_required' => 'Revisão manual',
                ] as $field => $label)
                    @php($dbField = str_replace('foxgo_', '', $field))
                    <div class="col-md-4">
                        <input type="hidden" name="{{ $field }}" value="0">
                        <label class="d-flex align-items-center gap-2 mb-0">
                            <input type="checkbox" name="{{ $field }}" value="1"
                                   {{ old($field, data_get($foxgoLogisticsProfile, $dbField)) ? 'checked' : '' }}>
                            <span>{{ $label }}</span>
                        </label>
                    </div>
                @endforeach
            </div>

            <small class="text-muted d-block mt-3">
                Observação: Restaurantes não são obrigados a preencher estes dados. Para Mercado, Farmácia e Compras, estes campos serão usados nas próximas etapas do motor inteligente.
            </small>
        </div>
    </div>
@endif
