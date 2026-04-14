local Util = require("lib.util")
local Version = require("lib.version")

local M = {}

local DEFAULT_BASE_URL = "https://raw.githubusercontent.com/tiny-core/ColonyFlow/"
local DEFAULT_REF = "master"
local DEFAULT_MANIFEST_PATH = "manifest.json"

local DEFAULT_TTL_MS = 6 * 60 * 60 * 1000
local CACHE_PATH = "data/update_check.json"

local function trim(s)
    return Util.trim(tostring(s or ""))
end

local function shorten(s, maxLen)
    s = tostring(s or "")
    if #s <= maxLen then return s end
    if maxLen <= 2 then return s:sub(1, maxLen) end
    return s:sub(1, maxLen - 2) .. ".."
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

function M.buildManifestUrl(installCfg)
    installCfg = (type(installCfg) == "table") and installCfg or {}

    local base = normalizeBaseUrl(installCfg.base_url or installCfg.base or DEFAULT_BASE_URL)
    if base == "" then base = normalizeBaseUrl(DEFAULT_BASE_URL) end

    local ref = trim(installCfg.ref or DEFAULT_REF)
    if ref == "" then ref = DEFAULT_REF end

    local manifestPath = trim(installCfg.manifest_path or DEFAULT_MANIFEST_PATH)
    if manifestPath == "" then manifestPath = DEFAULT_MANIFEST_PATH end
    manifestPath = manifestPath:gsub("^/+", "")

    return base .. ref .. "/" .. manifestPath
end

function M.defaultState(installedInfo)
    local installed = nil
    if type(installedInfo) == "table" and type(installedInfo.version) == "string" then
        installed = installedInfo.version
    end

    return {
        status = "init",
        installed_version = installed,
        available_version = nil,
        checked_at_ms = nil,
        ttl_ms = DEFAULT_TTL_MS,
        stale = false,
        manifest_url = nil,
        err = nil,
    }
end

function M.parseCacheText(txt)
    if type(txt) ~= "string" or txt == "" then return nil end
    local ok, obj = pcall(textutils.unserializeJSON, txt)
    if not ok or type(obj) ~= "table" then return nil end
    return obj
end

function M.normalizeCache(obj)
    if type(obj) ~= "table" then return nil end
    local out = {
        status = tostring(obj.status or "") ~= "" and tostring(obj.status) or "init",
        installed_version = nil,
        available_version = nil,
        checked_at_ms = tonumber(obj.checked_at_ms) or nil,
        ttl_ms = tonumber(obj.ttl_ms) or DEFAULT_TTL_MS,
        stale = obj.stale == true,
        manifest_url = (type(obj.manifest_url) == "string" and trim(obj.manifest_url) ~= "") and trim(obj.manifest_url) or
            nil,
        err = (type(obj.err) == "string" and trim(obj.err) ~= "") and trim(obj.err) or nil,
    }

    if type(obj.available_version) == "string" and Version.isValid(obj.available_version) then
        out.available_version = obj.available_version
    end
    return out
end

function M.loadCache()
    local txt = Util.readFile(CACHE_PATH)
    if txt == nil then return nil end
    local obj = M.parseCacheText(txt)
    return M.normalizeCache(obj)
end

local function saveCache(stateUpdate)
    Util.ensureDir("data")
    local payload = {
        status = stateUpdate.status,
        available_version = stateUpdate.available_version,
        checked_at_ms = stateUpdate.checked_at_ms,
        ttl_ms = stateUpdate.ttl_ms,
        stale = stateUpdate.stale == true,
        manifest_url = stateUpdate.manifest_url,
        err = stateUpdate.err,
    }
    Util.writeFileAtomic(CACHE_PATH, Util.jsonEncode(payload))
end

function M.shouldRefresh(stateUpdate, nowMs)
    if type(stateUpdate) ~= "table" then return true end
    nowMs = tonumber(nowMs) or Util.nowUtcMs()
    local checked = tonumber(stateUpdate.checked_at_ms)
    local ttl = tonumber(stateUpdate.ttl_ms) or DEFAULT_TTL_MS
    if not checked then return true end
    return (nowMs - checked) >= ttl
end

local function httpGetText(url)
    local resp, err = http.get(url)
    if not resp then
        return nil, "http_get_failed:" .. tostring(err)
    end
    local code = resp.getResponseCode and resp.getResponseCode() or nil
    local body = resp.readAll()
    resp.close()
    if code and code ~= 200 then
        return nil, "http_status:" .. tostring(code)
    end
    if not body or body == "" then
        return nil, "http_empty"
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
        if i < tries then os.sleep(0.5) end
    end
    return nil, lastErr or "http_failed"
end

local function applyInstalled(stateUpdate, installedInfo)
    if type(installedInfo) == "table" and type(installedInfo.version) == "string" and Version.isValid(installedInfo.version) then
        stateUpdate.installed_version = installedInfo.version
    else
        stateUpdate.installed_version = nil
    end
end

