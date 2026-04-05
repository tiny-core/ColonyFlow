---
status: partial
phase: 03-craft-entrega-com-progress-o
source: [03-VERIFICATION.md]
started: "2026-04-05T18:00:00.000Z"
updated: "2026-04-05T20:40:00.000Z"
---

## Current Test

number: 3
name: Craft apenas do faltante e sem duplicar jobs
expected: |
  Para missing > 0, o sistema inicia craft apenas do faltante e não repete craft em ciclos consecutivos.
awaiting: user response

## Tests

### 1. Rodar harness de testes
expected: `tests/run.lua` imprime `Tests: N/N OK`
result: pass

### 2. Entrega sem craft quando já há estoque no ME
expected: Para uma request cujo item já existe no ME, o sistema exporta para o destino padrão e não chama craft.
result: issue
reported: "Com duas requests do mesmo item (ex.: espadas), se já existir 1 unidade no destino, o sistema não envia a segunda até remover a primeira do destino."
severity: minor

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
passed: 1
issues: 1
pending: 3
skipped: 0
blocked: 0

## Gaps

- truth: "Duas requests concorrentes do mesmo item não devem ser 'satisfeitas' pela mesma unidade já presente no destino."
  status: failed
  reason: "User reported: Com duas requests do mesmo item, se já existir 1 unidade no destino, a outra request não recebe entrega até remover do destino."
  severity: minor
  test: 2
  artifacts: []
  missing: []
