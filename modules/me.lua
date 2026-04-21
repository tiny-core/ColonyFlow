-- Integração com AE2 via Advanced Peripherals (meBridge).
-- Responsabilidades:
-- - Consultar status do grid (online/conectado)
-- - Consultar estoque/craftabilidade e abrir crafts do faltante real
-- - Exportar itens ao destino e tratar falhas transitórias
-- Invariantes:
-- - Chamar métodos do bridge apenas via wrappers (call/callAny) para budget + safeCall + métricas
-- - Respeitar modo degradado (backoff) quando ME oscilar/offline

local Util = require("lib.util")

local ME = {}
ME.__index = ME

local function ensureHealth(state)
  if not state then return {} end
  state.health = state.health or {}
  return state.health
end

local function isDegraded(state)
  local h = ensureHealth(state)
  if h.me_degraded ~= true then return false end
  local nextAt = tonumber(h.next_me_retry_at_ms)
  if nextAt and Util.nowUtcMs() < nextAt then
    return true
  end
  return false
end

local function enterDegraded(state)
  local h = ensureHealth(state)
  local fail = (tonumber(h.me_fail_count) or 0) + 1
  h.me_fail_count = fail

  local exp = math.min(fail - 1, 2)
  local delay = math.min(120000, 30000 * (2 ^ exp))

  h.me_degraded = true
  h.next_me_retry_at_ms = Util.nowUtcMs() + delay
end

local function exitDegraded(state)
  local h = ensureHealth(state)
  h.me_fail_count = 0
  h.me_degraded = false
  h.next_me_retry_at_ms = nil
end

local function bumpIo(state, method)
  local m = state and state.metrics
  if type(m) ~= "table" or m.enabled ~= true then return end
  local io = m.io
  if type(io) ~= "table" then return end
  local g = io.me
  if type(g) ~= "table" then return end
  g.total = (tonumber(g.total) or 0) + 1
  local methods = g.methods
  if type(methods) == "table" then
    local k = tostring(method or "")
    methods[k] = (tonumber(methods[k]) or 0) + 1
  end
end

local function call(state, bridge, method, ...)
  if not bridge or type(bridge[method]) ~= "function" then
    return nil, "Método indisponível: " .. tostring(method)
  end
  if state and state.budget and type(state.budget.tryConsume) == "function" then
    if not state.budget:tryConsume(state, "me", 1, "me") then
      return nil, "budget_exceeded:me"
    end
  end
  bumpIo(state, method)
  local ok, res1, res2 = Util.safeCall(bridge[method], ...)
  if not ok then return nil, tostring(res1) end
  return res1, res2
end

local function callAny(state, bridge, methods, ...)
  local lastErr = nil
  for _, m in ipairs(methods or {}) do
    local res, err = call(state, bridge, m, ...)
    if res ~= nil then return res, err end
    lastErr = err
  end
  return nil, lastErr or "Método indisponível"
end

local function isDirection(target)
  if type(target) ~= "string" then return false end
  local t = target:lower()
  return t == "right" or t == "left" or t == "front" or t == "back" or t == "top" or t == "bottom"
      or t == "north" or t == "south" or t == "east" or t == "west" or t == "up" or t == "down"
end

local function cacheTtl(state, key, default)
  if not state or not state.cfg then return default end
  if type(state.cfg.getNumber) ~= "function" then return default end
  return state.cfg:getNumber("cache", key, default)
end

local function cacheGet(state, ns, key)
  if not state or not state.cache then return nil end
  if type(state.cache.get) ~= "function" then return nil end
  return state.cache:get(ns, key)
end

local function cacheSet(state, ns, key, value, ttl)
  if not state or not state.cache then return end
  if type(state.cache.set) ~= "function" then return end
  state.cache:set(ns, key, value, ttl)
end

function ME.new(state)
  return setmetatable({ state = state }, ME)
end

