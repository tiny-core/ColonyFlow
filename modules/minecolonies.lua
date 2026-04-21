-- Integracao com MineColonies via Advanced Peripherals (colonyIntegrator).
-- Responsabilidades:
-- - Ler requests/work orders e normalizar payload cru para um formato interno estavel
-- - Aplicar limites de budget e medir IO (para observabilidade/performance)
-- Invariantes:
-- - Chamar metodos do integrator apenas via wrapper (call) para safeCall + budget + metricas
-- - Gerar um id estavel quando o MineColonies nao fornecer r.id (hash do conteudo relevante)

local Util = require("lib.util")

local Mine = {}
Mine.__index = Mine

function Mine.new(state)
  return setmetatable({ state = state }, Mine)
end

local function bumpIo(state, method)
  local m = state and state.metrics
  if type(m) ~= "table" or m.enabled ~= true then return end
  local io = m.io
  if type(io) ~= "table" then return end
  local g = io.mc
  if type(g) ~= "table" then return end
  g.total = (tonumber(g.total) or 0) + 1
  local methods = g.methods
  if type(methods) == "table" then
    local k = tostring(method or "")
    methods[k] = (tonumber(methods[k]) or 0) + 1
  end
end

local function call(state, integrator, method, ...)
  if not integrator or type(integrator[method]) ~= "function" then
    return nil, "method_missing:" .. tostring(method)
  end
  if state and state.budget and type(state.budget.tryConsume) == "function" then
    if not state.budget:tryConsume(state, "mc", 1, "mc") then
      return nil, "budget_exceeded:mc"
    end
  end
  bumpIo(state, method)
  local ok, res1, res2 = Util.safeCall(integrator[method], ...)
  if not ok then return nil, tostring(res1) end
  return res1, res2
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

  local result, err = call(self.state, integrator, "getRequests")
  if result == nil and err and tostring(err):match("^budget_exceeded:") then
    return nil, tostring(err)
  end
  if result == nil and err then
    self.state.logger:error("Falha ao ler requests do MineColonies", { err = tostring(err) })
  elseif type(result) == "table" then
    for _, r in ipairs(result) do
      table.insert(out, normalizeRequest(r))
    end
  end

  local hasWO = type(integrator.getWorkOrders) == "function"
  local hasWOR = type(integrator.getWorkOrderResources) == "function"
  local hasBR = type(integrator.getBuilderResources) == "function"
  if hasWO and (hasWOR or hasBR) then
    local woResult, woErr = call(self.state, integrator, "getWorkOrders")
    if woResult == nil and woErr and tostring(woErr):match("^budget_exceeded:") then
      return nil, tostring(woErr)
    end
    if woResult == nil and woErr then
      self.state.logger:warn("Falha ao ler WorkOrders do MineColonies", { err = tostring(woErr) })
    elseif type(woResult) == "table" then
      local added = 0
      local lastErr = nil

      for _, wo in ipairs(woResult) do
        local resources = nil

        if hasWOR then
          local resOrErr, rErr = call(self.state, integrator, "getWorkOrderResources", wo.id)
          if resOrErr == nil and rErr and tostring(rErr):match("^budget_exceeded:") then
            return nil, tostring(rErr)
          end
          if type(resOrErr) == "table" then
            resources = resOrErr
          else
            lastErr = rErr or resOrErr
          end
        end

        if (not resources) and hasBR and type(wo.builder) == "table" then
          local resOrErr, rErr = call(self.state, integrator, "getBuilderResources", wo.builder)
          if resOrErr == nil and rErr and tostring(rErr):match("^budget_exceeded:") then
            return nil, tostring(rErr)
          end
          if type(resOrErr) == "table" then
            resources = resOrErr
          else
            lastErr = rErr or resOrErr
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
  local result, err = call(self.state, integrator, "getBuildings")
  if result == nil and err and tostring(err):match("^budget_exceeded:") then
    return nil, tostring(err)
  end
  if result == nil and err then
    self.state.logger:error("Falha ao ler buildings do MineColonies", { err = tostring(err) })
    return {}
  end
  if type(result) ~= "table" then return {} end

  local out = {}
  for _, b in ipairs(result) do
    if type(b) == "table" then
      table.insert(out, {
        name = b.name,
        type = b.type,
        level = b.level,
        built = b.built,
        guarded = b.guarded,
        location = b.location,
      })
    end
  end
  return out
end

function Mine:listCitizens()
  local integrator = self.state.devices.colonyIntegrator
  if not integrator or type(integrator.getCitizens) ~= "function" then return {} end

  local result, err = call(self.state, integrator, "getCitizens")
  if result == nil and err and tostring(err):match("^budget_exceeded:") then
    return nil, tostring(err)
  end
  if result == nil and err then
    self.state.logger:error("Falha ao ler citizens do MineColonies", { err = tostring(err) })
    return {}
  end
  if type(result) ~= "table" then return {} end

  local out = {}
  for _, c in ipairs(result) do
    if type(c) ~= "table" then
      goto continue
    end
    local work = nil
    if type(c.work) == "table" then
      work = {
        name = c.work.name,
        type = c.work.type,
        level = c.work.level,
      }
    end
    table.insert(out, {
      id = c.id,
      name = c.name,
      work = work,
      state = c.state,
      location = c.location,
    })
    ::continue::
  end
  return out
end

function Mine:getColonyStats()
  local integrator = self.state.devices.colonyIntegrator
  local stats = {}

  local name, errName = call(self.state, integrator, "getColonyName")
  if name == nil and errName and tostring(errName):match("^budget_exceeded:") then
    return nil, tostring(errName)
  end
  if name ~= nil then stats.name = name end

  local citizens, errCit = call(self.state, integrator, "amountOfCitizens")
  if citizens == nil and errCit and tostring(errCit):match("^budget_exceeded:") then
    return nil, tostring(errCit)
  end
  if citizens ~= nil then stats.citizens = citizens end

  local maxCit, errMax = call(self.state, integrator, "maxOfCitizens")
  if maxCit == nil and errMax and tostring(errMax):match("^budget_exceeded:") then
    return nil, tostring(errMax)
  end
  if maxCit ~= nil then stats.maxCitizens = maxCit end

  local happiness, errHappy = call(self.state, integrator, "getHappiness")
  if happiness == nil and errHappy and tostring(errHappy):match("^budget_exceeded:") then
    return nil, tostring(errHappy)
  end
  if happiness ~= nil then stats.happiness = happiness end

  local sites, errSites = call(self.state, integrator, "amountOfConstructionSites")
  if sites == nil and errSites and tostring(errSites):match("^budget_exceeded:") then
    return nil, tostring(errSites)
  end
  if sites ~= nil then stats.constructionSites = sites end

  return stats
end

return {
  new = Mine.new,
}
