# Phase 22: Alertas de Monitor - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `components/ui.lua` | component/renderer | request-response (read snapshot, write to monitor) | `components/ui.lua` renderRequests (Phase 21 [R:N] badge) | exact (self-analog: extend existing pattern) |
| `modules/engine.lua` | service/state-machine | event-driven (status transitions) | `modules/engine.lua` `_handleNoCandidate`, `_handleCraft`, `_handleExport` | exact (self-analog: set/clear work fields on status change) |
| `modules/snapshot.lua` | utility/transformer | transform (copy work fields) | `modules/snapshot.lua` `copyWorkJob` (l.63–82) | exact (self-analog: add one field to existing copy block) |
| `lib/config.lua` | config | — | `lib/config.lua` `[observability]` section (l.62–65) in DEFAULT_INI | exact (self-analog: add key to existing section) |
| `tests/run.lua` | test | batch | Phase 21 test block `engine_prepass_*` (l.2719–3252) | exact (self-analog: same state harness, same assertEq pattern) |

---

## Pattern Assignments

### `components/ui.lua` — renderRequests (color/suffix logic)

**Analog:** Same file — Phase 21 `[R:N]` badge pattern in the measurement loop (l.449–471) and render loop (l.540–554).

**Measurement loop pattern** (l.449–471) — include suffix in jobMax measurement:
```lua
-- Current pattern for [R:N] badge in measurement loop:
local etapa = jobSymbol(jobState)
-- WR-02: incluir badge [R:N] na medição para que jobMax reflita largura real
local retryCountM = job and tonumber(job.retry_count or 0) or 0
if retryCountM >= 1 then
  etapa = etapa .. "[R:" .. tostring(retryCountM) .. "]"
end
if #chosenDisplay > choMax then choMax = #chosenDisplay end
if #etapa > jobMax then jobMax = #etapa end
```

**New "Xm" suffix in measurement loop** — append after the existing badge check, same block:
```lua
-- PHASE 22: append stuck suffix to measurement etapa
local stuckSince = job and job.stuck_since_ms or nil
local alertMins  = state.cfg:getNumber("observability", "alert_stuck_minutes", 5)
if stuckSince then
  local elapsedMs = (state.at_ms or os.epoch("utc")) - stuckSince
  local elapsedMin = math.floor(elapsedMs / 60000)
  if elapsedMin >= alertMins then
    etapa = etapa .. tostring(elapsedMin) .. "m"
  end
end
if #etapa > jobMax then jobMax = #etapa end
```

**Render loop color/suffix pattern** (l.540–554) — current etapaStr + [R:N] then fg override:
```lua
local etapaStr = jobSymbol(jobState)
local retryCount = job and tonumber(job.retry_count or 0) or 0
if retryCount >= 1 then
  etapaStr = etapaStr .. "[R:" .. tostring(retryCount) .. "]"
end
-- ... then line format and drawText call:
self:drawText("requests", mon, 1, y, line, fg, bg)
```

**New stuck color + suffix in render loop** — insert after the [R:N] block, before the `line = string.format(...)`:
```lua
-- PHASE 22: stuck alert color and "Xm" suffix
local stuckSince = job and job.stuck_since_ms or nil
local alertMins  = (state.cfg and state.cfg:getNumber("observability","alert_stuck_minutes",5)) or 5
if stuckSince then
  local elapsedMs  = (state.at_ms or os.epoch("utc")) - stuckSince
  local elapsedMin = math.floor(elapsedMs / 60000)
  if elapsedMin >= alertMins then
    etapaStr = etapaStr .. tostring(elapsedMin) .. "m"
    -- D-04: blocked_by_tier → red; D-05: nao_craftavel / waiting_retry → yellow
    local st = tostring(jobState or ""):lower()
    if st == "blocked_by_tier" then
      fg = colors.red
    else
      fg = colors.yellow
    end
  end
end
```

**drawText call pattern** (l.552) — already passes `fg` correctly; no change needed there:
```lua
self:drawText("requests", mon, 1, y, line, fg, bg)
```

---

### `components/ui.lua` — renderStatus (summary line in OPERACAO section)

**Analog:** Same file — the existing OPERACAO counters block (l.753–786).

