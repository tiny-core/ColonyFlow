-- =====================================================================================================================
-- Arquivo: cclib/system/timer.lua
-- Descrição: Gestão centralizada de timers CC:Tweaked.
--            Evita timers soltos espalhados pelo código; dá nomes e rastreia cada timer.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

local TConst        = require("cclib.core.const")
local TLog          = require("cclib.system.log")

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Timer
local M             = {}

--#endregion

--#region Métodos privados ---------------------------------------------------------------------------------------------

--- ```lua
--- { [ccTimerId] = { name, interval, callback, loop, startedAt } }
--- ```
local _timers       = {}
--- ```lua
--- { [name] = ccTimerId }  -- índice por nome para cancelamento rápido
--- ```
local _byName       = {}
local _totalCount   = 0

local _delayCounter = 0

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.create(name, interval, callback, opts)
  if type(name) ~= "string" then
    TLog.warn("timer", "create: name deve ser string"); return nil
  end
  if type(interval) ~= "number" then
    TLog.warn("timer", "create: interval deve ser number"); return nil
  end
  if type(callback) ~= "function" then
    TLog.warn("timer", "create: callback deve ser function"); return nil
  end
  if interval < 0.05 then interval = 0.05 end

  opts = opts or {}

  -- Cancela timer anterior com o mesmo nome
  if _byName[name] then
    M.cancel(name)
  end

  if _totalCount >= TConst.LIMIT.TIMER_MAX then
    TLog.warn("timer", "Limite de %d timers atingido, não foi possível criar '%s'", TConst.LIMIT.TIMER_MAX, name)
    return nil
  end

  local ccId    = os.startTimer(interval)
  _timers[ccId] = {
    name      = name,
    interval  = interval,
    callback  = callback,
    loop      = opts.loop == true,
    args      = opts.args or {},
    startedAt = os.clock and os.clock() or 0,
  }
  _byName[name] = ccId
  _totalCount   = _totalCount + 1

  TLog.debug("timer", "Timer '%s' criado (id=%d, interval=%.2fs, loop=%s)",
    name, ccId, interval, tostring(opts.loop == true))
  return ccId
end

function M.fire(ccId)
  local entry = _timers[ccId]
  if not entry then return false end

  TLog.debug("timer", "Timer '%s' disparou (id=%d)", entry.name, ccId)

  -- Executa callback protegido
  local ok, err = pcall(entry.callback, table.unpack(entry.args))
  if not ok then
    TLog.error("timer", "Callback do timer '%s' lançou erro: %s", entry.name, tostring(err))
  end

  -- Remove da tabela (o ID CC é descartável após o disparo)
  _timers[ccId]       = nil
  _byName[entry.name] = nil
  _totalCount         = _totalCount - 1

  -- Re-agenda se loop
  if entry.loop then
    M.create(entry.name, entry.interval, entry.callback, {
      loop = true,
      args = entry.args,
    })
  end

  return true
end

function M.cancel(name)
  local ccId = _byName[name]
  if not ccId then return false end

  -- os.cancelTimer existe no CC:Tweaked mas não em todas as versões
  if os.cancelTimer then
    pcall(os.cancelTimer, ccId)
  end

  _timers[ccId] = nil
  _byName[name] = nil
  _totalCount   = _totalCount - 1

  TLog.debug("timer", "Timer '%s' cancelado", name)
  return true
end

function M.cancelAll()
  for ccId, entry in pairs(_timers) do
    if os.cancelTimer then pcall(os.cancelTimer, ccId) end
    TLog.debug("timer", "Timer '%s' cancelado (cancelAll)", entry.name)
  end
  _timers     = {}
  _byName     = {}
  _totalCount = 0
end

function M.exists(name)
  return _byName[name] ~= nil
end

function M.count()
  return _totalCount
end

function M.inspect()
  local result = {}
  for _, entry in pairs(_timers) do
    result[#result + 1] = {
      name     = entry.name,
      interval = entry.interval,
      loop     = entry.loop,
    }
  end
  return result
end

function M.delay(seconds, callback)
  _delayCounter = _delayCounter + 1
  local name = "__delay_" .. _delayCounter
  return M.create(name, seconds, callback, { loop = false })
end

function M.debounce(name, seconds, callback)
  if M.exists(name) then
    M.cancel(name)
  end
  return M.create(name, seconds, callback, { loop = false })
end

--#endregion

return M
