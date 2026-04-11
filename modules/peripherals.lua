local Util = require("lib.util")

local M = {}

local function safePeripheralWrap(name)
  local ok, res = pcall(peripheral.wrap, name)
  if ok then return res end
  return nil, tostring(res)
end

local function safePeripheralFind(...)
  local ok, res = pcall(peripheral.find, ...)
  if ok then return res end
  return nil, tostring(res)
end

local function safePeripheralGetNames()
  local ok, res = pcall(peripheral.getNames)
  if ok then return res end
  return {}, tostring(res)
end

local function getAvailablePeripheralsStr()
  local names, err = safePeripheralGetNames()
  if type(names) ~= "table" then return "(erro ao listar periféricos: " .. tostring(err) .. ")" end
  local count = #names
  if count == 0 then return "(0 encontrados)" end
  local max_list = 20
  local list = {}
  for i = 1, math.min(count, max_list) do
    table.insert(list, tostring(names[i]))
  end
  local str = table.concat(list, ", ")
  if count > max_list then
    str = str .. " ... (" .. (count - max_list) .. " omitidos)"
  end
  return string.format("%d encontrados: [%s]", count, str)
end

local function tryWrapByName(name)
  if not name or name == "" then return nil end
  local ok, present = pcall(peripheral.isPresent, name)
  if not ok or not present then return nil end
  return safePeripheralWrap(name)
end

local function tryFindByType(typeName)
  return safePeripheralFind(typeName)
end

local function resolve(cfg, logger, key, typeName)
  local name = cfg:get("peripherals", key, "")
  local dev = tryWrapByName(name)
  if dev then return dev, name end

  if type(typeName) == "table" then
    for _, t in ipairs(typeName) do
      dev = tryFindByType(t)
      if dev then
        local ok, pName = pcall(peripheral.getName, dev)
        if ok and pName then return dev, pName end
      end
    end
  else
    dev = tryFindByType(typeName)
    if dev then
      local ok, pName = pcall(peripheral.getName, dev)
      if ok and pName then return dev, pName end
    end
  end

  local typeLabel = type(typeName) == "table" and table.concat(typeName, "|") or tostring(typeName)
  local available = getAvailablePeripheralsStr()
  local hintMsg = string.format("Ajuste config.ini: [peripherals] %s=<nome do peripheral.getNames()>", key)

  logger:warn("Periférico não resolvido", {
    key = key,
    expected_type = typeLabel,
    configured_name = name,
    hint = hintMsg,
    available_peripherals = available
  })

  return nil, nil, typeLabel, name
end

function M.discover(cfg, logger)
  local issues = {}

  local colonyIntegrator, colonyName, colType, colCfg = resolve(cfg, logger, "colony_integrator", "colonyIntegrator")
  if not colonyIntegrator then
    table.insert(issues,
      string.format("[peripherals] %s ausente. Ajuste %s=<nome> (tipo: %s)", "colony_integrator", "colony_integrator",
        colType))
  end

  local meBridge, meName, meType, meCfg = resolve(cfg, logger, "me_bridge", { "meBridge", "me_bridge" })
  if not meBridge then
    table.insert(issues,
      string.format("[peripherals] %s ausente. Ajuste %s=<nome> (tipo: %s)", "me_bridge", "me_bridge", meType))
  end

  local modem, modemName, modemType, modemCfg = resolve(cfg, logger, "modem", "modem")
  if not modem then
    table.insert(issues,
      string.format(
      "[peripherals] %s ausente. Impacto na rede. Em MP, verifique permissões/alcance/bloqueios. Ajuste %s=<nome> (tipo: %s)",
        "modem", "modem", modemType))
  end

  local monReq, monReqName, monReqType, monReqCfg = resolve(cfg, logger, "monitor_requests", "monitor")
  local monStat, monStatName, monStatType, monStatCfg = resolve(cfg, logger, "monitor_status", "monitor")

  if not monReq then
    table.insert(issues,
      string.format("[peripherals] %s ausente. Ajuste %s=<nome> (tipo: %s)", "monitor_requests", "monitor_requests",
        monReqType))
  end
  if not monStat then
    table.insert(issues,
      string.format("[peripherals] %s ausente. Ajuste %s=<nome> (tipo: %s)", "monitor_status", "monitor_status",
        monStatType))
  end

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