**Existing OPERACAO header + counters pattern** (l.753–786):
```lua
self:drawText("status", mon, 1, y, centerText("OPERACAO", w), colors.cyan)
-- ...
y = y + 1
self:drawText("status", mon, 1, y, string.rep("-", math.max(0, w))); y = y + 1

local reqCount = (type(state.requests) == "table") and #state.requests or 0
local counters = {
  { label = "Requisicoes",   value = tostring(reqCount) },
  { label = "Entregues",     value = tostring(state.stats.delivered) },
  -- ...
}
for i = 1, #counters do
  if y > h - 2 then break end
  local it = counters[i]
  local leftPrefix = padRight(tostring(it.label or ""), counterLabelW) .. ": "
  local val = tostring(it.value or "")
  local line = shorten(leftPrefix, w)
  self:drawText("status", mon, 1, y, padRight(line, w))
  local startX = #leftPrefix + 1
  if startX <= w then
    self:drawText("status", mon, startX, y, shorten(val, math.max(0, w - #leftPrefix)), colors.white, colors.black, true)
  end
  y = y + 1
end
```

**View-guard pattern** (l.743) — existing pattern to check if on opPage:
```lua
if self.statusPage == opPage or pages == 1 then
  -- OPERACAO section rendered here
end
```

**New "Presas: N >Xm" line** — insert after the counters `for` loop, before the blank-line guard. D-09: only when N > 0. D-10: already guarded by the `opPage` check above.
```lua
-- PHASE 22: stuck summary line (D-08, D-09, D-10)
if y <= h - 2 then
  local stuckCount = 0
  local oldestStuck = nil  -- smallest stuck_since_ms among stuck requests
  local alertMins = (state.cfg and state.cfg:getNumber("observability","alert_stuck_minutes",5)) or 5
  local nowMs = state.at_ms or os.epoch("utc")
  for _, r in ipairs(state.requests or {}) do
    local job = state.work and state.work[tostring(r.id)] or nil
    if job and job.stuck_since_ms then
      stuckCount = stuckCount + 1
      if not oldestStuck or job.stuck_since_ms < oldestStuck then
        oldestStuck = job.stuck_since_ms
      end
    end
  end
  if stuckCount > 0 then
    local oldestMin = oldestStuck and math.floor((nowMs - oldestStuck) / 60000) or alertMins
    local line = "Presas: " .. tostring(stuckCount) .. " >" .. tostring(oldestMin) .. "m"
    self:drawText("status", mon, 1, y, padRight(shorten(line, w), w), colors.yellow, colors.black)
    y = y + 1
  end
end
```

**Note:** `state.at_ms` is set by `Snapshot.build` (l.111 in snapshot.lua). In the snapshot-based view, `state` is the snapshot and `state.at_ms` is the frozen clock timestamp — use it to avoid calling `os.epoch` in UI.

---

### `modules/engine.lua` — `work[id]` struct (stuck_since_ms field)

**Analog:** Same file — `retry_count` field: set in `_processRequest` (l.978), never persisted in `_persistWorkMaybe` (l.63–92).

**Pattern for in-memory-only fields** (l.978 — retry_count):
```lua
-- Set on every effective attempt, in _processRequest
work.retry_count = (tonumber(work.retry_count or 0) or 0) + 1
```

**Pattern for field NOT included in persistence** (l.63–92 — _persistWorkMaybe):
```lua
jobs[id] = {
  request_id = id,
  chosen = work.chosen,
  status = status,
  missing = tonumber(work.missing),
  started_at_ms = startedAt,
  retry_at_ms = tonumber(work.next_retry),
  last_err = work.err,
  -- retry_count intentionally omitted
  -- stuck_since_ms intentionally omitted (same contract)
}
```

**Set stuck_since_ms on first entry to any stuck status** — in `_handleNoCandidate` (l.709–746) and in `_handleMeOffline` / `_handleCraft` / `_handleExport` wherever `work.status` is set to `"blocked_by_tier"`, `"waiting_retry"` (nao_craftavel path), or `"waiting_retry"`:
```lua
-- D-01, D-02: set stuck_since_ms only on FIRST entry to any stuck status
-- Insert immediately before or after work.status = "blocked_by_tier" / "waiting_retry"
if work.stuck_since_ms == nil then
  work.stuck_since_ms = ctx.nowEpoch  -- or os.epoch("utc") where ctx is unavailable
end
```

**Clear stuck_since_ms when leaving stuck state** — in `_processRequest` at the two points where `work.status = "done"` (l.1017, l.924) and at the transition to `"crafting"` or `"delivering"`:
```lua
-- D-02: clear stuck_since_ms when request resolves or advances past stuck
work.stuck_since_ms = nil
work.status = "done"
```

