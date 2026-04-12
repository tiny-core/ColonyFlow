---
phase: 09
slug: instalador-git
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-12
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | CC: Tweaked in-world tests (`startup test`) + verificação manual guiada |
| **Config file** | `tests/run.lua` |
| **Quick run command** | `startup test` |
| **Full suite command** | `startup test` |
| **Estimated runtime** | ~5–30 seconds (depende do ambiente CC) |

---

## Sampling Rate

- **After every task commit:** Run `startup test` (quando o task modificar arquivos executáveis/testes)
- **After every plan wave:** Run `startup test`
- **Before `/gsd-verify-work`:** Rodar `startup test` e executar o checklist manual desta fase
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | CFG-01 | T-09-01 | Instalador não deixa arquivos extras na raiz e mantém estrutura modular | manual | `startup test` | ✅ | ⬜ pending |
| 09-01-02 | 01 | 1 | ROB-01 | T-09-02 | Update é 2 fases + snapshot + rollback; falha não deixa estado parcial | manual | `startup test` | ✅ | ⬜ pending |
| 09-01-03 | 01 | 1 | ROB-01 | T-09-03 | Erros de HTTP/permissão geram mensagens acionáveis e saída limpa | manual | `startup test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bootstrap em computador “limpo” | CFG-01 | Depende de ambiente/HTTP/wget in-world | Em um computador vazio: `wget run <raw-url>/tools/install.lua install`; confirmar que cria estrutura e roda `startup.lua` ao final. |
| Update preserva config/dados | ROB-01 | Precisa validar preservação real | Alterar `config.ini` e `data/mappings.json`, rodar `tools/install.lua update`, confirmar que ambos não foram sobrescritos. |
| Falha de HTTP é acionável | ROB-01 | Depende de config do servidor/modpack | Desabilitar HTTP, rodar `tools/install.lua doctor` e confirmar instruções claras do que habilitar. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

