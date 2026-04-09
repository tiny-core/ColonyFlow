local Util = require("lib.util")

local DB_PATH = "data/mappings.json"

local Equivalence = {}
Equivalence.__index = Equivalence

local function loadDb()
  local txt = Util.readFile(DB_PATH)
  local db = Util.jsonDecode(txt) or {}
  db.items = db.items or {}
  db.classes = db.classes or {}
  db.tier_overrides = db.tier_overrides or {}
  db.gating = db.gating or {}
  db.gating.by_building_type = db.gating.by_building_type or {}
  return db
end

function Equivalence.new(state)
  local initialTime = fs.exists(DB_PATH) and fs.attributes(DB_PATH).modified or 0
  return setmetatable({
    state = state,
    db = loadDb(),
    lastModified = initialTime
  }, Equivalence)
end

function Equivalence:reloadIfChanged()
  if not fs.exists(DB_PATH) then return end
  local currentModified = fs.attributes(DB_PATH).modified
  if currentModified > self.lastModified then
    self.lastModified = currentModified
    self.db = loadDb()
    if self.state and self.state.logger then
      self.state.logger:info("Mapeamentos recarregados automaticamente (hot-reload)")
    end
  end
end

function Equivalence:reload()
  self.db = loadDb()
end

function Equivalence:getItemMeta(name)
  return self.db.items[name]
end

function Equivalence:getTierOverride(name)
  return self.db.tier_overrides[name]
end

function Equivalence:isVanilla(name)
  if not name then return false end
  return tostring(name):sub(1, 10) == "minecraft:"
end

function Equivalence:isAllowed(name)
  if not name then return false end
  if self:isVanilla(name) then return true end
  return self.db.items[name] ~= nil
end

function Equivalence:getClass(name)
  local meta = self.db.items[name]
  return meta and meta.class or nil
end

function Equivalence:getClassTiers(className)
  local c = className and self.db.classes[className] or nil
  local tiers = c and c.tiers or nil
  if type(tiers) ~= "table" then return nil end
  return tiers
end

function Equivalence:getEquivalents(name)
  local meta = self.db.items[name]
  local out = { name }
  if meta and type(meta.equivalents) == "table" then
    for _, eq in ipairs(meta.equivalents) do
      if eq and eq ~= name then table.insert(out, eq) end
    end
  end
  return out
end

function Equivalence:getGatingMaxTier(buildingType, className)
  if not buildingType or not className then return nil end
  local byType = self.db.gating and self.db.gating.by_building_type or nil
  if type(byType) ~= "table" then return nil end
  local t = byType[buildingType]
  if type(t) ~= "table" then return nil end
  return t[className]
end

return {
  new = Equivalence.new,
}
