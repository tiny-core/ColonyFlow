---
phase: 22-alertas-monitor
plan: "02"
subsystem: ui, tests
tags: [stuck-request, alert, color, suffix, monitor, renderRequests, renderStatus]
dependency_graph:
  requires: [22-01 stuck_since_ms in snapshot, lib/config.lua alert_stuck_minutes]
  provides: [colored "Xm" suffix in ETAPA column, "Presas: N >Xm" summary in OPERACAO, 6 Phase 22 tests]
  affects: [operator visibility of stuck requests on CC monitor]
tech_stack:
  added: []
  patterns: [measurement-loop + render-loop symmetry (same logic both loops), conditional summary line]
key_files:
  created: []
  modified:
    - components/ui.lua
    - tests/run.lua
decisions:
  - "D-04: blocked_by_tier → colors.red; waiting_retry/nao_craftavel → colors.yellow"
  - "D-05: suffix 'Xm' shows elapsed minutes since first stuck entry"
  - "D-06: threshold from cfg:getNumber('observability','alert_stuck_minutes',5)"
  - "D-07: 'Xm' suffix included in measurement loop so jobMax reflects real column width"
  - "D-08: 'Presas: N >Xm' shows oldest stuck request's elapsed time"
  - "D-09: Presas line omitted when N = 0"
  - "D-10: Presas line only on view main (inside statusPage == opPage guard)"
metrics:
  duration: "~25 min"
  completed_date: "2026-04-30T00:00:00Z"
  tasks_completed: 2
  files_modified: 2
---

# Phase 22 Plan 02: Alertas Monitor — Display Layer Summary

## What was built

Extended the UI to surface stuck requests visually and added 6 automated test cases for
the Phase 22 data contract.

## Implementation in `components/ui.lua`

**renderRequests — measurement loop** (`~l.463–479`):
- After `[R:N]` block, before `if #etapa > jobMax`, reads `job.stuck_since_ms` and
  `cfg:getNumber("observability","alert_stuck_minutes",5)`.
- If elapsed >= threshold, appends `Xm` to `etapa` so `jobMax` accounts for the suffix (D-07).
- Uses distinct locals `stuckSinceM`, `alertMinsM`, `elapsedMsM`, `elapsedMinM`.

**renderRequests — render loop** (`~l.540–560`):
- After `[R:N]` block, before `string.format`, reads `job.stuck_since_ms`.
- If elapsed >= threshold: appends `Xm` to `etapaStr` and sets `fg = colors.red`
  (blocked_by_tier) or `fg = colors.yellow` (all other stuck statuses).

**renderStatus — OPERACAO section** (before blank-line gap):
- Scans `state.requests` for entries with non-nil `stuck_since_ms`.
- When count > 0: draws `"Presas: N >Xm"` in yellow, where X is the oldest stuck elapsed time.
- Line is omitted when count = 0 (D-09).
- Already inside `statusPage == opPage` guard (D-10).

## Tests added to `tests/run.lua` (6 new, Phase 22 block)

| Test | What it verifies |
|------|-----------------|
| `engine_blocked_by_tier_sets_stuck_since_ms` | stuck_since_ms is a number after blocked_by_tier |
| `engine_nao_craftavel_sets_stuck_since_ms` | stuck_since_ms set on waiting_retry (nao_craftavel) |
| `engine_stuck_since_ms_preserved_on_retry` | pre-seeded T0 not overwritten after retry tick |
| `engine_stuck_since_ms_cleared_on_done` | nil after item becomes available (missing <= 0) |
| `engine_stuck_since_ms_not_persisted` | absent from data/state.json after _persistWorkMaybe |
| `snapshot_copies_stuck_since_ms` | Snapshot.build copies 12345678 → snap.work["2206"] |

## Verification

- `grep -c "stuck_since_ms" components/ui.lua` → 5 ✓
- `grep "Presas:" components/ui.lua` → present ✓
- `grep "colors.red" components/ui.lua` (inside stuck block) → present ✓
- `grep "stuckSinceM" components/ui.lua` → measurement loop confirmed ✓
- 6 test names present in tests/run.lua ✓
- Phase 22 section header present ✓

## Checklist

- [x] components/ui.lua — measurement loop, render loop, Presas summary (2a18fb3)
- [x] tests/run.lua — 6 Phase 22 test cases appended (2a18fb3)
