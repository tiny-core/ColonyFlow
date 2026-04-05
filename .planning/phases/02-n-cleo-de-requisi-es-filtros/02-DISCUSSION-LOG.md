# Phase 02: Núcleo de Requisições + Filtros - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-05
**Phase:** 02 — Núcleo de Requisições + Filtros
**Areas discussed:** Normalização de requests, Destino + faltante real, Equivalências e substituição, Tiers e classes

---

## Normalização de requests

### Pendência
| Option | Description | Selected |
|--------|-------------|----------|
| Tabela configurável | Allow/deny list em config.ini com default permissivo | ✓ |
| Permissivo (como hoje) | Tudo exceto done/completed/fulfilled/success | |
| Conservador | Só estados explicitamente conhecidos | |

**User's choice:** Tabela configurável

### request.items no modelo interno
| Option | Description | Selected |
|--------|-------------|----------|
| Lista de aceitos | Conjunto de opções válidas; sem item primário por default | ✓ |
| Escolher item primário | Usa um item “principal” e os demais como fallback | |
| Modelo raw | Quase sem normalização | |

**User's choice:** Lista de aceitos

### Campos obrigatórios
| Option | Description | Selected |
|--------|-------------|----------|
| Aceitos + quantidades | accepted[] e requiredCount consolidado | |
| Aceitos + metadados | accepted[] + name/desc/minCount/maxStackSize quando houver | |
| O mínimo possível | Só o necessário para Phase 2 | ✓ |

**User's choice:** O mínimo possível

### Identidade do trabalho
| Option | Description | Selected |
|--------|-------------|----------|
| r.id com fallback | Usa r.id; se faltar/colidir, gera chave estável | ✓ |
| Sempre r.id | Assume id único e estável | |
| Chave composta | Ex.: id+target | |

**User's choice:** r.id com fallback

---

## Destino + faltante real

### Resolução de destino
| Option | Description | Selected |
|--------|-------------|----------|
| Mapeamento por config + fallback | Regras por target/building e fallback para default | |
| Somente destino padrão | Sempre usa delivery.default_target_container | ✓ |
| Resolver dinamicamente | Inferência “mágica” por varredura/heurísticas | |

**User's choice:** Somente destino padrão, com `delivery.default_target_container` aceitando lista (usa o primeiro disponível)

### Falha de validação do destino (DEL-04)
| Option | Description | Selected |
|--------|-------------|----------|
| Fila de retry + não crafta | waiting_retry + backoff simples; sem craft cego | ✓ |
| Fallback para destino padrão sempre | Mesmo quando falha, tenta no padrão | |
| Falha dura | Exige ação manual | |

**User's choice:** Fila de retry + não crafta

### Cálculo de faltante com múltiplos aceitos
| Option | Description | Selected |
|--------|-------------|----------|
| Escolhe candidato → calcula faltante desse item | Decide item, depois conta no destino só ele | ✓ |
| Conta todos os aceitos | Soma qualquer item aceito para considerar atendido | |
| Conta aceitos + equivalentes | Considera equivalentes também | |

**User's choice:** Escolhe candidato → calcula faltante desse item

### Cache/refresh (CACHE-02)
| Option | Description | Selected |
|--------|-------------|----------|
| TTL por destino | Cache por periférico com TTL curto + refresh sob demanda | ✓ |
| Sempre revarrer | Sem cache | |
| TTL alto | Cache longo (30–60s) | |

**User's choice:** TTL por destino

---

## Equivalências e substituição

### O que pode virar “item escolhido” (Fase 2)
| Option | Description | Selected |
|--------|-------------|----------|
| Somente itens aceitos | Escolha sempre dentro de request.items | ✓ |
| Aceitos + equivalentes explícitos | Pode escolher item fora de request.items | |
| Modo configurável | safe/suggest/aggressive no config.ini | |

**User's choice:** Somente itens aceitos

### Como resolver quando há vários aceitos
| Option | Description | Selected |
|--------|-------------|----------|
| Resolver por tier/política local | Lista ordenada por tier/categoria, sem ME | ✓ |
| Resolver usando ME já agora | Decide por disponibilidade/craftável do ME | |
| Não resolver; só normalizar | Phase 2 não escolhe | |

**User's choice:** Resolver por tier/política local

