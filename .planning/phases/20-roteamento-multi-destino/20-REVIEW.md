---
phase: 20-roteamento-multi-destino
reviewed: 2026-04-26T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/config.lua
  - modules/engine.lua
  - modules/config_cli.lua
  - tests/run.lua
findings:
  critical: 3
  warning: 6
  info: 3
  total: 12
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-04-26
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

This phase adds multi-destination routing (`[delivery_routing]`) for item delivery: items are routed to class-specific peripherals (helmet → rack_tools_0, etc.) with fallback to `default_target_container`. The implementation touches `lib/config.lua` (new INI section), `modules/engine.lua` (two new functions `guessClass` and `resolveRoutedTarget` plus per-request routing in `tick()`), `modules/config_cli.lua` (new menu), and `tests/run.lua` (four new routing tests plus a new engine health test).

**Critical problems found:** the `available` inventory map is shared across all requests in a single tick but is only seeded from `defaultSnap` — routed requests that land on a different destination read a snapshot from a different inventory but decrement the same shared map, producing incorrect over- or under-allocation. There is also a false negative in `guessClass` (`tool_axe` matches before `tool_pickaxe` for any item whose name contains both substrings), and the routing tests never call the real engine functions — they use locally-duplicated stubs — so the production code path goes completely untested.

---

## Critical Issues

### CR-01: `available` map is seeded only from `defaultSnap`; routed-destination requests read from a different inventory but consume from the same map

**File:** `modules/engine.lua:1213-1217`

**Issue:** In `Engine:tick()`, `available` is built exclusively from `defaultSnap`:

```lua
local available = {}
if type(defaultSnap) == "table" then
    for k, v in pairs(defaultSnap) do available[k] = tonumber(v or 0) or 0 end
end
```

All requests share this same `available` table via `baseCtx`. When a request is routed to a different peripheral (`routedName ~= defaultTargetName`), the engine takes a fresh snapshot of _that_ peripheral's inventory (`routedSnap`) and uses it to check whether items are present, but it still decrements and reads from `available`, which reflects the _default_ inventory. This means:

1. Items present in the routed inventory but absent in the default are treated as missing (triggering unnecessary craft/export).
2. Items present in the default are allocated to a request that will actually deliver to a different container, depleting the shared budget for other requests that genuinely target the default.

The spec (D-04/D-05) requires per-destination available maps or, at minimum, separate maps for each distinct `routedName`.

**Fix:** Maintain a per-destination `available` map keyed by target name:

```lua
local availableByTarget = {}
-- seed default
availableByTarget[defaultTargetName] = {}
if type(defaultSnap) == "table" then
    for k, v in pairs(defaultSnap) do
        availableByTarget[defaultTargetName][k] = tonumber(v or 0) or 0
    end
end

-- in the per-request loop, after resolving routedName/routedSnap:
if not availableByTarget[routedName] then
    availableByTarget[routedName] = {}
    if type(routedSnap) == "table" then
        for k, v in pairs(routedSnap) do
            availableByTarget[routedName][k] = tonumber(v or 0) or 0
        end
    end
end

local ctx = {
    available  = availableByTarget[routedName],
    ...
}
```

---

### CR-02: `guessClass` returns `tool_axe` for any item containing "axe", including "pickaxe"

**File:** `modules/engine.lua:124-126`

**Issue:** The check order is:

```lua
if n:find("pickaxe", 1, true) then return "tool_pickaxe" end
if n:find("shovel",  1, true) then return "tool_shovel"  end
if n:find("axe",     1, true) then return "tool_axe"     end
```

This specific order is correct — `"pickaxe"` is checked before `"axe"`. However, the `tool_axe` branch will also match any item whose name contains "axe" after "pickaxe" has already been checked (e.g. custom mod items named `mod:battleaxe_pickaxe`). More critically, the same issue exists for `tool_bow`:

```lua
if n:find("bow",     1, true) then return "tool_bow"     end
```

Any item whose name contains "bow" — including `"elbow"`, `"rainbow"`, `"elbow_pad"` — is classified as `tool_bow`. This silently misroutes such items to the bow-specific destination. The real-world risk is any mod item with "bow" as a substring (e.g. `supplementaries:merchant_elbow`).

**Fix:** Use word-boundary anchors or exact suffix matching rather than plain substring search. At minimum, check that "bow" is not just a substring of a longer word by requiring it to appear at a word boundary, for example:

```lua
if n:find("%fbow") or n:match("_bow$") or n:match("^bow_") or n == "bow" then
    return "tool_bow"
end
```

Or use explicit mod-namespace matching against known tool/weapon patterns rather than raw substring search.

---

### CR-03: Routing tests duplicate the production logic into local stubs; the actual `resolveRoutedTarget` in `engine.lua` is never exercised

**File:** `tests/run.lua:2729-2856`

**Issue:** All four routing tests (`routing_classe_mapeada_e_online`, `routing_classe_mapeada_e_offline`, `routing_classe_nao_mapeada`, `routing_item_sem_classe`) define their own local `guessClassStub` and `resolveRoutedTargetStub` functions that replicate the production logic. They never call `Engine` or access the real `resolveRoutedTarget`. This means:

