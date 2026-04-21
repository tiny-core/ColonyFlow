# Pitfalls

Este documento lista armadilhas típicas em automação MineColonies <-> AE2 e como o ColonyFlow evita (ou deve evitar) cada uma.

## 1) Craft duplicado por falta de estado

**Sintoma:**
- o mesmo item abre craft em ciclos consecutivos e o estoque cresce além do pedido

**Causa comum:**
- não existe identidade estável de trabalho por request (ou não é persistida/lembrada entre ticks)

**Como evitar:**
- manter estado explícito por request/work no engine
- aplicar retry/backoff em falhas (não repetir ação imediatamente)

**Onde olhar no codigo:**
- `modules/engine.lua` (estado do work por request)
- `modules/me.lua` (dedupe / tracking de craft)

---

## 2) Entregar no container errado

**Sintoma:**
- craft conclui, mas request continua pendente e o destino não muda

**Causa comum:**
- exportação do ME depende de onde o bridge está no mundo e/ou resolução de periférico incorreta

**Como evitar:**
- centralizar resolução de destino no bootstrap
- validar destino (quando possível) por leitura de inventário após exportação

**Onde olhar no codigo:**
- `lib/bootstrap.lua` (resolução/validação de periféricos e destinos)
- `modules/me.lua` (exportação ao destino)
- `modules/inventory.lua` (inspeção e agregação de slots)

---

## 3) Matching frágil de itens (variantes, dano, mods diferentes)

**Sintoma:**
- item "não encontrado" no ME para itens comuns, ou entrega de variante errada

**Causa comum:**
- usar displayName/aliases soltos e ignorar metadados simples

**Como evitar:**
- usar `name` técnico como chave primária
- aplicar tiers/equivalências de forma explícita (auditoria em logs/UI)

**Onde olhar no codigo:**
- `modules/minecolonies.lua` (normalização do payload de request)
- `modules/equivalence.lua` e `modules/tier.lua` (resolução de candidatos)
- `data/mappings.json` (regras do usuário)

---

## 4) UI travando o sistema

**Sintoma:**
- flicker constante e loop principal lento (perde responsividade)

**Causa comum:**
- UI faz IO (periféricos) ou redraw completo em alta frequência

**Como evitar:**
- usar snapshot publicado pelo engine
- renderizar com diff/dirty flags quando aplicavel

**Onde olhar no codigo:**
- `modules/snapshot.lua` (contrato: sem IO)
- `components/ui.lua` (render baseado em snapshot)
- `modules/scheduler.lua` (budget/limites por tick)

---

## 5) Falhas silenciosas de periféricos

**Sintoma:**
- telas congeladas, nil access, ou sistema "parado" sem diagnóstico claro

**Causa comum:**
- discovery apenas no startup e falta de health/watchdog durante execução

**Como evitar:**
- validar periféricos no boot e monitorar saúde
- entrar em modo degradado com log e banner na UI

**Onde olhar no codigo:**
- `modules/peripherals.lua` (descoberta e health)
- `modules/doctor.lua` (diagnóstico)
- `lib/logger.lua` (eventos e contexto)
