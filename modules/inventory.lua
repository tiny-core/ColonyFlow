local Util = require("lib.util")

local M = {}

local function bumpIo(state, method)
  local m = state and state.metrics
  if type(m) ~= "table" or m.enabled ~= true then return end
  local io = m.io
  if type(io) ~= "table" then return end
  local g = io.inv
  if type(g) ~= "table" then return end
  g.total = (tonumber(g.total) or 0) + 1
  local methods = g.methods
  if type(methods) == "table" then
    local k = tostring(method or "")
    methods[k] = (tonumber(methods[k]) or 0) + 1
  end
end

local function safeList(inv, state)
  if not inv then return nil, "inventário ausente" end
  if type(inv.list) ~= "function" then return nil, "inventário sem list()" end
  if state and state.budget then
    local ok, err = state.budget:consume(state, "inv")
    if not ok then return nil, err end
  end
  bumpIo(state, "list")
  local ok, res = Util.safeCall(inv.list)
  if not ok then return nil, tostring(res) end
  return res, nil
end

function M.countItem(inv, itemName, state)
  local list, err = safeList(inv, state)
  if not list then return nil, err end
  local total = 0
  for _, stack in pairs(list) do
    if stack and stack.name == itemName then
      total = total + (stack.count or 0)
    end
  end
  return total, nil
end

function M.countAny(inv, names, state)
  local list, err = safeList(inv, state)
  if not list then return nil, err end
  local set = {}
  for _, n in ipairs(names or {}) do set[n] = true end
  local total = 0
  for _, stack in pairs(list) do
    if stack and stack.name and set[stack.name] then
      total = total + (stack.count or 0)
    end
  end
  return total, nil
end

function M.snapshot(inv, state)
  local list, err = safeList(inv, state)
  if not list then return nil, err end
  local counts = {}
  for _, stack in pairs(list) do
    if stack and stack.name then
      counts[stack.name] = (counts[stack.name] or 0) + (stack.count or 0)
    end
  end
  return counts, nil
end

function M.getFreeSpace(inv, itemName, maxStackFallback, state)
  local list, err = safeList(inv, state)
  if not list then return nil, err end
  local size = type(inv.size) == "function" and inv.size() or 27
  local freeSpace = 0
  local maxStack = tonumber(maxStackFallback) or 64

  local occupiedSlots = 0
  for slot, stack in pairs(list) do
    occupiedSlots = occupiedSlots + 1
    if stack and stack.name == itemName then
      local stackMax = tonumber(stack.maxStackSize) or maxStack
      local current = tonumber(stack.count) or 0
      freeSpace = freeSpace + math.max(0, stackMax - current)
    end
  end
  
  local freeSlots = math.max(0, size - occupiedSlots)
  freeSpace = freeSpace + (freeSlots * maxStack)
  return freeSpace, nil
end

function M.countFromSnapshot(snapshot, itemName)
  if type(snapshot) ~= "table" then return 0 end
  return snapshot[itemName] or 0
end

return M
