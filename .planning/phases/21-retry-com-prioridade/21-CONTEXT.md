# Phase 21: Retry com Prioridade - Context

**Gathered:** 2026-04-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Adicionar prioridade de processamento para requests em `waiting_retry`: no início de cada tick, um
pre-pass coleta todos os requests elegíveis (next_retry <= nowEpoch), ordena por `started_at_ms`
(ASC — mais antigos primeiro) e os processa dentro do budget antes das requests normais via cursor
round-robin. Inclui contador de retries visível no monitor de requests.

</domain>

<decisions>
## Implementation Decisions

### Critério de prioridade
- **D-01:** Métrica de prioridade é `started_at_ms` — a request que está em `waiting_retry` há mais
  tempo (menor `started_at_ms`) é processada primeiro no pre-pass.
- **D-02:** Requests com `next_retry > nowEpoch` (janela ainda não expirou) são ignoradas no
  pre-pass, exatamente como no comportamento atual de `_processRequest`.

### Mecânica de reordenação
- **D-03:** Pre-pass no início do tick: coletar todos `work[id].status == "waiting_retry"` cujo
  `next_retry <= nowEpoch`, ordenar por `started_at_ms` ASC, processar em ordem dentro do budget.
  O cursor round-robin `_rq_cursor` continua para requests normais com o budget restante.
- **D-04:** O `_rq_cursor` é preservado entre ticks — o pre-pass não o altera. Requests normais
  continuam de onde o cursor parou no tick anterior.

### Interação com budget
- **D-05:** Pool compartilhado — retries e requests normais dividem o mesmo `requests_per_tick`.
  Sem nova config em `scheduler_budget`. Se o pre-pass esgotar o budget, nenhuma request nova é
  processada naquele tick.

### Exibição na UI
- **D-06:** Campo `retry_count` em `work[id]`, incrementado a cada vez que a request entra no
  processamento (pre-pass ou cursor). Exibido no monitor de requests ao lado do status,
  ex: `[R:3]` ou similar, quando `retry_count >= 1`.
- **D-07:** `retry_count` é somente em memória — não persiste em `data/work.json`. Zera ao
  reiniciar o sistema.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Lógica central do tick
- `modules/engine.lua` — `Engine:tick()` (loop principal, `_rq_cursor`, budget); `_markAllWaitingRetry`; `_handleNoCandidate`; `_handleMeOffline`
- `modules/engine.lua` — `work[id]` struct: campos `status`, `next_retry`, `started_at_ms`, `err`, `retry_count` (novo)

### UI de requests
- `components/ui.lua` — renderRequests / formatação de linha de request no monitor

### Persistência (para confirmar que retry_count NÃO deve ser incluído)
- `modules/persistence.lua` — schema do work.json; confirmar que retry_count fica fora

### Testes existentes relevantes
- `tests/run.lua` — `engine_request_na_janela_retry_e_ignorado` (linha ~2419): verifica skip correto; `engine_cursor_respects_requests_per_tick`: verifica budget — ambos devem continuar passando

### Roadmap
- `.planning/ROADMAP.md` — definição da Phase 21

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `work[id].started_at_ms` — já existe no estado, é a métrica de prioridade (D-01)
- `work[id].next_retry` — já existe, usado para filtrar elegíveis no pre-pass (D-02)
- `self._rq_cursor` — cursor round-robin preservado entre ticks; não deve ser alterado pelo pre-pass (D-04)

### Established Patterns
- `requests_per_tick` budget: contadores `scanned` e `processed` no loop do tick — o pre-pass usa o mesmo `processed` counter para consumir do budget compartilhado (D-05)
- `_processRequest(r, ctx)` retorna `true` quando processou, `nil, budgetErr` em budget exceeded — pre-pass respeita o mesmo protocolo

### Integration Points
- Pre-pass é inserido em `Engine:tick()` imediatamente antes do loop `while processed < rqLimit` atual
- Para construir o pre-pass, iterar `requests[]` (a lista do MineColonies) e cruzar com `self.work[r.id]` para ler `status`, `next_retry`, `started_at_ms`
- Incremento de `retry_count` deve acontecer em `_processRequest` ou no ponto de entrada do pre-pass (uma vez por tentativa real)

</code_context>

<specifics>
## Specific Ideas

- Formato sugerido para UI: `[R:3]` compacto ao lado do status no monitor de requests — cabe na
  largura existente sem quebrar layout.
- O pre-pass não precisa de nova config — é sempre ativo quando há requests elegíveis.

</specifics>

<deferred>
## Deferred Ideas

- Cap separado de budget para retries (ex: `retry_slots_per_tick`) — foi considerado mas descartado
  (D-05: pool compartilhado é suficiente e evita nova config).
- Persistir `retry_count` em work.json para diagnóstico pós-sessão — descartado (D-07: só memória).

</deferred>

---

*Phase: 21-retry-com-prioridade*
*Context gathered: 2026-04-27*
