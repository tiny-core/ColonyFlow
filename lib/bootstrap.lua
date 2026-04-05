local Config = require("lib.config")
local Logger = require("lib.logger")
local Cache = require("lib.cache")
local Peripherals = require("modules.peripherals")
local Scheduler = require("modules.scheduler")
local Engine = require("modules.engine")
local UI = require("components.ui")

local M = {}

function M.run()
  local cfg = Config.load("config.ini")
  local logger = Logger.new(cfg)
  logger:info("Inicializando sistema...")

  local cache = Cache.new({
    max_entries = cfg:getNumber("cache", "max_entries", 2000),
    default_ttl_seconds = cfg:getNumber("cache", "default_ttl_seconds", 5),
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
  }

  local engine = Engine.new(state)
  state.work = engine.work
  local ui = UI.new(state)

  Scheduler.run(state, engine, ui)
end

return M
