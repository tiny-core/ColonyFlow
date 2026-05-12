---@meta
---@version 1.0.0
-- cclib / types / system.timer.d.lua
-- Definições de tipo para system/timer.lua

-- ── Opções de criação ─────────────────────────────────────────────────────────

---@class CCLib.Timer.CreateOpts
---@field loop? boolean -- Se true, o timer reinicia automaticamente após cada disparo
---@field args? any[] -- Argumentos extras passados ao callback quando dispara

-- ── Entrada de inspeção ───────────────────────────────────────────────────────

---@class CCLib.Timer.InspectEntry
---@field name string -- Nome do timer
---@field interval number -- Intervalo em segundos
---@field loop boolean -- Timer em loop?

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.Timer
local Timer = {}

--- Cria e inicia um timer nomeado.
--- Se já existir um timer com o mesmo `name`, o anterior é cancelado antes.
---
--- ```lua
--- -- Timer simples (dispara uma vez)
--- Timer.create("auto-save", 5.0, function() Persist.save(store, "/data.lua") end)
---
--- -- Timer em loop (spinner, relógio, etc.)
--- Timer.create("blink", 0.5, function()
--- cursor.visible = not cursor.visible
--- screen:flush()
--- end, { loop = true })
--- ```
---@param name string -- Nome único do timer
---@param interval number -- Segundos até disparar (mínimo 0.05)
---@param callback fun(...): any -- Chamado quando o timer dispara
---@param opts? CCLib.Timer.CreateOpts
---@return integer | nil ID -- CC do timer, ou nil em caso de erro
function Timer.create(name, interval, callback, opts) end

--- Processa um evento `"timer"` do CC. Chamado automaticamente pela `session.lua`.
--- Retorna true se era um timer conhecido por esta lib.
---@param ccId integer ID retornado por `os.startTimer`
---@return boolean
function Timer.fire(ccId) end

--- Cancela um timer pelo nome.
---@param name string
---@return boolean -- true se o timer existia e foi cancelado
function Timer.cancel(name) end

--- Cancela todos os timers ativos.
function Timer.cancelAll() end

--- Verifica se existe um timer ativo com este nome.
---@param name string
---@return boolean
function Timer.exists(name) end

--- Retorna o número de timers ativos.
---@return integer
function Timer.count() end

--- Retorna lista de todos os timers ativos (para o inspector em DEV mode).
---@return CCLib.Timer.InspectEntry[]
function Timer.inspect() end

--- Cria um timer de delay único sem nome explícito.
--- O nome interno é gerado automaticamente (`__delay_N`).
---
--- ```lua
--- Timer.delay(2.0, function() Toast.show("Bem-vindo!") end)
--- ```
---@param seconds number
---@param callback fun(): any
---@return integer | nil -- ID CC do timer
function Timer.delay(seconds, callback) end

--- Cancela e re-agenda o timer com o mesmo nome se chamado antes de expirar.
--- Útil para salvar estado após série de mudanças rápidas.
---
--- ```lua
--- -- Chamado em cada store:set — só salva 2s depois da última mudança
--- store:watch("*", function()
--- Timer.debounce("persist", 2.0, function() Persist.save(store, path) end)
--- end)
--- ```
---@param name string
---@param seconds number
---@param callback fun(): any
---@return integer | nil
function Timer.debounce(name, seconds, callback) end

---@param time number
---@return number
function os.startTimer(time) end

---@param timerID number
function os.cancelTimer(timerID) end
