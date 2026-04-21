# Pitfalls

Este documento lista armadilhas tipicas em automacao MineColonies <-> AE2 e como o ColonyFlow evita (ou deve evitar) cada uma.

## 1) Craft duplicado por falta de estado

**Sintoma:**
- o mesmo item abre craft em ciclos consecutivos e o estoque cresce alem do pedido

**Causa comum:**
- nao existe identidade estavel de trabalho por request (ou nao e persistida/lembrada entre ticks)

**Como evitar:**
- manter estado explicito por request/work no engine
- aplicar retry/backoff em falhas (nao repetir acao imediatamente)

**Onde olhar no codigo:**
- `modules/engine.lua` (estado do work por request)
- `modules/me.lua` (dedupe / tracking de craft)

---

## 2) Entregar no container errado

**Sintoma:**
- craft conclui, mas request continua pendente e o destino nao muda

**Causa comum:**
- exportacao do ME depende de onde o bridge esta no mundo e/ou resolucao de periferico incorreta

**Como evitar:**
- centralizar resolucao de destino no bootstrap
- validar destino (quando possivel) por leitura de inventario apos exportacao

**Onde olhar no codigo:**
- `lib/bootstrap.lua` (resolucao/validacao de perifericos e destinos)
- `modules/me.lua` (exportacao ao destino)
- `modules/inventory.lua` (inspecao e agregacao de slots)

---

## 3) Matching fragil de itens (variantes, dano, mods diferentes)

**Sintoma:**
- item "nao encontrado" no ME para itens comuns, ou entrega de variante errada

**Causa comum:**
- usar displayName/aliases soltos e ignorar metadados simples

**Como evitar:**
- usar `name` tecnico como chave primaria
- aplicar tiers/equivalencias de forma explicita (auditoria em logs/UI)

**Onde olhar no codigo:**
- `modules/minecolonies.lua` (normalizacao do payload de request)
- `modules/equivalence.lua` e `modules/tier.lua` (resolucao de candidatos)
- `data/mappings.json` (regras do usuario)

---

## 4) UI travando o sistema

**Sintoma:**
- flicker constante e loop principal lento (perde responsividade)

**Causa comum:**
- UI faz IO (perifericos) ou redraw completo em alta frequencia

**Como evitar:**
- usar snapshot publicado pelo engine
- renderizar com diff/dirty flags quando aplicavel

**Onde olhar no codigo:**
- `modules/snapshot.lua` (contrato: sem IO)
- `components/ui.lua` (render baseado em snapshot)
- `modules/scheduler.lua` (budget/limites por tick)

---

## 5) Falhas silenciosas de perifericos

**Sintoma:**
- telas congeladas, nil access, ou sistema "parado" sem diagnostico claro

**Causa comum:**
- discovery apenas no startup e falta de health/watchdog durante execucao

**Como evitar:**
- validar perifericos no boot e monitorar saude
- entrar em modo degradado com log e banner na UI

**Onde olhar no codigo:**
- `modules/peripherals.lua` (descoberta e health)
- `modules/doctor.lua` (diagnostico)
- `lib/logger.lua` (eventos e contexto)

