---@meta
---@version 1.0.0

-- cclib / types / core.guard.d.lua
-- Definições de tipo para core/guard.lua
---@alias CCLib.GuardFn fun(v: any, name?: string): any
---Um validator é qualquer função que recebe um valor e um nome opcional,
---e lança error() se inválido ou retorna o valor se válido.
---@class CCLib.Guard
local Guard = {}

-- ── Primitivos ───────────────────────────────────────────────────────────────

---@param v any
---@param name? string -- Nome do parâmetro (para mensagens de erro)
---@return string
---@nodiscard
function Guard.isString(v, name)
end

---@param v any
---@param name? string
---@return number
---@nodiscard
function Guard.isNumber(v, name)
end

---@param v any
---@param name? string
---@return integer
---@nodiscard
function Guard.isInteger(v, name)
end

---@param v any
---@param name? string
---@return boolean
---@nodiscard
function Guard.isBoolean(v, name)
end

---@param v any
---@param name? string
---@return table
---@nodiscard
function Guard.isTable(v, name)
end

---@param v any
---@param name? string
---@return function
---@nodiscard
function Guard.isFunction(v, name)
end

-- ── Nil ──────────────────────────────────────────────────────────────────────

---Garante que o valor não é nil. Retorna o valor se válido.
---@param v any
---@param name? string
---@return any
---@nodiscard
function Guard.notNil(v, name)
end

---Garante que o valor é nil.
---@param v any
---@param name? string
function Guard.isNil(v, name)
end

-- ── Intervalos ───────────────────────────────────────────────────────────────

---@param v any
---@param min number
---@param max number
---@param name? string
---@return number
---@nodiscard
function Guard.range(v, min, max, name)
end

---@param v any
---@param minimum number
---@param name?string
---@return number
---@nodiscard
function Guard.min(v, minimum, name)
end

---@param v any
---@param maximum number
---@param name?string
---@return number
---@nodiscard
function Guard.max(v, maximum, name)
end

---@param v any
---@param name? string
---@return number
---@nodiscard
function Guard.positive(v, name)
end

---Verifica se o valor é um dos permitidos na lista.
---@param v any
---@param list any[] -- Lista de valores permitidos
---@param name? string
---@return any
---@nodiscard
function Guard.oneOf(v, list, name)
end

-- ── Strings ──────────────────────────────────────────────────────────────────

---@param v any
---@param name? string
---@return string
---@nodiscard
function Guard.nonEmpty(v, name)
end

---@param v any
---@param max integer -- Comprimento máximo permitido
---@param name? string
---@return string
---@nodiscard
function Guard.maxLen(v, max, name)
end

-- ── Wrappers ─────────────────────────────────────────────────────────────────

---Envolve qualquer guard para aceitar nil sem lançar erro.
---
---```lua
---Guard.optional(Guard.isString)(valor, "label")
---```
---@param fn CCLib.GuardFn
---@return CCLib.GuardFn
function Guard.optional(fn)
end

---Valida uma tabela de props contra um schema de validadores.
---Lança error() para o primeiro campo que falhar.
---
---```lua
---Guard.props(props, {
--- label= Guard.isString,
--- width= Guard.isNumber,
--- onClick = Guard.optional(Guard.isFunction),
---})
---```
---@param props table -- Tabela de props a validar
---@param schema table<string, CCLib.GuardFn> -- Mapa campo → validador
---@return table -- Retorna `props` se tudo válido
function Guard.props(props, schema)
end
