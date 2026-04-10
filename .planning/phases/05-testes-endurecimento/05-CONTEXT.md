# Phase 05: Testes + Endurecimento

## Objetivo

Garantir regressão e qualidade: seleção de candidatos, tier gating, comportamento “não craftável”, CLI de mapeamentos, e retenção/observabilidade (logs e relatórios).

## Escopo

- Expandir o harness de testes (logs de execução, SKIP opcional).
- Adicionar casos de teste que cobrem regressões recentes:
  - Seleção por tier (prioridade correta quando gating está ativo).
  - Fallbacks de craftabilidade (getItem vs isItemCraftable/isCraftable).
  - Item não craftável não vira erro genérico na UI (vira retry + entra em “Itens sem craft”).
  - Retenção de logs respeitando `log_max_files` e não apagando o arquivo atual.
- Endurecer ferramentas operacionais (`startup map` com `package.path` correto).

## Fora de escopo

- Adicionar equivalências “padrão” obrigatórias no dataset (o arquivo de mapeamentos é controlado pelo usuário).
- Mudanças de UI e novas telas (a não ser ajustes para suportar novos estados já existentes).

## Critérios de sucesso

- `startup test` gera relatório em arquivo e retorna sucesso quando não há falhas.
- Testes novos cobrem os comportamentos que já causaram regressões nesta milestone.
- `startup map` funciona sem erro de `require("lib.util")` em ambiente CC:Tweaked.

