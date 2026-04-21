---
phase: 16
slug: observabilidade-performance-metricas-contadores
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-21
---

# Phase 16 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | custom (tests/run.lua) |
| **Quick run command** | `startup test` |
| **Full suite command** | `startup test` |

## Sampling Rate

- After every task commit: `startup test`
- Before verification: `startup test` must be green

## Per-Task Verification Map

| Task ID | Plan | Wave | Threat Ref | Test Type | Automated Command | Status |
|---------|------|------|------------|----------|-------------------|--------|
| 16-01-01 | 01 | 1 | T-16-01 | unit | `startup test` | ⬜ pending |
| 16-01-02 | 01 | 1 | T-16-01 | unit | `startup test` | ⬜ pending |
| 16-01-03 | 01 | 1 | T-16-01 | unit | `startup test` | ⬜ pending |
| 16-01-04 | 01 | 1 | T-16-03 | unit | `startup test` | ⬜ pending |
| 16-01-05 | 01 | 1 | T-16-02 | manual | - | ⬜ pending |
| 16-01-06 | 01 | 1 | T-16-02 | manual | - | ⬜ pending |
| 16-01-07 | 01 | 1 | T-16-01 | unit | `startup test` | ⬜ pending |
| 16-01-08 | 01 | 1 | - | doc | - | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

## Manual-Only Verifications

| Behavior | Why Manual | Test Instructions |
|----------|------------|-------------------|
| UI bloco `[PERF]` e layout | depende de monitores | Seguir `16-VERIFICATION.md` |
| DEBUG resumo throttled | depende do log_level | Seguir `16-VERIFICATION.md` |

## Validation Sign-Off

- [ ] All unit tests green (`startup test`)
- [ ] Manual checks completed
- [ ] `nyquist_compliant: true` set in frontmatter

