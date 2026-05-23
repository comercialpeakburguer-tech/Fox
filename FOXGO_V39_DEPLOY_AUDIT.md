# Fox GO V3.9 Deploy Audit

Branch seguro: `foxgo/admin-v39-foxgo-merge`
Base real da VPS: `foxgo/admin-live-vps-20260522`

## Situacao do branch

- Branch esta 25 commits a frente da VPS.
- Branch nao esta atrasado em relacao a VPS.
- Nenhum deploy direto foi feito.

## Blocos V3.9 integrados no branch seguro

### Painel/Admin

- Controle de fornecedor verificado via endpoint admin.
- Base de colunas `stores.is_verified` e `stores.verified_at`.
- Rotas admin complementares carregadas por `RouteServiceProvider`.
- Plano de merge seguro documentado.

### App do entregador

- Relatorio detalhado V3.9 do entregador.
- Rota `GET /api/v1/delivery-man/new-earning-report`.
- Rotas Fox GO preservadas:
  - `GET /api/v1/delivery-man/available-requests`
  - `PUT /api/v1/delivery-man/release-to-another-deliveryman`

### App/Web do fornecedor

- Relatorio detalhado V3.9 do fornecedor.
- Rota `GET /api/v1/vendor/earning-report`.
- Reels do fornecedor:
  - `GET /api/v1/vendor/reels`
  - `POST /api/v1/vendor/reels/store`
  - `PUT /api/v1/vendor/reels/status`
- Baixo estoque:
  - `GET /api/v1/vendor/inventory/low-stock`

### Web/App cliente

- App download section:
  - `GET /api/v1/app-download-section`
- Reels publicos:
  - `GET /api/v1/reels`
- Prescricoes salvas/autosave:
  - `GET /api/v1/customer/saved-files`
  - `POST /api/v1/customer/saved-files/store`
  - `DELETE /api/v1/customer/saved-files/delete-all`

### Produto com video

- Trait `HasProductVideoPreview` integrado ao model `Item`.
- Suporte a video enviado, video link, YouTube, Vimeo, MP4/WebM/OGG.
- Trait ajustado para nao depender de helpers ausentes na VPS.

### Baixo estoque

- Coluna `items.low_stock_alert_quantity`.
- Scope `lowStock()` no model `Item`.
- Endpoint de baixo estoque para fornecedor.

### Reels

- Model `FoxGoReel`.
- Migration `foxgo_reels`.
- Controller `FoxGoReelController`.
- Rotas publicas e de fornecedor.

### Prescricoes salvas

- Model `UserFile`.
- Controller `FoxGoSavedPrescriptionController`.
- Migration `user_files`.
- Rotas de listagem, upload e limpeza.

## Arquivos alterados/adicionados

- `.env.example`
- `app/Http/Controllers/Admin/FoxGoV39Controller.php`
- `app/Http/Controllers/Api/V1/DeliverymanEarningReportController.php`
- `app/Http/Controllers/Api/V1/FoxGoConfigController.php`
- `app/Http/Controllers/Api/V1/FoxGoInventoryController.php`
- `app/Http/Controllers/Api/V1/FoxGoReelController.php`
- `app/Http/Controllers/Api/V1/FoxGoSavedPrescriptionController.php`
- `app/Http/Controllers/Api/V1/Vendor/StoreEarningReportController.php`
- `app/Models/FoxGoReel.php`
- `app/Models/Item.php`
- `app/Models/UserFile.php`
- `app/Providers/RouteServiceProvider.php`
- `app/Traits/HasProductVideoPreview.php`
- `app/Traits/ReportGeneratorTrait.php`
- `database/migrations/2026_05_23_010500_create_user_files_table_for_prescriptions.php`
- `database/migrations/2026_05_23_011000_add_v39_product_video_low_stock_verified_columns.php`
- `database/migrations/2026_05_23_011500_create_foxgo_reels_table.php`
- `routes/admin/foxgo_v39.php`
- `routes/api/v1/foxgo.php`

## Validacao obrigatoria antes de producao

Executar na VPS/staging antes do deploy definitivo:

```bash
php artisan optimize:clear
php artisan route:list | grep -E "foxgo-v39|reels|new-earning-report|low-stock|saved-files|app-download-section"
php artisan migrate --pretend
php artisan migrate
php artisan route:clear
php artisan config:clear
php artisan cache:clear
```

## Testes manuais minimos

1. Abrir painel admin e confirmar que as rotas antigas continuam funcionando.
2. Testar relatorio novo do entregador no app.
3. Testar relatorio novo do fornecedor.
4. Criar reel pelo fornecedor.
5. Listar reels publicos na web/app cliente.
6. Salvar e listar prescricoes no app/web cliente.
7. Verificar produto com video no payload de produto.
8. Testar baixo estoque no fornecedor.
9. Marcar/desmarcar fornecedor verificado pelo endpoint admin.
10. Confirmar que latest-orders, available-requests, aceite, release e logistica Fox GO continuam funcionando.

## Aviso

Ainda nao fazer deploy direto em producao sem rodar a validacao acima. Este branch esta preparado para PR/revisao e teste em staging/VPS.
