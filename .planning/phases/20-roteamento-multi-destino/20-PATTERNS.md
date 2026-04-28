# Phase 20: Roteamento Multi-Destino - Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** 4
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/engine.lua` | service (routing logic) | request-response | `modules/engine.lua` itself — `resolveTarget()` (line 167), `getDestinationSnapshot()` (line 217) | exact (self-extension) |
| `lib/config.lua` | config | CRUD | `lib/config.lua` itself — `DEFAULT_INI` block (lines 6-79) | exact (self-extension) |
| `modules/config_cli.lua` | UI / menu | request-response | `modules/config_cli.lua` itself — `runDeliveryMenu()` (lines 686-730), `main()` (lines 778-820) | exact (self-extension) |
| `tests/run.lua` | test | batch | `tests/run.lua` itself — `runTest()` harness (lines 34-48), `makeCfg()` stub (lines 53-95) | exact (self-extension) |

---

## Pattern Assignments

### `modules/engine.lua` — add routing logic + health update (D-01 to D-05, D-07)

**Analog:** `modules/engine.lua`

**Existing `guessClass()` — do not modify, call directly** (lines 116-131):
```lua
local function guessClass(name)
  if not name then return nil end
  local n = name:lower()
  if n:find("helmet", 1, true) then return "armor_helmet" end
  if n:find("chestplate", 1, true) or n:find("jetpack", 1, true) then return "armor_chestplate" end
  if n:find("leggings", 1, true) then return "armor_leggings" end
  if n:find("boots", 1, true) then return "armor_boots" end
  if n:find("pickaxe", 1, true) then return "tool_pickaxe" end
  if n:find("shovel", 1, true) then return "tool_shovel" end
  if n:find("axe", 1, true) then return "tool_axe" end
  if n:find("hoe", 1, true) then return "tool_hoe" end
  if n:find("sword", 1, true) then return "tool_sword" end
  if n:find("bow", 1, true) then return "tool_bow" end
  if n:find("shield", 1, true) then return "tool_shield" end
  return nil
end
```

**Existing `resolveTarget()` — call as fallback** (lines 167-179):
```lua
local function resolveTarget(cfg)
  local targets = cfg:getList("delivery", "default_target_container", {})
  for _, name in ipairs(targets) do
    if name ~= "" and peripheral.isPresent(name) then
      return name, peripheral.wrap(name)
    end
  end
  local raw = cfg:get("delivery", "default_target_container", "")
  if raw ~= "" and peripheral.isPresent(raw) then
    return raw, peripheral.wrap(raw)
  end
  return nil, nil
end
```

**New function to add — `resolveRoutedTarget(cfg, itemName)`:**
Copy the structure of `resolveTarget` (lines 167-179). New function reads the class via `guessClass(itemName)`, then looks up `cfg:get("delivery_routing", class, "")`. If non-empty and `peripheral.isPresent()` returns true, return that name and wrap. Otherwise fall through to `resolveTarget(cfg)`.

Pattern to copy:
```lua
-- Inline after resolveTarget() definition (around line 180)
local function resolveRoutedTarget(cfg, itemName)
  local class = guessClass(itemName)
  if class then
    local routedName = cfg:get("delivery_routing", class, "")
    if routedName ~= "" and peripheral.isPresent(routedName) then
      return routedName, peripheral.wrap(routedName)
    end
  end
  return resolveTarget(cfg)      -- fallback: D-01, D-02, D-03
end
```

**Existing `getDestinationSnapshot()` — no changes needed** (lines 217-227):
```lua
local function getDestinationSnapshot(state, targetName, targetInv, forceRefresh)
  local ttl = state.cfg:getNumber("delivery", "destination_cache_ttl_seconds", 2)
  if not forceRefresh then
    local cached = state.cache:get("dest", targetName)
    if cached then return cached, nil end
  end
  local snap, err = Inventory.snapshot(targetInv, state)
  if not snap then return nil, err end
  state.cache:set("dest", targetName, snap, ttl)
  return snap, nil
end
```
The `targetName` key already parameterises the cache per destination — each routed name gets its own TTL entry automatically (D-04, D-05).

**Tick loop insertion point — replace `resolveTarget` call** (line 1158):

Current code:
```lua
-- line 1158
local targetName, targetInv = resolveTarget(state.cfg)
if not targetInv then
  self:_markAllWaitingRetry(requests, "destino_indisponivel")
  ...
