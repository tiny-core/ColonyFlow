# Phase 21: Retry com Prioridade - Pattern Map

**Mapped:** 2026-04-27
**Files analyzed:** 3 (engine.lua, ui.lua, tests/run.lua) + persistence.lua confirmado somente-leitura
**Analogs found:** 3 / 3

---

## File Classification

| Arquivo Modificado | Role | Data Flow | Analog Mais Próximo | Qualidade |
|-------------------|------|-----------|---------------------|-----------|
| `modules/engine.lua` (Engine:tick — pre-pass) | service | event-driven / batch | próprio `Engine:tick()` budget loop (linhas 1162–1196) | exact |
| `modules/engine.lua` (work[id].retry_count) | model | CRUD | próprio `work[id]` struct (linhas 979–1070) | exact |
| `components/ui.lua` (badge `[R:N]` no ETAPA) | component | request-response | própria coluna ETAPA / `jobSymbol` (linhas 391–403, 535–542) | exact |
| `tests/run.lua` (novos testes do pre-pass) | test | request-response | `engine_request_na_janela_retry_e_ignorado` (linhas 2419–2488) + `engine_cursor_respects_requests_per_tick` (linhas 2489–2569) | exact |

---

## Pattern Assignments

### `modules/engine.lua` — Pre-pass em Engine:tick()

**Analog:** O próprio loop while de Engine:tick(), linhas 1162–1196.

**Ponto de inserção:** Imediatamente antes da linha 1162 (`local n = ...`), após a construção de `baseCtx` (linha 1155) e o cálculo de `rqLimit` (linhas 1157–1159).

**Padrão do loop principal existente** (linhas 1161–1196):
```lua
  local n = type(requests) == "table" and #requests or 0
  if n > 0 then
    local idx = tonumber(self._rq_cursor or 1) or 1
    if idx < 1 or idx > n then idx = 1 end

    local scanned, processed = 0, 0
    while processed < rqLimit and scanned < n do
      local r = requests[idx]
      local currentIdx = idx
      idx = idx < n and idx + 1 or 1
      scanned = scanned + 1

      local ctx = {
        available  = available,
        buildings  = baseCtx.buildings,
        citizens   = baseCtx.citizens,
        snap       = defaultSnap,
        snapErr    = defaultSnapErr,
        targetName = defaultTargetName,
        targetInv  = defaultTargetInv,
        nowEpoch   = baseCtx.nowEpoch,
      }

      local did, budgetErr = self:_processRequest(r, ctx)
      if did == nil and budgetErr ~= nil then
        self._rq_cursor = currentIdx
        publishSnapshot(state)
        self:_persistWorkMaybe()
        return
      end
      if did == true then processed = processed + 1 end
    end
    self._rq_cursor = idx
  else
    self._rq_cursor = 1
  end
```

**Padrão de coleta + sort para o pre-pass — análogo ao pickCandidate (linhas 335–346 + table.sort de config_cli.lua:295):**
```lua
-- Coletar elegíveis para o pre-pass
local retryEligible = {}
local nowEpoch = baseCtx.nowEpoch
for _, r in ipairs(requests) do
  if r and r.id then
    local w = self.work[r.id]
    if w and w.status == "waiting_retry"
       and w.next_retry and w.next_retry <= nowEpoch then
      table.insert(retryEligible, r)
    end
  end
end

-- Ordenar por started_at_ms ASC (mais antigos primeiro — D-01)
-- started_at_ms real no código: work.craft.started_at  (veja nota abaixo)
table.sort(retryEligible, function(a, b)
  local wa = self.work[a.id]
  local wb = self.work[b.id]
  local ta = (wa and type(wa.craft) == "table" and tonumber(wa.craft.started_at)) or math.huge
  local tb = (wb and type(wb.craft) == "table" and tonumber(wb.craft.started_at)) or math.huge
  return ta < tb
end)
```

