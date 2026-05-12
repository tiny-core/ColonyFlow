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
    -- Blocos
    BLOCK_FULL   = "\xDB",
    BLOCK_TOP    = "\xDF",
    BLOCK_BOTTOM = "\xDC",
    BLOCK_LEFT   = "\xDD",
    BLOCK_RIGHT  = "\xDE",
    SHADE_DARK   = "\xB2",
    SHADE_MED    = "\xB1",
    SHADE_LIGHT  = "\xB0",

    -- Linhas simples (box-drawing)
    LINE_H       = "\xC4",
    LINE_V       = "\xB3",
    CORNER_TL    = "\xDA",
    CORNER_TR    = "\xBF",
    CORNER_BL    = "\xC0",
    CORNER_BR    = "\xD9",
    TEE_L        = "\xC3",
    TEE_R        = "\xB4",
    TEE_T        = "\xC2",
    TEE_B        = "\xC1",
    CROSS        = "\xC5",

    -- Linhas duplas
    LINE_H2      = "\xCD",
    LINE_V2      = "\xBA",
    CORNER_TL2   = "\xC9",
    CORNER_TR2   = "\xBB",
    CORNER_BL2   = "\xC8",
    CORNER_BR2   = "\xBC",

    -- Símbolos
    BULLET       = "\x07",
    SQUARE       = "\xFE",
    DIAMOND      = "\x04",
    HEART        = "\x03",
    CLUB         = "\x05",
    SPADE        = "\x06",
    ARROW_R      = "\x10",
    ARROW_L      = "\x11",
    ARROW_UP     = "\x1E",
    ARROW_DOWN   = "\x1F",
    CHECK        = "\xFB",
    DEGREE       = "\xF8",
    PLUS_MINUS   = "\xF1",
    INFINITY     = "\xEC",
    PI           = "\xE3",
    SIGMA        = "\xE4",
    OMEGA        = "\xEA",
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