function M.refresh(state, opts)
    opts = (type(opts) == "table") and opts or {}
    local tries = tonumber(opts.tries) or 2

    state.update = (type(state.update) == "table") and state.update or M.defaultState(state.installed)
    applyInstalled(state.update, state.installed)
    state.update.ttl_ms = DEFAULT_TTL_MS

    local installCfg = nil
    do
        local txt = Util.readFile("data/install.json")
        local parsed = M.parseCacheText(txt or "")
        installCfg = (type(parsed) == "table") and parsed or {}
    end
    local manifestUrl = M.buildManifestUrl(installCfg)
    state.update.manifest_url = manifestUrl

    local nowMs = Util.nowUtcMs()

    if not httpAvailable() then
        state.update.status = "http_off"
        state.update.err = "http_off"
        state.update.checked_at_ms = nowMs
        state.update.stale = state.update.available_version ~= nil
        saveCache(state.update)
        return state.update
    end

    if type(http.checkURL) == "function" then
        local ok, err = http.checkURL(manifestUrl)
        if not ok then
            state.update.status = "http_blocked"
            state.update.err = "http_blocked:" .. tostring(err)
            state.update.checked_at_ms = nowMs
            state.update.stale = state.update.available_version ~= nil
            saveCache(state.update)
            return state.update
        end
    end

    local body, err = httpGetTextWithRetry(manifestUrl, tries)
    if not body then
        state.update.status = "error"
        state.update.err = tostring(err or "http_failed")
        state.update.checked_at_ms = nowMs
        state.update.stale = state.update.available_version ~= nil
        saveCache(state.update)
        return state.update
    end

    local ok, manifest = pcall(textutils.unserializeJSON, body)
    if not ok or type(manifest) ~= "table" then
        state.update.status = "error"
        state.update.err = "manifest_invalid_json"
        state.update.checked_at_ms = nowMs
        state.update.stale = state.update.available_version ~= nil
        saveCache(state.update)
        return state.update
    end

    local available = manifest.version
    if type(available) ~= "string" or not Version.isValid(available) then
        state.update.status = "error"
        state.update.err = "manifest_invalid_version"
        state.update.checked_at_ms = nowMs
        state.update.stale = state.update.available_version ~= nil
        saveCache(state.update)
        return state.update
    end

    state.update.available_version = available
    state.update.checked_at_ms = nowMs
    state.update.stale = false
    state.update.err = nil

    if not state.update.installed_version then
        state.update.status = "no_installed"
        saveCache(state.update)
        return state.update
    end

    local cmp = Version.compare(state.update.installed_version, available)
    if cmp == -1 then
        state.update.status = "update_available"
    else
        state.update.status = "no_update"
    end
    saveCache(state.update)
    return state.update
end

function M.tick(state, opts)
    opts = (type(opts) == "table") and opts or {}
    state.update = (type(state.update) == "table") and state.update or M.defaultState(state.installed)
    applyInstalled(state.update, state.installed)

    local nowMs = Util.nowUtcMs()
    if not M.shouldRefresh(state.update, nowMs) then
        local checked = tonumber(state.update.checked_at_ms) or nowMs
        local ttl = tonumber(state.update.ttl_ms) or DEFAULT_TTL_MS
        local remainingMs = math.max(0, (checked + ttl) - nowMs)
        return math.max(1, math.floor(remainingMs / 1000))
    end

    M.refresh(state, { tries = tonumber(opts.tries) or 2 })
    return math.max(10, math.floor((tonumber(state.update.ttl_ms) or DEFAULT_TTL_MS) / 1000))
end

function M.formatHeaderRight(state, width)
    width = tonumber(width) or 0
    local nowZ = os.date("!%H:%M:%SZ")

    local installed = nil
    if type(state) == "table" and type(state.installed) == "table" then
        installed = state.installed.version
    end
    if type(installed) ~= "string" or not Version.isValid(installed) then
        installed = nil
    end

    local upd = (type(state) == "table" and type(state.update) == "table") and state.update or {}
    local status = tostring(upd.status or "")
    local available = (type(upd.available_version) == "string" and Version.isValid(upd.available_version)) and
        upd.available_version or nil
    local staleMark = (upd.stale == true) and "*" or ""

    local right = nowZ .. " " .. (installed or "NO-VERSION")
    if installed and available then
        local cmp = Version.compare(installed, available)
        if cmp == -1 then
            right = nowZ .. " " .. installed .. "->" .. available .. staleMark
        end
    end

    if status == "http_off" or status == "http_blocked" then
        right = right .. " UPD:OFF"
    end

    if width > 0 then
        return shorten(right, width)
    end
    return right
end

function M.isUpdateAvailable(state)
    if type(state) ~= "table" then return false end
    if type(state.installed) ~= "table" or type(state.installed.version) ~= "string" then return false end
    if not Version.isValid(state.installed.version) then return false end
    if type(state.update) ~= "table" or type(state.update.available_version) ~= "string" then return false end
    if not Version.isValid(state.update.available_version) then return false end
    local cmp = Version.compare(state.installed.version, state.update.available_version)
    return cmp == -1
end

return M