**Status transitions that clear stuck_since_ms** — all places where `work.status` is set to a non-stuck value:
- `work.status = "done"` in `_processRequest` (l.1017)
- `work.status = "done"` after delivery in `_handleExport` (l.924)
- `work.status = "crafting"` in `_handleCraft` (l.816–819)
- `work.status = "pending"` at the end of `_processRequest` (l.1069)

**All stuck-status assignments that SET stuck_since_ms** (need `if work.stuck_since_ms == nil then` guard):
- `_handleNoCandidate` l.731: `work.status = "blocked_by_tier"`
- `_handleNoCandidate` l.736: `work.status = "waiting_retry"` (nao_craftavel path)
- `_handleMeOffline` l.750: `work.status = "waiting_retry"`
- `_handleCraft` l.798: `work.status = "waiting_retry"` (nao_craftavel path)
- `_handleCraft` l.822: `work.status = "waiting_retry"` (craft_falhou path)
- `_handleExport` l.857: `work.status = "waiting_retry"` (destino snapshot fail path)
- `_handleExport` l.893: `work.status = "waiting_retry"` (export fail path)
- `_handleExport` l.905: `work.status = "waiting_retry"` (post-delivery snapshot fail)
- `_handleExport` l.914: `work.status = "waiting_retry"` (validation inconsistency)
- `_markAllWaitingRetry` l.693: `work.status = "waiting_retry"`
- `_processRequest` l.999: `work.status = "waiting_retry"` (no snap path)
- `_processRequest` l.1041–1053: `work.status = "waiting_retry"` (freeSpace paths)

---

### `modules/snapshot.lua` — `copyWorkJob`

**Analog:** Same file — `copyWorkJob` function (l.63–82). Pattern: list every field explicitly (no generic copy).

**Existing copyWorkJob** (l.63–82):
```lua
local function copyWorkJob(job)
  job = asTable(job)
  local craft = nil
  if type(job.craft) == "table" then
    craft = shallowCopy(job.craft)
  end
  return {
    chosen = job.chosen,
    requested = job.requested,
    status = job.status,
    err = job.err,
    needed = job.needed,
    present_total = job.present_total,
    present = job.present,
    missing = job.missing,
    next_retry = job.next_retry,
    delivered = job.delivered,
    craft = craft,
  }
end
```

**New field to add** — append `stuck_since_ms = job.stuck_since_ms,` to the return table. The field is `nil` when not stuck (Lua omits nil keys), so no default is needed:
```lua
return {
  -- ... all existing fields ...
  craft = craft,
  retry_count = job.retry_count,   -- already added in Phase 21 (verify it's here)
  stuck_since_ms = job.stuck_since_ms,  -- PHASE 22: nil when not stuck
}
```

**Note on `at_ms`:** `Snapshot.build` already sets `snap.at_ms = Util.nowUtcMs()` (l.111). The UI reads `state.at_ms` to calculate elapsed time without calling `os.epoch` directly, satisfying the no-IO invariant of the UI.

---

### `lib/config.lua` — `[observability]` section

**Analog:** Same file — the `[observability]` block in `DEFAULT_INI` (l.62–65).

**Existing observability section** (l.62–65):
```ini
[observability]
enabled=false
ui_enabled=false
debug_log_enabled=false
debug_log_interval_seconds=30
```

**New key to add** — append `alert_stuck_minutes=5` inside the same section:
```ini
[observability]
enabled=false
ui_enabled=false
debug_log_enabled=false
debug_log_interval_seconds=30
alert_stuck_minutes=5
```

**Access pattern in engine/ui** — `cfg:getNumber("observability", "alert_stuck_minutes", 5)` (returns 5 if not present, consistent with `getNumber` pattern at l.151–158 of config.lua).

---

### `tests/run.lua` — new Phase 22 test cases

**Analog:** Same file — Phase 21 block (l.2719–3252). Three structural patterns to replicate:

**1. Test block section header pattern** (l.2719–2721):
```lua
-- =========================================================================
-- Phase 22: stuck_since_ms tests
-- =========================================================================
```

