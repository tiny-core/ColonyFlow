# Phase 20: Roteamento Multi-Destino

## Goal
Permitir que cada classe de item (armor_helmet, tool_pickaxe etc.) tenha um inventário de destino dedicado, com fallback automático para o `default_target_container` quando a classe não estiver mapeada ou o inventário configurado estiver offline.

## Problem
Hoje o sistema tem um único destino (`delivery.default_target_container`). Em colonies maiores, o player precisa rotear ferramentas para um rack de ferramentas e armaduras para outro. Sem isso, tudo vai para o mesmo inventário e o MineColonies pode não encontrar os itens.

## Behavior
- Novas chaves em `config.ini` sob `[delivery_routing]`: `armor_helmet`, `armor_chestplate`, `armor_leggings`, `armor_boots`, `tool_pickaxe`, `tool_shovel`, `tool_axe`, `tool_hoe`, `tool_sword`, `tool_bow`, `tool_shield`
- Se a classe do item pedido tiver inventário configurado e online → usa esse inventário
- Se não configurado ou offline → fallback para `default_target_container` (comportamento atual)
- Se `default_target_container` também offline → comportamento atual (waiting_retry)
- Config CLI (`modules/config_cli.lua`) expõe a seção delivery_routing
- Testes cobrem: classe mapeada online, classe mapeada offline (fallback), classe não mapeada (fallback), item sem classe (default)

## Files Likely Touched
- `lib/config.lua` — defaults da seção delivery_routing
- `lib/config_schema.lua` — validação dos nomes de periférico
- `modules/config_cli.lua` — menu delivery_routing
- `modules/engine.lua` — lógica de seleção de destino
- `tests/run.lua` — novos testes

## Depends On
Phase 19 (complete)

## Complexity
Medium — lógica de fallback é simples mas requer tocar engine.lua e config em vários pontos
