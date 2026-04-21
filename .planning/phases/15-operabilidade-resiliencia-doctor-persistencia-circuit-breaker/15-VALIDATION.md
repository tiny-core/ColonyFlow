---
phase: 15
slug: operabilidade-resiliencia-doctor-persistencia-circuit-breaker
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-19
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | CC: Tweaked custom harness (`tests/run.lua`) |
| **Config file** | none |
| **Quick run command** | `startup test` |
| **Full suite command** | `startup test` |
| **Estimated runtime** | ~seconds (depends on CC) |

---

## Sampling Rate

- **After every task commit:** Run `startup test`
- **After every plan wave:** Run `startup test`
- **Before `/gsd-verify-work`:** `startup test` must be green
- **Max feedback latency:** keep under a few minutes (manual run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | N/A | T-15-01 | Doctor output nao vaza dados sensiveis; safe calls | manual | `startup doctor` | ✅ | ⬜ pending |
| 15-01-02 | 01 | 1 | N/A | T-15-02 | Escrita atomica evita corrupcao em reboot | unit+manual | `startup test` | ✅ | ⬜ pending |
| 15-01-03 | 01 | 1 | N/A | T-15-03 | Circuit breaker reduz DoS por chamadas repetidas | unit+manual | `startup test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/run.lua` inclui testes para persistencia (encode/decode + writeFileAtomic via mock de fs)
- [ ] `tests/run.lua` inclui testes para circuit breaker/backoff do ME (mock de meBridge)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Persistir e retomar jobs apos reboot | N/A | Depende de reboot real do computador | Iniciar job, reboot, confirmar que job reaparece e nao duplica crafts |
| Reduzir spam quando ME oscila/offline | N/A | Depende de ambiente ME real | Desligar ME, observar degraded/backoff, religar e confirmar recuperacao |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
