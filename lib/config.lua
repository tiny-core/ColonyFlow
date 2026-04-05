local Util = require("lib.util")

local Config = {}
Config.__index = Config

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

return Config
