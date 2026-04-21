# Architecture

Este documento descreve a arquitetura do ColonyFlow em camadas e os principais contratos entre modulos.

## Visao geral (camadas)

```text
┌───────────────────────────────────────────────────────────────┐
│                        Apresentacao (UI)                       │
├───────────────────────────────────────────────────────────────┤
│  components/ui.lua  -> render dual-monitor a partir de snapshot│
├───────────────────────────────────────────────────────────────┤
│                       Aplicacao / Dominio                      │
├───────────────────────────────────────────────────────────────┤
│  modules/scheduler.lua  -> loop + budget                        │
│  modules/engine.lua     -> tick, fila/work, estado              │
│  modules/snapshot.lua   -> contrato de snapshot (sem IO)        │
├───────────────────────────────────────────────────────────────┤
│                        Integracoes / IO                         │
├───────────────────────────────────────────────────────────────┤
│  modules/minecolonies.lua -> colonyIntegrator (requests/buildings)│
│  modules/me.lua           -> meBridge (estoque/craft/export)      │
│  modules/inventory.lua    -> leitura de slots/destinos            │
│  modules/peripherals.lua  -> discovery/health                     │
├───────────────────────────────────────────────────────────────┤
│                           Infra (lib)                            │
├───────────────────────────────────────────────────────────────┤
│  lib/config.lua, lib/logger.lua, lib/cache.lua, lib/util.lua      │
└───────────────────────────────────────────────────────────────┘
```

## Responsabilidades (resumo)

| Area | Arquivo | Responsabilidade |
|------|---------|------------------|
| Entrada | `startup.lua` | ponto de entrada; delega para bootstrap |
| Bootstrap | `lib/bootstrap.lua` | carrega config; resolve perifericos; inicializa modulos |
| Loop | `modules/scheduler.lua` | coordena ticks; aplica budget/limites por ciclo |
| Estado/Decisao | `modules/engine.lua` | processa requests, controla work por request, transicoes de estado |
| UI contract | `modules/snapshot.lua` | cria snapshot consolidado para UI (sem IO) |
| UI | `components/ui.lua` | renderiza snapshot em 2 monitores; pagina e mostra status |
| MineColonies | `modules/minecolonies.lua` | le requests/buildings e normaliza payload |
| ME/AE2 | `modules/me.lua` | consulta estoque/craftabilidade; abre crafts; exporta ao destino |

## Contratos e invariantes importantes

- UI deve consumir **snapshot** (nao chamar perifericos).
- Integracoes (`minecolonies`, `me`, `inventory`) devem encapsular `pcall`/tratamento de erro e retornar dados normalizados para o engine.
- Engine deve manter estado explicito por request/work para evitar duplicidade.
- Calculo de faltante deve usar destino como fonte de verdade parcial (nao craftar cegamente).

## Estrutura do repo (o que fica onde)

- `lib/`: infraestrutura reutilizavel e generica
- `modules/`: regras e integracoes
- `components/`: UI ASCII
- `data/`: dados do usuario (ex.: `mappings.json`)
- `tests/`: harness de testes
- `tools/`: instalador e ferramentas auxiliares

## Leitura recomendada

1. `startup.lua` -> `lib/bootstrap.lua`
2. `modules/scheduler.lua` -> `modules/engine.lua`
3. `modules/snapshot.lua` -> `components/ui.lua`
4. `modules/minecolonies.lua` e `modules/me.lua`

