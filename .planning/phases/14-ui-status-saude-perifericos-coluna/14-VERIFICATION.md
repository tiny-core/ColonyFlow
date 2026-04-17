# Phase 14 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Layout em coluna (Monitor 2 / Status):
   - Rodar `startup`
   - Confirmar que na secao OPERACAO existe uma coluna para contadores e outra para perifericos
   - Confirmar alinhamento vertical (linhas no mesmo y) e truncamento sem quebrar layout
2. Cores:
   - Com ME Bridge online: "ME Bridge: Online" deve aparecer em verde
   - Com ME Bridge offline/desconectado: deve aparecer em vermelho
   - Periferico ausente: deve aparecer em vermelho (ou cinza se marcado como NA)
3. Performance:
   - Confirmar que a UI nao pisca/nao fica lenta e que o status nao spamma chamadas (cache TTL)

## Resultado

- [ ] Automated OK
- [ ] Manual OK
