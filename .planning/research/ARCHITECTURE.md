# Pesquisa de Arquitetura

**Domínio:** sistema autônomo de logística MineColonies ↔ AE2 em Lua
**Pesquisado em:** 2026-04-05
**Confiança:** HIGH

## Arquitetura Padrão

### Visão Geral do Sistema

```text
┌──────────────────────────────────────────────────────────────────────┐
│                         Camada de Apresentação                      │
├──────────────────────────────────────────────────────────────────────┤
│  Monitor de Requisições   │   Monitor de Status   │   Logs locais   │
├──────────────────────────────────────────────────────────────────────┤
│                           Camada de Aplicação                       │
├──────────────────────────────────────────────────────────────────────┤
│  Scheduler  │  Processador de fila  │  Orquestrador de crafting     │
│             │                       │  Orquestrador de entrega       │
├──────────────────────────────────────────────────────────────────────┤
│                          Camada de Integração                       │
├──────────────────────────────────────────────────────────────────────┤
│  Colony API │  ME Bridge API        │  Inventários/Containers        │
│  Config INI │  Periféricos monitor  │  Modem / descoberta            │
├──────────────────────────────────────────────────────────────────────┤
│                           Camada de Estado                          │
├──────────────────────────────────────────────────────────────────────┤
│  Config carregada │ Estado runtime │ Fila persistível │ Rotação logs │
└──────────────────────────────────────────────────────────────────────┘
```

### Responsabilidades dos Componentes

| Componente | Responsabilidade | Implementação típica |
|------------|------------------|----------------------|
| Bootstrap | Carregar config, descobrir periféricos e iniciar módulos | `startup.lua` enxuto que delega ao app principal |
| Registry de periféricos | Resolver nomes e capacidades de cada device | módulo de descoberta com validações e fallback |
| Coletor de requisições | Ler `getRequests()` e normalizar payloads | módulo MineColonies isolado |
| Resolver de itens | Mapear item pedido para item técnico do ME | serviço de matching por nome técnico e dano |
| Reconciliador de destino | Inspecionar slots e calcular faltante real | adaptadores de inventário + agregação por item |
| Orquestrador ME | Consultar estoque, craftabilidade e abrir jobs | wrapper do `meBridge` com tratamento de erro |
| Entregador | Exportar itens ao destino correto e validar resultado | uso de `exportItemToPeripheral` ou `exportItem` |
| Estado/UI | Manter snapshots prontos para renderização | store em memória com projeções para cada monitor |
| Logger | Registrar eventos com severidade e rotação | escrita em arquivos por data/tamanho |

## Estrutura Recomendada do Projeto

```text
/
├── startup.lua              # bootstrap mínimo
├── config.ini               # configuração do operador
├── lib/
│   ├── bootstrap.lua        # inicialização geral
│   ├── config.lua           # parser INI e defaults
│   ├── logger.lua           # logs e rotação
│   ├── state.lua            # store global em memória
│   └── util.lua             # helpers compartilhados
├── modules/
│   ├── peripherals.lua      # descoberta e validação
│   ├── minecolonies.lua     # leitura/normalização de requests
│   ├── me.lua               # consultas, craft e exportações
│   ├── inventory.lua        # leitura de slots e somatórios
│   ├── queue.lua            # estados, retries e reconciliação
│   └── scheduler.lua        # loops, timers e coordenação
├── components/
│   ├── request_board.lua    # render do monitor de requisições
│   ├── colony_board.lua     # render do monitor de status
│   ├── table.lua            # tabelas ASCII responsivas
│   └── pager.lua            # paginação e navegação
└── logs/
    └── *.log                # arquivos rotativos
```

### Racional da Estrutura

- **`lib/`** concentra infraestrutura reutilizável e sem dependência de domínio.
- **`modules/`** isola integrações e regras de negócio.
- **`components/`** separa UI ASCII da lógica operacional.
- **`logs/`** evita poluir a raiz e simplifica rotação/limpeza.

## Padrões Arquiteturais

### Padrão 1: Orquestração por Camadas

**O que é:** módulos de integração não decidem negócio; eles apenas leem/escrevem no mundo.
**Quando usar:** sempre que houver múltiplos periféricos e decisões compostas.
**Trade-offs:** adiciona algumas funções extras, mas reduz acoplamento e retrabalho.

### Padrão 2: Snapshot de Estado para UI

