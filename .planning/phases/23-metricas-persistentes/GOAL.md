# Phase 23: Métricas Persistentes

## Goal
Salvar snapshots periódicos de métricas em `data/metrics.json` e expor via `startup metrics` para inspeção pós-sessão sem precisar abrir o loop.

## Behavior
- A cada N ticks (configurável: `[observability] metrics_flush_interval_ticks = 60`) serializa `state.metrics` em `data/metrics.json`
- `startup metrics` lê e imprime o arquivo de forma legível (totais, médias, último flush)
- Não bloqueia nem atrasa o tick principal
- Arquivo sobrescrito a cada flush (não acumulativo — usar logs para histórico)

## Files Likely Touched
- `modules/engine.lua` (flush periódico), `modules/persistence.lua` ou novo `modules/metrics_store.lua`, `startup.lua`, `lib/config.lua`, `tests/run.lua`

## Depends On
Phase 19 (complete)

## Complexity
Low
