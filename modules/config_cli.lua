if type(package) == "table" and type(package.path) == "string" then
  local cwd = shell and shell.dir() or ""
  if cwd == "" then
    package.path = "/?.lua;/?/init.lua;" .. package.path
  else
    package.path = "/" .. cwd .. "/?.lua;/" .. cwd .. "/?/init.lua;/?.lua;/?/init.lua;" .. package.path
  end
end

local Util = require("lib.util")
local Config = require("lib.config")
local Schema = require("lib.config_schema")

local KEY = _G.keys
local PATH = "config.ini"

local function trim(s)
  return Util.trim(tostring(s or ""))
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

local function setCursor(x, y)
  term.setCursorPos(x, y)
end

local function clear()
  term.clear()
  setCursor(1, 1)
end

local function clearLine()
  if term.clearLine then term.clearLine() end
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

local function prompt(label, current)
  clear()
  print(label)
  if current ~= nil and current ~= "" then
    print("Atual: " .. tostring(current))
  end
  term.write("Novo (vazio mantem): ")
  local v = read()
  v = tostring(v or "")
  if trim(v) == "" then return nil end
  return v
end

local function listPeripherals()
  local ok, names = pcall(peripheral.getNames)
  if not ok or type(names) ~= "table" then return {} end
  table.sort(names, function(a, b) return tostring(a) < tostring(b) end)
  return names
end

local function suggestByType(typeName)
  local ok, dev = pcall(peripheral.find, typeName)
  if not ok or not dev then return nil end
  local ok2, name = pcall(peripheral.getName, dev)
  if ok2 and name then return tostring(name) end
  return nil
end

local function isPresentAndWrap(name)
  local ok, present = pcall(peripheral.isPresent, name)
  if not ok or not present then return false end
  local ok2, devOrErr = pcall(peripheral.wrap, name)
  if not ok2 or not devOrErr then return false end
  return true
end

local function showLines(title, lines)
  clear()
  print(title)
  print("")
  for _, l in ipairs(lines or {}) do
    print(tostring(l))
  end
  print("")
  print("Enter para voltar...")
  read()
end

local function loadCfg()
  return Config.load(PATH)
end

local function loadRaw()
  return Util.readFile(PATH) or ""
end

local function buildEffective(cfg, updates)
  local function v(section, key)
    if updates[section] and updates[section][key] ~= nil then
      return updates[section][key]
    end
    return cfg:get(section, key, "")
  end

  return {
    peripherals = {
      colony_integrator = v("peripherals", "colony_integrator"),
      me_bridge = v("peripherals", "me_bridge"),
      modem = v("peripherals", "modem"),
      monitor_requests = v("peripherals", "monitor_requests"),
      monitor_status = v("peripherals", "monitor_status"),
    },
    core = {
      poll_interval_seconds = v("core", "poll_interval_seconds"),
      ui_refresh_seconds = v("core", "ui_refresh_seconds"),
      log_level = v("core", "log_level"),
      log_dir = v("core", "log_dir"),
      log_max_files = v("core", "log_max_files"),
      log_max_kb = v("core", "log_max_kb"),
    },
    delivery = {
      default_target_container = v("delivery", "default_target_container"),
      export_mode = v("delivery", "export_mode"),
      export_direction = v("delivery", "export_direction"),
      export_buffer_container = v("delivery", "export_buffer_container"),
      destination_cache_ttl_seconds = v("delivery", "destination_cache_ttl_seconds"),
    }
  }
end

local function buildChangedOnly(cfg, updates)
  local out = { peripherals = {}, core = {}, delivery = {} }
  for section, kv in pairs(updates) do
    for k, newVal in pairs(kv) do
      local cur = cfg:get(section, k, "")
      if tostring(newVal) ~= tostring(cur) then
        out[section][k] = newVal
      end
    end
  end
  if next(out.peripherals) == nil then out.peripherals = nil end
  if next(out.core) == nil then out.core = nil end
  if next(out.delivery) == nil then out.delivery = nil end
  return out
end

local function previewChanges(rawText, updatesBySection)
  local patched = Config.patchIniText(rawText, updatesBySection)
  local lines = {}
  for _, c in ipairs(patched.changes or {}) do
    local old = c.old ~= nil and tostring(c.old) or "(vazio)"
    local newV = c.new ~= nil and tostring(c.new) or "(vazio)"
    table.insert(lines, ("%s.%s: %s -> %s"):format(tostring(c.section), tostring(c.key), old, newV))
  end
  if #lines == 0 then
    table.insert(lines, "Nenhuma mudanca.")
  end
  showLines("Preview", lines)
  return patched
