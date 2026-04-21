# Phase 17: Scheduler com Budget (limites por tick) - Research

**Created:** 2026-04-21
**Status:** Ready for planning

## Summary

O objetivo e reduzir picos/travamentos dividindo trabalho pesado em "fatias" pequenas por `engine.tick`, com limites configuraveis e comportamento deterministico:
- Processar no maximo N requests por tick, retomando do ponto em que parou.
- Limitar chamadas a perifericos (ME / MineColonies / Inventarios) por tick e por janela (token bucket simples).
- Expor um indicador discreto quando o sistema esta throttled (UI).

Arquitetura atual relevante:
- `modules/scheduler.lua` roda loops independentes (engine/ui/eventos/update) e chama `engine.tick` a cada `core.poll_interval_seconds`.
- `modules/engine.lua` faz fetch de requests + caches e percorre todos os requests em um loop, podendo chamar ME/inventario varias vezes por request.
- Wrappers `modules/me.lua`, `modules/minecolonies.lua`, `modules/inventory.lua` sao pontos naturais para aplicar budget por chamada (antes do `Util.safeCall`).

## Budget model recomendado

### 1) Budget por tick (hard cap)

- Objetivo: nunca fazer trabalho ilimitado dentro de um unico `engine.tick`.
- Implementacao: no inicio de `Engine:tick`, inicializar um objeto `budgetTick` (contadores restantes).
- Aplicacao:
  - `requests_per_tick`: limita quantos requests o engine tenta processar por tick (independente de perifericos).
  - `me_calls_per_tick`, `mc_calls_per_tick`, `inv_calls_per_tick`: limite de chamadas reais a perifericos por tick (antes de `pcall`/`safeCall`).

Quando um limite estourar:
- Parar de consumir a fila no tick atual (nao eh erro).
- Marcar `state.throttle`/`state.scheduler_budget` com `throttled=true` e `reason` (ex.: `me_calls_per_tick`).
- Retomar automaticamente no proximo tick (D-02).

### 2) Budget por janela (token bucket simples)

- Objetivo: amortecer bursts entre ticks e evitar ficar "batendo" no ME/inventario quando ha backlog.
- Implementacao: para cada grupo (me/mc/inv), manter:
  - `window_started_at_ms`
  - `window_seconds`
  - `used_in_window`
  - `limit_in_window`
- A cada chamada: se `now >= start + window` -> reset; se `used >= limit` -> negar.

Defaults sugeridos (safe):
- `window_seconds=2` (caso comum: tick a cada 2s)
- Limites de janela levemente maiores que por tick para permitir algum burst controlado.

## Scheduler / fila de requests

Para garantir `requests_per_tick` com correcoes:
- Persistir um cursor local no Engine (ex.: `self._rq_cursor`) que aponta para o proximo request a processar na lista atual.
- A cada tick:
  - Atualizar a lista de requests (com throttling por tempo, ex.: `requests_refresh_interval_seconds`).
  - Processar ate `requests_per_tick` items a partir do cursor, circularmente.
  - Se budgets (perifericos) estourarem, interromper cedo e manter cursor para retomada.

Isso evita "starvation" de requests no final da lista e reduz travamento quando `#requests` e grande.

## UI: indicador de throttling (D-03)

Recomendacao:
- `state.throttle = { active=true/false, reason="...", until_ms=nil, tick={...} }`
- UI Status (Monitor 2) mostrar uma linha curta quando `active=true`, ex.:
  - `THROTTLED: me_calls_per_tick` (ASCII-only)
  - ou um marcador discreto no header/OPERACAO.

## Pitfalls / cuidados

- Nao transformar throttle em "erro": evitar `state.stats.errors++` para budget.
- Evitar loops infinitos: quando budget estoura, sair do loop atual imediatamente.
- Evitar regressao de corretude: requests nao devem ser marcados como `error/waiting_retry` apenas por throttle; devem permanecer `pending` e serem retomados.
- Log: preferir logar transicoes (entrou/ saiu de throttled) e nao por tick.

## Validation Architecture

O projeto valida via `startup test` (harness em `tests/run.lua`) e verificacao in-world.

Recomendacao de testes unitarios:
- Budget tick/window:
  - Ao exceder limite, wrapper retorna `nil, "budget_exceeded:<kind>"` e NAO chama o peripheral (mock).
  - Ao virar a janela, o budget reseta e permite novamente.
- Engine cursor:
  - Com `requests_per_tick=1` e 3 requests pendentes, em 3 ticks o cursor avanca e todos recebem update.

Verificacao manual:
- Criar backlog artificial (muitos requests) e confirmar:
  - UI mostra indicador de throttling quando limites estouram.
  - O computador nao trava e o backlog reduz ao longo do tempo.
