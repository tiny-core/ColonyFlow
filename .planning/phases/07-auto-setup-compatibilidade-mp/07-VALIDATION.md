---
phase: 07
slug: 07-auto-setup-compatibilidade-mp
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-11
---

# Phase 07 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | custom Lua harness (`tests/run.lua`) |
| **Config file** | none |
| **Quick run command** | `lua tests/run.lua` |
| **Full suite command** | `lua tests/run.lua` |
| **Estimated runtime** | ~5–20s (depende do hardware / CC) |

## Sampling Rate

- **After every task commit:** `lua tests/run.lua`
- **After wave completion:** `lua tests/run.lua`
- **Before phase verification:** `lua tests/run.lua` deve passar
- **Max feedback latency:** < 60s

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | CFG-02 | T-07-01 | Não sobrescrever config existente | unit | `lua tests/run.lua` | ✅ | ⬜ pending |
| 07-01-02 | 01 | 1 | CFG-03 | T-07-02 | Criar JSON skeleton sem corromper DB | unit | `lua tests/run.lua` | ✅ | ⬜ pending |
| 07-01-03 | 01 | 1 | ROB-02 | T-07-03 | Diagnóstico sem crash em MP | unit | `lua tests/run.lua` | ✅ | ⬜ pending |

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `config.ini` ausente → arquivo criado e sistema inicia | CFG-02 | Requer filesystem real e boot completo | Apagar/renomear `config.ini`, executar `startup.lua`, verificar criação do arquivo e logs |
| Periféricos ausentes/permissões em MP → mensagens acionáveis | ROB-02 | Depende do servidor e rede de periféricos | Simular perifericos ausentes (remover modem/ME/colony), observar logs/UI sem crash |

## Validation Sign-Off

- [ ] Todos os tasks adicionados no plano têm verificação automatizada ou manual explícita
- [ ] Não há 3 tasks consecutivos sem verificação automatizada
- [ ] `nyquist_compliant: true` após implementação e verificação

**Approval:** pending

