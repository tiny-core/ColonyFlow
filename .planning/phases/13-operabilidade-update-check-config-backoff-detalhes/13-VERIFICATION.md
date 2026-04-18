# Phase 13 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Desabilitar update-check:
   - Em `config.ini`, setar `[update] enabled=false` (ou `startup config` -> `Update-check` -> `Checagem de update` = NAO)
   - Rodar `startup`
   - Confirmar que a UI sobe normalmente e nao mostra erro
   - No Monitor 2 (status), tocar em `[UPD]` e confirmar `Status: disabled`
2. Backoff em erro:
   - Simular HTTP bloqueado/off
   - Confirmar que o sistema nao "congela" por 6h sem tentar novamente; deve tentar conforme retry/backoff
   - Esperado (defaults): 120s, 240s, 480s... ate cap em 900s
3. Tela de detalhes:
   - No Monitor 2, tocar em `[UPD]` para entrar na view de update
   - Confirmar que mostra (nesta ordem):
     - Installed
     - Available
     - Status
     - Stale
     - Last checked
     - Last success
     - Last err
     - Manifest
   - Confirmar ASCII-only e layout nao quebra em monitores menores

## Resultado

- [ ] Automated OK
- [ ] Manual OK