end

local function confirmSave()
  term.write("Salvar? (s/n): ")
  local v = tostring(read() or ""):lower()
  return v == "s" or v == "sim" or v == "y" or v == "yes"
end

local function saveIni(cfg, updates)
  local raw = loadRaw()
  local effective = buildEffective(cfg, updates)
  local vres = Schema.validateUpdates(effective)
  if not vres.ok then
    showLines("Erros de validacao", vres.errors)
    return false
  end

  local changedOnly = buildChangedOnly(cfg, updates)
  if changedOnly.peripherals == nil and changedOnly.core == nil and changedOnly.delivery == nil then
    showLines("Salvar", { "Nenhuma mudanca para salvar." })
    return false
  end

  previewChanges(raw, changedOnly)
  if not confirmSave() then
    return false
  end

  local res = Config.patchIniFileAtomic(PATH, changedOnly, { backup_dir = "data/backups" })
  if not res.ok then
    showLines("Erro ao salvar", { tostring(res.err or "erro") })
    return false
  end

  showLines("Salvo", { "OK", "Backup: " .. tostring(res.backup_path or "") })
  return true
end

local function testPeripherals(effectivePeripherals)
  local lines = {}
  local function check(label, name)
    name = trim(name)
    if name == "" then
      table.insert(lines, label .. ": vazio")
      return false
    end
    if isPresentAndWrap(name) then
      table.insert(lines, label .. ": OK (" .. name .. ")")
      return true
    end
    table.insert(lines, label .. ": FAIL (" .. name .. ")")
    return false
  end

  local okAll = true
  okAll = check("colony_integrator", effectivePeripherals.colony_integrator) and okAll
  okAll = check("me_bridge", effectivePeripherals.me_bridge) and okAll
  okAll = check("modem", effectivePeripherals.modem) and okAll
  okAll = check("monitor_requests", effectivePeripherals.monitor_requests) and okAll
  okAll = check("monitor_status", effectivePeripherals.monitor_status) and okAll

  showLines("Teste de perifericos", lines)
  return okAll
end

local function choosePeripheralValue(label, current, typeNames)
  while true do
    local choices = {
      { text = "Digitar nome", action = "type" },
      { text = "Listar perifericos", action = "list" },
      { text = "Sugerir por tipo", action = "suggest" },
      { text = "Voltar", action = "back" },
    }
    local idx, why = selectList(label, "Enter confirma | <- volta", choices, 1)
    if why ~= "enter" or not idx then return nil, "back" end
    local chosen = choices[idx]
    if chosen.action == "back" then
      return nil, "back"
    elseif chosen.action == "type" then
      local v = prompt("Nome do periferico", current)
      if v == nil then return nil, "keep" end
      v = trim(v)
      if v == "" then
        showLines("Erro", { "Nome vazio." })
      elseif isPresentAndWrap(v) then
        return v, "set"
      else
        showLines("Erro", { "Periferico nao encontrado ou wrap falhou: " .. v })
      end
    elseif chosen.action == "list" then
      local names = listPeripherals()
      if #names == 0 then
        showLines("Perifericos", { "(nenhum)" })
      else
        local lbls = {}
        for i, n in ipairs(names) do
          lbls[i] = tostring(n)
        end
        local pick, pwhy = selectList("Perifericos", "Enter confirma | <- volta", lbls, 1)
        if pwhy == "enter" and pick then
          local v = tostring(lbls[pick])
          if isPresentAndWrap(v) then
            return v, "set"
          end
          showLines("Erro", { "wrap falhou: " .. v })
        end
      end
    elseif chosen.action == "suggest" then
      local suggested = nil
      if type(typeNames) == "table" then
        for _, t in ipairs(typeNames) do
          suggested = suggestByType(t)
          if suggested then break end
        end
      else
        suggested = suggestByType(typeNames)
      end
      if not suggested then
        showLines("Sugestao", { "Nenhum candidato encontrado." })
      else
        clear()
        print("Sugestao: " .. suggested)
        print("")
        term.write("Usar? (s/n): ")
        local a = tostring(read() or ""):lower()
        if a == "s" or a == "sim" or a == "y" or a == "yes" then
          if isPresentAndWrap(suggested) then
            return suggested, "set"
          end
          showLines("Erro", { "wrap falhou: " .. suggested })
        end
      end
    end
  end
