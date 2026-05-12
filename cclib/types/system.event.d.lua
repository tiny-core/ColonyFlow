---@meta
---@version 1.0.0
-- cclib / types / system.event.d.lua
-- Definições de tipo para system/event.lua

---@alias CCLib.Event.ListenerId integer
--- Identificador único de um listener, retornado por `Event.on()` e `Event.once()`.
--- Usa-o em `Event.off(id)` para cancelar a subscrição.

---@alias CCLib.Event.Handler fun(...): any
--- Callback de evento. Recebe os mesmos argumentos que o evento CC original.
--- Para eventos internos `cclib:*`, recebe uma única tabela `data`.

-- ── Estado de inspeção (DEV) ──────────────────────────────────────────────────

---@class CCLib.Event.InspectResult
---@field total integer -- Total de listeners registados
---@field events table<string, integer> -- Mapa eventName → número de listeners
---@field paused boolean -- Bus está pausado?
---@field queued integer -- Eventos em fila (enquanto pausado)

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Event
local Event = {}

--- Subscreve a um evento. Retorna um ID para cancelar com `Event.off`.
---
--- ```lua
--- local id = Event.on("mouse_click", function(button, x, y)
--- print("clique no", x, y)
--- end)
---
--- -- Evento interno CCLib:
--- Event.on("cclib:route_changed", function(data)
--- print("nova rota:", data.to)
--- end)
--- ```
---@param eventName string -- Nome do evento CC ou "cclib:*"
---@param fn CCLib.Event.Handler -- Callback
---@return CCLib.Event.ListenerId | nil -- nil se os argumentos forem inválidos
function Event.on(eventName, fn) end

--- Subscreve uma única vez — o listener é removido automaticamente após disparar.
---@param eventName string
---@param fn CCLib.Event.Handler
---@return CCLib.Event.ListenerId | nil
function Event.once(eventName, fn) end

--- Remove um listener pelo ID retornado por `on()` ou `once()`.
---@param id CCLib.Event.ListenerId
---@return boolean -- true se o listener existia e foi removido
function Event.off(id) end

--- Remove todos os listeners de um evento específico.
---@param eventName string
---@return integer -- Número de listeners removidos
function Event.offAll(eventName) end

--- Remove absolutamente todos os listeners de todos os eventos.
function Event.reset() end

--- Emite um evento interno (CCLib). Distribui imediatamente.
--- Para eventos CC nativos usa `Event.dispatch()`.
---
--- ```lua
--- Event.emit("cclib:route_changed", { from = "home", to = "settings" })
--- ```
---@param eventName string -- Deve começar com "cclib:"
---@param data? any -- Payload passado ao handler como primeiro argumento
function Event.emit(eventName, data) end

--- Distribui um evento CC nativo aos listeners registados.
--- Chamado automaticamente pela `session.lua` a cada ciclo do loop.
---
--- ```lua
--- -- Internamente na session:
--- Event.dispatch("mouse_click", button, x, y)
--- ```
---@param eventName string
---@param ... any -- Argumentos originais do evento CC
function Event.dispatch(eventName, ...) end

--- Pausa o bus: eventos são enfileirados em vez de distribuídos.
--- Útil durante transições de rota ou operações atómicas.
function Event.pause() end

--- Retoma o bus e distribui todos os eventos que ficaram em fila.
function Event.resume() end

--- Retorna o estado atual do bus (para o inspector em DEV mode).
---@return CCLib.Event.InspectResult
function Event.inspect() end
