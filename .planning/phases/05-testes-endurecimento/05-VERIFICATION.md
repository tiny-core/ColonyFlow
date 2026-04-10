# Verificação: Phase 05

## Checklist

- [x] `startup test` roda até o fim e grava um relatório em `logs/tests-*.txt`.
- [x] Relatório lista `[OK]`, `[FAIL]` e `[SKIP]` com o nome do teste.
- [x] Falha em teste aponta o caminho do relatório no erro final.
- [x] Caso “não craftável” resulta em `waiting_retry` e `err=nao_craftavel` (não vira `error` genérico).
- [x] Limpeza de logs mantém apenas os N mais recentes e nunca apaga o log atual.
- [x] `startup map` abre sem erro de `require` (package.path ok).
