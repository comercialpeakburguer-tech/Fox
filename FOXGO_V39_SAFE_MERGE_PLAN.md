# Fox GO V3.9 Safe Merge Plan

Branch correto para montagem: `foxgo/admin-v39-foxgo-merge`

Base deste branch: painel real da VPS (`foxgo/admin-live-vps-20260522`).

## Regra importante

O pacote `Admin panel update to V3.9.zip` e o branch `foxgo/admin-codecanyon-v39-original` representam arquivos de atualizacao da CodeCanyon, nao uma instalacao completa pronta para producao.

Por isso, o branch seguro de producao deve partir do painel real da VPS e receber os arquivos V3.9 de forma seletiva.

## Nao usar para deploy direto

Nao usar `foxgo/admin-v39-foxgo-full-merge` para producao sem revisao, porque ele partiu da estrutura do pacote de update. Ele serve como area de inspecao dos arquivos oficiais V3.9.

## Branch seguro

Usar `foxgo/admin-v39-foxgo-merge` para:

- preservar painel real da VPS;
- preservar rotas reais do Laravel;
- preservar web cliente real;
- preservar Fox GO Logistics;
- aplicar V3.9 modulo por modulo.

## Itens V3.9 a aplicar

- Vendor Reels
- Relatorios detalhados de ganhos
- Fornecedor verificado
- Video de produto
- Indicador de baixo estoque
- Admin e cadastro reformulados
- Download do app na web
- Autosave de prescricoes
- Compatibilidade Flutter 3.41.8

## Customizacoes Fox GO intocaveis

- latest-orders com offer real
- available-requests
- accept-order com lock
- timeout de oferta
- release para outro entregador
- OTP retirada
- delay de 4 minutos
- vehicle compatibility
- logistics status/event services
- wallet/repasses reais
- suporte/Nina/admin

## Proximo passo

Mapear os arquivos do pacote V3.9 e aplicar no branch `foxgo/admin-v39-foxgo-merge`, mantendo a VPS como base.
