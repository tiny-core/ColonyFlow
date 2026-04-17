# Phase 16: Observabilidade de Performance (metricas + contadores) - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
Medir desempenho e custo de IO para guiar otimizacao sem chute:
- tempo de `engine.tick` e `ui.tick`
- contagem de chamadas a perifericos (ME, MineColonies, inventarios)
- cache hit/miss por namespace (onde aplicavel)
- exibicao discreta no Monitor 2 (Status) e/ou logs em DEBUG
</domain>

<decisions>
- **D-01:** Nao mudar comportamento funcional; apenas instrumentacao.
- **D-02:** Exibicao deve ser discreta e opcional (config.ini).
- **D-03:** Metricas devem ser baratas (usar `os.epoch("utc")` e contadores simples).
</decisions>

<canonical_refs>
- `modules/scheduler.lua` (loops)
- `modules/engine.lua` (tick)
- `components/ui.lua` (tick/render)
- `modules/me.lua` e `modules/minecolonies.lua` (IO)
- `lib/cache.lua` (cache namespaces)
</canonical_refs>

---
*Phase: 16-observabilidade-performance-metricas-contadores*
