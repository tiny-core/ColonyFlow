local Util = require("lib.util")

local M = {}

local function sleepSeconds(s)
  local ms = math.floor((s or 0) * 1000)
  if ms <= 0 then
    os.sleep(0)
    return
  end
  os.sleep(ms / 1000)
end

function M.run(state, engine, ui)
  local pollInterval = state.cfg:getNumber("core", "poll_interval_seconds", 2)
  local uiInterval = state.cfg:getNumber("core", "ui_refresh_seconds", 1)

  local function loopEngine()
    while true do
      local ok, err = pcall(engine.tick, engine)
      if not ok then
        state.stats.errors = state.stats.errors + 1
        state.logger:error("Erro no engine.tick", { err = tostring(err) })
        sleepSeconds(1)
      else
        sleepSeconds(pollInterval)
      end
    end
  end

  local function loopUI()
    while true do
      local ok, err = pcall(ui.tick, ui)
      if not ok then
        state.stats.errors = state.stats.errors + 1
        state.logger:error("Erro no ui.tick", { err = tostring(err) })
        sleepSeconds(1)
      else
        sleepSeconds(uiInterval)
      end
    end
  end

  parallel.waitForAny(loopEngine, loopUI)
end

return M
