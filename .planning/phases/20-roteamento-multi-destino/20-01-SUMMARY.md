---
phase: 20-roteamento-multi-destino
plan: 01
subsystem: engine
tags: [lua, routing, delivery, config, peripheral, health]

# Dependency graph
requires:
  - phase: 18-refactor-snapshots
    provides: getDestinationSnapshot com cache parametrizado por targetName
  - phase: 10-config-cli
    provides: estrutura Config.lua com DEFAULT_INI e API cfg:get/getList
provides:
  - resolveRoutedTarget(cfg, itemName) em modules/engine.lua
  - secao [delivery_routing] com 11 chaves vazias em lib/config.lua DEFAULT_INI
  - roteamento per-request no tick loop com ctx sobrescrito por destino roteado
  - health display "Targets: X/Y online" substituindo "Target: Online/Offline"
affects:
  - 20-02 (config_cli delivery_routing menu le as mesmas chaves)
  - 20-03 (testes devem usar resolveRoutedTarget e as chaves de config)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - resolveRoutedTarget: guessClass + cfg:get("delivery_routing", cls, "") + peripheral.isPresent como padrao de resolucao de destino por classe
    - ctx per-request: ctx base compartilhado + sobrescrita de snap/targetName/targetInv por request dentro do tick loop
    - health counter: iterar ROUTING_CLASSES + peripheral.isPresent para contar X/Y online

key-files:
  created: []
  modified:
    - lib/config.lua
    - modules/engine.lua

key-decisions:
  - "Verificacao de saude usa resolveTarget (default) — se offline, aborta tick inteiro (comportamento preservado D-03)"
  - "available compartilhado entre todos os requests do tick para evitar over-allocation mesmo com destinos diferentes"
  - "Snapshot do destino roteado reutiliza cache por targetName — sem IO redundante para mesmo destino no mesmo tick (D-04, D-05)"
  - "Health usa cfg:get com trim() local ja existente em buildPeripheralHealth"

patterns-established:
  - "resolveRoutedTarget: class lookup + peripheral gate + fallback para resolveTarget"
  - "ctx per-request dentro do while loop do tick"

requirements-completed: [phase-20]

# Metrics
duration: 12min
completed: 2026-04-26
---

# Phase 20 Plan 01: Roteamento Multi-Destino — Nucleo Summary

**resolveRoutedTarget por classe de item com fallback para default_target_container, roteamento per-request no tick loop e health display "Targets: X/Y online" em Lua/CC:Tweaked**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-26T21:13:23Z
- **Completed:** 2026-04-26T21:25:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Secao [delivery_routing] com 11 chaves vazias (armor_helmet..tool_shield) inserida no DEFAULT_INI de lib/config.lua; cfg:get retorna "" como sentinela de fallback (D-02)
- resolveRoutedTarget(cfg, itemName) definida em modules/engine.lua apos resolveTarget; usa guessClass + cfg:get + peripheral.isPresent com fallback automatico (D-01, D-02, D-03)
- Tick loop modificado: resolveTarget como verificacao de saude pre-loop; ctx construido per-request com destino roteado especifico para cada requisicao; cache de snapshot reutilizado quando destino == default (D-04, D-05)
- buildPeripheralHealth substituiu "Target: Online/Offline" por "Targets: X/Y online" contando default_target_container + destinos roteados nao-vazios (D-07)

## Task Commits

1. **Task 1: Adicionar defaults [delivery_routing] em lib/config.lua** - `8dd7d24` (feat)
2. **Task 2: Implementar resolveRoutedTarget + roteamento per-request + health update** - `41bce5d` (feat)

## Files Created/Modified

- `lib/config.lua` - Adicionada secao [delivery_routing] com 11 chaves vazias antes do `]]` do heredoc DEFAULT_INI
- `modules/engine.lua` - Adicionada resolveRoutedTarget, tick loop com roteamento per-request, health exibe "Targets: X/Y online"

## Decisions Made

- Verificacao de saude pre-loop usa `resolveTarget` (default) — se o default estiver offline, todo o tick aborta; comportamento original preservado (D-03)
- O campo `available` do ctx e compartilhado entre todos os requests do tick para garantir que a alocacao nao ultrapasse o estoque real mesmo quando destinos sao diferentes
- Reutilizacao do snapshot: quando `routedName == defaultTargetName`, usa `defaultSnap` sem nova chamada a `getDestinationSnapshot` (D-04, D-05)
- `trim()` local ja existia em `buildPeripheralHealth` (linha 524); usada diretamente sem importacao adicional

## Deviations from Plan

None - plano executado exatamente como especificado.

## Issues Encountered

- Lua nao disponivel como CLI no ambiente de execucao — verificacoes foram feitas por leitura direta dos arquivos editados confirmando presenca das strings esperadas.

## Known Stubs

None — todos os valores sao funcionais; chaves vazias em [delivery_routing] sao o comportamento correto (sentinela para "usa default").

## Threat Flags

Nenhuma nova superficie de seguranca fora do threat_model do plano. resolveRoutedTarget passa nome de periferico vindo de config apenas para `peripheral.isPresent`/`peripheral.wrap` (CC:Tweaked sandbox, T-20-01 aceito).

## User Setup Required

None — nenhuma configuracao externa necessaria. Para usar roteamento, o operador configura os nomes dos perifericos via config.ini (chaves em [delivery_routing]).

## Next Phase Readiness

- Nucleo de roteamento pronto para Plan 02 (config_cli menu de delivery_routing)
- Plan 03 (testes de roteamento) pode ser implementado usando inline stub de resolveRoutedTarget conforme padrao makeCfg existente em tests/run.lua

---
*Phase: 20-roteamento-multi-destino*
*Completed: 2026-04-26*
