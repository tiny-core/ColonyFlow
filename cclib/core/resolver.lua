-- =====================================================================================================================
-- Arquivo: cclib/core/Resolver.lua
-- Descrição: Execução protegida com callbacks de sucesso e erro.
--            API única: Result.try(fn, { onSuccess, onError })
--            fn não recebe argumentos — usa closure para capturar valores externos.
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Resolver
local M = {}

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.try(fn, callbacks)
  if type(fn) ~= "function" then
    error("[Result.try] fn deve ser function, recebeu " .. type(fn), 2)
  end
  callbacks = callbacks or {}

  local ok, val = pcall(fn)

  if ok then
    if type(callbacks.onSuccess) == "function" then
      callbacks.onSuccess(val)
    end
  else
    if type(callbacks.onError) == "function" then
      callbacks.onError(tostring(val))
    end
  end
end

--#endregion

return M