**O que é:** a UI renderiza um snapshot consolidado, não periféricos diretamente.
**Quando usar:** em monitores com refresh frequente.
**Trade-offs:** exige um store central, mas evita flicker, leituras repetidas e inconsistência visual.

### Padrão 3: Fila de Trabalho com Estados Explícitos

**O que é:** cada requisição percorre estados como `pending`, `checking`, `crafting`, `delivering`, `waiting_retry`, `error`, `done`.
**Quando usar:** sempre que falhas parciais forem possíveis.
**Trade-offs:** requer modelagem disciplinada, mas torna retry, logs e UI muito mais claros.

## Fluxo de Dados

### Fluxo Principal de Requisição

```text
MineColonies request
    ↓
Normalização do pedido
    ↓
Matching do item técnico
    ↓
Leitura do destino
    ↓
Cálculo do faltante
    ↓
Consulta ME / estoque
    ↓
Solicitação de craft do faltante
    ↓
Exportação ao destino
    ↓
Atualização do estado + UI + log
```

### Gestão de Estado

```text
Loops de integração
    ↓
Store central em memória
    ↓
Projeções derivadas
    ├── monitor de requisições
    ├── monitor de status
    ├── fila e retries
    └── logs/diagnóstico
```

### Fluxos-Chave

1. **Descoberta de periféricos:** config → rede de periféricos → validação de capabilities → registro runtime.
2. **Reconciliação de pedido:** request MineColonies → inventário de destino → faltante real → ação no ME.
3. **Observabilidade:** eventos de fila → logger → snapshot → painéis.

## Considerações de Escala

| Escala | Ajustes recomendados |
|--------|----------------------|
| Baixa (1-20 pedidos ativos) | Polling simples, snapshots integrais e redraw total aceitáveis |
| Média (20-100 pedidos ativos) | Cache curto, redraw parcial, paginação e reconciliação incremental |
| Alta (100+ pedidos ativos) | Debouncing agressivo, índices por item/destino e limites por ciclo de processamento |

### Prioridades de Escala

1. **Primeiro gargalo:** consultas repetidas a periféricos e inventários — resolver com cache curto e batch por ciclo.
2. **Segundo gargalo:** renderização excessiva nos monitores — resolver com diffs de tela e paginação estável.

## Anti-Padrões

### Anti-Padrão 1: UI acoplada ao polling

**O que fazem:** o componente de tela consulta MineColonies e ME diretamente.
**Por que é errado:** mistura IO, negócio e renderização; gera flicker e leituras duplicadas.
**Faça isto:** usar store central e renderização baseada em snapshot.

### Anti-Padrão 2: Estado implícito no fluxo

**O que fazem:** inferem o estado da requisição apenas por logs ou pelo último passo executado.
**Por que é errado:** retry e diagnóstico ficam opacos.
**Faça isto:** persistir estado explícito por requisição/chave de trabalho.

## Pontos de Integração

### Serviços Externos

| Serviço | Padrão de integração | Notas |
|---------|----------------------|-------|
| MineColonies via `colonyIntegrator` | leitura periódica e normalização | fonte da demanda, sem escrever de volta |
| AE2 via `meBridge` | consulta, craft e exportação | verificar `isCraftable`, energia e CPUs quando relevante |
| Inventários de destino | leitura de slots e exportação | precisam ser nomeados ou fisicamente posicionados de forma previsível |
| Monitores avançados | renderização segmentada | ideal usar componentes desacoplados e paginação |

### Fronteiras Internas

| Fronteira | Comunicação | Notas |
|-----------|-------------|-------|
| `minecolonies ↔ queue` | tabelas normalizadas | nunca usar payload cru da UI como regra de negócio |
| `queue ↔ me` | contratos de item e quantidades | centralizar cálculo do faltante antes de chamar o bridge |
| `state ↔ components` | snapshots prontos para render | UI não conhece periféricos |
| `scheduler ↔ logger` | eventos estruturados | logs devem refletir transições reais de estado |

## Fontes

- https://tweaked.cc/ — APIs de periféricos, monitores, inventários, eventos e paralelismo
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/colony_integrator/ — modelo de leitura da colônia
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/me_bridge/ — craft, consulta e exportação do ME Bridge
- https://minecolonies.com/wiki/ — natureza operacional de colônias, prédios e trabalhadores

---
*Pesquisa de arquitetura para: automação MineColonies-ME*
*Pesquisado em: 2026-04-05*
