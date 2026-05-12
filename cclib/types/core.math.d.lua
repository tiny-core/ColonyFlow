---@meta
---@version 1.0.0
-- cclib / types / core.math.d.lua
-- Definições de tipo para core/math.lua

---@class CCLib.Math
local Math = {}

-- ── Básicos ──────────────────────────────────────────────────────────────────

--- Limita `v` ao intervalo `[min, max]`.
---@param v number
---@param min number
---@param max number
---@return number
function Math.clamp(v, min, max) end

--- Interpolação linear entre `a` e `b` com fator `t` em [0, 1].
---@param a number
---@param b number
---@param t number
---@return number
function Math.lerp(a, b, t) end

--- Mapeia `v` de `[inMin..inMax]` para `[outMin..outMax]`.
---@param v number
---@param inMin number
---@param inMax number
---@param outMin number
---@param outMax number
---@return number
function Math.map(v, inMin, inMax, outMin, outMax) end

--- Arredonda para o inteiro mais próximo.
---@param v number
---@return integer
function Math.round(v) end

--- Arredonda para `decimals` casas decimais.
---@param v number
---@param decimals integer
---@return number
function Math.roundTo(v, decimals) end

--- Retorna 1, -1 ou 0 conforme o sinal.
---@param v number
---@return -1 | 0 | 1
function Math.sign(v) end

--- Retorna true se `v` é um número inteiro.
---@param v number
---@return boolean
function Math.isInt(v) end

-- ── Percentagem ──────────────────────────────────────────────────────────────

--- Percentagem de `value` em relação a `total`. Resultado em [0..100].
---@param value number
---@param total number
---@return number
function Math.percent(value, total) end

--- Normaliza `value` para [0..1] dado um intervalo `[min..max]`.
---@param value number
---@param min number
---@param max number
---@return number
function Math.normalize(value, min, max) end

-- ── Array stats ───────────────────────────────────────────────────────────────

---@param t number[]
---@return number
function Math.sum(t) end

---@param t number[]
---@return number
function Math.average(t) end

---@param t number[]
---@return number | nil
function Math.minOf(t) end

---@param t number[]
---@return number | nil
function Math.maxOf(t) end

--- Retorna mínimo e máximo numa só passagem.
---@param t number[]
---@return number | nil, number | nil
function Math.bounds(t) end

---@param t number[]
---@return number
function Math.median(t) end

-- ── Easing ───────────────────────────────────────────────────────────────────

--- Suavização ease-in-out quadrática. `t` em [0..1].
---@param t number
---@return number
function Math.easeInOut(t) end

--- Suavização ease-out (desacelera no fim). `t` em [0..1].
---@param t number
---@return number
function Math.easeOut(t) end

-- ── Posição / UI ─────────────────────────────────────────────────────────────

--- Arredonda `v` para o múltiplo de `gridSize` mais próximo.
---@param v number
---@param gridSize number
---@return number
function Math.snapToGrid(v, gridSize) end

--- Distância euclidiana entre dois pontos.
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function Math.distance(x1, y1, x2, y2) end

--- Retorna true se o ponto `(px, py)` está dentro do rect `(x, y, w, h)`.
---@param px number
---@param py number
---@param x number
---@param y number
---@param w number
---@param h number
---@return boolean
function Math.inRect(px, py, x, y, w, h) end
