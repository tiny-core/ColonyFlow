# Phase 03: Craft + Entrega com Progressão — Research

**Date:** 2026-04-05

## Summary

Esta fase encaixa bem no codebase atual porque:
- `modules/engine.lua` já calcula `missing` e mantém `self.work` por request
- `modules/me.lua` já existe como wrapper do ME Bridge, mas precisa compatibilidade com variações de nomes de método e com export para periféricos na rede
- `modules/minecolonies.lua:listBuildings()` já retorna `type` e `level` para aplicar gating (MC-03)

O foco da implementação deve ser:
- manter o loop resiliente (degradado quando ME/destino falham)
- evitar duplicidade de crafts (isCrafting + lock TTL)
- aplicar gating por building (fail closed quando não resolver)
- tornar estados rastreáveis para UI na Phase 4 (`crafting`/`delivering`/`waiting_retry`/`blocked_by_tier`)

## ME Bridge (Advanced Peripherals) — Notas de API

Os filtros de item aceitam pelo menos `{ name, count?, nbt? }` e também podem aceitar `fingerprint` quando aplicável. `craftItem` retorna `(success: boolean, message: string)` e existe o evento `crafting` que espelha esse retorno. `getItem` pode retornar `amount` e `isCraftable` dependendo do item no sistema. `exportItem` exporta para um inventário adjacente por direção e `exportItemToPeripheral` exporta para um container na rede periférica (quando disponível). [docs](https://docs.advanced-peripherals.de/latest/peripherals/me_bridge/)【web_search_result:1†L1-L4】

Riscos/armadilhas observáveis:
- a API pode variar por versão (ex.: `isItemCrafting` vs `isCrafting`, `isItemCraftable` vs `isCraftable`), então o wrapper precisa tentar múltiplos nomes antes de falhar.
- dependendo da versão, algumas chamadas podem exigir que “o item exista no sistema” para certas operações; o fluxo deve tolerar erros e seguir com retry/backoff.

## Recomendações de implementação (concretas)

### 1) Evoluir `modules/me.lua` para compatibilidade

Adicionar fallback de nomes:
- `isCrafting`: tentar `isCrafting` e depois `isItemCrafting`
- `isCraftable`: tentar `isCraftable` e depois `isItemCraftable`
- export: expor `exportItemToPeripheral` quando existir; manter `exportItem` como fallback

Além disso:
- padronizar retorno `(res, err)` sem jogar exceção (já usa `Util.safeCall`)
- preferir **export para periférico por nome** quando `exportItemToPeripheral` existir, pois o projeto já trabalha com periféricos resolvidos por nome (não por direção)

### 2) Estados e máquina de trabalho em `modules/engine.lua`

Extender o estado por request (em `self.work[id]`) para acomodar:
- `status`: `pending` | `crafting` | `delivering` | `waiting_retry` | `blocked_by_tier` | `done` | `error`
- `chosen`, `needed`, `present`, `missing`
- `craft`: `{ key=item+qtd, started_at, last_seen_crafting, last_message }`
- `lock_key` e `lock_until` (TTL 15s) usando `state.cache` (namespace ex.: `"craft_lock"`)

Fluxo recomendado por tick (alto nível):
1. validar periféricos essenciais (colonyIntegrator, destino padrão; ME pode ser degradado)
2. construir lista de buildings (cache TTL curto) para gating
3. para cada request pendente:
   - escolher candidato entre `accepted[]` priorizando estoque no ME, respeitando gating
   - se gating bloquear todos: `blocked_by_tier` + retry/backoff
   - se `missing == 0`: marcar `done`
   - se `missing > 0`:
     - checar anti-duplicidade: `isCrafting({name,count})` ou lock local (item+qtd+destino)
     - se não estiver craftando: checar craftável e disparar `craftItem({name,count=missing})`
     - manter `status=crafting` enquanto `isCrafting` for true ou até observar mudança de estoque
   - quando houver estoque suficiente (ou parcial, conforme decisão D-01/D-04): partir para `delivering` e chamar export para destino
4. validar pós-entrega por snapshot do destino; se destino cheio/erro, voltar para `waiting_retry`

### 3) Tier gating por building (MC-03 + TIER-03)

Pontos em aberto (a resolver no plano):
- como mapear `request.target` para um building específico (por `name` vs `type`)
- estrutura do override JSON (D-14): colocar dentro de `data/mappings.json` em uma seção dedicada (ex.: `progression_gating`) ou arquivo próprio em `data/`

Recomendação:
- começar com gating simples por `building.type` e `building.level` para `class -> maxTier`
- quando não resolver building: fail closed (bloqueia tiers altos e mantém em retry com log)
- quando o item escolhido estiver acima do tier permitido: tentar outro item aceito de tier menor; se nenhum, `blocked_by_tier`

## Validation Architecture

Este projeto tem um harness próprio em `tests/run.lua`. Para esta fase, a estratégia de validação deve combinar:
- testes unitários (Lua puro) com periféricos mockados (`meBridge`, inventário, integrator)
- verificação manual in-world mínima (garantir que export/craft funcionam com o setup real)

Critérios mínimos de regressão automatizada:
- engine não dispara `craftItem` repetidamente em ticks consecutivos para o mesmo `item+qtd+destino`
- engine respeita gating e escolhe tier menor quando disponível
- quando `export` falha (sem espaço/erro), request vira `waiting_retry` e não entra em loop de spam

## Checklist de riscos

- export por nome vs direção: detectar e preferir `exportItemToPeripheral`
- divergência de nomes de método no ME Bridge: compat layer no wrapper
- concorrência no destino: validação pós-entrega deve tolerar “mudanças simultâneas” e ainda assim evitar falso sucesso

