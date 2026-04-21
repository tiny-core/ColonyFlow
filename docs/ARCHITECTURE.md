# Architecture

Este documento descreve a arquitetura do ColonyFlow em camadas e os principais contratos entre módulos.

## Visão geral (camadas)

```text
┌────────────────────────────────────────────────────────────────────┐
│                        Apresentação (UI)                           │
├────────────────────────────────────────────────────────────────────┤
│  components/ui.lua  -> render dual-monitor a partir de snapshot    │
├────────────────────────────────────────────────────────────────────┤
│                       Aplicação / Domínio                          │
├────────────────────────────────────────────────────────────────────┤
│  modules/scheduler.lua  -> loop + budget                           │
│  modules/engine.lua     -> tick, fila/work, estado                 │
│  modules/snapshot.lua   -> contrato de snapshot (sem IO)           │
├────────────────────────────────────────────────────────────────────┤
│                        Integrações / IO                            │
├────────────────────────────────────────────────────────────────────┤
│  modules/minecolonies.lua -> colonyIntegrator (requests/buildings) │
│  modules/me.lua           -> meBridge (estoque/craft/export)       │
│  modules/inventory.lua    -> leitura de slots/destinos             │
│  modules/peripherals.lua  -> discovery/health                      │
├────────────────────────────────────────────────────────────────────┤
│                           Infra (lib)                              │
├────────────────────────────────────────────────────────────────────┤
│  lib/config.lua, lib/logger.lua, lib/cache.lua, lib/util.lua       │
└────────────────────────────────────────────────────────────────────┘
```

## Responsabilidades (resumo)

| Área | Arquivo | Responsabilidade |
|------|---------|------------------|
| Entrada | `startup.lua` | ponto de entrada; delega para bootstrap |
| Bootstrap | `lib/bootstrap.lua` | carrega config; resolve periféricos; inicializa módulos |
| Loop | `modules/scheduler.lua` | coordena ticks; aplica budget/limites por ciclo |
| Estado/Decisão | `modules/engine.lua` | processa requests, controla work por request, transições de estado |
| UI contract | `modules/snapshot.lua` | cria snapshot consolidado para UI (sem IO) |
| UI | `components/ui.lua` | renderiza snapshot em 2 monitores; pagina e mostra status |
| MineColonies | `modules/minecolonies.lua` | lê requests/buildings e normaliza payload |
| ME/AE2 | `modules/me.lua` | consulta estoque/craftabilidade; abre crafts; exporta ao destino |

## Contratos e invariantes importantes

- UI deve consumir **snapshot** (não chamar periféricos).
- Integrações (`minecolonies`, `me`, `inventory`) devem encapsular `pcall`/tratamento de erro e retornar dados normalizados para o engine.
- Engine deve manter estado explícito por request/work para evitar duplicidade.
- Cálculo de faltante deve usar destino como fonte de verdade parcial (não craftar cegamente).

## Estrutura do repo (o que fica onde)

- `lib/`: infraestrutura reutilizável e genérica
- `modules/`: regras e integrações
- `components/`: UI ASCII
- `data/`: dados do usuário (ex.: `mappings.json`)
- `tests/`: harness de testes
- `tools/`: instalador e ferramentas auxiliares

## Leitura recomendada

1. `startup.lua` -> `lib/bootstrap.lua`
2. `modules/scheduler.lua` -> `modules/engine.lua`
3. `modules/snapshot.lua` -> `components/ui.lua`
4. `modules/minecolonies.lua` e `modules/me.lua`
