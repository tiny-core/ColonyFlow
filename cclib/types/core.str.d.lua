---@meta
---@version 1.0.0

-- cclib / types / core.str.d.lua
-- Definições de tipo para core/str.lua

-- ── Tabela de caracteres CP437 ────────────────────────────────────────────────

---@class CCLib.Str.Char
---@field BLOCK_FULL    string -- █  (0xDB)
---@field BLOCK_TOP     string -- ▀  (0xDF)
---@field BLOCK_BOTTOM  string -- ▄  (0xDC)
---@field BLOCK_LEFT    string -- ▌  (0xDD)
---@field BLOCK_RIGHT   string -- ▐  (0xDE)
---@field SHADE_DARK    string -- ▓  (0xB2)
---@field SHADE_MED     string -- ▒  (0xB1)
---@field SHADE_LIGHT   string -- ░  (0xB0)
---@field LINE_H        string -- ─  (0xC4)
---@field LINE_V        string -- │  (0xB3)
---@field CORNER_TL     string -- ┌  (0xDA)
---@field CORNER_TR     string -- ┐  (0xBF)
---@field CORNER_BL     string -- └  (0xC0)
---@field CORNER_BR     string -- ┘  (0xD9)
---@field TEE_L         string -- ├  (0xC3)
---@field TEE_R         string -- ┤  (0xB4)
---@field TEE_T         string -- ┬  (0xC2)
---@field TEE_B         string -- ┴  (0xC1)
---@field CROSS         string -- ┼  (0xC5)
---@field LINE_H2       string -- ═  dupla horizontal
---@field LINE_V2       string -- ║  dupla vertical
---@field CORNER_TL2    string -- ╔
---@field CORNER_TR2    string -- ╗
---@field CORNER_BL2    string -- ╚
---@field CORNER_BR2    string -- ╝
---@field BULLET        string -- •
---@field SQUARE        string -- ■
---@field DIAMOND       string -- ◆
---@field HEART         string -- ♥
---@field CLUB          string -- ♣
---@field SPADE         string -- ♠
---@field ARROW_R       string -- ►
---@field ARROW_L       string -- ◄
---@field ARROW_UP      string -- ▲
---@field ARROW_DOWN    string -- ▼
---@field CHECK         string -- ✓
---@field DEGREE        string -- °
---@field PLUS_MINUS    string -- ±
---@field INFINITY      string -- ∞
---@field PI            string -- π
---@field SIGMA         string -- Σ
---@field OMEGA         string -- Ω

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Str
---@field CHAR CCLib.Str.Char -- Tabela de caracteres CP437 com aliases legíveis
local Str = {}

---Remove whitespace do início e fim.
---@param s string
---@return string
function Str.trim(s) end

---Remove whitespace só do início.
---@param s string
---@return string
function Str.trimLeft(s) end

---Remove whitespace só do fim.
---@param s string
---@return string
function Str.trimRight(s) end

---Divide a string pelo separador (caractere simples).
---@param s string
---@param sep? string -- Padrão separador (default `","`)
---@return string[]
function Str.split(s, sep) end

---Junta array de strings com separador.
---@param t   string[]
---@param sep? string -- (default `""`)
---@return string
function Str.join(t, sep) end

---Pad à esquerda até `width` caracteres.
---@param s string | number
---@param width integer
---@param char? string -- Caractere de preenchimento (default `" "`)
---@return string
function Str.padLeft(s, width, char) end

---Pad à direita até `width` caracteres.
---@param s string | number
---@param width integer
---@param char? string -- (default `" "`)
---@return string
function Str.padRight(s, width, char) end

---Centraliza a string em `width` caracteres.
---@param s string | number
---@param width integer
---@param char? string -- (default `" "`)
---@return string
function Str.center(s, width, char) end

---Trunca com reticências se exceder `width`.
---@param s string | number
---@param width integer
---@param ellipsis? string  (default `"..."`)
---@return string
function Str.truncate(s, width, ellipsis) end

---Quebra texto em linhas de no máximo `width` caracteres (word-wrap).
---Retorna array de strings.
---@param s string
---@param width integer
---@return string[]
function Str.wrap(s, width) end

---Conta quantas linhas `wrap()` geraria sem criá-las.
---@param s string
---@param width integer
---@return integer
function Str.countLines(s, width) end

---@param s string
---@param prefix string
---@return boolean
function Str.startsWith(s, prefix) end

---@param s string
---@param suffix string
---@return boolean
function Str.endsWith(s, suffix) end

---@param s string
---@param sub string
---@return boolean
function Str.contains(s, sub) end

---Conta ocorrências de um padrão Lua na string.
---@param s string
---@param pattern string -- Padrão Lua
---@return integer
function Str.count(s, pattern) end

---Substitui todas as ocorrências de `find` por `replace` (sem padrões Lua).
---@param s string
---@param find string
---@param replace string
---@return string
function Str.replace(s, find, replace) end

---Converte string para boolean ("true"/"1"/"yes"/"sim" → true).
---@param s string
---@return boolean
function Str.toBool(s) end

---Verifica se string representa um número válido.
---@param s string
---@return boolean
function Str.isNumeric(s) end

---Verifica se string é nil ou só contém whitespace.
---@param s string | nil
---@return boolean
function Str.isEmpty(s) end

---Repete string `n` vezes com separador opcional.
---@param s string
---@param n integer
---@param sep? string
---@return string
function Str.rep(s, n, sep) end

---Linha horizontal de `width` chars com o caractere de box-drawing.
---@param width integer
---@param char? string -- (default `Str.CHAR.LINE_H`)
---@return string
function Str.hline(width, char) end

---Gera um box simples de `width`×`height` como array de linhas.
---
---```lua
---local lines = Str.box(20, 3, "título")
----- { "┌──────────────────┐", "│ título           │", "└──────────────────┘" }
---for i, line in ipairs(lines) do screen:write(1, i, line) end
---```
---@param width  integer
---@param height integer
---@param title? string -- Texto opcional na segunda linha
---@return string[]
function Str.box(width, height, title) end
