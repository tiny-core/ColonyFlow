if type(package) == "table" and type(package.path) == "string" then
  local cwd = shell and shell.dir() or ""
  if cwd == "" then
    package.path = "/?.lua;/?/init.lua;" .. package.path
  else
    package.path = "/" .. cwd .. "/?.lua;/" .. cwd .. "/?/init.lua;/?.lua;/?/init.lua;" .. package.path
  end
end

local Util = require("lib.util")

local PATH = "data/mappings.json"
local KEY = _G.keys

local CLASSES = {
  { group = "armor", label = "Armadura: Helmet", short = "HELMET", class_json = "armor_helmet" },
  { group = "armor", label = "Armadura: Chestplate", short = "CHESTPLATE", class_json = "armor_chestplate" },
  { group = "armor", label = "Armadura: Leggings", short = "LEGGINGS", class_json = "armor_leggings" },
  { group = "armor", label = "Armadura: Boots", short = "BOOTS", class_json = "armor_boots" },
  { group = "tool", label = "Tool: Pick", short = "PICK", class_json = "tool_pickaxe" },
  { group = "tool", label = "Tool: Shovel", short = "SHOVEL", class_json = "tool_shovel" },
  { group = "tool", label = "Tool: Axe", short = "AXE", class_json = "tool_axe" },
  { group = "tool", label = "Tool: Hoe", short = "HOE", class_json = "tool_hoe" },
  { group = "tool", label = "Tool: Sword", short = "SWORD", class_json = "tool_sword" },
  { group = "tool", label = "Tool: Bow", short = "BOW", class_json = "tool_bow" },
  { group = "tool", label = "Tool: Shield", short = "SHIELD", class_json = "tool_shield" },
}

local COMMON_TIERS = { "leather", "wood", "stone", "iron", "diamond", "netherite" }

local function trim(s)
  if not s then return "" end
  return Util.trim(tostring(s))
end

local function inferKind(selector)
  selector = tostring(selector or "")
  if selector:sub(1, 1) == "#" then return "tag" end
  return "item"
end

local function normalizeSelector(raw)
  local s = trim(raw)
  if s == "" then return nil, "vazio" end
  s = s:lower()
  local kind = inferKind(s)
  if kind == "tag" then
    local tag = s:sub(2)
    if tag == "" then return nil, "tag_invalida" end
    if not tag:find(":", 1, true) then return nil, "tag_sem_namespace" end
    return "#" .. tag, "tag"
  end
  if not s:find(":", 1, true) then return nil, "id_sem_namespace" end
  return s, "item"
end

local function normalizeDbShape(db)
  if type(db) ~= "table" then db = {} end
  local rules = {}
  if type(db.rules) == "table" then
    for i, v in ipairs(db.rules) do
      rules[i] = v
    end
  end
  local out = {
    version = 2,
    rules = rules,
    tier_overrides = type(db.tier_overrides) == "table" and db.tier_overrides or {},
    gating = type(db.gating) == "table" and db.gating or { by_building_type = {} },
  }
  if type(out.gating.by_building_type) ~= "table" then out.gating.by_building_type = {} end
  return out
end

local function loadDb()
  local txt = Util.readFile(PATH)
  local decoded = nil
  if txt and txt ~= "" then
    local ok, resOrErr = pcall(function() return Util.jsonDecode(txt) end)
    if ok then decoded = resOrErr end
  end
  return normalizeDbShape(decoded)
end

local function saveDb(db)
  Util.writeFile(PATH, Util.jsonEncode({
    version = 2,
    rules = db.rules or {},
    tier_overrides = db.tier_overrides or {},
    gating = db.gating or { by_building_type = {} },
  }))
end

local function prompt(label)
  term.write(label .. ": ")
  return read()
end

local function setCursor(x, y)
  term.setCursorPos(x, y)
end

local function clear()
  term.clear()
  setCursor(1, 1)
end

local function supportsColor()
  return colors and term and term.isColor and term.isColor()
end

local function withTextColor(c, fn)
  if not supportsColor() or not c then
    return fn()
  end
  local old = term.getTextColor()
  term.setTextColor(c)
  local ok, res = pcall(fn)
  term.setTextColor(old)
  if not ok then error(res, 2) end
  return res
end

local function clearLine()
  if term.clearLine then term.clearLine() end
end