### Itens de mod + fallback para vanilla (detalhe do usuário)
**User's choice:**  
- manter allowlist de itens de mod aceitos no banco  
- se pedido for item de mod allowlisted: pode atender com ele  
- se não allowlisted: tentar equivalente vanilla que esteja aceito na request; se não houver, marcar não suportado e manter em retry  
- monitor/UI devem mostrar pedido → escolhido + motivo/fallback

### Registro em log/UI
| Option | Description | Selected |
|--------|-------------|----------|
| Sempre registrar quando houver equivalência | Loga equivalências/sugestões/substituições | ✓ |
| Só quando escolhido | Só loga substituição efetiva | |
| Configurar verbosidade | DEBUG vs INFO | |

**User's choice:** Sempre registrar quando houver equivalência

### Onde vive a allowlist
| Option | Description | Selected |
|--------|-------------|----------|
| No mappings.json | Reusar `data/mappings.json` (editável via CLI) | ✓ |
| Arquivo separado | `data/allowlist_mods.json` | |
| No config.ini | Lista manual | |

**User's choice:** No mappings.json

### Prioridade vanilla vs mod quando ambos aceitos
| Option | Description | Selected |
|--------|-------------|----------|
| Preferir vanilla | Mais previsível | |
| Preferir mod (se allowlisted) | Atende mod por padrão | |
| Deixar configurável | Flag vanilla-first vs mod-first | ✓ |

**User's choice:** Deixar configurável

### Se pedido for mod allowlisted
| Option | Description | Selected |
|--------|-------------|----------|
| Atender com o item pedido | Trata como válido e pode ser escolhido | ✓ |
| Sempre normalizar para vanilla | Tenta cair para vanilla sempre | |
| Depende do request | Usa vanilla se for aceito, senão mod | |

**User's choice:** Atender com o item pedido

### Mod não allowlisted sem equivalente vanilla aceito
| Option | Description | Selected |
|--------|-------------|----------|
| Marcar como não suportado + retry | Loga e mantém fila com backoff | ✓ |
| Ignorar definitivamente | Dropa o pedido | |
| Tentar mesmo assim | Atende mod mesmo sem allowlist | |

**User's choice:** Marcar como não suportado + retry

---

## Tiers e classes

### Preferência de tier
| Option | Description | Selected |
|--------|-------------|----------|
| Preferir tier mais baixo | Conserva recursos | |
| Preferir tier mais alto | Mais forte | |
| Configurável | lowest-first vs highest-first | ✓ |

**User's choice:** Configurável (global)

### Tiers suportados e gold
| Option | Description | Selected |
|--------|-------------|----------|
| Tool: wood/stone/iron/diamond/netherite; Armor: leather/iron/diamond/netherite | Set mínimo v1 | ✓ |
| Incluir gold como tier próprio | Gold como tier separado | |
| Gold tratado como iron | Heurística atual | |

**User's choice:** Tool: wood/stone/iron/diamond/netherite; Armor: leather/iron/diamond/netherite

### Classes/categorias mínimas
| Option | Description | Selected |
|--------|-------------|----------|
| Só ARMOR_CHEST e TOOL_PICKAXE | Começa pequeno por slot | |
| Expandir set básico | Várias classes por slot | |
| Genérico por categoria | Categorias TOOL/ARMOR | ✓ |

**User's choice:** Categorias TOOL e ARMOR

### Gating por nível
| Option | Description | Selected |
|--------|-------------|----------|
| Tabela configurável | mapping nível→tier max por config | |
| Hardcoded simples | regra fixa | |
| Sem gating nesta fase | Só inferir/organizar | ✓ |

**User's choice:** Sem gating nesta fase

### Ordem de inferência
| Option | Description | Selected |
|--------|-------------|----------|
| override > db > tags > name | Controlável e previsível | ✓ |
| override > tags > db > name | Confia mais em tags | |
| Configurável | ordem customizável | |

**User's choice:** override > db > tags > name

### Determinar categoria
| Option | Description | Selected |
|--------|-------------|----------|
| Preferir mappings.json, senão heurística | DB primeiro; fallback heurístico | ✓ |
| Só heurística por nome/tags | Sem dependência de DB | |
| Exigir DB | unknown se não cadastrado | |

**User's choice:** Preferir mappings.json, senão heurística

---

## Claude's Discretion

None

## Deferred Ideas

None
