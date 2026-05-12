---@meta
---@version 1.0.0

-- cclib / types / core.result.d.lua
-- Definições de tipo para core/result.lua
-- Usa genéricos LuaLS para preservar o tipo do valor em Ok<T> e Err<E>.

-- ── Ok<T> ────────────────────────────────────────────────────────────────────

---@class CCLib.Ok<T>: CCLib.Result<T, any>
---@field _value T

-- ── Err<E> ───────────────────────────────────────────────────────────────────

---@class CCLib.Err<E>: CCLib.Result<any, E>
---@field _error E

-- ── Result<T, E> ─────────────────────────────────────────────────────────────

---@class CCLib.Result<T, E>
local Result = {}

---@return boolean true -- se Ok, false se Err
function Result:isOk() end

---@return boolean true -- se Err, false se Ok
function Result:isErr() end

---Retorna o valor se Ok. Lança error() se Err.
---@generic T
---@return T
function Result:unwrap() end

---Retorna o erro se Err. Lança error() se Ok.
---@generic E
---@return E
function Result:unwrapErr() end

---Retorna o valor se Ok, ou `default` se Err.
---@generic T
---@param default T
---@return T
function Result:unwrapOr(default) end

---Retorna o valor se Ok, ou lança error() com `msg` se Err.
---@generic T
---@param msg string -- Mensagem de erro personalizada
---@return T
function Result:expect(msg) end

---Transforma o valor interno se Ok. Propaga Err sem modificar.
---@generic T, U, E
---@param fn fun(value: T): U
---@return CCLib.Result<U, E>
function Result:map(fn) end

---Transforma o erro interno se Err. Propaga Ok sem modificar.
---@generic T, E, F
---@param fn fun(err: E): F
---@return CCLib.Result<T, F>
function Result:mapErr(fn) end

---Encadeia operações que retornam Result. Propaga Err sem chamar `fn`.
---@generic T, U, E
---@param fn fun(value: T): CCLib.Result<U, E>
---@return CCLib.Result<U, E>
function Result:andThen(fn) end

---Fallback se Err. Propaga Ok sem chamar `fn`.
---@generic T, E
---@param fn fun(err: E): CCLib.Result<T, E>
---@return CCLib.Result<T, E>
function Result:orElse(fn) end

---Executa um side-effect sem modificar o resultado.
---@generic T
---@param fn fun(value: T)
---@return CCLib.Result<T, any>
function Result:tap(fn) end

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.ResultModule
local ResultModule = {}

---Cria um resultado de sucesso.
---@generic T
---@param value T
---@return CCLib.Ok<T>
function ResultModule.ok(value) end

---Cria um resultado de falha.
---@generic E
---@param err E
---@return CCLib.Err<E>
function ResultModule.err(err) end

---Envolve uma chamada de função num Result automaticamente.
---
---```lua
---local r = Result.try(io.open, "/ficheiro", "r")
---if r:isOk() then
--- local handle = r:unwrap()
---end
---```
---@generic T
---@param fn fun(...): T -- Função a chamar
---@param ... any -- Argumentos para a função
---@return CCLib.Ok<T> | CCLib.Err<string>
function ResultModule.try(fn, ...) end

---Converte o padrão Lua `valor, mensagem_erro` para Result.
---
---```lua
---local r = Result.from(io.open("/path", "r"))
---```
---@generic T
---@param value T | nil
---@param err? string
---@return CCLib.Ok<T> | CCLib.Err<string>
function ResultModule.from(value, err) end

---Combina múltiplos Results numa lista.
---Retorna o primeiro Err encontrado, ou Ok com array de todos os valores.
---@generic T
---@param list CCLib.Result<T, any>[]
---@return CCLib.Ok<T[]> | CCLib.Err<any>
function ResultModule.all(list) end

---Verifica se um valor qualquer é um Result (Ok ou Err).
---@param v any
---@return boolean
function ResultModule.isResult(v) end
