# Pesquisa de Armadilhas

**Domínio:** automação autônoma MineColonies ↔ AE2 em CC: Tweaked
**Pesquisado em:** 2026-04-05
**Confiança:** HIGH

## Armadilhas Críticas

### Armadilha 1: Craft duplicado por falta de estado

**O que dá errado:**
O sistema abre novos crafts para o mesmo pedido em ciclos consecutivos, inflando filas do AE2 e produzindo mais itens do que o necessário.

**Por que acontece:**
O script olha apenas para a requisição bruta e não registra jobs já abertos, itens em trânsito ou o conteúdo atual do destino.

**Como evitar:**
Modelar uma fila com identidade estável por pedido, persistir estados do trabalho e só reavaliar um item após janela de retry ou mudança observável.

**Sinais de alerta:**
Mesmo item sendo craftado repetidamente, backlog parado e estoque crescendo além do pedido.

**Fase para tratar:**
Fase 2 — modelagem da fila e do reconciliador.

---

### Armadilha 2: Entregar para o container errado

**O que dá errado:**
O sistema crafta corretamente, mas exporta para um baú incorreto ou genérico, deixando a colônia ainda sem o item.

**Por que acontece:**
No ME Bridge, exportação adjacente depende do bloco ao lado do bridge, não do computador; além disso, nomes de periféricos em rede podem ser confusos.

**Como evitar:**
Centralizar resolução de destino, validar o periférico configurado no bootstrap e confirmar por leitura do inventário após exportação.

**Sinais de alerta:**
Craft concluído com sucesso, mas a requisição continua pendente e o destino não muda.

**Fase para tratar:**
Fase 3 — integração logística e entrega.

---

### Armadilha 3: Matching frágil de itens

**O que dá errado:**
Pedidos deixam de casar com o item do AE2 ou são atendidos com o item errado.

**Por que acontece:**
Uso de `displayName`, aliases improvisados ou ignorância de metadados básicos.

**Como evitar:**
Usar `name` técnico como chave primária, incluir dano/metadados quando necessário e manter camada de normalização explícita.

**Sinais de alerta:**
Pedidos “sem item correspondente” para itens comuns ou entregas incorretas em variantes similares.

**Fase para tratar:**
Fase 2 — matching e normalização de catálogo.

---

### Armadilha 4: UI travando o sistema

**O que dá errado:**
Os monitores parecem bonitos, mas o loop principal fica lento, perde eventos e aumenta o tempo de resposta do processamento.

**Por que acontece:**
Redraw completo em toda atualização, sem store central nem paginação estável.

**Como evitar:**
Separar renderização do polling, usar snapshots consolidados e redesenhar apenas quando houver mudança relevante ou timer de UI.

**Sinais de alerta:**
Flicker constante, latência no processamento e uso excessivo de ciclos de atualização.

**Fase para tratar:**
Fase 4 — interface e observabilidade.

---

### Armadilha 5: Falhas silenciosas de periféricos

**O que dá errado:**
Um modem cai, o bridge some ou um monitor desconecta e o programa continua em estado inconsistente.

**Por que acontece:**
Descoberta de periféricos feita só no startup e ausência de verificação de saúde durante a execução.

**Como evitar:**
Implementar watchdog de periféricos, revalidação periódica e transições para modo degradado com logs e alertas visuais.

**Sinais de alerta:**
Telas congeladas, nenhuma nova operação, erros intermitentes ou nil access em periféricos.

**Fase para tratar:**
Fase 1 — bootstrap, discovery e resiliência básica.

## Padrões de Dívida Técnica

| Atalho | Benefício imediato | Custo de longo prazo | Quando aceitável |
|--------|--------------------|----------------------|------------------|
| Guardar tudo em variáveis globais | Escrever rápido | Dificulta testes, reinício parcial e manutenção | Nunca em uma v1 modular |
| Parser INI simplista sem validação | Menos código inicial | Configs inválidas geram falhas opacas | Só com defaults fortes e validação posterior |
| Ignorar rotação de logs | Implementação fácil | Disco poluído e análise difícil | Nunca em sistema autônomo duradouro |
| Polling agressivo em todos os periféricos | Sensação de tempo real | Sobrecarga e gargalos | Só em protótipo momentâneo |

## Pegadinhas de Integração

