# Phase 03: Craft + Entrega com Progressão - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-05
**Phase:** 03-Craft + Entrega com Progressão
**Areas discussed:** Craft do faltante, Anti-duplicidade de jobs, Entrega ao destino, Tier gating por building

---

## Craft do faltante

| Option | Description | Selected |
|--------|-------------|----------|
| Entrega parcial + craft resto | Exporta o disponível e abre craft só do restante. | ✓ |
| Esperar completar | Só entrega quando o total requerido estiver disponível. | |
| Config. por opção | Default entrega parcial, mas com flag para “entregar só completo”. | |

**User's choice:** Entrega parcial + craft resto  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| Fila + retry | Marca waiting_retry com backoff e loga “não craftável agora”. | ✓ |
| Erro permanente | Marca erro/unsupported até intervenção. | |
| Sugestão apenas | Não tenta craft, mas alerta e mantém na fila. | |

**User's choice:** Fila + retry  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| Preferir em estoque | Entre aceitos, escolhe primeiro o que já tem quantidade no ME; se nenhum, escolhe o mais viável dentro do gating. | ✓ |
| Manter política da Phase 2 | Escolha por vanilla/mod + tier (sem olhar ME) e só depois verifica estoque/craft. | |
| Priorizar craftável | Ignora estoque parcial; escolhe o mais craftável/consistente. | |

**User's choice:** Preferir em estoque  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| Polling isCrafting | Consulta isCrafting a cada ciclo para marcar craftando/ok. | |
| Guardar retorno do craftItem | Guarda handle/job quando existir; fallback se não existir. | ✓ |
| Só estados simples | Só pending/crafting/ready/delivering por leitura pontual do ME. | |

**User's choice:** Guardar retorno do craftItem (com fallback isCrafting)  
**Notes:** Fallback preferido: chave item+qtd.  

| Option | Description | Selected |
|--------|-------------|----------|
| Chave item+qtd | Consulta isCrafting({name,count}) até sair. | ✓ |
| Chave por request | Usa requestId → item+qtd; consulta isCrafting só por name. | |
| Somente lock local | Não confia em isCrafting; só lock TTL local e reavalia por estoque. | |

**User's choice:** Chave item+qtd  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| Exporta primeiro | Exporta do ME para destino, depois abre craft do restante. | |
| Craft primeiro | Abre craft do faltante, depois exporta o que estiver disponível. | ✓ |
| Depende de espaço | Decide com base no espaço do destino. | |

**User's choice:** Craft primeiro  
**Notes:** —  

---

## Anti-duplicidade de jobs

| Option | Description | Selected |
|--------|-------------|----------|
| isCrafting + lock TTL | Checa isCrafting; se não der/for nil, usa lock local TTL. | ✓ |
| Somente isCrafting | Confia 100% no ME bridge. | |
| Somente lock local | Não consulta isCrafting; só lock TTL e reavalia por estoque/craftável. | |

**User's choice:** isCrafting + lock TTL  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| 15s | Evita duplicidade entre ticks rápidos sem atrasar recuperação. | ✓ |
| 60s | Mais conservador; pode atrasar recuperação. | |
| Config. no ini | Default 15s, mas expõe no config.ini. | |

**User's choice:** 15s  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| item+qtd+destino | Evita duplicidade por destino e quantidade. | ✓ |
| requestId+item | Evita duplicar por request; simples. | |
| item apenas | Impede múltiplas requests do mesmo item em paralelo. | |

**User's choice:** item+qtd+destino  
**Notes:** —  

---

## Entrega ao destino

| Option | Description | Selected |
|--------|-------------|----------|
| Destino padrão | Exporta para `delivery.default_target_container`. | ✓ |
| Alvo da request | Tenta alvo específico; fallback pro padrão. | |
| Só quando explícito | Usa alvo da request apenas com mapping explícito. | |

**User's choice:** Destino padrão  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, por snapshot | Re-le destino e confirma aumento de quantidade. | ✓ |
| Não, só confiar no exportItem | Confia no retorno do ME bridge. | |
| Configurable | Default valida por snapshot, com flag para desligar. | |

**User's choice:** Sim, por snapshot  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| Fila + retry | waiting_retry com backoff. | ✓ |
| Entregar parcial | Entrega o que couber e mantém restante na fila. | |
| Erro até intervenção | Erro e aguarda operador. | |

**User's choice:** Fila + retry  
**Notes:** —  

---

## Tier gating por building

| Option | Description | Selected |
|--------|-------------|----------|
| Fail closed | Não atende acima do tier; mantém em retry com log. | ✓ |
| Fail open | Atende normalmente. | |
| Fallback configurável | Default fail closed com flag para fail open. | |

**User's choice:** Fail closed  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| Recusar + retry | Bloqueia por tier e mantém em retry. | |
| Buscar tier menor | Se houver aceito dentro do tier permitido, troca automaticamente. | ✓ |
| Entregar mesmo assim | Ignora gating. | |

**User's choice:** Buscar tier menor  
**Notes:** —  

| Option | Description | Selected |
|--------|-------------|----------|
| Config.ini | Matriz building→maxTier no INI. | |
| JSON no data/ | Estruturado em arquivo de dados. | |
| Híbrido | Defaults embutidos + overrides em JSON; config ativa/aponta. | ✓ |

**User's choice:** Híbrido  
**Notes:** —  

---

## Claude's Discretion

Nenhuma.
