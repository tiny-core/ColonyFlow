# Phase 08: Mapping v2 (Simplificação + Preferências) - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Evoluir o sistema de mapeamentos para um formato v2 mais simples de operar via editor, focado em:
- classificar itens/tags em classes (armaduras e ferramentas por subtipo)
- definir preferências explícitas de escolha (vanilla-first vs preferir equivalente)
- manter compatibilidade de leitura com o formato v1 (migração em memória)

</domain>

<decisions>
## Implementation Decisions

### Fonte de dados e formato v2
- **D-01:** Continuar com `data/mappings.json` como fonte de verdade (não migrar o banco para INI).
- **D-02:** O JSON v2 terá `version = 2` e um bloco de regras explícitas por seletor (item ou tag), além de manter `tier_overrides` (e demais estruturas existentes quando aplicável).
- **D-03:** O editor aceitará `ID` (`mod:item`) e `tag` com prefixo `#` (ex.: `#forge:tools/pickaxes`) como entrada do “item”.

### Modelo de regra (classificação)
- **D-04:** O mapping v2 será por **classificação por tipo** (classe/subtipo), não por links explícitos item↔item como fluxo principal.
- **D-05:** Classes suportadas (mínimo) para o editor:
  - Armaduras: `ARMOR_HELM`, `ARMOR_CHEST`, `ARMOR_LEGS`, `ARMOR_BOOTS`
  - Ferramentas: `TOOL_PICK`, `TOOL_SHOVEL`, `TOOL_AXE`, `TOOL_HOE`, `TOOL_SWORD`, `TOOL_BOW`, `TOOL_SHIELD`
- **D-06:** Representação recomendada (contrato) para regras no JSON:
  - `selector`: string (`minecraft:iron_chestplate` ou `#forge:...`)
  - `kind`: `"item"` ou `"tag"` (pode ser inferido pelo `#`, mas será persistido para validação)
  - `class`: uma das classes acima
  - `prefer_equivalent`: boolean (opcional; ver semântica abaixo)

### Preferência (prioridade) vanilla vs equivalente
- **D-07:** `prefer_equivalent` decide **somente vanilla vs equivalente** dentro da mesma classe: quando existir um item vanilla e um item equivalente (mesma classe) e ambos forem aceitos e disponíveis/craftáveis, `true` dá preferência ao equivalente; `false` mantém vanilla-first.
- **D-08:** Default quando ausente: `prefer_equivalent = false` (vanilla-first).

### Tier override
- **D-09:** O editor também permite definir `tier_overrides` (override explícito de tier).
- **D-10:** Tier override é aplicado a seletores do tipo `item` (IDs). Tags não recebem tier override no v2 inicial.

### Editor (startup map) e navegação
- **D-11:** Operações obrigatórias no editor: adicionar, editar e remover regras (CRUD completo) com listagem e busca.
- **D-12:** Controles do editor serão por teclado:
  - setas ↑/↓ para navegar listas
  - Enter para confirmar seleção
  - seta ← para voltar/cancelar
  - seta → para avançar/confirmar (atalho equivalente ao Enter quando fizer sentido)

### Migração v1 → v2
- **D-13:** Ao encontrar `data/mappings.json` v1, o sistema migra **em memória** para a estrutura interna v2 (sem reescrever o arquivo automaticamente).

### Claude's Discretion
- Detalhes de layout das telas do editor (mantendo consistência com a UI atual).
- Mensagens de validação e erros (mantendo logs em português e “salvamento seguro”).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e requisitos
- `.planning/ROADMAP.md` — definição da Fase 08 (goal, inclui e success criteria)
- `.planning/REQUIREMENTS.md` — requisitos CFG-03, EQ-01/02/03, TIER-01/02/03
- `.planning/PROJECT.md` — constraints (logs PT, operação autônoma, estrutura de arquivos)
- `.planning/phases/02-nucleo-de-requisicoes-filtros/02-CONTEXT.md` — vanilla-first/mod-first e política de equivalências
- `.planning/phases/04-ui-configuracao-operacional/04-CONTEXT.md` — decisões do editor TUI e salvamento seguro

### Especificação do editor (visão do usuário)
- `.planning/temp/mapping.md` — requisitos do fluxo simplificado (ID/tag → classe + prioridade + setas/Enter)

### Código impactado
- `data/mappings.json` — banco atual a evoluir para v2 (versionamento)
- `modules/equivalence.lua` — loader/hot-reload e API de leitura de mapeamentos
- `modules/mapping_cli.lua` — editor atual (baseline) que será evoluído/substituído
- `modules/tier.lua` — uso de `tier_overrides` e pipeline de inferência de tier

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/equivalence.lua` já cria o arquivo base e faz hot-reload por `fs.attributes(...).modified`.
- `modules/mapping_cli.lua` já tem estrutura de “menu” simples no terminal e leitura/gravação de JSON.
- `data/mappings.json` já suporta `tier_overrides` e uma estrutura mínima para `gating`.

### Established Patterns
- Persistência em JSON via `Util.jsonDecode/Encode` e leitura/gravação via `Util.readFile/writeFile`.
- Operação “hot reload” do banco sem reiniciar o sistema.

### Integration Points
- A resolução de candidatos depende do que `Equivalence` expõe (classe, allow/deny, equivalentes).
- Tier override precisa continuar influenciando a inferência e o gating já existentes.

</code_context>

<specifics>
## Specific Ideas

- O fluxo do editor começa com: digitar `ID` ou `#tag` → escolher classe/subtipo → definir prioridade (`prefer_equivalent`) → (opcional) definir tier override → salvar.
- Navegação orientada por setas, com confirmação por Enter e retorno por seta esquerda.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-mapping-v2*
*Context gathered: 2026-04-12*
