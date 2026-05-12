-- =====================================================================================================================
-- Arquivo: cclib/core/str.lua
-- Descrição: Utilitários de string + caracteres especiais CP437 para CC:Tweaked.
--            CC:Tweaked usa a página de código 437 (DOS/IBM) no terminal e monitor.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Str
local M = {
  CHAR = {
    BLOCK_FULL = string.char(219),
    BLOCK_TOP = string.char(223),
    BLOCK_BOTTOM = string.char(220),
    BLOCK_LEFT = string.char(221),
    BLOCK_RIGHT = string.char(222),
    SHADE_DARK = string.char(176),
    SHADE_MED = string.char(177),
    SHADE_LIGHT = string.char(178),
    LINE_H = string.char(196),
    LINE_V = string.char(179),
    CORNER_TL = string.char(218),
    CORNER_TR = string.char(191),
    CORNER_BL = string.char(192),
    CORNER_BR = string.char(217),
    TEE_L = string.char(195),
    TEE_R = string.char(180),
    TEE_T = string.char(194),
    TEE_B = string.char(193),
    CROSS = string.char(197),
    LINE_H2 = string.char(205),
    LINE_V2 = string.char(186),
    CORNER_TL2 = string.char(201),
    CORNER_TR2 = string.char(187),
    CORNER_BL2 = string.char(200),
    CORNER_BR2 = string.char(188),
    BULLET = string.char(7),
    SQUARE = string.char(254),
    DIAMOND = string.char(4),
    HEART = string.char(3),
    CLUB = string.char(5),
    SPADE = string.char(6),
    ARROW_R = string.char(26),
    ARROW_L = string.char(27),
    ARROW_UP = string.char(24),
    ARROW_DOWN = string.char(25),
    CHECK = string.char(251),
    DEGREE = string.char(248),
    PLUS_MINUS = string.char(241),
    INFINITY = string.char(236),
    PI = string.char(227),
    SIGMA = string.char(228),
    OMEGA = string.char(234)
  }
}

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.trim(s)
  return s:match("^%s*(.-)%s*$")
end

function M.trimLeft(s)
  return s:match("^%s*(.+)$") or s
end

function M.trimRight(s)
  return s:match("^(.-)%s*$")
end

function M.split(s, sep)
  sep = sep or ","
  local result = {}
  local pattern = "([^" .. sep .. "]*)" .. sep .. "?"
  for part in s:gmatch(pattern) do
    result[#result + 1] = part
  end
  -- remove último elemento vazio que gmatch adiciona
  if #result > 0 and result[#result] == "" then
    result[#result] = nil
  end
  return result
end

function M.join(t, sep)
  sep = sep or ""
  return table.concat(t, sep)
end

function M.padLeft(s, width, char)
  char = char or " "
  s = tostring(s)
  while #s < width do s = char .. s end
  return s
end

function M.padRight(s, width, char)
  char = char or " "
  s = tostring(s)
  while #s < width do s = s .. char end
  return s
end

function M.center(s, width, char)
  char = char or " "
  s = tostring(s)
  local gap = width - #s
  if gap <= 0 then return s:sub(1, width) end
  local left  = math.floor(gap / 2)
  local right = gap - left
  return string.rep(char, left) .. s .. string.rep(char, right)
end

function M.truncate(s, width, ellipsis)
  ellipsis = ellipsis or "..."
  s = tostring(s)
  if #s <= width then return s end
  if width <= #ellipsis then return ellipsis:sub(1, width) end
  return s:sub(1, width - #ellipsis) .. ellipsis
end

function M.wrap(s, width)
  if width <= 0 then return { s } end
  local lines = {}
  local line  = ""

  for word in s:gmatch("%S+") do
    if #line == 0 then
      -- primeira palavra da linha, pode exceder se a palavra for maior que width
      if #word > width then
        -- parte a palavra
        while #word > width do
          lines[#lines + 1] = word:sub(1, width)
          word = word:sub(width + 1)
        end
        line = word
      else
        line = word
      end
    elseif #line + 1 + #word <= width then
      line = line .. " " .. word
    else
      lines[#lines + 1] = line
      line = word
    end
  end

  if #line > 0 then lines[#lines + 1] = line end
  if #lines == 0 then lines[1] = "" end
  return lines
end

function M.countLines(s, width)
  return #M.wrap(s, width)
end

function M.startsWith(s, prefix)
  return s:sub(1, #prefix) == prefix
end

function M.endsWith(s, suffix)
  if suffix == "" then return true end
  return s:sub(- #suffix) == suffix
end

function M.contains(s, sub)
  return s:find(sub, 1, true) ~= nil
end

function M.count(s, pattern)
  local n = 0
  for _ in s:gmatch(pattern) do n = n + 1 end
  return n
end

function M.replace(s, find, replace)
  return s:gsub(find:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1"), replace)
end

function M.toBool(s)
  s = M.trim(s):lower()
  return s == "true" or s == "1" or s == "yes" or s == "sim"
end

function M.isNumeric(s)
  return tonumber(s) ~= nil
end

function M.isEmpty(s)
  return s == nil or M.trim(s) == ""
end

function M.rep(s, n, sep)
  return string.rep(s, n, sep or "")
end

function M.hline(width, char)
  char = char or M.CHAR.LINE_H
  return string.rep(char, width)
end

function M.box(width, height, title)
  local C = M.CHAR
  local inner = width - 2
  local lines = {}

  -- top
  lines[1] = C.CORNER_TL .. string.rep(C.LINE_H, inner) .. C.CORNER_TR

  -- middle rows
  for i = 2, height - 1 do
    if i == 2 and title then
      lines[i] = C.LINE_V .. M.padRight(" " .. title, inner) .. C.LINE_V
    else
      lines[i] = C.LINE_V .. string.rep(" ", inner) .. C.LINE_V
    end
  end

  -- bottom
  lines[height] = C.CORNER_BL .. string.rep(C.LINE_H, inner) .. C.CORNER_BR

  return lines
end

--#endregion

return M
