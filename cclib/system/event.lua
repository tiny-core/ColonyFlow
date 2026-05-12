--- =====================================================================================================================
-- Arquivo: cclib/system/event.lua
-- Descrição:
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

local Log        = require("cclib.system.log")

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Event
local M          = {}

--#endregion

--#region Propriedades privadas ----------------------------------------------------------------------------------------

local _listeners = {} -- { [eventName] = { {id, fn, once}, ... } }
local _nextId    = 1
local _paused    = false
local _queue     = {} -- fila de eventos emitidos enquanto pausado

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.on(eventName, fn)
  if type(eventName) ~= "string" then
    Log.warn("event", "M.on: eventName deve ser string, recebeu %s", type(eventName))
    return nil
  end
  if type(fn) ~= "function" then
    Log.warn("event", "M.on: fn deve ser function")
    return nil
  end

  if not _listeners[eventName] then
    _listeners[eventName] = {}
  end

  local id = _nextId
  _nextId = _nextId + 1
  _listeners[eventName][#_listeners[eventName] + 1] = {
    id   = id,
    fn   = fn,
    once = false,
  }

  Log.debug("event", "Listener #%d registado para '%s'", id, eventName)
  return id
end

function M.once(eventName, fn)
  if type(eventName) ~= "string" or type(fn) ~= "function" then
    Log.warn("event", "M.once: argumentos inválidos")
    return nil
  end

  if not _listeners[eventName] then
    _listeners[eventName] = {}
  end

  local id = _nextId
  _nextId = _nextId + 1
  _listeners[eventName][#_listeners[eventName] + 1] = {
    id   = id,
    fn   = fn,
    once = true,
  }
  return id
end

function M.off(id)
  if type(id) ~= "number" then return false end

  for eventName, list in pairs(_listeners) do
    for i, entry in ipairs(list) do
      if entry.id == id then
        table.remove(list, i)
        Log.debug("event", "Listener #%d removido de '%s'", id, eventName)
        return true
      end
    end
  end
  return false
end

function M.offAll(eventName)
  if _listeners[eventName] then
    local count = #_listeners[eventName]
    _listeners[eventName] = {}
    Log.debug("event", "%d listeners removidos de '%s'", count, eventName)
    return count
  end
  return 0
end

function M.reset()
  local total = 0
  for _, list in pairs(_listeners) do total = total + #list end
  _listeners = {}
  Log.debug("event", "Bus resetado (%d listeners removidos)", total)
end

function M.emit(eventName, data)
  if _paused then
    _queue[#_queue + 1] = { eventName, data }
    return
  end

  local list = _listeners[eventName]
  if not list or #list == 0 then return end

  Log.debug("event", "emit '%s' (%d listeners)", eventName, #list)

  local snapshot = {}
  for i, e in ipairs(list) do snapshot[i] = e end

  local toRemove = {}
  for _, entry in ipairs(snapshot) do
    local ok, err = pcall(entry.fn, data)
    if not ok then
      Log.error("event", "Handler de '%s' lançou erro: %s", eventName, tostring(err))
    end
    if entry.once then
      toRemove[#toRemove + 1] = entry.id
    end
  end

  -- Remove os once que dispararam
  for _, id in ipairs(toRemove) do M.off(id) end
end

function M.dispatch(eventName, ...)
  if _paused then
    -- Empacota os args variáveis numa tabela para a queue
    local args = { eventName, { __cc_args = true, ... } }
    _queue[#_queue + 1] = args
    return
  end

  local list = _listeners[eventName]
  if not list or #list == 0 then return end

  local snapshot = {}
  for i, e in ipairs(list) do snapshot[i] = e end

  local toRemove = {}
  for _, entry in ipairs(snapshot) do
    local ok, err = pcall(entry.fn, ...)
    if not ok then
      Log.error("event", "Handler de '%s' lançou erro: %s", eventName, tostring(err))
    end
    if entry.once then toRemove[#toRemove + 1] = entry.id end
  end
  for _, id in ipairs(toRemove) do M.off(id) end
end

function M.pause()
  _paused = true
  Log.debug("event", "Bus pausado")
end

function M.resume()
  _paused = false
  local queued = _queue
  _queue = {}
  Log.debug("event", "Bus retomado (%d eventos em fila)", #queued)

  for _, entry in ipairs(queued) do
    local name = entry[1]
    local data = entry[2]
    if type(data) == "table" and data.__cc_args then
      M.dispatch(name, table.unpack(data))
    else
      M.emit(name, data)
    end
  end
end

function M.inspect()
  local result = { total = 0, events = {} }
  for name, list in pairs(_listeners) do
    result.events[name] = #list
    result.total = result.total + #list
  end
  result.paused = _paused
  result.queued = #_queue
  return result
end

--#endregion

return M
