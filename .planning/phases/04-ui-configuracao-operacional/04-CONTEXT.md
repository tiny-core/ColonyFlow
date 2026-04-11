# Phase 04: UI + Configuração Operacional - Context

**Gathered:** 2026-04-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Tornar o sistema operável em produção com:
- UI em 2 monitores (fila de requisições + painel de status misto) com paginação eficiente e atualização sem flicker excessivo
- Interface no terminal para editar mapeamentos (equivalências, classes/tiers, overrides e allowlist) persistindo em JSON e aplicando no próximo ciclo sem reiniciar
- Observabilidade: UI e logs deixando claro “pedido vs escolhido”, e quando houve substituição vs sugestão e por quê

</domain>

<decisions>
## Implementation Decisions

### Paginação e Controles
- **D-01:** Navegação no Monitor 1 por toque (←/→) com fallback de rotação automática quando não houver interação.
- **D-02:** Tamanho da página calculado automaticamente pela altura útil do monitor (responsivo).
- **D-03:** Refresh baseado em snapshot + diff (renderizar só quando mudar) com limites mínimo/máximo para evitar flicker e custo excessivo.
- **D-04:** Controles adicionais no terminal (atalhos) para navegar páginas, aplicar filtros e pausar rotação automática.

### Monitor 1 — Fila de Requisições
- **D-05:** Ordenação padrão: por prioridade de status, depois por faltante (descendente).
- **D-06:** Densidade “padrão”: uma linha por request com colunas essenciais (ex.: STATUS, ID, TARGET, REQ→ESC, FALT, AÇÃO/JOB).
- **D-07:** Substituição/sugestão representada com marcador + cor na própria linha (REQ→ESC), deixando visível quando mudou e se é substituição (aceito) ou sugestão (não aceito).
- **D-08:** Filtros rápidos por status (toggle via toque/atalho), para operação e debug.

### Monitor 2 — Status Misto
- **D-09:** Layout em 3 blocos compactos: Colônia | Operação | Estoque crítico.
- **D-10:** Bloco de colônia mantém o conjunto atual de métricas (nome, cidadãos, felicidade, underAttack, obras).
- **D-11:** Estoque crítico definido automaticamente por heurística (a implementação decide os critérios).
- **D-12:** Alertas (ME offline, destino indisponível, blocked_by_tier, etc.) aparecem como banner com cor + contadores.

### Editor de Mapeamentos (Terminal)
- **D-13:** Estilo do editor: menu (TUI) com busca e operações guiadas.
- **D-14:** Operações obrigatórias: equivalências (link/unlink), classe/tier por item, tier overrides e allowlist.
- **D-15:** Salvamento seguro: validar JSON, criar backup e permitir preview do diff quando fizer sentido.
- **D-16:** Mudanças aplicam no próximo ciclo automaticamente (hot reload sem reiniciar).

### Claude's Discretion
- Mapeamento exato dos atalhos de teclado e a prioridade detalhada de status (mantendo consistência com os estados do `Engine`).
- Critérios da heurística de “estoque crítico”, desde que seja explicável via UI/log e configurável quando necessário.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Escopo e requisitos
- `.planning/ROADMAP.md` — definição da Fase 4 (goal, inclui e success criteria)
- `.planning/REQUIREMENTS.md` — requisitos UI-01/02/03, CFG-04, EQ-04
- `.planning/PROJECT.md` — constraints (logs PT, operação autônoma, dual-monitor)
- `.planning/phases/01-fundacao-operacional/01-CONTEXT.md` — decisões globais (logs/cache/estrutura)
- `.planning/phases/02-nucleo-de-requisicoes-filtros/02-CONTEXT.md` — pedido vs escolhido, equivalências auditáveis
- `.planning/phases/03-craft-entrega-com-progressao/03-CONTEXT.md` — estados operacionais e progressão (gating/retry)

### UI (monitor/terminal)
- `components/ui.lua` — baseline atual de dual-monitor + paginação automática (ponto de evolução da Fase 4)
- `modules/engine.lua` — origem dos estados e dados (`state.requests`, `self.work[...]`) consumidos pela UI

### Mapeamentos e persistência
- `data/mappings.json` — banco editável (classes/tiers/equivalências/allowlist)
- `modules/mapping_cli.lua` — editor atual (baseline) a ser substituído/evoluído
- `modules/equivalence.lua` — leitura/uso de equivalências e allowlist
- `modules/tier.lua` — inferência e overrides de tier (e gating na Fase 3)

### Logs
- `lib/logger.lua` — formato e níveis dos logs (auditoria de substituições/sugestões)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `components/ui.lua` já renderiza em dois monitores e tem estrutura de tabela + paginação (hoje: rotação automática por tempo).
- `modules/engine.lua` já preenche `state.requests` e mantém `self.work[requestId]` com `status`, `chosen`, `missing`, `target` e detalhes de escolha.
- `data/mappings.json` + `modules/mapping_cli.lua` já estabelecem o formato do banco e uma forma mínima de edição via terminal.

### Established Patterns
- Renderização via `term.redirect()` com clear completo; precisa evoluir para “diff/snapshot” para reduzir flicker.
- Erros e interações com periféricos isolados via `Util.safeCall(...)` e logs estruturados.

### Integration Points
- UI deve ler e exibir de forma consistente os estados do `Engine` (ex.: `pending`, `crafting`, `waiting_retry`, `blocked_by_tier`, `unsupported`, `error`, `done`).
- Editor deve salvar em `data/mappings.json` e forçar reload dos dados na próxima iteração (sem reinício).

</code_context>

<specifics>
## Specific Ideas

- A fila no Monitor 1 sempre mostra “pedido → escolhido” com marcador/cores, e deixa claro quando é sugestão vs substituição.
- Painel de status mostra alertas como banner em cor (sem alternar telas), para não “sumir” informações durante operação.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-ui-configuracao-operacional*
*Context gathered: 2026-04-09*