**NOTA CRITICA — campo `started_at_ms` vs `work.craft.started_at`:**
O CONTEXT.md referencia `work[id].started_at_ms` como nome conceitual. No código real o campo é
`work[id].craft.started_at` (engine.lua linha 819: `work.craft.started_at = nowEpoch`).
A persistência salva como `started_at_ms` (linha 83: `started_at_ms = startedAt`) mas no estado
em memória o acesso correto é `work.craft and work.craft.started_at`.
O planner deve usar `work.craft and tonumber(work.craft.started_at)` no comparador do sort,
com fallback `math.huge` para requests sem craft iniciado (D-01 ainda se aplica — chegam por último).

**Padrão do loop do pre-pass (consumindo `processed` compartilhado — D-05):**
```lua
-- Pre-pass: processar retries elegíveis em ordem de prioridade
local processed = 0   -- declarar ANTES do pre-pass; compartilhado com o loop normal
for _, r in ipairs(retryEligible) do
  if processed >= rqLimit then break end
  local ctx = {
    available  = available,
    buildings  = baseCtx.buildings,
    citizens   = baseCtx.citizens,
    snap       = defaultSnap,
    snapErr    = defaultSnapErr,
    targetName = defaultTargetName,
    targetInv  = defaultTargetInv,
    nowEpoch   = nowEpoch,
  }
  local did, budgetErr = self:_processRequest(r, ctx)
  if did == nil and budgetErr ~= nil then
    -- budget system: preservar cursor e sair (mesmo padrão do loop normal)
    self._rq_cursor = tonumber(self._rq_cursor or 1) or 1
    publishSnapshot(state)
    self:_persistWorkMaybe()
    return
  end
  if did == true then processed = processed + 1 end
end
-- continua para o loop round-robin normal com budget restante (processed já incrementado)
```

**Protocolo de retorno de `_processRequest`** (linhas 964–1071):
- `true, nil`  — processou (conta no budget)
- `false, nil` — ignorou (não conta; ex.: next_retry no futuro, linha 972–974)
- `nil, "budget_exceeded:..."` — budget do sistema excedido; deve abortar o tick

---

### `modules/engine.lua` — Campo `retry_count` em work[id]

**Analog:** Os campos `work.status`, `work.next_retry`, `work.err` no mesmo struct (linhas 979–1000).

**Padrão de leitura/escrita de campo no work struct** (linhas 979–1000):
```lua
local work = self.work[r.id] or {}
work.request_state = r.state
work.target        = r.target
work.requested     = ...
-- (campos existentes são escritos diretamente no hash work)
self.work[r.id] = work
```

**Incremento de `retry_count` — onde inserir:**
`retry_count` deve ser incrementado no ponto de entrada de cada tentativa real. O lugar mais
natural é no início de `_processRequest`, depois da verificação de skip por janela (linha 974),
pois toda chamada que passa dessa guarda representa uma tentativa efetiva:
```lua
-- Após linha 974 (guarda next_retry), antes de qualquer outra lógica:
local work = self.work[r.id] or {}
work.retry_count = (tonumber(work.retry_count or 0) or 0) + 1
self.work[r.id] = work
```

**Inicialização:** Não é necessário — `nil` tratado como 0 via `tonumber(work.retry_count or 0)`.

**Persistência — campo NÃO deve aparecer em `_persistWorkMaybe`** (linhas 63–92):
O job serializado usa campos explícitos: `chosen`, `status`, `missing`, `started_at_ms`,
`retry_at_ms`, `last_err`. `retry_count` é somente memória (D-07) — não adicionar ao bloco
`jobs[id] = { ... }` de `_persistWorkMaybe`.

**Restauração — campo NÃO deve aparecer em `_restorePersistedWork`** (linhas 32–61):
Os campos restaurados são: `chosen`, `status`, `missing`, `last_err`, `retry_at_ms`,
`started_at_ms`. Não incluir `retry_count` aqui.

---

### `components/ui.lua` — Badge `[R:N]` no monitor de requests

**Analog:** A coluna ETAPA renderizada por `jobSymbol` e inserida na linha via `string.format`,
linhas 535–542.

