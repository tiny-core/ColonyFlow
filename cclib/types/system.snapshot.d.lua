---@meta
---@version 1.0.0
-- cclib / types / system.snapshot.d.lua
-- Definições de tipo para system/snapshot.lua

-- ── Resultado do diff ─────────────────────────────────────────────────────────

---@class CCLib.Snapshot.DiffResult
---@field added table<any, any> -- Chaves presentes em `new` mas não em `old`
---@field removed table<any, any> -- Chaves presentes em `old` mas não em `new`
---@field changed table<any, {old: any, new: any}> -- Chaves com valor alterado
---@field isEmpty boolean -- true se não há diferenças

---@class CCLib.Snapshot.DeepDiffEntry
---@field path string -- Caminho separado por pontos, ex: "jogador.inventario.0"
---@field old any -- Valor anterior (nil se era inexistente)
---@field new any -- Valor novo (nil se foi removido)

-- ── Histórico (undo stack) ────────────────────────────────────────────────────

---@class CCLib.Snapshot.History<T>
local History = {}

--- Adiciona um snapshot ao histórico. Descarta "futuro" se houve undo antes.
---@generic T
---@param snap T
function History:push(snap) end

--- Retorna o snapshot anterior (undo). nil se já no início.
---@generic T
---@return T | nil
function History:undo() end

--- Retorna o snapshot seguinte (redo). nil se já no fim.
---@generic T
---@return T | nil
function History:redo() end

---@return boolean true se há estado anterior disponível
function History:canUndo() end

---@return boolean true se há estado posterior disponível (após undo)
function History:canRedo() end

---@return integer Número total de snapshots guardados
function History:size() end

--- Limpa todo o histórico.
function History:clear() end

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Snapshot
local Snapshot = {}

--- Cria uma cópia profunda de qualquer valor.
--- Protegido contra referências circulares (max. `Const.LIMIT.SNAPSHOT_DEPTH`).
---
--- ```lua
--- local backup = Snapshot.copy(store:getAll())
--- ```
---@generic T
---@param orig T
---@param _visited? table
---@param _depth? integer
---@return T
function Snapshot.copy(orig, _visited, _depth) end

--- Compara dois snapshots superficialmente (primeiro nível).
--- Retorna as diferenças categorizadas em `added`, `removed` e `changed`.
---
--- ```lua
--- local before = Snapshot.copy(state)
--- state.hp = 50
--- local d = Snapshot.diff(before, state)
--- if not d.isEmpty then Log.info("game", "Estado mudou") end
--- ```
---@param old table
---@param new table
---@return CCLib.Snapshot.DiffResult
function Snapshot.diff(old, new) end

--- Diff profundo (recursivo). Retorna lista de todos os paths alterados.
--- Retorna lista plana de paths alterados: { "chave.subchave", ... }
--- ```lua
--- local changes = Snapshot.deepDiff(before, after)
--- for _, c in ipairs(changes) do
--- print(c.path, ":", tostring(c.old), "→", tostring(c.new))
--- end
--- ```
---@param old table
---@param new table
---@param _path? string
---@param _results? table
---@param _depth? integer
---
---@return CCLib.Snapshot.DeepDiffEntry[]
function Snapshot.deepDiff(old, new, _path, _results, _depth) end

--- Verifica se dois valores são profundamente iguais.
--- Mais rápido que `diff` quando só precisas saber "mudou ou não".
---@param a any
---@param b any
---@param _depth integer
---@return boolean
function Snapshot.equal(a, b, _depth) end

--- Cria um gestor de histórico com undo/redo.
---
--- ```lua
--- local history = Snapshot.history(16)
--- history:push(Snapshot.copy(state))
---
--- if history:canUndo() then
--- state = history:undo()
--- end
--- ```
---@generic T
---@param maxSize? integer -- Máximo de snapshots a guardar (default 16)
---@return CCLib.Snapshot.History<T>
function Snapshot.history(maxSize) end
