# Summary 06-01: Cache de ME Bridge

- Implementou cache TTL configurável no wrapper do ME Bridge:
  - `ME:getItem` (por item)
  - `ME:listItems` (por item quando `filter.name` existe)
  - `ME:isCraftable` (por item+count)
- Adicionou chaves no `config.ini` para controlar TTL e permitir desativação via `0`:
  - `me_item_ttl_seconds`, `me_list_ttl_seconds`, `me_craftable_ttl_seconds`
- Adicionou testes de regressão para validar cache hit e comportamento com TTL=0:
  - `me_getItem_cache_hit_e_ttl0`
  - `me_isCraftable_cache_hit`

## Verificação

- `startup test` passa com os testes de cache inclusos.

