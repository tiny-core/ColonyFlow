---
phase: 08-mapping-v2
plan: 01
subsystem: mapping
tags: [mapping, equivalence, cli, v2]
requires: []
provides: [mapping-v2, rule-indexing, prefer-equivalent]
affects: [equivalence, engine, mapping-cli, mappings-db]
tech-stack:
  added: []
  patterns: [defensive-json-load, in-memory-fallback, hot-reload, keyboard-tui]
key-files:
  created: []
  modified:
    - data/mappings.json
    - modules/equivalence.lua
    - modules/engine.lua
    - modules/mapping_cli.lua
    - tests/run.lua
key-decisions:
  - id: v2-rules-by-selector
    description: "Adotar mappings v2 com regras por selector (item/tag) e classe explícita"
    rationale: "Simplifica edição e permite classificação por tags, reduzindo pares item↔item"
  - id: prefer-equivalent-per-selector
    description: "Implementar prefer_equivalent por regra (item/tag) para decidir vanilla-first vs mod-first"
    rationale: "Torna a escolha previsível e ajustável caso a caso sem alterar política global"
requirements: [CFG-04, EQ-01, EQ-02, TIER-01, TIER-02]
metrics:
  completed: 2026-04-12
---

# Phase 08 Plan 01: Mapping v2 Summary

Implementado um formato v2 de mapeamentos baseado em regras por selector (ID de item ou tag) com classe explícita e preferência `prefer_equivalent`. O loader agora lê `data/mappings.json` com validação mínima e indexa regras por item e por tag, mantendo compatibilidade com o formato v1 e preservando campos legacy (`items/classes/tier_overrides/gating`). O Engine passa a considerar regras por tag durante a seleção de candidatos e aplica a preferência vanilla/mod por regra sem quebrar o tier gating.

## Completed Tasks

1. **DB v2 (skeleton)**: `data/mappings.json` atualizado para `version=2` com `rules=[]`, preservando campos legacy.
2. **Loader + API v2**: `modules/equivalence.lua` ganhou indexação de regras por item/tag e APIs `getClassFor`, `getPreferEquivalentFor`, `isAllowedFor`, com leitura defensiva e fallback em memória.
3. **Integração no Engine**: `modules/engine.lua` passa a usar `getClassFor` (com tags), aplica `prefer_equivalent` no scoring vanilla/mod e corrige heurística `guessClass`/expansão de armaduras vanilla.
4. **Editor (startup map)**: `modules/mapping_cli.lua` reescrito para CRUD de regras v2 com navegação por setas e Enter, incluindo tier overrides para items.
5. **Testes**: `tests/run.lua` recebeu cobertura para carregamento v2 por item/tag, fallback v1 e semântica de `prefer_equivalent`.

## Verification Notes

- Verificação automática no host não foi executada (sem runtime Lua instalado). Validar in-game:
  - Rodar `startup test` e garantir que passa.
  - Rodar `startup map`, criar regra por ID e por tag, salvar e observar efeito no próximo ciclo (hot-reload) e nos logs.

## Self-Check: PENDING (in-world)
