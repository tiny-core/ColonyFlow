-- Engine: coração do sistema.
-- Faz o tick de processamento: lê requests (MineColonies), decide ação (tiers/equivalências),
-- calcula faltante real (destino), aciona ME (craft/entrega) e atualiza `state.work`.
-- Publica `state.snapshot` para a UI (UI não deve tocar periféricos diretamente).
-- Persistência: salva jobs em disco para retomar após reboot.

local MineColonies = require("modules.minecolonies")
local Inventory = require("modules.inventory")
local Equivalence = require("modules.equivalence")
local ME = require("modules.me")
local Tier = require("modules.tier")
local Util = require("lib.util")
local Persistence = require("modules.persistence")
local Snapshot = require("modules.snapshot")

local Engine = {}
Engine.__index = Engine

local PERSIST_PATH = "data/state.json"
local PERSIST_INTERVAL_MS = 2000
local PERSIST_MAX_AGE_MS = 6 * 60 * 60 * 1000

local function isBudgetExceeded(err)
  return type(err) == "string" and err:match("^budget_exceeded:") ~= nil
end

local function publishSnapshot(state)
  if type(state) ~= "table" then return end
  state.snapshot = Snapshot.build(state)
end

function Engine:_restorePersistedWork()
  local persisted = Persistence.load(PERSIST_PATH)
  if not persisted then return end

  local savedAt = tonumber(persisted.saved_at_ms or 0) or 0
  if savedAt > 0 and (Util.nowUtcMs() - savedAt) > PERSIST_MAX_AGE_MS then
    return
  end

  for reqId, job in pairs(persisted.jobs) do
    local id = tostring(reqId or "")
    if id ~= "" and type(job) == "table" then
      local work = self.work[id] or {}

      if job.chosen ~= nil then work.chosen = tostring(job.chosen) end
      if job.status ~= nil then work.status = tostring(job.status) end
      if job.missing ~= nil then work.missing = tonumber(job.missing) or work.missing end
      if job.last_err ~= nil then work.err = tostring(job.last_err) end
      if job.retry_at_ms ~= nil then work.next_retry = tonumber(job.retry_at_ms) or work.next_retry end

      local startedAt = tonumber(job.started_at_ms)
      if startedAt then
        work.craft = work.craft or {}
        work.craft.started_at = startedAt
      end

      self.work[id] = work
    end
  end
end

function Engine:_persistWorkMaybe()
  local now = Util.nowUtcMs()
  if self._persist_next_at_ms and now < self._persist_next_at_ms then return end
  self._persist_next_at_ms = now + PERSIST_INTERVAL_MS

  local jobs = {}
  for reqId, work in pairs(self.work) do
    local id = tostring(reqId or "")
    if id ~= "" and type(work) == "table" then
      local status = work.status and tostring(work.status) or ""
      if status ~= "" and status ~= "done" then
        local startedAt = nil
        if type(work.craft) == "table" and work.craft.started_at ~= nil then
          startedAt = tonumber(work.craft.started_at)
        end
        jobs[id] = {
          request_id = id,
          chosen = work.chosen,
          status = status,
          missing = tonumber(work.missing),
          started_at_ms = startedAt,
          retry_at_ms = tonumber(work.next_retry),
          last_err = work.err,
        }
      end
    end
  end

  Persistence.save(PERSIST_PATH, jobs)
end

function Engine.new(state)
  local self = setmetatable({
    state = state,
    mine = MineColonies.new(state),
    eq = Equivalence.new(state),
    me = ME.new(state),
    tier = nil,
    work = {},
    _rq_cursor = 1,
    _next_requests_refresh_at_ms = 0,
  }, Engine)

  if type(state) == "table" and state.snapshot == nil then
    publishSnapshot(state)
  end

  self._persist_next_at_ms = Util.nowUtcMs() + PERSIST_INTERVAL_MS
  self:_restorePersistedWork()
  self:_persistWorkMaybe()
  return self
end

local function guessClass(name)
  if not name then return nil end
  local n = name:lower()
  if n:find("helmet", 1, true) then return "armor_helmet" end
  if n:find("chestplate", 1, true) or n:find("jetpack", 1, true) then return "armor_chestplate" end
  if n:find("leggings", 1, true) then return "armor_leggings" end
  if n:find("boots", 1, true) then return "armor_boots" end
  if n:find("pickaxe", 1, true) then return "tool_pickaxe" end
  if n:find("shovel", 1, true) then return "tool_shovel" end
  if n:find("axe", 1, true) then return "tool_axe" end
  if n:find("hoe", 1, true) then return "tool_hoe" end
  if n:find("sword", 1, true) then return "tool_sword" end
  if n:find("bow", 1, true) then return "tool_bow" end
  if n:find("shield", 1, true) then return "tool_shield" end
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
  if type(className) == "string" and className:match("^armor_") then return armor[tierName] end
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

local function resolveInvByName(name)
  if not name or name == "" then return nil end
  if not peripheral.isPresent(name) then return nil end
  return peripheral.wrap(name)
end