- A bug introduced in the real `guessClass` or `resolveRoutedTarget` functions (e.g. the `tool_bow` substring issue in CR-02) will NOT be caught by any test.
- The stubs diverge from production; e.g. the stubs for `routing_classe_mapeada_e_online` / `routing_classe_mapeada_e_offline` only handle `armor_helmet`, while the production `guessClass` handles 11 classes. Any regression in the other 10 classes goes undetected.

**Fix:** Test the production function directly. Since `resolveRoutedTarget` is module-local, expose it via `Engine._test` (mirroring the existing `_test = { buildPeripheralHealth = buildPeripheralHealth }` pattern), then call it from the tests:

```lua
-- in engine.lua return block:
return {
    new   = Engine.new,
    _test = {
        buildPeripheralHealth = buildPeripheralHealth,
        resolveRoutedTarget   = resolveRoutedTarget,
        guessClass            = guessClass,
    },
}

-- in tests/run.lua:
local t = require("modules.engine")._test
-- set up peripheral stub, cfg stub, then:
local name, inv = t.resolveRoutedTarget(cfg, "minecraft:iron_helmet")
assertEq(name, "rack_tools_0")
```

---

## Warnings

### WR-01: `_handleExport` post-delivery validation is `afterCount < beforeCount`, which never fires when the delivery target is the _routed_ peripheral but `beforeSnap`/`afterSnap` are taken against `ctx.targetInv`

**File:** `modules/engine.lua:977-986`

**Issue:**

```lua
local beforeCount = Inventory.countFromSnapshot(beforeSnap, candidate.name)
local afterCount  = Inventory.countFromSnapshot(afterSnap,  candidate.name)
if afterCount < beforeCount then   -- ← only fires on decrease, never on equal
```