**Padrão de construção da linha** (linhas 535–542):
```lua
local line = string.format(
  "%-" .. reqW .. "s | %-" .. choMax .. "s | %" .. faltW .. "s | %-" .. jobMax .. "s",
  shorten(displayItem, reqW),
  centerText(shorten(chosenDisplay, choMax), choMax),
  shorten(missingLabel, faltW),
  centerText(shorten(jobSymbol(jobState), jobMax), jobMax)
)
```

**Onde inserir o badge `[R:N]`:**
O badge é inserido na expressão da coluna ETAPA (4° campo do format). A abordagem que minimiza
impacto no layout é concatenar ao resultado de `jobSymbol` antes de `centerText`/`shorten`:
```lua
local etapaStr = jobSymbol(jobState)
local retryCount = job and tonumber(job.retry_count or 0) or 0
if retryCount >= 1 then
  etapaStr = etapaStr .. "[R:" .. tostring(retryCount) .. "]"
end
-- então usar shorten(etapaStr, jobMax) no format
```

**Padrão de acesso ao `job` já disponível** na iteração (linha 495):
```lua
local job = state.work and state.work[tostring(r.id)] or nil
-- job.retry_count estará disponível aqui (pode ser nil → tratar como 0)
```

**Função `jobSymbol` existente** (linhas 391–403) — não modificar:
```lua
local function jobSymbol(jobState)
  local s = tostring(jobState or "")
  s = s:lower()
  if s == "" then return "--" end
  if s == "done" then return "OK" end
  if s:find("wait") or s:find("retry") or s:find("await") then return "AG" end
  if s:find("craft") then return "CR" end
  if s:find("pend") then return "PD" end
  if s:find("blocked_by_tier") or s:find("blocked") then return "BT" end
  if s:find("unsupport") or s:find("nao_suport") then return "NS" end
  if s:find("err") or s:find("fail") then return "ER" end
  return shorten(s, 2)
end
```

**Onde o loop de renderização lê o job** (linhas 493–544) — loop principal para linhas visíveis:
O loop já tem `job` disponível em linha 495. O `jobMax` para a coluna é calculado no primeiro
loop de medição (linhas 449–465) — se o badge aumentar o texto da coluna ETAPA, `jobMax` pode
precisar ser ajustado (atualmente limitado a 10 chars na linha 469). `"AG[R:99]"` tem 8 chars;
cabe dentro de 10.

---

### `tests/run.lua` — Novos testes do pre-pass

**Analogs:**
1. `engine_request_na_janela_retry_e_ignorado` (linhas 2419–2488) — padrão para manipular
   `engine.work["id"]` antes do tick e verificar comportamento do skip.
2. `engine_cursor_respects_requests_per_tick` (linhas 2489–2569) — padrão para múltiplos ticks
   verificando budget e cursor.

**Estrutura base de um teste de engine** (linhas 2419–2488 condensado):
```lua
{ "nome_do_teste", function()
  local Engine = require("modules.engine")
  local Cache  = require("lib.cache")

  -- stub periférico mínimo
  local inv = { list = function() return {} end }
  local oldPeripheral = peripheral
  peripheral = {
    isPresent = function(name) return name == "test_inv" end,
    wrap = function() return inv end,
  }

  local cfg = makeCfg({
    minecolonies = { pending_states_allow = "requested", completed_states_deny = "done" },
    delivery     = { default_target_container = "test_inv", destination_cache_ttl_seconds = "0" },
    scheduler_budget = { enabled = "true", requests_per_tick = "2" },
  })

  local state = {
    cfg     = cfg,
    cache   = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
    logger  = { warn = function() end, info = function() end, error = function() end },
    devices = {
      meBridge = {
        isConnected = function() return true end,
        isOnline    = function() return true end,
        getItem     = function(f) return { name = f.name, amount = 5, isCraftable = false } end,
        exportItemToPeripheral = function(f, _) return f.count, nil end,
      },
      colonyIntegrator = {
        getRequests = function()
          return {
            { id = 1, state = "requested", target = "x", count = 1,
              items = { { name = "minecraft:stone", count = 1 } } },
            { id = 2, state = "requested", target = "x", count = 1,
              items = { { name = "minecraft:stone", count = 1 } } },
          }
        end,
        getColonyName            = function() return "t" end,
        amountOfCitizens         = function() return 0 end,
        maxOfCitizens            = function() return 0 end,
        getHappiness             = function() return 0 end,
        isUnderAttack            = function() return false end,
        amountOfConstructionSites = function() return 0 end,
      },
    },
    requests = {},
    stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
  }

  local engine = Engine.new(state)
  state.work = engine.work

  -- Pré-setar work antes do tick (padrão da linha 2475):
  engine.work["1"] = {
    status     = "waiting_retry",
    next_retry = 0,  -- elegível
    craft      = { started_at = 1000 },
  }
  engine.work["2"] = {
    status     = "waiting_retry",
    next_retry = 0,  -- elegível, mais recente
    craft      = { started_at = 2000 },
  }

  engine:tick()
  peripheral = oldPeripheral

  -- Assertions
  assertEq(engine.work["1"].retry_count >= 1, true, "id=1 deve ter retry_count incrementado")
  assertEq(engine.work["2"].retry_count >= 1, true, "id=2 deve ter retry_count incrementado")
end },
```

