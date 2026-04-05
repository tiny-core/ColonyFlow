---
phase: 02-n-cleo-de-requisi-es-filtros
plan: 01
subsystem: "requests-core"
tags: [cc-tweaked, minecolonies, filters, tiers, equivalence, gsd]
provides: [request-normalization, destination-reconcile, missing-calculation, candidate-selection]
affects: [config.ini, lib/config.lua, modules/minecolonies.lua, modules/inventory.lua, modules/equivalence.lua, modules/engine.lua, tests/run.lua, .planning/ROADMAP.md]
completed: 2026-04-05
---

# Phase 2: Núcleo de Requisições + Filtros Summary

## Entregas principais

- Normalização de requests com `accepted[]`, `requiredCount` e `id` estável quando `r.id` não existir.
- Reconciliação de destino com snapshot do inventário (varredura completa via `list()`), cache TTL e cálculo de faltante real.
- Política de seleção de candidato restrita a `accepted[]`, com preferência configurável (vanilla/mod e lowest/highest tier) e allowlist para itens de mod via `data/mappings.json`.
- Engine refatorada para não depender de ME Bridge nesta fase (sem craft/export); o output é o snapshot de `work` com `present/missing` e motivos.

## Arquivos alterados

- config.ini
- lib/config.lua
- modules/minecolonies.lua
- modules/inventory.lua
- modules/equivalence.lua
- modules/engine.lua
- tests/run.lua
- .planning/ROADMAP.md

## Observações

- A verificação operacional desta fase depende de rodar `tests/run.lua` e validar em-world a leitura do destino configurado (periférico real).
