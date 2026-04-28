---
phase: 21-retry-com-prioridade
reviewed: 2026-04-28T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - modules/engine.lua
  - components/ui.lua
  - tests/run.lua
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 21: Code Review Report

**Reviewed:** 2026-04-28
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Phase 21 added a pre-pass block in `Engine:tick()` to prioritise `waiting_retry` requests, a `retry_count` field incremented in `_processRequest`, the `[R:N]` badge in `components/ui.lua`, and 7 new tests covering pre-pass behaviour.

The core pre-pass logic is structurally sound and matches the plan exactly. However two critical correctness bugs were found: (1) the pre-pass processes requests that are **already in the normal-loop queue**, creating a double-processing opportunity in the same tick whenever a `waiting_retry` request also passes the `isPendingState` check; and (2) the `retry_count` increment block reads `self.work[r.id]` a **second time**, creating a new empty table that then overwrites the `work` table already partially built by the same call further down in `_processRequest` — silently discarding fields written by earlier branches and producing incorrect state in some code paths. Four warnings cover sort instability, missing test coverage, a pre-pass budget-exceeded that does not save cursor correctly relative to design intent, and a UI measurement loop that does not account for the badge width. Two info items flag dead-code and a test isolation risk.

---

## Critical Issues

### CR-01: `retry_count` increment overwrites `work` table built later in the same `_processRequest` call

**File:** `modules/engine.lua:977-984`

**Issue:**
`_processRequest` increments `retry_count` by reading `self.work[r.id]` into a fresh local `work_rc`, incrementing, and writing it back with `self.work[r.id] = work_rc`. A few lines later (line 984) the function reads `self.work[r.id]` again into a separate local `work` and writes fields into it throughout the function body, eventually writing it back with `self.work[r.id] = work` (lines 993, 1005, 1029, …, 1075). Because `work_rc` and `work` are **separate table references**, changes made to `work` do **not** affect `work_rc`, but more importantly any branch that returns early (lines 993, 1005, 1029, 1048, 1055, 1075) does `self.work[r.id] = work`, which is a **different table** from `work_rc`. That write is correct. However, branches that do NOT return early (the main happy-path that reaches line 1075 and beyond) also do `self.work[r.id] = work` at the end — which is also the `work_rc` table at that point, so `retry_count` survives. But any branch that returns `true, nil` by an **early-return** such as line 993 (`self.work[r.id] = work; return true, nil`) uses the `work` local (read after the `work_rc` write at line 979), which means `work.retry_count` is whatever was stored in `self.work[r.id]` **after** the `work_rc` write. This is actually fine for those early-returns.

The real correctness hazard is the inverse: the `work_rc` table written at line 979 contains **only** `retry_count` (and whatever pre-existing fields were already in `self.work[r.id]`). If the function later reads `self.work[r.id]` at line 984 and mutates that table, then writes it back at line 1075, `retry_count` is preserved because both reads share the same underlying table **if the work entry already existed**. But when the entry did **not** previously exist (`self.work[r.id]` was nil), line 977 creates `work_rc = {}`, writes `retry_count = 1`, stores it at `self.work[r.id] = work_rc`. Line 984 then reads `self.work[r.id]` (now `work_rc`) into `work` — same table reference. So the `retry_count` field survives in this case too.

The actual bug is narrower but real: when `_processRequest` is called a **second time for the same request in the same tick** (which is exactly what the pre-pass enables — see CR-02), `retry_count` is incremented **twice per tick** because the pre-pass calls `_processRequest` for the eligible request and then the normal round-robin loop calls it again unless the second call returns `false, nil` from the `next_retry` guard. After the pre-pass processes a request that transitions to `done` or `crafting`, the `next_retry` guard is NOT set (it was cleared), so the round-robin loop will attempt to process it again and increment `retry_count` a second time in the same tick.

Additionally, the scope split between `work_rc` (line 977) and `work` (line 984) is unnecessary and fragile. They should be the same variable to remove the cognitive hazard and prevent future divergence.

**Fix:**
Remove the separate `work_rc` local. Merge the `retry_count` increment directly into the `work` read that follows:
```lua
-- Incrementar retry_count a cada tentativa efetiva (D-06)
local work = self.work[r.id] or {}
work.retry_count = (tonumber(work.retry_count or 0) or 0) + 1
-- (then continue using `work` for all subsequent field writes in this function)
-- Remove the duplicate `local work = self.work[r.id] or {}` at line 984
```
This requires removing line 984's `local work = self.work[r.id] or {}` and using the single `work` variable throughout. This is a one-line structural fix and eliminates the split-reference hazard entirely.

