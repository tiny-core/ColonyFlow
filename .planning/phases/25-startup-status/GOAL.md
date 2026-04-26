# Phase 25: startup status

## Goal
`startup status` imprime o estado atual do sistema em texto plano (requests pendentes, saúde dos periféricos, versão instalada, último update check) sem iniciar o loop principal.

## Behavior
- Lê `data/state.json`, `data/version.json`, `data/update_check.json`, `config.ini`
- Imprime resumo em ~10 linhas: versão, N requests em andamento, saúde (periférico presente/ausente), status do update
- Retorna exit code 0 se saudável, 1 se algum periférico essencial ausente
- Não requer periféricos conectados para rodar (lê só arquivos)

## Files Likely Touched
- `startup.lua` (novo case "status"), novo `modules/status_report.lua`

## Depends On
Phase 19 (complete)

## Complexity
Low
