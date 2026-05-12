---@meta
---@version 1.0.0
-- cclib / types / core.fmt.d.lua
-- Definições de tipo para core/fmt.lua

---@class CCLib.Fmt
local Fmt = {}

-- ── Números ──────────────────────────────────────────────────────────────────

---Formata inteiro com separador de milhar.
---
--- ```lua
--- Fmt.number(1234567)       -- "1,234,567"
--- Fmt.number(1234567, ".")  -- "1.234.567"
--- ```
---@param n number
---@param sep? string -- Separador (default `","`)
---@return string
function Fmt.number(n, sep) end

--- Formata float com casas decimais fixas.
---
--- ```lua
---  M.float(3.14159, 2) → "3.14"
--- ```
---@param n number
---@param decimals? integer -- (default 2)
---@return string
function Fmt.float(n, decimals) end

--- Formata como percentagem com símbolo `%`.
---
--- ```lua
--- M.percent(67.5)   → "67.5%"
--- M.percent(0.5, 0) → "1%"    (quando n já é 0..100)
--- ```
---@param n number -- Valor em 0..100
---@param decimals? integer -- (default 1)
---@return string
function Fmt.percent(n, decimals) end

--- Barra de progresso em texto.
---
--- ```lua
--- Fmt.bar(0.6, 10)           -- "[██████ ]"
--- Fmt.bar(0.6, 10, "#", "-") -- "[######----]"
--- ```
---@param ratio number -- Progresso em [0..1]
---@param width integer -- Largura da barra (entre os colchetes)
---@param fill? string -- Caractere de preenchimento (default `█`)
---@param empty? string -- Caractere de vazio (default `" "`)
---@return string
function Fmt.bar(ratio, width, fill, empty) end

-- ── Bytes ─────────────────────────────────────────────────────────────────────

--- Formata bytes em unidade legível (B, KB, MB, GB).
---
--- ```lua
--- M.bytes(1536) → "1.5 KB"
--- ```
---@param n integer
---@return string
function Fmt.bytes(n) end

-- ── Duração ───────────────────────────────────────────────────────────────────

--- Formata duração em segundos para texto legível.
---
--- ```lua
--- Fmt.duration(90)    -- "1m 30s"
--- Fmt.duration(3670)  -- "1h 1m"
--- Fmt.duration(90000) -- "1d 1h"
--- ```
---@param seconds number
---@return string
function Fmt.duration(seconds) end

--- Formata em HH:MM:SS.
--- ```lua
--- M.clock(3670) → "01:01:10"
--- ```
---@param seconds number
---@return string
function Fmt.clock(seconds) end

-- ── Tempo Minecraft ───────────────────────────────────────────────────────────

--- Converte ticks do jogo (0..24000) para hora em formato 12h.
---
--- ```lua
--- Fmt.mcTime(6000)  -- "12:00 PM" (meio-dia)
--- Fmt.mcTime(0)     -- " 6:00 AM" (amanhecer)
--- ```
---@param ticks integer Ticks do jogo (os.time() retorna este valor)
---@return string
function Fmt.mcTime(ticks) end

--- Retorna a fase do dia a partir dos ticks.
---@param ticks integer
---@return "Day" | "Sunset" | "Night" | "Sunrise"
function Fmt.mcPhase(ticks) end

-- ── Pluralização ─────────────────────────────────────────────────────────────

--- Pluraliza automaticamente.
---
--- ```lua
--- Fmt.plural(1, "item")           -- "1 item"
--- Fmt.plural(3, "item")           -- "3 items"
--- Fmt.plural(3, "item", "itens")  -- "3 itens"
--- ```
---@param n number
---@param singular string
---@param plural? string Forma plural (default: singular + "s")
---@return string
function Fmt.plural(n, singular, plural) end

-- ── Padding ───────────────────────────────────────────────────────────────────

--- Número com zeros à esquerda.
---
--- ```lua
--- Fmt.pad(5, 3) -- "005"
--- ```
---@param n integer
---@param width integer
---@return string
function Fmt.pad(n, width) end

-- ── Boolean ──────────────────────────────────────────────────────────────────

--- Converte boolean para string personalizada.
---
--- ```lua
--- Fmt.bool(true)                -- "Yes"
--- Fmt.bool(false, "On", "Off")  -- "Off"
--- ```
---@param v boolean
---@param trueStr? string -- (default `"Yes"`)
---@param falseStr? string -- (default `"No"`)
---@return string
function Fmt.bool(v, trueStr, falseStr) end

-- ── Debug ─────────────────────────────────────────────────────────────────────

--- Serializa qualquer valor para string legível (para logs/debug).
--- Não usa textutils — funciona em qualquer contexto Lua.
---@param t any
---@param depth? integer -- Profundidade máxima (default 3)
---@return string
function Fmt.table(t, depth) end
