---
status: partial
phase: 03-craft-entrega-com-progress-o
source: [03-VERIFICATION.md]
started: "2026-04-05T18:00:00.000Z"
updated: "2026-04-05T18:00:00.000Z"
---

## Current Test

awaiting human testing

## Tests

### 1. Rodar harness de testes
expected: `tests/run.lua` imprime `Tests: N/N OK`
result: pending

### 2. Entrega sem craft quando já há estoque no ME
expected: Para uma request cujo item já existe no ME, o sistema exporta para o destino padrão e não chama craft.
result: pending

### 3. Craft apenas do faltante e sem duplicar jobs
expected: Para missing > 0, o sistema inicia craft apenas do faltante e não repete craft em ciclos consecutivos.
result: pending

### 4. Destino cheio/erro vira waiting_retry
expected: Quando export retorna 0/erro (destino cheio), status vira waiting_retry com backoff e sem spam.
result: pending

### 5. Tier gating por building (fail closed) e fallback para tier menor
expected: Quando um item aceito é acima do tier permitido, o sistema escolhe um item aceito de tier menor; se não houver, bloqueia por tier e não entrega acima.
result: pending

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps

