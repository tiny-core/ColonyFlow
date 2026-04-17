# Phase 15 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Doctor:
   - Rodar `startup doctor`
   - Confirmar que imprime um resumo ASCII acionavel (HTTP, perifericos, ME, config) e sugestoes
2. Persistencia:
   - Iniciar o sistema, deixar um job em andamento
   - Reiniciar o computador
   - Confirmar que o job reaparece e nao duplica crafts
3. Circuit breaker ME:
   - Desconectar/desligar o ME
   - Confirmar que o sistema entra em modo degraded (menos spam) e que retenta apos backoff
   - Religar o ME e confirmar que recupera

## Resultado

- [ ] Automated OK
- [ ] Manual OK
