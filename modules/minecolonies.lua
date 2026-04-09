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
  local out = {}

  local ok, result = Util.safeCall(integrator.getRequests)
  if not ok then
    self.state.logger:error("Falha ao ler requests do MineColonies", { err = tostring(result) })
  elseif type(result) == "table" then
    for _, r in ipairs(result) do
      table.insert(out, normalizeRequest(r))
    end
  end

  local hasWO = type(integrator.getWorkOrders) == "function"
  local hasWOR = type(integrator.getWorkOrderResources) == "function"
  local hasBR = type(integrator.getBuilderResources) == "function"
  if hasWO and (hasWOR or hasBR) then
    local okWO, woResult = Util.safeCall(integrator.getWorkOrders)
    if not okWO then
      self.state.logger:warn("Falha ao ler WorkOrders do MineColonies", { err = tostring(woResult) })
    elseif type(woResult) == "table" then
      local added = 0
      local lastErr = nil

      for _, wo in ipairs(woResult) do
        local resources = nil

        if hasWOR then
          local okRes, resOrErr = Util.safeCall(integrator.getWorkOrderResources, wo.id)
          if okRes and type(resOrErr) == "table" then
            resources = resOrErr
          else
            lastErr = resOrErr
          end
        end

        if (not resources) and hasBR and type(wo.builder) == "table" then
          local okRes, resOrErr = Util.safeCall(integrator.getBuilderResources, wo.builder)
          if okRes and type(resOrErr) == "table" then
            resources = resOrErr
          else
            lastErr = resOrErr
          end
        end

        if type(resources) == "table" then
          for _, res in pairs(resources) do
            if type(res) ~= "table" then goto continue_res end
            local needed = tonumber(res.needs or res.needed or res.count or res.amount or 0) or 0

            local available = 0
            if type(res.available) == "number" then
              available = tonumber(res.available) or 0
            elseif type(res.available) == "boolean" then
              available = res.available and needed or 0
            end

            local delivering = 0
            if type(res.delivering) == "number" then
              delivering = tonumber(res.delivering) or 0
            elseif type(res.delivering) == "boolean" then
              delivering = res.delivering and needed or 0
            end

            local itemName = nil
            if type(res.item) == "string" then
              itemName = res.item
            elseif type(res.item) == "table" then
              itemName = res.item.name or res.item.item
            elseif type(res.name) == "string" then
              itemName = res.name
            end

            local missing = math.max(0, needed - available - delivering)
            if missing > 0 and itemName and itemName ~= "" then
              local synthId = "wo:" .. tostring(wo.id) .. ":" .. tostring(itemName)
              local acceptedItem = nil
              if type(res.item) == "table" then
                acceptedItem = {
                  name = itemName,
                  displayName = res.item.displayName,
                  count = missing,
                  maxStackSize = res.item.maxStackSize,
                  tags = res.item.tags,
                  nbt = res.item.nbt
                }
              else
                acceptedItem = {
                  name = itemName,
                  displayName = res.displayName,
                  count = missing,
                  maxStackSize = res.maxStackSize,
                  tags = res.tags,
                  nbt = res.nbt
                }
              end

              table.insert(out, normalizeRequest({
                id = synthId,
                name = itemName,
                desc = "WorkOrder " .. tostring(wo.workOrderType or wo.type or ""),
                state = "requested",
                target = wo.buildingName or wo.type or "builder",
                count = missing,
                items = { acceptedItem }
              }))
              added = added + 1
            end
            ::continue_res::
          end
        end
      end

      if #woResult > 0 and added == 0 then
        self.state.logger:warn("WorkOrders encontrados, mas nenhum recurso exportável foi gerado", {
          work_orders = #woResult,
          err = tostring(lastErr or ""),
        })
      end
    end
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

function Mine:listCitizens()
  local integrator = self.state.devices.colonyIntegrator
  if not integrator or type(integrator.getCitizens) ~= "function" then return {} end

  local ok, result = Util.safeCall(integrator.getCitizens)
  if not ok then
    self.state.logger:error("Falha ao ler citizens do MineColonies", { err = tostring(result) })
    return {}
  end
  if type(result) ~= "table" then
    return {}
  end

  local out = {}
  for _, c in ipairs(result) do
    local work = nil
    if type(c) == "table" and type(c.work) == "table" then
      work = {
        name = c.work.name,
        type = c.work.type,
        level = c.work.level,
      }
    end
    table.insert(out, {
      id = c and c.id or nil,
      name = c and c.name or nil,
      work = work,
    })
  end
  return out
end

function Mine:getColonyStats()
  local integrator = self.state.devices.colonyIntegrator
  local stats = {}

  local okName, name = Util.safeCall(integrator.getColonyName)
  if okName then stats.name = name end

  local okLoc, loc = Util.safeCall(integrator.getLocation)
  if okLoc and type(loc) == "table" then stats.location = loc end

  local okCit, citizens = Util.safeCall(integrator.amountOfCitizens)
  if okCit then stats.citizens = citizens end

  local okMax, maxCit = Util.safeCall(integrator.maxOfCitizens)
  if okMax then stats.maxCitizens = maxCit end

  local okHappy, happiness = Util.safeCall(integrator.getHappiness)
  if okHappy then stats.happiness = happiness end

  local under = false
  if type(integrator.isUnderAttack) == "function" then
    local okAtk, underAttack = Util.safeCall(integrator.isUnderAttack)
    if okAtk then
      if underAttack == true or underAttack == 1 or underAttack == "true" or underAttack == "TRUE" then
        under = true
      end
    end
  end

  if not under and type(integrator.getColonyInfo) == "function" then
    local okInfo, info = Util.safeCall(integrator.getColonyInfo)
    if okInfo and type(info) == "table" then
      local v = info.underAttack or info.isUnderAttack or info.under_attack or info.is_under_attack
      if v == true or v == 1 or v == "true" or v == "TRUE" then
        under = true
      end
      local raid = info.raid or info.raids
      if not under and type(raid) == "table" then
        if raid.active == true or raid.isActive == true or raid.ongoing == true or raid.inProgress == true then
          under = true
        end
        if not under and #raid > 0 then
          under = true
        end
      end
    end
  end

  if not under and type(integrator.getRaids) == "function" then
    local okR, raids = Util.safeCall(integrator.getRaids)
    if okR and type(raids) == "table" then
      for _, r in pairs(raids) do
        if r == true then
          under = true
          break
        end
        if type(r) == "table" then
          if r.active == true or r.isActive == true or r.ongoing == true or r.inProgress == true then
            under = true
            break
          end
        end
      end
      if not under and #raids > 0 then
        under = true
      end
    end
  end

  stats.underAttack = under

  local okSites, sites = Util.safeCall(integrator.amountOfConstructionSites)
  if okSites then stats.constructionSites = sites end

  return stats
end

return {
  new = Mine.new,
}