local function pushFromBuffer(bufferInv, targetName, itemName, qty, state)
  if not bufferInv then return 0, "buffer_indisponivel" end
  if type(bufferInv.list) ~= "function" then return 0, "buffer_sem_list" end
  if type(bufferInv.pushItems) ~= "function" then return 0, "buffer_sem_pushItems" end
  if state and state.budget and type(state.budget.tryConsume) == "function" then
    if not state.budget:tryConsume(state, "inv", 1, "inv") then
      return 0, "budget_exceeded:inv"
    end
  end
  local list = bufferInv.list()
  if type(list) ~= "table" then return 0, "buffer_list_invalida" end
  local movedTotal = 0
  local remaining = tonumber(qty or 0) or 0
  for slot, stack in pairs(list) do
    if remaining <= 0 then break end
    if type(stack) == "table" and stack.name == itemName then
      if state and state.budget and type(state.budget.tryConsume) == "function" then
        if not state.budget:tryConsume(state, "inv", 1, "inv") then
          return movedTotal, "budget_exceeded:inv"
        end
      end
      local moved = bufferInv.pushItems(targetName, slot, remaining)
      moved = tonumber(moved or 0) or 0
      if moved > 0 then
        movedTotal = movedTotal + moved
        remaining = remaining - moved
      end
    end
  end
  return movedTotal, nil
end

local function getDestinationSnapshot(state, targetName, targetInv, forceRefresh)
  local ttl = state.cfg:getNumber("delivery", "destination_cache_ttl_seconds", 2)
  if not forceRefresh then
    local cached = state.cache:get("dest", targetName)
    if cached then return cached, nil end
  end
  local snap, err = Inventory.snapshot(targetInv, state)
  if not snap then return nil, err end
  state.cache:set("dest", targetName, snap, ttl)
  return snap, nil
end

local function getMeAmount(me, itemName)
  if not me then return 0, nil end
  if type(me.getItem) == "function" then
    local res, err = me:getItem({ name = itemName })
    if res == nil and isBudgetExceeded(err) then
      return nil, err
    end
    if type(res) == "table" then
      local n = tonumber(res.amount or 0) or 0
      if n > 0 then return n, nil end
    end
  end
  if type(me.listItems) ~= "function" then return 0, nil end
  local list, err = me:listItems({ name = itemName })
  if list == nil and isBudgetExceeded(err) then
    return nil, err
  end
  if type(list) ~= "table" then return 0, nil end
  local total = 0
  for _, v in pairs(list) do
    if type(v) == "table" and v.name == itemName then
      total = total + (tonumber(v.amount or v.count or 0) or 0)
    end
  end
  return total, nil
end

local function isMeCraftable(me, itemName, count)
  if not me then return nil, nil end
  if type(me.getItem) == "function" then
    local res, err = me:getItem({ name = itemName })
    if res == nil and isBudgetExceeded(err) then
      return nil, err
    end
    if type(res) == "table" and res.isCraftable ~= nil then
      if res.isCraftable == true then
        return true, nil
      end
    end
  end
  if type(me.isCraftable) ~= "function" then return nil, nil end
  local res, err = me:isCraftable({ name = itemName, count = count })
  if res == nil and isBudgetExceeded(err) then
    return nil, err
  end
  return res, err
end

local function strLower(s)
  return s and tostring(s):lower() or ""
end

local function normalizeName(s)
  s = strLower(s)
  s = s:gsub("%s+", " ")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

local function resolveBuildingForTarget(buildings, target)
  local t = strLower(target)
  if t == "" then return nil, false end
  for _, b in ipairs(buildings or {}) do
    if b and (strLower(b.name) == t or strLower(b.type) == t) then
      return b, true
    end
  end
  for _, b in ipairs(buildings or {}) do
    if b and (strLower(b.name):find(t, 1, true) or strLower(b.type):find(t, 1, true)) then
      return b, true
    end
  end
  return nil, false
end

local function resolveBuildingForRequest(buildings, citizens, target)
  local b, ok = resolveBuildingForTarget(buildings, target)
  if ok and b then return b, true end

  local t = normalizeName(target)
  if t == "" then return nil, false end
  local tNoPrefix = t:match("^[^%s]+%s+(.+)$") or t
  for _, c in ipairs(citizens or {}) do
    local cn = c and normalizeName(c.name) or ""
    if cn ~= "" then
      local match = (cn == t) or (t:find(cn, 1, true) ~= nil) or (cn:find(t, 1, true) ~= nil) or (cn == tNoPrefix) or
          (tNoPrefix:find(cn, 1, true) ~= nil) or (cn:find(tNoPrefix, 1, true) ~= nil)
      if match and type(c.work) == "table" and c.work.type then
        return { name = c.work.name or c.work.type, type = c.work.type, level = c.work.level, built = true }, true
      end
    end
  end
  return nil, false
end

local function defaultMaxTierForLevel(className, level)
  local lvl = tonumber(level or 0) or 0
  if lvl >= 5 then return "netherite" end
  if lvl >= 3 then return "diamond" end
  return "iron"
end

