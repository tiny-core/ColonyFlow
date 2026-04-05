# Roadmap: MineColonies ME Automation

**Created:** 2026-04-05
**Granularity:** standard
**Mode:** yolo

## Overview

Objetivo: entregar um sistema autônomo em Lua (CC: Tweaked) que lê requisições do MineColonies, decide o que craftar no AE2 com base em estoque e destino, aplica filtragem/equivalências com tier gating, entrega itens automaticamente e oferece observabilidade completa (UI + logs).

## Phases

| # | Fase | Goal | Requisitos | Critérios de sucesso |
|---|------|------|------------|----------------------|
| 1 | Fundação Operacional | Boot confiável com config, logs, cache e periféricos validados | CFG-01, CFG-02, LOG-01, LOG-02, CACHE-01, ME-01, ROB-01, ROB-02 | 5 |
| 2 | Núcleo de Requisições + Filtros | Normalizar requests, resolver equivalências/tiers e calcular faltante real por destino | MC-01, MC-02, DEL-01, DEL-02, DEL-04, EQ-01, EQ-02, TIER-01, TIER-02, CACHE-02, CFG-03 | 5 |
| 3 | Craft + Entrega com Progressão | Integrar ME para craft e entrega, evitando duplicidade e respeitando tier gating por building | ME-02, ME-03, ME-04, DEL-03, EQ-03, TIER-03, MC-03 | 5 |
| 4 | UI + Configuração Operacional | UI dual-monitor, paginação, status misto e editor de mapeamentos com logs de substituição | UI-01, UI-02, UI-03, CFG-04, EQ-04 | 5 |
| 5 | Testes + Endurecimento | Harness de testes, cobertura de mapeamentos e ajustes de performance/estabilidade | TEST-01, TEST-02 | 4 |

## Phase Details

### Phase 1: Fundação Operacional

Goal: o programa inicia sempre, valida periféricos essenciais, registra tudo e se mantém estável em loop.

Inclui:
- Estrutura de arquivos com `startup.lua` e `config.ini` na raiz e módulos em subpastas
- Parser INI com defaults e validação mínima
- Logger estruturado com rotação
- Cache TTL simples (com limites)
- Registry e validação de periféricos (colonyIntegrator, meBridge, monitores, modem, destinos)
- Scheduler base com watchdog e modo degradado

Success criteria:
1. Sistema inicia sem travar mesmo com periféricos ausentes, exibindo mensagem clara e logando o motivo.
2. `config.ini` ausente → defaults são aplicados e registrados.
3. Logs são escritos com nível e rotação funciona sem acumular arquivos infinitos.
4. Cache TTL funciona e não cresce sem limites.
5. Loop principal roda continuamente e sobrevive a erros de `pcall` sem encerrar.

### Phase 2: Núcleo de Requisições + Filtros

Goal: o sistema entende corretamente o que a colônia pede e decide “o que falta” e “o que pode ser equivalente”, sem ainda depender de craft/entrega.

Inclui:
- Coleta e normalização de `getRequests()`
- Modelo interno de requisição (id, state, target, itens aceitos)
- Reconciliador de destino (varredura total de slots, somatórios)
- Motor de equivalências (classe + tier) e resolver de candidatos
- Classificador de tier (regras explícitas, tags, metadados, fallback por nome)
- Cache de destinos e inferências

Success criteria:
1. Requisições pendentes são listadas e normalizadas em um formato estável.
2. Para um pedido com `count` e destino, o sistema calcula o faltante real corretamente.
3. Banco de equivalências aceita mapeamento como “jetpack ↔ iron chestplate” e gera candidatos.
4. Tier é inferido de forma consistente (com override via JSON/config).
5. Pedidos com destino inválido entram em estado de retry com log e sem craft cego.

### Phase 3: Craft + Entrega com Progressão

Goal: fechar o ciclo operacional com AE2: craft do faltante e entrega ao destino correto, respeitando progressão por building.

Inclui:
- Consulta de item no ME (quantidade disponível + craftável)
- Prevenção de duplicidade de crafting (job já em andamento quando suportado)
- Solicitação de craft para o faltante real
- Exportação/entrega ao destino (preferir alvo configurado) e validação pós-entrega quando possível
- Tier gating: seleção de ferramenta/equipamento equivalente compatível com nível do building

Success criteria:
1. Se o item já estiver disponível no ME, o sistema entrega sem abrir craft desnecessário.
2. Se faltar, o sistema abre craft apenas do faltante e não duplica jobs em ciclos consecutivos.
3. Entrega coloca itens no destino configurado e registra quantidades entregues.
4. Substituições não quebram progressão: itens acima do tier permitido são recusados com log e UI.
5. Em falha (ME offline/destino ausente), o sistema alerta e mantém a requisição na fila com backoff.

### Phase 4: UI + Configuração Operacional

Goal: tornar o sistema operável em produção com dois monitores e uma interface simples de configuração.

Inclui:
- Monitor 1: fila de requisições (estado, item, faltante, ação, página)
- Monitor 2: status misto (colônia + operação + estoque crítico)
- Paginação responsiva e atualização em tempo real baseada em snapshot
- UI/terminal: editor de mapeamentos (equivalências e overrides de tier) persistindo em JSON
- Log detalhado de substituições/sugestões e motivos

Success criteria:
1. UI funciona em diferentes tamanhos de monitor sem quebrar layout.
2. Paginação suporta listas longas sem travar e sem flicker excessivo.
3. UI mostra claramente quando houve substituição vs sugestão (não aceita pela requisição).
4. Editor de mapeamentos altera JSON e efeito aparece no próximo ciclo sem reiniciar.
5. Logs permitem depurar uma substituição a partir do request id e do item escolhido.

### Phase 5: Testes + Endurecimento

Goal: garantir regressão e qualidade: mapeamentos, tiers e regras de progressão validados por testes.

Inclui:
- Harness simples de testes unitários em Lua
- Casos de teste para equivalências e tier gating com itens de mods populares + ATM10 v6.4 (dataset sintético)
- Testes de parser INI, cache e seleção de candidatos
- Ajustes finais de performance e robustez (SP/MP)

Success criteria:
1. Test harness executa localmente no CC e retorna status de sucesso/falha.
2. Cobertura mínima: tiers + equivalências + gating + parser config.
3. Dataset de mapeamentos inclui casos representativos e não permite “pular” tiers por substituição.
4. Loop de produção mantém performance aceitável com cache e refresh configurável.

---
*Roadmap created: 2026-04-05*
