local Util = require("lib.util")

local Snapshot = {}

local function asTable(v)
  if type(v) == "table" then return v end
  return {}
end

local function shallowCopy(t)
  if type(t) ~= "table" then return {} end
  local out = {}
  for k, v in pairs(t) do
    out[k] = v
  end
  return out
end

local function copyList(list, mapFn)
  if type(list) ~= "table" then return {} end
  local out = {}
  for i, v in ipairs(list) do
    out[i] = mapFn(v)
  end
  return out
end

local function copyRequest(r)
  r = asTable(r)
  local items = copyList(asTable(r.items), function(it)
    it = asTable(it)
    return {
      name = it.name,
      count = it.count,
      tags = it.tags,
    }
  end)
  local accepted = copyList(asTable(r.accepted), function(it)
    it = asTable(it)
    return {
      name = it.name,
      count = it.count,
      tags = it.tags,
    }
  end)
  return {
    id = r.id,
    state = r.state,
    target = r.target,
    count = r.count,
    requiredCount = r.requiredCount,
    items = items,
    accepted = accepted,
  }
end

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

local function copyHealth(health)
  health = asTable(health)
  local peripherals = copyList(asTable(health.peripherals), function(it)
    it = asTable(it)
    return {
      label = it.label,
      value = it.value,
      level = it.level,
    }
  end)
  return { peripherals = peripherals }
end

local function defaultStats()
  return {
    processed = 0,
    crafted = 0,
    delivered = 0,
    substitutions = 0,
    errors = 0,
  }
end

function Snapshot.build(state)
  state = asTable(state)

  local snap = {
    at_ms = Util.nowUtcMs(),
    requests = copyList(asTable(state.requests), copyRequest),
    work = {},
    health = copyHealth(state.health),
    stats = shallowCopy(state.stats),
    metrics = shallowCopy(state.metrics),
    throttle = shallowCopy(state.throttle),
  }

  if next(snap.stats) == nil then
    snap.stats = defaultStats()
  end

  local work = asTable(state.work)
  for id, job in pairs(work) do
    snap.work[tostring(id)] = copyWorkJob(job)
  end

  if type(state.installed) == "table" then
    snap.installed = shallowCopy(state.installed)
  end
  if type(state.update) == "table" then
    snap.update = shallowCopy(state.update)
  end

  if next(snap.metrics) == nil then
    snap.metrics = { enabled = false }
  end
  if next(snap.throttle) == nil then
    snap.throttle = { active = false }
  end

  return snap
end

return Snapshot
