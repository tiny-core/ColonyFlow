# Pesquisa de Funcionalidades

**Domínio:** automação de requisições MineColonies com AE2 e CC: Tweaked
**Pesquisado em:** 2026-04-05
**Confiança:** HIGH

## Panorama de Funcionalidades

### Table Stakes

| Funcionalidade | Por que é esperada | Complexidade | Notas |
|----------------|--------------------|--------------|-------|
| Leitura automática de requisições da colônia | Sem isso o sistema não automatiza MineColonies de verdade | MÉDIA | Deve usar `colonyIntegrator.getRequests()` como fonte primária |
| Consulta de estoque e craftabilidade no ME | A automação precisa saber o que já existe e o que pode ser produzido | MÉDIA | `meBridge.getItem()` e verificação de `isCraftable` são centrais |
| Reconciliação do destino antes do craft | Evita craftar itens que já estão parcialmente entregues | MÉDIA | Requer varredura de slots do inventário de destino |
| Solicitação de autocrafting do faltante | É o núcleo de valor do sistema | MÉDIA | Deve usar `craftItem` apenas para a quantidade faltante |
| Entrega automática ao destino | Fecha o ciclo operacional | ALTA | Exige mapear corretamente o inventário do pedido |
| Painel operacional em monitores | Automação sem observabilidade vira caixa-preta | MÉDIA | Um monitor para fila, outro para status agregado |
| Logs estruturados com falhas e retentativas | Sistemas autônomos precisam explicar o que estão fazendo | BAIXA | Fundamental para suporte e ajustes de configuração |

### Diferenciadores

| Funcionalidade | Proposta de valor | Complexidade | Notas |
|----------------|-------------------|--------------|-------|
| Cálculo exato do faltante por destino | Reduz desperdício e crafting desnecessário | MÉDIA | Diferencia o sistema de scripts simplistas baseados apenas na requisição bruta |
| Painel misto da colônia | Ajuda a operar a logística com contexto humano e estrutural | MÉDIA | Pode exibir cidadãos, prédios em obra, backlog e saúde do ME |
| Fila inteligente com retentativas | Suporta packs reais com falhas intermitentes | ALTA | Precisa de estados claros: pendente, aguardando, erro, resolvido |
| Layout responsivo com paginação | Permite uso em monitores de tamanhos diferentes | MÉDIA | Importante em bases já existentes com restrições físicas |
| Estrutura modular extensível | Prepara integrações futuras sem reescrita | BAIXA | Facilita comandos manuais, cache, alertas e novos painéis |

### Anti-Features

| Funcionalidade | Por que costuma ser pedida | Por que é problemática | Alternativa |
|----------------|----------------------------|------------------------|-------------|
| Matching por nome exibido | Parece fácil de entender na UI | Quebra com idioma, packs e variantes de item | Usar nome técnico e metadados |
| Refazer craft a cada ciclo sem debouncing | Dá sensação de “reatividade” | Duplica solicitações e gera spam de crafting | Controlar fila local e jobs já abertos |
| UI super densa em um único monitor | Parece economizar espaço | Reduz legibilidade e dificulta operação | Separar fila e status em dois monitores |
| Dependência de input manual para erros comuns | Dá mais controle ao operador | Mata o valor de operação autônoma | Retentar automaticamente e escalar por log/UI |

## Dependências Entre Funcionalidades

```text
Descoberta de periféricos
    └──requer──> Configuração e bootstrap
Leitura de requisições
    └──requer──> Integração MineColonies
Reconciliação do destino
    └──requer──> Mapeamento de inventários
Craft inteligente
    └──requer──> Consulta ME + reconciliação do destino
Entrega automática
    └──requer──> Craft inteligente + roteamento do container
Painel duplo
    └──depende──> Estado agregador confiável
Retentativas e logs
    └──sustentam──> Operação autônoma
```

### Notas de Dependência

- **Craft inteligente requer reconciliação do destino:** sem conferir slots, o sistema não sabe o faltante real.
- **Entrega automática requer roteamento de inventários:** exportar para o container errado invalida o ciclo inteiro.
- **Painel duplo depende de um estado agregador:** UI não deve consultar periféricos diretamente a cada redraw.
- **Retentativas dependem de classificação de erro:** faltou padrão, faltou energia, bridge offline e destino ausente exigem ações distintas.

## Definição de MVP

### Lançar com

- [ ] Descoberta e validação de periféricos essenciais — sem isso o sistema não pode iniciar com segurança
- [ ] Leitura de requisições via MineColonies — origem oficial do backlog
- [ ] Catálogo de itens ME com disponibilidade e craftabilidade — base para decisão
- [ ] Reconciliação do destino por slots — garante cálculo correto do faltante
- [ ] Abertura de crafting para o faltante real — entrega o valor central do produto
- [ ] Entrega automática ao inventário configurado — fecha o ciclo funcional
- [ ] Dois monitores com paginação e refresh em tempo real — observabilidade mínima viável
- [ ] Logs em português com rotação e níveis — suporte operacional
- [ ] Fila com retentativas e estados claros — confiabilidade de produção

### Adicionar Após Validação

- [ ] Comandos manuais de pausa, retry forçado e diagnóstico — úteis após o núcleo estabilizar
- [ ] Cache de consultas do ME e heurísticas por prioridade — adicionar quando a escala justificar
- [ ] Regras de aliases por item problemático — adicionar quando surgirem casos reais do pack

### Consideração Futura

- [ ] Matching por NBT completo — adiar até existir necessidade real
- [ ] Métricas históricas e dashboard analítico — valioso, mas não essencial para a v1
- [ ] Suporte multi-colônia ou multi-bridge — só quando houver uma topologia que exija isso

## Matriz de Priorização

| Funcionalidade | Valor ao usuário | Custo de implementação | Prioridade |
|----------------|------------------|------------------------|------------|
| Leitura de requisições | HIGH | MEDIUM | P1 |
| Consulta ME e craft inteligente | HIGH | MEDIUM | P1 |
| Entrega automática | HIGH | HIGH | P1 |
| Painel dual-monitor | HIGH | MEDIUM | P1 |
| Logs e retentativas | HIGH | MEDIUM | P1 |
| Comandos manuais | MEDIUM | LOW | P2 |
| Matching por NBT | MEDIUM | HIGH | P3 |
| Analytics histórico | LOW | MEDIUM | P3 |

## Análise Comparativa

| Funcionalidade | Scripts simplistas | Automação manual do jogador | Nossa abordagem |
|----------------|--------------------|-----------------------------|-----------------|
| Cálculo de faltante | Normalmente inexistente | Feito visualmente pelo jogador | Reconciliação por destino antes do craft |
| Observabilidade | Logs pobres ou inexistentes | Depende da memória do operador | UI dedicada + logs estruturados |
| Entrega ao destino | Frequentemente parcial | Manual | Automatizada e verificável |
| Robustez | Falha em loops ou itens ausentes | Exige intervenção constante | Fila com estados e retentativas |

## Fontes

- https://minecolonies.com/wiki/ — natureza das colônias, trabalhadores e prédios que geram demanda
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/colony_integrator/ — leitura de requisições e dados da colônia
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/me_bridge/ — consulta, craft e exportação pelo ME Bridge
- https://tweaked.cc/ — suporte a monitores, inventários, eventos, periféricos e paralelismo

---
*Pesquisa de funcionalidades para: automação MineColonies-ME*
*Pesquisado em: 2026-04-05*
