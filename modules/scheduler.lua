-- Scheduler/loops do sistema.
-- Orquestra loops em paralelo:
-- - engine.tick (lógica + IO controlado)
-- - ui.tick (render baseado em snapshot)
-- - eventos (touch/terminate) e roteamento para UI
-- - update check (background, com backoff)
-- Invariantes:
-- - loops devem usar pcall e nunca derrubar o programa por erro transitório
-- - respeitar intervalos de poll e budget para evitar travamentos

local Util = require("lib.util")
local UpdateCheck = require("modules.update_check")

local M = {}

local function metricsTiming(state)
  local m = state and state.metrics
  if type(m) ~= "table" or m.enabled ~= true then return nil end
  if type(m.timing) ~= "table" then return nil end
  return m.timing
end

local function updateTiming(timing, prefix, dt)
  if type(timing) ~= "table" then return end
  dt = tonumber(dt) or 0
  timing[prefix .. "_ms_last"] = dt

  local avgKey = prefix .. "_ms_avg"
  local prevAvg = tonumber(timing[avgKey])
  if prevAvg == nil then
    timing[avgKey] = dt
  else
    timing[avgKey] = (prevAvg * 0.9) + (dt * 0.1)
  end

  local maxKey = prefix .. "_ms_max"
  local prevMax = tonumber(timing[maxKey]) or 0
  if dt > prevMax then timing[maxKey] = dt end
end

local function maybeLogMetrics(state)
  local m = state and state.metrics
  if type(m) ~= "table" or m.enabled ~= true or m.debug_log_enabled ~= true then return end

  local interval = tonumber(m.debug_log_interval_seconds) or 30
  if interval < 5 then interval = 5 end

  local now = Util.nowUtcMs()
  if m._next_log_at_ms and now < m._next_log_at_ms then return end
  m._next_log_at_ms = now + (interval * 1000)

  local t = type(m.timing) == "table" and m.timing or {}
  local io = type(m.io) == "table" and m.io or {}
  local cache = type(m.cache) == "table" and m.cache or {}

  local meTotal = type(io.me) == "table" and tonumber(io.me.total) or 0
  local mcTotal = type(io.mc) == "table" and tonumber(io.mc.total) or 0
  local invTotal = type(io.inv) == "table" and tonumber(io.inv.total) or 0

  state.logger:debug("Metrics", {
    eng_last = t.engine_tick_ms_last,
    eng_avg = t.engine_tick_ms_avg,
    eng_max = t.engine_tick_ms_max,
    ui_last = t.ui_tick_ms_last,
    ui_avg = t.ui_tick_ms_avg,
    ui_max = t.ui_tick_ms_max,
    me = meTotal,
    mc = mcTotal,
    inv = invTotal,
    cache_hit = cache.hit_total,
    cache_miss = cache.miss_total,
  })
end

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
      local t0 = Util.nowUtcMs()
      local ok, err = pcall(engine.tick, engine)
      local dt = Util.nowUtcMs() - t0
      local timing = metricsTiming(state)
      if timing then updateTiming(timing, "engine_tick", dt) end
      if not ok then
        state.stats.errors = state.stats.errors + 1
        state.logger:error("Erro no engine.tick", { err = tostring(err) })
        sleepSeconds(1)
      else
        maybeLogMetrics(state)
        sleepSeconds(pollInterval)
      end
    end
  end

  local function loopUI()
    while true do
      if engine and type(engine.updateHealthSnapshot) == "function" then
        local okHealth, errHealth = pcall(engine.updateHealthSnapshot, engine, true)
        if not okHealth then
          state.stats.errors = state.stats.errors + 1
          state.logger:error("Erro no engine.updateHealthSnapshot", { err = tostring(errHealth) })
        end
      end
      local t0 = Util.nowUtcMs()
      local ok, err = pcall(ui.tick, ui)
      local dt = Util.nowUtcMs() - t0
      local timing = metricsTiming(state)
      if timing then updateTiming(timing, "ui_tick", dt) end
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
