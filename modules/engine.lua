local MineColonies = require("modules.minecolonies")
local Inventory = require("modules.inventory")
local Equivalence = require("modules.equivalence")
local ME = require("modules.me")
local Tier = require("modules.tier")

local Engine = {}
Engine.__index = Engine

function Engine.new(state)
  return setmetatable({
    state = state,
    mine = MineColonies.new(state),
    eq = Equivalence.new(state),
    me = ME.new(state),
    tier = nil,
    work = {},
  }, Engine)
end

local function guessClass(name)
  if not name then return nil end
  local n = name:lower()
  if n:find("chestplate", 1, true) or n:find("jetpack", 1, true) then return "ARMOR_CHEST" end
  if n:find("pickaxe", 1, true) then return "TOOL_PICKAXE" end
  return nil
end

local function listIndex(list, value)
  if type(list) ~= "table" then return nil end
  for i, v in ipairs(list) do
    if v == value then return i end
  end
  return nil
end

local function tierRank(eq, className, tierName)
  if not tierName then return nil end
  local tiers = eq:getClassTiers(className)
  local idx = listIndex(tiers, tierName)
  if idx then return idx end
  local tool = { wood = 1, stone = 2, iron = 3, diamond = 4, netherite = 5 }
  local armor = { leather = 1, iron = 2, diamond = 3, netherite = 4 }
  if className == "ARMOR_CHEST" then return armor[tierName] end
  return tool[tierName]
end

local function isPendingState(cfg, stateValue)
  local s = stateValue and tostring(stateValue):lower() or ""
  if s == "" then return false end
  local deny = cfg:getList("minecolonies", "completed_states_deny", { "done", "completed", "fulfilled", "success" })
  for _, v in ipairs(deny) do
    if s == tostring(v):lower() then return false end
  end
  local allow = cfg:getList("minecolonies", "pending_states_allow", {})
  if #allow == 0 then return true end
  for _, v in ipairs(allow) do
    if s == tostring(v):lower() then return true end
  end
  return false
end

local function resolveTarget(cfg)
  local targets = cfg:getList("delivery", "default_target_container", {})
  for _, name in ipairs(targets) do
    if name ~= "" and peripheral.isPresent(name) then
      return name, peripheral.wrap(name)
    end
  end
  local raw = cfg:get("delivery", "default_target_container", "")
  if raw ~= "" and peripheral.isPresent(raw) then
    return raw, peripheral.wrap(raw)
  end
  return nil, nil
end

local function getDestinationSnapshot(state, targetName, targetInv, forceRefresh)
  local ttl = state.cfg:getNumber("delivery", "destination_cache_ttl_seconds", 2)
  if not forceRefresh then
    local cached = state.cache:get("dest", targetName)
    if cached then return cached, nil end
  end
  local snap, err = Inventory.snapshot(targetInv)
  if not snap then return nil, err end
  state.cache:set("dest", targetName, snap, ttl)
  return snap, nil
end

local function getMeAmount(me, itemName)
  local res = me and me.getItem and me:getItem({ name = itemName }) or nil
  if type(res) ~= "table" then return 0 end
  return tonumber(res.amount or 0) or 0
end

