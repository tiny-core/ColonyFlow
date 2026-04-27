---
phase: 20-roteamento-multi-destino
fixed_at: 2026-04-27T00:00:00Z
fix_scope: critical_warning
findings_in_scope: 9
fixed: 8
skipped: 1
status: partial
iteration: 1
---

# Phase 20: Code Review Fix Report

**Fixed at:** 2026-04-27
**Source review:** `.planning/phases/20-roteamento-multi-destino/20-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 9 (CR-01, CR-02, CR-03, WR-01, WR-02, WR-03, WR-04, WR-05, WR-06)
- Fixed: 8
- Skipped: 1 (WR-06 — already fixed in codebase prior to this run)

---

## Fixed Issues

### CR-01: per-destination available maps in tick()

**Files modified:** `modules/engine.lua`
**Commit:** f95cd56
**Applied fix:** Replaced the shared `available` map (seeded only from `defaultSnap`) with an `availableByTarget` table keyed by target name. The default target is pre-seeded from `defaultSnap`. For each request in the tick loop, if the resolved `effectiveRoutedName` has no entry yet, a new map is seeded from `routedSnap`. The `ctx.available` field now points to the per-destination map, preventing cross-destination over-allocation (D-04/D-05 spec requirement).

---

### CR-02: word-boundary matching for tool_bow in guessClass

**Files modified:** `modules/engine.lua`
**Commit:** 52f1ddc
**Applied fix:** Replaced `n:find("bow", 1, true)` with `n:find("%fbow") or n:match("_bow$") or n:match("^bow_") or n == "bow"` using Lua frontier pattern and suffix/prefix anchors. Items whose names contain "bow" as a substring of a longer word (e.g. `elbow`, `rainbow`) are no longer misrouted to the bow-specific destination.

---

### CR-03: expose resolveRoutedTarget/guessClass via Engine._test and use in routing tests

**Files modified:** `modules/engine.lua`, `tests/run.lua`
**Commit:** 01c02a2
**Applied fix:** Added `resolveRoutedTarget` and `guessClass` to the `Engine._test` export block in `engine.lua`. Replaced the four routing test cases (`routing_classe_mapeada_e_online`, `routing_classe_mapeada_e_offline`, `routing_classe_nao_mapeada`, `routing_item_sem_classe`) with versions that call `require("modules.engine")._test.resolveRoutedTarget` directly, eliminating the duplicated local stubs and ensuring the production code path is exercised.

---

### WR-01: fix post-delivery check afterCount <= beforeCount

**Files modified:** `modules/engine.lua`
**Commit:** 6d2f198 — requires human verification
**Applied fix:** Changed `afterCount < beforeCount` to `afterCount <= beforeCount` in `_handleExport`. A successful export that leaves the target inventory count unchanged (e.g. slot visibility gap or full inventory after snapshot) is now correctly flagged as `waiting_retry` with `err = "pos_entrega_inconsistente"` instead of silently marking the work as done.

Note: This is a logic condition change. The semantic correctness (whether `<=` is the right threshold vs. `< beforeCount + exported`) should be confirmed by a developer reviewing the delivery flow.

---

### WR-02: remove dead fallback raw-string branch in resolveTarget

**Files modified:** `modules/engine.lua`
**Commit:** 0ec6c49
**Applied fix:** Removed the three-line fallback block that called `cfg:get("delivery", "default_target_container", "")` and passed the raw string to `peripheral.isPresent`. The fallback was dead code in the success case (single-value lists are already handled by the `getList` loop) and potentially harmful in the failure case (the raw string could be a comma-separated list, which is never a valid peripheral name). If the list iteration finds no online peripheral, the function now returns `nil, nil` directly.

---

### WR-03: dynamic buildChangedOnly and next() guard in saveIni

**Files modified:** `modules/config_cli.lua`
**Commit:** 11aadab
**Applied fix:** Simplified `buildChangedOnly` to use `local out = {}` (no pre-populated section keys) and `out[section] = out[section] or {}` inside the loop. Removed the five explicit `if next(out.X) == nil then out.X = nil end` lines. Updated the `saveIni` guard from the hardcoded five-section AND chain to `if next(changedOnly) == nil then`. New sections added to `updates` are now automatically included.

---

### WR-04: warn on unknown peripheral name in routing menu

**Files modified:** `modules/config_cli.lua`
**Commit:** b665a4e
**Applied fix:** In `runDeliveryRoutingMenu`, after trimming the user input, if the value is non-empty, calls `isPresentAndWrap(trimmed)` and shows a non-blocking `showLines("Aviso", ...)` warning if the peripheral is not found. The value is still saved (to allow temporarily offline peripherals to be pre-configured), but the user is informed of the potential typo at input time.

---

### WR-05: use getList for default_target_container in buildPeripheralHealth

**Files modified:** `modules/engine.lua`
**Commit:** d9f2206
**Applied fix:** Replaced the single `cfg:get("delivery", "default_target_container", "")` call with `cfg:getList(...)` iteration. Each individual peripheral name in the comma-separated list is now checked with `peripheral.isPresent(dn)`, fixing the misleading `0/1 online` display in the health UI when `default_target_container` contains multiple names.

---

## Skipped Issues

### WR-06: engine_health_snapshot test assertEq label "Target" vs "Targets"

**File:** `tests/run.lua:2039`
**Reason:** Already fixed in codebase prior to this run. Inspection of `tests/run.lua` line 2037 shows the assertion is `assertEq(snap[4].label, "Targets")` (plural), which matches the production `buildPeripheralHealth` label. The finding describes a past state; no change was needed.
**Original issue:** Test used `"Target"` (singular) but production code returns `"Targets"` (plural), causing the test to always fail in CI.

---

_Fixed: 2026-04-27_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
