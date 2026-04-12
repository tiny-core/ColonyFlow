local args = { ... }

local DEFAULT_BASE_URL = "https://raw.githubusercontent.com/tiny-core/ColonyFlow/"
local DEFAULT_REF = "main"
local DEFAULT_MANIFEST_PATH = "manifest.json"

local function setExitCode(code)
  if type(shell) == "table" and type(shell.setExitCode) == "function" then
    shell.setExitCode(code)
  end
end

local function nowUtc()
  local t = os.date("!*t")
  return string.format(
    "%04d-%02d-%02dT%02d:%02d:%02dZ",
    t.year, t.month, t.day, t.hour, t.min, t.sec
  )
end

local function trim(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ensureDir(path)
  if fs.exists(path) then return fs.isDir(path) end
  fs.makeDir(path)
  return true
end

local function readFile(path)
  if not fs.exists(path) then return nil end
  local h = fs.open(path, "r")
  local txt = h.readAll()
  h.close()
  return txt
end

local function writeFile(path, content)
  local dir = fs.getDir(path)
  if dir and dir ~= "" then ensureDir(dir) end
  local h = fs.open(path, "w")
  h.write(content)
  h.close()
end

local function jsonDecode(txt)
  if not txt or txt == "" then return nil end
  return textutils.unserializeJSON(txt)
end

local function jsonEncode(tbl)
  return textutils.serializeJSON(tbl, { pretty = true })
end

local function normalizeBaseUrl(u)
  u = trim(u)
  if u == "" then return "" end
  if not u:match("/$") then u = u .. "/" end
  return u
end

local function httpAvailable()
  return type(http) == "table" and type(http.get) == "function"
end

local function parseOverrides(argv, startIdx)
  local o = {}
  local i = startIdx or 1
  while i <= #argv do
    local a = tostring(argv[i] or "")
    if a == "--base-url" then
      local v = argv[i + 1]
      if v == nil then return nil, "Faltou valor para --base-url" end
      o.base_url = tostring(v)
      i = i + 2
    elseif a == "--repo" then
      local v = argv[i + 1]
      if v == nil then return nil, "Faltou valor para --repo" end
      o.repo = tostring(v)
      i = i + 2
    elseif a == "--ref" then
      local v = argv[i + 1]
      if v == nil then return nil, "Faltou valor para --ref" end
      o.ref = tostring(v)
      i = i + 2
    elseif a == "--manifest" then
      local v = argv[i + 1]
      if v == nil then return nil, "Faltou valor para --manifest" end
      o.manifest_path = tostring(v)
      i = i + 2
    elseif a == "" then
      i = i + 1
    else
      return nil, "Flag desconhecida: " .. a
    end
  end
  return o
end

local function applyOverrides(cfg, overrides)
  if type(overrides) ~= "table" then return false end
  local changed = false

  if overrides.repo and trim(overrides.repo) ~= "" then
    cfg.base_url = "https://raw.githubusercontent.com/" .. trim(overrides.repo) .. "/"
    changed = true
  end
  if overrides.base_url and trim(overrides.base_url) ~= "" then
    cfg.base_url = trim(overrides.base_url)
    changed = true
  end
  if overrides.ref and trim(overrides.ref) ~= "" then
    cfg.ref = trim(overrides.ref)
    changed = true
  end
  if overrides.manifest_path and trim(overrides.manifest_path) ~= "" then
    cfg.manifest_path = trim(overrides.manifest_path)
    changed = true
  end

  return changed
end

local function doctor(cfg)
  print("Instalador - Doctor")
  print("Hora UTC: " .. nowUtc())
  print("")

  if not httpAvailable() then
    print("ERRO: HTTP API indisponível (http.get não existe).")
    print("Ação: habilite HTTP no CC: Tweaked (config do mod/servidor) e tente novamente.")
    return false
  end

  if cfg.base_url == DEFAULT_BASE_URL then
    print("ATENÇÃO: base_url ainda está no placeholder padrão.")
    print("Ação: edite data/install.json e configure base_url para o raw do seu repositório, ou rode:")
    print("  tools/install.lua doctor --repo OWNER/REPO --ref main")
    return false
  end

  local base = normalizeBaseUrl(cfg.base_url)
  local ref = trim(cfg.ref or DEFAULT_REF)
  local manifestPath = trim(cfg.manifest_path or DEFAULT_MANIFEST_PATH)
  local manifestUrl = base .. ref .. "/" .. manifestPath

  if http.checkURL then
    local ok, err = http.checkURL(manifestUrl)
    if not ok then
      print("ERRO: URL bloqueada/inválida: " .. tostring(manifestUrl))
      print("Detalhe: " .. tostring(err))
      return false
    end
  end

  local free = fs.getFreeSpace("/")
  print("OK: HTTP disponível")
  print("Manifest URL: " .. manifestUrl)
  print("Espaço livre: " .. tostring(free))
  return true
end

local function loadOrCreateInstallConfig()
  ensureDir("data")
  local path = "data/install.json"
  local txt = readFile(path)
  local cfg = jsonDecode(txt) or {}
  if type(cfg) ~= "table" then cfg = {} end

  if trim(cfg.base_url) == "" then cfg.base_url = DEFAULT_BASE_URL end
  if trim(cfg.ref) == "" then cfg.ref = DEFAULT_REF end
  if trim(cfg.manifest_path) == "" then cfg.manifest_path = DEFAULT_MANIFEST_PATH end

  if not txt then
    writeFile(path, jsonEncode(cfg))
    print("Criado: " .. path)
  end
  return cfg
end

local function httpGetText(url)
  local resp, err = http.get(url)
  if not resp then
    return nil, "Falha HTTP: " .. tostring(err)
  end
  local code = resp.getResponseCode and resp.getResponseCode() or nil
  local body = resp.readAll()
  resp.close()
  if code and code ~= 200 then
    return nil, "HTTP " .. tostring(code)
  end
  if not body or body == "" then
    return nil, "Resposta vazia"
  end
  return body
end

local function httpGetTextWithRetry(url, tries)
  tries = math.max(1, tonumber(tries) or 1)
  local lastErr = nil
  for i = 1, tries do
    local body, err = httpGetText(url)
    if body then return body end
    lastErr = err
    if i < tries then sleep(0.5) end
  end
  return nil, lastErr
end

local function validateManifest(manifest)
  if type(manifest) ~= "table" then
    return nil, "Manifesto inválido: objeto ausente."
  end
  if type(manifest.manifest_version) ~= "number" then
    return nil, "Manifesto inválido: 'manifest_version' deve ser número."
  end
  if type(manifest.files) ~= "table" then
    return nil, "Manifesto inválido: campo 'files' ausente."
  end

  local files = {}
  for i, f in ipairs(manifest.files) do
    if type(f) ~= "table" then
      return nil, "Manifesto inválido: files[" .. tostring(i) .. "] não é objeto."
    end
    if type(f.path) ~= "string" then
      return nil, "Manifesto inválido: files[" .. tostring(i) .. "].path não é string."
    end
    local p = trim(f.path)
    if p == "" then
      return nil, "Manifesto inválido: files[" .. tostring(i) .. "].path vazio."
    end
    if p:match("^/") or p:match("^%a:[/\\]") or p:find("%.%.", 1, true) then
      return nil, "Manifesto inválido: caminho inseguro em files[" .. tostring(i) .. "]: " .. p
    end
    if f.size ~= nil and type(f.size) ~= "number" then
      return nil, "Manifesto inválido: files[" .. tostring(i) .. "].size deve ser número."
    end
    if f.preserve ~= nil and type(f.preserve) ~= "boolean" then
      return nil, "Manifesto inválido: files[" .. tostring(i) .. "].preserve deve ser boolean."
    end
    files[#files + 1] = { path = p, size = f.size, preserve = f.preserve == true }
  end
  return { manifest_version = manifest.manifest_version, generated_utc = manifest.generated_utc, files = files }
end

local function loadManifest(cfg)
  local base = normalizeBaseUrl(cfg.base_url)
  local ref = trim(cfg.ref or DEFAULT_REF)
  local manifestPath = trim(cfg.manifest_path or DEFAULT_MANIFEST_PATH)
  local url = base .. ref .. "/" .. manifestPath

  local body, err = httpGetTextWithRetry(url, 3)
  if not body then
    return nil, "Não foi possível baixar o manifesto: " .. tostring(err) .. " (" .. url .. ")"
  end

  local ok, parsed = pcall(textutils.unserializeJSON, body)
  if not ok or type(parsed) ~= "table" then
    return nil, "Manifesto inválido (JSON)."
  end
  local normalized, vErr = validateManifest(parsed)
  if not normalized then
    return nil, vErr
  end

  return {
    url = url,
    base = base,
    ref = ref,
    manifest = normalized,
  }
end

local function pathSetFromManifest(manifest)
  local set = {}
  local preserve = {}
  local files = {}
  for _, f in ipairs(manifest.files) do
    if type(f) == "table" and type(f.path) == "string" and trim(f.path) ~= "" then
      local p = f.path
      set[p] = true
      files[#files + 1] = { path = p, size = f.size, preserve = f.preserve == true }
      if f.preserve == true then preserve[p] = true end
    end
  end
  return set, preserve, files
end

local function readInstalledVersion()
  local txt = readFile("data/version.json")
  local v = jsonDecode(txt)
  if type(v) ~= "table" then return nil end
  return v
end

local function writeInstalledVersion(info)
  ensureDir("data")
  writeFile("data/version.json", jsonEncode(info))
end

local function isPreservedPath(p, preserveFromManifest)
  if p == "config.ini" then return true end
  if p == "data/mappings.json" then return true end
  if p == "data/install.json" then return true end
  if p == "data/version.json" then return true end
  if preserveFromManifest[p] then return true end
  return false
end

local function copyFile(src, dst)
  local dir = fs.getDir(dst)
  if dir and dir ~= "" then ensureDir(dir) end
  if fs.exists(dst) then fs.delete(dst) end
  fs.copy(src, dst)
end

local function snapshotBackup(paths, backupRoot)
  local meta = { created_utc = nowUtc(), paths = {} }
  for _, p in ipairs(paths) do
    local existed = fs.exists(p) and not fs.isDir(p)
    meta.paths[#meta.paths + 1] = { path = p, existed = existed }
    if existed then
      local backupPath = fs.combine(backupRoot, p)
      ensureDir(fs.getDir(backupPath))
      fs.copy(p, backupPath)
    end
  end
  writeFile(fs.combine(backupRoot, "meta.json"), jsonEncode(meta))
  return meta
end

local function rollback(backupRoot, meta)
  for _, item in ipairs(meta.paths or {}) do
    local p = item.path
    if item.existed then
      local backupPath = fs.combine(backupRoot, p)
      if fs.exists(backupPath) then
        copyFile(backupPath, p)
      end
    else
      if fs.exists(p) and not fs.isDir(p) then
        fs.delete(p)
      end
    end
  end
end

local function downloadToTemp(bundle, files, tempRoot)
  local results = {}
  for _, f in ipairs(files) do
    local url = bundle.base .. bundle.ref .. "/" .. f.path
    local body, err = httpGetTextWithRetry(url, 3)
    if not body then
      return nil, "Falha ao baixar " .. f.path .. ": " .. tostring(err)
    end
    if f.size and tonumber(f.size) and #body ~= tonumber(f.size) then
      return nil, "Tamanho divergente em " .. f.path .. " (esperado " .. tostring(f.size) .. ", obtido " .. tostring(#body) .. ")"
    end
    local out = fs.combine(tempRoot, f.path)
    writeFile(out, body)
    results[#results + 1] = { path = f.path, tmp = out, size = #body }
    print("OK  " .. f.path .. " (" .. tostring(#body) .. " bytes)")
  end
  return results
end

local function applyFiles(downloaded, preserveFromManifest)
  local applied = {}
  for _, d in ipairs(downloaded) do
    local preserve = isPreservedPath(d.path, preserveFromManifest)
    if preserve and fs.exists(d.path) then
      print("SKIP(preserved) " .. d.path)
    else
      copyFile(d.tmp, d.path)
      applied[#applied + 1] = d.path
      print("APPLY " .. d.path)
    end
  end
  return applied
end

local function computeOrphans(prev, nextSet, preserveFromManifest)
  local orphans = {}
  if type(prev) ~= "table" or type(prev.managed_files) ~= "table" then return orphans end
  for _, p in ipairs(prev.managed_files) do
    if type(p) == "string" and p ~= "" then
      if not nextSet[p] and not isPreservedPath(p, preserveFromManifest) then
        orphans[#orphans + 1] = p
      end
    end
  end
  table.sort(orphans)
  return orphans
end

local function deleteOrphans(paths)
  for _, p in ipairs(paths) do
    if fs.exists(p) and not fs.isDir(p) then
      fs.delete(p)
      print("DELETE " .. p)
    end
  end
end

local function installOrUpdate(mode, overrides)
  local cfg = loadOrCreateInstallConfig()
  local changed = applyOverrides(cfg, overrides)
  if changed then
    writeFile("data/install.json", jsonEncode(cfg))
    print("Atualizado: data/install.json")
  end

  if mode == "doctor" then
    local ok = doctor(cfg)
    setExitCode(ok and 0 or 1)
    return ok and 0 or 1
  end

  if not httpAvailable() then
    print("ERRO: HTTP API indisponível (http.get não existe).")
    print("Ação: habilite HTTP no CC: Tweaked (config do mod/servidor) e tente novamente.")
    setExitCode(1)
    return 1
  end

  if cfg.base_url == DEFAULT_BASE_URL then
    print("ERRO: base_url ainda está no placeholder padrão.")
    print("Ação: configure data/install.json ou passe --repo/--base-url neste comando.")
    print("Exemplos:")
    print("  tools/install.lua " .. mode .. " --repo OWNER/REPO --ref main")
    print("  tools/install.lua " .. mode .. " --base-url https://raw.githubusercontent.com/OWNER/REPO/ --ref main")
    setExitCode(1)
    return 1
  end

  local bundle, err = loadManifest(cfg)
  if not bundle then
    print("ERRO: " .. tostring(err))
    setExitCode(1)
    return 1
  end

  local nextSet, preserveFromManifest, files = pathSetFromManifest(bundle.manifest)
  local prev = readInstalledVersion()

  local ts = tostring(os.epoch("utc"))
  local tempRoot = fs.combine("data/.install_tmp", ts)
  local backupRoot = fs.combine("data/backups", ts)
  ensureDir(tempRoot)
  ensureDir(backupRoot)

  print("Modo: " .. mode)
  print("Ref: " .. bundle.ref)
  print("Manifest: " .. bundle.url)
  print("")

  local ok, downloadedOrErr = pcall(downloadToTemp, bundle, files, tempRoot)
  if not ok then
    print("ERRO: Falha durante download: " .. tostring(downloadedOrErr))
    return 1
  end
  local downloaded, dlErr = downloadedOrErr, nil
  if type(downloaded) ~= "table" then
    dlErr = tostring(downloaded)
  end
  if dlErr then
    print("ERRO: " .. dlErr)
    setExitCode(1)
    return 1
  end

  local toBackup = {}
  for _, d in ipairs(downloaded) do
    if not (isPreservedPath(d.path, preserveFromManifest) and fs.exists(d.path)) then
      toBackup[#toBackup + 1] = d.path
    end
  end
  local orphans = (mode == "update") and computeOrphans(prev, nextSet, preserveFromManifest) or {}
  for _, p in ipairs(orphans) do
    toBackup[#toBackup + 1] = p
  end
  local metaOk, metaOrErr = pcall(snapshotBackup, toBackup, backupRoot)
  if not metaOk then
    print("ERRO: Falha ao criar snapshot: " .. tostring(metaOrErr))
    setExitCode(1)
    return 1
  end
  local meta = metaOrErr

  local appliedOk = false
  local applied = {}
  local applyErr = nil
  local ok2, res = pcall(function()
    applied = applyFiles(downloaded, preserveFromManifest)
    if mode == "update" then
      deleteOrphans(orphans)
    end
    appliedOk = true
  end)
  if not ok2 then
    applyErr = tostring(res)
  end

  if not appliedOk then
    print("ERRO: Falha ao aplicar update: " .. tostring(applyErr))
    print("Rollback automático...")
    rollback(backupRoot, meta)
    setExitCode(1)
    return 1
  end

  local managedFiles = {}
  for _, f in ipairs(files) do managedFiles[#managedFiles + 1] = f.path end
  table.sort(managedFiles)

  local finalOk, finalErr = pcall(function()
    writeInstalledVersion({
      installed_at_utc = nowUtc(),
      ref = bundle.ref,
      manifest_url = bundle.url,
      manifest_version = bundle.manifest.manifest_version,
      managed_files = managedFiles,
    })
    if fs.exists(tempRoot) then
      fs.delete(tempRoot)
    end
  end)
  if not finalOk then
    print("ERRO: Falha ao finalizar update: " .. tostring(finalErr))
    print("Rollback automático...")
    rollback(backupRoot, meta)
    setExitCode(1)
    return 1
  end

  print("")
  print("Resumo:")
  print("- Aplicados: " .. tostring(#applied))
  print("- Órfãos removidos: " .. tostring(#orphans))
  print("- Preservados: config.ini, data/mappings.json, data/install.json, data/version.json")
  print("OK.")
  setExitCode(0)
  return 0
end

local sub = trim(args[1])
if sub == "" then sub = "doctor" end
if sub ~= "doctor" and sub ~= "install" and sub ~= "update" then
  print("Uso:")
  print("  tools/install.lua doctor [--repo OWNER/REPO] [--ref main] [--base-url URL] [--manifest manifest.json]")
  print("  tools/install.lua install [--repo OWNER/REPO] [--ref main] [--base-url URL] [--manifest manifest.json]")
  print("  tools/install.lua update [--repo OWNER/REPO] [--ref main] [--base-url URL] [--manifest manifest.json]")
  return
end

local overrides, oErr = parseOverrides(args, 2)
if not overrides then
  print("ERRO: " .. tostring(oErr))
  print("")
  print("Uso:")
  print("  tools/install.lua " .. sub .. " [--repo OWNER/REPO] [--ref main] [--base-url URL] [--manifest manifest.json]")
  setExitCode(1)
  return
end

local code = installOrUpdate(sub, overrides)
if code ~= 0 then
  print("Falha (" .. tostring(sub) .. "). Veja mensagens acima.")
  setExitCode(code)
  return
end
