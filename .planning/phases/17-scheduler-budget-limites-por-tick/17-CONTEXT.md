# Phase 17: Scheduler com Budget (limites por tick) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
Reduzir picos/travamentos limitando trabalho por ciclo:
- processar no max N requests por `engine.tick`
- limitar chamadas caras ao ME/inventarios por janela
- escalonar tarefas pesadas (scan de destino, list ME) em rodadas separadas
</domain>

<decisions>
- **D-01:** Budgets configuraveis via `config.ini` (defaults seguros).
- **D-02:** Sempre manter correção: quando budget estourar, adiar para proximo tick.
- **D-03:** UI deve mostrar quando esta "throttled" (indicador discreto).
</decisions>

<canonical_refs>
- `modules/scheduler.lua`
- `modules/engine.lua`
- `modules/me.lua`
- `modules/inventory.lua`
</canonical_refs>

---
*Phase: 17-scheduler-budget-limites-por-tick*
