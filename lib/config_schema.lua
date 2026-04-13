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
    validateEnum(errors, "core.log_level", core.log_level, LOG_LEVELS, function(s) return tostring(s):upper() end)
    validateNumber(errors, "core.log_max_files", core.log_max_files, nil, 1)
    validateNumber(errors, "core.log_max_kb", core.log_max_kb, nil, 1)
  end

  local delivery = updatesBySection.delivery
  if type(delivery) == "table" then
    validateEnum(errors, "delivery.export_mode", delivery.export_mode, EXPORT_MODES, function(s) return tostring(s):lower() end)
    validateEnum(errors, "delivery.export_direction", delivery.export_direction, DIRECTIONS, function(s) return tostring(s):lower() end)
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

  return { ok = #errors == 0, errors = errors }
end

return M
