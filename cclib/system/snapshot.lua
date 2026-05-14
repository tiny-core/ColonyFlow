-- =====================================================================================================================
-- Arquivo: cclib/system/snapshot.lua
-- Descrição: Deep copy e diff de tabelas. Usado pelo store.lua para detetar mudanças e pelo sistema de undo.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

local SConst = require("cclib.core.const")
local SLog   = require("cclib.system.log")
local SLang  = require("cclib.lang.init")

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Snapshot
local M      = {}

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.copy(orig, _visited, _depth)
  _depth   = _depth or 0
  _visited = _visited or {}

  if _depth > SConst.LIMIT.SNAPSHOT_DEPTH then
    SLog.warn("snapshot", SLang.t("cclib.snapshot.max_deep_copy", SConst.LIMIT.SNAPSHOT_DEPTH))
    return orig
  end

  if type(orig) ~= "table" then return orig end

  -- Detecção de ciclo
  if _visited[orig] then
    SLog.warn("snapshot", SLang.t("cclib.snapshot.max_deep_copy"))
    return nil
  end
  _visited[orig] = true

  local copy = {}
  for k, v in pairs(orig) do
    local kk = type(k) == "table" and M.copy(k, _visited, _depth + 1) or k
    copy[kk] = M.copy(v, _visited, _depth + 1)
  end

  setmetatable(copy, getmetatable(orig))
  _visited[orig] = nil -- limpa para permitir referências não-circulares à mesma tabela
  return copy
end

-- ── Diff ──────────────────────────────────────────────────────────────────────

-- Retorna uma tabela com:
--   added   = { [key] = newValue }     → chaves que existem em `new` mas não em `old`
--   removed = { [key] = oldValue }     → chaves que existem em `old` mas não em `new`
--   changed = { [key] = {old, new} }   → chaves com valor alterado
--   isEmpty = bool                     → true se não há diferenças
--
-- Nota: compara apenas o primeiro nível. Para diff profundo usa deepDiff.
function M.diff(old, new)
  local result = {
    added   = {},
    removed = {},
    changed = {},
    isEmpty = true,
  }

  -- Verifica tudo em `new`
  for k, vNew in pairs(new) do
    local vOld = old[k]
    if vOld == nil then
      result.added[k] = vNew
      result.isEmpty  = false
    elseif vOld ~= vNew then
      -- Tabelas: compara por referência para detetar mudança
      -- (O store usa M.copy antes de mudar, por isso referências diferentes = mudança)
      result.changed[k] = { old = vOld, new = vNew }
      result.isEmpty = false
    end
  end

  -- Verifica o que foi removido
  for k, vOld in pairs(old) do
    if new[k] == nil then
      result.removed[k] = vOld
      result.isEmpty    = false
    end
  end

  return result
end

function M.deepDiff(old, new, _path, _results, _depth)
  _path    = _path or ""
  _results = _results or {}
  _depth   = _depth or 0

  if _depth > SConst.LIMIT.SNAPSHOT_DEPTH then return _results end

  if type(old) ~= "table" or type(new) ~= "table" then
    if old ~= new then
      _results[#_results + 1] = { path = _path, old = old, new = new }
    end
    return _results
  end

  -- Chaves em new
  for k, vNew in pairs(new) do
    local p = _path == "" and tostring(k) or (_path .. "." .. tostring(k))
    local vOld = old[k]
    if vOld == nil then
      _results[#_results + 1] = { path = p, old = nil, new = vNew }
    elseif type(vNew) == "table" and type(vOld) == "table" then
      M.deepDiff(vOld, vNew, p, _results, _depth + 1)
    elseif vOld ~= vNew then
      _results[#_results + 1] = { path = p, old = vOld, new = vNew }
    end
  end

  -- Chaves removidas
  for k, vOld in pairs(old) do
    if new[k] == nil then
      local p = _path == "" and tostring(k) or (_path .. "." .. tostring(k))
      _results[#_results + 1] = { path = p, old = vOld, new = nil }
    end
  end

  return _results
end

-- ── Igualdade profunda ────────────────────────────────────────────────────────

function M.equal(a, b, _depth)
  _depth = _depth or 0
  if _depth > SConst.LIMIT.SNAPSHOT_DEPTH then return a == b end

  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end

  -- Verifica todas as chaves de a em b
  for k, v in pairs(a) do
    if not M.equal(v, b[k], _depth + 1) then return false end
  end
  -- Verifica se b tem chaves extra
  for k in pairs(b) do
    if a[k] == nil then return false end
  end

  return true
end

-- ── Histórico (undo stack) ────────────────────────────────────────────────────

-- Uso:
--   local history = M.history(16)      -- máximo 16 snapshots
--   history:push(M.copy(state))
--   local prev = history:undo()               -- retorna snapshot anterior
--   local next = history:redo()               -- retorna snapshot seguinte
function M.history(maxSize)
  maxSize      = maxSize or 16
  local stack  = {}
  local cursor = 0 -- posição atual no histórico (0 = vazio)

  local h      = {}

  function h:push(snap)
    -- Descarta "futuro" ao empurrar novo estado
    while #stack > cursor do table.remove(stack) end
    stack[#stack + 1] = snap
    cursor = #stack
    -- Limita tamanho
    if #stack > maxSize then
      table.remove(stack, 1)
      cursor = #stack
    end
  end

  function h:undo()
    if cursor <= 1 then return nil end
    cursor = cursor - 1
    return stack[cursor]
  end

  function h:redo()
    if cursor >= #stack then return nil end
    cursor = cursor + 1
    return stack[cursor]
  end

  function h:canUndo() return cursor > 1 end

  function h:canRedo() return cursor < #stack end

  function h:size() return #stack end

  function h:clear()
    stack = {}
    cursor = 0
  end

  return h
end

--#endregion

return M