function ME:isOnline()
  if isDegraded(self.state) then
    return false, "degraded"
  end
  local b = self.state.devices.meBridge
  if not b then return false, "meBridge ausente" end
  local connected, connErr = call(self.state, b, "isConnected")
  local online, onlineErr = call(self.state, b, "isOnline")
  if type(connErr) == "string" and connErr:match("^budget_exceeded:") then
    return nil, connErr
  end
  if type(onlineErr) == "string" and onlineErr:match("^budget_exceeded:") then
    return nil, onlineErr
  end
  if connected == nil and online == nil then
    local e1 = tostring(connErr or "")
    local e2 = tostring(onlineErr or "")
    local missing1 = e1:match("^M[ée]todo indispon[íi]vel") ~= nil
    local missing2 = e2:match("^M[ée]todo indispon[íi]vel") ~= nil
    if missing1 and missing2 then
      exitDegraded(self.state)
      return true, nil
    end
    enterDegraded(self.state)
    return false, (connErr or onlineErr or "erro_me_bridge")
  end
  if connected == false then
    enterDegraded(self.state)
    return false, "grid desconectado"
  end
  if online == false then
    enterDegraded(self.state)
    return false, "grid offline"
  end
  exitDegraded(self.state)
  return true, nil
end

function ME:getItem(filter)
  if isDegraded(self.state) then
    return nil, "me_degraded"
  end
  local b = self.state.devices.meBridge
  local name = filter and filter.name
  local ttl = cacheTtl(self.state, "me_item_ttl_seconds", 1)
  if ttl and ttl > 0 and type(name) == "string" and name ~= "" then
    local cached = cacheGet(self.state, "me_item", name)
    if cached ~= nil then return cached, nil end
    local res, err = call(self.state, b, "getItem", filter)
    if res ~= nil then cacheSet(self.state, "me_item", name, res, ttl) end
    return res, err
  end
  return call(self.state, b, "getItem", filter)
end

function ME:listItems(filter)
  if isDegraded(self.state) then
    return {}, "me_degraded"
  end
  local b = self.state.devices.meBridge
  local name = filter and filter.name
  local ttl = cacheTtl(self.state, "me_list_ttl_seconds", 1)
  if ttl and ttl > 0 and type(name) == "string" and name ~= "" then
    local cached = cacheGet(self.state, "me_list", name)
    if cached ~= nil then return cached, nil end
    local res, err = nil, nil
    if b and type(b.getItems) == "function" then
      res, err = call(self.state, b, "getItems", filter or {})
    elseif b and type(b.listItems) == "function" then
      res, err = call(self.state, b, "listItems", filter or {})
    else
      res, err = {}, nil
    end
    if res ~= nil then cacheSet(self.state, "me_list", name, res, ttl) end
    return res, err
  end
  if b and type(b.getItems) == "function" then
    return call(self.state, b, "getItems", filter or {})
  end
  if b and type(b.listItems) == "function" then
    return call(self.state, b, "listItems", filter or {})
  end
  return {}, nil
end

function ME:isCrafting(filter)
  if isDegraded(self.state) then
    return nil, "me_degraded"
  end
  local b = self.state.devices.meBridge
  local res, err = callAny(self.state, b, { "isCrafting", "isItemCrafting" }, filter)
  if res == nil and err then return nil, err end
  return res, err
end

function ME:isCraftable(filter)
  if isDegraded(self.state) then
    return nil, "me_degraded"
  end
  local b = self.state.devices.meBridge
  local name = filter and filter.name
  local count = filter and filter.count
  local ttl = cacheTtl(self.state, "me_craftable_ttl_seconds", 2)
  if ttl and ttl > 0 and type(name) == "string" and name ~= "" then
    local key = name .. "|" .. tostring(count or "")
    local cached = cacheGet(self.state, "me_craftable", key)
    if cached ~= nil then return cached, nil end
    local res, err = callAny(self.state, b, { "isCraftable", "isItemCraftable" }, filter)
    if type(res) == "boolean" then cacheSet(self.state, "me_craftable", key, res, ttl) end
    return res, err
  end
  return callAny(self.state, b, { "isCraftable", "isItemCraftable" }, filter)
end

function ME:craftItem(filter)
  if isDegraded(self.state) then
    return nil, "me_degraded"
  end
  local b = self.state.devices.meBridge
  return call(self.state, b, "craftItem", filter)
end

function ME:supportsExportToPeripheral()
  local b = self.state.devices.meBridge
  return b and type(b.exportItemToPeripheral) == "function"
end

function ME:exportItem(filter, target)
  if isDegraded(self.state) then
    return nil, "me_degraded"
  end
  local b = self.state.devices.meBridge
  if b and type(b.exportItemToPeripheral) == "function" then
    return call(self.state, b, "exportItemToPeripheral", filter, target)
  end
  if isDirection(target) then
    return call(self.state, b, "exportItem", filter, target)
  end
  return nil, "exportItemToPeripheral indisponível e target não é direção: " .. tostring(target)
end

return {
  new = ME.new,
}
