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

local function resolveInvByName(name)
  if not name or name == "" then return nil end
  if not peripheral.isPresent(name) then return nil end
  return peripheral.wrap(name)
end

local function pushFromBuffer(bufferInv, targetName, itemName, qty)
  if not bufferInv then return 0, "buffer_indisponivel" end
  if type(bufferInv.list) ~= "function" then return 0, "buffer_sem_list" end
  if type(bufferInv.pushItems) ~= "function" then return 0, "buffer_sem_pushItems" end
  local list = bufferInv.list()
  if type(list) ~= "table" then return 0, "buffer_list_invalida" end
  local movedTotal = 0
  local remaining = tonumber(qty or 0) or 0
  for slot, stack in pairs(list) do
    if remaining <= 0 then break end
    if type(stack) == "table" and stack.name == itemName then
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
  local snap, err = Inventory.snapshot(targetInv)
  if not snap then return nil, err end
  state.cache:set("dest", targetName, snap, ttl)
  return snap, nil
end

local function getMeAmount(me, itemName)
  if not me then return 0 end
  if type(me.getItem) == "function" then
    local res = me:getItem({ name = itemName })
    if type(res) == "table" then
      local n = tonumber(res.amount or 0) or 0
      if n > 0 then return n end
    end
  end
  if type(me.listItems) ~= "function" then return 0 end
  local list = me:listItems({ name = itemName })
  if type(list) ~= "table" then return 0 end
  local total = 0
  for _, v in pairs(list) do
    if type(v) == "table" and v.name == itemName then
      total = total + (tonumber(v.amount or v.count or 0) or 0)
    end
  end
  return total
end

