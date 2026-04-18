---
phase: 13
slug: operabilidade-update-check-config-backoff-detalhes
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-18
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | custom (tests/run.lua) |
| **Config file** | tests/run.lua |
| **Quick run command** | `startup test` |
| **Full suite command** | `startup test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `startup test`
- **After every plan wave:** Run `startup test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | TBD | T-13-01 | No spam / safe defaults | unit | `startup test` | ✅ | ⬜ pending |
| 13-01-02 | 01 | 1 | TBD | T-13-02 | Backoff capped / no lockup | unit | `startup test` | ✅ | ⬜ pending |
| 13-01-03 | 01 | 1 | TBD | T-13-03 | UI ASCII-only / truncation | unit+manual | `startup test` | ✅ | ⬜ pending |
| 13-01-04 | 01 | 1 | TBD | T-13-04 | No background crash | unit | `startup test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase needs (tests/run.lua already present).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Update details view no Monitor 2 | TBD | Peripheral + layout | Seguir `.planning/phases/13-operabilidade-update-check-config-backoff-detalhes/13-VERIFICATION.md` |
| Backoff com HTTP off/bloqueado | TBD | HTTP environment | Seguir `.planning/phases/13-operabilidade-update-check-config-backoff-detalhes/13-VERIFICATION.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<verify>` with automated command or explicit manual steps
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
