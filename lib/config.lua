local Util = require("lib.util")

local Config = {}
Config.__index = Config

local DEFAULT_INI = [[
[core]
poll_interval_seconds=2
ui_refresh_seconds=1
peripheral_watchdog_seconds=60
log_level=INFO
log_dir=logs
log_max_files=10
log_max_kb=256

[peripherals]
colony_integrator=colony_integrator_2
me_bridge=me_bridge_2
modem=modem_0
monitor_requests=monitor_0
monitor_status=monitor_1

[minecolonies]
pending_states_allow=
completed_states_deny=done,completed,fulfilled,success

[delivery]
default_target_container=minecolonies:rack_0,entangled:tile_0
export_mode=auto
export_direction=up
export_buffer_container=minecolonies:rack_1
destination_cache_ttl_seconds=2

[substitution]
mode=safe
vanilla_first=true
allow_unmapped_mods=false
tier_preference=highest

[tiers]
default_tool_tier=wood
default_armor_tier=leather
max_tool_tier=netherite
max_armor_tier=netherite

[cache]
max_entries=2000
default_ttl_seconds=5
me_item_ttl_seconds=1
me_list_ttl_seconds=1
me_craftable_ttl_seconds=2

[progression]
enforce_building_gating=true

[update]
enabled=true
ttl_hours=6
retry_seconds=120
error_backoff_max_seconds=900

[observability]
enabled=false
ui_enabled=false
debug_log_enabled=false
debug_log_interval_seconds=30

[scheduler_budget]
enabled=true
requests_per_tick=10
mc_calls_per_tick=20
me_calls_per_tick=40
inv_calls_per_tick=20
window_seconds=2
mc_calls_per_window=50
me_calls_per_window=100
inv_calls_per_window=50
requests_refresh_interval_seconds=5

[delivery_routing]
armor_helmet=
armor_chestplate=
armor_leggings=
armor_boots=
tool_pickaxe=
tool_shovel=
tool_axe=
tool_hoe=
tool_sword=
tool_bow=
tool_shield=
]]

local function parseIni(text)
  local data = {}
  local section = nil

  for rawLine in text:gmatch("[^\r\n]+") do
    local line = Util.trim(rawLine)
    if line ~= "" and not line:match("^;") and not line:match("^#") then
      local s = line:match("^%[([^%]]+)%]$")
      if s then
        section = Util.trim(s)
        data[section] = data[section] or {}
      else
        local key, value = line:match("^([^=]+)=(.*)$")
        if key then
          key = Util.trim(key)
          value = Util.trim(value)
          if not section then
            section = "default"
            data[section] = data[section] or {}
          end
          data[section][key] = value
        end
      end
    end
  end

  return data
end

function Config.ensureDefaults(path)
  if fs.exists(path) then
    return { created = false }
  end
  local ok, err = pcall(function()
    local h = fs.open(path, "w")
    if not h then error("failed to open file for writing") end
    h.write(DEFAULT_INI)
    h.close()
  end)
  if not ok then
    return { created = false, err = tostring(err) }
  end
  return { created = true, defaults = parseIni(DEFAULT_INI) }
end

function Config.load(path)
  local text
  if fs.exists(path) then
    local h = fs.open(path, "r")
    text = h.readAll()
    h.close()
  else
    text = ""
  end
  local obj = setmetatable({
    path = path,
    data = parseIni(text),
  }, Config)
  return obj
end

function Config:get(section, key, default)
  local s = self.data[section]
  if not s then return default end
  local v = s[key]
  if v == nil or v == "" then return default end
  return v
end

function Config:getNumber(section, key, default)
  local v = self:get(section, key, nil)
  if v == nil then return default end
  local n = tonumber(v)
  if not n then return default end
  return n
end

function Config:getBool(section, key, default)
  local v = self:get(section, key, nil)
  if v == nil then return default end
  v = v:lower()
  if v == "true" or v == "1" or v == "yes" or v == "y" or v == "on" then return true end
  if v == "false" or v == "0" or v == "no" or v == "n" or v == "off" then return false end
  return default
end

function Config:getList(section, key, default, sep)
  local v = self:get(section, key, nil)
  if v == nil then return default or {} end
  local out = {}
  local s = tostring(v)
  local delimiter = sep or ","
  for part in s:gmatch("[^" .. delimiter .. "]+") do
    local t = Util.trim(part)
    if t ~= "" then table.insert(out, t) end
  end
  if #out == 0 then return default or {} end
  return out
end

local function splitIniTextPreserveEmpty(text)
  local lines = {}
  text = tostring(text or "")
  if text == "" then return lines, false end
  local i = 1
  while true do
    local j = text:find("\n", i, true)
    if not j then
      local last = text:sub(i)
      if last:sub(-1) == "\r" then last = last:sub(1, -2) end
      table.insert(lines, last)
      break
    end
    local line = text:sub(i, j - 1)
    if line:sub(-1) == "\r" then line = line:sub(1, -2) end
    table.insert(lines, line)
    i = j + 1
    if i > #text then
      table.insert(lines, "")
      break
    end
  end
  return lines, text:sub(-1) == "\n"
end

local function isSectionHeader(line)
  local t = Util.trim(line or "")
  local s = t:match("^%[([^%]]+)%]$")
  if not s then return nil end
  return Util.trim(s)
end