end
local snap, snapErr = getDestinationSnapshot(state, targetName, targetInv, false)
```

The call at line 1158 resolves ONE shared target for the whole tick. For per-request routing the resolution must move **inside** `_processRequest`. The planner must:
1. Keep line 1158 as the default-target resolution for requests whose item class has no routing.
2. Or move the resolution into `_processRequest` using `resolveRoutedTarget(state.cfg, candidate.name)` after `candidate` is known (after line 1021), replacing `ctx.targetName` / `ctx.targetInv` / `ctx.snap` / `ctx.available` per-request.

The ctx construction pattern to copy (lines 1192-1201):
```lua
local ctx = {
  available  = available,
  buildings  = buildings,
  citizens   = citizens,
  snap       = snap,
  snapErr    = snapErr,
  targetName = targetName,
  targetInv  = targetInv,
  nowEpoch   = os.epoch("utc"),
}
```

**Health block — `buildPeripheralHealth()` target entry** (lines 637-663):

Current pattern (target = single entry):
```lua
local targetValue, targetLevel = "NA", "unknown"
if cfg and type(cfg.getList) == "function" and ... then
  local _, targetInv = resolveTarget(cfg)
  if targetInv then
    targetValue, targetLevel = "Online", "ok"
  else
    targetValue, targetLevel = "Offline", "bad"
  end
end
...
return {
  ...
  { label = "Target", value = targetValue, level = targetLevel },
}
```

D-07 replaces the single `Target` entry with `Targets: X/Y online`. Pattern: count `default_target_container` plus all non-empty `delivery_routing` keys; iterate with `peripheral.isPresent(name)` same as the existing target check.

Config read pattern to follow:
```lua
-- read delivery_routing keys:
local ROUTING_CLASSES = {
  "armor_helmet","armor_chestplate","armor_leggings","armor_boots",
  "tool_pickaxe","tool_shovel","tool_axe","tool_hoe","tool_sword","tool_bow","tool_shield"
}
local total, online = 0, 0
-- count default
local defaultName = cfg:get("delivery", "default_target_container", "")
if defaultName ~= "" then
  total = total + 1
  if peripheral.isPresent(defaultName) then online = online + 1 end
end
-- count routed
for _, cls in ipairs(ROUTING_CLASSES) do
  local n = cfg:get("delivery_routing", cls, "")
  if n ~= "" then
    total = total + 1
    if peripheral.isPresent(n) then online = online + 1 end
  end
end
-- produce label
local targetsValue = online .. "/" .. total .. " online"
```

---

### `lib/config.lua` — add `[delivery_routing]` section defaults (D-01, D-02)

**Analog:** `lib/config.lua`

**Existing `DEFAULT_INI` block pattern** (lines 6-79):
The entire default config is one Lua heredoc string. Each section is `[name]\nkey=value\n`. New section with 11 empty keys goes at the end of the string, before the closing `]]`.

Pattern to copy — end of `DEFAULT_INI` (lines 68-79):
```lua
[observability]
enabled=false
ui_enabled=false
debug_log_enabled=false
debug_log_interval_seconds=30

[scheduler_budget]
...
]]
```

New section to append immediately after `[scheduler_budget]` block and before `]]`:
```lua

[delivery_routing]
armor_helmet=
armor_chestplate=
armor_leggings=
armor_boots=
tool_pickaxe=
tool_shovel=
tool_axe=
tool_hoe=
tool_sword=
tool_bow=
tool_shield=
```

All values are empty string (meaning "use default"). `cfg:get("delivery_routing", cls, "")` returns `""` which triggers fallback (D-02). No new Config API methods are needed — `cfg:get()` (line 142) handles missing keys with the `default` parameter.

---

### `modules/config_cli.lua` — add `delivery_routing` menu (D-06)

**Analog:** `modules/config_cli.lua`

**`FIELD_LABELS` pattern** (lines 21-50):
```lua
local FIELD_LABELS = {
  delivery = {
    default_target_container = "Destino padrao (inventario)",
    ...
  },
  ...
}
```
Add parallel entry:
```lua
  delivery_routing = {
    armor_helmet      = "Helmet",
    armor_chestplate  = "Chestplate",
    armor_leggings    = "Leggings",
    armor_boots       = "Boots",
    tool_pickaxe      = "Pickaxe",
    tool_shovel       = "Shovel",
    tool_axe          = "Axe",
    tool_hoe          = "Hoe",
    tool_sword        = "Sword",
    tool_bow          = "Bow",
    tool_shield       = "Shield",
  },
