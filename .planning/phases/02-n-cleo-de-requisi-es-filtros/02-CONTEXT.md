# Phase 02: Núcleo de Requisições + Filtros - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementar o núcleo que:
- lê e normaliza requisições do MineColonies em um formato interno estável
- calcula o faltante real por destino (sem craft cego quando o destino falha)
- aplica regras de tiers + equivalências para ordenar/explicar candidatos

Nesta fase, o foco é “entender o pedido e decidir o que falta / o que é equivalente”, preparando dados e regras. (Integração completa de craft/entrega fica na fase seguinte.)

</domain>

<decisions>
## Implementation Decisions

### Normalização de Requests
- **D-01:** Estados “pendentes” serão controlados por tabela configurável (allow/deny list) com default permissivo.
- **D-02:** `request.items` é tratado como lista de itens aceitos (conjunto de opções válidas), sem “item primário” por padrão.
- **D-03:** O modelo normalizado fica no mínimo necessário para a Fase 2: `accepted[]` (name/count/tags/nbt quando existir), `requiredCount` e `target` (demais campos são opcionais).
- **D-04:** A identidade do trabalho usa `r.id` quando existir; se faltar/colidir, gerar uma chave estável (hash) a partir de dados como target + itens.

### Destino + Faltante Real
- **D-05:** O destino é resolvido somente por destino padrão; `delivery.default_target_container` deve aceitar lista e o sistema usa o primeiro periférico disponível.
- **D-06:** Se o destino não puder ser validado (ausente/erro), a request entra em `waiting_retry` com backoff simples; não crafta nem entrega “no escuro” (DEL-04).
- **D-07:** Com múltiplos itens aceitos, primeiro escolhe um candidato e então calcula `faltante = max(0, requerido - presente_no_destino)` apenas para o item escolhido.
- **D-08:** Varredura do inventário de destino usa cache por destino com TTL curto e refresh sob demanda (CACHE-02).

### Equivalências e Substituição
- **D-09:** O item escolhido para atender deve ser sempre um dos itens aceitos pela request; equivalências servem para sugestão/explicação e para construir a base.
- **D-10:** A resolução entre múltiplos itens aceitos deve ser feita por política local baseada em tier/categoria (sem depender de ME nesta fase), produzindo lista ordenada com justificativa.
- **D-11:** Itens de mod são atendidos apenas quando estiverem allowlisted no banco (mappings.json). Se não estiverem:
  - procurar equivalente vanilla que esteja aceito pela request
  - se não houver equivalente vanilla aceito, marcar “não suportado” e manter em retry
  A UI/monitor deve refletir pedido vs escolhido e quando houve fallback.
- **D-12:** Sempre registrar (log/UI) quando houver equivalência/sugestão/substituição relevante para a escolha.
- **D-13:** A prioridade vanilla-first vs mod-first quando ambos forem aceitos deve ser configurável.

### Tiers e Classes
- **D-14:** Tiers suportados na v1:
  - Ferramentas: `wood/stone/iron/diamond/netherite`
  - Armaduras: `leather/iron/diamond/netherite`
- **D-15:** Classificação começa com categorias genéricas `TOOL` e `ARMOR`.
- **D-16:** Ordem de inferência de tier: `override > db > tags > name`.
- **D-17:** Categoria (TOOL vs ARMOR) usa preferencialmente o banco (mappings.json); se faltar, usa heurística por nome/tags.
- **D-18:** Nesta fase não aplicamos “gating” por nível de building/worker; apenas inferimos e organizamos. (Gating efetivo fica na Phase 3.)
- **D-19:** A preferência de escolha por tier (lowest-first vs highest-first) será configurável globalmente.

### Claude's Discretion
Nenhuma — decisões acima travadas.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e requisitos
- `.planning/ROADMAP.md` — definição da Fase 2 (goal, inclui e success criteria)
- `.planning/REQUIREMENTS.md` — requisitos MC-01/02, DEL-01/02/04, EQ-01/02, TIER-01/02, CACHE-02, CFG-03
- `.planning/PROJECT.md` — visão, constraints e decisões globais (logs PT, cache TTL, operação autônoma)
- `.planning/phases/01-funda-o-operacional/01-CONTEXT.md` — decisões travadas da base (logs, cache, estrutura)

### Banco de mapeamentos (tiers/equivalências/allowlist)
- `data/mappings.json` — fonte de classes, tiers, equivalents e allowlist/editável via CLI
- `modules/mapping_cli.lua` — editor atual do banco (CLI)

### Código que será impactado
- `modules/minecolonies.lua` — leitura/normalização de requests e buildings
- `modules/inventory.lua` — contagem/varredura de itens no destino
- `modules/equivalence.lua` — carregamento do banco e resolução de equivalentes
- `modules/tier.lua` — inferência de tier e regras base
- `modules/engine.lua` — onde a escolha/cálculo hoje está acoplada e deve ser refatorada/alinhada à Fase 2

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/config.lua` + `config.ini` — base para tabelas configuráveis (states pendentes, prioridade tier, vanilla/mod)
- `lib/cache.lua` — cache TTL já existente, útil para CACHE-02 (destinos/varreduras)
- `modules/minecolonies.lua` — normalizeRequest já estrutura items (name/displayName/count/tags/nbt)
- `modules/inventory.lua` — `countItem` e `countAny` para faltante por item/candidato
- `modules/equivalence.lua` + `data/mappings.json` — base do banco editável e reload
- `modules/tier.lua` — pipeline de inferência já está próximo do desejado (com ordem a ajustar)

### Established Patterns
- `Util.safeCall(...)` para isolamento de falhas de periféricos com logs em português
- Cache por namespace (`state.cache:get("mc", ...)`, `state.cache:get("me", ...)`)
- Estrutura modular: `modules/*` com injeção de `state`

### Integration Points
- `modules/engine.lua` concentra “escolha de candidato + contagem no destino + estados de work”; Fase 2 deve separar:
  - normalização de requests
  - resolução de candidato (tier/equivalência)
  - reconciliação de destino (cache/TTL) e cálculo de faltante

</code_context>

<specifics>
## Specific Ideas

- “Lista de itens de mod aceitos” (allowlist) deve governar quando um item de mod pode ser atendido.
- Quando houver fallback para vanilla (ou item de mod allowlisted), a exibição no monitor deve mostrar claramente: item pedido → item escolhido + motivo.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-n-cleo-de-requisi-es-filtros*
*Context gathered: 2026-04-05*
