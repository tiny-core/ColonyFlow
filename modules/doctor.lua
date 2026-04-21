if type(package) == "table" and type(package.path) == "string" then
  local cwd = shell and shell.dir and shell.dir() or ""
  if cwd == "" then
    package.path = "/?.lua;/?/init.lua;" .. package.path
  else
    package.path = "/" .. cwd .. "/?.lua;/" .. cwd .. "/?/init.lua;/?.lua;/?/init.lua;" .. package.path
  end
end

local Config = require("lib.config")
local Schema = require("lib.config_schema")
local ME = require("modules.me")

local function trim(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function nowUtc()
  local t = os.date("!*t")
  return string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local function safeIsPresent(name)
  if name == "" then return false end
  local ok, res = pcall(peripheral.isPresent, name)
  if not ok then return false end
  return res == true
end

local function safeWrap(name)
  local ok, res = pcall(peripheral.wrap, name)
  if not ok then return nil end
  return res
end

local function httpStatus(url)
  if type(http) ~= "table" or type(http.get) ~= "function" then
    return "OFF", "http_get_missing"
  end
  if type(http.checkURL) == "function" then
    local ok, err = http.checkURL(url)
    if ok then return "OK", nil end
    return "BLOCKED", tostring(err or "blocked")
  end
  return "OK", "no_checkURL"
end

local function buildManifestUrl()
  local base = "https://raw.githubusercontent.com/tiny-core/ColonyFlow/"
  local ref = "master"
  local manifestPath = "manifest.json"
  return base .. ref .. "/" .. manifestPath
end

local function printLine(k, v)
  print(string.format("%-10s %s", tostring(k), tostring(v)))
end

local actions = {}
local function addAction(s)
  s = trim(s)
  if s ~= "" then table.insert(actions, s) end
end

print("ColonyFlow - Doctor")
print("UTC: " .. nowUtc())
print("")

local ensured = nil
do
  local ok, res = pcall(Config.ensureDefaults, "config.ini")
  if ok then
    ensured = res
  else
    ensured = { created = false, err = tostring(res) }
  end
end

local cfg = Config.load("config.ini")

local validation = Schema.validateUpdates(cfg.data)
if ensured and ensured.err then
  addAction("Acao: falha ao criar config.ini com defaults: " .. tostring(ensured.err))
end

if validation.ok ~= true then
  addAction("Acao: corrija config.ini (valores invalidos)")
  if type(validation.errors) == "table" and validation.errors[1] then
    addAction("Acao: " .. tostring(validation.errors[1]))
  end
end

local manifestUrl = buildManifestUrl()
local httpSt, httpDetail = httpStatus(manifestUrl)
if httpSt == "OFF" then
  addAction("Acao: habilite HTTP no servidor/modpack (CC:Tweaked)")
elseif httpSt == "BLOCKED" then
  addAction("Acao: URL bloqueada; ajuste whitelist/blacklist de HTTP")
end

local function pCfg(key)
  return trim(cfg:get("peripherals", key, ""))
end

local pCol = pCfg("colony_integrator")
local pMe = pCfg("me_bridge")
local pModem = pCfg("modem")
local pMonReq = pCfg("monitor_requests")
local pMonStat = pCfg("monitor_status")

local function periphLine(label, key, name)
  local st = safeIsPresent(name) and "PRESENT" or "ABSENT"
  local shown = name ~= "" and name or "<empty>"
  printLine(label .. ":", st .. " (" .. tostring(key) .. "=" .. shown .. ")")
  if st == "ABSENT" then
    addAction("Acao: ajuste [peripherals] " .. tostring(key) .. "=<peripheral_name>")
  end
end

printLine("HTTP:", httpSt)
printLine("URL:", manifestUrl)
print("")
periphLine("COLONY", "colony_integrator", pCol)
periphLine("ME", "me_bridge", pMe)
periphLine("MODEM", "modem", pModem)
periphLine("MON_REQ", "monitor_requests", pMonReq)
periphLine("MON_STAT", "monitor_status", pMonStat)
print("")

local meLine = "OFFLINE"
if safeIsPresent(pMe) then
  local bridge = safeWrap(pMe)
  if bridge then
    local state = {
      cfg = cfg,
      cache = { get = function() return nil end, set = function() end },
      devices = { meBridge = bridge },
      health = {},
    }
    local me = ME.new(state)
    local ok, err = me:isOnline()
    if ok == true then
      meLine = "ONLINE"
    else
      meLine = "OFFLINE"
      addAction("Acao: verifique ME Bridge e grid (isOnline/isConnected)")
      if err and err ~= "" then
        addAction("Acao: ME detail: " .. tostring(err))
      end
    end
  else
    addAction("Acao: falha ao wrap do me_bridge; verifique nome/permissao")
  end
else
  addAction("Acao: me_bridge ausente; ajuste config.ini")
end

local cfgLine = (validation.ok == true) and "OK" or "INVALID"

printLine("ME:", meLine)
printLine("CONFIG:", cfgLine)
print("")
print("ACTIONS:")
if #actions == 0 then
  print("- (none)")
else
  for _, a in ipairs(actions) do
    print("- " .. tostring(a))
  end
end