---

### CR-02: Pre-pass requests are also processed by the normal round-robin loop in the same tick — double processing

**File:** `modules/engine.lua:1187-1244`

**Issue:**
The pre-pass iterates over `retryEligible` and calls `_processRequest` for each. After the pre-pass, the normal round-robin loop iterates over `requests` starting from `_rq_cursor`. If a request processed by the pre-pass also appears at the cursor position in `requests`, `_processRequest` is called for the same `r.id` a **second time** in the same tick.

The second call will not be skipped by the `next_retry` guard (lines 972-974) **unless** `_processRequest` set a new `next_retry` in the first call. For a request that was `waiting_retry` and transitioned to `done` or `crafting` during the pre-pass, `work[r.id].next_retry` is not updated, so the guard at line 972 reads the now-stale `next_retry` from the pre-pass and may still return `false, nil` — but only if `next_retry > ctx.nowEpoch`. In all cases where the pre-pass succeeded and resolved the request to `done`, `next_retry` is not set, so the guard returns `true` (no skip), and the normal loop re-processes the same request within the same tick.

Concrete impact: A `done` request may be re-evaluated and re-delivered in the same tick. A `crafting` request may trigger another `craftItem` call (mitigated by the craft-lock cache, but that lock has a TTL; see `_handleCraft` line 786). More importantly, `retry_count` is incremented twice per tick for any pre-pass-processed request that is also within the round-robin window (CR-01 secondary effect).

The standard guard against double-processing in the pre-pass context is to check `isPendingState` at line 967, which is correct — but `done` is in `completed_states_deny` only if the config says so. There is no code-level deduplication between pre-pass and the round-robin loop.

**Fix:**
After the pre-pass processes a request successfully, mark it so the round-robin loop skips it in the same tick. The cleanest approach is to track processed IDs:
```lua
local prePassProcessed = {}
for _, r in ipairs(retryEligible) do
  if processed >= rqLimit then break end
  -- ... ctx setup ...
  local did, budgetErr = self:_processRequest(r, ctx)
  if did == nil and budgetErr ~= nil then
    -- budget exceeded path unchanged
    self._rq_cursor = tonumber(self._rq_cursor or 1) or 1
    publishSnapshot(state)
    self:_persistWorkMaybe()
    return
  end
  if did == true then
    processed = processed + 1
    prePassProcessed[tostring(r.id)] = true
  end
end
```
Then in the round-robin loop, add an early-continue:
```lua
if prePassProcessed[tostring(r.id)] then
  -- already handled by pre-pass this tick
else
  local did, budgetErr = self:_processRequest(r, ctx)
  -- ...
end
```
Alternatively, the pre-pass could set `work.next_retry` to a near-future value after successful processing to ensure the `next_retry` guard fires — but the set-tracking approach is cleaner and avoids polluting retry timing.

---

## Warnings

### WR-01: Sort comparator is not a strict weak ordering when both `ta` and `tb` are `math.huge` — undefined sort order for requests without `craft.started_at`

**File:** `modules/engine.lua:1179-1185`

**Issue:**
The sort comparator returns `ta < tb`. When both `ta` and `tb` are `math.huge` (both requests have no `craft.started_at`), the comparator returns `false` in both directions, which is correct for equal elements. However Lua's `table.sort` is **not stable** — the relative order of equal elements is unspecified. The spec says "oldest first"; requests without `craft` (e.g., those that never triggered a craft operation) always land at the end in arbitrary order. This is by design (D-01) but it means repeated ticks process these "no craft" requests in an unpredictable sequence. If there are many such requests and the budget is tight, some may starve indefinitely while others always happen to come first from the sort.

This is not a correctness bug for the stated requirement ("requests with craft oldest first") but is a behavioural risk worth surfacing because the sort key (craft.started_at) is **absent for most requests** in a system where items are already available in ME and no craft is needed. Those requests end up in random sort order, partially defeating the "fair ordering" intent.

