---
phase: 14-ui-status-saude-perifericos-coluna
plan: "01"
subsystem: ui
tags: [status, peripherals, cache, tests]
requires:
  - phase: 12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi
    provides: monitor status baseline + header UI
provides:
  - state.health.peripherals snapshot (TTL cache)
  - Monitor 2 (Status) two-column OPERACAO block: counters | peripheral health
  - colored Online/Offline/NA values (ASCII-only)
affects: [ui, engine, cache]
tech-stack:
  added: []
  patterns:
    - snapshot_cacheado_para_ui
    - ui_duas_colunas_com_truncamento_deterministico
    - status_colorido_por_nivel_ok_bad_unknown
key-files:
  created: []
  modified:
    - modules/engine.lua
    - components/ui.lua
    - tests/run.lua
    - .planning/phases/14-ui-status-saude-perifericos-coluna/14-VERIFICATION.md
    - .planning/phases/14-ui-status-saude-perifericos-coluna/14-VALIDATION.md
requirements-completed: []
duration: n/a
completed: 2026-04-18
---

# Phase 14 Plan 01: UI Status - Saude de perifericos (coluna alinhada) Summary

**Monitor 2 (Status) passa a exibir, na secao OPERACAO, contadores e saude de perifericos lado a lado, com snapshot cacheado no engine para evitar polling por frame.**

## Performance

- **Tasks:** 4
- **Files modified:** 5

## Accomplishments

- Adiciona snapshot `state.health.peripherals` cacheado (TTL 2s) em `Engine:tick()` para consumo barato pela UI
- Garante que o status do `ME Bridge` reflete o grid via `ME:isOnline()` (online/offline), nao apenas presenca do peripheral
- Migra OPERACAO para layout em duas colunas com separador ` | `, truncamento deterministico e cor aplicada somente ao valor de status
- Adiciona cobertura de testes para formatacao em duas colunas, mapeamento de cores e fallbacks `NA`
- Atualiza checklist manual e strategy de validacao da fase 14

## Task Commits

Cada tarefa foi commitada de forma atomica:

1. **Task 1: Snapshot cacheado de saude** - `d9a24f9` (feat)
2. **Task 2: UI coluna de perifericos** - `7aa0986` (feat)
3. **Task 3: Testes (layout/cor/fallback)** - `16edf84` (test)
4. **Task 4: Checklist/validacao** - (docs)

## Decisions Made

None - seguiu as decisoes registradas em 14-CONTEXT.md.

## Deviations from Plan

None.

## Issues Encountered

None.

## Next Phase Readiness

- UI de status agora tem base de "saude operacional" para evolucoes (doctor/circuit-breaker/performance) nas fases seguintes.

---
*Phase: 14-ui-status-saude-perifericos-coluna*
*Completed: 2026-04-18*
