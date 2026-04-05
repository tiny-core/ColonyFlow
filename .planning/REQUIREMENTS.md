# Requisitos: MineColonies ME Automation

**Definidos:** 2026-04-05
**Core Value:** Fechar de forma confiável e autônoma o ciclo completo entre pedido do MineColonies e entrega do item correto, craftando somente o necessário.

## Requisitos v1

### Integração MineColonies

- [ ] **MC-01**: O sistema obtém as requisições atuais via `colonyIntegrator.getRequests()` e identifica quais estão pendentes (por estado) para processamento.
- [ ] **MC-02**: Para cada requisição, o sistema extrai a lista de itens aceitos (`request.items`) com `name`, `count`, `tags` e `nbt` quando presentes.
- [ ] **MC-03**: O sistema correlaciona requisições com contexto de colônia (prédios e níveis) usando `colonyIntegrator.getBuildings()` para aplicar regras de tier por building quando aplicável.

### Integração AE2 (ME Bridge)

- [ ] **ME-01**: O sistema verifica conectividade/online do grid antes de operar e entra em modo degradado com log/alerta quando indisponível.
- [ ] **ME-02**: O sistema consulta disponibilidade e craftabilidade por item via ME Bridge (por filtro de item ou tag quando suportado).
- [ ] **ME-03**: O sistema evita duplicidade de jobs de crafting para o mesmo item/quantidade, usando verificação de crafting em andamento quando disponível.
- [ ] **ME-04**: O sistema inicia autocrafting somente para a quantidade faltante calculada e registra o resultado (sucesso/falha ao iniciar).

### Destinos e Entrega

- [ ] **DEL-01**: O sistema valida o inventário de destino antes de craftar, inspecionando todos os slots e somando quantidades por item.
- [ ] **DEL-02**: O sistema calcula a diferença: `faltante = max(0, requerido - presente_no_destino)` e solicita craft apenas desse faltante.
- [ ] **DEL-03**: O sistema entrega automaticamente ao destino configurado, exportando itens e confirmando a variação do inventário quando possível.
- [ ] **DEL-04**: Quando não for possível validar destino (periférico ausente/erro), o sistema registra o evento e coloca a requisição em fila com retentativa (não crafta cegamente).

### Filtragem e Equivalências Entre Mods

- [ ] **EQ-01**: O sistema mantém um banco de equivalências que agrupa itens por “classe” e tier (ex.: `ARMOR_CHEST/IRON`) e permite mapear itens equivalentes entre mods.
- [ ] **EQ-02**: O sistema suporta mapeamentos explícitos como “Armored Jetpack é equivalente a Iron Chestplate (mesmo tier/classe)” e usa isso para priorizar itens disponíveis.
- [ ] **EQ-03**: Ao decidir qual item atender, o sistema respeita a lista de itens aceitos pela requisição; quando a substituição não for explicitamente aceita, o sistema apenas sugere/indica a equivalência na UI/log e mantém o pedido na fila.
- [ ] **EQ-04**: O sistema registra em log todas as substituições/sugestões com motivo (disponibilidade, tier, restrição de building, regra de mapeamento).

### Tiers e Restrições por Progressão

- [ ] **TIER-01**: O sistema classifica itens em tiers (mínimo: `wood/stone/iron/diamond/netherite` para ferramentas, e `leather/iron/diamond/netherite` para armaduras) com regras configuráveis e heurísticas.
- [ ] **TIER-02**: A inferência de tier usa, em ordem: regra explícita do banco de dados, tags do item, metadados simples e fallback por nome técnico.
- [ ] **TIER-03**: O sistema aplica “tier gating” por nível de building/worker: para um dado tipo (ex.: ferramenta de minerador), só aceita tiers permitidos pelo nível atual (tabela configurável).

### Configuração e Mapeamentos

- [ ] **CFG-01**: Na raiz do computador existem apenas `startup.lua` e `config.ini`; demais arquivos ficam em subpastas funcionais.
- [ ] **CFG-02**: O sistema carrega `config.ini` com defaults quando o arquivo não existir e registra quais defaults foram aplicados.
- [ ] **CFG-03**: O sistema carrega mapeamentos adicionais de equivalência e tiers via arquivo JSON em pasta dedicada e permite mesclar com regras embutidas.
- [ ] **CFG-04**: O sistema fornece uma interface de configuração no terminal para adicionar/editar mapeamentos (persistindo no JSON) sem editar código.

