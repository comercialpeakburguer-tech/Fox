# Bugs pendentes

## [UI][PT-BR] Dropdown de tipo de veículo exibe chaves técnicas

- **Tela:** Cadastro de entregador > Configurar > Tipo de veículo.
- **Problema atual:** O dropdown está exibindo valores técnicos crus em vez de textos amigáveis.

### Valores atuais exibidos
- `bike_delivery`
- `moto_delivery`
- `car_delivery`
- `utility_delivery`
- `van_delivery`
- `moto_ride`
- `car_economy_ride`
- `car_comfort_ride`

### Esperado (apenas camada de apresentação em PT-BR)
- Bicicleta — Entrega
- Moto — Entrega
- Carro — Entrega
- Utilitário — Entrega
- Van — Entrega
- Moto — Corrida
- Carro econômico — Corrida
- Carro conforto — Corrida

### Regra de implementação
- **Não alterar** IDs, slugs, valores enviados para API ou regra de negócio.
- Ajustar **somente** a camada de apresentação do app para mapear os valores técnicos para nomes amigáveis em PT-BR.
