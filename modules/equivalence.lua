local Util = require("lib.util")
local Schema = require("lib.schema")

local DB_PATH = "data/mappings.json"

local Equivalence = {}
Equivalence.__index = Equivalence

local CLASS_SET = {
  armor_helmet = true,
  armor_chestplate = true,
  armor_leggings = true,
  armor_boots = true,
  tool_pickaxe = true,
  tool_shovel = true,
  tool_axe = true,
  tool_hoe = true,
  tool_sword = true,
  tool_bow = true,
  tool_shield = true,
}

local function normalizeClass(v)
  if type(v) ~= "string" then return nil end
  local s = tostring(v):lower()
  s = s:gsub("[%s%-]+", "_")
  if CLASS_SET[s] then return s end
  return nil
end

local function normalizeTagKey(s)
  if not s then return nil end
  local t = tostring(s)
  if t:sub(1, 1) == "#" then t = t:sub(2) end
  return t
end

local function skeletonV2()
  return {
    version = 2,
    rules = {},
    tier_overrides = {},
    gating = { by_building_type = {} }
  }
end

local function normalizeDbShape(db)
  if type(db) ~= "table" then db = {} end
  local out = {
    version = 2,
    rules = {},
    tier_overrides = type(db.tier_overrides) == "table" and db.tier_overrides or {},
    gating = type(db.gating) == "table" and db.gating or { by_building_type = {} },
  }
  if type(out.gating.by_building_type) ~= "table" then out.gating.by_building_type = {} end
  if type(db.rules) == "table" then
    for i, v in ipairs(db.rules) do
      out.rules[i] = v
    end
  end
  return out
end

local function indexV2Rules(db)
  db._rules_by_item = {}
  db._rules_by_tag = {}
  if type(db.rules) ~= "table" then return end
  for _, r in ipairs(db.rules) do
    if type(r) == "table" and type(r.selector) == "string" then
      local selector = r.selector
      local isTag = selector:sub(1, 1) == "#"
      local kind = r.kind
      if kind ~= "item" and kind ~= "tag" then
        kind = isTag and "tag" or "item"
        r.kind = kind
      end
      r.class = normalizeClass(r.class)
      if kind == "tag" then
        local key = normalizeTagKey(selector)
        if key and key ~= "" then
          db._rules_by_tag[key] = r
        end
      else
        if selector ~= "" then
          db._rules_by_item[selector] = r
        end
      end
    end
  end
end

local function loadDb(state)
  if not fs.exists(DB_PATH) then
    local skeleton = skeletonV2()
    pcall(function()
      Util.writeFile(DB_PATH, Util.jsonEncode(skeleton))
    end)
    if state and state.logger then
      state.logger:info("data/mappings.json ausente; arquivo criado com estrutura mínima")
    end
    return skeleton
  end

  local txt = Util.readFile(DB_PATH)
  local ok, decoded = pcall(function()
    return Util.jsonDecode(txt)
  end)
  local db = ok and decoded or nil
  if type(db) ~= "table" then
    if state and state.logger then
      state.logger:warn("Falha ao ler data/mappings.json; usando defaults em memória", { err = tostring(decoded) })
    end
    db = skeletonV2()
  end
  db = normalizeDbShape(db)
  local validation = Schema.validateMappings(db)
  if not validation.ok and state and state.logger then
    for _, err in ipairs(validation.errors) do
      state.logger:warn("mappings.json invalido: " .. err)
    end
  end
  indexV2Rules(db)
  return db
end

function Equivalence.new(state)
  local db = loadDb(state)
  local initialTime = fs.exists(DB_PATH) and fs.attributes(DB_PATH).modified or 0
  return setmetatable({
    state = state,
    db = db,
    lastModified = initialTime
  }, Equivalence)
end

function Equivalence:reloadIfChanged()
  if not fs.exists(DB_PATH) then return end
  local currentModified = fs.attributes(DB_PATH).modified
  if currentModified > self.lastModified then
    self.lastModified = currentModified
    self.db = loadDb(self.state)
    if self.state and self.state.logger then
      self.state.logger:info("Mapeamentos recarregados automaticamente (hot-reload)")
    end
  end
end

function Equivalence:reload()
  self.db = loadDb(self.state)
end

function Equivalence:getItemMeta(name)
  return nil
end

function Equivalence:getTierOverride(name)
  return self.db.tier_overrides[name]
end

function Equivalence:isVanilla(name)
  if not name then return false end
  local s = tostring(name)
  return s:sub(1, 10) == "minecraft:" or s:sub(1, 17) == "domum_ornamentum:" or s:sub(1, 13) == "minecolonies:"
end

function Equivalence:isAllowed(name)
  if not name then return false end
  if self:isVanilla(name) then return true end
  return self.db._rules_by_item and self.db._rules_by_item[name] ~= nil
end

function Equivalence:getClass(name)
  if not name then return nil end
  return self:getClassFor({ name = name })
end

function Equivalence:getRuleForItem(name)
  if not name then return nil end
  return self.db._rules_by_item and self.db._rules_by_item[name] or nil
end

function Equivalence:getRuleForTags(tags)
  if type(tags) ~= "table" then return nil end
  if not self.db._rules_by_tag then return nil end
  for _, t in ipairs(tags) do
    if type(t) == "string" then
      local key = normalizeTagKey(t)
      local r = self.db._rules_by_tag[key]
      if r then return r end
    end
  end
  return nil
end

function Equivalence:getRuleFor(item)
  if type(item) ~= "table" then return nil end
  local r = item.name and self:getRuleForItem(item.name) or nil
  if r then return r end
  return self:getRuleForTags(item.tags)
end

function Equivalence:getClassFor(item)
  if type(item) ~= "table" then return nil end
  local r = self:getRuleFor(item)
  return r and r.class or nil
end

function Equivalence:getPreferEquivalentFor(item)
  local r = self:getRuleFor(item)
  if not r then return false, false end
  if r.prefer_equivalent == nil then return false, true end
  return r.prefer_equivalent == true, true
end

function Equivalence:isAllowedFor(item)
  if type(item) ~= "table" then return false end
  local name = item.name
  if not name then return false end
  if self:isVanilla(name) then return true end
  if self:getRuleForItem(name) then return true end
  if self:getRuleForTags(item.tags) then return true end
  return false
end

function Equivalence:getClassTiers(className)
  return nil
end

function Equivalence:getEquivalents(name)
  return { name }
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
