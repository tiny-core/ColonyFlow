---
phase: 14
slug: ui-status-saude-perifericos-coluna
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-18
---

# Phase 14 - Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | custom Lua harness |
| Config file | `tests/run.lua` |
| Quick run command | `startup test` |
| Full suite command | `startup test` |
| Estimated runtime | ~10-30 seconds |

## Sampling Rate

- After every task commit: run `startup test`
- After phase wave complete: run `startup test`
- Before `/gsd-verify-work`: run full `startup test` with green result
- Max feedback latency: 30 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | TBD | T-14-01 | Health snapshot uses TTL cache and avoids repeated peripheral polling | unit/manual | `startup test` | ✅ | ✅ done |
| 14-01-02 | 01 | 1 | TBD | T-14-02 | UI keeps stable two-column alignment and bounded truncation | unit/manual | `startup test` | ✅ | ✅ done |
| 14-01-03 | 01 | 1 | TBD | T-14-03 | Colored online/offline state does not misreport ME grid status | unit/manual | `startup test` | ✅ | ✅ done |

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Monitor 2 side-by-side column rendering | TBD | depends on in-world monitor size | Run `startup`; inspect OPERACAO block in monitor status |
| ME online/offline color transition | TBD | needs real/injected peripheral state | Toggle ME bridge availability and confirm green/red change |
| UI responsiveness under loop | TBD | runtime behavior | Observe 30s with active loop; confirm no heavy flicker |

## Validation Sign-Off

- [x] All tasks have automated verify or existing test harness coverage
- [x] Sampling continuity maintained (`startup test` after each task)
- [x] Wave 0 not required for new framework setup
- [x] No watch-mode flags
- [x] Feedback latency target < 30s
- [x] `nyquist_compliant: true` in frontmatter

**Approval:** approved
