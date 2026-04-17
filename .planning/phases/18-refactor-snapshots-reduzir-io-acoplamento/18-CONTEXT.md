# Phase 18: Refactor por Snapshots (reduzir acoplamento/IO) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
Reduzir complexidade e IO padronizando snapshots:
- engine produz snapshots de requests, work, health e metrics
- UI consome snapshots (nao chama periferico)
- regras de decisao (tiers/equivalencia/escolha) viram funcoes puras testaveis
</domain>

<decisions>
- **D-01:** Mudanca incremental: introduzir snapshots sem reescrever tudo de uma vez.
- **D-02:** Interfaces de modulo devem ser pequenas e previsiveis.
- **D-03:** Otimizacao guiada por metricas (fase 16).
</decisions>

<canonical_refs>
- `modules/engine.lua`
- `components/ui.lua`
- `modules/me.lua`, `modules/minecolonies.lua`, `modules/inventory.lua`
- `tests/run.lua`
</canonical_refs>

---
*Phase: 18-refactor-snapshots-reduzir-io-acoplamento*
