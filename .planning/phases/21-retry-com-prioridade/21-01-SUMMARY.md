---
phase: 21-retry-com-prioridade
plan: "01"
subsystem: engine,ui
tags: [retry, priority, pre-pass, badge, scheduler]
dependency_graph:
  requires: [engine.lua Engine:tick, engine.lua Engine:_processRequest, components/ui.lua renderRequests]
  provides: [pre-pass retry priority in Engine:tick, retry_count field in work, badge [R:N] in ETAPA column]
  affects: [modules/engine.lua, components/ui.lua, tests/run.lua]
tech_stack:
  added: []
  patterns: [pre-pass before round-robin, shared budget counter, in-memory only field]
key_files:
  created: []
  modified:
    - modules/engine.lua
    - components/ui.lua
    - tests/run.lua
decisions:
  - Pre-pass inserido antes do loop round-robin consumindo budget compartilhado (D-05)
  - retry_count somente em memória — não persiste em work.json (D-07)
  - Badge [R:N] concatenado ao resultado de jobSymbol, não dentro da função (preserva jobSymbol imutável)
metrics:
  duration: "~25 min"
  completed_date: "2026-04-28T16:45:00Z"
  tasks_completed: 2
  files_modified: 3
---

# Phase 21 Plan 01: Retry com Prioridade — Summary

**One-liner:** Pre-pass em Engine:tick() processa requests em waiting_retry elegíveis por ordem de started_at ASC com budget compartilhado; badge [R:N] na coluna ETAPA do monitor.

## What Was Built

### Task 1 (TDD — RED+GREEN): Pre-pass de retry em Engine:tick() + campo retry_count

**Implementação em `modules/engine.lua`:**

- Pre-pass inserido após cálculo de `rqLimit` e antes do loop round-robin normal
- Coleta requests com `work[id].status == "waiting_retry"` e `next_retry <= nowEpoch`
- Ordena por `work.craft.started_at` ASC — fallback `math.huge` para requests sem craft
- `local processed = 0` declarado antes do pre-pass; compartilhado com o loop normal
- Budget-exceeded no pre-pass: preserva `_rq_cursor` com valor atual, retorna sem modificar cursor
- Loop normal usa `local scanned = 0` (sem redeclarar `processed`)
- `retry_count` incrementado em `_processRequest` após guarda `next_retry` (linha ~976)
- `retry_count` ausente em `_persistWorkMaybe` e `_restorePersistedWork` (D-07)

**Testes adicionados em `tests/run.lua` (7 novos):**
- `engine_prepass_processa_waiting_retry_elegivel`
- `engine_prepass_ignora_waiting_retry_na_janela`
- `engine_prepass_ordena_por_started_at_asc`
- `engine_prepass_nao_altera_cursor`
- `engine_prepass_budget_compartilhado_com_loop_normal`
- `engine_retry_count_incrementado_em_processRequest`
- `engine_retry_count_nao_persiste`

### Task 2: Badge [R:N] na coluna ETAPA

**Implementação em `components/ui.lua`:**

- No loop `renderRequests`, substitui uso direto de `jobSymbol(jobState)` por variável `etapaStr`
- `retryCount = job and tonumber(job.retry_count or 0) or 0`
- Se `retryCount >= 1`: `etapaStr = etapaStr .. "[R:" .. tostring(retryCount) .. "]"`
- `string.format` usa `shorten(etapaStr, jobMax)` no 4º campo
- `jobSymbol` permanece inalterada

## Commits

| Hash | Type | Descrição |
|------|------|-----------|
| `04aab05` | test | RED: 7 novos testes para pre-pass e retry_count |
| `632ddf7` | feat | GREEN: pre-pass em Engine:tick() + retry_count em _processRequest |
| `8d2264a` | feat | Badge [R:N] na coluna ETAPA do monitor de requests |

## Deviations from Plan

None — plano executado exatamente conforme especificado.

## TDD Gate Compliance

- RED gate: commit `04aab05` — `test(21-01): add failing tests...`
- GREEN gate: commit `632ddf7` — `feat(21-01): add retry pre-pass...`
- REFACTOR gate: não necessário

## Known Stubs

None.

## Threat Flags

None — todas as ameaças identificadas no threat_model do plano estão mitigadas pela implementação (T-21-01 via `if processed >= rqLimit then break end`; T-21-05 via fallback `math.huge`).

## Self-Check: PASSED

- [x] modules/engine.lua — modificado e commitado (632ddf7)
- [x] components/ui.lua — modificado e commitado (8d2264a)
- [x] tests/run.lua — 7 novos testes adicionados e commitados (04aab05)
- [x] `retryEligible` presente em engine.lua: 4 ocorrências
- [x] `table.sort(retryEligible` presente: 1 ocorrência
- [x] `craft.started_at` no sort: confirmado
- [x] `retry_count` ausente de _persistWorkMaybe (linhas 63-92): 0 ocorrências
- [x] `[R:` presente em ui.lua: 1 ocorrência
- [x] `jobSymbol` inalterada (sem retry_count nas linhas 391-403)
