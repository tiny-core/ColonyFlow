local Util = require("lib.util")

local function loadDb(path)
  local txt = Util.readFile(path)
  if not txt then
    return { version = 1, classes = {}, items = {}, tier_overrides = {} }
  end
  local obj = Util.jsonDecode(txt)
  if type(obj) ~= "table" then
    return { version = 1, classes = {}, items = {}, tier_overrides = {} }
  end
  obj.items = obj.items or {}
  obj.classes = obj.classes or {}
  obj.tier_overrides = obj.tier_overrides or {}
  return obj
end

local function saveDb(path, db)
  Util.writeFile(path, Util.jsonEncode(db))
end

local function prompt(label)
  term.write(label .. ": ")
  return read()
end

local function ensureItem(db, name)
  db.items[name] = db.items[name] or { equivalents = {} }
  db.items[name].equivalents = db.items[name].equivalents or {}
  return db.items[name]
end

local function addEquivalent(list, name)
  for _, v in ipairs(list) do
    if v == name then return end
  end
  table.insert(list, name)
end

local function main()
  local path = "data/mappings.json"
  local db = loadDb(path)

  print("Editor de mapeamentos (equivalências/tier)")
  print("Arquivo: " .. path)
  print("")

  local a = prompt("Item A (ex: minecraft:iron_chestplate)")
  local b = prompt("Item B (equivalente)")
  local class = prompt("Classe (ex: ARMOR_CHEST)")
  local tier = prompt("Tier (ex: iron)")

  if a == "" or b == "" then
    print("Itens inválidos.")
    return
  end

  local itemA = ensureItem(db, a)
  local itemB = ensureItem(db, b)
  itemA.class = class ~= "" and class or itemA.class
  itemB.class = class ~= "" and class or itemB.class
  itemA.tier = tier ~= "" and tier or itemA.tier
  itemB.tier = tier ~= "" and tier or itemB.tier

  addEquivalent(itemA.equivalents, b)
  addEquivalent(itemB.equivalents, a)

  saveDb(path, db)
  print("")
  print("Salvo com sucesso.")
end

main()