**Fix:**
Add a secondary sort key for tie-breaking, e.g., the request's array position in `requests` (its index in the original list):
```lua
-- build retryEligible with position info
for i, r in ipairs(requests or {}) do
  if r and r.id then
    local w = self.work[r.id]
    if w and w.status == "waiting_retry"
       and w.next_retry and w.next_retry <= nowEpoch then
      table.insert(retryEligible, { r = r, pos = i })
    end
  end
end

table.sort(retryEligible, function(a, b)
  local wa = self.work[a.r.id]
  local wb = self.work[b.r.id]
  local ta = (wa and type(wa.craft) == "table" and tonumber(wa.craft.started_at)) or math.huge
  local tb = (wb and type(wb.craft) == "table" and tonumber(wb.craft.started_at)) or math.huge
  if ta ~= tb then return ta < tb end
  return a.pos < b.pos  -- stable by original position
end)
```

---

### WR-02: Badge `[R:N]` is measured in the **measurement loop** using the pre-badge `etapa` string (2 chars), not the post-badge string — `jobMax` underestimates required column width

**File:** `components/ui.lua:449-465`

**Issue:**
`renderRequests` has two loops: a measurement loop (lines 449–465) that computes `choMax` and `jobMax`, and a render loop (lines 493–549) that builds each line. The measurement loop reads `jobState` and calls `jobSymbol(jobState)` (line 463: `local etapa = jobSymbol(jobState)`) to compute the width of the ETAPA column. However the render loop (lines 535–539) appends `[R:N]` to `etapaStr` after calling `jobSymbol`. The measurement loop does **not** account for the `[R:N]` suffix.

`jobMax` is capped at 10 (line 469: `if jobMax > 10 then jobMax = 10 end`). `"AG[R:99]"` is 8 chars, which fits within 10. `"AG[R:999]"` is 9 chars — still within 10. `"AG[R:1000]"` is 10 chars — exactly at the cap, so it fits. However `"AG[R:10000]"` is 11 chars, which exceeds the cap and will be truncated. As noted in the plan (threat T-21-02), `retry_count` is bounded by double precision and does not persist — but a retry_count of 10000 is reachable in a long-running session where requests are repeatedly retried (e.g., one retry every 5 seconds over ~14 hours). The visual truncation itself is not a crash, but it means the column header "ETAPA" and the data are misaligned for high-count retries, breaking the fixed-format line layout.

More immediately: `jobMax` is initialised from the measurement loop using the **pre-badge** `etapa` string (2 chars for "AG", "CR", etc.). So `jobMax` starts at 5 (from `jobMin`) and only grows if any `etapa` value exceeds 5. If all jobs have 2-char symbols and `retry_count` is 0 in the measurement loop, `jobMax` will be 5. The render loop then tries to render `"AG[R:1]"` (7 chars) into a 5-char field, and `shorten` truncates it to `"AG[R."` — misleading display.

**Fix:**
Either (a) include the badge in the measurement loop:
```lua
-- in measurement loop (lines 449-465), after computing etapa:
local retryCountM = job and tonumber(job.retry_count or 0) or 0
if retryCountM >= 1 then
  etapa = etapa .. "[R:" .. tostring(retryCountM) .. "]"
end
if #etapa > jobMax then jobMax = #etapa end
```
Or (b) simply raise the hard cap from 10 to 12 to accommodate badges up to `[R:9999]` (6 extra chars) without changing measurement logic. Option (a) is more correct.

---

### WR-03: Test `engine_prepass_nao_altera_cursor` does not actually verify the cursor is *unchanged by the pre-pass* — it only verifies it is a number after the tick

**File:** `tests/run.lua:3014-3016`

**Issue:**
The test sets `engine._rq_cursor = 2` before the tick and then asserts `type(engine._rq_cursor) == "number"`. This assertion is trivially true regardless of whether the pre-pass touched the cursor. The cursor value after the tick is whatever the round-robin loop left it at — the test provides no evidence that the pre-pass did not alter it.

A correct verification would assert that the cursor advanced predictably from position 2 through the round-robin loop and did not regress to 1 (which would happen if the pre-pass reset it). With 3 requests and cursor starting at 2, after one full tick with `requests_per_tick=10`, the cursor should end up at 1 (wrapped). The test currently cannot distinguish between "pre-pass correctly left cursor alone and loop advanced it normally" vs "pre-pass reset cursor to 1 by accident and loop advanced from 1."

**Fix:**
```lua
-- after engine:tick()
-- With cursor starting at 2 and 3 requests processed (or however many the budget allows),
-- cursor should wrap around, NOT start from 1 due to pre-pass interference.
-- Stronger assertion: verify specific cursor value or that at least it was modified by the
-- round-robin loop, not reset by the pre-pass.

-- Minimal stronger assertion: verify cursor != 1 after partial round-robin from position 2
-- (with 3 requests and budget=10, all are processed; cursor ends at 1 after wrap,
-- but this is identical to pre-pass-reset behavior).
-- Alternative: use a larger request list so wrapping doesn't produce 1.
-- Or: verify that request at original cursor position (id=906) was processed,
-- proving the loop started from position 2 not 1.
assertEq(type(engine.work["906"]), "table", "id=906 at cursor pos 2 should be processed first by normal loop")
```

---

### WR-04: `engine_prepass_budget_compartilhado_com_loop_normal` test asserts `w911 == nil or retry_count == 0` — the `nil` branch masks a potential bug

**File:** `tests/run.lua:3093-3099`

**Issue:**
The test assertion for ids 911 and 912 is:
```lua
assertEq(w911 == nil or (w911.retry_count or 0) == 0, true, ...)
assertEq(w912 == nil or (w912.retry_count or 0) == 0, true, ...)
```
The `== nil` branch allows the test to pass even if the work entries for 911 and 912 simply were never written, regardless of whether the pre-pass consumed the full budget correctly. If there is a bug where the budget tracking is broken and the requests were processed but `work` was written as a new table (without `retry_count`), `w911.retry_count` would be nil, satisfying `(w911.retry_count or 0) == 0`. The test would pass despite incorrect behaviour.

The correct assertion is that if 911 was processed at all, `retry_count` must be 0 (i.e., it was not processed). The nil branch silently accepts either scenario.

**Fix:**
Split the assertion to make it explicit:
```lua
-- With budget=1 all consumed by pre-pass (id=910), the normal loop should not run at all
-- (processed=1 >= rqLimit=1), so work entries for 911 and 912 should remain nil.
assertEq(engine.work["911"], nil, "id=911 should not be in work when budget exhausted by pre-pass")
assertEq(engine.work["912"], nil, "id=912 should not be in work when budget exhausted by pre-pass")
```
Note: this stricter assertion may or may not pass depending on whether CR-02 (double-processing) is present; fixing CR-02 first would make this assertion reliable.

---

## Info

### IN-01: Pre-pass budget-exceeded early-return comment says "D-04 — nao alterar _rq_cursor aqui" but the code does alter it (sets to current value)

**File:** `modules/engine.lua:1201-1203`

**Issue:**
The comment reads `-- budget excedido: preservar cursor e sair (D-04 — nao alterar _rq_cursor aqui)` but the immediately following line is `self._rq_cursor = tonumber(self._rq_cursor or 1) or 1`, which does write to `_rq_cursor`. The comment says "don't alter here" but the code does alter it (to ensure it has a numeric default). The comment is misleading — it should say "preserve cursor value" not "do not alter." This is a documentation inconsistency, not a code bug, but it will confuse future readers.

**Fix:**
```lua
-- budget excedido: preservar cursor sem avançar (D-04)
self._rq_cursor = tonumber(self._rq_cursor or 1) or 1
```

---

### IN-02: `engine_retry_count_nao_persiste` test fs stub missing `getDir` — will error if `_persistWorkMaybe` calls `fs.getDir`

**File:** `tests/run.lua:3178-3196`

**Issue:**
The `fs` stub in `engine_retry_count_nao_persiste` implements `exists`, `open`, and `makeDir`, but not `getDir`. The `Persistence.save` code path (called via `_persistWorkMaybe`) may call `fs.getDir` to resolve the directory of the output path. If it does, the test will error with an attempt to call a nil value. The test already controls the `_persist_next_at_ms` timer to force an immediate persist, making this code path always execute during the test.

Other tests that stub `fs` (e.g., `persistence_save_and_load_v1_schema` at line 2043) do include `getDir`. The omission here is an oversight.

**Fix:**
Add `getDir` to the fs stub:
```lua
fs = {
  exists = ...,
  open = ...,
  makeDir = function() end,
  getDir = function(path)
    local i = string.match(path, "^.*()/")
    if not i then return "" end
    return string.sub(path, 1, i - 1)
  end,
}
```

---

_Reviewed: 2026-04-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
