---
phase: 03
slug: craft-entrega-com-progressao
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-05
---

# Phase 03 — Validation Strategy

> Contrato de validação por fase para manter feedback curto durante execução.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | harness Lua (CC) em `tests/run.lua` |
| **Config file** | none |
| **Quick run command** | `tests/run.lua` |
| **Full suite command** | `tests/run.lua` |
| **Estimated runtime** | ~2-10s (depende do CC/ambiente) |

---

## Sampling Rate

- **After every task commit:** Run `tests/run.lua`
- **After every plan wave:** Run `tests/run.lua`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | ME-02 / ME-03 / ME-04 | — | N/A | unit | `tests/run.lua` | ✅ | ⬜ pending |
| 03-01-02 | 01 | 1 | DEL-03 | — | N/A | unit | `tests/run.lua` | ✅ | ⬜ pending |
| 03-01-03 | 01 | 1 | TIER-03 / MC-03 | — | N/A | unit | `tests/run.lua` | ✅ | ⬜ pending |
| 03-01-04 | 01 | 1 | EQ-03 | — | N/A | unit | `tests/run.lua` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Export real via ME Bridge para destino padrão | DEL-03 | Depende do mundo/periféricos e do posicionamento do ME Bridge | Em-world: garantir que o destino está acessível, forçar uma request com missing>0 e observar entrega e logs |
| Craft real via ME Bridge (autocrafting) | ME-04 | Depende de padrões/crafting CPUs do ME | Em-world: garantir padrão de craft, forçar missing e observar craft→estoque→entrega |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
