# Phase 17 (Plan 01) - Summary

- Adicionada secao `[scheduler_budget]` no DEFAULT_INI e validacao no schema para limites/intervalos.
- Criado `modules/budget.lua` (limites por tick e por janela) e inicializado no bootstrap (`state.budget` + `state.throttle`).
- Aplicado enforcement de budget em chamadas de perifericos:
  - ME (`modules/me.lua`)
  - MineColonies (`modules/minecolonies.lua`)
  - Inventarios (`modules/inventory.lua`)
- Engine refatorado para:
  - processar requests por cursor (round-robin) com `requests_per_tick`
  - throttling de refresh de requests (`requests_refresh_interval_seconds`)
  - tratar `budget_exceeded:*` como defer (encerra tick sem virar erro)
- UI Status mostra indicador discreto `THROTTLED: <reason>` quando `state.throttle.active=true` (ASCII-only).
- Adicionados testes unitarios para budget (nega chamada e nao toca peripheral) e para cursor do engine respeitando `requests_per_tick`.
