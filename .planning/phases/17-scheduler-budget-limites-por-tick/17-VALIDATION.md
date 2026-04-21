---
phase: 17
slug: scheduler-budget-limites-por-tick
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 17 — Validation Strategy

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
| 17-01-01 | 01 | 1 | N/A | T-17-01 | Budget defaults seguros; nao quebra config.ini existente | unit | `startup test` | ✅ | ⬜ pending |
| 17-01-02 | 01 | 1 | N/A | T-17-02 | Budget gate nao faz chamadas quando excedido | unit | `startup test` | ✅ | ⬜ pending |
| 17-01-03 | 01 | 1 | N/A | T-17-03 | Engine limita trabalho por tick e retoma corretamente | unit | `startup test` | ✅ | ⬜ pending |
| 17-01-04 | 01 | 1 | N/A | T-17-04 | UI nao quebra layout e indica throttling | manual | (in-world) | ✅ | ⬜ pending |
| 17-01-05 | 01 | 1 | N/A | T-17-05 | Log nao spama; throttle loga transicoes | manual | (in-world) | ✅ | ⬜ pending |
| 17-01-06 | 01 | 1 | N/A | — | Checklist de verificacao/validacao existe e e acionavel | docs | N/A | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Indicador de throttling em UI | N/A | Depende de monitores e runtime real | Gerar backlog; observar Status mostrar THROTTLED e o sistema seguir responsivo |
| Reducao de picos sob backlog | N/A | Depende de perifericos reais e volume real | Aumentar requests; confirmar que o loop nao trava e backlog reduz ao longo do tempo |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
