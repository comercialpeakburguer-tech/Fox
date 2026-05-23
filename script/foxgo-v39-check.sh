#!/usr/bin/env bash
set -e
cd "${1:-/opt/foxgo/admin}"

PHP_RUN="php"
if ! command -v php >/dev/null 2>&1; then
  CID=$(docker ps -q | head -n 1)
  if [ -z "$CID" ]; then
    echo "ERRO: PHP nao encontrado e nenhum container Docker ativo."
    exit 1
  fi
  PHP_RUN="docker exec $CID php"
fi

echo "== PHP =="
$PHP_RUN -v | head -n 1

echo "== BRANCH =="
git branch --show-current
git status --short

echo "== SINTAXE PHP =="
for file in \
app/Http/Controllers/Admin/FoxGoV39Controller.php \
app/Http/Controllers/Api/V1/DeliverymanEarningReportController.php \
app/Http/Controllers/Api/V1/FoxGoConfigController.php \
app/Http/Controllers/Api/V1/FoxGoInventoryController.php \
app/Http/Controllers/Api/V1/FoxGoReelController.php \
app/Http/Controllers/Api/V1/FoxGoSavedPrescriptionController.php \
app/Http/Controllers/Api/V1/Vendor/StoreEarningReportController.php \
app/Models/FoxGoReel.php \
app/Models/Item.php \
app/Models/UserFile.php \
app/Providers/RouteServiceProvider.php \
app/Traits/HasProductVideoPreview.php \
app/Traits/ReportGeneratorTrait.php \
routes/admin/foxgo_v39.php \
routes/api/v1/foxgo.php \
database/migrations/2026_05_23_010500_create_user_files_table_for_prescriptions.php \
database/migrations/2026_05_23_011000_add_v39_product_video_low_stock_verified_columns.php \
database/migrations/2026_05_23_011500_create_foxgo_reels_table.php
do
  $PHP_RUN -l "$file"
done

echo "== LIMPAR CACHE =="
$PHP_RUN artisan optimize:clear

echo "== ROTAS FOX GO ARQUIVOS =="
grep -n "foxgo.php\|foxgo_v39.php" app/Providers/RouteServiceProvider.php routes/api/v1/api.php routes/admin.php || true

echo "== ROTAS FOX GO NO ARTISAN =="
$PHP_RUN artisan route:list | grep -Ei "reels|new-earning-report|low-stock|saved-files|app-download-section|foxgo-v39" || true

echo "== MIGRATE PRETEND =="
$PHP_RUN artisan migrate --pretend

echo "== OK: validacao terminou =="
