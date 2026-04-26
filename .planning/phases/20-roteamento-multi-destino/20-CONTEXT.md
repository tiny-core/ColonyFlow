# Phase 20: Roteamento Multi-Destino - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Adicionar roteamento de destino por classe de item: cada classe (armor_helmet, tool_pickaxe, etc.)
pode ter um inventario de destino dedicado configurado em `[delivery_routing]` no config.ini.
Fallback automatico para `default_target_container` quando a classe nao estiver mapeada ou o
inventario configurado estiver offline. Inclui exposicao no config_cli e resumo de saude no
doctor/healthcheck.

</domain>

<decisions>
## Implementation Decisions

### Logica de fallback
- **D-01:** Um unico periferico por classe (sem lista). Se o periferico configurado estiver offline,
  cai diretamente no `default_target_container` (sem lista de fallback por classe).
- **D-02:** Se a classe do item nao tiver mapeamento em `delivery_routing`, usa `default_target_container`.
- **D-03:** Se `default_target_container` tambem estiver offline, comportamento atual (waiting_retry).

### Cache e snapshot de destino
- **D-04:** Reutilizar o cache existente parameterizado por nome (`state.cache:get("dest", targetName)`).
  Cada destino roteado tem seu proprio TTL independente via mesma estrutura de cache. Zero mudanca
  de API no sistema de cache.
- **D-05:** A snapshot do destino roteado e tirada on-demand por requisicao (igual ao default),
  aproveitando o cache por nome para evitar IO redundante no mesmo tick.

### Config CLI
- **D-06:** Menu estatico com as 11 classes fixas listadas:
  `armor_helmet`, `armor_chestplate`, `armor_leggings`, `armor_boots`,
  `tool_pickaxe`, `tool_shovel`, `tool_axe`, `tool_hoe`, `tool_sword`, `tool_bow`, `tool_shield`.
  Exibe valor atual de cada classe ao lado. Usuario escolhe a classe para editar e digita o
  nome do periferico (ou deixa vazio para limpar o mapeamento).

### Health display
- **D-07:** Exibir `Targets: X/Y online` no doctor/healthcheck — conta o `default_target_container`
  mais todos os destinos roteados configurados (nao-vazios). Substitui o atual `Target: Online/Offline`.

### Testes
- **D-08:** Testes cobrem: classe mapeada e online, classe mapeada e offline (fallback para default),
  classe nao mapeada (fallback para default), item sem classe/guessClass retorna nil (fallback para default).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e definicao da fase
- `.planning/phases/20-roteamento-multi-destino/GOAL.md` — definicao completa, comportamentos esperados e arquivos afetados

### Codigo central (ler antes de planejar)
- `modules/engine.lua` — `guessClass()` (linha 116), `resolveTarget()` (linha 167), logica de tick principal (linha 1158)
- `lib/config.lua` — defaults da secao `[delivery]` (linha 27); adicionar `[delivery_routing]` aqui
- `modules/config_cli.lua` — secao `delivery` existente (linha 37, 359); expandir para `delivery_routing`
- `tests/run.lua` — estrutura de testes existentes

### Referencia de configuracao
- `.planning/ROADMAP.md` — definicao da Phase 20

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `guessClass(name)` em `engine.lua:116` — ja classifica itens em 11 classes. Usar diretamente
  para resolver qual chave de `delivery_routing` consultar.
- `resolveTarget(cfg)` em `engine.lua:167` — logica de fallback por lista existe aqui; a nova logica
  de roteamento por classe deve chamar essa funcao como fallback final.
- `state.cache:get("dest", targetName)` / `:set(...)` — cache parametrizado por nome ja existe.
  Reutilizar sem modificacao para snapshots de destinos roteados.

### Established Patterns
- `cfg:getList("delivery", "default_target_container", {})` — padrao de leitura de config;
  `delivery_routing` usa `cfg:get(...)` simples (valor unico, nao lista).
- A secao `delivery` no config_cli usa campos estaticos nomeados — o mesmo padrao para `delivery_routing`
  com as 11 classes fixas.

### Integration Points
- A logica de resolucao de destino por classe entra em `engine.lua` antes de construir o `ctx`
  (linha ~1158). Cada requisicao no loop do tick resolve seu proprio target usando `guessClass` +
  lookup em `delivery_routing`.
- `getDestinationSnapshot(state, targetName, targetInv, ...)` ja aceita `targetName` dinamico —
  chamadas com nomes diferentes naturalmente usam entradas de cache separadas.

</code_context>

<specifics>
## Specific Ideas

- No config_cli, ao exibir o menu de delivery_routing, mostrar o nome da classe e o periferico atual
  lado a lado (ex: `armor_helmet   [rack_tools_0]`). Valor vazio indica "usa default".
- A linha de health `Targets: X/Y online` deve aparecer no mesmo lugar que o atual `Target:` na UI
  de status do monitor.

</specifics>

<deferred>
## Deferred Ideas

- **UI de update disponivel mais discreta:** Exibir versao como `v1.5.0 -> v1.6.0` com cores
  diferentes para cada versao, posicionado no header do monitor de status (substitui a linha
  gigante atual). Pertence a uma fase de UI/polish (Phase 25 ou nova fase).

</deferred>

---

*Phase: 20-roteamento-multi-destino*
*Context gathered: 2026-04-26*
