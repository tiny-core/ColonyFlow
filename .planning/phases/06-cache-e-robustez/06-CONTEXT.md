# Phase 06: Cache e Robustez Operacional

## Objetivo

Reduzir chamadas repetidas a periféricos (principalmente ME Bridge) e endurecer comportamento em execução longa (SP/MP) sem afetar correção do fluxo.

## Escopo

- Cache TTL para consultas repetidas do ME Bridge:
  - disponibilidade (getItem/listItems)
  - craftabilidade (isCraftable/isItemCraftable)
- Configuração por `config.ini` para habilitar/ajustar TTL.
- Testes garantindo que:
  - cache reduz chamadas repetidas
  - TTL=0 desativa cache

## Fora de escopo

- “Dataset padrão” de equivalências obrigatório.
- Mudanças na UI além de refletir estados já existentes.

