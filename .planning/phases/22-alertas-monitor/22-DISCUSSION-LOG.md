# Phase 22: Alertas de Monitor - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-28
**Phase:** 22-alertas-monitor
**Areas discussed:** Quais statuses disparam alerta, Esquema de cores, Posição do resumo no Monitor 2

---

## Quais statuses disparam alerta

| Option | Description | Selected |
|--------|-------------|----------|
| Toda waiting_retry >N min | Qualquer request em retry por mais de N minutos aparece em destaque — simples e garante que nada passe despercebido | ✓ |
| Só blocked_by_tier e nao_craftavel | waiting_retry transitórias nunca aparecem como alerta — menos ruído, mas pode esconder requests esquecidas | |
| waiting_retry com err nao_craftavel | Só waiting_retry cujo campo err contém 'nao_craftavel' — distingue falha de craft de falha de periférico | |

**User's choice:** Toda waiting_retry >N min

---

| Option | Description | Selected |
|--------|-------------|----------|
| Continua acumulando | stuck_since_ms definido na primeira vez, nunca reseta durante retries | ✓ |
| Reseta a cada tentativa falha | stuck_since_ms atualizado cada vez que volta para waiting_retry | |

**User's choice:** Continua acumulando — timer cresce com o tempo total presa

---

## Esquema de cores

| Option | Description | Selected |
|--------|-------------|----------|
| Vermelho para tier, amarelo para outros | blocked_by_tier → vermelho (ação humana); nao_craftavel + waiting_retry → amarelo | ✓ |
| Tudo vermelho | Qualquer stuck >N min fica vermelha independente do motivo | |
| Dois níveis de tempo | Amarelo entre N e 2N min, vermelho acima de 2N | |

**User's choice:** Vermelho para blocked_by_tier (precisa de ação humana); amarelo para os demais

---

| Option | Description | Selected |
|--------|-------------|----------|
| Só minutos: '12m' | GOAL.md especifica 'Xm'. Simples, cabe na coluna ETAPA | ✓ |
| Minutos e segundos: '12m30s' | Mais preciso mas ocupa mais espaço na coluna | |

**User's choice:** Só minutos: "12m"

---

## Posição do resumo no Monitor 2

| Option | Description | Selected |
|--------|-------------|----------|
| Linha na seção OPERAÇÃO | Adicionada aos contadores existentes; visível apenas quando há presas | ✓ |
| Banner fixo no topo (linha 2) | Sempre na linha 2 do monitor; ocupa espaço permanentemente | |
| Footer do monitor de status | Na última linha; discreta mas sempre visível | |

**User's choice:** Linha na seção OPERAÇÃO junto com os contadores existentes

---

| Option | Description | Selected |
|--------|-------------|----------|
| Só na view principal | GOAL.md: máx 1 linha; view main já tem a seção OPERAÇÃO | ✓ |
| Em todas as views ativas | Garante que o alerta não seja perdido durante rotação | |

**User's choice:** Só na view principal (main)

---

## Claude's Discretion

- Posicionamento exato da linha "Presas: N >Xm" dentro da seção OPERAÇÃO (antes ou após contadores existentes) — decidir com base no espaço disponível
- Cor da linha de resumo no Monitor 2: amarelo sugerido por Claude (mistura tipos de stuck)

## Deferred Ideas

None.
