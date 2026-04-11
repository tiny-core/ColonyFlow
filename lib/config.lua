local Util = require("lib.util")

local Config = {}
Config.__index = Config

local DEFAULT_INI = [[
[core]
poll_interval_seconds=2
ui_refresh_seconds=1
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

return Config
