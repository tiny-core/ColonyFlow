# Phase 12 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Boot normal:
   - Rodar `startup`
   - Confirmar que a UI sobe rapidamente (sem esperar rede)
   - Confirmar que o header mostra `HH:MM:SSZ <versao_instalada>` (ou indicador de versao ausente)
2. HTTP indisponivel:
   - Em um ambiente com HTTP desabilitado, rodar `startup`
   - Confirmar que a UI mostra `UPD:OFF` no header (ASCII) e o sistema continua operando
3. Sem versao instalada:
   - Remover/renomear `data/version.json` (se existir) e rodar `startup`
   - Confirmar que a UI indica ausencia de versao e sugere `tools/install.lua install` (no Monitor 2 / Status)
4. Update disponivel:
   - Garantir que `data/version.json` tenha uma versao menor que a do manifesto remoto
   - Rodar `startup`
   - Confirmar que o header mostra `inst->avail`
   - Confirmar que o Monitor 2 (Status) mostra banner/linha com comando: `tools/install.lua update`
5. Cache + TTL:
   - Confirmar que existe um cache persistido do update-check (ex.: `data/update_check.json`)
   - Reiniciar o computador dentro de 6 horas e confirmar que nao faz nova checagem (ou respeita o TTL, conforme logs)
   - Apos expirar o TTL, confirmar que faz checagem em background novamente

## Resultado

- [ ] Automated OK
- [ ] Manual OK
