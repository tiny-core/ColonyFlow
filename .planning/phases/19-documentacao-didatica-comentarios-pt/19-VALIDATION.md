---
phase: 19
slug: documentacao-didatica-comentarios-pt
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | CC: Tweaked Lua test harness (tests/run.lua) |
| **Config file** | none |
| **Quick run command** | `startup test` |
| **Full suite command** | `startup test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `startup test` (if any Lua runtime file changed)
- **After every plan wave:** Run `startup test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | — | T-19-01 | Docs geradas e linkadas corretamente | grep/file | `startup test` | ✅ | ⬜ pending |
| 19-01-02 | 01 | 1 | — | T-19-02 | Comentarios nao mudam runtime e mantem testes verdes | unit | `startup test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Links e estrutura de docs no repo | — | Docs sao conteudo humano | Confirmar que `README.md` tem secao `## Documentacao` e links para `docs/LEIA-ME-DO-CODIGO.md`, `docs/SUMMARY.md`, `docs/ARCHITECTURE.md`, `docs/PITFALLS.md` |
| Guia didatico tem roteiro de leitura e mapa do repo | — | Qualidade de explicacao | Confirmar que `docs/LEIA-ME-DO-CODIGO.md` contem as secoes: objetivo, mapa do repo, roteiro de leitura, fluxo principal, glossario |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

