---
phase: 11
slug: 11-versionamento-robusto-versao-real-script-node-para-regenerar
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
---

# Phase 11 — Validation Strategy

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
| 11-01-01 | 01 | 1 | REQ-TBD | T-11-01 | Rejeitar manifesto sem `version` (mensagem ASCII) | unit | `startup test` | ✅ | ⬜ pending |
| 11-01-02 | 01 | 1 | REQ-TBD | T-11-02 | Persistir `version` em `data/version.json` sem quebrar schema antigo | unit | `startup test` | ✅ | ⬜ pending |
| 11-01-03 | 01 | 1 | REQ-TBD | T-11-03 | Geracao deterministica de `manifest.json` (offline) | manual | — | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Script Node regenera `manifest.json` com `version` e `size` | REQ-TBD | Fora do runtime do CC | Rodar `node tools/gen_manifest.js` e conferir JSON gerado |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
