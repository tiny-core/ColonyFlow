local Util = require("lib.util")

local Mine = {}
Mine.__index = Mine

function Mine.new(state)
  return setmetatable({ state = state }, Mine)
end

local function fnv1a32(str)
  local hash = 2166136261
  for i = 1, #str do
    hash = bit32.bxor(hash, str:byte(i))
    hash = (hash * 16777619) % 4294967296
  end
  return hash
end

local function hashHex32(n)
  return string.format("%08x", n % 4294967296)
end

local function normalizeRequest(r)
  local accepted = {}
  if type(r.items) == "table" then
    for _, it in ipairs(r.items) do
      table.insert(accepted, {
        name = it.name,
        displayName = it.displayName,
        count = tonumber(it.count),
        maxStackSize = it.maxStackSize,
        tags = it.tags,
        nbt = it.nbt,
      })
    end
  end

  local requiredCount = tonumber(r.count) or tonumber(r.minCount)
  if not requiredCount and accepted[1] and accepted[1].count then requiredCount = accepted[1].count end
  requiredCount = requiredCount or 0

  for _, it in ipairs(accepted) do
    if not it.count then it.count = requiredCount end
  end

  local id = r.id and tostring(r.id) or nil
  if not id or id == "" then
    local keys = {}
    for _, it in ipairs(accepted) do
      if it and it.name then
        table.insert(keys, tostring(it.name) .. ":" .. tostring(it.count or 0))
      end
    end
    table.sort(keys)
    local raw = tostring(r.target or "") .. "|" .. tostring(requiredCount) .. "|" .. table.concat(keys, "|")
    id = "gen:" .. hashHex32(fnv1a32(raw))
  end

  return {
    id = id,
    raw_id = r.id,
    name = r.name,
    desc = r.desc,
    state = r.state,
    target = r.target,
    requiredCount = requiredCount,
    accepted = accepted,
    items = accepted,
    count = requiredCount,
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

function Mine:getColonyStats()
  local integrator = self.state.devices.colonyIntegrator
  local stats = {}

  local okName, name = Util.safeCall(integrator.getColonyName)
  if okName then stats.name = name end

  local okCit, citizens = Util.safeCall(integrator.amountOfCitizens)
  if okCit then stats.citizens = citizens end

  local okMax, maxCit = Util.safeCall(integrator.maxOfCitizens)
  if okMax then stats.maxCitizens = maxCit end

  local okHappy, happiness = Util.safeCall(integrator.getHappiness)
  if okHappy then stats.happiness = happiness end

  local okAtk, underAttack = Util.safeCall(integrator.isUnderAttack)
  if okAtk then stats.underAttack = underAttack end

  local okSites, sites = Util.safeCall(integrator.amountOfConstructionSites)
  if okSites then stats.constructionSites = sites end

  return stats
end

return {
  new = Mine.new,
}