end

local function runPeripheralsMenu(cfg, updates)
  local keys = {
    { key = "colony_integrator", types = "colonyIntegrator" },
    { key = "me_bridge", types = { "meBridge", "me_bridge" } },
    { key = "modem", types = "modem" },
    { key = "monitor_requests", types = "monitor" },
    { key = "monitor_status", types = "monitor" },
  }

  while true do
    local effective = buildEffective(cfg, updates).peripherals
    local labels = {
      { text = "Editar colony_integrator", suffix = "(" .. trim(effective.colony_integrator) .. ")", suffixColor = separatorColor() },
      { text = "Editar me_bridge", suffix = "(" .. trim(effective.me_bridge) .. ")", suffixColor = separatorColor() },
      { text = "Editar modem", suffix = "(" .. trim(effective.modem) .. ")", suffixColor = separatorColor() },
      { text = "Editar monitor_requests", suffix = "(" .. trim(effective.monitor_requests) .. ")", suffixColor = separatorColor() },
      { text = "Editar monitor_status", suffix = "(" .. trim(effective.monitor_status) .. ")", suffixColor = separatorColor() },
      { separator = true },
      { text = "Testar perifericos", action = "test" },
      { text = "Salvar", action = "save" },
      { text = "Voltar", action = "back" },
    }

    local idx, why = selectList("Perifericos", "Enter confirma | <- volta", labels, 1)
    if why ~= "enter" or not idx then return end

    local chosen = labels[idx]
    if type(chosen) == "table" and chosen.action == "back" then
      return
    end
    if type(chosen) == "table" and chosen.action == "test" then
      testPeripherals(effective)
    elseif type(chosen) == "table" and chosen.action == "save" then
      local okAll = testPeripherals(effective)
      if okAll then
        cfg = loadCfg()
        saveIni(cfg, updates)
        cfg = loadCfg()
      else
        clear()
        print("Teste falhou. Mesmo assim, salvar? (s/n): ")
        local a = tostring(read() or ""):lower()
        if a == "s" or a == "sim" then
          cfg = loadCfg()
          saveIni(cfg, updates)
          cfg = loadCfg()
        end
      end
    else
      local map = {
        [1] = keys[1],
        [2] = keys[2],
        [3] = keys[3],
        [4] = keys[4],
        [5] = keys[5],
      }
      local it = map[idx]
      if it then
        local current = effective[it.key]
        local v, why2 = choosePeripheralValue(it.key, current, it.types)
        if why2 == "set" and v ~= nil then
          updates.peripherals[it.key] = v
        end
      end
    end
  end
end

local function chooseEnum(label, current, options, normalize)
  local labels = {}
  local initial = 1
  for i, v in ipairs(options) do
    labels[i] = tostring(v)
    if normalize then
      if normalize(current) == normalize(v) then initial = i end
    else
      if tostring(current) == tostring(v) then initial = i end
    end
  end
  local idx, why = selectList(label, "Enter confirma | <- volta", labels, initial)
  if why ~= "enter" or not idx then return nil end
  return labels[idx]
end

local function runCoreMenu(cfg, updates)
  while true do
    local eff = buildEffective(cfg, updates).core
    local labels = {
      { text = "poll_interval_seconds", suffix = "(" .. trim(eff.poll_interval_seconds) .. ")", suffixColor = separatorColor() },
      { text = "ui_refresh_seconds", suffix = "(" .. trim(eff.ui_refresh_seconds) .. ")", suffixColor = separatorColor() },
      { text = "log_level", suffix = "(" .. trim(eff.log_level) .. ")", suffixColor = separatorColor() },
      { text = "log_dir", suffix = "(" .. trim(eff.log_dir) .. ")", suffixColor = separatorColor() },
      { text = "log_max_files", suffix = "(" .. trim(eff.log_max_files) .. ")", suffixColor = separatorColor() },
      { text = "log_max_kb", suffix = "(" .. trim(eff.log_max_kb) .. ")", suffixColor = separatorColor() },
      { separator = true },
      { text = "Salvar", action = "save" },
      { text = "Voltar", action = "back" },
    }
    local idx, why = selectList("Core+Logs", "Enter confirma | <- volta", labels, 1)
    if why ~= "enter" or not idx then return end
    local chosen = labels[idx]
    if type(chosen) == "table" and chosen.action == "back" then
      return
    end
    if type(chosen) == "table" and chosen.action == "save" then
      cfg = loadCfg()
      saveIni(cfg, updates)
      cfg = loadCfg()
    else
      if idx == 1 then
        local v = prompt("core.poll_interval_seconds", eff.poll_interval_seconds)
        if v ~= nil then updates.core.poll_interval_seconds = v end
      elseif idx == 2 then
        local v = prompt("core.ui_refresh_seconds", eff.ui_refresh_seconds)
        if v ~= nil then updates.core.ui_refresh_seconds = v end
      elseif idx == 3 then
        local v = chooseEnum("log_level", eff.log_level, { "DEBUG", "INFO", "WARN", "ERROR" }, function(s) return tostring(s):upper() end)
        if v ~= nil then updates.core.log_level = v end
      elseif idx == 4 then
        local v = prompt("core.log_dir", eff.log_dir)
        if v ~= nil then updates.core.log_dir = trim(v) end
      elseif idx == 5 then
        local v = prompt("core.log_max_files", eff.log_max_files)
        if v ~= nil then updates.core.log_max_files = v end
      elseif idx == 6 then
        local v = prompt("core.log_max_kb", eff.log_max_kb)
        if v ~= nil then updates.core.log_max_kb = v end
      end
    end
  end