```

**`buildEffective()` pattern** (lines 335-373):
```lua
delivery = {
  default_target_container = v("delivery", "default_target_container"),
  ...
},
```
Add sibling key:
```lua
delivery_routing = {
  armor_helmet     = v("delivery_routing", "armor_helmet"),
  armor_chestplate = v("delivery_routing", "armor_chestplate"),
  armor_leggings   = v("delivery_routing", "armor_leggings"),
  armor_boots      = v("delivery_routing", "armor_boots"),
  tool_pickaxe     = v("delivery_routing", "tool_pickaxe"),
  tool_shovel      = v("delivery_routing", "tool_shovel"),
  tool_axe         = v("delivery_routing", "tool_axe"),
  tool_hoe         = v("delivery_routing", "tool_hoe"),
  tool_sword       = v("delivery_routing", "tool_sword"),
  tool_bow         = v("delivery_routing", "tool_bow"),
  tool_shield      = v("delivery_routing", "tool_shield"),
},
```

**`buildChangedOnly()` pattern** (lines 375-390):
```lua
local out = { peripherals = {}, core = {}, delivery = {}, update = {} }
```
Add `delivery_routing = {}` to this table and add corresponding nil-check + nil-clear for the new section.

**`saveIni()` changed-only nil check pattern** (lines 413-441):
```lua
if changedOnly.peripherals == nil and changedOnly.core == nil and changedOnly.delivery == nil and changedOnly.update == nil then
```
Extend condition to include `and changedOnly.delivery_routing == nil`.

**`runDeliveryMenu()` full pattern** (lines 686-730) — copy as template for `runDeliveryRoutingMenu()`:

The pattern is:
1. `while true do`
2. `local eff = buildEffective(cfg, updates).delivery` — use `.delivery_routing` for new menu
3. Build `labels` table with `{ text = ..., suffix = "(" .. trim(eff.<key>) .. ")", suffixColor = separatorColor() }` per field
4. Separator + Salvar + Voltar entries
5. `selectList(title, subtitle, labels, 1)`
6. `if chosen.action == "back" then return end`
7. `if chosen.action == "save" then saveIni(...) end`
8. `else` branch: `if idx == N then local v = prompt(...); if v ~= nil then updates.delivery_routing.<key> = trim(v) end end`

Key difference from delivery menu: user can enter empty string to clear mapping. Use `prompt()` but allow clearing — when user enters empty string explicitly (not just pressing Enter), set value to `""`.

**`main()` pattern** (lines 778-820):
```lua
local updates = {
  peripherals = {},
  core = {},
  delivery = {},
  update = {},
}
```
Add `delivery_routing = {}`.

Top-level menu labels (line 790-795):
```lua
local labels = {
  "Perifericos",
  "Core+Logs",
  "Delivery",
  "Update-check",
  "Sair",
}
```
Add `"Roteamento de destino"` entry before `"Sair"`. Add corresponding `elseif` branch calling `runDeliveryRoutingMenu(cfg, updates)`.

---

### `tests/run.lua` — add routing tests (D-08)

**Analog:** `tests/run.lua`

**Test harness pattern** (lines 34-48):
```lua
local function runTest(name, fn)
  local ok, resOrErr = pcall(fn)
  if ok then
    if resOrErr == "SKIP" then
      logLine("[SKIP] " .. name)
      return true
    end
    logLine("[OK] " .. name)
    return true
  end
  local msg = "[FAIL] " .. name .. " -> " .. tostring(resOrErr)
  logLine(msg)
  table.insert(failures, msg)
  return false
end
```

**`makeCfg()` stub pattern** (lines 53-95):
```lua
local function makeCfg(values)
  local cfg = {}
  function cfg:get(section, key, default)
    local s = values[section]
    if not s then return default end
    local v = s[key]
    if v == nil or v == "" then return default end
    return v
  end
  function cfg:getList(section, key, default, sep) ... end
  return cfg
