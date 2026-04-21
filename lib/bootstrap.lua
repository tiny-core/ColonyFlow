-- Bootstrap do ColonyFlow.
-- Responsabilidades:
-- - Garantir config.ini (defaults) e inicializar logger/cache
-- - Descobrir/validar perifericos essenciais (MineColonies, ME, monitores, destinos)
-- - Montar o `state` canonico (cfg/logger/cache/devices/stats/metrics/work/snapshot)
-- - Instanciar Engine + UI e delegar o loop ao Scheduler
-- Invariante: manter apenas `startup.lua` e `config.ini` na raiz; o resto vive em subpastas.

local Config = require("lib.config")
local Logger = require("lib.logger")
local Cache = require("lib.cache")
local Version = require("lib.version")
local Peripherals = require("modules.peripherals")
local UpdateCheck = require("modules.update_check")
local Scheduler = require("modules.scheduler")
local Engine = require("modules.engine")
local Budget = require("modules.budget")
local UI = require("components.ui")

local M = {}

function M.run()
  local ensure = Config.ensureDefaults("config.ini")
  local cfg = Config.load("config.ini")
  local logger = Logger.new(cfg)

  if ensure.err then
    logger:error("Erro ao criar config.ini padrão: " .. ensure.err)
  elseif ensure.created then
    logger:info("config.ini criado com defaults")
    for section, keys in pairs(ensure.defaults) do
      for key, value in pairs(keys) do
        logger:info("Default aplicado", { section = section, key = key, value = value })
      end
    end
  end

  logger:info("Inicializando sistema...")

  local obsEnabled = cfg:getBool("observability", "enabled", false)
  local metrics = {
    enabled = obsEnabled,
    ui_enabled = cfg:getBool("observability", "ui_enabled", false),
    debug_log_enabled = cfg:getBool("observability", "debug_log_enabled", false),
    debug_log_interval_seconds = cfg:getNumber("observability", "debug_log_interval_seconds", 30),
  }
  if obsEnabled then
    metrics.timing = {}
    metrics.io = {
      me = { total = 0, methods = {} },
      mc = { total = 0, methods = {} },
      inv = { total = 0, methods = {} },
    }
    metrics.cache = {
      hit_total = 0,
      miss_total = 0,
      hit_by_namespace = {},
      miss_by_namespace = {},
    }
  end

  local cache = Cache.new({
    max_entries = cfg:getNumber("cache", "max_entries", 2000),
    default_ttl_seconds = cfg:getNumber("cache", "default_ttl_seconds", 5),
    metrics = obsEnabled and metrics or nil,
  })

  local devices, deviceIssues = Peripherals.discover(cfg, logger)
  if deviceIssues and #deviceIssues > 0 then
    for _, issue in ipairs(deviceIssues) do
      logger:warn(issue)
    end
  end

  local state = {
    started_at = os.epoch("utc"),
    cfg = cfg,
    logger = logger,
    cache = cache,
    devices = devices,
    requests = {},
    stats = {
      processed = 0,
      crafted = 0,
      delivered = 0,
      substitutions = 0,
      errors = 0,
    },
    metrics = metrics,
    throttle = { active = false },
  }

  state.budget = Budget.new(cfg)

  state.installed = Version.readInstalled()
  state.update = UpdateCheck.defaultState(state.installed)
  do
    local cached = UpdateCheck.loadCache()
    if cached then
      for k, v in pairs(cached) do
        state.update[k] = v
      end
      if state.installed and state.installed.version then
        state.update.installed_version = state.installed.version
      else
        state.update.installed_version = nil
      end
    end
  end

  local engine = Engine.new(state)
  state.work = engine.work
  local ui = UI.new(state)

  Scheduler.run(state, engine, ui)
end

return M
