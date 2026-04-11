# Verificação: Phase 06

## Checklist

- [x] Consultas repetidas ao ME (mesmo item) não fazem chamadas duplicadas dentro do TTL.
- [x] `me_item_ttl_seconds=0` e `me_craftable_ttl_seconds=0` desativam cache.
- [x] `startup test` cobre cache do ME e passa sem regressões.
