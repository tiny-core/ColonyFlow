# Roadmap: MineColonies ME Automation

## Overview

Objetivo: entregar um sistema autônomo em Lua (CC: Tweaked) que lê requisições do MineColonies, decide o que craftar no AE2 com base em estoque e destino, aplica filtragem/equivalências com tier gating, entrega itens automaticamente e oferece observabilidade completa (UI + logs).

## Phases

- [x] **Phase 1: Fundação Operacional** - Bootstrap confiável com config, logs, cache e periféricos validados (completed 2026-04-05)
- [x] **Phase 2: Núcleo de Requisições + Filtros** - Normalizar requests, resolver equivalências/tiers e calcular faltante real por destino
- [x] **Phase 3: Craft + Entrega com Progressão** - Integrar ME para craft e entrega, evitando duplicidade e respeitando tier gating por building
- [x] **Phase 4: UI + Configuração Operacional** - UI dual-monitor, paginação, status misto e editor de mapeamentos com logs de substituição
- [x] **Phase 5: Testes + Endurecimento** - Harness de testes, cobertura de mapeamentos e ajustes de performance/estabilidade
- [x] **Phase 6: Cache + Robustez Operacional** - Cache TTL para consultas do ME e endurecimento para operação longa
- [ ] **Phase 7: Auto-Setup + Compatibilidade MP** - Auto-geração de config.ini, validação/diagnóstico de periféricos e endurecimento para multiplayer
- [ ] **Phase 8: Mapping v2 (Estrutura + Comportamento)** - Evoluir estrutura do mappings.json e o comportamento de equivalências/tiers
- [ ] **Phase 9: Instalador In-Game (Git)** - Script de instalação/atualização que baixa os arquivos do sistema do repositório direto no CC

## Phase Details

### Phase 1: Fundação Operacional

**Goal**: o programa inicia sempre, valida periféricos essenciais, registra tudo e se mantém estável em loop.
**Depends on**: Nothing (first phase)
**Requirements**: CFG-01, CFG-02, LOG-01, LOG-02, CACHE-01, ME-01, ROB-01, ROB-02
**Plans**: 1 plan

Inclui:

- Estrutura de arquivos com `startup.lua` e `config.ini` na raiz e módulos em subpastas
- Parser INI com defaults e validação mínima
- Logger estruturado com rotação
- Cache TTL simples (com limites)
- Registry e validação de periféricos (colonyIntegrator, meBridge, monitores, modem, destinos)
- Scheduler base com watchdog e modo degradado

**Success Criteria** (what must be TRUE):

1. Sistema inicia sem travar mesmo com periféricos ausentes, exibindo mensagem clara e logando o motivo.
2. `config.ini` ausente → defaults são aplicados e registrados.
3. Logs são escritos com nível e rotação funciona sem acumular arquivos infinitos.
4. Cache TTL funciona e não cresce sem limites.
5. Loop principal roda continuamente e sobrevive a erros de `pcall` sem encerrar.

Plans:

- [x] 01-01: Formalizar e verificar a fundação operacional (retroativo)

### Phase 2: Núcleo de Requisições + Filtros

**Goal**: o sistema entende corretamente o que a colônia pede e decide “o que falta” e “o que pode ser equivalente”, sem ainda depender de craft/entrega.
**Depends on**: Phase 1
**Requirements**: MC-01, MC-02, DEL-01, DEL-02, DEL-04, EQ-01, EQ-02, TIER-01, TIER-02, CACHE-02, CFG-03
**Plans**: 1 plan

Inclui:

- Coleta e normalização de `getRequests()`
- Modelo interno de requisição (id, state, target, itens aceitos)
- Reconciliador de destino (varredura total de slots, somatórios)
- Motor de equivalências (classe + tier) e resolver de candidatos
- Classificador de tier (regras explícitas, tags, metadados, fallback por nome)
- Cache de destinos e inferências

**Success Criteria** (what must be TRUE):

1. Requisições pendentes são listadas e normalizadas em um formato estável.
2. Para um pedido com `count` e destino, o sistema calcula o faltante real corretamente.
3. Banco de equivalências aceita mapeamento como “jetpack ↔ iron chestplate” e gera candidatos.
4. Tier é inferido de forma consistente (com override via JSON/config).
5. Pedidos com destino inválido entram em estado de retry com log e sem craft cego.

Plans:

