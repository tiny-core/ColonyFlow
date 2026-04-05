local Util = require("lib.util")

local Cache = {}
Cache.__index = Cache

function Cache.new(opts)
  return setmetatable({
    max_entries = opts.max_entries or 2000,
    default_ttl_ms = (opts.default_ttl_seconds or 5) * 1000,
    store = {},
    order = {},
  }, Cache)
end

local function makeKey(namespace, key)
  return tostring(namespace) .. ":" .. tostring(key)
end

function Cache:get(namespace, key)
  local k = makeKey(namespace, key)
  local entry = self.store[k]
  if not entry then return nil end
  if entry.expires_at and entry.expires_at <= Util.nowUtcMs() then
    self.store[k] = nil
    return nil
  end
  entry.last_access = Util.nowUtcMs()
  return entry.value
end

function Cache:set(namespace, key, value, ttlSeconds)
  local k = makeKey(namespace, key)
  local ttl = ttlSeconds and (ttlSeconds * 1000) or self.default_ttl_ms
  self.store[k] = {
    value = value,
    expires_at = Util.nowUtcMs() + ttl,
    last_access = Util.nowUtcMs(),
  }
  table.insert(self.order, k)
  self:evictIfNeeded()
end

function Cache:evictIfNeeded()
  local count = 0
  for _ in pairs(self.store) do count = count + 1 end
  if count <= self.max_entries then return end

  local keys = {}
  for k, v in pairs(self.store) do
    table.insert(keys, { k = k, last = v.last_access or 0 })
  end
  table.sort(keys, function(a, b) return a.last < b.last end)

  local toRemove = count - self.max_entries
  for i = 1, toRemove do
    self.store[keys[i].k] = nil
  end
end

return Cache
