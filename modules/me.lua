local Util = require("lib.util")

local ME = {}
ME.__index = ME

local function call(bridge, method, ...)
  if not bridge or type(bridge[method]) ~= "function" then
    return nil, "Método indisponível: " .. tostring(method)
  end
  local ok, res1, res2 = Util.safeCall(bridge[method], ...)
  if not ok then return nil, tostring(res1) end
  return res1, res2
end

function ME.new(state)
  return setmetatable({ state = state }, ME)
end

function ME:isOnline()
  local b = self.state.devices.meBridge
  if not b then return false, "meBridge ausente" end
  local connected = call(b, "isConnected")
  local online = call(b, "isOnline")
  if connected == nil and online == nil then
    return true, nil
  end
  if connected == false then return false, "grid desconectado" end
  if online == false then return false, "grid offline" end
  return true, nil
end

function ME:getItem(filter)
  local b = self.state.devices.meBridge
  return call(b, "getItem", filter)
end

function ME:listItems(filter)
  local b = self.state.devices.meBridge
  if b and type(b.getItems) == "function" then
    return call(b, "getItems", filter or {})
  end
  if b and type(b.listItems) == "function" then
    return call(b, "listItems", filter or {})
  end
  return {}, nil
end

function ME:isCrafting(filter)
  local b = self.state.devices.meBridge
  local res, err = call(b, "isCrafting", filter)
  if res == nil and err then return nil, err end
  return res, err
end

function ME:isCraftable(filter)
  local b = self.state.devices.meBridge
  return call(b, "isCraftable", filter)
end

function ME:craftItem(filter)
  local b = self.state.devices.meBridge
  return call(b, "craftItem", filter)
end

function ME:exportItem(filter, target)
  local b = self.state.devices.meBridge
  return call(b, "exportItem", filter, target)
end

return {
  new = ME.new,
}

