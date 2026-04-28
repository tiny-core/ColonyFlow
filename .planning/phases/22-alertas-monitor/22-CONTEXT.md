# Phase 22: Alertas de Monitor - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Detectar requests presas há mais de N minutos (em qualquer status stuck: `blocked_by_tier`,
`nao_craftavel`, ou `waiting_retry` longa) e exibi-las em destaque colorido no monitor de
requests com sufixo de tempo. Adicionar uma linha de resumo na seção OPERAÇÃO do Monitor 2.
Nenhuma mudança no fluxo principal do engine — apenas renderização e um novo campo de
timestamp no estado.

</domain>

<decisions>
## Implementation Decisions

### Quais statuses disparam alerta
- **D-01:** Todo status stuck — `blocked_by_tier`, `nao_craftavel`, e `waiting_retry` —
  dispara o alerta se o tempo stuck ultrapassar `alert_stuck_minutes`. Não há distinção
  entre tipos de `waiting_retry` (qualquer que seja o `err`).
- **D-02:** `stuck_since_ms` é definido na PRIMEIRA vez que a request entra em qualquer
  status stuck e NUNCA é resetado durante retries. Ele só é removido (ou nil-ado) quando
  a request sai do estado stuck de vez (entra em `crafting`, `delivering`, `done`, ou é
  entregue com sucesso).
- **D-03:** Para `waiting_retry`: mesmo que uma tentativa seja feita e falhe novamente
  (voltando ao loop), o `stuck_since_ms` permanece o mesmo — o timer cresce continuamente
  mostrando o tempo TOTAL que a request está presa.

### Esquema de cores
- **D-04:** `blocked_by_tier` → `colors.red` (ação humana necessária — config de tier).
- **D-05:** `nao_craftavel` e `waiting_retry` longa → `colors.yellow`.
- **D-06:** Sufixo de tempo: `"Xm"` (só minutos, arredondado para baixo).
  Ex: `"12m"` para 12 minutos e meio. Sem segundos.
- **D-07:** O sufixo é concatenado ao `etapaStr` existente na coluna ETAPA do monitor de
  requests. Ex.: `"⚙[R:2]12m"`. O measurement loop de `renderRequests` também deve
  contabilizar o sufixo para calcular corretamente a largura da coluna `jobMax`.

### Resumo no Monitor 2
- **D-08:** Uma linha `"Presas: N >Xm"` é adicionada na seção OPERAÇÃO da view main do
  Monitor 2, junto com os contadores existentes (Processado/Craftado/Entregue/Erros).
- **D-09:** A linha só aparece quando N > 0 (omitida quando não há requests presas).
- **D-10:** Aparece apenas na view `"main"` do Monitor 2 — não é exibida nas outras views
  rotativas (nocraftview, update details, etc.).

### Claude's Discretion
- Exato posicionamento da linha de Presas dentro da seção OPERAÇÃO (antes ou após
  contadores existentes): deixar para o planner decidir com base no espaço disponível.
- Cor da linha de resumo no Monitor 2: amarelo (`colors.yellow`) quando há presas, pois
  mistura tipos diferentes de stuck. Usar branco quando não há (mas nesse caso é omitida).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### UI e renderização
- `components/ui.lua` — `renderRequests` (dois loops: measurement ~l.449–465, render ~l.493–555);
  `renderStatus` (view main com seção OPERAÇÃO); `drawText` com parâmetros fg/bg para cores
- `components/ui.lua` — padrão `jobSymbol` + `etapaStr` + badge `[R:N]` (Phase 21, l.540–545)
  — o novo sufixo `"Xm"` segue o mesmo padrão e deve ser contabilizado no measurement loop

### Engine (estado de trabalho)
- `modules/engine.lua` — `work[id]` struct: campos `status`, `next_retry`, `started_at_ms`,
  `err`, `retry_count`; pontos onde status muda para stuck (buscar `work.status =`)
- `modules/engine.lua` — pontos de transição de status para não-stuck onde `stuck_since_ms`
  deve ser removido: `done`, `delivering`, `done` pós-entrega

### Snapshot (contrato UI/Engine)
- `modules/snapshot.lua` — `copyWorkJob` (l.63–82): adicionar `stuck_since_ms` aqui para
  que a UI leia do snapshot corretamente; `Snapshot.build` usa `Util.nowUtcMs()` disponível
  como `at_ms` no snapshot para calcular elapsed sem acesso a relógio na UI

### Configuração
- `lib/config.lua` — seção `[observability]` (l.62–65): nova chave `alert_stuck_minutes = 5`
  a ser adicionada como default

### Testes
- `tests/run.lua` — testes existentes de engine para não causar regressão; adicionar casos
  de teste para `stuck_since_ms` (set na 1ª entrada, preservado em retry, removido ao resolver)

### Roadmap
- `.planning/ROADMAP.md` — definição da Phase 22

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `colors.red`, `colors.yellow`, `colors.white` — já usados em `renderRequests` para fg;
  a lógica de cor por stuck sobrescreve o fg atual da linha
- `Util.nowUtcMs()` — disponível em `modules/snapshot.lua` (já importado) para calcular
  `elapsed = at_ms - stuck_since_ms` na UI sem acessar relógio diretamente
- `job.retry_count` — padrão de campo in-memory sem persistência; `stuck_since_ms` segue
  o mesmo contrato (in-memory, não persiste em `data/work.json`)

### Established Patterns
- Snapshot pattern (Phase 18): engine escreve `work[id].stuck_since_ms`; `copyWorkJob` em
  `snapshot.lua` copia o campo; UI lê de `state.snapshot.work[id].stuck_since_ms`
- Measurement + render loop (Phase 21 bug conhecida): o measurement loop deve incluir o
  sufixo `"Xm"` no cálculo de `jobMax`, do contrário a coluna será subdimensionada.
  Ver `.planning/phases/21-retry-com-prioridade/21-REVIEW.md` para contexto do bug similar
  com `[R:N]`.
- Views rotativas no Monitor 2: `self.statusView` controla a view atual; a linha de resumo
  deve ser guarded por `if self.statusView == "main" then`

### Integration Points
- `engine.lua`: detectar transições de status e setar/limpar `stuck_since_ms`; não precisa
  de novo campo em `config.ini` além de `alert_stuck_minutes`
- `renderRequests`: após calcular `etapaStr`, verificar se `job.stuck_since_ms` existe e
  elapsed > threshold; se sim, concatenar `"Xm"` e sobrescrever `fg`
- `renderStatus` (view main): varrer `state.work` para contar requests presas e calcular
  `Xm` do mais antigo (ou threshold), então adicionar linha condicional na seção OPERAÇÃO

</code_context>

<specifics>
## Specific Ideas

- Formato do preview mockup aprovado pelo usuário para o Monitor 2:
  ```
  === OPERACAO ===
  Processado: 42  Craftado: 38
  Entregue: 35    Erros: 2
  Presas: 3 >5m              ← nova linha (omitida quando 0)
  ```
- Sufixo na coluna ETAPA do Monitor 1 (requests): ex. `"⚙[R:2]12m"` — concatenar `"Xm"`
  ao final de `etapaStr` quando presa (não como campo separado).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 22-alertas-monitor*
*Context gathered: 2026-04-28*