function Config.patchIniText(linesOrText, updatesBySection)
  if type(updatesBySection) ~= "table" then updatesBySection = {} end

  local originalText = nil
  local originalEndsWithNl = false
  local inputLines = nil
  if type(linesOrText) == "table" then
    inputLines = {}
    for i, v in ipairs(linesOrText) do inputLines[i] = tostring(v or "") end
  else
    originalText = tostring(linesOrText or "")
    inputLines, originalEndsWithNl = splitIniTextPreserveEmpty(originalText)
  end

  local blocks = {}
  local current = { name = nil, header = nil, lines = {} }
  for _, line in ipairs(inputLines) do
    local name = isSectionHeader(line)
    if name then
      table.insert(blocks, current)
      current = { name = name, header = line, lines = {} }
    else
      table.insert(current.lines, line)
    end
  end
  table.insert(blocks, current)

  local seenSections = {}
  local changes = {}

  for _, b in ipairs(blocks) do
    if b.name then seenSections[b.name] = true end
    local updates = b.name and updatesBySection[b.name] or nil
    if type(updates) == "table" then
      local applied = {}
      for i, raw in ipairs(b.lines) do
        local t = Util.trim(raw)
        if t ~= "" and not t:match("^;") and not t:match("^#") then
          local k, v = t:match("^([^=]+)=(.*)$")
          if k then
            k = Util.trim(k)
            if updates[k] ~= nil then
              local newVal = tostring(updates[k])
              local oldVal = Util.trim(v)
              b.lines[i] = k .. "=" .. newVal
              applied[k] = true
              table.insert(changes, { section = b.name, key = k, old = oldVal, new = newVal, op = "update" })
            end
          end
        end
      end

      local missing = {}
      for k, _ in pairs(updates) do
        if not applied[k] then table.insert(missing, tostring(k)) end
      end
      table.sort(missing, function(a, b2) return tostring(a) < tostring(b2) end)

      if #missing > 0 then
        local lastNonBlank = #b.lines
        while lastNonBlank >= 1 and Util.trim(b.lines[lastNonBlank]) == "" do
          lastNonBlank = lastNonBlank - 1
        end
        local pos = lastNonBlank + 1
        for _, k in ipairs(missing) do
          local newVal = tostring(updates[k])
          table.insert(b.lines, pos, k .. "=" .. newVal)
          pos = pos + 1
          table.insert(changes, { section = b.name, key = k, old = nil, new = newVal, op = "insert" })
        end
      end
    end
  end

  local extraSections = {}
  for sec, _ in pairs(updatesBySection) do
    if not seenSections[sec] then
      table.insert(extraSections, tostring(sec))
    end
  end
  table.sort(extraSections, function(a, b2) return tostring(a) < tostring(b2) end)

  if #extraSections > 0 then
    local last = blocks[#blocks]
    if last and not last.header then
      local lastLine = last.lines[#last.lines]
      if lastLine ~= nil and Util.trim(lastLine) ~= "" then
        table.insert(last.lines, "")
      end
    end
    for _, sec in ipairs(extraSections) do
      local keys = {}
      local u = updatesBySection[sec]
      for k, _ in pairs(u or {}) do table.insert(keys, tostring(k)) end
      table.sort(keys, function(a, b2) return tostring(a) < tostring(b2) end)
      local newBlock = { name = sec, header = "[" .. sec .. "]", lines = {} }
      for _, k in ipairs(keys) do
        local newVal = tostring(u[k])
        table.insert(newBlock.lines, k .. "=" .. newVal)
        table.insert(changes, { section = sec, key = k, old = nil, new = newVal, op = "insert" })
      end
      table.insert(blocks, newBlock)
    end
  end

  local outLines = {}
  for _, b in ipairs(blocks) do
    if b.header then table.insert(outLines, b.header) end
    for _, l in ipairs(b.lines) do table.insert(outLines, l) end
  end

  if originalEndsWithNl and (#outLines == 0 or outLines[#outLines] ~= "") then
    table.insert(outLines, "")
  end

  return { text = table.concat(outLines, "\n"), changes = changes }
end

function Config:validate()
  local Schema = require("lib.config_schema")
  return Schema.validateUpdates(self.data)
end

function Config.patchIniFileAtomic(path, updatesBySection, opts)
  opts = type(opts) == "table" and opts or {}
  local backupDir = tostring(opts.backup_dir or "data/backups")
  local keepBackups = tonumber(opts.keep_backups or 2) or 2
  Util.ensureDir(backupDir)

  local src = Util.readFile(path) or ""
  local patched = Config.patchIniText(src, updatesBySection)

  local ts = Util.isoTimestampUtc()
  local baseName = (fs.getName and fs.getName(path)) and fs.getName(path) or tostring(path)
  local backupPath = fs.combine(backupDir, baseName .. "." .. ts .. ".bak")

  local ok, err = pcall(function()
    Util.writeFile(backupPath, src)
    Util.writeFileAtomic(path, patched.text)
  end)
  if not ok then
    return { ok = false, err = tostring(err) }
  end

  if keepBackups >= 0 then
    local ok2 = pcall(function()
      if fs.exists(backupDir) and fs.isDir(backupDir) then
        local prefix = baseName .. "."
        local all = fs.list(backupDir)
        local matches = {}
        for _, name in ipairs(all) do
          if name:sub(1, #prefix) == prefix and name:sub(-4) == ".bak" then
            table.insert(matches, name)
          end
        end
        table.sort(matches)
        while #matches > keepBackups do
          local del = table.remove(matches, 1)
          fs.delete(fs.combine(backupDir, del))
        end
      end
    end)
    if not ok2 then
      -- ignore prune errors
    end
  end

  return { ok = true, changes = patched.changes, backup_path = backupPath }
end

return Config
