---
status: complete
phase: 03-craft-entrega-com-progressao
source: [03-VERIFICATION.md]
started: "2026-04-05T18:00:00.000Z"
updated: "2026-04-21T11:18:39.307Z"
---

## Current Test

[testing complete]

## Tests

### 1. Rodar harness de testes
expected: `tests/run.lua` imprime `Tests: N/N OK`
result: pass

### 2. Entrega sem craft quando já há estoque no ME
expected: Para uma request cujo item já existe no ME, o sistema exporta para o destino padrão e não chama craft.
result: pass

### 3. Craft apenas do faltante e sem duplicar jobs
expected: Para missing > 0, o sistema inicia craft apenas do faltante e não repete craft em ciclos consecutivos.
result: pass

### Test 3.1: Falta de Espaço e Backpressure (Novo Teste)
expected: O sistema detecta que o contêiner de destino final (ex: `minecolonies:rack_0`) não possui capacidade para os itens, e evita enviá-los para o buffer. O monitor exibe todas as requisições (incluindo blocos de construção) em vez de apenas as de equipamentos, através da leitura dos Work Orders.
result: pass

### 4. Destino cheio/erro vira waiting_retry
expected: Quando export retorna 0/erro (destino cheio), status vira waiting_retry com backoff e sem spam.
result: pass

### 5. Tier gating por building (fail closed) e fallback para tier menor
expected: Quando um item aceito é acima do tier permitido, o sistema escolhe um item aceito de tier menor; se não houver, bloqueia por tier e não entrega acima.
result: pass

## Summary

total: 6
passed: 6
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps
