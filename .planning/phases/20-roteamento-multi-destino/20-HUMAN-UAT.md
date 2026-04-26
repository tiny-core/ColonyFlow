---
status: partial
phase: 20-roteamento-multi-destino
source: [20-VERIFICATION.md]
started: 2026-04-26T00:00:00.000Z
updated: 2026-04-26T00:00:00.000Z
---

## Current Test

[aguardando verificação humana no CC:Tweaked]

## Tests

### 1. Menu "Roteamento de destino" no Config CLI
expected: Ao rodar `startup config`, o menu principal exibe "Roteamento de destino" entre "Delivery" e "Update-check". Ao entrar, as 11 classes são listadas com o valor atual em parênteses (vazio = `()`). Editar e salvar persiste em `config.ini` na seção `[delivery_routing]`.
result: [pending]

### 2. Roteamento real no loop do engine
expected: Com `armor_helmet=rack_tools_0` configurado e `rack_tools_0` online, uma request de helmet é entregue em `rack_tools_0` e não no `default_target_container`. Com `rack_tools_0` offline, o fallback entrega no `default_target_container` normalmente.
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