If an export "succeeds" (returns `exported > 0`) but the item does not actually appear in the target inventory (e.g. the ME bridge exported into a different slot that `countFromSnapshot` can't see, or the target is full after the snapshot), `afterCount == beforeCount`. The condition `afterCount < beforeCount` is false, so the engine marks the work as delivered and sets `status = "done"` even though no net increase was observed. The correct check is `afterCount <= beforeCount` (or `afterCount < beforeCount + exported`).

**Fix:**

```lua
if afterCount <= beforeCount then
    work.status   = "waiting_retry"
    work.err      = "pos_entrega_inconsistente"
    work.next_retry = nowEpoch + 5000
    ...
    return nil
end
```

---

### WR-02: `resolveTarget` falls back to a raw string `peripheral.isPresent` call after already iterating the list — can wrap the same peripheral twice

**File:** `modules/engine.lua:167-179`

**Issue:**

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

When `default_target_container` is a single value (not comma-separated), `getList` returns a one-element list containing that value, so the loop finds it and returns early. The fallback `raw` branch is dead code in that case.

However, when `default_target_container` contains a comma-separated list (e.g. `minecolonies:rack_0,entangled:tile_0` as in the default INI), and **none** of those are online, the fallback calls `cfg:get(...)` which returns the entire raw string `"minecolonies:rack_0,entangled:tile_0"` — a value that is never a valid peripheral name. `peripheral.isPresent("minecolonies:rack_0,entangled:tile_0")` will return false, so the fallback silently does nothing wrong. But the intent of the fallback is unclear and the code path is dead in the success case. This should be removed to avoid confusion.

**Fix:** Remove the fallback block (lines 174–178). If the list iteration returns nothing, return `nil, nil` directly.

---

### WR-03: `buildChangedOnly` in `config_cli.lua` does not include `delivery_routing` when no other sections have changes, but the guard that prevents saving is `and`-chained with `nil` checks only for the five sections it knows about

**File:** `modules/config_cli.lua:450`

**Issue:**

```lua
if changedOnly.peripherals == nil and changedOnly.core == nil
   and changedOnly.delivery == nil and changedOnly.update == nil
   and changedOnly.delivery_routing == nil then
    showLines("Salvar", { "Nenhuma mudanca para salvar." })
    return false
end
```

This is correct but `buildChangedOnly` initialises `out` with five sections and sets each to `nil` when empty. If a future section is added to `buildEffective` but not to `buildChangedOnly`'s guard list, changes will be silently dropped. More concretely, the `buildChangedOnly` function silently discards any section in `updates` that is not one of the five it knows about — if a caller adds a new section to `updates`, it will be silently ignored.

**Fix:** Iterate dynamically rather than enumerating section names:

```lua
local function buildChangedOnly(cfg, updates)
    local out = {}
    for section, kv in pairs(updates) do
        for k, newVal in pairs(kv) do
            local cur = cfg:get(section, k, "")
            if tostring(newVal) ~= tostring(cur) then
                out[section] = out[section] or {}
                out[section][k] = newVal
            end
        end
    end
    return out
end
-- save guard:
if next(changedOnly) == nil then ... end
```

---

### WR-04: `runDeliveryRoutingMenu` does not validate peripheral name before saving; user can write any string as a routed target

**File:** `modules/config_cli.lua:793-797`

**Issue:**

```lua
local v = prompt(fieldLabel("delivery_routing", key), trim(eff2[key] or ""))
if v ~= nil then
    updates.delivery_routing[key] = trim(v)
end
```

Unlike `runPeripheralsMenu`, which calls `choosePeripheralValue` → `isPresentAndWrap` to verify the peripheral exists before accepting it, the routing menu accepts any free-text string without checking. A typo in a peripheral name is stored and causes silent routing failures at runtime (the `peripheral.isPresent` check in `resolveRoutedTarget` returns false, so the system silently falls back to default with no warning at save time).

**Fix:** After trimming, if the value is non-empty, call `isPresentAndWrap(v)` and warn (but do not block) if it fails — or offer the same `choosePeripheralValue` picker used for the other peripheral fields.

---

### WR-05: `buildPeripheralHealth` counts `default_target_container` as a single string name; if it is a comma-separated list, only the full raw string is checked with `peripheral.isPresent`

**File:** `modules/engine.lua:659-661`

**Issue:**

```lua
local defaultName = trim(cfg:get("delivery", "default_target_container", ""))
if defaultName ~= "" then
    targetsTotal = targetsTotal + 1
    if peripheral.isPresent(defaultName) then targetsOnline = targetsOnline + 1 end
end
```

`cfg:get` returns the raw string `"minecolonies:rack_0,entangled:tile_0"` for the default INI. `peripheral.isPresent("minecolonies:rack_0,entangled:tile_0")` returns false (no peripheral has a comma in its name), so the UI always shows `0/1 online` for the Targets entry even when both peripherals are online. The health display is misleading.

**Fix:** Use `cfg:getList` to iterate all default targets:

```lua
local defaultNames = cfg:getList("delivery", "default_target_container", {})
for _, dn in ipairs(defaultNames) do
    dn = trim(dn)
    if dn ~= "" then
        targetsTotal = targetsTotal + 1
        if peripheral.isPresent(dn) then targetsOnline = targetsOnline + 1 end
    end
end
```

---

### WR-06: `engine_health_snapshot_me_online_offline` test asserts `snap[4].label == "Target"` but the production label is `"Targets"` (plural)

**File:** `tests/run.lua:2039`

**Issue:**

```lua
assertEq(snap[4].label, "Target")   -- line 2039
```

But `buildPeripheralHealth` at line 685 returns `{ label = "Targets", ... }`. This test will always fail in CI as written, masking all genuine regressions in the Targets field.

**Fix:**

```lua
assertEq(snap[4].label, "Targets")
```

---

## Info

### IN-01: `getList` uses a raw string delimiter in a `gmatch` character class, making special pattern characters unsafe

**File:** `lib/config.lua:186`

**Issue:**

```lua
for part in s:gmatch("[^" .. delimiter .. "]+") do
```

If `delimiter` ever contains a Lua pattern special character (e.g. `.`, `%`, `^`, `]`), the pattern is silently malformed. In practice the only callers use `","`, so this is low-risk today. The same copy of this logic appears in `tests/run.lua:86-90`.

**Fix:** Escape the delimiter character before embedding it:

```lua
local esc = delimiter:gsub("([%.%^%$%(%)%[%]%*%+%-%?%%])", "%%%1")
for part in s:gmatch("[^" .. esc .. "]+") do
```

---

### IN-02: Routing stubs in tests are duplicated verbatim across four test cases (approx. 15 lines each × 4)

**File:** `tests/run.lua:2730-2856`

**Issue:** Each of the four routing tests defines identical `guessClassStub`, `resolveTargetStub`, and `resolveRoutedTargetStub` local functions. This is 60+ lines of duplication that will silently diverge from production and from each other. (This is also the mechanism behind CR-03 above.)

**Fix:** Hoist the stubs into a shared local function at the top of the `tests` table, or — better — expose the real functions via `Engine._test` as described in CR-03.

---

### IN-03: `[delivery_routing]` keys in `DEFAULT_INI` have empty values; `Config:get` returns the `default` parameter when the value is `""`, so callers that pass `""` as default never know whether the user explicitly cleared a key vs. it being absent

**File:** `lib/config.lua:159`

**Issue:**

```lua
local v = s[key]
if v == nil or v == "" then return default end
```

This is intentional design (empty string = no value), but it means there is no way for callers to distinguish "user set this key to empty" from "key was never written". In the routing use case this is fine (empty = route to default), but the same `Config:get` is used for `default_target_container`; if a user explicitly writes `default_target_container=` they get the hardcoded default `"minecolonies:rack_0,entangled:tile_0"` returned instead of treating the field as cleared. This is a design limitation worth noting as tech debt.

**Fix (if desired):** Provide a `Config:getRaw` that returns empty string as-is, used when explicit empty is meaningful.

---

_Reviewed: 2026-04-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