- [x] 02-01: Implementar normalização, tiers e equivalências com reconciliação de destino

### Phase 3: Craft + Entrega com Progressão

**Goal**: fechar o ciclo operacional com AE2: craft do faltante e entrega ao destino correto, respeitando progressão por building.
**Depends on**: Phase 2
**Requirements**: ME-02, ME-03, ME-04, DEL-03, EQ-03, TIER-03, MC-03
**Plans**: 1 plan

Inclui:

- Consulta de item no ME (quantidade disponível + craftável)
- Prevenção de duplicidade de crafting (job já em andamento quando suportado)
- Solicitação de craft para o faltante real
- Exportação/entrega ao destino (preferir alvo configurado) e validação pós-entrega quando possível
- Tier gating: seleção de ferramenta/equipamento equivalente compatível com nível do building

**Success Criteria** (what must be TRUE):

1. Se o item já estiver disponível no ME, o sistema entrega sem abrir craft desnecessário.
2. Se faltar, o sistema abre craft apenas do faltante e não duplica jobs em ciclos consecutivos.
3. Entrega coloca itens no destino configurado e registra quantidades entregues.
4. Substituições não quebram progressão: itens acima do tier permitido são recusados com log e UI.
5. Em falha (ME offline/destino ausente), o sistema alerta e mantém a requisição na fila com backoff.

Plans:

- [x] 03-01: Integrar ME Bridge para craft/entrega com prevenção de duplicidade e gating

### Phase 4: UI + Configuração Operacional

**Goal**: tornar o sistema operável em produção com dois monitores e uma interface simples de configuração.
**Depends on**: Phase 3
**Requirements**: UI-01, UI-02, UI-03, CFG-04, EQ-04
**Plans**: 1 plan

Inclui:

- Monitor 1: fila de requisições (estado, item, faltante, ação, página)
- Monitor 2: status misto (colônia + operação + estoque crítico)
- Paginação responsiva e atualização em tempo real baseada em snapshot
- UI/terminal: editor de mapeamentos (equivalências e overrides de tier) persistindo em JSON
- Log detalhado de substituições/sugestões e motivos

**Success Criteria** (what must be TRUE):

1. UI funciona em diferentes tamanhos de monitor sem quebrar layout.
2. Paginação suporta listas longas sem travar e sem flicker excessivo.
3. UI mostra claramente quando houve substituição vs sugestão (não aceita pela requisição).
4. Editor de mapeamentos altera JSON e efeito aparece no próximo ciclo sem reiniciar.
5. Logs permitem depurar uma substituição a partir do request id e do item escolhido.

Plans:

- [x] 04-01: Implementar UI dual-monitor e ferramentas operacionais de mapeamento

### Phase 5: Testes + Endurecimento

**Goal**: garantir regressão e qualidade: mapeamentos, tiers e regras de progressão validados por testes.
**Depends on**: Phase 4
**Requirements**: TEST-01, TEST-02
**Plans**: 1 plan

Inclui:

- Harness simples de testes unitários em Lua
- Casos de teste para equivalências e tier gating com itens de mods populares + ATM10 v6.4 (dataset sintético)
- Testes de parser INI, cache e seleção de candidatos
- Ajustes finais de performance e robustez (SP/MP)

**Success Criteria** (what must be TRUE):

1. Test harness executa localmente no CC e retorna status de sucesso/falha.
2. Cobertura mínima: tiers + equivalências + gating + parser config.
3. Dataset de mapeamentos inclui casos representativos e não permite “pular” tiers por substituição.
4. Loop de produção mantém performance aceitável com cache e refresh configurável.

Plans:

- [x] 05-01: Consolidar testes, dataset de mapeamentos e endurecimento final

### Phase 6: Cache + Robustez Operacional

**Goal**: reduzir chamadas repetidas a periféricos (principalmente ME Bridge) com cache TTL configurável sem comprometer correção do fluxo.
**Depends on**: Phase 5
**Requirements**: CACHE-01, ROB-02
**Plans**: 1 plan

Inclui:

- Cache TTL para consultas do ME (getItem/listItems/isCraftable)
- Configuração de TTLs no `config.ini` e desativação via `0`
- Testes de regressão para hits/misses de cache

**Success Criteria** (what must be TRUE):

1. Consultas repetidas ao ME no mesmo item não duplicam chamadas dentro do TTL.
2. TTL=0 desativa cache.
3. Testes passam e não há regressões no fluxo principal.

