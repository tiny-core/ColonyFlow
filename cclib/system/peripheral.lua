-- =====================================================================================================================
-- Arquivo: cclib/system/peripheral.lua
-- Descrição: Detecção e gestão de periféricos CC:Tweaked.
--            Suporta sides físicos ("top", "left"…) E periféricos por wired modem ("monitor_0"…).
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

local PConst = require("cclib.core.const")
local PGuard = require("cclib.core.guard")
local PLog   = require("cclib.system.log")
local PEvent = require("cclib.system.event")
local PLang  = require("cclib.lang.init")

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Peripheral
local M      = {}

--#endregion

--#region Propriedades privadas ----------------------------------------------------------------------------------------

-- { [name] = { type, obj, name, wired } }
-- `name` pode ser um side ("top") ou um ID wired ("monitor_0")
local _known = {}

-- Lookup de sides para distinguir wired vs side em O(1)
local _SIDES = {}
for _, s in ipairs(PConst.SIDE.ALL) do _SIDES[s] = true end

local function _isWired(name)
  return not _SIDES[name]
end

--#endregion

--#region Métodos privados ---------------------------------------------------------------------------------------------


local function _register(name)
  if not peripheral.isPresent(name) then return end

  local pType = peripheral.getType(name)
  local obj   = peripheral.wrap(name)

  if not obj then
    PLog.warn("peripheral", "Falha ao fazer wrap de '%s' (%s)", name, tostring(pType))
    return
  end

  local wired = _isWired(name)
  _known[name] = { type = pType, obj = obj, name = name, wired = wired }

  if wired then
    PLog.info("peripheral", "Registado (wired): %-12s (%s)", name, pType)
  else
    PLog.info("peripheral", "Registado (side):  %-12s (%s)", name, pType)
  end

  PEvent.emit(PConst.EVENT.PERIPHERAL_FOUND, {
    name  = name,
    type  = pType,
    obj   = obj,
    wired = wired,
  })
end

local function _unregister(name)
  local entry = _known[name]
  if not entry then return end
  PLog.info("peripheral", "Desconectado: %s (%s)", name, entry.type)
  PEvent.emit(PConst.EVENT.PERIPHERAL_LOST, { name = name, type = entry.type, wired = entry.wired })
  _known[name] = nil
end


--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.init()
  PLog.info("peripheral", PLang.t("cclib.peripheral.scan"))

  local names = {}

  if peripheral.getNames then
    -- Retorna ["top", "monitor_0", "speaker_1", ...] — sides e wired juntos
    names = peripheral.getNames()
    PLog.debug("peripheral", PLang.t("cclib.peripheral.getNames_available", #names))
  else
    -- Fallback para CC:Tweaked < 1.84 — só sides
    PLog.debug("peripheral", PLang.t("cclib.peripheral.getNames_unavailable"))
    for _, side in ipairs(PConst.SIDE.ALL) do
      if peripheral.isPresent(side) then
        names[#names + 1] = side
      end
    end
  end

  for _, name in ipairs(names) do
    _register(name)
  end

  -- Reage a conexões/desconexões (funciona para sides e wired)
  PEvent.on("peripheral", function(name) _register(name) end)
  PEvent.on("peripheral_detach", function(name) _unregister(name) end)

  local count = 0
  for _ in pairs(_known) do count = count + 1 end
  PLog.info("peripheral", PLang.t("cclib.peripheral.found", count))
end

function M.get(pType, name)
  if name then
    local entry = _known[name]
    if entry and entry.type == pType then return entry.obj, name end
    return nil
  end
  for n, entry in pairs(_known) do
    if entry.type == pType then return entry.obj, n end
  end
  return nil
end

function M.getByName(name)
  name = PGuard.isString(name, "name")
  local entry = _known[name]
  if not entry then return nil end
  return entry.obj, entry.type, entry.wired
end

function M.getAll(pType)
  local result = {}
  for name, entry in pairs(_known) do
    if entry.type == pType then
      result[#result + 1] = { obj = entry.obj, name = name, wired = entry.wired }
    end
  end
  return result
end

function M.has(pType, name)
  if name then
    return _known[name] ~= nil and _known[name].type == pType
  end
  for _, entry in pairs(_known) do
    if entry.type == pType then return true end
  end
  return false
end

-- M.nameOf("monitor") → "monitor_0", true
-- M.nameOf("modem")   → "left",      false
function M.nameOf(pType)
  for name, entry in pairs(_known) do
    if entry.type == pType then return name, entry.wired end
  end
  return nil
end

function M.inspect()
  local result = {}
  for name, entry in pairs(_known) do
    result[#result + 1] = { name = name, type = entry.type, wired = entry.wired }
  end
  table.sort(result, function(a, b)
    if a.wired ~= b.wired then return not a.wired end -- sides primeiro
    return a.name < b.name
  end)
  return result
end

function M.rescan(name)
  if name then
    _unregister(name)
    _register(name)
  else
    _known = {}
    M.init()
  end
end

--#endregion

return M