local function getMaxTier(eq, className, building, resolved)
  if building and (building.type or building.name) then
    local bt = building.type or building.name
    local override = eq:getGatingMaxTier(bt, className) or eq:getGatingMaxTier(building.name, className)
    if override then return override, true, "override" end
  end
  if resolved and building then
    return defaultMaxTierForLevel(className, building.level), true, "default"
  end
  return "iron", false, "unresolved"
end

local function pickCandidate(state, eq, tier, me, request, building, buildingResolved)
  local accepted = request.accepted or request.items or {}
  if #accepted == 0 then return nil, "sem_itens" end

  local allowUnmapped = state.cfg:getBool("substitution", "allow_unmapped_mods", false)
  local vanillaFirst = state.cfg:getBool("substitution", "vanilla_first", true)
  local tierPref = state.cfg:get("substitution", "tier_preference", "lowest"):lower()

  local eligible = {}
  local blocked = {}
  for _, it in ipairs(accepted) do
    if it and it.name then
      local allowed = allowUnmapped or (eq.isAllowedFor and eq:isAllowedFor(it) or eq:isAllowed(it.name))
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

  do
    local expanded = {}
    local seen = {}
    for _, it in ipairs(eligible) do
      if it and it.name and not seen[it.name] then
        seen[it.name] = true
        table.insert(expanded, it)

        local className = (eq.getClassFor and eq:getClassFor(it) or eq:getClass(it.name)) or guessClass(it.name)
        if type(className) == "string" and className:match("^armor_") then
          local _, piece = tostring(it.name):match(
            "^minecraft:(leather|iron|diamond|netherite)_(helmet|chestplate|leggings|boots)$")
          if piece then
            local tiers = { "leather", "iron", "diamond", "netherite" }
            for _, tName in ipairs(tiers) do
              local n = "minecraft:" .. tName .. "_" .. piece
              if not seen[n] then
                seen[n] = true
                table.insert(expanded, { name = n, count = it.count, tags = it.tags })
              end
            end
          end
        end
      end
    end
    eligible = expanded
  end

  local blockedByTier = {}
  local blockedByCraft = {}
  local best, bestWhy, bestScore = nil, nil, -math.huge
  for idx, it in ipairs(eligible) do
    local className = (eq.getClassFor and eq:getClassFor(it) or eq:getClass(it.name)) or guessClass(it.name)
    local t, tierWhy = tier:infer({ name = it.name, tags = it.tags })
    local maxTier, maxTierResolved, maxTierSource = getMaxTier(eq, className, building, buildingResolved)
    if t then
      local allowedByTier = maxTier and tier:isTierAllowed(className, t, maxTier) or false
      if not allowedByTier then
        table.insert(blockedByTier, { name = it.name, class = className, tier = t, max = maxTier })
        goto continue_item
      end
    end
    local amount, amountErr = getMeAmount(me, it.name)
    if amount == nil and isBudgetExceeded(amountErr) then
      return nil, amountErr
    end
    local craftable, craftableErr = nil, nil
    if amount <= 0 then
      craftable, craftableErr = isMeCraftable(me, it.name,
        tonumber(it.count or request.requiredCount or request.count or 1) or 1)
      if craftable == nil and isBudgetExceeded(craftableErr) then
        return nil, craftableErr
      end
    end
    if amount <= 0 and craftable == false then
      table.insert(blockedByCraft, { name = it.name, class = className, tier = t, max = maxTier, err = craftableErr })
      goto continue_item
    end
    local score = 0

    if amount > 0 then score = score + 10000 end
    if craftable == true then score = score + 5000 end
    if craftable == false then score = score - 5000 end

    local isVanilla = eq:isVanilla(it.name)
    local preferEq, hasPrefer = false, false
    if eq.getPreferEquivalentFor then
      preferEq, hasPrefer = eq:getPreferEquivalentFor(it)
    end
    local vanillaFirstEff = vanillaFirst
    if hasPrefer then vanillaFirstEff = not preferEq end
    if vanillaFirstEff then
      if isVanilla then score = score + 100 end
    else
      if not isVanilla then score = score + 100 end
    end

    local enforceGating = state.cfg:getBool("progression", "enforce_building_gating", true)
    local tierPrefEff = tierPref
    if enforceGating and maxTierResolved then
      tierPrefEff = "highest"
    end

    local isAvailable = (amount > 0) or (craftable == true)
    local rank = tierRank(eq, className, t)
    if rank then
      if tierPrefEff == "highest" then
        if isAvailable then
          score = score + (rank * 100000)
        else
          score = score + rank
        end
      else
        score = score + (100 - rank)
      end
    end

    score = score - (idx / 1000)

    if score > bestScore then
      bestScore = score
      best = it
      bestWhy = {
        policy = {
          vanilla_first_cfg = vanillaFirst,
          vanilla_first_effective = vanillaFirstEff,
          prefer_equivalent = hasPrefer and preferEq or nil,
          tier_preference = tierPref,
          allow_unmapped_mods = allowUnmapped
        },
        class = className,
        tier = t,
        tier_reason = tierWhy,
        max_tier = maxTier,
        max_tier_resolved = maxTierResolved,
        max_tier_source = maxTierSource,
        building = building and { name = building.name, type = building.type, level = building.level } or nil,
        vanilla = isVanilla,
        allowed = true,
        me_amount = amount,
        me_craftable = craftable,
        me_craftable_err = craftableErr,
        equivalents = eq:getEquivalents(it.name),
      }
    end
    ::continue_item::
  end

  if not best then
    if #blockedByTier > 0 then
      return nil,
          {
            reason = "blocked_by_tier",
            building = building and
                { name = building.name, type = building.type, level = building.level } or nil,
            blocked = blockedByTier
          }
    end
    if #blockedByCraft > 0 then
      return nil, "nao_craftavel"
    end
    return nil, "sem_candidato"
  end
  return best, bestWhy
