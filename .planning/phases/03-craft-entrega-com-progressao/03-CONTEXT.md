# Phase 03: Craft + Entrega com Progressão - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Fechar o ciclo operacional com AE2 (ME Bridge) para:
- entregar itens ao destino padrão configurado
- iniciar autocrafting apenas do faltante real quando necessário
- evitar duplicidade de jobs entre ciclos
- aplicar tier gating por building/worker usando dados de buildings do MineColonies

</domain>

<decisions>
## Implementation Decisions

### Craft do faltante
- **D-01:** Se houver quantidade parcial disponível no ME, entregar parcial e abrir craft apenas do restante.
- **D-02:** Se o item não for craftável no ME, colocar a request em fila com retry (backoff) e logar motivo (não “falha permanente”).
- **D-03:** Com múltiplos itens aceitos, escolher primeiro o que já tiver estoque no ME; se nenhum, escolher o mais viável respeitando gating.
- **D-04:** Ordem padrão: abrir craft do faltante primeiro; depois exportar o que estiver disponível para entrega.
- **D-05:** Progresso: armazenar retorno do `craftItem` quando existir; fallback para `isCrafting` usando chave por `item+qtd`.

### Anti-duplicidade de jobs
- **D-06:** Regra principal: `isCrafting` + lock local TTL (fallback quando API variar/retornar nil).
- **D-07:** TTL padrão do lock local: 15s.
- **D-08:** Chave do lock local: `item+qtd+destino`.

### Entrega ao destino
- **D-09:** Entrega usa o destino padrão configurado em `delivery.default_target_container`.
- **D-10:** Após exportar, validar pós-entrega por snapshot do inventário (com tolerância a concorrência).
- **D-11:** Se destino estiver cheio/sem espaço suficiente, colocar em fila com retry (backoff), sem “forçar” entrega parcial.

### Tier gating por building
- **D-12:** Se não der para resolver tipo/nível do building, operar em fail closed (não entrega acima do tier permitido; mantém em retry com log).
- **D-13:** Se o item escolhido estiver acima do tier permitido, tentar buscar um item (aceito) de tier menor; se não existir, bloquear por tier e manter em retry.
- **D-14:** Tabela de gating: híbrida (defaults embutidos + overrides em JSON; config.ini controla/ativa e aponta arquivo quando necessário).

### Claude's Discretion
Nenhuma — decisões acima travadas.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e requisitos
- `.planning/ROADMAP.md` — definição da Fase 3 (goal, inclui e success criteria)
- `.planning/REQUIREMENTS.md` — requisitos ME-02/03/04, DEL-03, EQ-03, TIER-03, MC-03
- `.planning/PROJECT.md` — constraints (operação autônoma, logs PT, cache TTL, estrutura)
- `.planning/phases/01-fundacao-operacional/01-CONTEXT.md` — decisões globais da base (logs, cache, estrutura)
- `.planning/phases/02-nucleo-de-requisicoes-filtros/02-CONTEXT.md` — decisões sobre escolha de candidato, faltante real e destino padrão

### Configuração e dados
- `config.ini` — defaults operacionais (inclui estados e destino padrão)
- `data/mappings.json` — classes/tiers/equivalências/allowlist e possíveis overrides

### Código que será impactado
- `modules/me.lua` — wrapper ME Bridge (isOnline/getItem/listItems/isCrafting/isCraftable/craftItem/exportItem)
- `modules/engine.lua` — orquestração do ciclo (work state, escolha, faltante) e ponto de integração para craft+entrega+gating
- `modules/minecolonies.lua` — requests + `getBuildings()` para MC-03 (níveis/tipos)
- `modules/inventory.lua` — snapshot/contagem no destino e validação pós-entrega
- `modules/tier.lua` — inferência + `isTierAllowed` (base para gating)
- `modules/equivalence.lua` — meta/allowlist/equivalências usadas na seleção

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/me.lua` já expõe as chamadas necessárias para Phase 3 (craft/export/isCrafting/isCraftable).
- `modules/engine.lua` já mantém estado por request em `self.work` e já calcula faltante por snapshot do destino.
- `lib/cache.lua` pode servir para TTL do lock local e para reduzir consultas repetidas ao ME.
- `modules/minecolonies.lua:listBuildings()` já retorna `type` e `level` para aplicar gating.

### Established Patterns
- `Util.safeCall(...)` para isolamento de falhas de periféricos com logs estruturados em português.
- Cache por namespace em `state.cache` para evitar rescans/consultas repetidas.

### Integration Points
- Expandir o fluxo do `Engine:tick()` para: avaliar ME (online/estoque/craftável/isCrafting), abrir craft do faltante e exportar para destino padrão, atualizando `work.status` para uso na UI da Phase 4.

</code_context>

<specifics>
## Specific Ideas

- Progresso deve ser rastreável para UI: estados como `crafting`/`delivering`/`waiting_retry`, com chave por `item+qtd` quando não houver handle do ME.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-craft-entrega-com-progressao*
*Context gathered: 2026-04-05*
