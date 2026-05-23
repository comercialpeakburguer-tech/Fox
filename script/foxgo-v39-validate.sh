#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${1:-/opt/foxgo/admin}"
cd "$APP_DIR"

PHP_RUN=""
PHP_DESC=""

pick_php() {
  if command -v php >/dev/null 2>&1; then
    PHP_RUN="php"
    PHP_DESC="local php"
    return 0
  fi

  for bin in php8.4 php8.3 php8.2 php8.1 php8.0; do
    if command -v "$bin" >/dev/null 2>&1; then
      PHP_RUN="$bin"
      PHP_DESC="local $bin"
      return 0
    fi
  done

  if command -v docker >/dev/null 2>&1; then
    if command -v docker-compose >/dev/null 2>&1; then
      for service in app php laravel admin backend web workspace fpm; do
        if docker-compose ps --services 2>/dev/null | grep -qx "$service" && docker-compose exec -T "$service" php -v >/dev/null 2>&1; then
          PHP_RUN="docker-compose exec -T $service php"
          PHP_DESC="docker-compose service $service"
          return 0
        fi
      done
    fi

    if docker compose version >/dev/null 2>&1; then
      for service in app php laravel admin backend web workspace fpm; do
        if docker compose ps --services 2>/dev/null | grep -qx "$service" && docker compose exec -T "$service" php -v >/dev/null 2>&1; then
          PHP_RUN="docker compose exec -T $service php"
          PHP_DESC="docker compose service $service"
          return 0
        fi
      done
    fi

    while IFS= read -r container_id; do
      if docker exec "$container_id" php -v >/dev/null 2>&1; then
        PHP_RUN="docker exec $container_id php"
        PHP_DESC="docker container $container_id"
        return 0
      fi
    done < <(docker ps --format '{{.ID}}' 2>/dev/null)
  fi

  return 1
}

run_php() {
  # shellcheck disable=SC2086
  $PHP_RUN "$@"
}

echo "== Fox GO V3.9 validation =="
echo "Path: $(pwd)"

echo "\n== Detect PHP runtime =="
if ! pick_php; then
  echo "ERROR: PHP CLI nao encontrado no servidor nem dentro de containers Docker." >&2
  echo "Envie a saida deste comando para diagnostico:" >&2
  echo "command -v php; command -v php8.3; command -v docker; docker ps --format '{{.Names}} {{.Image}}'" >&2
  exit 127
fi

echo "PHP runtime: $PHP_DESC"
run_php -v | head -n 1

echo "\n== Git branch =="
git branch --show-current || true
git status --short || true

echo "\n== PHP syntax check: changed Fox GO/V3.9 files =="
files=(
  app/Http/Controllers/Admin/FoxGoV39Controller.php
  app/Http/Controllers/Api/V1/DeliverymanEarningReportController.php
  app/Http/Controllers/Api/V1/FoxGoConfigController.php
  app/Http/Controllers/Api/V1/FoxGoInventoryController.php
  app/Http/Controllers/Api/V1/FoxGoReelController.php
  app/Http/Controllers/Api/V1/FoxGoSavedPrescriptionController.php
  app/Http/Controllers/Api/V1/Vendor/StoreEarningReportController.php
  app/Models/FoxGoReel.php
  app/Models/Item.php
  app/Models/UserFile.php
  app/Providers/RouteServiceProvider.php
  app/Traits/HasProductVideoPreview.php
  app/Traits/ReportGeneratorTrait.php
  routes/admin/foxgo_v39.php
  routes/api/v1/foxgo.php
  database/migrations/2026_05_23_010500_create_user_files_table_for_prescriptions.php
  database/migrations/2026_05_23_011000_add_v39_product_video_low_stock_verified_columns.php
  database/migrations/2026_05_23_011500_create_foxgo_reels_table.php
)

for file in "${files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: arquivo nao encontrado: $file" >&2
    exit 1
  fi
  run_php -l "$file"
done

echo "\n== Clear cached Laravel bootstrap =="
run_php artisan optimize:clear

echo "\n== Route check =="
run_php artisan route:list | grep -E "foxgo-v39|reels|new-earning-report|low-stock|saved-files|app-download-section" || {
  echo "ERROR: Expected V3.9/Fox GO routes were not found." >&2
  exit 1
}

echo "\n== Migration dry run =="
run_php artisan migrate --pretend

echo "\n== Validation completed. If no errors appeared above, branch is ready for controlled migration/deploy test. =="
