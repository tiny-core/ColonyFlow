---
phase: 22-alertas-monitor
plan: "01"
subsystem: engine, snapshot, config
tags: [stuck-request, alert, lifecycle, persistence, observability]
dependency_graph:
  requires: [modules/engine.lua status transitions, modules/snapshot.lua copyWorkJob, lib/config.lua DEFAULT_INI]
  provides: [stuck_since_ms lifecycle in engine work, snapshot copy of stuck_since_ms, alert_stuck_minutes config default]
  affects: [components/ui.lua (Plan 02 reads stuck_since_ms from snapshot)]
tech_stack:
  added: []
  patterns: [nil-guard set-once pattern, intentional persistence exclusion same as retry_count]
key_files:
  created: []
  modified:
    - modules/engine.lua
    - modules/snapshot.lua
    - lib/config.lua
decisions:
  - "D-01: stuck_since_ms set ONLY when nil (nil-guard) — never overwritten during retry loops"
  - "D-02: stuck_since_ms cleared (nil) at every non-stuck transition (done, crafting, pending)"
  - "D-03: stuck_since_ms intentionally excluded from _persistWorkMaybe — same contract as retry_count"
metrics:
  duration: "~20 min"
  completed_date: "2026-04-30T00:00:00Z"
  tasks_completed: 2
  files_modified: 3
---

# Phase 22 Plan 01: Alertas Monitor — Data Layer Summary

## What was built

Added `stuck_since_ms` lifecycle tracking to the engine's in-memory work state, plumbing it through
the snapshot contract and adding the config default the UI will read.

## Implementation in `modules/engine.lua`

- **13 nil-guard set-points**: every status transition to `blocked_by_tier` or `waiting_retry` now
  sets `work.stuck_since_ms = os.epoch("utc")` if and only if it is currently nil, across all
  handlers: `_markAllWaitingRetry`, `_handleNoCandidate`, `_handleMeOffline`, `_handleCraft`,
  `_handleExport`, `_processRequest`.
- **6 clear-points**: `work.stuck_since_ms = nil` inserted before every non-stuck transition
  (`done` × 2, `crafting` × 2, `pending` × 2) including both `if/elseif` branches in `_handleExport`.
- **Persistence excluded**: `_persistWorkMaybe` comment updated to
  `-- retry_count, stuck_since_ms intentionally omitted`.

## Implementation in `modules/snapshot.lua`

- `copyWorkJob` return table extended with:
  ```lua
  retry_count    = job.retry_count,      -- Phase 21
  stuck_since_ms = job.stuck_since_ms,   -- Phase 22
  ```

## Implementation in `lib/config.lua`

- `alert_stuck_minutes=5` appended to `[observability]` block in `DEFAULT_INI`.

## Verification

- `grep -c "stuck_since_ms" modules/engine.lua` → 20 ✓
- `grep "if work.stuck_since_ms == nil then" modules/engine.lua | wc -l` → 13 ✓
- `grep "work.stuck_since_ms = nil" modules/engine.lua | wc -l` → 6 ✓
- persistence section: field absent ✓
- `grep "stuck_since_ms" modules/snapshot.lua` → present ✓
- `grep "alert_stuck_minutes" lib/config.lua` → `alert_stuck_minutes=5` ✓

## Checklist

- [x] modules/engine.lua — 13 set-points + 6 clear-points + omission comment (2a18fb3)
- [x] modules/snapshot.lua — copyWorkJob returns stuck_since_ms (2a18fb3)
- [x] lib/config.lua — alert_stuck_minutes=5 in DEFAULT_INI (2a18fb3)