### Cache e Performance

- [ ] **CACHE-01**: O sistema implementa cache (TTL) para consultas de itens no ME e para inferência de tier/equivalência, com invalidação por tempo e limites de tamanho.
- [ ] **CACHE-02**: O sistema não revarre inventários de destino desnecessariamente; aplica política de refresh configurável e/ou sob demanda por requisição.

### Interface Dual-Monitor

- [ ] **UI-01**: O sistema usa 2 Advanced Monitors: um painel para requisições e outro painel misto (colônia + operação + estoque crítico).
- [ ] **UI-02**: As telas renderizam tabelas ASCII com layout responsivo ao tamanho do monitor e paginação eficiente para listas longas.
- [ ] **UI-03**: A UI mostra, por requisição, o item pedido, o item escolhido, se houve substituição/sugestão, e o estado (pendente/craftando/entregando/erro/aguardando retry).

### Logs e Robustez

- [ ] **LOG-01**: O sistema implementa logging com níveis (DEBUG/INFO/WARN/ERROR) e mensagens em português, com contexto estruturado (evento, item, quantidades, destino, request id).
- [ ] **LOG-02**: O sistema implementa rotação de logs por tamanho e/ou quantidade máxima de arquivos.
- [ ] **ROB-01**: O sistema roda em loop autônomo e se recupera de falhas transitórias de periféricos sem travar (usa `pcall` e backoff simples).
- [ ] **ROB-02**: O sistema funciona em singleplayer e multiplayer (não depende de estado local do jogador; depende apenas de periféricos e permissões do servidor).

### Testes

- [ ] **TEST-01**: Existe um harness de testes unitários executável no CC que valida: parsing de config, inferência de tier, resolução de equivalências e tier gating.
- [ ] **TEST-02**: Os testes cobrem mapeamentos representativos para mods populares e o modpack ATM10 v6.4, validando que a progressão não é quebrada por substituições.

## Requisitos v2

### Integração Avançada e Precisão de Tier

- **TIER-04**: Inferir tiers por análise de padrões/receitas do ME quando disponível (inputs do padrão) para maior precisão em modpacks complexos.
- **EQ-05**: Suporte a matching por NBT completo e fingerprints quando necessário.

## Fora de Escopo

| Item | Motivo |
|------|--------|
| Modificar a requisição dentro do MineColonies | Fora do alcance de CC: Tweaked; requer mod do lado do servidor |
| Painel web/externo | O objetivo é operar in-world |

## Rastreabilidade

| Requisito | Fase | Status |
|-----------|------|--------|
| MC-01 | Phase 2 | Pending |
| MC-02 | Phase 2 | Pending |
| MC-03 | Phase 3 | Pending |
| ME-01 | Phase 1 | Pending |
| ME-02 | Phase 3 | Pending |
| ME-03 | Phase 3 | Pending |
| ME-04 | Phase 3 | Pending |
| DEL-01 | Phase 2 | Pending |
| DEL-02 | Phase 2 | Pending |
| DEL-03 | Phase 3 | Pending |
| DEL-04 | Phase 2 | Pending |
| EQ-01 | Phase 2 | Pending |
| EQ-02 | Phase 2 | Pending |
| EQ-03 | Phase 3 | Pending |
| EQ-04 | Phase 4 | Pending |
| TIER-01 | Phase 2 | Pending |
| TIER-02 | Phase 2 | Pending |
| TIER-03 | Phase 3 | Pending |
| CFG-01 | Phase 1 | Pending |
| CFG-02 | Phase 1 | Pending |
| CFG-03 | Phase 2 | Pending |
| CFG-04 | Phase 4 | Pending |
| CACHE-01 | Phase 1 | Pending |
| CACHE-02 | Phase 2 | Pending |
| UI-01 | Phase 4 | Pending |
| UI-02 | Phase 4 | Pending |
| UI-03 | Phase 4 | Pending |
| LOG-01 | Phase 1 | Pending |
| LOG-02 | Phase 1 | Pending |
| ROB-01 | Phase 1 | Pending |
| ROB-02 | Phase 1 | Pending |
| TEST-01 | Phase 5 | Pending |
| TEST-02 | Phase 5 | Pending |

**Cobertura:**
- v1 requirements: 33 total
- Mapeados para fases: 33
- Não mapeados: 0 ✓

---
*Requisitos definidos: 2026-04-05*
*Last updated: 2026-04-05 after initial definition*
