-- =====================================================================================================================
-- Arquivo: cclib/core/fmt.lua
-- Descrição: Formatação de valores para exibição em UI.
--            Converte números, bytes, tempo MC, durações e booleans em strings legíveis.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Fmt
local M = {}

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------


-- Inteiro com separador de milhar
-- M.number(1234567) → "1,234,567"
-- M.number(1234567, ".") → "1.234.567"
function M.number(n, sep)
  sep = sep or ","
  local negative = n < 0
  local s = tostring(math.floor(math.abs(n)))
  local result = ""
  local count  = 0

  for i = #s, 1, -1 do
    if count > 0 and count % 3 == 0 then
      result = sep .. result
    end
    result = s:sub(i, i) .. result
    count  = count + 1
  end

  return negative and ("-" .. result) or result
end

function M.float(n, decimals)
  decimals = decimals or 2
  return string.format("%." .. decimals .. "f", n)
end

function M.percent(n, decimals)
  decimals = decimals or 1
  return string.format("%." .. decimals .. "f%%", n)
end

function M.bar(ratio, width, fill, empty)
  fill  = fill  or "\xDB"   -- █
  empty = empty or " "
  ratio = math.max(0, math.min(1, ratio))
  local filled = math.floor(ratio * width + 0.5)
  return "[" .. string.rep(fill, filled) .. string.rep(empty, width - filled) .. "]"
end

function M.bytes(n)
  if n < 1024 then
    return n .. " B"
  elseif n < 1024 * 1024 then
    return string.format("%.1f KB", n / 1024)
  elseif n < 1024 * 1024 * 1024 then
    return string.format("%.1f MB", n / (1024 * 1024))
  else
    return string.format("%.2f GB", n / (1024 * 1024 * 1024))
  end
end

function M.duration(seconds)
  seconds = math.floor(seconds)
  if seconds < 0 then seconds = 0 end

  if seconds < 60 then
    return seconds .. "s"
  elseif seconds < 3600 then
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return s > 0 and (m .. "m " .. s .. "s") or (m .. "m")
  elseif seconds < 86400 then
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    return m > 0 and (h .. "h " .. m .. "m") or (h .. "h")
  else
    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    return h > 0 and (d .. "d " .. h .. "h") or (d .. "d")
  end
end

function M.clock(seconds)
  seconds = math.floor(math.max(0, seconds))
  local h = math.floor(seconds / 3600)
  local m = math.floor((seconds % 3600) / 60)
  local s = seconds % 60
  return string.format("%02d:%02d:%02d", h, m, s)
end

function M.mcTime(ticks)
  -- ticks 0 = 6:00 AM no jogo
  local totalMinutes = math.floor((ticks / 1000) * 60)
  local hour   = math.floor(totalMinutes / 60 + 6) % 24
  local minute = totalMinutes % 60
  local ampm   = hour >= 12 and "PM" or "AM"
  local h12    = hour % 12
  if h12 == 0 then h12 = 12 end
  return string.format("%2d:%02d %s", h12, minute, ampm)
end

function M.mcPhase(ticks)
  if ticks < 13000 then return "Day"
  elseif ticks < 13800 then return "Sunset"
  elseif ticks < 22200 then return "Night"
  else return "Sunrise" end
end

function M.plural(n, singular, plural)
  plural = plural or (singular .. "s")
  return n == 1 and (n .. " " .. singular) or (n .. " " .. plural)
end

function M.pad(n, width)
  return string.format("%0" .. width .. "d", n)
end

function M.bool(v, trueStr, falseStr)
  trueStr  = trueStr  or "Yes"
  falseStr = falseStr or "No"
  return v and trueStr or falseStr
end

function M.table(t, depth)
  depth = depth or 0
  if depth > 3 then return "{...}" end
  if type(t) ~= "table" then return tostring(t) end

  local parts = {}
  local isArray = #t > 0

  if isArray then
    for i, v in ipairs(t) do
      if type(v) == "table" then
        parts[i] = M.table(v, depth + 1)
      else
        parts[i] = tostring(v)
      end
    end
    return "{" .. table.concat(parts, ", ") .. "}"
  else
    for k, v in pairs(t) do
      local key = type(k) == "string" and k or ("[" .. tostring(k) .. "]")
      local val = type(v) == "table" and M.table(v, depth + 1) or tostring(v)
      parts[#parts + 1] = key .. "=" .. val
    end
    return "{" .. table.concat(parts, ", ") .. "}"
  end
end

--#endregion

return M
