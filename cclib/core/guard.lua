-- =====================================================================================================================
-- Arquivo: cclib/core/Guard.lua
-- Descrição: Validação de tipos e argumentos em tempo de execução.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

local GLang = require("cclib.lang.init")

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Guard
local M = {}

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

-- ── Primitivos ───────────────────────────────────────────────────────────────

function M.isString(v, name)
  if type(v) ~= "string" then
    -- error(("[Guard] '%s' deve ser string, recebeu %s"):format(name or "?", type(v)), 2)
    error(GLang.t("cclib.guard.must_be_string", name, type(v)), 2)
  end
  return v
end

function M.isNumber(v, name)
  if type(v) ~= "number" then
    -- error(("[Guard] '%s' deve ser number, recebeu %s"):format(name or "?", type(v)), 2)
    error(GLang.t("cclib.guard.must_be_number", name, type(v)), 2)
  end
  return v
end

function M.isInteger(v, name)
  v = M.isNumber(v, name)
  if v ~= math.floor(v) then
    -- error(("[Guard] '%s' deve ser integer, recebeu %s"):format(name or "?", tostring(v)), 2)
    error(GLang.t("cclib.guard.must_be_integer", name, type(v)), 2)
  end
  return v
end

function M.isBoolean(v, name)
  if type(v) ~= "boolean" then
    -- error(("[Guard] '%s' deve ser boolean, recebeu %s"):format(name or "?", type(v)), 2)
    error(GLang.t("cclib.guard.must_be_boolean", name, type(v)), 2)
  end
  return v
end

function M.isTable(v, name)
  if type(v) ~= "table" then
    -- error(("[Guard] '%s' deve ser table, recebeu %s"):format(name or "?", type(v)), 2)
    error(GLang.t("cclib.guard.must_be_table", name, type(v)), 2)
  end
  return v
end

function M.isFunction(v, name)
  if type(v) ~= "function" then
    -- error(("[Guard] '%s' deve ser function, recebeu %s"):format(name or "?", type(v)), 2)
    error(GLang.t("cclib.guard.must_be_function", name, type(v)), 2)
  end
  return v
end

-- ── Nil ──────────────────────────────────────────────────────────────────────

function M.notNil(v, name)
  if v == nil then
    -- error(("[Guard] '%s' não pode ser nil"):format(name or "?"), 2)
    error(GLang.t("cclib.guard.must_not_be_nil", name, type(v)), 2)
  end
  return v
end

function M.isNil(v, name)
  if v ~= nil then
    -- error(("[Guard] '%s' deve ser nil, recebeu %s"):format(name or "?", type(v)), 2)
    error(GLang.t("cclib.guard.must_be_nil", name, type(v)), 2)
  end
end

-- ── Intervalos e conjuntos ───────────────────────────────────────────────────

function M.range(v, min, max, name)
  v = M.isNumber(v, name)
  if v < min or v > max then
    -- error(("[Guard] '%s' deve estar entre %s e %s, recebeu %s"):format(name or "?", min, max, v), 2)
    error(GLang.t("cclib.guard.must_be_between", name or "?", min, max, v), 2)
  end
  return v
end

function M.min(v, minimum, name)
  v = M.isNumber(v, name)
  if v < minimum then
    -- error(("[Guard] '%s' deve ser >= %s, recebeu %s"):format(name or "?", minimum, v), 2)
    error(GLang.t("cclib.guard.must_be_greater_or_equal", name or "?", minimum, v), 2)
  end
  return v
end

function M.max(v, maximum, name)
  v = M.isNumber(v, name)
  if v > maximum then
    -- error(("[Guard] '%s' deve ser <= %s, recebeu %s"):format(name or "?", maximum, v), 2)
    error(GLang.t("cclib.guard.must_be_less_or_equal", name or "?", maximum, v), 2)
  end
  return v
end

function M.positive(v, name)
  v = M.isNumber(v, name)
  if v <= 0 then
    -- error(("[Guard] '%s' deve ser > 0, recebeu %s"):format(name or "?", v), 2)
    error(GLang.t("cclib.guard.must_be_greater_zero", name or "?", v), 2)
  end
  return v
end

function M.oneOf(v, list, name)
  for _, allowed in ipairs(list) do
    if v == allowed then return v end
  end
  local opts = {}
  for _, a in ipairs(list) do opts[#opts + 1] = tostring(a) end
  -- error(("[Guard] '%s' deve ser um de [%s], recebeu '%s'"):format(name or "?", table.concat(opts, ", "), tostring(v)), 2)
  error(GLang.t("cclib.guard.must_be_one_of", name or "?", table.concat(opts, ", "), tostring(v)), 2)
end

-- ── Strings ──────────────────────────────────────────────────────────────────

function M.nonEmpty(v, name)
  v = M.isString(v, name)
  if v == "" then
    -- error(("[Guard] '%s' não pode ser string vazia"):format(name or "?"), 2)
    error(GLang.t("cclib.guard.must_not_be_empty", name or "?"), 2)
  end
  return v
end

function M.maxLen(v, max, name)
  v = M.isString(v, name)
  if #v > max then
    -- error(("[Guard] '%s' não pode ter mais de %d chars, tem %d"):format(name or "?", max, #v), 2)
    error(GLang.t("cclib.guard.must_not_be_max_char", name or "?", max, #v), 2)
  end
  return v
end

-- ── Opcional ─────────────────────────────────────────────────────────────────
-- Envolve qualquer guard para aceitar nil sem erro.
--
-- Uso:
--   M.optional(M.isString)(v, "label")
--   → OK se v for nil ou string, erro se for number, table, etc.

function M.optional(fn)
  return function(v, name)
    if v == nil then return nil end
    return fn(v, name)
  end
end

-- ── Props de componentes ──────────────────────────────────────────────────────
-- Valida uma tabela de props contra um schema de tipos.
--
-- Uso:
--   M.props(props, {
--     label  = M.isString,
--     width  = M.isNumber,
--     onClick = M.optional(M.isFunction),
--   })

function M.props(props, schema)
  props = M.isTable(props, "props")
  schema = M.isTable(schema, "schema")
  for key, validator in pairs(schema) do
    local ok, err = pcall(validator, props[key], key)
    if not ok then
      error(("[Guard.props] " .. err):gsub("%[Guard%] ", ""), 2)
    end
  end
  return props
end

--#endregion

return M