end

local function buildPeripheralHealth(state, me)
  local devices = (type(state) == "table" and type(state.devices) == "table") and state.devices or nil
  local cfg = (type(state) == "table" and type(state.cfg) == "table") and state.cfg or nil

  local function trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
  end

  local function stripModTag(name)
    local s = trim(name)
    local _, suffix = s:match("^([^:]+):(.+)$")
    return suffix or s
  end

  local function listFromCfg(section, key)
    if not cfg then return {} end
    if type(cfg.getList) == "function" then
      local out = cfg:getList(section, key, {})
      if type(out) == "table" and #out > 0 then
        local cleaned = {}
        for _, v in ipairs(out) do
          local t = trim(v)
          if t ~= "" then
            table.insert(cleaned, t)
          end
        end
        if #cleaned > 0 then return cleaned end
      end
    end
    if type(cfg.get) == "function" then
      local raw = trim(cfg:get(section, key, ""))
      if raw ~= "" then
        local out = {}
        for part in raw:gmatch("[^,]+") do
          local t = trim(part)
          if t ~= "" then
            table.insert(out, t)
          end
        end
        return out
      end
    end
    return {}
  end

  local function resolvePeripheralName(name)
    name = trim(name)
    if name == "" then return nil end
    if name:find(":", 1, true) then
      return name
    end
    if type(peripheral) ~= "table" or type(peripheral.getNames) ~= "function" then
      return name
    end
    local ok, names = pcall(peripheral.getNames)
    if not ok or type(names) ~= "table" then
      return name
    end
    for _, n in ipairs(names) do
      n = tostring(n or "")
      if n == name then return n end
      if n:sub(-(#name + 1)) == (":" .. name) then
        return n
      end
    end
    return name
  end

  local function presentByName(name)
    if type(name) ~= "string" or name == "" then return nil end
    if type(peripheral) ~= "table" or type(peripheral.isPresent) ~= "function" then return nil end
    local resolved = resolvePeripheralName(name)
    local ok, present = pcall(peripheral.isPresent, resolved)
    if not ok then return nil end
    return present == true
  end

  local function wrapByName(name)
    if type(name) ~= "string" or name == "" then return nil end
    if type(peripheral) ~= "table" or type(peripheral.wrap) ~= "function" then return nil end
    local ok, dev = pcall(peripheral.wrap, name)
    if not ok then return nil end
    return dev
  end

  local function refreshDeviceFromConfig(deviceKey, nameKey, cfgKey)
    if not devices then return nil, nil end
    local name = trim(devices[nameKey] or "")
    if name == "" and cfg and type(cfg.get) == "function" then
      name = trim(cfg:get("peripherals", cfgKey, ""))
    end
    if name == "" then return devices[deviceKey], nil end

    local resolved = resolvePeripheralName(name)
    local present = presentByName(resolved)
    devices[nameKey] = resolved
    if present == true then
      devices[deviceKey] = wrapByName(resolved) or devices[deviceKey]
    else
      devices[deviceKey] = nil
    end
    return devices[deviceKey], resolved
  end

  local function deviceStatus(dev, name)
    local present = presentByName(name)
    if present == true then return "Online", "ok" end
    if present == false then return "Offline", "bad" end
    if not devices then
      return "NA", "unknown"
    end
    if dev then return "Online", "ok" end
    return "Offline", "bad"
  end

  local meValue, meLevel = "NA", "unknown"
  local meDev, _ = refreshDeviceFromConfig("meBridge", "meName", "me_bridge")
  if meDev then
    meValue, meLevel = "Online", "ok"
  else
    meValue, meLevel = "Offline", "bad"
  end
  if me and type(me.isOnline) == "function" then
    local ok = me:isOnline()
    if ok == true then
      meValue, meLevel = "Online", "ok"
    elseif ok == false then
      meValue, meLevel = "Offline", "bad"
    end
  end

  local bufferName = ""
  if cfg and type(cfg.get) == "function" then
    bufferName = trim(cfg:get("delivery", "export_buffer_container", ""))
  end
  local bufferValue, bufferLevel = deviceStatus(resolveInvByName(resolvePeripheralName(bufferName)), bufferName)

  local targetValue, targetLevel = "NA", "unknown"
  if cfg and type(cfg.getList) == "function" and type(peripheral) == "table" and type(peripheral.isPresent) == "function" then
    local _, targetInv = resolveTarget(cfg)
    if targetInv then
      targetValue, targetLevel = "Online", "ok"
    else
      targetValue, targetLevel = "Offline", "bad"
    end
  elseif cfg then
    local raw = trim(type(cfg.get) == "function" and cfg:get("delivery", "default_target_container", "") or "")
    if raw ~= "" then
      targetValue, targetLevel = "Offline", "bad"
    end
  end

  local colonyDev, colonyName = refreshDeviceFromConfig("colonyIntegrator", "colonyName", "colony_integrator")
  local colonyValue, colonyLevel = deviceStatus(colonyDev, colonyName)

  return {
    { label = "ME Bridge", value = meValue,     level = meLevel },
    { label = "Colony",    value = colonyValue, level = colonyLevel },
    { label = "Buffer",    value = bufferValue, level = bufferLevel },
    { label = "Target",    value = targetValue, level = targetLevel },
  }
end

function Engine:tick()
  local state = self.state

  if self.eq and self.eq.reloadIfChanged then
    self.eq:reloadIfChanged()
  end

  state.stats.processed = state.stats.processed + 1

  if state.budget and type(state.budget.beginTick) == "function" then
    state.budget:beginTick(state)
  end

  self:updateHealthSnapshot(false)

  if not state.devices.colonyIntegrator then
    state.logger:warn("colonyIntegrator indisponível; aguardando...")
    publishSnapshot(state)
    self:_persistWorkMaybe()
    return
  end

  if not self.tier then
    self.tier = Tier.new(state, self.eq)
  end

  local sbEnabled = true
  if state.cfg and type(state.cfg.getBool) == "function" then
    sbEnabled = state.cfg:getBool("scheduler_budget", "enabled", true) == true
  end

  local nowMs = Util.nowUtcMs()
  local refreshSec = sbEnabled and state.cfg:getNumber("scheduler_budget", "requests_refresh_interval_seconds", 5) or 0
  local refreshMs = (tonumber(refreshSec or 0) or 0) > 0 and (tonumber(refreshSec or 0) * 1000) or 0
  if refreshMs < 0 then refreshMs = 0 end

  local requests = state.requests
  if type(requests) ~= "table" then requests = {} end
  local shouldRefresh = (refreshMs == 0) or (not self._next_requests_refresh_at_ms) or
  (nowMs >= self._next_requests_refresh_at_ms)
  if shouldRefresh then
    local fresh, freshErr = self.mine:listRequests()
    if fresh == nil and isBudgetExceeded(freshErr) then
      publishSnapshot(state)
      self:_persistWorkMaybe()
      return
    end
    if type(fresh) == "table" then
      requests = fresh
      state.requests = fresh
    end
    self._next_requests_refresh_at_ms = nowMs + refreshMs
  else
    state.requests = requests
  end

  local colonyStats = state.cache and type(state.cache.get) == "function" and state.cache:get("mc", "stats") or nil
  if not colonyStats then
    local cs, csErr = self.mine:getColonyStats()
    if cs == nil and isBudgetExceeded(csErr) then
      publishSnapshot(state)
      self:_persistWorkMaybe()
      return
    end
    colonyStats = cs or {}
    if state.cache and type(state.cache.set) == "function" then
      state.cache:set("mc", "stats", colonyStats, 2)
    end
  end
  state.colonyStats = colonyStats

  local targetName, targetInv = resolveTarget(state.cfg)

  if not targetInv then
    state.logger:warn("Destino padrão indisponível; aguardando...",
      { target = state.cfg:get("delivery", "default_target_container", "") })
    for _, r in ipairs(requests or {}) do
      if r and r.id and isPendingState(state.cfg, r.state) then
        local work = self.work[r.id] or {}
        local needed = tonumber(r.requiredCount or r.count or 0) or 0
        work.status = "waiting_retry"
        work.request_state = r.state
        work.target = r.target
        work.err = "destino_indisponivel"
        work.needed = needed
        work.present_total = nil
        work.present = 0
        work.missing = needed
        work.next_retry = os.epoch("utc") + 5000
        self.work[r.id] = work
      end
    end
    publishSnapshot(state)
    self:_persistWorkMaybe()
    return
  end

  local snap, snapErr = getDestinationSnapshot(state, targetName, targetInv, false)
  if snap == nil and isBudgetExceeded(snapErr) then
    publishSnapshot(state)
    self:_persistWorkMaybe()
    return
  end
  local available = {}
  if type(snap) == "table" then
    for k, v in pairs(snap) do
      available[k] = tonumber(v or 0) or 0
    end
  end
  local buildings = state.cache and type(state.cache.get) == "function" and state.cache:get("mc", "buildings") or nil
  if not buildings then
    local b, bErr = self.mine:listBuildings()
    if b == nil and isBudgetExceeded(bErr) then
      publishSnapshot(state)
      self:_persistWorkMaybe()
      return
    end
    buildings = b or {}
    if state.cache and type(state.cache.set) == "function" then
      state.cache:set("mc", "buildings", buildings, 5)
    end
  end
  local citizens = state.cache and type(state.cache.get) == "function" and state.cache:get("mc", "citizens") or nil
  if not citizens then
    local c, cErr = self.mine:listCitizens()
    if c == nil and isBudgetExceeded(cErr) then
      publishSnapshot(state)
      self:_persistWorkMaybe()
      return
    end
    citizens = c or {}
    if state.cache and type(state.cache.set) == "function" then
      state.cache:set("mc", "citizens", citizens, 5)
    end
  end

  local nowEpoch = os.epoch("utc")
  local rqLimit = sbEnabled and state.cfg:getNumber("scheduler_budget", "requests_per_tick", 10) or 0
  rqLimit = tonumber(rqLimit or 0) or 0
  if rqLimit > 0 then rqLimit = math.floor(rqLimit) end
  if rqLimit <= 0 then rqLimit = math.huge end

  local function processOne(r)
    if not (r and r.id and isPendingState(state.cfg, r.state)) then
      return false, nil
    end

    local job = self.work[r.id]
    if job and job.next_retry and job.next_retry > nowEpoch then
      return false, nil
    end

    local building, buildingResolved = resolveBuildingForRequest(buildings, citizens, r.target)
    local candidate, why = pickCandidate(state, self.eq, self.tier, self.me, r, building, buildingResolved)
    local work = self.work[r.id] or {}
    work.request_state = r.state
    work.target = r.target
    work.requested = (r.accepted and r.accepted[1] and r.accepted[1].name) or
        (r.items and r.items[1] and r.items[1].name) or nil

    if not candidate then
      if isBudgetExceeded(why) then
        return nil, tostring(why)
      end
      do
        local reqItem = work.requested or ""
        local needed = tonumber(r.requiredCount or r.count or 0) or 0
        if snap and reqItem ~= "" then
          local presentTotal = Inventory.countFromSnapshot(snap, reqItem)
          local alloc = math.min(tonumber(available[reqItem] or 0) or 0, needed)
          available[reqItem] = (tonumber(available[reqItem] or 0) or 0) - alloc
          local missing = math.max(0, needed - alloc)
          work.needed = needed
          work.present_total = presentTotal
          work.present = alloc
          work.missing = missing
        else
          work.needed = needed
          work.present_total = nil
          work.present = 0
          work.missing = needed
        end
      end
      if type(why) == "table" and why.reason == "blocked_by_tier" then
        work.status = "blocked_by_tier"
        work.err = "blocked_by_tier"
        work.next_retry = os.epoch("utc") + 15000
      else
        if why == "nao_craftavel" then
          work.status = "waiting_retry"
          work.err = "nao_craftavel"
          work.next_retry = os.epoch("utc") + 15000
        else
          work.status = (why == "nao_suportado") and "unsupported" or "error"
          work.err = why
          work.next_retry = os.epoch("utc") + 15000
        end
      end
      self.work[r.id] = work
      if why == "nao_craftavel" then
        state.logger:warn("Item não craftável agora; aguardando...", { request = r.id, item = work.requested })
      else
        state.logger:warn("Request sem candidato", { request = r.id, reason = why })
      end
      return true, nil
    end

    work.chosen = candidate.name
    work.choice = why
    work.needed = tonumber(candidate.count or r.requiredCount or r.count or 0) or 0

    if not snap then
      work.status = "waiting_retry"
      work.err = snapErr
      work.next_retry = nowEpoch + 5000
      self.work[r.id] = work
      state.logger:warn("Falha ao ler destino", { request = r.id, err = snapErr })
      return true, nil
    end

    local presentTotal = Inventory.countFromSnapshot(snap, candidate.name)
    local alloc = math.min(tonumber(available[candidate.name] or 0) or 0, work.needed)
    available[candidate.name] = (tonumber(available[candidate.name] or 0) or 0) - alloc
    local missing = math.max(0, work.needed - alloc)
    work.present_total = presentTotal
    work.present = alloc
    work.missing = missing

    if missing <= 0 then
      work.status = "done"
      self.work[r.id] = work
      return true, nil
    end

    local meOnline, meErr = self.me:isOnline()
    if isBudgetExceeded(meErr) then
      return nil, tostring(meErr)
    end
    if not meOnline then
      work.status = "waiting_retry"
      local errStr = tostring(meErr or "")
      if errStr == "degraded" then
        work.err = "me_degraded"
        local nextAt = state.health and tonumber(state.health.next_me_retry_at_ms) or nil
        if nextAt and nextAt > os.epoch("utc") then
          work.next_retry = nextAt
        else
          work.next_retry = nowEpoch + 5000
        end
        if not work.logged_me_degraded then
          state.logger:warn("ME degraded; aguardando retry...", {
            request = r.id,
            next_retry_at_ms = work.next_retry
          })
          work.logged_me_degraded = true
        end
      else
        work.err = "me_offline:" .. errStr
        work.next_retry = nowEpoch + 5000
        work.logged_me_degraded = nil
        state.logger:warn("ME indisponível; aguardando...", { request = r.id, err = errStr })
      end
      self.work[r.id] = work
      return true, nil
    end
    work.logged_me_degraded = nil

    local meAmount, meAmountErr = getMeAmount(self.me, candidate.name)
    if meAmount == nil and isBudgetExceeded(meAmountErr) then
      return nil, tostring(meAmountErr)
    end
    local missingDest = missing
    local craftQty = math.max(0, missingDest - meAmount)
    local exportQty = math.min(meAmount, missingDest)

    if exportQty > 0 then
      local freeSpace, freeErr = Inventory.getFreeSpace(targetInv, candidate.name, candidate.maxStackSize, state)
      if freeSpace == nil and isBudgetExceeded(freeErr) then
        return nil, tostring(freeErr)
      end
      if not freeSpace then
        work.status = "waiting_retry"
        work.err = "erro_capacidade_destino:" .. tostring(freeErr or "")
        work.next_retry = nowEpoch + 5000
        state.logger:warn("Falha ao ler capacidade do destino", { request = r.id, err = freeErr })
        return true, nil
      end
      if freeSpace <= 0 then
        work.status = "waiting_retry"
        work.err = "destino_cheio_capacidade"
        work.next_retry = nowEpoch + 5000
        state.logger:info("Destino cheio, aguardando espaço", { request = r.id, item = candidate.name })
        exportQty = 0
        craftQty = 0
        return true, nil
      end
      exportQty = math.min(exportQty, freeSpace)
    end

    if craftQty > 0 then
      local lockTtlSeconds = 15
      local lockKey = tostring(candidate.name) .. "|" .. tostring(craftQty) .. "|" .. tostring(targetName)
      local locked = state.cache:get("craft_lock", lockKey)
      local crafting, craftErr = self.me:isCrafting({ name = candidate.name, count = craftQty })
      if crafting == nil and isBudgetExceeded(craftErr) then
        return nil, tostring(craftErr)
      end
      if crafting == true or locked then
        work.status = "crafting"
        work.craft = work.craft or {}
        work.craft.key = lockKey
        work.craft.last_seen = nowEpoch
      else
        local craftable, craftableErr = self.me:isCraftable({ name = candidate.name, count = craftQty })
        if craftable == nil and isBudgetExceeded(craftableErr) then
          return nil, tostring(craftableErr)
        end
        if craftable == false then
          work.status = "waiting_retry"
          work.err = "nao_craftavel:" .. tostring(craftableErr or "")
          work.next_retry = nowEpoch + 15000
          state.logger:warn("Item não craftável agora; aguardando...",
            { request = r.id, item = candidate.name, err = tostring(craftableErr) })
        else
          local started, startErr = self.me:craftItem({ name = candidate.name, count = craftQty })
          if started == nil and isBudgetExceeded(startErr) then
            return nil, tostring(startErr)
          end
          if started == nil and startErr == nil then
            started = true
            startErr = "retorno_nil"
          end
          if started == true then
            state.cache:set("craft_lock", lockKey, true, lockTtlSeconds)
            state.stats.crafted = state.stats.crafted + 1
            work.status = "crafting"
            work.craft = work.craft or {}
            work.craft.key = lockKey
            work.craft.started_at = nowEpoch
            work.craft.message = startErr
          else
            work.status = "waiting_retry"
            work.err = "craft_falhou:" .. tostring(startErr or "")
            work.next_retry = nowEpoch + 15000
            state.logger:warn("Falha ao iniciar craft",
              { request = r.id, item = candidate.name, err = tostring(startErr) })
          end
        end
      end
    end

    if exportQty > 0 then
      local exportMode = tostring(state.cfg:get("delivery", "export_mode", "auto") or "auto"):lower()
      local exportDirection = tostring(state.cfg:get("delivery", "export_direction", "up") or "up"):lower()
      local bufferName = tostring(state.cfg:get("delivery", "export_buffer_container", "") or "")

      if exportMode == "auto" then
        if self.me:supportsExportToPeripheral() then
          exportMode = "peripheral"
        elseif bufferName ~= "" then
          exportMode = "buffer"
        else
          exportMode = "direction"
        end
      end

      local beforeSnap, beforeErr = getDestinationSnapshot(state, targetName, targetInv, true)
      if beforeSnap == nil and isBudgetExceeded(beforeErr) then
        return nil, tostring(beforeErr)
      end
      if not beforeSnap then
        work.status = "waiting_retry"
        work.err = beforeErr
        work.next_retry = nowEpoch + 5000
        state.logger:warn("Falha ao ler destino antes da entrega", { request = r.id, err = beforeErr })
      else
        local exported, exportErr = nil, nil
        local pushed, pushErr = nil, nil

        if exportMode == "peripheral" then
          exported, exportErr = self.me:exportItem({ name = candidate.name, count = exportQty }, targetName)
        elseif exportMode == "direction" then
          exported, exportErr = self.me:exportItem({ name = candidate.name, count = exportQty }, exportDirection)
        elseif exportMode == "buffer" then
          local bufferInv = resolveInvByName(bufferName)
          if not bufferInv then
            exported, exportErr = 0, "export_buffer_indisponivel:" .. bufferName
          else
            exported, exportErr = self.me:exportItem({ name = candidate.name, count = exportQty }, exportDirection)
            if exported == nil and isBudgetExceeded(exportErr) then
              return nil, tostring(exportErr)
            end
            exported = tonumber(exported or 0) or 0
            if exported > 0 then
              pushed, pushErr = pushFromBuffer(bufferInv, targetName, candidate.name, exported, state)
              if pushed ~= nil and isBudgetExceeded(pushErr) then
                return nil, tostring(pushErr)
              end
              pushed = tonumber(pushed or 0) or 0
              if pushed <= 0 then
                exported, exportErr = 0, "push_buffer_falhou:" .. tostring(pushErr or "")
              end
            end
          end
        else
          exported, exportErr = 0, "export_mode_invalido:" .. tostring(exportMode)
        end

        if exported == nil and isBudgetExceeded(exportErr) then
          return nil, tostring(exportErr)
        end
        exported = tonumber(exported or 0) or 0
        if exported <= 0 then
          work.status = "waiting_retry"
          work.err = "destino_cheio_ou_export_falhou:" .. tostring(exportErr or "")
          work.next_retry = nowEpoch + 5000
          state.logger:warn("Entrega não ocorreu; aguardando...",
            { request = r.id, item = candidate.name, err = tostring(exportErr) })
        else
          local afterSnap, afterErr = getDestinationSnapshot(state, targetName, targetInv, true)
          if afterSnap == nil and isBudgetExceeded(afterErr) then
            return nil, tostring(afterErr)
          end
          if not afterSnap then
            work.status = "waiting_retry"
            work.err = "pos_entrega_snapshot_falhou:" .. tostring(afterErr or "")
            work.next_retry = nowEpoch + 5000
            state.logger:warn("Falha ao ler destino após entrega", { request = r.id, err = afterErr })
          else
            local beforeCount = Inventory.countFromSnapshot(beforeSnap, candidate.name)
            local afterCount = Inventory.countFromSnapshot(afterSnap, candidate.name)
            if afterCount < beforeCount then
              work.status = "waiting_retry"
              work.err = "pos_entrega_inconsistente"
              work.next_retry = nowEpoch + 5000
              state.logger:warn("Validação pós-entrega inconsistente; aguardando...",
                { request = r.id, item = candidate.name })
            else
              state.stats.delivered = state.stats.delivered + exported
              work.delivered = (work.delivered or 0) + exported
              work.present = afterCount
              work.missing = math.max(0, work.needed - afterCount)
              if work.missing <= 0 then
                work.status = "done"
              elseif work.status ~= "crafting" and work.status ~= "waiting_retry" then
                work.status = "pending"
              end
            end
          end
        end
      end
    end

    if not work.status then
      work.status = "pending"
    end

    local reqItem = (r.items and r.items[1] and r.items[1].name) or ""
    if candidate.name ~= reqItem then
      if not work.logged_substitution then
        state.stats.substitutions = state.stats.substitutions + 1
        state.logger:info("Substituindo item solicitado", {
          requestId = r.id,
          reqItem = reqItem,
          chosen = candidate.name
        })
        work.logged_substitution = true
      end
    end

    self.work[r.id] = work

    if type(why) == "table" and type(why.equivalents) == "table" and #why.equivalents > 1 then
      if not work.logged_equivalents then
        state.logger:info("Equivalências conhecidas para o item escolhido", {
          requestId = r.id,
          requested = reqItem,
          chosen = candidate.name,
          target = r.target,
          tier = why.tier,
          class = why.class,
          max_tier = why.max_tier,
          resolved = why.max_tier_resolved,
          source = why.max_tier_source,
          building = why.building,
        })
        work.logged_equivalents = true
      end
    end
    return true, nil
  end

  local n = type(requests) == "table" and #requests or 0
  if n > 0 then
    local idx = tonumber(self._rq_cursor or 1) or 1
    if idx < 1 then idx = 1 end
    if idx > n then idx = 1 end

    local scanned = 0
    local processed = 0
    while processed < rqLimit and scanned < n do
      local currentIdx = idx
      local r = requests[currentIdx]
      idx = currentIdx + 1
      if idx > n then idx = 1 end
      scanned = scanned + 1

      local did, budgetErr = processOne(r)
      if did == nil and budgetErr ~= nil then
        self._rq_cursor = currentIdx
        publishSnapshot(state)
        self:_persistWorkMaybe()
        return
      end
      if did == true then
        processed = processed + 1
      end
    end
    self._rq_cursor = idx
  else
    self._rq_cursor = 1
  end

  publishSnapshot(state)
  self:_persistWorkMaybe()
end

function Engine:updateHealthSnapshot(forceRefresh)
  local state = self.state
  state.health = state.health or {}

  local snap = nil
  if forceRefresh ~= true and state.cache and type(state.cache.get) == "function" then
    snap = state.cache:get("ui_health", "peripherals")
  end

  if not snap then
    snap = buildPeripheralHealth(state, self.me)
    if state.cache and type(state.cache.set) == "function" then
      local ttl = 1
      if state.cfg and type(state.cfg.getNumber) == "function" then
        ttl = state.cfg:getNumber("ui", "health_ttl_seconds", 1)
      end
      state.cache:set("ui_health", "peripherals", snap, ttl)
    end
  end

  state.health.peripherals = snap
  return snap
end

return {
  new = Engine.new,
  _test = {
    buildPeripheralHealth = buildPeripheralHealth,
  },
}
