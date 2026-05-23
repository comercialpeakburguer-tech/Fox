{{-- Fox GO V3.9 - Produto com vídeo e alerta de estoque baixo --}}
<div class="col-md-4">
    <div class="form-group mb-0 error-wrapper">
        <label class="input-label">Fox GO - Link do vídeo do produto</label>
        <input type="text"
               name="video_link"
               class="form-control"
               value="{{ old('video_link', $product->video_link ?? '') }}"
               placeholder="https://youtube.com/... ou https://...">
        <small class="text-muted">Esse link será usado pelo app/web cliente para prévia do produto.</small>
    </div>
</div>

<div class="col-md-4">
    <div class="form-group mb-0 error-wrapper">
        <label class="input-label">Fox GO - Arquivo de vídeo do produto</label>
        <input type="file"
               name="video"
               class="form-control"
               accept="video/mp4,video/webm,video/quicktime">
        @if(!empty($product?->video_full_url))
            <small class="d-block mt-1">
                <a href="{{ $product->video_full_url }}" target="_blank">Ver vídeo atual</a>
            </small>
        @else
            <small class="text-muted">Opcional. Preferência: MP4 leve.</small>
        @endif
    </div>
</div>

<div class="col-md-4">
    <div class="form-group mb-0 error-wrapper">
        <label class="input-label">Fox GO - Alerta de estoque baixo</label>
        <input type="number"
               name="low_stock_alert_quantity"
               class="form-control"
               min="0"
               value="{{ old('low_stock_alert_quantity', $product->low_stock_alert_quantity ?? '') }}"
               placeholder="Ex: 5">
        <small class="text-muted">Quando o estoque chegar nesse número, aparece no alerta de baixo estoque.</small>
    </div>
</div>
