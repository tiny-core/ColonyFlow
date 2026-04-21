# Phase 16 - Verificacao

## Automated

- Rodar `startup test` e confirmar que termina com `Tests: X/X OK`.

## Manual (in-world)

1. Habilitar observability:
   - Em `config.ini`, adicionar/ajustar:
     - `[observability] enabled=true`
     - `ui_enabled=true`
   - Rodar `startup` (ou reiniciar o programa)
2. UI (Monitor 2 / Status):
   - Confirmar que aparece um bloco com prefixo `[PERF]`
   - Confirmar que os numeros mudam ao longo do tempo (tick\_ms e contadores)
3. Cache hit/miss:
   - Confirmar que `cache <hit>/<miss>` muda durante operacao normal
4. DEBUG (opcional):
   - Em `config.ini`:
     - `[core] log_level=DEBUG`
     - `[observability] debug_log_enabled=true`
     - `debug_log_interval_seconds=30`
   - Confirmar que logs mostram linhas `Metrics` periodicamente (sem spam por tick)

## Resultado

- [ ] Automated OK
- [ ] Manual OK

