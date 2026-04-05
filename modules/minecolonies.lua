local Util = require("lib.util")

local Mine = {}
Mine.__index = Mine

function Mine.new(state)
  return setmetatable({ state = state }, Mine)
end

local function normalizeRequest(r)
  local items = {}
  if type(r.items) == "table" then
    for _, it in ipairs(r.items) do
      table.insert(items, {
        name = it.name,
        displayName = it.displayName,
        count = it.count,
        maxStackSize = it.maxStackSize,
        tags = it.tags,
        nbt = it.nbt,
      })
    end
  end

  return {
    id = r.id,
    name = r.name,
    desc = r.desc,
    state = r.state,
    count = r.count,
    minCount = r.minCount,
    target = r.target,
    items = items,
  }
end

function Mine:listRequests()
  local integrator = self.state.devices.colonyIntegrator
  local ok, result = Util.safeCall(integrator.getRequests)
  if not ok then
    self.state.logger:error("Falha ao ler requests do MineColonies", { err = tostring(result) })
    return {}
  end
  if type(result) ~= "table" then
    return {}
  end

  local out = {}
  for _, r in ipairs(result) do
    table.insert(out, normalizeRequest(r))
  end
  return out
end

function Mine:listBuildings()
  local integrator = self.state.devices.colonyIntegrator
  local ok, result = Util.safeCall(integrator.getBuildings)
  if not ok then
    self.state.logger:error("Falha ao ler buildings do MineColonies", { err = tostring(result) })
    return {}
  end
  if type(result) ~= "table" then
    return {}
  end

  local out = {}
  for _, b in ipairs(result) do
    table.insert(out, {
      name = b.name,
      type = b.type,
      level = b.level,
      built = b.built,
    })
  end
  return out
end

return {
  new = Mine.new,
}
