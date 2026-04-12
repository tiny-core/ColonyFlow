local Tier = {}
Tier.__index = Tier

local TIERS_TOOL = { wood = 1, stone = 2, iron = 3, diamond = 4, netherite = 5 }
local TIERS_ARMOR = { leather = 1, iron = 2, diamond = 3, netherite = 4 }

local function tierFromName(name)
  if not name then return nil end
  local n = name:lower()
  if n:find("netherite", 1, true) then return "netherite" end
  if n:find("diamond", 1, true) then return "diamond" end
  if n:find("iron", 1, true) then return "iron" end
  if n:find("gold", 1, true) or n:find("golden", 1, true) then return "iron" end
  if n:find("stone", 1, true) then return "stone" end
  if n:find("wood", 1, true) or n:find("wooden", 1, true) then return "wood" end
  if n:find("leather", 1, true) then return "leather" end
  return nil
end

local function tierFromTags(tags)
  if type(tags) ~= "table" then return nil end
  for _, t in ipairs(tags) do
    if type(t) == "string" then
      local s = t:lower()
      if s:find("netherite", 1, true) then return "netherite" end
      if s:find("diamond", 1, true) then return "diamond" end
      if s:find("iron", 1, true) then return "iron" end
      if s:find("stone", 1, true) then return "stone" end
      if s:find("wood", 1, true) then return "wood" end
      if s:find("leather", 1, true) then return "leather" end
    end
  end
  return nil
end

function Tier.new(state, equivalence)
  return setmetatable({ state = state, eq = equivalence }, Tier)
end

function Tier:infer(item)
  local name = item and item.name or nil
  if not name then return nil, "sem_nome" end

  local override = self.eq and self.eq:getTierOverride(name) or nil
  if override then return override, "override" end

  local t1 = tierFromTags(item.tags)
  if t1 then return t1, "tags" end

  local t2 = tierFromName(name)
  if t2 then return t2, "name" end

  return nil, "unknown"
end

function Tier:isTierAllowed(className, tier, maxTier)
  if not tier or not maxTier then return false end
  if type(className) == "string" and className:match("^armor_") then
    return (TIERS_ARMOR[tier] or 0) <= (TIERS_ARMOR[maxTier] or 0)
  end
  return (TIERS_TOOL[tier] or 0) <= (TIERS_TOOL[maxTier] or 0)
end

return {
  new = Tier.new,
}
