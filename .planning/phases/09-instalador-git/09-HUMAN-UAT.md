---
status: partial
phase: 09-instalador-git
source: [09-VERIFICATION.md]
started: 2026-04-12T00:00:00Z
updated: 2026-04-12T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Bootstrap em computador “limpo”
expected: `wget run <raw-url>/tools/install.lua install` instala o sistema e o `startup.lua` roda sem crash.
result: [pending]

### 2. Doctor com HTTP habilitado/desabilitado
expected: `tools/install.lua doctor` confirma HTTP disponível ou mostra instrução acionável quando indisponível.
result: [pending]

### 3. Update preserva config e mappings por padrão
expected: `tools/install.lua update` não sobrescreve `config.ini` nem `data/mappings.json` por padrão (preservação explícita no output).
result: [pending]

### 4. Update remove órfãos sem tocar preservados
expected: Em update, arquivos órfãos (gerenciados na versão anterior e ausentes no manifesto novo) são removidos sem tocar preservados.
result: [pending]

### 5. Erros de HTTP/URL/permissão são acionáveis
expected: Em falha de HTTP/URL inválida/permissão, o instalador imprime mensagem acionável (incluindo o erro) e sai limpo.
result: [pending]

### 6. Rollback automático em falha no apply
expected: Se falhar no meio do apply, o instalador executa rollback automático via snapshot e não deixa o sistema em estado parcial.
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