| Integração | Erro comum | Abordagem correta |
|------------|-------------|-------------------|
| `meBridge` | Assumir que o inventário exportado é o adjacente ao computador | Considerar a posição do bridge ou usar `exportItemToPeripheral` |
| `colonyIntegrator` | Usar payload cru diretamente na UI e na fila | Normalizar e versionar o formato interno do pedido |
| Inventários de destino | Somar apenas primeiro slot encontrado | Varredura completa de slots e agregação por item |
| Monitores | Amarrar layout a um tamanho fixo | Medir tamanho em runtime e paginar dinamicamente |

## Armadilhas de Performance

| Armadilha | Sintomas | Prevenção | Quando quebra |
|-----------|----------|-----------|---------------|
| Recontar todos os slots de todos os destinos a cada ciclo | Lag e tempo alto de loop | Cache curto por container e reconciliação sob demanda | Em colônias com muitos pedidos simultâneos |
| Consultar o ME repetidamente para o mesmo item | Tráfego redundante e latência | Índice por item durante o ciclo atual | A partir de dezenas de pedidos repetidos |
| Redesenhar monitor inteiro a todo tick | Flicker e UI cara | Dirty flags, paginação e refresh escalonado | Mesmo em bases médias |

## Erros de Segurança/Confiabilidade

| Erro | Risco | Prevenção |
|------|-------|-----------|
| Aceitar configuração inválida sem fallback | Sistema não sobe ou sobe incorreto | Validar config e registrar defaults aplicados |
| Não capturar erros por chamada de periférico | Crash total por falha transitória | Wrappers com `pcall` e classificação de erro |
| Não limitar retries | Loop infinito e spam de crafting/log | Backoff simples e limiar por requisição |

## Armadilhas de UX Operacional

| Armadilha | Impacto | Melhor abordagem |
|-----------|---------|------------------|
| Exibir apenas erro técnico bruto | Operador não entende a ação necessária | Mensagens em português com causa e próximo passo |
| Misturar backlog, saúde e métricas na mesma tabela | Tela poluída | Separar monitores por responsabilidade |
| Paginação sem contexto | Operador se perde em listas longas | Cabeçalho com página atual, total e filtros implícitos |

## Checklist de “Parece Pronto, Mas Não Está”

- [ ] **Descoberta de periféricos:** detectar ausência e reconectar sem travar
- [ ] **Matching de itens:** validar casos com variantes e dano
- [ ] **Reconciliação do destino:** verificar todos os slots, não só o primeiro
- [ ] **Craft inteligente:** confirmar que abre apenas o faltante
- [ ] **Entrega automática:** validar que o item chegou ao destino correto
- [ ] **Fila e retry:** garantir que erro não gera duplicidade
- [ ] **UI:** confirmar comportamento em monitores de tamanhos diferentes
- [ ] **Logs:** garantir rotação e mensagens úteis em português

## Estratégias de Recuperação

| Armadilha | Custo de recuperação | Passos |
|-----------|----------------------|--------|
| Craft duplicado | MÉDIO | Cancelar ou consumir backlog excedente, limpar estado e reforçar chaves únicas |
| Destino errado | MÉDIO | Corrigir mapeamento, reimportar ao ME se possível e reenfileirar entrega |
| Bridge/periférico offline | BAIXO | Revalidar periféricos, entrar em modo degradado e retomar automaticamente |
| Matching incorreto | MÉDIO | Ajustar normalização/aliases e reprocessar pendências afetadas |

## Mapeamento Armadilha → Fase

| Armadilha | Fase de prevenção | Verificação |
|-----------|-------------------|-------------|
| Falhas silenciosas de periféricos | Fase 1 | Startup falha com diagnóstico claro e watchdog funcional |
| Craft duplicado por falta de estado | Fase 2 | Mesma requisição não abre múltiplos jobs equivalentes |
| Matching frágil de itens | Fase 2 | Itens pedidos casam corretamente com catálogo técnico |
| Entregar para o container errado | Fase 3 | Exportação validada no destino configurado |
| UI travando o sistema | Fase 4 | Renderização não degrada o loop principal |

## Fontes

- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/me_bridge/ — detalhes de exportação e crafting do ME Bridge
- https://docs.advanced-peripherals.de/0.7-bridges/peripherals/colony_integrator/ — fonte de requisições e dados da colônia
- https://tweaked.cc/ — práticas de periféricos, eventos, monitores e paralelismo em CC: Tweaked
- https://minecolonies.com/wiki/ — contexto das requisições de trabalhadores e construções

---
*Pesquisa de armadilhas para: automação MineColonies-ME*
*Pesquisado em: 2026-04-05*
