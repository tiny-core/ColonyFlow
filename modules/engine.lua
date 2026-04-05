local MineColonies = require("modules.minecolonies")
local ME = require("modules.me")
local Inventory = require("modules.inventory")
local Equivalence = require("modules.equivalence")
local Tier = require("modules.tier")

local Engine = {}
Engine.__index = Engine

function Engine.new(state)
  return setmetatable({
    state = state,
    mine = MineColonies.new(state),
    me = ME.new(state),
    eq = Equivalence.new(state),
    tier = nil,
    work = {},
  }, Engine)
end

local function isPendingRequest(r)
  if not r or not r.state then return false end
  local s = tostring(r.state):lower()
  if s == "done" or s == "completed" or s == "fulfilled" or s == "success" then return false end
  return true
end

local function getItemAmount(itemInfo)
  if not itemInfo then return 0 end
  return itemInfo.amount or itemInfo.count or itemInfo.stored or 0
end

local function guessClass(name)
  if not name then return nil end
  local n = name:lower()
  if n:find("chestplate", 1, true) or n:find("jetpack", 1, true) then return "ARMOR_CHEST" end
  if n:find("pickaxe", 1, true) then return "TOOL_PICKAXE" end
  return nil
end

local function maxTierForLevel(level)
  if not level then return nil end
  if level <= 1 then return "iron" end
  if level == 2 then return "diamond" end
  return "netherite"
end

local function pickCandidate(state, me, eq, tier, request, opts)
  if #request.items == 0 then return nil, "sem_itens" end

  local mode = state.cfg:get("substitution", "mode", "safe")
  local candidates = {}

  for _, it in ipairs(request.items) do
    table.insert(candidates, { item = it, source = "request" })
  end

  if mode ~= "safe" then
    local base = request.items[1]
    local eqs = eq:getEquivalents(base.name)
    for _, n in ipairs(eqs) do
      table.insert(candidates, { item = { name = n, count = base.count }, source = "equivalence" })
    end
  end

  local maxTool = opts and opts.maxTool or state.cfg:get("tiers", "max_tool_tier", "netherite")
  local maxArmor = opts and opts.maxArmor or state.cfg:get("tiers", "max_armor_tier", "netherite")

  local best = nil
  local bestScore = -math.huge
  local bestWhy = nil

  for _, c in ipairs(candidates) do
    local it = c.item
    if it and it.name then
      local info = state.cache:get("me", it.name)
      if not info then
        local itemInfo = me:getItem({ name = it.name })
        local craftable = me:isCraftable({ name = it.name })
        info = {
          amount = getItemAmount(itemInfo),
          craftable = craftable == true or (itemInfo and itemInfo.isCraftable == true),
          tags = itemInfo and itemInfo.tags or it.tags,
        }
        state.cache:set("me", it.name, info, 5)
      end

      local meta = eq:getItemMeta(it.name)
      local className = (meta and meta.class) or guessClass(it.name)
      local t, tierWhy = tier:infer({ name = it.name, tags = info.tags })
      local allowed = true
      if className == "ARMOR_CHEST" and t then
        allowed = tier:isTierAllowed(className, t, maxArmor)
      elseif className and t then
        allowed = tier:isTierAllowed(className, t, maxTool)
      end

      local score = 0
      if not allowed then
        score = score - 10000
      else
        if info.amount and info.amount > 0 then score = score + 1000 end
        if info.craftable then score = score + 100 end
      end

      if t then
        local tn = tierWhy == "override" and 50 or 0
        score = score + tn
        if t == "netherite" then score = score + 50 end
        if t == "diamond" then score = score + 40 end
        if t == "iron" then score = score + 30 end
        if t == "stone" then score = score + 20 end
        if t == "wood" or t == "leather" then score = score + 10 end
      end

      if c.source == "request" then score = score + 5 end

      if score > bestScore then
        bestScore = score
        best = it
        bestWhy = {
          source = c.source,
          amount = info.amount,
          craftable = info.craftable,
          class = className,
          tier = t,
          tier_reason = tierWhy,
          allowed = allowed,
        }
      end
    end
  end

  if not best then return nil, "sem_candidato" end
  return best, bestWhy
end

