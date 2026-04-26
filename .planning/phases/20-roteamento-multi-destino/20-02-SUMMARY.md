---
phase: 20-roteamento-multi-destino
plan: 02
subsystem: ui
tags: [lua, config-cli, routing, delivery, tests, cc-tweaked]

# Dependency graph
requires:
  - phase: 20-roteamento-multi-destino
    plan: 01
    provides: resolveRoutedTarget(cfg, itemName) e secao [delivery_routing] em lib/config.lua
provides:
  - runDeliveryRoutingMenu em modules/config_cli.lua com entrada no menu principal
  - 4 testes de roteamento (D-08) em tests/run.lua
affects:
  - 20-03 (health display ja tem base; testes de routing prontos)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - runDeliveryRoutingMenu: ROUTING_CLASS_KEYS + loop sobre ipairs + buildEffective(.delivery_routing) + prompt para editar cada classe
    - routing tests: inline stub de guessClass + resolveRoutedTarget + peripheral mock por teste (padrao makeCfg existente)

key-files:
  created: []
  modified:
    - modules/config_cli.lua
    - tests/run.lua

key-decisions:
  - "ROUTING_CLASS_KEYS definida como constante local antes de runDeliveryRoutingMenu para reutilizacao futura"
  - "Testes usam stub inline de resolveRoutedTarget (6 linhas) ao inves de extrair para lib/routing.lua — evita nova dependencia, segue padrao makeCfg existente"
  - "routing_classe_nao_mapeada usa makeCfg com armor_helmet='' — makeCfg retorna default ('') confirmando comportamento de sentinela correto"

patterns-established:
  - "runDeliveryRoutingMenu: estrutura de menu sobre lista de chaves fixas com suffix mostrando valor atual ou '()'"
  - "testes de roteamento: guessClassStub + resolveTargetStub + resolveRoutedTargetStub inline com peripheral mock por pcall"

requirements-completed: [phase-20]

# Metrics
duration: 8min
completed: 2026-04-26
---

# Phase 20 Plan 02: Config CLI delivery_routing menu + 4 testes de roteamento Summary

**Menu estatico de 11 classes em Config CLI para configurar destinos por classe de item, com 4 testes de regressao inline validando logica de fallback de resolveRoutedTarget**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-26T21:12:00Z
- **Completed:** 2026-04-26T21:20:02Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- FIELD_LABELS estendido com 11 labels (Helmet..Shield); buildEffective/buildChangedOnly/saveIni estendidos para delivery_routing; runDeliveryRoutingMenu implementada com loop, labels de valor atual e Salvar/Voltar (D-06)
- main() inicializa updates.delivery_routing = {} e exibe "Roteamento de destino" entre "Delivery" e "Update-check"
- 4 testes de roteamento adicionados em tests/run.lua usando stub inline: classe mapeada online, classe mapeada offline, classe nao mapeada e item sem classe (D-08)

## Task Commits

1. **Task 1: Adicionar menu delivery_routing ao Config CLI** - `fb58682` (feat)
2. **Task 2: Adicionar 4 testes de roteamento em tests/run.lua** - `582a5e6` (feat)

## Files Created/Modified

- `modules/config_cli.lua` - FIELD_LABELS + buildEffective + buildChangedOnly + saveIni + ROUTING_CLASS_KEYS + runDeliveryRoutingMenu + main() modificado
- `tests/run.lua` - 4 testes routing_* adicionados ao final da tabela tests

## Decisions Made

- ROUTING_CLASS_KEYS extraida como constante local antes da funcao para clareza e possivel reuso
- Testes usam stub inline (opcao 2 do PATTERNS.md) ao inves de extrair lib/routing.lua — evita nova dependencia e segue o padrao makeCfg ja estabelecido no projeto
- `routing_classe_nao_mapeada` confia corretamente em `makeCfg:get` retornar `""` (o default passado) quando o valor armazenado e `""`, confirmando o sentinela

## Deviations from Plan

None - plano executado exatamente como especificado.

## Issues Encountered

None.

## Known Stubs

None — runDeliveryRoutingMenu exibe e persiste dados reais de config.ini; testes validam logica real de fallback.

## Threat Flags

Nenhuma nova superficie de seguranca fora do threat_model do plano. Entrada do usuario em runDeliveryRoutingMenu passa pelo trim() e e armazenada via saveIni com escrita atomica (T-20-05 mitigado).

## User Setup Required

None - nenhuma configuracao externa necessaria. Para usar o menu no CC: `startup config` -> "Roteamento de destino".

## Next Phase Readiness

- Config CLI completo para delivery_routing; usuario pode configurar destinos por classe in-game
- Testes de roteamento prontos para validacao no CC com `startup test`
- Plan 03 (doctor/healthcheck "Targets: X/Y online") pode ser implementado — base do contador ja existe em engine.lua (buildPeripheralHealth)

## Self-Check: PASSED

- FOUND: modules/config_cli.lua (runDeliveryRoutingMenu, Roteamento de destino, delivery_routing={}, changedOnly.delivery_routing)
- FOUND: tests/run.lua (routing_classe_mapeada_e_online, routing_classe_mapeada_e_offline, routing_classe_nao_mapeada, routing_item_sem_classe)
- FOUND: .planning/phases/20-roteamento-multi-destino/20-02-SUMMARY.md
- FOUND: fb58682 (feat(20-02): add delivery_routing menu to Config CLI)
- FOUND: 582a5e6 (feat(20-02): add 4 routing tests to test harness)
- No file deletions detected

---
*Phase: 20-roteamento-multi-destino*
*Completed: 2026-04-26*