end
```
The four routing tests (D-08) all use inline `makeCfg` + inline `peripheral` stub. Pattern is identical to existing peripheral tests (lines 515-553): save old `peripheral`, replace with fake table, restore after.

**Test entry format** (line 97 onward):
```lua
local tests = {
  { "test_name_here", function()
    -- arrange
    local cfg = makeCfg({ delivery = { default_target_container = "rack_0" }, delivery_routing = { armor_helmet = "rack_tools_0" } })
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "rack_tools_0" or name == "rack_0" end,
      wrap = function(name) return { fake = true } end,
    }
    -- act
    -- (inline resolveRoutedTarget logic or require engine and expose function)
    -- assert
    assertEq(...)
    peripheral = oldPeripheral
  end },
```

**Four tests to add (D-08):**

| Test name | Setup | Expected |
|---|---|---|
| `routing_classe_mapeada_e_online` | `delivery_routing.armor_helmet = "rack_tools_0"`, peripheral online | returns `"rack_tools_0"` |
| `routing_classe_mapeada_e_offline` | `delivery_routing.armor_helmet = "rack_tools_0"`, peripheral offline, `default_target_container = "rack_0"` online | returns `"rack_0"` (fallback) |
| `routing_classe_nao_mapeada` | `delivery_routing.armor_helmet = ""`, `default_target_container = "rack_0"` online | returns `"rack_0"` |
| `routing_item_sem_classe` | item name `"minecraft:bread"` (guessClass returns nil), `default_target_container = "rack_0"` online | returns `"rack_0"` |

Note: because `resolveRoutedTarget` is a `local function` in engine.lua, tests cannot require it directly. Two options (planner decides):
1. Extract `resolveRoutedTarget` into a small `lib/routing.lua` module — testable independently.
2. Test it indirectly via a thin test stub that reimplements the same 6-line logic inline.

The existing test file uses the inline-stub approach for complex functions (see `makeCfg` reimplementing Config API) — copying that pattern avoids a new module.

---

## Shared Patterns

### Config read — single value
**Source:** `lib/config.lua:142-148`
**Apply to:** `resolveRoutedTarget()`, `runDeliveryRoutingMenu()`, health counter
```lua
function Config:get(section, key, default)
  local s = self.data[section]
  if not s then return default end
  local v = s[key]
  if v == nil or v == "" then return default end
  return v
end
```
`cfg:get("delivery_routing", class, "")` — empty string is the sentinel for "no mapping".

### Peripheral online check
**Source:** `modules/engine.lua:167-179` (`resolveTarget`) and health block `lines 638-650`
**Apply to:** `resolveRoutedTarget()`, health counter
```lua
if name ~= "" and peripheral.isPresent(name) then
  return name, peripheral.wrap(name)
end
```

### selectList + suffix display of current value
**Source:** `modules/config_cli.lua:553-557`
**Apply to:** `runDeliveryRoutingMenu()` labels
```lua
{ text = keys[N].label, suffix = "(" .. trim(effective.<key>) .. ")", suffixColor = separatorColor() },
```
Empty suffix displays as `()` which signals "usa default" — acceptable per D-06 spec (user sees empty = default).

### assertEq + peripheral stub in tests
**Source:** `tests/run.lua:1-5`, `515-553`
**Apply to:** all four D-08 tests
```lua
local function assertEq(a, b, msg)
  if a ~= b then
    error((msg or "assertEq falhou") .. ": esperado=" .. tostring(b) .. " obtido=" .. tostring(a), 2)
  end
end
-- peripheral stub pattern:
local oldPeripheral = peripheral
peripheral = { isPresent = function(name) return name == "rack_0" end, wrap = function(name) return {} end }
-- ... test ...
peripheral = oldPeripheral
```

---

## No Analog Found

None — all four files are self-extensions of existing modules with clear analog patterns within the same file.

---

## Metadata

**Analog search scope:** `modules/engine.lua`, `lib/config.lua`, `modules/config_cli.lua`, `tests/run.lua`
**Files scanned:** 4 (all targeted reads, no full-file loads except `lib/config.lua` which is 383 lines)
**Pattern extraction date:** 2026-04-26
