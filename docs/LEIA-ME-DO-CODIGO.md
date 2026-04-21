# Leia-me do código

Este guia existe para ajudar você a ler o ColonyFlow do ponto de entrada até o coração (engine/scheduler) e as integrações (MineColonies e ME/AE2), entendendo o "por quê" das decisões.

## Como pensar o sistema

Modelo mental (camadas):

- **Entrada/Bootstrap:** `startup.lua` chama o bootstrap e valida ambiente/config/periféricos.
- **Infra (lib/):** utilitários sem "regra de negócio" (config, logger, cache, helpers).
- **Domínio (modules/):** regras e orquestração (engine, scheduler, minecolonies, me, inventory, equivalence, tier).
- **Apresentação (components/):** UI ASCII (2 monitores) consumindo snapshot, sem IO de periféricos.

Regra de ouro:

- **IO e decisão não devem viver na UI.** O engine produz estado/snapshot; a UI apenas renderiza.

## Fluxo principal (do pedido ate a entrega)

Fluxo simplificado:

1. Ler requests do MineColonies (`modules/minecolonies.lua`)
2. Normalizar para um formato interno estável (request id, target, itens aceitos)
3. Resolver candidatos e aplicar tiers/equivalências (`modules/equivalence.lua`, `modules/tier.lua`)
4. Resolver/inspecionar destino e calcular faltante real (`modules/inventory.lua`)
5. Consultar ME (estoque + craftabilidade) e abrir craft apenas do faltante (`modules/me.lua`)
6. Entregar ao destino e validar (quando possível) (`modules/me.lua` + destino)
7. Atualizar estado, logs e UI (engine -> snapshot -> components/ui.lua)

Pontos onde bugs normalmente aparecem:

- Identidade de request e deduplicação de trabalho (não abrir craft duplicado)
- Resolução de destino (não entregar no container errado)
- Matching (não confundir variantes / dano)
- UI/loop (não travar o sistema por redraw ou IO extra)

## Mapa do repositório

Diretórios principais:

- `lib/` infraestrutura compartilhada (config/logger/cache/util/version/bootstrap)
- `modules/` regras e integrações (engine/scheduler/minecolonies/me/inventory/equivalence/tier/...)
- `components/` UI ASCII (monitores)
- `tools/` ferramentas (instalador, gerador de manifest)
- `tests/` harness de testes (executado via `startup test`)
- `data/` dados do usuário (ex.: `mappings.json`)

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

## Glossário

- **request**: pedido vindo do MineColonies (pode aceitar varios itens equivalentes)
- **target**: destino do pedido (container/periferico)
- **chosen**: item escolhido para atender o pedido (pode ser igual ao pedido ou equivalente aceito)
- **missing**: faltante real = max(0, requerido - presente_no_destino)
- **retry/backoff**: política de retentativa para falhas temporárias (ME offline, destino ausente)
- **snapshot**: estado consolidado publicado pelo engine e consumido pela UI (sem IO na UI)

## Operação (rodar, doctor, testes)

No computador (CC: Tweaked):

- Rodar: `startup`
- Diagnóstico: `tools/install.lua doctor` (quando instalado via instalador) ou `startup doctor` (se exposto)
- Configuração: `startup config`
- Testes: `startup test`

Boas práticas:

- Depois de mexer em arquivos Lua, rode `startup test`.
- Em falhas de periférico, procure mensagens no log e banners/alertas na UI.

## Quando X quebra (onde olhar)

Sintomas comuns:

- **Craft duplicado / craft demais:** ver `modules/engine.lua` (chaves/estado de work), `modules/me.lua` (dedupe/job tracking)
- **Entrega no lugar errado:** ver `modules/me.lua` (exportação) e resolução de destino/config em `lib/bootstrap.lua`
- **Item não casa no ME:** ver `modules/minecolonies.lua` (normalização) e `modules/equivalence.lua`/`modules/tier.lua`
- **UI travando / flicker:** ver `components/ui.lua` e `modules/snapshot.lua` (UI deve consumir snapshot)
- **Periféricos somem:** ver `modules/peripherals.lua` e `modules/doctor.lua`

Docs de apoio:

- `docs/SUMMARY.md` (visão rápida do sistema)
- `docs/ARCHITECTURE.md` (camadas e responsabilidades)
- `docs/PITFALLS.md` (armadilhas e recuperação)
