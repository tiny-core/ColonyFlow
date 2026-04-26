local M = {}

function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.normalizeName(s)
  if not s then return "" end
  s = tostring(s):lower():gsub("%s+", " ")
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.nowUtcMs()
  return os.epoch("utc")
end

function M.safeCall(fn, ...)
  local ok, res1, res2, res3, res4 = pcall(fn, ...)
  if ok then return true, res1, res2, res3, res4 end
  return false, res1
end

function M.ensureDir(path)
  if fs.exists(path) then
    if fs.isDir(path) then return true end
    return false
  end
  fs.makeDir(path)
  return true
end

function M.readFile(path)
  if not fs.exists(path) then return nil end
  local h = fs.open(path, "r")
  local txt = h.readAll()
  h.close()
  return txt
end

function M.writeFile(path, content)
  local dir = fs.getDir(path)
  if dir and dir ~= "" then
    M.ensureDir(dir)
  end
  local h = fs.open(path, "w")
  h.write(content)
  h.close()
end

function M.jsonDecode(txt)
  if not txt or txt == "" then return nil end
  return textutils.unserializeJSON(txt)
end

function M.jsonEncode(tbl)
  return textutils.serializeJSON(tbl, { pretty = true })
end

function M.copyFile(src, dst)
  local txt = M.readFile(src)
  if txt == nil then return false, "src_nao_existe" end
  M.writeFile(dst, txt)
  return true
end

function M.writeFileAtomic(path, content)
  local tmp = tostring(path) .. ".tmp"
  M.writeFile(tmp, content)
  if fs.exists(path) then
    fs.delete(path)
  end
  fs.move(tmp, path)
  return true
end

function M.isoTimestampUtc()
  return os.date("!%Y-%m-%dT%H%M%SZ")
end

return M
