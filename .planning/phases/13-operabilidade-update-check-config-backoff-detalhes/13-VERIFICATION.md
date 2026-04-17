# Phase 13 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Desabilitar update-check:
   - Em `config.ini`, setar `[update] enabled=false`
   - Rodar `startup`
   - Confirmar que a UI sobe normalmente e nao mostra erro; update-check deve ficar discreto/inativo
2. Backoff em erro:
   - Simular HTTP bloqueado/off
   - Confirmar que o sistema nao "congela" por 6h sem tentar novamente; deve tentar conforme retry/backoff
3. Tela de detalhes:
   - No Monitor 2, entrar na view de update
   - Confirmar que mostra: installed, available, status, stale, last_checked, last_success, last_err, manifest_url (truncada)
   - Confirmar ASCII-only e layout nao quebra em monitores menores

## Resultado

- [ ] Automated OK
- [ ] Manual OK
