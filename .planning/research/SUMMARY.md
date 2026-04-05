# Resumo da Pesquisa do Projeto

**Projeto:** MineColonies ME Automation
**Domínio:** automação logística de colônia em Minecraft com Lua
**Pesquisado em:** 2026-04-05
**Confiança:** HIGH

## Resumo Executivo

Este projeto se encaixa em um padrão bem definido de automação in-world: um computador do CC: Tweaked atua como orquestrador, o MineColonies fornece a demanda operacional, o Advanced Peripherals expõe as integrações e o AE2 executa estoque, crafting e exportação. A abordagem recomendada é tratar o sistema como um serviço autônomo com filas, estado explícito, snapshots para UI e wrappers de periféricos com tratamento de falhas.

O maior risco não está em “fazer craft”, mas em fazer craft demais, entregar ao destino errado ou perder a rastreabilidade do que já foi solicitado. Por isso, a ordem certa é: descoberta robusta de periféricos, modelagem da fila, reconciliação do destino, integração ME, entrega validada e só então otimização visual/operacional. Essa sequência maximiza confiabilidade e evita que a UI esconda problemas estruturais.

## Descobertas-Chave

### Stack Recomendado

O núcleo deve permanecer totalmente nativo do ecossistema CC: Tweaked, sem dependências externas. `parallel`, `peripheral`, `term`, `window`, `textutils`, métodos de inventário e sistema de arquivos cobrem praticamente tudo que a aplicação precisa. No lado de integração, `colonyIntegrator` é a origem dos pedidos e `meBridge` é o backend de decisão e execução para estoque, craft e entrega.

**Tecnologias centrais:**
- CC: Tweaked — runtime, UI ASCII, eventos, armazenamento local e coordenação
- Advanced Peripherals — `colonyIntegrator` e `meBridge`
- Applied Energistics 2 — estoque, craftabilidade e exportação
- MineColonies — domínio de requisições, cidadãos e construções

### Funcionalidades Esperadas

O domínio tem um conjunto claro de table stakes: capturar pedidos, consultar o ME, calcular o faltante real, iniciar o craft apenas do necessário e entregar com observabilidade. O diferencial deste projeto está em tratar o destino como fonte de verdade parcial e transformar isso em reconciliação real antes de qualquer craft.

**Must have:**
- Leitura automática das requisições do MineColonies
- Consulta de estoque e craftabilidade no AE2
- Verificação detalhada do inventário de destino
- Craft apenas do faltante real
- Entrega automática ao destino correto
- UI dual-monitor com paginação e atualização em tempo real
- Logs em português e fila com retentativas

**Should have:**
- Painel misto da colônia no segundo monitor
- Descoberta de periféricos com watchdog
- Estado explícito por requisição para evitar duplicidade

**Deferir:**
- Matching por NBT completo
- Analytics histórico
- Suporte multi-colônia ou multi-bridge

### Abordagem Arquitetural

A arquitetura mais segura é em camadas: integrações isoladas, regras de negócio no centro, store em memória para snapshots e componentes de UI desacoplados. O sistema deve ser orientado por uma fila de trabalho com estados explícitos e loops paralelos leves, em vez de um script único sequencial.

**Componentes principais:**
1. Descoberta/registro de periféricos — valida ambiente e capabilities
2. Coletor MineColonies — lê e normaliza requisições
3. Reconciliador de destino — calcula o faltante real
4. Orquestrador ME — consulta estoque, abre crafts e exporta itens
5. Store + UI + logs — mantém operação legível e auditável

### Armadilhas Críticas

1. **Craft duplicado por falta de estado** — evitar com fila explícita e debouncing por requisição
2. **Entrega ao destino errado** — evitar com resolução centralizada do container e validação pós-exportação
3. **Matching frágil de itens** — evitar usando nome técnico e dano, não nome visual
4. **UI travando o sistema** — evitar com snapshots e renderização desacoplada do polling
5. **Falhas silenciosas de periféricos** — evitar com watchdog, revalidação e modo degradado

## Implicações para o Roadmap

