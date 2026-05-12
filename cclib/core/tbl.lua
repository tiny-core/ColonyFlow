-- =====================================================================================================================
-- Arquivo: cclib/core/tbl.lua
-- Descrição: Utilitários funcionais e estruturais para tabelas Lua.
--            Distingue arrays (ipairs) de dicts (pairs) onde relevante.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Tbl
local M = {}

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.copy(orig)
  if type(orig) ~= "table" then return orig end
  local copy = {}
  for k, v in pairs(orig) do copy[k] = v end
  return setmetatable(copy, getmetatable(orig))
end

function M.deepCopy(orig, _depth)
  _depth = _depth or 0
  if _depth > 32 then return orig end   -- proteção anti-ciclo

  local copy
  if type(orig) == "table" then
    copy = {}
    for k, v in pairs(orig) do
      copy[M.deepCopy(k, _depth + 1)] = M.deepCopy(v, _depth + 1)
    end
    setmetatable(copy, getmetatable(orig))
  else
    copy = orig
  end
  return copy
end

function M.merge(...)
  local result = {}
  for i = 1, select("#", ...) do
    local t = select(i, ...)
    if type(t) == "table" then
      for k, v in pairs(t) do result[k] = v end
    end
  end
  return result
end

-- Merge profundo: tabelas aninhadas são merged recursivamente
function M.deepMerge(base, override)
  local result = M.deepCopy(base)
  if type(override) ~= "table" then return result end
  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = M.deepMerge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

function M.map(t, fn)
  local result = {}
  for i, v in ipairs(t) do result[i] = fn(v, i) end
  return result
end

function M.filter(t, fn)
  local result = {}
  for _, v in ipairs(t) do
    if fn(v) then result[#result + 1] = v end
  end
  return result
end

function M.reduce(t, fn, init)
  local acc = init
  for i, v in ipairs(t) do acc = fn(acc, v, i) end
  return acc
end

function M.forEach(t, fn)
  for i, v in ipairs(t) do fn(v, i) end
end

function M.find(t, fn)
  for i, v in ipairs(t) do
    if fn(v, i) then return v, i end
  end
  return nil, nil
end

function M.indexOf(t, value)
  for i, v in ipairs(t) do
    if v == value then return i end
  end
  return nil
end

function M.any(t, fn)
  for _, v in ipairs(t) do
    if fn(v) then return true end
  end
  return false
end

function M.all(t, fn)
  for _, v in ipairs(t) do
    if not fn(v) then return false end
  end
  return true
end

function M.flatten(t)
  local result = {}
  for _, v in ipairs(t) do
    if type(v) == "table" then
      for _, inner in ipairs(v) do result[#result + 1] = inner end
    else
      result[#result + 1] = v
    end
  end
  return result
end

function M.slice(t, from, to)
  local result = {}
  to = to or #t
  if from < 0 then from = math.max(1, #t + from + 1) end
  for i = from, to do result[#result + 1] = t[i] end
  return result
end

function M.reverse(t)
  local result = {}
  for i = #t, 1, -1 do result[#result + 1] = t[i] end
  return result
end

function M.unique(t)
  local seen   = {}
  local result = {}
  for _, v in ipairs(t) do
    if not seen[v] then
      seen[v] = true
      result[#result + 1] = v
    end
  end
  return result
end

function M.groupBy(t, fn)
  local result = {}
  for _, v in ipairs(t) do
    local key = fn(v)
    if not result[key] then result[key] = {} end
    result[key][#result[key] + 1] = v
  end
  return result
end

function M.zip(a, b)
  local result = {}
  local len    = math.min(#a, #b)
  for i = 1, len do result[i] = { a[i], b[i] } end
  return result
end

function M.insert(t, pos, value)
  table.insert(t, pos, value)
  return t
end

function M.remove(t, pos)
  return table.remove(t, pos)
end

function M.removeValue(t, value)
  for i, v in ipairs(t) do
    if v == value then
      table.remove(t, i)
      return true
    end
  end
  return false
end

function M.keys(t)
  local result = {}
  for k in pairs(t) do result[#result + 1] = k end
  return result
end

function M.values(t)
  local result = {}
  for _, v in pairs(t) do result[#result + 1] = v end
  return result
end

function M.entries(t)
  local result = {}
  for k, v in pairs(t) do result[#result + 1] = { k, v } end
  return result
end

function M.invert(t)
  local result = {}
  for k, v in pairs(t) do result[v] = k end
  return result
end

function M.filterDict(t, fn)
  local result = {}
  for k, v in pairs(t) do
    if fn(v, k) then result[k] = v end
  end
  return result
end

function M.mapDict(t, fn)
  local result = {}
  for k, v in pairs(t) do result[k] = fn(v, k) end
  return result
end

function M.isEmpty(t)
  return next(t) == nil
end

function M.count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

function M.contains(t, value)
  for _, v in pairs(t) do
    if v == value then return true end
  end
  return false
end

function M.hasKey(t, key)
  return t[key] ~= nil
end

function M.sortedPairs(t, fn)
  local keys = M.keys(t)
  table.sort(keys, fn)
  local i = 0
  return function()
    i = i + 1
    local k = keys[i]
    if k ~= nil then return k, t[k] end
  end
end

--#endregion

return M
