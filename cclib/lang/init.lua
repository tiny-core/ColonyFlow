-- =====================================================================================================================
-- Arquivo: cclib/lang/init.lua
-- Descrição: Motor de internacionalização (i18n).
-- Funcionalidades:
--   · Acesso por notação de ponto: Lang.get("ui.button.ok")
--   · Interpolação printf:         Lang.get("ui.label.page", 1, 5) → "Página 1 de 5"
--   · Fallback automático para EN  se a chave não existe no idioma ativo
--   · Merge de traduções custom    sem substituir toda a tabela
--   · Registo de novos idiomas     em runtime
--   · Reset ao idioma padrão
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Lang
local M          = {}

--#endregion

--#region Propriedades privadas ----------------------------------------------------------------------------------------

local _languages = {}      -- { [code] = tabela de traduções }
local _current   = "pt_BR" -- idioma ativo
local _fallback  = "pt_BR" -- fallback se chave não existe no ativo
local _cache     = {}      -- cache de lookups por chave (limpa em load/merge)

--#endregion

--#region Métodos privados ---------------------------------------------------------------------------------------------

local function _resolve(tbl, key)
  if type(tbl) ~= "table" then return nil end

  -- Tentativa rápida: chave sem ponto
  if not key:find(".", 1, true) then
    return tbl[key]
  end

  -- Navega pela notação de ponto
  local cursor = tbl
  for part in key:gmatch("[^%.]+") do
    if type(cursor) ~= "table" then return nil end
    cursor = cursor[part]
  end
  return cursor
end

local function _deepMerge(base, override)
  for k, v in pairs(override) do
    if type(v) == "table" and type(base[k]) == "table" then
      _deepMerge(base[k], v)
    else
      base[k] = v
    end
  end
end

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.register(code, translations)
  if type(code) ~= "string" then error("[Lang] code deve ser string", 2) end
  if type(translations) ~= "table" then error("[Lang] translations deve ser table", 2) end

  if _languages[code] then
    -- Merge profundo com as existentes
    _deepMerge(_languages[code], translations)
  else
    _languages[code] = translations
  end

  _cache = {} -- invalida cache
end

function M.load(code)
  if type(code) ~= "string" then error("[Lang] code deve ser string", 2) end

  if not _languages[code] then
    return false, ("idioma '%s' não registado"):format(code)
  end

  _current = code
  _cache   = {}
  return true
end

function M.setFallback(code)
  if type(code) ~= "string" then error("[Lang] code deve ser string", 2) end
  _fallback = code
  _cache    = {}
end

function M.get(key, ...)
  if type(key) ~= "string" then return tostring(key) end

  -- Cache hit (só sem args de formato)
  local argCount = select("#", ...)
  if argCount == 0 and _cache[key] ~= nil then
    return _cache[key]
  end

  -- Procura no idioma ativo
  local value = _resolve(_languages[_current], key)

  -- Fallback
  if value == nil and _current ~= _fallback then
    value = _resolve(_languages[_fallback], key)
  end

  -- Chave não encontrada em nenhum idioma → retorna a chave
  if value == nil then
    return key
  end

  -- Valor não-string (tabela, número, bool) → converte
  if type(value) ~= "string" then
    value = tostring(value)
  end

  -- Interpolação printf
  if argCount > 0 then
    local ok, result = pcall(string.format, value, ...)
    return ok and result or value
  end

  -- Guarda em cache (só valores sem args)
  _cache[key] = value
  return value
end

M.t = M.get

function M.has(key)
  if _resolve(_languages[_current], key) ~= nil then return true end
  if _current ~= _fallback then
    return _resolve(_languages[_fallback], key) ~= nil
  end
  return false
end

function M.merge(translations, code)
  code = code or _current
  if not _languages[code] then
    _languages[code] = {}
  end
  _deepMerge(_languages[code], translations)
  _cache = {}
end

function M.set(key, value, code)
  code = code or _current
  if not _languages[code] then _languages[code] = {} end
  _languages[code][key] = value
  _cache[key] = nil
end

function M.current()
  return _current
end

function M.available()
  local list = {}
  for code in pairs(_languages) do list[#list + 1] = code end
  table.sort(list)
  return list
end

function M.reset()
  _current = _fallback
  _cache   = {}
end

function M.clearCache()
  _cache = {}
end

function M.inspect()
  local stats = {}
  for code, tbl in pairs(_languages) do
    -- Conta chaves folha recursivamente
    local function countLeaves(t, n)
      n = n or 0
      for _, v in pairs(t) do
        if type(v) == "table" then
          n = countLeaves(v, n)
        else
          n = n + 1
        end
      end
      return n
    end
    stats[code] = countLeaves(tbl)
  end
  return {
    current   = _current,
    fallback  = _fallback,
    languages = stats,
    cacheSize = (function()
      local n = 0
      for _ in pairs(_cache) do n = n + 1 end
      return n
    end)(),
  }
end

--#endregion

return M
