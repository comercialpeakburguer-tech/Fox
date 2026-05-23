# Fox GO V3.9 Merge Status

Branch: `foxgo/admin-v39-foxgo-full-merge`

Base: CodeCanyon Admin Panel Update V3.9.

Objetivo: manter as funcionalidades oficiais V3.9 e reintegrar as customizacoes Fox GO sem quebrar o sistema.

## Produtos cobertos

1. Painel/Admin
2. App do entregador
3. Web do cliente

## Branches

- V3.9 oficial: `foxgo/admin-codecanyon-v39-original`
- Painel VPS real: `foxgo/admin-live-vps-20260522`
- Merge completo: `foxgo/admin-v39-foxgo-full-merge`

## V3.9 deve manter

- Vendor Reels
- Relatorios detalhados de ganhos
- Fornecedor verificado
- Video de produto
- Indicador de baixo estoque
- Admin e cadastro reformulados
- Download do aplicativo na web
- Autosave de prescricoes
- Correcoes oficiais e Flutter 3.41.8

## Fox GO deve preservar

- Dispatch/logistica Fox GO
- Latest orders com offer real e timeout
- Available requests apos timeout/recusa
- Aceite de pedido com lock
- Release para outro entregador
- OTP de retirada
- Delay de 4 minutos antes de chamar entregador
- Compatibilidade de veiculos Fox GO
- Eventos logisticos e status operacional
- Suporte/Nina/admin
- Wallet/repasses reais

## Arquivos criticos

- `app/Http/Controllers/Api/V1/DeliverymanController.php`
- `routes/api/v1/api.php`
- `app/Models/FoxGoDispatchOffer.php`
- `app/Services/FoxGo/DispatchOfferService.php`
- `app/Services/FoxGo/DispatchScoringService.php`
- `app/Services/FoxGo/LogisticsEventService.php`
- `app/Services/FoxGo/LogisticsStatusService.php`

## Proximos passos

1. Reintroduzir arquivos Fox GO ausentes no branch V3.9 completo.
2. Mesclar DeliverymanController mantendo V3.9 e Fox GO.
3. Mesclar rotas API mantendo V3.9 e Fox GO.
4. Validar migrations V3.9 e Fox GO.
5. Validar web cliente.
6. Validar app entregador contra os endpoints atualizados.

Nao fazer deploy direto em producao sem validacao.
