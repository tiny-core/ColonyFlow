local Util = require("lib.util")

local M = {}

local function addErr(errors, msg)
  table.insert(errors, tostring(msg or "erro"))
end

local function toNumber(v)
  local n = tonumber(v)
  if not n then return nil end
  return n
end

local function isInSet(v, set)
  return set[tostring(v)] == true
end

local function validateNumber(errors, label, v, minExclusive, minInclusive)
  if v == nil or v == "" then return end
  local n = toNumber(v)
  if not n then
    addErr(errors, label .. ": deve ser numero")
    return
  end
  if minExclusive ~= nil and not (n > minExclusive) then
    addErr(errors, label .. ": deve ser > " .. tostring(minExclusive))
    return
  end
  if minInclusive ~= nil and not (n >= minInclusive) then
    addErr(errors, label .. ": deve ser >= " .. tostring(minInclusive))
    return
  end
end

local function validateBool(errors, label, v)
  if v == nil or v == "" then return end
  local s = tostring(v):lower()
  local ok = (s == "true" or s == "false" or s == "1" or s == "0" or s == "yes" or s == "no" or s == "y" or s == "n" or s == "on" or s == "off")
  if not ok then
    addErr(errors, label .. ": deve ser bool (true/false)")
  end
end

local function validateEnum(errors, label, v, set, normalize)
  if v == nil or v == "" then return end
  local raw = tostring(v)
  local n = normalize and normalize(raw) or raw
  if not isInSet(n, set) then
    addErr(errors, label .. ": valor invalido (" .. raw .. ")")
  end
end

local LOG_LEVELS = { DEBUG = true, INFO = true, WARN = true, ERROR = true }
local EXPORT_MODES = { auto = true, peripheral = true, direction = true, buffer = true }
local DIRECTIONS = { up = true, down = true, north = true, south = true, east = true, west = true }

function M.validateUpdates(updatesBySection)
  local errors = {}
  if type(updatesBySection) ~= "table" then
    return { ok = true, errors = errors }
  end

  local core = updatesBySection.core
  if type(core) == "table" then
    validateNumber(errors, "core.poll_interval_seconds", core.poll_interval_seconds, 0, nil)
    validateNumber(errors, "core.ui_refresh_seconds", core.ui_refresh_seconds, 0, nil)
    validateNumber(errors, "core.peripheral_watchdog_seconds", core.peripheral_watchdog_seconds, nil, 0)
    validateEnum(errors, "core.log_level", core.log_level, LOG_LEVELS, function(s) return tostring(s):upper() end)
    validateNumber(errors, "core.log_max_files", core.log_max_files, nil, 1)
    validateNumber(errors, "core.log_max_kb", core.log_max_kb, nil, 1)
  end

  local delivery = updatesBySection.delivery
  if type(delivery) == "table" then
    validateEnum(errors, "delivery.export_mode", delivery.export_mode, EXPORT_MODES,
      function(s) return tostring(s):lower() end)
    validateEnum(errors, "delivery.export_direction", delivery.export_direction, DIRECTIONS,
      function(s) return tostring(s):lower() end)
    validateNumber(errors, "delivery.destination_cache_ttl_seconds", delivery.destination_cache_ttl_seconds, nil, 0)
  end

  local p = updatesBySection.peripherals
  if type(p) == "table" then
    local mr = Util.trim(p.monitor_requests or "")
    local ms = Util.trim(p.monitor_status or "")
    if mr ~= "" and ms ~= "" and mr == ms then
      addErr(errors, "peripherals: monitor_requests e monitor_status nao podem ser iguais")
    end
  end

  local upd = updatesBySection.update
  if type(upd) == "table" then
    validateBool(errors, "update.enabled", upd.enabled)

    validateNumber(errors, "update.ttl_hours", upd.ttl_hours, 0, nil)
    validateNumber(errors, "update.retry_seconds", upd.retry_seconds, nil, 1)
    validateNumber(errors, "update.error_backoff_max_seconds", upd.error_backoff_max_seconds, nil, 1)

    local rs = tonumber(upd.retry_seconds)
    local mx = tonumber(upd.error_backoff_max_seconds)
    if rs and mx and mx < rs then
      addErr(errors, "update.error_backoff_max_seconds: deve ser >= update.retry_seconds")
    end
  end

  local obs = updatesBySection.observability
  if type(obs) == "table" then
    validateBool(errors, "observability.enabled", obs.enabled)
    validateBool(errors, "observability.ui_enabled", obs.ui_enabled)
    validateBool(errors, "observability.debug_log_enabled", obs.debug_log_enabled)
    validateNumber(errors, "observability.debug_log_interval_seconds", obs.debug_log_interval_seconds, nil, 5)
  end

  local sb = updatesBySection.scheduler_budget
  if type(sb) == "table" then
    validateBool(errors, "scheduler_budget.enabled", sb.enabled)
    validateNumber(errors, "scheduler_budget.requests_per_tick", sb.requests_per_tick, nil, 0)
    validateNumber(errors, "scheduler_budget.mc_calls_per_tick", sb.mc_calls_per_tick, nil, 0)
    validateNumber(errors, "scheduler_budget.me_calls_per_tick", sb.me_calls_per_tick, nil, 0)
    validateNumber(errors, "scheduler_budget.inv_calls_per_tick", sb.inv_calls_per_tick, nil, 0)
    validateNumber(errors, "scheduler_budget.window_seconds", sb.window_seconds, nil, 0)
    validateNumber(errors, "scheduler_budget.mc_calls_per_window", sb.mc_calls_per_window, nil, 0)
    validateNumber(errors, "scheduler_budget.me_calls_per_window", sb.me_calls_per_window, nil, 0)
    validateNumber(errors, "scheduler_budget.inv_calls_per_window", sb.inv_calls_per_window, nil, 0)
    validateNumber(errors, "scheduler_budget.requests_refresh_interval_seconds", sb.requests_refresh_interval_seconds, nil, 0)

    local enabled = true
    if sb.enabled ~= nil and sb.enabled ~= "" then
      local s = tostring(sb.enabled):lower()
      if s == "false" or s == "0" or s == "no" or s == "n" or s == "off" then
        enabled = false
      end
    end

    if enabled then
      local ws = toNumber(sb.window_seconds)
      if ws ~= nil and ws < 1 then
        addErr(errors, "scheduler_budget.window_seconds: deve ser >= 1 quando enabled")
      end
      local rr = toNumber(sb.requests_refresh_interval_seconds)
      if rr ~= nil and rr < 1 then
        addErr(errors, "scheduler_budget.requests_refresh_interval_seconds: deve ser >= 1 quando enabled")
      end
    end
  end

  return { ok = #errors == 0, errors = errors }
end

return M
