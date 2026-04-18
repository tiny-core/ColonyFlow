# Phase 14 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.
- Confirmar que os testes da fase 14 aparecem como OK:
  - `ui_status_two_col_format_normal_width`
  - `ui_status_two_col_format_small_width_truncates`
  - `ui_status_health_color_mapping`
  - `ui_status_health_fallback_na`
  - `engine_health_snapshot_me_online_offline`

## Manual (in-world)

1. Layout em coluna (Monitor 2 / Status):
   - Rodar `startup`
   - Confirmar que na secao OPERACAO existem linhas com separador fixo ` | ` (duas colunas alinhadas)
   - Confirmar que a coluna da direita exibe exatamente estes 5 labels (nesta ordem):
     - `ME Bridge`
     - `Colony`
     - `Modem`
     - `Mon Req`
     - `Mon Stat`
   - Em monitor menor/estreito, confirmar truncamento deterministico com `..` sem quebrar o alinhamento
2. Cores:
   - `Online` deve aparecer em verde (lime)
   - `Offline` deve aparecer em vermelho
   - `NA` deve aparecer em cinza
   - Para ME Bridge, o status deve refletir o grid via `ME:isOnline()` (nao apenas presenca do periferico)
3. Fallback `NA`:
   - Logo apos iniciar, antes do primeiro snapshot (ou se `state.health.peripherals` estiver ausente), confirmar que a UI mostra `NA` (cinza) sem erro
   - Confirmar que o valor troca de `NA` para `Online/Offline` depois que o engine roda o snapshot
3. Performance:
   - Confirmar que a UI nao pisca/nao fica lenta
   - Confirmar que o status nao spamma chamadas por frame (snapshot cacheado com TTL ~2s)

## Resultado

- [ ] Automated OK
- [ ] Manual OK
