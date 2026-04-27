---
status: complete
phase: 20-roteamento-multi-destino
source: [20-VERIFICATION.md]
started: 2026-04-26T00:00:00.000Z
updated: 2026-04-27T00:00:00.000Z
---

## Current Test

[testing complete]

## Tests

### 1. Menu "Roteamento de destino" no Config CLI
expected: Ao rodar `startup config`, o menu principal exibe "Roteamento de destino" entre "Delivery" e "Update-check". Ao entrar, as 11 classes são listadas com o valor atual em parênteses (vazio = `()`). Editar e salvar persiste em `config.ini` na seção `[delivery_routing]`.
result: pass

### 2. Roteamento real no loop do engine
expected: Com `armor_helmet=rack_tools_0` configurado e `rack_tools_0` online, uma request de helmet é entregue em `rack_tools_0` e não no `default_target_container`. Com `rack_tools_0` offline, o fallback entrega no `default_target_container` normalmente.
result: issue
reported: "deu erro no loop: engine.lua:128: missing '[' after '%f' in pattern (CC:Tweaked Lua 5.1 nao suporta frontier pattern). Segundo ponto: removida a funcionalidade inteira — nao faz sentido rotear por classe pois varios guard towers podem pedir o mesmo item; default_target_container deve ser unico (warehouse) e o currier resolve a entrega. default_target_container simplificado para valor unico."
severity: blocker

## Summary

total: 2
passed: 1
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Roteamento por classe de item entrega em perifericos distintos conforme configurado"
  status: failed
  reason: "User reported: feature removida a pedido — multi-destino nao faz sentido com multiplas guard towers pedindo mesmo item; default via warehouse resolve pelo currier"
  severity: blocker
  test: 2
  root_cause: "Decisao de design: funcionalidade removida, nao um bug a corrigir"
  artifacts:
    - path: "modules/engine.lua"
      issue: "frontier pattern %f nao suportado em CC:Tweaked Lua 5.1"
  missing:
    - "Feature removida em commit 8264e0f"
