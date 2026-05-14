---@meta
---@version 1.0.0

-- cclib / types / core.resolver.d.lua
-- Definições de tipo para core/resolver.lua
-- Usa genéricos LuaLS para preservar o tipo do valor em Ok<T> e Err<E>.

-- ── Callbacks ─────────────────────────────────────────────────────────────────

---@class CCLib.Resolver.Callbacks<T>
---@field onSuccess? fun(data: T)      Chamado com o retorno de fn em caso de sucesso
---@field onError?   fun(err: string)  Chamado com a mensagem de erro em caso de falha

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Resolver
local Result = {}

---Executa `fn` com pcall e chama o callback apropriado.
---`fn` não recebe argumentos — usa closure para capturar valores externos.
---`onSuccess` recebe o valor de retorno de `fn`.
---`onError` recebe a mensagem de erro como string.
---Ambos os callbacks são opcionais.
---
---```lua
----- Exemplo com Persist.load
---Result.try(function()
---  local data, err = Persist.load("/data.lua")
---  if not data then error(err) end  -- propaga para onError
---  return data
---end, {
---  onSuccess = function(data)
---    store:patch(data)
---    Toast.success("Dados carregados")
---  end,
---  onError = function(err)
---    Log.error("main", "Falha: %s", err)
---  end,
---})
---
----- Sem onError (ignora falhas silenciosamente)
---Result.try(function()
---  return Persist.load("/config.lua")
---end, {
---  onSuccess = function(cfg) applyConfig(cfg) end,
---})
---
----- Sem callbacks (só executa e protege com pcall)
---Result.try(function()
---  dangerousOperation()
---end)
---```
---@generic T
---@param fn fun(): T
---@param callbacks? CCLib.Resolver.Callbacks<T>
function Result.try(fn, callbacks) end
