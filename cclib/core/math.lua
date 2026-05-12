-- =====================================================================================================================
-- Arquivo: cclib/core/math.lua
-- Descrição: Utilitários matemáticos que complementam a biblioteca padrão `math` do Lua.
--            Não substitui `math` — usa o nome local `M` para não colidir.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Math
local M = {}

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.clamp(v, min, max)
  if v < min then return min end
  if v > max then return max end
  return v
end

function M.lerp(a, b, t)
  return a + (b - a) * t
end

function M.map(v, inMin, inMax, outMin, outMax)
  if inMax == inMin then return outMin end
  return outMin + (v - inMin) * (outMax - outMin) / (inMax - inMin)
end

function M.round(v)
  return math.floor(v + 0.5)
end

function M.roundTo(v, decimals)
  local f = 10 ^ decimals
  return math.floor(v * f + 0.5) / f
end

-- Sinal: 1, -1 ou 0
function M.sign(v)
  if v > 0 then
    return 1
  elseif v < 0 then
    return -1
  else
    return 0
  end
end

function M.isInt(v)
  return type(v) == "number" and v == math.floor(v)
end

function M.percent(value, total)
  if total == 0 then return 0 end
  return M.clamp((value / total) * 100, 0, 100)
end

function M.normalize(value, min, max)
  if max == min then return 0 end
  return M.clamp((value - min) / (max - min), 0, 1)
end

function M.sum(t)
  local s = 0
  for _, v in ipairs(t) do s = s + v end
  return s
end

function M.average(t)
  if #t == 0 then return 0 end
  return M.sum(t) / #t
end

function M.minOf(t)
  if #t == 0 then return nil end
  local m = t[1]
  for i = 2, #t do if t[i] < m then m = t[i] end end
  return m
end

function M.maxOf(t)
  if #t == 0 then return nil end
  local m = t[1]
  for i = 2, #t do if t[i] > m then m = t[i] end end
  return m
end

function M.bounds(t)
  if #t == 0 then return nil, nil end
  local mn, mx = t[1], t[1]
  for i = 2, #t do
    if t[i] < mn then mn = t[i] end
    if t[i] > mx then mx = t[i] end
  end
  return mn, mx
end

function M.median(t)
  if #t == 0 then return 0 end
  local sorted = {}
  for i, v in ipairs(t) do sorted[i] = v end
  table.sort(sorted)
  local mid = math.floor(#sorted / 2)
  if #sorted % 2 == 1 then
    return sorted[mid + 1]
  else
    return (sorted[mid] + sorted[mid + 1]) / 2
  end
end

function M.easeInOut(t)
  t = M.clamp(t, 0, 1)
  return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
end

function M.easeOut(t)
  t = M.clamp(t, 0, 1)
  return 1 - (1 - t) * (1 - t)
end

function M.snapToGrid(v, gridSize)
  return M.round(v / gridSize) * gridSize
end

function M.distance(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

function M.inRect(px, py, x, y, w, h)
  return px >= x and px < x + w and py >= y and py < y + h
end

--#endregion

return M
