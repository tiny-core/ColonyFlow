# Phase 19: Documentacao Didatica + Comentarios (PT) - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Facilitar aprendizado e manutencao do projeto com:
- um guia de estudo/leituras do codigo (startup -> bootstrap -> scheduler -> engine -> UI -> integracoes)
- documentacao em portugues (sem renomear APIs/identificadores)
- comentarios explicativos em portugues apenas onde existe decisao, invariante ou ponto de risco (sem comentar o obvio)

Regras globais a manter:
- nomes de funcoes/variaveis/APIs permanecem em ingles (nao renomear)
- mensagens exibidas na UI/logs do CC devem evitar acentos e caracteres especiais (ASCII)
</domain>

<decisions>
## Implementation Decisions

### Estrutura de docs
- **D-01:** Criar o guia didatico principal em `docs/LEIA-ME-DO-CODIGO.md`.
- **D-02:** Adicionar uma secao "Documentacao" no `README.md` apontando para o guia e docs de apoio.
- **D-03:** Formato "misto": 1 guia central + poucos docs de apoio, sem fragmentar em muitos capitulos.
- **D-04:** Expor no README (alem do guia) 3 docs de apoio: arquitetura/fluxo, pitfalls/operacao, e um resumo.
- **D-05:** Os 3 docs de apoio devem existir em `docs/` (copias/derivados de `.planning/research/`), para manter o README apontando para docs "publicas".

### Politica de comentarios (ja travado)
- **D-06:** Comentarios devem explicar "por que" e "invariantes", nao reescrever o codigo.

### Prioridade de leitura (ja travado)
- **D-07:** Priorizar modulos principais: startup/bootstrap/scheduler/engine/ui/me/minecolonies.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e ponto de edicao
- `.planning/ROADMAP.md` — definicao da Fase 19
- `README.md` — onde sera criada a secao "Documentacao"

### Fontes para derivar docs "publicas"
- `.planning/research/ARCHITECTURE.md` — baseline de arquitetura/fluxo para adaptar em `docs/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md` — pitfalls/operacao para adaptar em `docs/PITFALLS.md`
- `.planning/research/SUMMARY.md` — resumo para adaptar em `docs/SUMMARY.md`

### Codigo a referenciar no guia didatico
- `startup.lua`
- `lib/bootstrap.lua`
- `modules/scheduler.lua`
- `modules/engine.lua`
- `modules/snapshot.lua`
- `components/ui.lua`
- `modules/me.lua`
- `modules/minecolonies.lua`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/research/*` ja tem docs tecnicos (ARCHITECTURE/PITFALLS/SUMMARY) que podem ser adaptados para `docs/` e referenciados no README.

### Established Patterns
- Estrutura do projeto ja esta descrita no `README.md` (secao "Estrutura do Projeto"); o guia deve complementar isso com o "como ler" e "por que" das decisoes.

### Integration Points
- O guia deve orientar leitura pelos arquivos listados em "Codigo a referenciar", sem precisar mudar nomes/exports.
</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope
</deferred>

---

*Phase: 19-documentacao-didatica-comentarios-pt*
