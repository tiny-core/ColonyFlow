---@meta
---@version 1.0.0
-- cclib / types / system.peripheral.d.lua

-- ── Tipos ─────────────────────────────────────────────────────────────────────

--- Entrada retornada por `Peripheral.getAll()`.
---@class CCLib.Peripheral.Entry
---@field obj table -- Objeto wrapped (peripheral.wrap)
---@field name string -- Side ("top") ou ID wired ("monitor_0")
---@field wired boolean -- true se conectado por wired modem

--- Entrada retornada por `Peripheral.inspect()`.
---@class CCLib.Peripheral.InspectEntry
---@field name string
---@field type string
---@field wired boolean

--- Payload de `cclib:peripheral_found`.
---@class CCLib.Peripheral.FoundPayload
---@field name string -- Side ou ID wired
---@field type string -- Tipo: "monitor", "modem", etc.
---@field obj table -- Objeto wrapped
---@field wired boolean -- true se conectado por cabo

--- Payload de `cclib:peripheral_lost`.
---@class CCLib.Peripheral.LostPayload
---@field name string
---@field type string
---@field wired boolean

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Peripheral
local Peripheral = {}

--- Escaneia todos os periféricos disponíveis (sides + wired modems).
--- Usa `peripheral.getNames()` quando disponível (CC:Tweaked 1.84+),
--- com fallback para scan manual dos 6 sides em versões mais antigas.
--- Regista listeners para `peripheral` e `peripheral_detach`.
--- Deve ser chamado no `main.lua` antes de `Session.run()`.
function Peripheral.init() end

--- Retorna o objeto wrapped do primeiro periférico do tipo dado.
--- Aceita sides físicos ("top") e IDs wired ("monitor_0").
---
--- ```lua
--- Peripheral.get("monitor") -- primeiro monitor encontrado
--- Peripheral.get("monitor", Const.SIDE.TOP) -- monitor no lado "top"
--- Peripheral.get("monitor", "monitor_0") -- monitor wired com ID "monitor_0"
--- ```
---@param pType string -- Tipo do periférico ("monitor", "modem", etc.)
---@param name? string -- Side ou ID wired (opcional)
---@return table | nil, string | nil -- obj, name
function Peripheral.get(pType, name) end

--- Retorna qualquer periférico directamente pelo seu nome, sem filtrar por tipo.
--- Ideal quando já sabes o ID wired exato.
---
--- ```lua
--- local obj, pType, isWired = Peripheral.getByName("monitor_0")
--- local obj, pType, isWired = Peripheral.getByName("top")
--- ```
---@param name string Side ou ID wired exato
---@return table | nil -- obj (nil se não encontrado)
---@return string | nil -- pType Tipo do periférico
---@return boolean | nil -- wired true se wired
function Peripheral.getByName(name) end

--- Retorna todos os periféricos de um tipo como array de entries.
--- Inclui tanto os conectados por side como os wired.
---
--- ```lua
--- local monitors = Peripheral.getAll("monitor")
--- for _, m in ipairs(monitors) do
--- print(m.name, m.wired and "(wired)" or "(side)")
--- local screen = Screen.create(m.obj)
--- end
--- ```
---@param pType string
---@return CCLib.Peripheral.Entry[]
function Peripheral.getAll(pType) end

--- Verifica se existe pelo menos um periférico do tipo (e nome opcional).
---@param pType string
---@param name? string -- Side ou ID wired
---@return boolean
function Peripheral.has(pType, name) end

--- Retorna o nome do primeiro periférico do tipo (side ou ID wired), e o flag wired.
---@param pType string
---@return string | nil -- name
---@return boolean | nil -- wired
function Peripheral.nameOf(pType) end

--- Retorna lista de todos os periféricos conhecidos, ordenada (sides primeiro, depois wired).
---@return CCLib.Peripheral.InspectEntry[]
function Peripheral.inspect() end

--- Re-escaneia um periférico específico ou todos se `name` for nil.
---@param name? string -- Side ou ID wired a re-escanear
function Peripheral.rescan(name) end