end

local function runDeliveryMenu(cfg, updates)
  while true do
    local eff = buildEffective(cfg, updates).delivery
    local labels = {
      { text = "default_target_container", suffix = "(" .. trim(eff.default_target_container) .. ")", suffixColor = separatorColor() },
      { text = "export_mode", suffix = "(" .. trim(eff.export_mode) .. ")", suffixColor = separatorColor() },
      { text = "export_direction", suffix = "(" .. trim(eff.export_direction) .. ")", suffixColor = separatorColor() },
      { text = "export_buffer_container", suffix = "(" .. trim(eff.export_buffer_container) .. ")", suffixColor = separatorColor() },
      { text = "destination_cache_ttl_seconds", suffix = "(" .. trim(eff.destination_cache_ttl_seconds) .. ")", suffixColor = separatorColor() },
      { separator = true },
      { text = "Salvar", action = "save" },
      { text = "Voltar", action = "back" },
    }
    local idx, why = selectList("Delivery", "Enter confirma | <- volta", labels, 1)
    if why ~= "enter" or not idx then return end
    local chosen = labels[idx]
    if type(chosen) == "table" and chosen.action == "back" then
      return
    end
    if type(chosen) == "table" and chosen.action == "save" then
      cfg = loadCfg()
      saveIni(cfg, updates)
      cfg = loadCfg()
    else
      if idx == 1 then
        local v = prompt("delivery.default_target_container", eff.default_target_container)
        if v ~= nil then updates.delivery.default_target_container = trim(v) end
      elseif idx == 2 then
        local v = chooseEnum("export_mode", eff.export_mode, { "auto", "peripheral", "direction", "buffer" }, function(s) return tostring(s):lower() end)
        if v ~= nil then updates.delivery.export_mode = v end
      elseif idx == 3 then
        local v = chooseEnum("export_direction", eff.export_direction, { "up", "down", "north", "south", "east", "west" }, function(s) return tostring(s):lower() end)
        if v ~= nil then updates.delivery.export_direction = v end
      elseif idx == 4 then
        local v = prompt("delivery.export_buffer_container", eff.export_buffer_container)
        if v ~= nil then updates.delivery.export_buffer_container = trim(v) end
      elseif idx == 5 then
        local v = prompt("delivery.destination_cache_ttl_seconds", eff.destination_cache_ttl_seconds)
        if v ~= nil then updates.delivery.destination_cache_ttl_seconds = v end
      end
    end
  end
end

local function main()
  local updates = {
    peripherals = {},
    core = {},
    delivery = {},
  }

  local cfg = loadCfg()

  while true do
    local labels = {
      "Perifericos",
      "Core+Logs",
      "Delivery",
      "Sair",
    }
    local idx, why = selectList("Config CLI", "Enter confirma | <- volta", labels, 1)
    if why ~= "enter" or not idx then break end

    local choice = labels[idx]
    if choice == "Perifericos" then
      cfg = loadCfg()
      runPeripheralsMenu(cfg, updates)
    elseif choice == "Core+Logs" then
      cfg = loadCfg()
      runCoreMenu(cfg, updates)
    elseif choice == "Delivery" then
      cfg = loadCfg()
      runDeliveryMenu(cfg, updates)
    else
      break
    end
  end

  clear()
end

main()

