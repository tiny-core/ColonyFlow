# Phase 24: Testes de Integração

## Goal
Cobrir cenários de falha real que os testes unitários atuais não alcançam: ME oscilante durante craft em andamento, periférico que faz timeout via safeCallTimeout, colony sem requests, e inventário de destino cheio.

## Scenarios
1. ME fica offline enquanto craft está em `crafting` → job vira waiting_retry ao tentar confirmar entrega
2. safeCallTimeout dispara (parallel mock) → erro "timeout" propagado corretamente pelo engine
3. Colony retorna lista vazia → engine não processa nada, stats.processed = 0
4. Destino cheio (exportItem retorna 0) → waiting_retry com err "destino_cheio"

## Files Likely Touched
- `tests/run.lua` (4+ novos testes de integração via mocks existentes)

## Depends On
Phase 19, Phase 20 (safeCallTimeout já implementado)

## Complexity
Low — só novos testes, sem mudança de produção
