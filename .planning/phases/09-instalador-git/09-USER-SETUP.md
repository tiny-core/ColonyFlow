# Phase 09: User Setup Required

**Generated:** 2026-04-12
**Phase:** 09-instalador-git
**Status:** Incomplete

Complete estes itens in-world para validar o instalador. O código já foi implementado; estes passos exigem execução manual no CC: Tweaked.

## Environment Variables

None.

## Account Setup

None.

## Dashboard Configuration

None.

## Verification

- [ ] **Bootstrap em computador “limpo”**
  - Em um Advanced Computer vazio: rodar `wget run <raw-url>/tools/install.lua install` apontando para o repositório.
  - Confirmar que os arquivos são criados e que `startup.lua` roda sem crash ao final.

- [ ] **Update preserva dados/config**
  - Alterar `config.ini` e `data/mappings.json`.
  - Rodar `tools/install.lua update`.
  - Confirmar preservação (output deve mostrar `SKIP(preserved)` para os preservados) e `data/version.json` atualizado.

- [ ] **HTTP desabilitado é acionável**
  - Desabilitar HTTP no ambiente (modpack/servidor).
  - Rodar `tools/install.lua doctor`.
  - Confirmar instruções claras do que habilitar e por quê.

---

**Once all items complete:** Mark status as "Complete" at top of file.