local function pickCandidate(state, eq, tier, me, request)
  local accepted = request.accepted or request.items or {}
  if #accepted == 0 then return nil, "sem_itens" end

  local allowUnmapped = state.cfg:getBool("substitution", "allow_unmapped_mods", false)
  local vanillaFirst = state.cfg:getBool("substitution", "vanilla_first", true)
  local tierPref = state.cfg:get("substitution", "tier_preference", "lowest"):lower()

  local eligible = {}
  local blocked = {}
  for _, it in ipairs(accepted) do
    if it and it.name then
      local allowed = allowUnmapped or eq:isAllowed(it.name)
      if allowed then
        table.insert(eligible, it)
      else
        table.insert(blocked, it)
      end
    end
  end

  if #eligible == 0 then
    if #blocked > 0 then return nil, "nao_suportado" end
    return nil, "sem_candidato"
  end

  local best, bestWhy, bestScore = nil, nil, -math.huge
  for idx, it in ipairs(eligible) do
    local className = eq:getClass(it.name) or guessClass(it.name)
    local t, tierWhy = tier:infer({ name = it.name, tags = it.tags })
    local amount = getMeAmount(me, it.name)
    local score = 0

    if amount > 0 then score = score + 10000 end

    local isVanilla = eq:isVanilla(it.name)
    if vanillaFirst then
      if isVanilla then score = score + 100 end
    else
      if not isVanilla then score = score + 100 end
    end

    local rank = tierRank(eq, className, t)
    if rank then
      if tierPref == "highest" then
        score = score + rank
      else
        score = score + (100 - rank)
      end
    end

    score = score - (idx / 1000)

    if score > bestScore then
      bestScore = score
      best = it
      bestWhy = {
        policy = { vanilla_first = vanillaFirst, tier_preference = tierPref, allow_unmapped_mods = allowUnmapped },
        class = className,
        tier = t,
        tier_reason = tierWhy,
        vanilla = isVanilla,
        allowed = true,
        me_amount = amount,
        equivalents = eq:getEquivalents(it.name),
      }
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

  local targetName, targetInv = resolveTarget(state.cfg)

  if not targetInv then
    state.logger:warn("Destino padrão indisponível; aguardando...",
      { target = state.cfg:get("delivery", "default_target_container", "") })
    for _, r in ipairs(requests) do
      if r and r.id and isPendingState(state.cfg, r.state) then
        local work = self.work[r.id] or {}
        work.status = "waiting_retry"
        work.request_state = r.state
        work.target = r.target
        work.err = "destino_indisponivel"
        work.next_retry = os.epoch("utc") + 5000
        self.work[r.id] = work
      end
    end
    return
  end

  local snap, snapErr = getDestinationSnapshot(state, targetName, targetInv, false)

  for _, r in ipairs(requests) do
    if r and r.id and isPendingState(state.cfg, r.state) then
      local job = self.work[r.id]
      if job and job.next_retry and job.next_retry > os.epoch("utc") then
        goto continue
      end

      local meOnline, meErr = self.me:isOnline()
      if not meOnline then
        local work = self.work[r.id] or {}
        work.status = "waiting_retry"
        work.request_state = r.state
        work.target = r.target
        work.err = "me_offline:" .. tostring(meErr or "")
        work.next_retry = os.epoch("utc") + 5000
        self.work[r.id] = work
        state.logger:warn("ME indisponível; aguardando...", { request = r.id, err = tostring(meErr) })
        goto continue
      end

      local candidate, why = pickCandidate(state, self.eq, self.tier, self.me, r)
      local work = self.work[r.id] or {}
      work.request_state = r.state
      work.target = r.target
      work.requested = (r.accepted and r.accepted[1] and r.accepted[1].name) or
      (r.items and r.items[1] and r.items[1].name) or nil
      work.accepted = r.accepted or r.items

      if not candidate then
        work.status = (why == "nao_suportado") and "unsupported" or "error"
        work.err = why
        work.next_retry = os.epoch("utc") + 15000
        self.work[r.id] = work
        state.logger:warn("Request sem candidato", { request = r.id, reason = why })
        goto continue
      end

      work.chosen = candidate.name
      work.choice = why
      work.needed = tonumber(candidate.count or r.requiredCount or r.count or 0) or 0

      if not snap then
        work.status = "waiting_retry"
        work.err = snapErr
        work.next_retry = os.epoch("utc") + 5000
        self.work[r.id] = work
        state.logger:warn("Falha ao ler destino", { request = r.id, err = snapErr })
        goto continue
      end

      local present = Inventory.countFromSnapshot(snap, candidate.name)
      local missing = math.max(0, work.needed - present)
      work.present = present
      work.missing = missing

      if missing <= 0 then
        work.status = "done"
        self.work[r.id] = work
        goto continue
      end

      local lockTtlSeconds = 15
      local lockKey = tostring(candidate.name) .. "|" .. tostring(missing) .. "|" .. tostring(targetName)
      local locked = state.cache:get("craft_lock", lockKey)
      local crafting, craftErr = self.me:isCrafting({ name = candidate.name, count = missing })
      if crafting == true or locked then
        work.status = "crafting"
        work.craft = work.craft or {}
        work.craft.key = lockKey
        work.craft.last_seen = os.epoch("utc")
        self.work[r.id] = work
        goto continue
      end

      local craftable, craftableErr = self.me:isCraftable({ name = candidate.name, count = missing })
      if craftable ~= true then
        work.status = "waiting_retry"
        work.err = "nao_craftavel:" .. tostring(craftableErr or "")
        work.next_retry = os.epoch("utc") + 15000
        self.work[r.id] = work
        state.logger:warn("Item não craftável agora; aguardando...",
          { request = r.id, item = candidate.name, err = tostring(craftableErr) })
        goto continue
      end

      local started, startErr = self.me:craftItem({ name = candidate.name, count = missing })
      if started == true then
        state.cache:set("craft_lock", lockKey, true, lockTtlSeconds)
        state.stats.crafted = state.stats.crafted + 1
        work.status = "crafting"
        work.craft = work.craft or {}
        work.craft.key = lockKey
        work.craft.started_at = os.epoch("utc")
        work.craft.message = startErr
        self.work[r.id] = work
      else
        work.status = "waiting_retry"
        work.err = "craft_falhou:" .. tostring(startErr or "")
        work.next_retry = os.epoch("utc") + 15000
        self.work[r.id] = work
        state.logger:warn("Falha ao iniciar craft", { request = r.id, item = candidate.name, err = tostring(startErr) })
      end

      if type(why) == "table" and type(why.equivalents) == "table" and #why.equivalents > 1 then
        state.stats.substitutions = state.stats.substitutions + 1
        state.logger:info("Equivalências conhecidas para o item escolhido", {
          request = r.id,
          target = r.target,
          item = candidate.name,
          tier = why.tier,
          class = why.class,
        })
      end
    end
    ::continue::
  end
end

return {
  new = Engine.new,
}