function Engine:tick()
  local state = self.state
  state.stats.processed = state.stats.processed + 1

  if not state.devices.colonyIntegrator then
    state.logger:warn("colonyIntegrator indisponível; aguardando...")
    return
  end

  if not self.tier then
    self.tier = Tier.new(state, self.eq)
  end

  local requests = self.mine:listRequests()
  state.requests = requests

  local colonyStats = state.cache:get("mc", "stats")
  if not colonyStats then
    colonyStats = self.mine:getColonyStats()
    state.cache:set("mc", "stats", colonyStats, 2)
  end
  state.colonyStats = colonyStats

  local buildings = state.cache:get("mc", "buildings")
  if not buildings then
    buildings = self.mine:listBuildings()
    state.cache:set("mc", "buildings", buildings, 10)
  end

  if not state.devices.meBridge then
    state.logger:warn("meBridge indisponível; aguardando...")
    return
  end

  local okOnline, onlineErr = self.me:isOnline()
  if not okOnline then
    state.logger:warn("ME indisponível; aguardando...", { reason = onlineErr })
    return
  end

  local target = state.cfg:get("delivery", "default_target_container", "")
  local targetInv = (target ~= "" and peripheral.isPresent(target)) and peripheral.wrap(target) or nil
  if not targetInv then
    state.logger:warn("Destino padrão indisponível; aguardando...", { target = target })
    return
  end

  local enforce = state.cfg:getBool("progression", "enforce_building_gating", true)

  for _, r in ipairs(requests) do
    if isPendingRequest(r) then
      local job = self.work[r.id]
      if job and job.next_retry and job.next_retry > os.epoch("utc") then
        goto continue
      end

      local buildingLevel = nil
      if enforce and type(r.target) == "string" then
        local targetLower = r.target:lower()
        for _, b in ipairs(buildings) do
          if b and b.name and targetLower:find(tostring(b.name):lower(), 1, true) then
            buildingLevel = tonumber(b.level) or buildingLevel
            break
          end
        end
      end

      local candidate, why = pickCandidate(state, self.me, self.eq, self.tier, r, {
        maxTool = (enforce and buildingLevel) and maxTierForLevel(buildingLevel) or nil,
        maxArmor = (enforce and buildingLevel) and maxTierForLevel(buildingLevel) or nil,
      })
      if not candidate then
        self.work[r.id] = { status = "error", next_retry = os.epoch("utc") + 5000 }
        state.logger:warn("Request sem candidato", { request = r.id, reason = why })
        goto continue
      end

      if type(why) == "table" and why.source == "equivalence" then
        state.stats.substitutions = state.stats.substitutions + 1
        state.logger:info("Substituição sugerida por equivalência", {
          request = r.id,
          target = r.target,
          item = candidate.name,
          tier = why.tier,
          class = why.class,
          allowed = why.allowed,
        })
      end

      local needed = tonumber(candidate.count or r.count or 0) or 0
      local work = self.work[r.id] or {}
      work.status = work.status or "pending"
      work.request_state = r.state
      work.target = r.target
      work.requested = (r.items[1] and r.items[1].name) or nil
      work.chosen = candidate.name
      work.choice = why
      work.needed = needed
      local present, invErr = Inventory.countItem(targetInv, candidate.name)
      if present == nil then
        work.status = "waiting_retry"
        work.next_retry = os.epoch("utc") + 5000
        work.err = invErr
        self.work[r.id] = work
        state.logger:warn("Falha ao ler destino", { request = r.id, err = invErr })
        goto continue
      end

      local missing = math.max(0, needed - present)
      if missing <= 0 then
        work.status = "done"
        work.present = present
        work.missing = 0
        self.work[r.id] = work
        goto continue
      end
      work.present = present
      work.missing = missing
      work.status = "pending"
      self.work[r.id] = work

      local itemInfo = self.me:getItem({ name = candidate.name })
      local available = getItemAmount(itemInfo)
      local deliverNow = math.min(missing, available)
      if deliverNow > 0 then
        local exported, expErr = self.me:exportItem({ name = candidate.name, count = deliverNow }, target)
        if exported == nil then
          work.status = "waiting_retry"
          work.next_retry = os.epoch("utc") + 5000
          work.err = expErr
          self.work[r.id] = work
          state.stats.errors = state.stats.errors + 1
          state.logger:error("Falha ao exportar item", { request = r.id, item = candidate.name, err = expErr })
          goto continue
        end
        state.stats.delivered = state.stats.delivered + deliverNow
        missing = missing - deliverNow
        work.delivered = (work.delivered or 0) + deliverNow
        work.missing = missing
        work.status = missing > 0 and "partial_delivered" or "done"
        self.work[r.id] = work
      end

      if missing > 0 then
        local crafting, craftStateErr = self.me:isCrafting({ name = candidate.name })
        if crafting == true then
          work.status = "crafting"
          work.next_retry = os.epoch("utc") + 5000
          self.work[r.id] = work
          goto continue
        end

        local craftable = self.me:isCraftable({ name = candidate.name })
        if craftable ~= true then
          work.status = "waiting_retry"
          work.next_retry = os.epoch("utc") + 15000
          work.err = craftStateErr
          self.work[r.id] = work
          state.logger:warn("Item não craftável no ME", { request = r.id, item = candidate.name, missing = missing, err = craftStateErr })
          goto continue
        end

        local craftJob, craftErr = self.me:craftItem({ name = candidate.name, count = missing })
        if craftJob == nil then
          work.status = "waiting_retry"
          work.next_retry = os.epoch("utc") + 15000
          work.err = craftErr
          self.work[r.id] = work
          state.stats.errors = state.stats.errors + 1
          state.logger:error("Falha ao solicitar craft", { request = r.id, item = candidate.name, err = craftErr })
          goto continue
        end

        state.stats.crafted = state.stats.crafted + missing
        work.status = "crafting"
        work.next_retry = os.epoch("utc") + 5000
        work.craft_requested = missing
        self.work[r.id] = work
      end
    end
    ::continue::
  end
end

return {
  new = Engine.new,
}
