# Phase 15 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Doctor:
   - Rodar `startup doctor`
   - Confirmar que imprime um resumo ASCII acionavel (HTTP, peripherals, ME, config) e sugestoes
   - Confirmar que contem as strings `HTTP:`, `ME:`, `CONFIG:` e `ACTIONS:`
2. Persistencia:
   - Iniciar o sistema, deixar um job em andamento
   - Reiniciar o computador
   - Confirmar que o job reaparece e nao duplica crafts
3. Circuit breaker ME:
   - Desconectar/desligar o ME
   - Confirmar que o sistema entra em modo degraded (menos spam) e que retenta apos backoff
   - Confirmar que aparece `me_degraded` no estado do job (work.err) ou log `ME degraded; aguardando retry...`
   - Religar o ME e confirmar que recupera

## Resultado

- [ ] Automated OK
- [ ] Manual OK