local function classSuffixColor(group)
  if not supportsColor() then return nil end
  if group == "armor" then return colors.orange end
  if group == "tool" then return colors.lightBlue end
  return colors.lightGray
end

local function headerColor()
  if not supportsColor() then return nil end
  return colors.cyan
end

local function subtitleColor()
  if not supportsColor() then return nil end
  return colors.lightGray
end

local function separatorColor()
  if not supportsColor() then return nil end
  return colors.gray
end

local function prefixColor(selected)
  if not supportsColor() then return nil end
  return selected and colors.yellow or colors.gray
end

local function defaultItemTextColor(selected)
  if not supportsColor() then return nil end
  return selected and colors.white or colors.lightGray
end

local function printSeparator(w)
  local line = ("-"):rep(math.max(1, w))
  withTextColor(separatorColor(), function()
    print(line)
  end)
end

local function selectList(title, subtitle, labels, initialIdx)
  local w, h = term.getSize()
  local idx = initialIdx or 1
  if idx < 1 then idx = 1 end
  if idx > #labels then idx = #labels end
  local top = 1

  local function isSeparator(i)
    local it = labels[i]
    return type(it) == "table" and it.separator == true
  end

  local function clampToSelectable(i, dir)
    if #labels == 0 then return 0 end
    local step = dir or 1
    local tries = 0
    while i >= 1 and i <= #labels and isSeparator(i) and tries < (#labels + 2) do
      i = i + step
      tries = tries + 1
    end
    if i < 1 then
      i = 1
      while i <= #labels and isSeparator(i) do i = i + 1 end
    elseif i > #labels then
      i = #labels
      while i >= 1 and isSeparator(i) do i = i - 1 end
    end
    if i < 1 then i = 1 end
    if i > #labels then i = #labels end
    return i
  end

  idx = clampToSelectable(idx, 1)

  while true do
    clear()
    withTextColor(headerColor(), function()
      print(title)
    end)
    if subtitle and subtitle ~= "" then
      withTextColor(subtitleColor(), function()
        print(subtitle)
      end)
    end
    printSeparator(w)

    local baseY = (subtitle and subtitle ~= "") and 4 or 3
    local listHeight = h - 4
    if listHeight < 1 then listHeight = 1 end
    if idx < top then top = idx end
    if idx > (top + listHeight - 1) then top = idx - listHeight + 1 end
    if top < 1 then top = 1 end

    for i = top, math.min(#labels, top + listHeight - 1) do
      local y = baseY + (i - top)
      setCursor(1, y)
      clearLine()

      local selected = i == idx
      local prefix = selected and "> " or "  "

      local item = labels[i]
      if type(item) == "table" and item.separator == true then
        withTextColor(separatorColor(), function()
          term.write(("-"):rep(math.max(1, w)))
        end)
      elseif type(item) == "table" then
        local text = tostring(item.text or "")
        local suffix = tostring(item.suffix or "")
        local suffixColor = item.suffixColor
        local textColor = item.textColor or defaultItemTextColor(selected)

        local remain = w - #prefix
        if remain < 0 then remain = 0 end

        local suffixWithSpace = suffix ~= "" and (" " .. suffix) or ""
        local showSuffix = suffixWithSpace ~= "" and remain > #suffixWithSpace
        local textMax = showSuffix and (remain - #suffixWithSpace) or remain

        if #text > textMax then text = text:sub(1, textMax) end
        if not showSuffix then suffixWithSpace = "" end

        withTextColor(prefixColor(selected), function()
          term.write(prefix)
        end)
        withTextColor(textColor, function()
          term.write(text)
        end)
        withTextColor(suffixColor, function()
          term.write(suffixWithSpace)
        end)
      else
        local line = prefix .. tostring(item)
        if #line > w then line = line:sub(1, w) end
        withTextColor(prefixColor(selected), function()
          term.write(prefix)
        end)
        withTextColor(defaultItemTextColor(selected), function()
          term.write(line:sub(#prefix + 1))
        end)
      end
    end

    local ev, a = os.pullEvent()
    if ev == "key" then
      if KEY and a == KEY.up then
        idx = clampToSelectable(math.max(1, idx - 1), -1)
      elseif KEY and a == KEY.down then
        idx = clampToSelectable(math.min(#labels, idx + 1), 1)
      elseif KEY and a == KEY.enter then
        return idx, "enter"
      elseif KEY and a == KEY.left then
        return nil, "back"
      elseif KEY and a == KEY.right then
        return idx, "enter"
      end
    end
  end
end

local function rulesIndexBySelector(db)
  local idx = {}
  for i, r in ipairs(db.rules or {}) do
    if type(r) == "table" and type(r.selector) == "string" then
      idx[r.selector] = i
    end
  end
  return idx
end

local function sortRules(db)
  table.sort(db.rules, function(a, b)
    return tostring(a.selector or "") < tostring(b.selector or "")
  end)
end

local function pickClass(current)
  local labels = {}
  local initial = 1
  local outIdx = 0
  local insertedSep = false
  for _, c in ipairs(CLASSES) do
    if c.group == "tool" and not insertedSep then
      outIdx = outIdx + 1
      labels[outIdx] = { separator = true }
      insertedSep = true
    end
    outIdx = outIdx + 1
    labels[outIdx] = {
      text = c.label,
      suffix = "(" .. tostring(c.short or c.value) .. ")",
      suffixColor = classSuffixColor(c.group),
      classValue = c.class_json,
    }
    if current and c.class_json == current then initial = outIdx end
  end
  local idx, why = selectList("Selecionar classe", "Enter confirma | <- volta", labels, initial)
  if why ~= "enter" or not idx then return nil, "back" end
  local chosen = labels[idx]
  if type(chosen) ~= "table" or chosen.separator == true then return nil, "back" end
  return chosen.classValue, "ok"
end

local function pickPrefer(currentBool)
  local labels = {
    { text = "Vanilla-first", suffix = "(prioriza vanilla)", suffixColor = separatorColor() },
    { text = "Equivalent-first", suffix = "(prioriza equivalente)", suffixColor = separatorColor() },
  }
  local initial = (currentBool == true) and 2 or 1
  local idx, why = selectList("Prioridade", "Enter confirma | <- volta", labels, initial)
  if why ~= "enter" or not idx then return nil, "back" end
  return idx == 2, "ok"
end

local function pickTierOverride(current)
  local tlabels = {}
  tlabels[1] = "Sem override"
  tlabels[2] = { separator = true }
  local initialTier = 3
  for i, t in ipairs(COMMON_TIERS) do
    tlabels[i + 2] = t
    if current == t then initialTier = i + 2 end
  end

  local tidx, twhy = selectList("Selecionar tier", "Enter confirma | <- volta", tlabels, initialTier)
  if twhy ~= "enter" or not tidx then return current, "keep" end
  if tidx == 1 then return nil, "remove" end
  if type(tlabels[tidx]) == "table" and tlabels[tidx].separator == true then return current, "keep" end
  return COMMON_TIERS[tidx - 2], "set"
end

local function upsertRule(db, rule)
  local idxBy = rulesIndexBySelector(db)
  local existingIdx = idxBy[rule.selector]
  if existingIdx then
    db.rules[existingIdx] = rule
  else
    table.insert(db.rules, rule)
  end
  sortRules(db)
end

local function removeRule(db, selector)
  local out = {}
  for _, r in ipairs(db.rules or {}) do
    if type(r) == "table" and r.selector ~= selector then
      table.insert(out, r)
    end
  end
  db.rules = out
end

local function addRuleFlow(db)
  while true do
    clear()
    print("Adicionar regra")
    print("Digite ID (mod:item) ou tag (#namespace:tag/path)")
    local raw = prompt("Selector")
    local selector, kindOrErr = normalizeSelector(raw)
    if selector then
      local className, cwhy = pickClass(nil)
      if cwhy ~= "ok" then return db end

      local preferEq, pwhy = pickPrefer(false)
      if pwhy ~= "ok" then return db end

      local kind = kindOrErr
      local tierOverride = nil
      if kind == "item" then
        tierOverride = db.tier_overrides[selector]
        local t, twhy = pickTierOverride(tierOverride)
        if twhy == "back" then return db end
        tierOverride = t
      end

      local rule = {
        selector = selector,
        kind = kind,
        class = className,
        prefer_equivalent = preferEq
      }

      upsertRule(db, rule)
      if kind == "item" then
        if tierOverride == nil then
          db.tier_overrides[selector] = nil
        else
          db.tier_overrides[selector] = tierOverride
        end
      end
      saveDb(db)
      return db
    end

    local err = kindOrErr
    if err == "vazio" then
      return db
    end
    clear()
    print("Formato invalido para selector.")
    if err == "id_sem_namespace" then
      print("Use mod:item (ex: mekanism:jetpack).")
    elseif err == "tag_sem_namespace" then
      print("Use #namespace:tag/path (ex: #forge:tools/pickaxes).")
    else
      print("Use mod:item ou #namespace:tag/path.")
    end
    print("")
    print("Pressione Enter para tentar novamente...")
    read()
  end
end

local function editRuleFlow(db, rule)
  while true do
    local labels = {
      "Alterar classe",
      "Alterar prioridade",
    }
    if rule.kind == "item" then
      table.insert(labels, "Tier override")
    end
    table.insert(labels, "Remover regra")
    table.insert(labels, "Voltar")

    local subtitle = ("Selector: %s | Classe: %s | prefer_equivalent=%s"):format(rule.selector, tostring(rule.class), tostring(rule.prefer_equivalent == true))
    local idx, why = selectList("Editar regra", subtitle, labels, 1)
    if why ~= "enter" or not idx then return db end

    local chosen = labels[idx]
    if chosen == "Alterar classe" then
      local className, cwhy = pickClass(rule.class)
      if cwhy == "ok" then
        rule.class = className
        upsertRule(db, rule)
        saveDb(db)
      end
    elseif chosen == "Alterar prioridade" then
      local preferEq, pwhy = pickPrefer(rule.prefer_equivalent == true)
      if pwhy == "ok" then
        rule.prefer_equivalent = preferEq
        upsertRule(db, rule)
        saveDb(db)
      end
    elseif chosen == "Tier override" and rule.kind == "item" then
      local current = db.tier_overrides[rule.selector]
      local t, twhy = pickTierOverride(current)
      if twhy ~= "back" then
        db.tier_overrides[rule.selector] = t
        saveDb(db)
      end
    elseif chosen == "Remover regra" then
      local confirm, cwhy = selectList("Confirmar remocao", "Enter confirma | <- cancela", { "Nao", "Sim" }, 1)
      if cwhy == "enter" and confirm == 2 then
        removeRule(db, rule.selector)
        if rule.kind == "item" then
          db.tier_overrides[rule.selector] = nil
        end
        saveDb(db)
        return db
      end
    else
      return db
    end
  end
end

local function manageRules(db)
  local filter = ""
  while true do
    local labels = { "Adicionar regra", "Buscar/filtro", "Voltar", { separator = true } }
    local rules = {}
    for _, r in ipairs(db.rules or {}) do
      if type(r) == "table" and type(r.selector) == "string" then
        local line = ("%s  %s  prefer_equivalent=%s"):format(r.selector, tostring(r.class or ""), tostring(r.prefer_equivalent == true))
        if filter == "" or line:lower():find(filter:lower(), 1, true) then
          table.insert(rules, { rule = r, label = line })
        end
      end
    end
    for _, rr in ipairs(rules) do table.insert(labels, rr.label) end

    local subtitle = ("Arquivo: %s | Regras: %d | Filtro: %s"):format(PATH, #db.rules, filter ~= "" and filter or "(nenhum)")
    local idx, why = selectList("Regras", subtitle, labels, 1)
    if why ~= "enter" or not idx then return db end

    local chosen = labels[idx]
    if chosen == "Adicionar regra" then
      db = addRuleFlow(db)
    elseif chosen == "Buscar/filtro" then
      clear()
      print("Filtro atual: " .. (filter ~= "" and filter or "(nenhum)"))
      local v = prompt("Novo filtro (vazio limpa)")
      filter = trim(v)
    elseif chosen == "Voltar" then
      return db
    else
      local ruleIdx = idx - 4
      local r = rules[ruleIdx] and rules[ruleIdx].rule or nil
      if r then
        db = editRuleFlow(db, r)
      end
    end
  end
end

local function main()
  local db = loadDb()
  while true do
    local labels = { "Regras", "Sair" }
    local idx, why = selectList("Editor de mapeamentos", ("Arquivo: %s"):format(PATH), labels, 1)
    if why ~= "enter" or not idx then break end
    if labels[idx] == "Regras" then
      db = loadDb()
      db = manageRules(db)
    else
      break
    end
  end
  clear()
end

main()
