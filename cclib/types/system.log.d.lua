---@meta
---@version 1.0.0
-- cclib / types / system.log.d.lua
-- Definições de tipo para system/log.lua

---@alias CCLib.Log.Level "DEBUG"|"INFO"|"WARN"|"ERROR"|"FATAL"

-- ── Opções de inicialização ───────────────────────────────────────────────────

---@class CCLib.Log.InitOpts
---@field level? CCLib.Log.Level -- Nível mínimo (default: "INFO", "DEBUG" em DEV)
---@field file? boolean -- Escrever num ficheiro de log em disco (default: true)
---@field monitor? string -- Side do monitor de debug, ex: `"right"` (opcional)

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Log
local Log = {}

--- Inicializa o sistema de logging.
--- Deve ser chamado no `main.lua` antes de qualquer outro módulo que use Log.
---
--- ```lua
--- Log.init({ level = "DEBUG", file = true, monitor = "right" })
--- ```
---@param opts? CCLib.Log.InitOpts
function Log.init(opts) end

---@param level integer
---@param message string
function Log._write(level, module, message) end

--- Log de nível DEBUG (só visível quando `Const.DEV = true`).
--- Suporta formato printf.
---
--- ```lua
--- Log.debug("modulo", "valor=%s count=%d", valor, count)
--- ```
---@param module string -- Identificador do módulo que está a logar
---@param fmt string -- Mensagem ou formato printf
---@param ... any -- Argumentos de formato
function Log.debug(module, fmt, ...) end

--- Log de nível INFO.
---@param module string
---@param fmt string
---@param ... any
function Log.info(module, fmt, ...) end

--- Log de nível WARN. Visível mesmo com DEV desativo.
---@param module string
---@param fmt string
---@param ... any
function Log.warn(module, fmt, ...) end

--- Log de nível ERROR.
---@param module string
---@param fmt string
---@param ... any
function Log.error(module, fmt, ...) end

--- Log de nível FATAL. Para erros irrecuperáveis.
---@param module string
---@param fmt string
---@param ... any
function Log.fatal(module, fmt, ...) end

--- Muda o nível mínimo em runtime.
---@param level CCLib.Log.Level
function Log.setLevel(level) end

--- Retorna o nível atual como string.
---@return CCLib.Log.Level
function Log.getLevel() end

--- Fecha o ficheiro de log e liberta o handle.
--- Deve ser chamado no `onStop` da session.
function Log.close() end

--- Escreve uma linha separadora nos logs (para marcar início/fim de sessão).
---@param label? string -- Texto opcional no centro do separador
function Log.separator(label) end