local function isMeCraftable(me, itemName, count)
  if not me then return nil, nil end
  if type(me.getItem) == "function" then
    local res = me:getItem({ name = itemName })
    if type(res) == "table" and res.isCraftable ~= nil then
      return res.isCraftable == true, nil
    end
  end
  if type(me.isCraftable) ~= "function" then return nil, nil end
  return me:isCraftable({ name = itemName, count = count })
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

  local blockedByTier = {}
  local best, bestWhy, bestScore = nil, nil, -math.huge
  for idx, it in ipairs(eligible) do
    local className = eq:getClass(it.name) or guessClass(it.name)
    local t, tierWhy = tier:infer({ name = it.name, tags = it.tags })
    local maxTier, maxTierResolved, maxTierSource = getMaxTier(eq, className, building, buildingResolved)
    if t then
      local allowedByTier = maxTier and tier:isTierAllowed(className, t, maxTier) or false
      if not allowedByTier then
        table.insert(blockedByTier, { name = it.name, class = className, tier = t, max = maxTier })
        goto continue_item
      end
    end
    local amount = getMeAmount(me, it.name)
    local craftable, craftableErr = nil, nil
    if amount <= 0 then
      craftable, craftableErr = isMeCraftable(me, it.name,
        tonumber(it.count or request.requiredCount or request.count or 1) or 1)
    end
    local score = 0

    if amount > 0 then score = score + 10000 end
    if craftable == true then score = score + 5000 end
    if craftable == false then score = score - 5000 end

    local isVanilla = eq:isVanilla(it.name)
    if vanillaFirst then
      if isVanilla then score = score + 100 end
    else
      if not isVanilla then score = score + 100 end
    end

    local enforceGating = state.cfg:getBool("progression", "enforce_building_gating", true)
    local tierPrefEff = tierPref
    if enforceGating and maxTierResolved then
      tierPrefEff = "highest"
    end

    local rank = tierRank(eq, className, t)
    if rank then
      if tierPrefEff == "highest" then
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
    return nil, "sem_candidato"
  end
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
  local available = {}
  if type(snap) == "table" then
    for k, v in pairs(snap) do
      available[k] = tonumber(v or 0) or 0
    end
  end
  local buildings = state.cache:get("mc", "buildings")
  if not buildings then
    buildings = self.mine:listBuildings()
    state.cache:set("mc", "buildings", buildings, 5)
  end
  local citizens = state.cache:get("mc", "citizens")
  if not citizens then
    citizens = self.mine:listCitizens()
    state.cache:set("mc", "citizens", citizens, 5)
  end

  for _, r in ipairs(requests) do
    if r and r.id and isPendingState(state.cfg, r.state) then
      local job = self.work[r.id]
      if job and job.next_retry and job.next_retry > os.epoch("utc") then
        goto continue
      end

      local building, buildingResolved = resolveBuildingForRequest(buildings, citizens, r.target)
      local candidate, why = pickCandidate(state, self.eq, self.tier, self.me, r, building, buildingResolved)
      local work = self.work[r.id] or {}
      work.request_state = r.state
      work.target = r.target
      work.requested = (r.accepted and r.accepted[1] and r.accepted[1].name) or
          (r.items and r.items[1] and r.items[1].name) or nil

      if not candidate then
        if type(why) == "table" and why.reason == "blocked_by_tier" then
          work.status = "blocked_by_tier"
          work.err = "blocked_by_tier"
          work.next_retry = os.epoch("utc") + 15000
        else
          work.status = (why == "nao_suportado") and "unsupported" or "error"
          work.err = why
          work.next_retry = os.epoch("utc") + 15000
        end
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
        goto continue
      end

      local meOnline, meErr = self.me:isOnline()
      if not meOnline then
        work.status = "waiting_retry"
        work.err = "me_offline:" .. tostring(meErr or "")
        work.next_retry = os.epoch("utc") + 5000
        self.work[r.id] = work
        state.logger:warn("ME indisponível; aguardando...", { request = r.id, err = tostring(meErr) })
        goto continue
      end

      local meAmount = getMeAmount(self.me, candidate.name)
      local missingDest = missing
      local craftQty = math.max(0, missingDest - meAmount)
      local exportQty = math.min(meAmount, missingDest)

      if exportQty > 0 then
        local freeSpace, freeErr = Inventory.getFreeSpace(targetInv, candidate.name, candidate.maxStackSize)
        if not freeSpace then
          work.status = "waiting_retry"
          work.err = "erro_capacidade_destino:" .. tostring(freeErr or "")
          work.next_retry = os.epoch("utc") + 5000
          state.logger:warn("Falha ao ler capacidade do destino", { request = r.id, err = freeErr })
          goto continue
        end
        if freeSpace <= 0 then
          work.status = "waiting_retry"
          work.err = "destino_cheio_capacidade"
          work.next_retry = os.epoch("utc") + 5000
          state.logger:info("Destino cheio, aguardando espaço", { request = r.id, item = candidate.name })
          exportQty = 0
          craftQty = 0
          goto continue
        end
        exportQty = math.min(exportQty, freeSpace)
      end

      if craftQty > 0 then
        local lockTtlSeconds = 15
        local lockKey = tostring(candidate.name) .. "|" .. tostring(craftQty) .. "|" .. tostring(targetName)
        local locked = state.cache:get("craft_lock", lockKey)
        local crafting, craftErr = self.me:isCrafting({ name = candidate.name, count = craftQty })
        if crafting == true or locked then
          work.status = "crafting"
          work.craft = work.craft or {}
          work.craft.key = lockKey
          work.craft.last_seen = os.epoch("utc")
        else
          local craftable, craftableErr = self.me:isCraftable({ name = candidate.name, count = craftQty })
          if craftable == false then
            work.status = "waiting_retry"
            work.err = "nao_craftavel:" .. tostring(craftableErr or "")
            work.next_retry = os.epoch("utc") + 15000
            state.logger:warn("Item não craftável agora; aguardando...",
              { request = r.id, item = candidate.name, err = tostring(craftableErr) })
          else
            local started, startErr = self.me:craftItem({ name = candidate.name, count = craftQty })
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
              work.craft.started_at = os.epoch("utc")
              work.craft.message = startErr
            else
              work.status = "waiting_retry"
              work.err = "craft_falhou:" .. tostring(startErr or "")
              work.next_retry = os.epoch("utc") + 15000
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
        if not beforeSnap then
          work.status = "waiting_retry"
          work.err = beforeErr
          work.next_retry = os.epoch("utc") + 5000
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
              exported = tonumber(exported or 0) or 0
              if exported > 0 then
                pushed, pushErr = pushFromBuffer(bufferInv, targetName, candidate.name, exported)
                pushed = tonumber(pushed or 0) or 0
                if pushed <= 0 then
                  exported, exportErr = 0, "push_buffer_falhou:" .. tostring(pushErr or "")
                end
              end
            end
          else
            exported, exportErr = 0, "export_mode_invalido:" .. tostring(exportMode)
          end

          exported = tonumber(exported or 0) or 0
          if exported <= 0 then
            work.status = "waiting_retry"
            work.err = "destino_cheio_ou_export_falhou:" .. tostring(exportErr or "")
            work.next_retry = os.epoch("utc") + 5000
            state.logger:warn("Entrega não ocorreu; aguardando...",
              { request = r.id, item = candidate.name, err = tostring(exportErr) })
          else
            local afterSnap, afterErr = getDestinationSnapshot(state, targetName, targetInv, true)
            if not afterSnap then
              work.status = "waiting_retry"
              work.err = "pos_entrega_snapshot_falhou:" .. tostring(afterErr or "")
              work.next_retry = os.epoch("utc") + 5000
              state.logger:warn("Falha ao ler destino após entrega", { request = r.id, err = afterErr })
            else
              local beforeCount = Inventory.countFromSnapshot(beforeSnap, candidate.name)
              local afterCount = Inventory.countFromSnapshot(afterSnap, candidate.name)
              if afterCount < beforeCount then
                work.status = "waiting_retry"
                work.err = "pos_entrega_inconsistente"
                work.next_retry = os.epoch("utc") + 5000
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

      self.work[r.id] = work

      if type(why) == "table" and type(why.equivalents) == "table" and #why.equivalents > 1 then
        state.stats.substitutions = state.stats.substitutions + 1
        state.logger:info("Equivalências conhecidas para o item escolhido", {
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
