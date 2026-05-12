-- =====================================================================================================================
-- Arquivo: cclib/system/log.lua
-- Descrição: Sistema de logging com níveis, saída para ficheiro e monitor de debug opcional.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

local LConst       = require("cclib.core.const")
local Str          = require("cclib.core.str")

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Log
local M            = {}

--#endregion

--#region Propriedades privadas ----------------------------------------------------------------------------------------

local _level       = LConst.DEV and LConst.LOG.DEBUG or LConst.LOG.INFO
local _fileHandle  = nil
local _debugMon    = nil -- monitor lateral para logs em tempo real
local _lineCount   = 0
local _initialized = false
local _buffer      = {} -- buffer de linhas antes da inicialização

--#endregion

--#region Métodos privados ---------------------------------------------------------------------------------------------

function M._write(level, module, message)
  if level < _level then return end

  local levelName = LConst.LOG_NAMES[level] or "?"
  local time      = os.date and os.date("%H:%M:%S") or "??:??:??"
  local line      = string.format("[%s] [%-5s] [%s] %s", time, levelName, module, message)

  -- Terminal (só em DEV ou se WARN+)
  if LConst.DEV or level >= LConst.LOG.WARN then
    print(line)
  end

  -- Ficheiro
  if _fileHandle then
    _fileHandle:write(line .. "\n")
    _fileHandle:flush()
    _lineCount = _lineCount + 1

    -- Rotação de ficheiro quando atinge o limite
    if _lineCount >= LConst.LIMIT.LOG_FILE_LINES then
      _fileHandle:write("--- log rotacionado ---\n")
      _fileHandle:close()
      _fileHandle = nil
      _lineCount  = 0
      M.init({ file = true }) -- reabre novo ficheiro
    end
  end

  -- Monitor de debug
  if _debugMon then
    local ok = pcall(function()
      local w, h = _debugMon.getSize()
      _debugMon.scroll(1)
      _debugMon.setCursorPos(1, h)
      -- Cor por nível
      if level >= LConst.LOG.FATAL then
        _debugMon.setTextColor(colors and colors.red or 16384)
      elseif level >= LConst.LOG.ERROR then
        _debugMon.setTextColor(colors and colors.orange or 2)
      elseif level >= LConst.LOG.WARN then
        _debugMon.setTextColor(colors and colors.yellow or 16)
      else
        _debugMon.setTextColor(colors and colors.lightGray or 256)
      end
      _debugMon.write(Str.truncate(line, w))
      _debugMon.setTextColor(colors and colors.white or 1)
    end)
    if not ok then _debugMon = nil end -- monitor desconectado
  end
end

-- Todos os métodos aceitam formato printf:
-- M.info("modulo", "valor=%s count=%d", valor, count)
local function _makeLogger(level)
  return function(module, fmt, ...)
    local msg
    if select("#", ...) > 0 then
      local ok, result = pcall(string.format, fmt, ...)
      msg = ok and result or (tostring(fmt) .. " [fmt error]")
    else
      msg = tostring(fmt)
    end

    if not _initialized then
      _buffer[#_buffer + 1] = { level, module, msg }
    else
      M._write(level, module, msg)
    end
  end
end

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.init(opts)
  opts = opts or {}

  -- Nível mínimo
  if opts.level then
    local levels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4, FATAL = 5 }
    _level = levels[opts.level:upper()] or _level
  end

  -- Ficheiro de log
  if opts.file ~= false then
    local path = LConst.PATH.LOGS
    if not fs.exists(path) then
      fs.makeDir(path)
    end
    local filename = path .. os.date("%Y-%m-%d") .. ".log"
    local handle, err = io.open(filename, "a")
    if handle then
      _fileHandle = handle
    else
      -- não podemos logar o erro ainda — vai para o buffer
      _buffer[#_buffer + 1] = { LConst.LOG.WARN, "log", "Não foi possível abrir ficheiro de log: " .. tostring(err) }
    end
  end

  -- Monitor de debug
  if opts.monitor then
    local mon = peripheral.find and peripheral.find(LConst.PERIPHERAL.MONITOR) or
        (peripheral.isPresent(opts.monitor) and peripheral.wrap(opts.monitor))
    if mon then
      _debugMon = mon
      _debugMon.setTextScale(0.5)
      _debugMon.clear()
      _debugMon.setCursorPos(1, 1)
    end
  end

  _initialized = true

  -- Descarrega buffer de mensagens pré-init
  for _, entry in ipairs(_buffer) do
    M._write(entry[1], entry[2], entry[3])
  end
  _buffer = {}
end

M.debug = _makeLogger(LConst.LOG.DEBUG)
M.info  = _makeLogger(LConst.LOG.INFO)
M.warn  = _makeLogger(LConst.LOG.WARN)
M.error = _makeLogger(LConst.LOG.ERROR)
M.fatal = _makeLogger(LConst.LOG.FATAL)

function M.setLevel(level)
  local levels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4, FATAL = 5 }
  _level = levels[tostring(level):upper()] or _level
end

function M.getLevel()
  return LConst.LOG_NAMES[_level] or "?"
end

function M.close()
  if _fileHandle then
    M.info("log", "Log encerrado")
    _fileHandle:flush()
    _fileHandle:close()
    _fileHandle = nil
  end
end

function M.separator(label)
  local line = string.rep("-", 40)
  label = label and (" " .. label .. " ") or ""
  local sep = line .. label .. line
  M._write(LConst.LOG.INFO, "---", sep:sub(1, 60))
end

--#endregion

return M
