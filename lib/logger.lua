local Util = require("lib.util")

local LEVELS = { DEBUG = 10, INFO = 20, WARN = 30, ERROR = 40 }

local Logger = {}
Logger.__index = Logger

local function levelNum(level)
  return LEVELS[level] or LEVELS.INFO
end

local function pad2(n)
  n = tonumber(n) or 0
  if n < 10 then return "0" .. tostring(n) end
  return tostring(n)
end

local function utcStamp()
  local t = os.date("!*t")
  return string.format(
    "%04d-%s-%s %s:%s:%sZ",
    t.year,
    pad2(t.month),
    pad2(t.day),
    pad2(t.hour),
    pad2(t.min),
    pad2(t.sec)
  )
end

local function safeToString(v)
  if type(v) == "string" then return v end
  if type(v) == "table" then
    return textutils.serialize(v, { compact = true })
  end
  return tostring(v)
end

function Logger.new(cfg)
  local logDir = cfg:get("core", "log_dir", "logs")
  Util.ensureDir(logDir)

  local o = setmetatable({
    level = cfg:get("core", "log_level", "INFO"),
    dir = logDir,
    maxFiles = cfg:getNumber("core", "log_max_files", 10),
    maxBytes = cfg:getNumber("core", "log_max_kb", 256) * 1024,
    file = nil,
    filePath = nil,
  }, Logger)

  o:openCurrentFile()
  o:cleanupOldFiles()
  return o
end

function Logger:openCurrentFile()
  local date = os.date("!%Y-%m-%d")
  self.filePath = fs.combine(self.dir, "minecolonies-me-" .. date .. ".log")
  self.file = fs.open(self.filePath, "a")
end

function Logger:close()
  if self.file then
    self.file.close()
    self.file = nil
  end
end

function Logger:rotateIfNeeded()
  if not self.filePath or not fs.exists(self.filePath) then return end
  local size = fs.getSize(self.filePath)
  if size < self.maxBytes then return end

  self:close()

  local date = os.date("!%Y-%m-%d")
  local ts = os.date("!%H%M%S")
  local rotated = fs.combine(self.dir, "minecolonies-me-" .. date .. "-" .. ts .. ".log")
  fs.move(self.filePath, rotated)

  self:cleanupOldFiles()
  self:openCurrentFile()
end

function Logger:cleanupOldFiles()
  local maxFiles = math.floor(tonumber(self.maxFiles or 0) or 0)
  if maxFiles <= 0 then return end

  local files = fs.list(self.dir)
  local logs = {}
  for _, f in ipairs(files) do
    if f:match("^minecolonies%-me%-.+%.log$") then
      table.insert(logs, f)
    end
  end
  table.sort(logs)
  local remaining = #logs
  if remaining <= maxFiles then return end

  local current = self.filePath
  for _, f in ipairs(logs) do
    if remaining <= maxFiles then break end
    local p = fs.combine(self.dir, f)
    if current and p == current then
      goto continue
    end
    if fs.exists(p) then
      fs.delete(p)
      remaining = remaining - 1
    end
    ::continue::
  end
end

function Logger:emit(level, msg, ctx)
  if levelNum(level) < levelNum(self.level) then return end

  self:rotateIfNeeded()
  local line = "[" .. utcStamp() .. "] [" .. level .. "] " .. safeToString(msg)
  if ctx ~= nil then
    line = line .. " | ctx=" .. safeToString(ctx)
  end

  print(line)
  if self.file then
    self.file.writeLine(line)
    self.file.flush()
  end
end

function Logger:debug(msg, ctx) self:emit("DEBUG", msg, ctx) end
function Logger:info(msg, ctx) self:emit("INFO", msg, ctx) end
function Logger:warn(msg, ctx) self:emit("WARN", msg, ctx) end
function Logger:error(msg, ctx) self:emit("ERROR", msg, ctx) end

return Logger
