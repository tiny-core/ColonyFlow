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
  return db
end

function Equivalence.new(state)
  return setmetatable({
    state = state,
    db = loadDb(),
  }, Equivalence)
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

return {
  new = Equivalence.new,
}
