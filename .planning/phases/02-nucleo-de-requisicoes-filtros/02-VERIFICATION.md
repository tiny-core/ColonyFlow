---
phase: 02-nucleo-de-requisicoes-filtros
verified: "2026-04-05T00:00:00.000Z"
status: pending
score: 0/5 must-haves verified
---

# Phase 2: nucleo-de-requisicoes-filtros — Verification

## Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Requisições pendentes são listadas e normalizadas em um formato interno estável | pending | `modules/minecolonies.lua` (accepted/requiredCount/id estável) |
| 2 | Para um pedido com quantidade e destino, o sistema calcula o faltante real corretamente | pending | `modules/inventory.lua` + `modules/engine.lua` (snapshot + missing) |
| 3 | Banco de equivalências gera candidatos/explicações sem violar accepted[] | pending | `modules/equivalence.lua` + `modules/engine.lua` (seleção apenas em accepted) |
| 4 | Tier é inferido de forma consistente (override > db > tags > nome) e ordenação é configurável | pending | `modules/tier.lua` + `config.ini` (tier_preference) |
| 5 | Falha de destino coloca request em waiting_retry e não executa ações cegas | pending | `modules/engine.lua` (destino_indisponivel / snapErr) |

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tests/run.lua` | Testes cobrindo normalização/seleção/faltante/cache | pending | Rodar em-world (CC) |
| `config.ini` | Parâmetros de pending states, destino e política de seleção | pending | Ajustar conforme mundo |

## Próximos passos de verificação (in-world)

- Rodar `tests/run.lua` no computador do CC.
- Configurar `delivery.default_target_container` para um inventário real acessível e validar que `present/missing` fazem sentido.
- Induzir falha no destino (remover/desconectar periférico) e confirmar `waiting_retry` com logs.
