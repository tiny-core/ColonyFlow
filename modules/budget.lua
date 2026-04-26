local Budget = {}
Budget.__index = Budget

local function getBool(cfg, section, key, default)
  if not cfg or type(cfg.getBool) ~= "function" then return default end
  return cfg:getBool(section, key, default)
end

local function getNumber(cfg, section, key, default)
  if not cfg or type(cfg.getNumber) ~= "function" then return default end
  return cfg:getNumber(section, key, default)
end

local function normalizeLimit(v)
  local n = tonumber(v)
  if not n then return nil end
  if n <= 0 then return nil end
  return math.floor(n)
end

local function nowMs()
  return os.epoch("utc")
end

local function ensureWindow(self, group, now)
  local w = self.window[group]
  if type(w) ~= "table" then
    w = { started_at_ms = now, used = 0 }
    self.window[group] = w
    return w
  end
  local started = tonumber(w.started_at_ms or 0) or 0
  local age = now - started
  if started <= 0 or age < 0 or age >= (self.window_seconds * 1000) then
    w.started_at_ms = now
    w.used = 0
  end
  return w
end

function Budget.new(cfg)
  local enabled = getBool(cfg, "scheduler_budget", "enabled", true) == true
  local windowSeconds = math.floor(getNumber(cfg, "scheduler_budget", "window_seconds", 2) or 2)
  if windowSeconds < 1 then windowSeconds = 1 end

  local self = setmetatable({
    enabled = enabled,
    window_seconds = windowSeconds,
    tick_used = {},
    window = {},
    limits = {
      tick = {
        mc = normalizeLimit(getNumber(cfg, "scheduler_budget", "mc_calls_per_tick", 20)),
        me = normalizeLimit(getNumber(cfg, "scheduler_budget", "me_calls_per_tick", 40)),
        inv = normalizeLimit(getNumber(cfg, "scheduler_budget", "inv_calls_per_tick", 20)),
      },
      window = {
        mc = normalizeLimit(getNumber(cfg, "scheduler_budget", "mc_calls_per_window", 50)),
        me = normalizeLimit(getNumber(cfg, "scheduler_budget", "me_calls_per_window", 100)),
        inv = normalizeLimit(getNumber(cfg, "scheduler_budget", "inv_calls_per_window", 50)),
      },
    },
  }, Budget)

  return self
end

function Budget:beginTick(state)
  self.tick_used = {}
  if type(state) == "table" then
    if type(state.throttle) ~= "table" then state.throttle = {} end
    state.throttle.active = false
    state.throttle.reason = nil
    state.throttle.group = nil
  end
end

function Budget:consume(state, group, amount)
  group = tostring(group or "")
  if not self:tryConsume(state, group, amount or 1, group) then
    return false, "budget_exceeded:" .. group
  end
  return true
end

function Budget:tryConsume(state, group, amount, reasonKey)
  if self.enabled ~= true then return true end

  group = tostring(group or "")
  amount = tonumber(amount or 1) or 1
  if group == "" or amount <= 0 then return true end

  local tickLimit = self.limits and self.limits.tick and self.limits.tick[group] or nil
  local usedTick = tonumber(self.tick_used[group] or 0) or 0
  if tickLimit and (usedTick + amount) > tickLimit then
    if type(state) == "table" then
      if type(state.throttle) ~= "table" then state.throttle = {} end
      state.throttle.active = true
      state.throttle.group = group
      state.throttle.reason = group .. "_calls_per_tick"
      if reasonKey and tostring(reasonKey) ~= "" then
        state.throttle.reason = tostring(reasonKey) .. ":" .. state.throttle.reason
      end
    end
    return false
  end

  local windowLimit = self.limits and self.limits.window and self.limits.window[group] or nil
  if windowLimit then
    local now = nowMs()
    local w = ensureWindow(self, group, now)
    local usedWin = tonumber(w.used or 0) or 0
    if (usedWin + amount) > windowLimit then
      if type(state) == "table" then
        if type(state.throttle) ~= "table" then state.throttle = {} end
        state.throttle.active = true
        state.throttle.group = group
        state.throttle.reason = group .. "_calls_per_window"
        if reasonKey and tostring(reasonKey) ~= "" then
          state.throttle.reason = tostring(reasonKey) .. ":" .. state.throttle.reason
        end
      end
      return false
    end
    w.used = usedWin + amount
  end

  self.tick_used[group] = usedTick + amount
  return true
end

return {
  new = Budget.new,
}
