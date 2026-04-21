# Phase 17 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Em `config.ini`, manter `[scheduler_budget] enabled=true` (defaults OK).
2. Criar backlog (muitas requests) e observar:
   - Status mostra `THROTTLED: ...` quando limites entram em acao.
   - O computador segue responsivo; nao trava.
3. Ajustar limites para forcar throttling mais cedo (ex.: `me_calls_per_tick=1`) e confirmar:
   - Nenhuma chamada ao peripheral ocorre quando o budget estoura (trabalho e adiado).
   - O sistema retoma automaticamente no proximo tick quando ha budget.

## Resultado

- [ ] Automated OK
- [ ] Manual OK
