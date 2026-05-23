#!/usr/bin/env bash
set -euo pipefail

cd "${1:-/opt/foxgo/admin}"

echo "== Fox GO V3.9 validation =="
echo "Path: $(pwd)"

echo "\n== Git branch =="
git branch --show-current || true
git status --short || true

echo "\n== PHP syntax check: changed Fox GO/V3.9 files =="
php -l app/Http/Controllers/Admin/FoxGoV39Controller.php
php -l app/Http/Controllers/Api/V1/DeliverymanEarningReportController.php
php -l app/Http/Controllers/Api/V1/FoxGoConfigController.php
php -l app/Http/Controllers/Api/V1/FoxGoInventoryController.php
php -l app/Http/Controllers/Api/V1/FoxGoReelController.php
php -l app/Http/Controllers/Api/V1/FoxGoSavedPrescriptionController.php
php -l app/Http/Controllers/Api/V1/Vendor/StoreEarningReportController.php
php -l app/Models/FoxGoReel.php
php -l app/Models/Item.php
php -l app/Models/UserFile.php
php -l app/Providers/RouteServiceProvider.php
php -l app/Traits/HasProductVideoPreview.php
php -l app/Traits/ReportGeneratorTrait.php
php -l routes/admin/foxgo_v39.php
php -l routes/api/v1/foxgo.php
php -l database/migrations/2026_05_23_010500_create_user_files_table_for_prescriptions.php
php -l database/migrations/2026_05_23_011000_add_v39_product_video_low_stock_verified_columns.php
php -l database/migrations/2026_05_23_011500_create_foxgo_reels_table.php

echo "\n== Clear cached Laravel bootstrap =="
php artisan optimize:clear

echo "\n== Route check =="
php artisan route:list | grep -E "foxgo-v39|reels|new-earning-report|low-stock|saved-files|app-download-section" || {
  echo "ERROR: Expected V3.9/Fox GO routes were not found." >&2
  exit 1
}

echo "\n== Migration dry run =="
php artisan migrate --pretend

echo "\n== Validation completed. If no errors appeared above, branch is ready for controlled migration/deploy test. =="
