---@meta
---@version 1.0.0
-- cclib / types / core.tbl.d.lua
-- Definições de tipo para core/tbl.lua

---@class CCLib.Tbl
local Tbl = {}

-- ── Cópia ────────────────────────────────────────────────────────────────────

--- Cópia superficial (um nível).
---@generic T: table
---@param orig T
---@return T
function Tbl.copy(orig) end

--- Cópia profunda recursiva com proteção contra ciclos.
---@generic T: table
---@param orig T
---@param _depth? integer
---@return T
function Tbl.deepCopy(orig, _depth) end

-- ── Merge ────────────────────────────────────────────────────────────────────

--- Merge superficial: valores da direita sobrescrevem a esquerda.
--- Tbl.merge({a=1}, {b=2}, {a=3}) → {a=3, b=2}
---@param ... table
---@return table
function Tbl.merge(...) end

--- Merge profundo: tabelas aninhadas são merged recursivamente.
---@generic T: table
---@param base T
---@param override table
---@return T
function Tbl.deepMerge(base, override) end

-- ── Array (ipairs) ───────────────────────────────────────────────────────────

--- Transforma cada elemento do array.
---@generic T, U
---@param t  T[]
---@param fn fun(v: T, i: integer): U
---@return U[]
function Tbl.map(t, fn) end

--- Mantém apenas os elementos para os quais `fn` retorna true.
---@generic T
---@param t  T[]
---@param fn fun(v: T): boolean
---@return T[]
function Tbl.filter(t, fn) end

--- Reduz o array a um único valor acumulado.
---@generic T, U
---@param t    T[]
---@param fn   fun(acc: U, v: T, i: integer): U
---@param init U
---@return U
function Tbl.reduce(t, fn, init) end

--- Itera para side effects, sem retorno.
---@generic T
---@param t  T[]
---@param fn fun(v: T, i: integer)
function Tbl.forEach(t, fn) end

--- Retorna o primeiro elemento que passa no teste, e o seu índice.
---@generic T
---@param t  T[]
---@param fn fun(v: T, i: integer): boolean
---@return T | nil, integer | nil
function Tbl.find(t, fn) end

--- Retorna o índice do primeiro elemento com este valor.
---@generic T
---@param t T[]
---@param value T
---@return integer | nil
function Tbl.indexOf(t, value) end

--- Retorna true se algum elemento passar no teste.
---@generic T
---@param t  T[]
---@param fn fun(v: T): boolean
---@return boolean
function Tbl.any(t, fn) end

--- Retorna true se todos os elementos passarem no teste.
---@generic T
---@param t  T[]
---@param fn fun(v: T): boolean
---@return boolean
function Tbl.all(t, fn) end

--- Achata um array de arrays em um único array (1 nível).
---@generic T
---@param t (T | T[])[]
---@return T[]
function Tbl.flatten(t) end

--- Copia parte do array de `from` até `to` (inclusivo).
---@generic T
---@param t    T[]
---@param from integer -- Aceita negativo (conta a partir do fim)
---@param to?  integer -- (default último elemento)
---@return T[]
function Tbl.slice(t, from, to) end

--- Retorna cópia do array em ordem inversa.
---@generic T
---@param t T[]
---@return T[]
function Tbl.reverse(t) end

--- Remove duplicatas, mantendo a primeira ocorrência de cada valor.
---@generic T
---@param t T[]
---@return T[]
function Tbl.unique(t) end

--- Agrupa elementos por resultado de `fn(v)`.
--- Tbl.groupBy({"a","ab","b","bc"}, function(s) return #s end)
--  → { [1]={"a","b"}, [2]={"ab","bc"} }
---@generic T, K
---@param t  T[]
---@param fn fun(v: T): K
---@return table<K, T[]>
function Tbl.groupBy(t, fn) end

--- Zip dois arrays em array de pares `{a[i], b[i]}`.
--- Tbl.zip({1,2,3}, {"a","b","c"}) → {{1,"a"},{2,"b"},{3,"c"}}
---@generic A, B
---@param a A[]
---@param b B[]
---@return {[1]: A, [2]: B}[]
function Tbl.zip(a, b) end

--- Insere elemento em posição específica (shift para a direita).
---@generic T
---@param t T[]
---@param pos   integer
---@param value T
---@return T[]
function Tbl.insert(t, pos, value) end

--- Remove elemento em posição e retorna-o.
---@generic T
---@param t   T[]
---@param pos integer
---@return T
function Tbl.remove(t, pos) end

--- Remove primeira ocorrência do valor. Retorna true se removeu.
---@generic T
---@param t T[]
---@param value T
---@return boolean
function Tbl.removeValue(t, value) end

-- ── Dict (pairs) ─────────────────────────────────────────────────────────────

--- Retorna array de chaves da tabela.
---@param t table
---@return any[]
function Tbl.keys(t) end

--- Retorna array de valores da tabela.
---@param t table
---@return any[]
function Tbl.values(t) end

--- Retorna array de pares `{chave, valor}`.
---@param t table
---@return {[1]: any, [2]: any}[]
function Tbl.entries(t) end

--- Inverte chaves e valores.
---@generic K, V
---@param t table<K, V>
---@return table<V, K>
function Tbl.invert(t) end

--- Filtra um dict por valor.
---@generic K, V
---@param t  table<K, V>
---@param fn fun(v: V, k: K): boolean
---@return table<K, V>
function Tbl.filterDict(t, fn) end

--- Mapeia valores de um dict.
---@generic K, V, U
---@param t  table<K, V>
---@param fn fun(v: V, k: K): U
---@return table<K, U>
function Tbl.mapDict(t, fn) end

-- ── Inspeção ─────────────────────────────────────────────────────────────────

--- Retorna true se a tabela não tem nenhuma chave.
---@param t table
---@return boolean
function Tbl.isEmpty(t) end

--- Conta pares chave/valor (funciona em dicts, ao contrário de `#t`).
---@param t table
---@return integer
function Tbl.count(t) end

--- Retorna true se a tabela contém o valor (usando pairs).
---@param t table
---@param value any
---@return boolean
function Tbl.contains(t, value) end

--- Retorna true se a chave existe no dict.
---@param t   table
---@param key any
---@return boolean
function Tbl.hasKey(t, key) end

--- Itera sobre a tabela com chaves em ordem determinística.
--- Útil para logs e testes.
---@param t  table
---@param fn? fun(a: any, b: any): boolean -- Comparador de ordenação
---@return fun(): any, any -- Iterator (chave, valor)
function Tbl.sortedPairs(t, fn) end
