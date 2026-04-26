---
phase: 07-auto-setup-compatibilidade-mp
plan: 01
subsystem: core
tags: [setup, config, peripherals, multiplayer]
requires: []
provides: [auto-setup, resilient-discovery]
affects: [bootstrap, config, peripherals, equivalence]
tech-stack:
  added: []
  patterns: [pcall, fallback, default-generation]
key-files:
  created: []
  modified:
    - lib/config.lua
    - lib/bootstrap.lua
    - modules/equivalence.lua
    - modules/peripherals.lua
    - tests/run.lua
key-decisions:
  - id: auto-setup-defaults
    description: "Gerar config.ini e data/mappings.json vazios/skeleton automaticamente quando ausentes"
    rationale: "Reduz o atrito de instalacao e evita que o sistema crashe na primeira execucao"
  - id: pcall-peripherals
    description: "Envolver as APIs do peripheral (find, wrap, getNames) em pcall"
    rationale: "No multiplayer, permissoes ou limitacoes de blocos de terceiros podem lancar erros lua (yield) que crashavam a thread principal"
requirements: [CFG-02, CFG-03, ROB-02]
metrics:
  duration: "10 min"
  completed: 2026-04-11T17:04:14Z
---

# Phase 07 Plan 01: Auto-Setup + Compatibilidade MP Summary

Sistema de setup automatizado implementado. O \config.ini\ e o banco de dados \mappings.json\ agora sao gerados automaticamente com defaults razoaveis se nao existirem. O discovery de perifericos foi reescrito usando \pcall\ para ser resiliente a erros de API do Computercraft (comuns em ambientes Multiplayer devido a claims/permissoes). Os logs de erro de perifericos agora incluem orientacoes claras e acionaveis de como ajustar o \config.ini\.

## Completed Tasks

1. **Auto-gerar config.ini com template padrão**: Adicionado \Config.ensureDefaults\ que recria o arquivo e loga detalhadamente as chaves default aplicadas.
2. **Garantir mappings.json com estrutura mínima**: \loadDb\ agora cria um skeleton valido se o arquivo nao existir.
3. **Melhorar diagnóstico de periféricos**: APIs do Computercraft agora usam wrappers com \pcall\. Logs incluem nome configurado, tipo esperado, dica de configuracao e lista dos perifericos disponiveis na rede.
4. **Adicionar testes**: Inclusos testes no \un.lua\ validando comportamento sem depender de ambiente ou file system real.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