**Padrão para testar ORDER do pre-pass (started_at_ms ASC):**
Criar 2 requests com `next_retry = 0` e `craft.started_at` diferentes. Limitar budget a 1 com
`requests_per_tick = "1"`. Verificar qual dos dois foi processado primeiro pelo retry_count.

**Padrão para testar que cursor NÃO é alterado pelo pre-pass (D-04):**
Setar `engine._rq_cursor = 2` antes do tick. Após o tick com pre-pass, verificar que o cursor
mantém o valor esperado pelo loop normal (não foi resetado para 1 pelo pre-pass).

---

## Shared Patterns

### Budget Protocol — aplicar a todo código novo em Engine:tick()
**Source:** `modules/engine.lua` linhas 1184–1190
```lua
local did, budgetErr = self:_processRequest(r, ctx)
if did == nil and budgetErr ~= nil then
  self._rq_cursor = currentIdx  -- preservar posição antes de sair
  publishSnapshot(state)
  self:_persistWorkMaybe()
  return
end
if did == true then processed = processed + 1 end
```
**Aplicar a:** loop do pre-pass (substituir `currentIdx` pela lógica adequada — no pre-pass não há
`currentIdx` de cursor; preservar `self._rq_cursor` com valor atual sem alterar).

### isBudgetExceeded helper
**Source:** `modules/engine.lua` linhas 23–25
```lua
local function isBudgetExceeded(err)
  return type(err) == "string" and err:match("^budget_exceeded:") ~= nil
end
```
**Aplicar a:** qualquer chamada que retorne possível `budgetErr` no pre-pass.

### publishSnapshot + _persistWorkMaybe ao sair do tick
**Source:** `modules/engine.lua` linhas 1198–1199
```lua
  publishSnapshot(state)
  self:_persistWorkMaybe()
```
**Aplicar a:** todos os early-return dentro do pre-pass.

### ctx local por request
**Source:** `modules/engine.lua` linhas 1173–1182
```lua
local ctx = {
  available  = available,
  buildings  = baseCtx.buildings,
  citizens   = baseCtx.citizens,
  snap       = defaultSnap,
  snapErr    = defaultSnapErr,
  targetName = defaultTargetName,
  targetInv  = defaultTargetInv,
  nowEpoch   = baseCtx.nowEpoch,
}
```
**Aplicar a:** cada iteração do pre-pass (mesmo padrão — ctx é local por request).

---

## No Analog Found

Nenhum arquivo desta phase fica sem analog. Todos os padrões necessários existem no próprio
codebase com correspondência exata de role + data flow.

---

## Metadata

**Escopo de busca:** `modules/`, `components/`, `tests/`, `lib/`
**Arquivos lidos:** engine.lua (1231 linhas), ui.lua (974 linhas), persistence.lua (59 linhas), tests/run.lua (seções ~2090–2569)
**Data de extração:** 2026-04-27
