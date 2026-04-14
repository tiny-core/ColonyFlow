---
phase: 12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi
plan: 01
subsystem: update-check
tags: [update, manifest, ui, cache, cc-tweaked]

requires:
  - phase: 11-versionamento-robusto-versao-real-script-node-para-regenerar
    provides: manifest.json com version + leitura local via data/version.json
provides:
  - Update-check em background (nao bloqueia boot) com TTL persistido (6h)
  - Header da UI mostra versao instalada e, quando houver, `inst->avail` (+ `UPD:OFF` quando HTTP off)
  - Banner no Monitor 2 (Status) com comando sugerido (`tools/install.lua update` / `tools/install.lua install`)
affects: [startup, ui, scheduler, installer]

tech-stack:
  added: []
  patterns: [cache persistido em data/update_check.json, loop paralelo no scheduler]

key-files:
  created: [modules/update_check.lua]
  modified: [lib/bootstrap.lua, modules/scheduler.lua, components/ui.lua, tests/run.lua, manifest.json]

key-decisions:
  - "Checagem em background com TTL 6h e retry 2x, sem travar UI/engine"
  - "UI ASCII-only: header discreto e banner apenas quando necessario"

requirements-completed: []

completed: 2026-04-14
---

# Phase 12 Plan 01: Update check leve + UI de versao instalada vs disponivel - Summary

**Update-check nao-bloqueante baseado em manifesto remoto, com cache TTL e exibicao discreta na UI (dual-monitor).**

## Accomplishments

- Modulo `modules/update_check.lua` para montar manifest URL (defaults do instalador), ler/escrever cache e checar manifesto remoto com retry limitado
- Bootstrap inicializa `state.installed` (data/version.json) e `state.update` (cache persistido) para a UI renderizar desde o primeiro frame
- Scheduler roda `loopUpdateCheck` em paralelo com engine/ui/eventos e registra logs INFO quando status muda (sem spam)
- UI troca placeholder por header real (hora + versao instalada, `inst->avail` quando update, `UPD:OFF` quando HTTP off)
- Monitor 2 (Status) exibe banner/linha com comando sugerido quando update existe ou quando a versao instalada nao existe

## Files Created/Modified

- modules/update_check.lua
- lib/bootstrap.lua
- modules/scheduler.lua
- components/ui.lua
- tests/run.lua
- manifest.json (regenerado via tools/gen_manifest.js para incluir modules/update_check.lua e sizes atualizados)

## Verification

- Automated: rodar `startup test` in-world
- Manual: seguir [12-VERIFICATION.md](file:///d:/Game/Minecraft/Instances/All%20the%20Mods%2010%20-%20ATM10/saves/Tests/computercraft/computer/0/.planning/phases/12-update-check-leve-no-startup-mostrar-versao-atual-vs-disponi/12-VERIFICATION.md)
