-- =====================================================================================================================
-- Arquivo: cclib/core/M.lua
-- Descrição: Monad de resultado Ok/Err para tratamento explícito de erros.
--            Evita o padrão frágil de "nil, mensagem_de_erro" do Lua.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.ResultModule
local M         = {}

--#endregion

--#region Propriedades privadas ----------------------------------------------------------------------------------------

local OkMeta    = {}
OkMeta.__index  = OkMeta
OkMeta.__name   = "Ok"

local ErrMeta   = {}
ErrMeta.__index = ErrMeta
ErrMeta.__name  = "Err"

--#endregion

--#region Métodos privados ---------------------------------------------------------------------------------------------

function OkMeta:isOk() return true end

function OkMeta:isErr() return false end

function OkMeta:unwrap()
  return self._value
end

function OkMeta:unwrapErr()
  error("Chamou unwrapErr() num Ok: " .. tostring(self._value), 2)
end

function OkMeta:unwrapOr(_default)
  return self._value
end

function OkMeta:expect(_msg)
  return self._value
end

-- Transforma o valor interno se Ok
function OkMeta:map(fn)
  local ok, val = pcall(fn, self._value)
  if ok then
    return M.ok(val)
  else
    return M.err(val)
  end
end

-- Transforma o erro se Err (não faz nada se Ok)
function OkMeta:mapErr(_fn)
  return self
end

-- Encadeia operações que retornam Result
function OkMeta:andThen(fn)
  return fn(self._value)
end

-- Fallback se Err (não faz nada se Ok)
function OkMeta:orElse(_fn)
  return self
end

-- Executa side-effect sem modificar o resultado
function OkMeta:tap(fn)
  fn(self._value)
  return self
end

function OkMeta:__tostring()
  return ("Ok(%s)"):format(tostring(self._value))
end

function ErrMeta:isOk() return false end

function ErrMeta:isErr() return true end

function ErrMeta:unwrap()
  error("Chamou unwrap() num Err: " .. tostring(self._error), 2)
end

function ErrMeta:unwrapErr()
  return self._error
end

function ErrMeta:unwrapOr(default)
  return default
end

function ErrMeta:expect(msg)
  error(msg .. ": " .. tostring(self._error), 2)
end

function ErrMeta:map(_fn)
  return self
end

function ErrMeta:mapErr(fn)
  local ok, val = pcall(fn, self._error)
  if ok then
    return M.err(val)
  else
    return M.err(val)
  end
end

function ErrMeta:andThen(_fn)
  return self
end

function ErrMeta:orElse(fn)
  return fn(self._error)
end

function ErrMeta:tap(_fn)
  return self
end

function ErrMeta:__tostring()
  return ("Err(%s)"):format(tostring(self._error))
end

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

-- ── Construtores ─────────────────────────────────────────────────────────────

function M.ok(value)
  return setmetatable({ _value = value }, OkMeta)
end

function M.err(err)
  return setmetatable({ _error = err }, ErrMeta)
end

-- ── Utilitários ──────────────────────────────────────────────────────────────

-- Envolve uma chamada de função num Result automaticamente
-- M.try(fn, args...) → Ok(retorno) ou Err(mensagem de erro)
function M.try(fn, ...)
  local ok, val = pcall(fn, ...)
  if ok then
    return M.ok(val)
  else
    return M.err(val)
  end
end

-- Converte o padrão Lua de "valor, erro" para Result
-- M.from(io.open("/ficheiro", "r"))  → Ok(handle) ou Err("mensagem")
function M.from(value, err)
  if value ~= nil then
    return M.ok(value)
  else
    return M.err(err or "erro desconhecido")
  end
end

-- Combina múltiplos Results: retorna o primeiro Err, ou Ok com array de valores
function M.all(list)
  local values = {}
  for i, r in ipairs(list) do
    if r:isErr() then return r end
    values[i] = r:unwrap()
  end
  return M.ok(values)
end

-- Verifica se um valor é um Result (Ok ou Err)
function M.isResult(v)
  if type(v) ~= "table" then return false end
  local mt = getmetatable(v)
  return mt == OkMeta or mt == ErrMeta
end

--#endregion

return M