### Fase 1: Fundação Operacional
**Racional:** sem bootstrap, config, logging e descoberta confiável de periféricos, qualquer integração posterior fica frágil.
**Entrega:** estrutura modular, parser INI, logger com rotação, registro de periféricos e watchdog básico.
**Endereça:** resiliência de ambiente, observabilidade e preparação do runtime.
**Evita:** falhas silenciosas de periféricos.

### Fase 2: Núcleo de Requisições e Reconciliação
**Racional:** antes de craftar qualquer coisa, o sistema precisa entender corretamente os pedidos e o faltante real.
**Entrega:** leitura de requests, normalização, matching técnico de itens, leitura de destino e fila com estados explícitos.
**Usa:** `colonyIntegrator`, métodos de inventário e estado central.
**Implementa:** coração da lógica de decisão.

### Fase 3: Integração ME e Entrega
**Racional:** só após saber o faltante real faz sentido abrir crafting e enviar itens.
**Entrega:** consulta ao ME, verificação de craftabilidade, abertura de jobs, tracking mínimo e exportação ao destino.
**Usa:** `meBridge` para `getItem`, `craftItem` e exportação.
**Evita:** craft excessivo e entrega incorreta.

### Fase 4: UI Dual-Monitor e Operação Assistida
**Racional:** com o fluxo funcional, a interface pode refletir o estado real sem mascarar problemas.
**Entrega:** dois painéis, paginação, layout responsivo, resumo da colônia, backlog, falhas e status de estoque crítico.
**Implementa:** observabilidade operacional completa.

### Fase 5: Endurecimento e Otimizações
**Racional:** o sistema já resolve o problema principal; agora deve ganhar robustez de longo prazo.
**Entrega:** backoff, retries refinados, redução de polling, melhorias de performance e diagnósticos extras.
**Foco:** confiabilidade, observabilidade e extensibilidade.

### Racional da Ordem

- Primeiro estabilizar ambiente e estado, depois abrir ações irreversíveis como craft/export.
- Reconciliação do destino vem antes do ME para impedir excesso de produção.
- UI vem depois do núcleo para refletir verdade operacional, não suposições.
- Otimização vem por último porque depende do comportamento real do fluxo principal.

### Flags de Pesquisa

Fases que merecem pesquisa mais profunda durante o planejamento:
- **Fase 2:** formato completo de `getRequests()` e estratégia de chave estável por pedido
- **Fase 3:** detalhes do ciclo de crafting, tratamento de erros e modelo de entrega do `meBridge`
- **Fase 4:** desenho de paginação e interação com monitores de diferentes tamanhos

Fases com padrões mais estáveis:
- **Fase 1:** configuração, logging, bootstrap e descoberta seguem padrões conhecidos de CC: Tweaked

## Avaliação de Confiança

| Área | Confiança | Notas |
|------|-----------|-------|
| Stack | HIGH | APIs e capacidades confirmadas em documentação oficial |
| Funcionalidades | HIGH | Escopo alinhado com o problema e com as integrações disponíveis |
| Arquitetura | HIGH | Padrões maduros para sistemas autônomos em CC: Tweaked |
| Armadilhas | HIGH | Riscos derivados diretamente do comportamento esperado das integrações |

**Confiança geral:** HIGH

### Lacunas a Endereçar

- Formato exato do payload de requisição relevante para roteamento de destino — validar no planejamento da Fase 2
- Convenção final de mapeamento entre pedidos MineColonies e containers físicos da base — definir explicitamente nos requisitos
- Critérios de “job já aberto” no ME Bridge para evitar duplicidade — detalhar na Fase 3

## Fontes

### Primárias
- https://tweaked.cc/ — APIs de runtime, periféricos, eventos, monitores e inventários
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/colony_integrator/ — integração com MineColonies
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/me_bridge/ — integração com AE2
- https://minecolonies.com/wiki/ — contexto de domínio da colônia

### Secundárias
- https://docs.advanced-peripherals.de/0.7/ — panorama do mod e compatibilidade

---
*Pesquisa concluída em: 2026-04-05*
*Pronto para roadmap: yes*
