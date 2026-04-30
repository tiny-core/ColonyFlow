---
phase: 23-metricas-persistentes
plan: "02"
subsystem: cli
tags: [metrics, cli, observability, startup, testing]

requires:
  - phase: 23-01
    provides: [Engine._metricsFlushMaybe, data/metrics.json, config.metrics_flush_interval_ticks]

provides:
  - modules/metrics_cli.lua reads data/metrics.json and prints Timing/IO/Cache report
  - startup.lua mode 'metrics' dispatches to modules/metrics_cli.lua
  - 3 Phase 23 test cases verify flush contract in tests/run.lua

affects: [startup.lua, modules/metrics_cli.lua, tests/run.lua]

tech-stack:
  added: []
  patterns: [standalone CLI module called via shell.run, mode dispatch pattern in startup.lua, nil-guarded field access for optional JSON fields]

key-files:
  created:
    - modules/metrics_cli.lua
  modified:
    - startup.lua
    - tests/run.lua

key-decisions:
  - "All field accesses in metrics_cli.lua use nil-guards (tonumber(v or 0) or 0) so corrupted/partial JSON never crashes"
  - "metrics_cli.lua is standalone script called via shell.run, consistent with doctor.lua pattern"
  - "pcall wraps Util.jsonDecode to handle corrupted data/metrics.json gracefully (T-23-04)"
  - "runMetrics() guards with fs.exists before shell.run so missing metrics_cli.lua prints error cleanly (T-23-06)"

patterns-established:
  - "Standalone CLI module pattern: modules/X_cli.lua called via shell.run from startup.lua mode dispatch"
  - "Nil-guard pattern for optional metric fields: tonumber(v or 0) or 0"

requirements-completed:
  - phase-23

duration: ~14min
completed: "2026-04-30"
---

# Phase 23 Plan 02: Metrics CLI and Tests Summary

**`startup metrics` CLI command reads data/metrics.json and prints Timing/IO/Cache report; 3 test cases verify Phase 23 flush contract**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-04-30T12:46:27Z
- **Completed:** 2026-04-30T13:00:23Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Created modules/metrics_cli.lua: standalone script with nil-guarded JSON reading, Timing/IO/Cache section printing, graceful handling of missing/corrupted file
- Extended startup.lua with runMetrics() function and `if mode == "metrics"` dispatch block, following the established doctor.lua pattern
- Added 3 Phase 23 test cases to tests/run.lua: flush at interval, skip when disabled, payload fields validation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create modules/metrics_cli.lua** - `ef36be6` (feat)
2. **Task 2: Add 'metrics' mode to startup.lua** - `24744f9` (feat)
3. **Task 3: Add Phase 23 test cases to tests/run.lua** - `03e1122` (test)

## Files Created/Modified
- `modules/metrics_cli.lua` - Standalone CLI: reads data/metrics.json, prints formatted Timing/IO/Cache report
- `startup.lua` - Added runMetrics() + mode 'metrics' dispatch block + header comment update
- `tests/run.lua` - 3 Phase 23 test cases: engine_flushes_metrics_at_interval, engine_skips_metrics_flush_when_disabled, engine_metrics_payload_has_required_fields

## Decisions Made
- All field accesses in metrics_cli.lua use nil-guards so partial JSON never causes runtime errors
- pcall wraps Util.jsonDecode to handle corrupted metrics.json gracefully (covers threat T-23-04)
- runMetrics() checks fs.exists before shell.run, prevents error if metrics_cli.lua is absent (covers threat T-23-06)
- Followed established doctor.lua pattern for standalone CLI modules called via shell.run

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - metrics_cli.lua reads live data from data/metrics.json written by Plan 01's engine flush.

## Threat Surface Scan

No new security-relevant surfaces beyond those documented in the plan's threat model. metrics_cli.lua reads data/metrics.json read-only and never writes. startup.lua mode dispatch does not expose user input to shell operations.

## Issues Encountered

None.

## Next Phase Readiness
- Phase 23 complete: operators can run `startup metrics` to inspect performance data
- data/metrics.json is written by Plan 01 and read by Plan 02 CLI
- All 3 Phase 23 tests verify the flush contract end-to-end

## Self-Check

- modules/metrics_cli.lua: committed in ef36be6
- startup.lua metrics mode: committed in 24744f9
- tests/run.lua Phase 23 block: committed in 03e1122
- Commit ef36be6 exists: FOUND
- Commit 24744f9 exists: FOUND
- Commit 03e1122 exists: FOUND

## Self-Check: PASSED

---
*Phase: 23-metricas-persistentes*
*Completed: 2026-04-30*