**2. Minimal engine state harness** (Phase 21 template, l.2736–2770):
```lua
local cfg = makeCfg({
  minecolonies = { pending_states_allow = "requested", completed_states_deny = "done" },
  delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "0" },
  scheduler_budget = { enabled = "true", requests_per_tick = "10" },
  observability = { alert_stuck_minutes = "1" },  -- short threshold for tests
})

local state = {
  cfg = cfg,
  cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
  logger = { warn = function() end, info = function() end, error = function() end },
  devices = {
    meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(f) return { name = f.name, amount = 5, isCraftable = false } end,
      exportItemToPeripheral = function(f, _) return f.count, nil end,
    },
    colonyIntegrator = {
      getRequests = function()
        return {
          { id = 1001, state = "requested", target = "x", count = 1,
            items = { { name = "minecraft:stone", count = 1 } } },
        }
      end,
      getColonyName = function() return "t" end,
      amountOfCitizens = function() return 0 end,
      maxOfCitizens = function() return 0 end,
      getHappiness = function() return 0 end,
      isUnderAttack = function() return false end,
      amountOfConstructionSites = function() return 0 end,
    },
  },
  requests = {},
  stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
}
```

**3. Pre-seed work and assert pattern** (l.2775–2788):
```lua
-- Pre-seed work with stuck state already set
engine.work["1001"] = {
  status = "blocked_by_tier",
  err = "blocked_by_tier",
  next_retry = Util.nowUtcMs() + 60000,  -- not eligible for retry
  stuck_since_ms = Util.nowUtcMs() - 120000,  -- 2 minutes ago
}

engine:tick()
peripheral = oldPeripheral

-- Assertion style:
assertEq(type(engine.work["1001"].stuck_since_ms), "number",
  "stuck_since_ms deve ser number")
assertEq(engine.work["1001"].stuck_since_ms ~= nil, true,
  "stuck_since_ms deve ser preservado durante retry")
```

**4. Test cases to implement** (D-01, D-02, D-03):

| Test name (suggested) | What it verifies |
|-----------------------|-----------------|
| `engine_blocked_by_tier_sets_stuck_since_ms` | First entry to `blocked_by_tier` sets `stuck_since_ms` to a number |
| `engine_nao_craftavel_sets_stuck_since_ms` | First entry to `waiting_retry` (nao_craftavel) sets `stuck_since_ms` |
| `engine_stuck_since_ms_preserved_on_retry` | After second tick with still-stuck status, `stuck_since_ms` is unchanged |
| `engine_stuck_since_ms_cleared_on_done` | When item becomes available (missing=0), `stuck_since_ms` is nil |
| `engine_stuck_since_ms_not_persisted` | `stuck_since_ms` must not appear in the persisted JSON payload (same pattern as `engine_retry_count_nao_persiste`) |
| `snapshot_copies_stuck_since_ms` | `Snapshot.build` copies `stuck_since_ms` from work to snapshot.work |

---

## Shared Patterns

### Color override pattern
**Source:** `components/ui.lua` l.509–534 (fg assigned per condition, overrides earlier value)
**Apply to:** `renderRequests` render loop only
```lua
local fg = colors.white
-- ... existing done/substitution color logic ...
-- PHASE 22: stuck alert overrides fg at the end (highest priority)
if stuck and elapsed >= alertMins then
  fg = (jobState == "blocked_by_tier") and colors.red or colors.yellow
end
```

### Nil-safe field access pattern
**Source:** `components/ui.lua` l.451, 465, 541
**Apply to:** All new stuck_since_ms reads in UI
```lua
local stuckSince = job and job.stuck_since_ms or nil
```

### In-memory-only field contract (no persistence)
**Source:** `modules/engine.lua` l.63–92 (`_persistWorkMaybe`) — `retry_count` intentionally omitted
**Apply to:** `stuck_since_ms` — same omission from the `jobs[id]` table in `_persistWorkMaybe`

### makeCfg with observability section
**Source:** `tests/run.lua` l.53–99 (`makeCfg` helper)
**Apply to:** All new Phase 22 tests that need `alert_stuck_minutes`
```lua
local cfg = makeCfg({
  -- ... existing sections ...
  observability = { alert_stuck_minutes = "1" },
})
```

### assertEq pattern
**Source:** `tests/run.lua` l.1–5
```lua
assertEq(engine.work["id"].stuck_since_ms ~= nil, true, "stuck_since_ms deve existir")
assertEq(engine.work["id"].stuck_since_ms, nil, "stuck_since_ms deve ser nil apos done")
```

---

## No Analog Found

All files have direct self-analogs (the patterns to follow already exist in each file being modified). No files require falling back to RESEARCH.md.

---

## Metadata

**Analog search scope:** `components/`, `modules/`, `lib/`, `tests/`
**Files scanned:** 5 (ui.lua, engine.lua, snapshot.lua, config.lua, tests/run.lua)
**Pattern extraction date:** 2026-04-28
