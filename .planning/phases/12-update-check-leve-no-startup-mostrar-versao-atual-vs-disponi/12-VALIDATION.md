---
phase: 12
slug: 12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | CC: Tweaked test runner (tests/run.lua via `startup test`) |
| **Config file** | none |
| **Quick run command** | `startup test` |
| **Full suite command** | `startup test` |
| **Estimated runtime** | ~5-20 seconds (depende do mundo) |

---

## Sampling Rate

- **After every task commit:** Run `startup test`
- **After every plan wave:** Run `startup test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | REQ-TBD | T-12-01 | Nao bloquear boot; degradar quando HTTP off | unit | `startup test` | ⬜ | ⬜ pending |
| 12-01-02 | 01 | 1 | REQ-TBD | T-12-02 | Cache persistido com TTL e sem corrupcao | unit | `startup test` | ⬜ | ⬜ pending |
| 12-01-03 | 01 | 1 | REQ-TBD | T-12-01 | Loop em background protegido por `pcall` | unit | `startup test` | ⬜ | ⬜ pending |
| 12-01-04 | 01 | 1 | REQ-TBD | T-12-03 | UI discreta, ASCII-only, sem travar render | manual | — | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements, but tests must be extended for:
- URL building (install.json -> manifest_url defaults)
- Cache TTL behavior (fresh vs stale)
- Header formatting (truncation + status markers)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Header mostra `instalada->disponivel` quando update existe | REQ-TBD | Depende de monitores | Rodar sistema e observar header/busca em background |
| Status monitor mostra banner com comando `tools/install.lua update` | REQ-TBD | Depende de UI | Forcar update disponivel (ou simular) e observar |
| HTTP indisponivel mostra `UPD:OFF` sem interromper operacao | REQ-TBD | Depende do ambiente | Desabilitar HTTP no mundo/servidor e observar |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
