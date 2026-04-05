local Util = require("lib.util")

local M = {}

local function tryWrapByName(name)
  if not name or name == "" then return nil end
  if not peripheral.isPresent(name) then return nil end
  return peripheral.wrap(name)
end

local function tryFindByType(typeName)
  return peripheral.find(typeName)
end

local function resolve(cfg, logger, key, typeName)
  local name = cfg:get("peripherals", key, "")
  local dev = tryWrapByName(name)
  if dev then return dev, name end

  if type(typeName) == "table" then
    for _, t in ipairs(typeName) do
      dev = tryFindByType(t)
      if dev then return dev, peripheral.getName(dev) end
    end
  else
    dev = tryFindByType(typeName)
    if dev then return dev, peripheral.getName(dev) end
  end

  local typeLabel = type(typeName) == "table" and table.concat(typeName, "|") or tostring(typeName)
  logger:warn("Periférico não encontrado: " .. key .. " (" .. typeLabel .. ")")
  return nil, nil
end

function M.discover(cfg, logger)
  local issues = {}

  local colonyIntegrator, colonyName = resolve(cfg, logger, "colony_integrator", "colonyIntegrator")
  if not colonyIntegrator then table.insert(issues, "colonyIntegrator ausente") end

  local meBridge, meName = resolve(cfg, logger, "me_bridge", { "meBridge", "me_bridge" })
  if not meBridge then table.insert(issues, "meBridge ausente") end

  local modem, modemName = resolve(cfg, logger, "modem", "modem")
  if not modem then
    table.insert(issues, "modem ausente (rede de periféricos pode não funcionar)")
  end

  local monReq, monReqName = resolve(cfg, logger, "monitor_requests", "monitor")
  local monStat, monStatName = resolve(cfg, logger, "monitor_status", "monitor")

  if not monReq then table.insert(issues, "monitor_requests ausente") end
  if not monStat then table.insert(issues, "monitor_status ausente") end

  local devices = {
    colonyIntegrator = colonyIntegrator,
    colonyName = colonyName,
    meBridge = meBridge,
    meName = meName,
    modem = modem,
    modemName = modemName,
    monitorRequests = monReq,
    monitorRequestsName = monReqName,
    monitorStatus = monStat,
    monitorStatusName = monStatName,
  }

  Util.ensureDir(cfg:get("core", "log_dir", "logs"))
  Util.ensureDir("data")

  return devices, issues
end

return M
