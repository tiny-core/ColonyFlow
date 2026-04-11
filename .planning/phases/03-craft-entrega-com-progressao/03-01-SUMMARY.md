---
phase: 03-craft-entrega-com-progressao
plan: 01
subsystem: "craft-delivery"
tags: [cc-tweaked, advanced-peripherals, ae2, minecolonies, delivery, gating, gsd]
provides: [me-bridge-compat, crafting-trigger, delivery-export, post-delivery-validation, anti-duplicate-craft, building-tier-gating]
affects: [modules/me.lua, modules/engine.lua, modules/minecolonies.lua, modules/inventory.lua, modules/equivalence.lua, data/mappings.json, tests/run.lua, .planning/ROADMAP.md]
completed: 2026-04-05
---

# Phase 3: Craft + Entrega com Progressão Summary

## Entregas principais

- Wrapper do ME Bridge mais compatível: fallbacks para nomes de método e export por periférico (`exportItemToPeripheral`) quando disponível.
- Engine integra ME para: abrir craft apenas do faltante (considerando estoque atual no ME), prevenir duplicidade com `isCrafting` + lock TTL, e exportar itens para o destino padrão.
- Entrega com validação pós-entrega: snapshot antes/depois e política de retry quando destino está cheio/erro.
- Tier gating por building: resolve building via `getBuildings()`, aplica maxTier (default por nível + override via JSON) e escolhe item aceito de tier menor quando necessário.
- Harness de testes ampliado com mocks de periféricos para cobrir: compat do ME wrapper, não duplicar craft em ticks, entrega ok, destino cheio e gating.

## Arquivos alterados

- modules/me.lua
- modules/engine.lua
- modules/equivalence.lua
- data/mappings.json
- tests/run.lua

## Observações

- A verificação completa requer testes in-world (ME Bridge real + destino real + padrões de autocrafting) para validar ME-04/DEL-03 em cenário real.
- Correção aplicada em `modules/engine.lua` para remover erro de sintaxe que impedia carregar o módulo durante `tests/run.lua`.
