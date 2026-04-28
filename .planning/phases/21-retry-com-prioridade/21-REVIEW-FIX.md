---
phase: 21-retry-com-prioridade
fixed_at: 2026-04-28T21:57:19Z
review_path: .planning/phases/21-retry-com-prioridade/21-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 21: Code Review Fix Report

**Fixed at:** 2026-04-28T21:57:19Z
**Source review:** .planning/phases/21-retry-com-prioridade/21-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

## Fixes Applied

### CR-01: `retry_count` increment overwrites `work` table built later in `_processRequest`

**Status:** fixed
**Files modified:** `modules/engine.lua`
**Commit:** 4b5b43d
**Applied fix:** Removed the separate `work_rc` local variable and the duplicate `local work = self.work[r.id] or {}` at line 984. The `retry_count` increment is now done directly on the single `work` table that is used throughout the entire function, eliminating the split-reference hazard. The uncommitted change was already correct in the working tree; it was verified and committed.

---

### CR-02: Pre-pass requests are double-processed by the round-robin loop in the same tick

**Status:** fixed
**Files modified:** `modules/engine.lua`
**Commit:** 4a6b976
**Applied fix:** Added `local prePassProcessed = {}` before the pre-pass collection loop. When `did == true` in the pre-pass loop, the request ID is recorded: `prePassProcessed[tostring(r.id)] = true`. In the normal round-robin while loop, an early-skip check wraps the entire `_processRequest` call body: `if not (r and r.id and prePassProcessed[tostring(r.id)]) then ... end`. This prevents any request already handled by the pre-pass from being processed again in the same tick. The `goto` approach was replaced with a negated `if` block to avoid jumping over local variable declarations (Lua restriction).

---

### WR-01: Sort comparator not a strict weak ordering when both `started_at` are `math.huge`

**Status:** fixed
**Files modified:** `modules/engine.lua`
**Commit:** 68ba76d
**Applied fix:** Changed the eligible-request collection loop to store `{r = r, pos = posCounter}` structs with `posCounter` incremented for every request in the ipairs loop. The sort comparator was updated to read `a.r.id` / `b.r.id` for work lookups, compare `ta ~= tb` first, and fall back to `a.pos < b.pos` for stable tiebreaking. The pre-pass iteration was updated to `for _, entry in ipairs(retryEligible) do local r = entry.r` so the rest of the loop body is unchanged.

---

### WR-02: Badge `[R:N]` not included in measurement loop — `jobMax` underestimates column width

**Status:** fixed
**Files modified:** `components/ui.lua`
**Commit:** 72715e2
**Applied fix:** In the measurement loop (around line 463), after `local etapa = jobSymbol(jobState)`, added:
```lua
local retryCountM = job and tonumber(job.retry_count or 0) or 0
if retryCountM >= 1 then
  etapa = etapa .. "[R:" .. tostring(retryCountM) .. "]"
end
```
The existing `if #etapa > jobMax then jobMax = #etapa end` line then accounts for the badge width, mirroring the render loop logic exactly.

---

### WR-03: Test `engine_prepass_nao_altera_cursor` only verifies cursor is a number, not its value

**Status:** fixed
**Files modified:** `tests/run.lua`
**Commit:** 6fbb4c3
**Applied fix:** Added a stronger assertion after the existing assertions in `engine_prepass_nao_altera_cursor`:
```lua
assertEq(type(engine.work["906"]), "table", "id=906 at cursor position 2 should be processed by normal round-robin loop")
```
id=906 is at position 2 in the requests array, which is where `_rq_cursor` was set before the tick. If the pre-pass reset the cursor to 1, the round-robin loop would start from position 1 (id=905, which was already processed by pre-pass and now skipped via CR-02 fix), potentially leaving id=906 unprocessed depending on budget. This assertion proves the loop started from position 2 as expected.

---

### WR-04: Test `engine_prepass_budget_compartilhado_com_loop_normal` uses `nil or retry_count==0` — masks bugs

**Status:** fixed
**Files modified:** `tests/run.lua`
**Commit:** 6fbb4c3
**Applied fix:** Replaced the two weak `w911 == nil or (w911.retry_count or 0) == 0` assertions with strict nil checks:
```lua
assertEq(engine.work["911"], nil, "id=911 should not be in work when budget exhausted by pre-pass")
assertEq(engine.work["912"], nil, "id=912 should not be in work when budget exhausted by pre-pass")
```
The intermediate locals `w911` and `w912` are no longer needed and were removed. These strict assertions now fail if the normal loop ran (processing 911 or 912 would create a work entry), regardless of whether `retry_count` was written.

---

## Verification

**Tier 1 (re-read):** All modified file sections were re-read after each edit to confirm fix text was present and surrounding code was intact.

**Tier 2 (syntax check):** `lua` is not available in the CI environment (this is a CC:Tweaked Minecraft mod; Lua runs in-game, not in the host shell). Syntax verification was performed by careful manual inspection of each change:
- `modules/engine.lua`: No `goto` was used in the final implementation (replaced with negated `if` block); all `local` variable scopes are correct; the `{r = r, pos = posCounter}` struct change is consistent throughout the pre-pass section.
- `components/ui.lua`: The added block follows the identical pattern of the render loop (lines 535–539); no variable shadowing introduced.
- `tests/run.lua`: Assertions follow the existing `assertEq` call signature used throughout the file.

**Test suite:** `lua tests/run.lua` could not be run — Lua interpreter not found on host. Test verification must be performed in-game or via a CC:Tweaked emulator.

---

_Fixed: 2026-04-28T21:57:19Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
