---
phase: 23-metricas-persistentes
plan: "01"
subsystem: engine
tags: [metrics, persistence, observability, engine, config]
dependency_graph:
  requires: []
  provides: [Engine._metricsFlushMaybe, data/metrics.json, config.metrics_flush_interval_ticks]
  affects: [modules/engine.lua, lib/config.lua]
tech_stack:
  added: []
  patterns: [tick-gated flush, pcall-guarded serialization, atomic file write]
key_files:
  created: []
  modified:
    - modules/engine.lua
    - lib/config.lua
decisions:
  - "Flush gated by state.stats.processed % interval to avoid extra state or timers in Engine"
  - "pcall wraps textutils.serializeJSON so serialization failures never propagate to tick loop (T-23-01)"
  - "interval <= 0 guard prevents division-by-zero and infinite flush (T-23-03)"
  - "METRICS_PATH constant mirrors PERSIST_PATH pattern established in Phase 18"
metrics:
  duration: ~6 min
  completed: "2026-04-30T11:25:14Z"
  tasks_completed: 2
  files_modified: 2
---

# Phase 23 Plan 01: Metrics Flush Engine Summary

## One-liner

Periodic tick-gated flush of `state.metrics` to `data/metrics.json` via `Engine:_metricsFlushMaybe()`, with pcall-guarded serialization and config default of 60 ticks.

## What Was Built

### Engine:_metricsFlushMaybe (modules/engine.lua)

New method added immediately after `Engine:_persistWorkMaybe`. The method:

1. Early-returns when `state.metrics` is nil or `state.metrics.enabled` is false — zero cost when observability is off.
2. Reads `metrics_flush_interval_ticks` from config (default 60) via `cfg:getNumber`.
3. Guards against `interval <= 0` (prevents division-by-zero).
4. Fires only when `state.stats.processed % interval == 0`.
5. Writes `{v=1, flushed_at_ms, started_at_ms, metrics}` atomically to `data/metrics.json` via `Util.writeFileAtomic`.
6. Wraps `textutils.serializeJSON` in `pcall` so serialization errors never crash the tick loop.

### Call sites in tick()

`self:_metricsFlushMaybe()` inserted after every `self:_persistWorkMaybe()` inside `Engine:tick()`:

- no colonyIntegrator early return
- requests == nil early return
- colonyStats == nil early return
- defaultTargetInv unavailable early return
- defaultSnap nil + budget exceeded early return
- buildings == nil early return
- citizens == nil early return
- pre-pass budget exceeded early return
- normal loop budget exceeded early return
- normal end of tick

Total: 10 call sites in tick() + 1 method definition = 11 occurrences.

### config.lua DEFAULT_INI

`metrics_flush_interval_ticks=60` appended as last line of `[observability]` block. Phase 22 default `alert_stuck_minutes=5` preserved unchanged.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 97bd055 | feat(23-01): add METRICS_PATH constant and _metricsFlushMaybe to engine.lua |
| Task 2 | 347db27 | feat(23-01): add metrics_flush_interval_ticks=60 to config.lua DEFAULT_INI |

## Deviations from Plan

None — plan executed exactly as written.

## Threat Model Coverage

| Threat ID | Mitigation | Status |
|-----------|-----------|--------|
| T-23-01 | pcall wraps serializeJSON — flush failure never propagates to tick loop | Implemented |
| T-23-02 | metrics.json contains only operational timing/count data — accepted | N/A |
| T-23-03 | `if interval <= 0 then return end` prevents division-by-zero and infinite flush | Implemented |

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: modules/engine.lua
- FOUND: lib/config.lua
- FOUND: .planning/phases/23-metricas-persistentes/23-01-SUMMARY.md
- FOUND commit: 97bd055
- FOUND commit: 347db27
