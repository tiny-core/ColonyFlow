# Leia-me do codigo

Este guia existe para ajudar voce a ler o ColonyFlow do ponto de entrada ate o coracao (engine/scheduler) e as integracoes (MineColonies e ME/AE2), entendendo o "por que" das decisoes.

## Como pensar o sistema

Modelo mental (camadas):

- **Entrada/Bootstrap:** `startup.lua` chama o bootstrap e valida ambiente/config/perifericos.
- **Infra (lib/):** utilitarios sem "regra de negocio" (config, logger, cache, helpers).
- **Dominio (modules/):** regras e orquestracao (engine, scheduler, minecolonies, me, inventory, equivalence, tier).
- **Apresentacao (components/):** UI ASCII (2 monitores) consumindo snapshot, sem IO de perifericos.

Regra de ouro:

- **IO e decisao nao devem viver na UI.** O engine produz estado/snapshot; a UI apenas renderiza.

## Fluxo principal (do pedido ate a entrega)

Fluxo simplificado:

1. Ler requests do MineColonies (`modules/minecolonies.lua`)
2. Normalizar para um formato interno estavel (request id, target, itens aceitos)
3. Resolver candidatos e aplicar tiers/equivalencias (`modules/equivalence.lua`, `modules/tier.lua`)
4. Resolver/inspecionar destino e calcular faltante real (`modules/inventory.lua`)
5. Consultar ME (estoque + craftabilidade) e abrir craft apenas do faltante (`modules/me.lua`)
6. Entregar ao destino e validar (quando possivel) (`modules/me.lua` + destino)
7. Atualizar estado, logs e UI (engine -> snapshot -> components/ui.lua)

Pontos onde bugs normalmente aparecem:

- Identidade de request e deduplicacao de trabalho (nao abrir craft duplicado)
- Resolucao de destino (nao entregar no container errado)
- Matching (nao confundir variantes / dano)
- UI/loop (nao travar o sistema por redraw ou IO extra)

## Mapa do repo

Diretorios principais:

- `lib/` infraestrutura compartilhada (config/logger/cache/util/version/bootstrap)
- `modules/` regras e integracoes (engine/scheduler/minecolonies/me/inventory/equivalence/tier/...)
- `components/` UI ASCII (monitores)
- `tools/` ferramentas (instalador, gerador de manifest)
- `tests/` harness de testes (executado via `startup test`)
- `data/` dados do usuario (ex.: `mappings.json`)

Arquivos na raiz:

- `startup.lua` (ponto de entrada)
- `config.ini` (config do operador)
- `manifest.json` (lista de arquivos gerenciados pelo instalador)

## Roteiro de leitura (ordem sugerida)

1. `README.md`
2. `startup.lua`
3. `lib/bootstrap.lua`
4. `modules/scheduler.lua`
5. `modules/engine.lua`
6. `modules/snapshot.lua` (contrato de snapshot)
7. `components/ui.lua` (render dual-monitor)
8. `modules/minecolonies.lua` (requests)
9. `modules/me.lua` (estoque/craft/entrega)

Leitura em "camadas":

- Primeiro: entender interfaces e responsabilidades de cada arquivo.
- Depois: seguir o fluxo (engine.tick -> work -> snapshot -> UI) e ver onde entram minecolonies e me.

## Glossario

- **request**: pedido vindo do MineColonies (pode aceitar varios itens equivalentes)
- **target**: destino do pedido (container/periferico)
- **chosen**: item escolhido para atender o pedido (pode ser igual ao pedido ou equivalente aceito)
- **missing**: faltante real = max(0, requerido - presente_no_destino)
- **retry/backoff**: politica de retentativa para falhas temporarias (ME offline, destino ausente)
- **snapshot**: estado consolidado publicado pelo engine e consumido pela UI (sem IO na UI)

## Operacao (rodar, doctor, testes)

No computador (CC: Tweaked):

- Rodar: `startup`
- Diagnostico: `tools/install.lua doctor` (quando instalado via instalador) ou `startup doctor` (se exposto)
- Testes: `startup test`

Boas praticas:

- Depois de mexer em arquivos Lua, rode `startup test`.
- Em falhas de periferico, procure mensagens no log e banners/alertas na UI.

## Quando X quebra (onde olhar)

Sintomas comuns:

- **Craft duplicado / craft demais:** ver `modules/engine.lua` (chaves/estado de work), `modules/me.lua` (dedupe/job tracking)
- **Entrega no lugar errado:** ver `modules/me.lua` (exportacao) e resolucao de destino/config em `lib/bootstrap.lua`
- **Item nao casa no ME:** ver `modules/minecolonies.lua` (normalizacao) e `modules/equivalence.lua`/`modules/tier.lua`
- **UI travando / flicker:** ver `components/ui.lua` e `modules/snapshot.lua` (UI deve consumir snapshot)
- **Perifericos somem:** ver `modules/peripherals.lua` e `modules/doctor.lua`

Docs de apoio:

- `docs/SUMMARY.md` (visao rapida do sistema)
- `docs/ARCHITECTURE.md` (camadas e responsabilidades)
- `docs/PITFALLS.md` (armadilhas e recuperacao)