Plans:

- [x] 06-01: Implementar cache de ME Bridge com TTL e testes

### Phase 7: Auto-Setup + Compatibilidade MP

**Goal**: reduzir atrito de instalação e garantir operação previsível em singleplayer e multiplayer (diagnóstico claro e defaults seguros).
**Depends on**: Phase 6
**Requirements**: CFG-02, CFG-03, ROB-02
**Plans**: 1 plan

Inclui:

- Gerar `config.ini` com defaults quando ausente e registrar quais defaults foram aplicados
- Melhorar diagnóstico de periféricos (mensagens mais acionáveis quando algo está ausente)
- Checklist e endurecimento para ambiente multiplayer (permissões, nomes de periféricos, modem)

**Success Criteria** (what must be TRUE):

1. `config.ini` ausente → o sistema cria um arquivo com defaults e continua operando.
2. Logs mostram claramente qual periférico está faltando e qual chave/config resolver.
3. Operação em multiplayer não depende do jogador e falha de forma previsível quando faltar permissão/periférico.

Plans:

- [ ] 07-01: Auto-geração de config e robustez MP

### Phase 8: Mapping v2 (Estrutura + Comportamento)

**Goal**: evoluir o sistema de mapeamentos para suportar estrutura mais expressiva e regras mais previsíveis sem exigir edição manual em massa.
**Depends on**: Phase 7
**Requirements**: CFG-03, EQ-01, EQ-02, EQ-03, TIER-01, TIER-02
**Plans**: 1 plan

Inclui:

- Revisão do formato `data/mappings.json` (v2) mantendo compatibilidade retroativa quando possível
- Regras de resolução de equivalências mais explícitas (ex.: preferências, direção, bloqueios)
- Mecanismo de migração (v1 -> v2) e validação do arquivo
- Atualização do editor (`startup map`) para suportar o novo formato

**Success Criteria** (what must be TRUE):

1. O sistema carrega `mappings.json` v2 e mantém fallback para v1 (ou migra automaticamente).
2. `startup map` consegue editar os principais campos do novo formato.
3. Logs/UI continuam explicando claramente por que um item foi escolhido/substituído.

Plans:

- [ ] 08-01: Implementar mappings v2, migração e editor

### Phase 9: Instalador In-Game (Git)

**Goal**: permitir instalação/atualização dentro do jogo com um único script, baixando arquivos do repositório via HTTP.
**Depends on**: Phase 8
**Requirements**: CFG-01, ROB-01
**Plans**: 1 plan

Inclui:

- Script `install.lua` que baixa uma lista de arquivos do repositório (raw) e escreve no disco do computador
- Modo update: sobrescrever arquivos gerenciados e preservar `config.ini`/dados do usuário quando configurado
- Validação básica (hash/tamanho) e logs de progresso
- Documentação de pré-requisito: HTTP habilitado no CC:Tweaked

**Success Criteria** (what must be TRUE):

1. Um computador “limpo” consegue instalar e rodar o sistema com `pastebin`/`wget`/`http.get` (conforme disponibilidade) apontando para o repositório.
2. Atualização não apaga `config.ini` nem `data/mappings.json` por padrão.
3. Falhas de HTTP/permissões geram mensagens acionáveis.

Plans:

- [ ] 09-01: Implementar instalador/atualizador via Git raw

## Progress

| Phase                              | Plans Complete | Status      | Completed  |
| ---------------------------------- | -------------- | ----------- | ---------- |
| 1. Fundação Operacional            | 1/1            | Complete    | 2026-04-05 |
| 2. Núcleo de Requisições + Filtros | 1/1            | Complete    | 2026-04-10 |
| 3. Craft + Entrega com Progressão  | 1/1            | Complete    | 2026-04-10 |
| 4. UI + Configuração Operacional   | 1/1            | Complete    | 2026-04-10 |
| 5. Testes + Endurecimento          | 1/1            | Complete    | 2026-04-10 |
| 6. Cache + Robustez Operacional    | 1/1            | Complete    | 2026-04-11 |
| 7. Auto-Setup + Compatibilidade MP | 0/1            | Not started | -          |
| 8. Mapping v2 (Estrutura + Comportamento) | 0/1      | Not started | -          |
| 9. Instalador In-Game (Git)        | 0/1            | Not started | -          |
