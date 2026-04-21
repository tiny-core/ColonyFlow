---
phase: 18
slug: refactor-snapshots-reduzir-io-acoplamento
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 18 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | CC: Tweaked custom harness (`tests/run.lua`) |
| **Quick run command** | `startup test` |
| **Full suite command** | `startup test` |

## Sampling Rate

- After every task commit: run `startup test`
- Before verify-work: `startup test` must be green

## Per-Task Verification Map

| Task ID | Plan | Wave | Threat Ref | Test Type | Automated Command | Status |
|---------|------|------|------------|-----------|-------------------|--------|
| 18-01-01 | 01 | 1 | T-18-01 | unit | `startup test` (snapshot_build_has_stable_keys_and_defaults) | ⬜ pending |
| 18-01-02 | 01 | 1 | T-18-01 | unit | `startup test` | ⬜ pending |
| 18-01-03 | 01 | 1 | T-18-02 | unit/manual | `startup test` (ui_tick_prefers_snapshot_view) | ⬜ pending |
| 18-01-04 | 01 | 1 | T-18-03 | unit/docs | `startup test` | ⬜ pending |

## Manual-Only Verifications

| Behavior | Why Manual | Test Instructions |
|----------|------------|-------------------|
| UI nao toca perifericos | Depende de runtime real e operacao | Rodar com monitores e confirmar operacao normal; sem erros e sem travar |

## Validation Sign-Off

- [ ] All tasks have verify coverage
- [ ] `nyquist_compliant: true` set in frontmatter
