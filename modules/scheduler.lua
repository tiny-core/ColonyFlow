local Util = require("lib.util")
local UpdateCheck = require("modules.update_check")

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

  local function loopEvents()
    while true do
      local ev = { os.pullEventRaw() }
      local name = ev[1]
      if name == "terminate" then
        print("Terminated by user")
        break
      end

      if ui.handleEvent then
        local ok, err = pcall(ui.handleEvent, ui, table.unpack(ev))
        if not ok then
          state.logger:error("Erro no ui.handleEvent", { err = tostring(err) })
        end
      end
    end
  end

  local function loopUpdateCheck()
    local lastKey = nil
    while true do
      local enabled = state.cfg:getBool("update", "enabled", true)
      if enabled ~= true then
        state.update = type(state.update) == "table" and state.update or {}
        state.update.status = "disabled"
        state.update.err = nil
        state.update.stale = false

        local key = "disabled"
        if key ~= lastKey then
          lastKey = key
          state.logger:info("Update check desativado")
        end

        sleepSeconds(3600)
      else
        local ok, sleepSecOrErr = pcall(UpdateCheck.tick, state, { tries = 2 })
        if not ok then
          state.logger:info("Update check falhou", { err = tostring(sleepSecOrErr) })
          sleepSeconds(60)
        else
          local upd = type(state.update) == "table" and state.update or {}
          local lastAttempt = tonumber(upd.last_attempt_at_ms) or tonumber(upd.checked_at_ms) or nil
          local key = table.concat({
            tostring(upd.status or ""),
            tostring(upd.installed_version or ""),
            tostring(upd.available_version or ""),
            upd.stale == true and "1" or "0",
            tostring(upd.err or ""),
            tostring(lastAttempt or ""),
          }, "|")

          if key ~= lastKey then
            lastKey = key
            local st = tostring(upd.status or "")
            if st == "update_available" then
              state.logger:info("Update disponivel", {
                installed = upd.installed_version,
                available = upd.available_version,
                cmd = "tools/install.lua update",
                stale = upd.stale == true
              })
            elseif st == "no_update" then
              state.logger:info("Update check ok", {
                installed = upd.installed_version,
                available = upd.available_version,
                stale = upd.stale == true
              })
            elseif st == "no_installed" then
              state.logger:info("Versao instalada ausente", { cmd = "tools/install.lua install" })
            elseif st == "http_off" or st == "http_blocked" then
              state.logger:info("Update check indisponivel (HTTP off)", { manifest_url = upd.manifest_url })
            elseif st == "error" then
              state.logger:info("Update check falhou",
                { err = upd.err, manifest_url = upd.manifest_url, stale = upd.stale == true })
            end
          end

          sleepSeconds(tonumber(sleepSecOrErr) or 60)
        end
      end
    end
  end

  parallel.waitForAny(loopEngine, loopUI, loopEvents, loopUpdateCheck)
end

return M
