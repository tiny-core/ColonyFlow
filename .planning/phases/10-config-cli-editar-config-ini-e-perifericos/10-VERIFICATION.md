# Phase 10 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Rodar `startup config` e confirmar que abre o menu:
   - Perifericos
   - Core+Logs
   - Delivery
2. Core+Logs:
   - Alterar `log_level` para `DEBUG`
   - Salvar
   - Abrir `config.ini` e confirmar que comentarios existentes continuam no arquivo
3. Perifericos:
   - Tentar configurar `monitor_requests` igual a `monitor_status`
   - Tentar salvar e confirmar que o CLI bloqueia com erro
4. Delivery:
   - Tentar salvar `export_mode` invalido (ex.: `x`)
   - Confirmar que o CLI bloqueia com erro
5. Backup/escrita segura:
   - Confirmar que foi criado um backup em `data/backups/`
   - Confirmar que nao existe `config.ini.tmp` ao final

## Resultado

- [ ] Automated OK
- [ ] Manual OK
