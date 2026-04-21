local Util = require("lib.util")

local M = {}

local function asNumber(v)
  local n = tonumber(v)
  if not n then return nil end
  return n
end

function M.load(path)
  path = tostring(path or "")
  if path == "" then return nil end
  if not fs.exists(path) then return nil end
  local txt = Util.readFile(path)
  local ok, obj = pcall(Util.jsonDecode, txt)
  if not ok then return nil end
  if type(obj) ~= "table" then return nil end
  if obj.v ~= 1 then return nil end
  if type(obj.jobs) ~= "table" then return nil end
  if obj.saved_at_ms ~= nil and asNumber(obj.saved_at_ms) == nil then
    return nil
  end
  return obj
end

function M.save(path, jobs)
  path = tostring(path or "")
  if path == "" then return false, "path_vazio" end
  if type(jobs) ~= "table" then jobs = {} end

  Util.ensureDir("data")

  local obj = {
    v = 1,
    saved_at_ms = Util.nowUtcMs(),
    jobs = jobs,
  }

  local json = textutils.serializeJSON(obj)
  Util.writeFileAtomic(path, json)
  return true, nil
end

return M
