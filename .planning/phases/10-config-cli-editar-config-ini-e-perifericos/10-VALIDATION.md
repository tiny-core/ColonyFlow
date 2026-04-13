---
phase: 10
slug: config-cli-editar-config-ini-e-perifericos
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | cc-tweaked lua tests (tests/run.lua) |
| **Config file** | none |
| **Quick run command** | `startup test` |
| **Full suite command** | `startup test` |
| **Estimated runtime** | ~2 seconds |

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
| 10-01-01 | 01 | 1 | — | — | N/A | unit | `startup test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_config_cli_ini_patch.lua` — unit tests para patcher do INI (preserva comentarios e chaves desconhecidas)
- [ ] `tests/test_config_cli_validation.lua` — unit tests para validacoes (enums/ranges/monitores duplicados)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rodar `startup config` e navegar no menu, salvar e checar que o arquivo manteve comentarios | — | Interacao TUI e ambiente de perifericos variam | 1) `startup config` 2) Ajustar `log_level` 3) Salvar 4) Abrir `config.ini` e conferir comentarios |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
