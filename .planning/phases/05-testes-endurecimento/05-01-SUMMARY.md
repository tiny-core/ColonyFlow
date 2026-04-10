# Summary 05-01: Consolidar testes e endurecimento

- Fortaleceu o harness de testes com relatório em arquivo (`logs/tests-*.txt`) e suporte a `[SKIP]`.
- Ajustou seleção de candidatos para:
  - não tratar `getItem().isCraftable=false` como definitivo (tenta `isCraftable/isItemCraftable`)
  - evitar que itens não craftáveis virem erro genérico na UI (vira `waiting_retry` + `nao_craftavel`)
- Endureceu o logger:
  - aplica retenção também na inicialização
  - respeita `log_max_files` e não apaga o arquivo de log atual
- Consertou `startup map` (CLI de mapeamentos) garantindo `package.path` compatível para resolver `lib.util`.
- Adicionou testes de regressão:
  - `engine_nao_craftavel_vira_waiting_retry`
  - `logger_cleanup_respeita_max_files_sem_apagar_atual`

## Verificação

- `startup test`: 23/23 OK (com `equivalencia_jetpack` podendo ser SKIP quando o mapeamento não existe).

