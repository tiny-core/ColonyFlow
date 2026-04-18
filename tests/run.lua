local function assertEq(a, b, msg)
  if a ~= b then
    error((msg or "assertEq falhou") .. ": esperado=" .. tostring(b) .. " obtido=" .. tostring(a), 2)
  end
end

local function ensureDir(path)
  if not fs.exists(path) then fs.makeDir(path) end
end

ensureDir("logs")
local reportPath = ("logs/tests-%s-%s.txt"):format(os.date("!%Y-%m-%d"), os.date("!%H%M%S"))
local report = fs.open(reportPath, "w")
local function logLine(s)
  s = tostring(s or "")
  print(s)
  if report then
    report.writeLine(s)
    report.flush()
  end
end

local failures = {}

if type(package) == "table" and type(package.path) == "string" then
  local cwd = shell and shell.dir() or ""
  if cwd == "" then
    package.path = "/?.lua;/?/init.lua;" .. package.path
  else
    package.path = "/" .. cwd .. "/?.lua;/" .. cwd .. "/?/init.lua;/?.lua;/?/init.lua;" .. package.path
  end
end

local function runTest(name, fn)
  local ok, resOrErr = pcall(fn)
  if ok then
    if resOrErr == "SKIP" then
      logLine("[SKIP] " .. name)
      return true
    end
    logLine("[OK] " .. name)
    return true
  end
  local msg = "[FAIL] " .. name .. " -> " .. tostring(resOrErr)
  logLine(msg)
  table.insert(failures, msg)
  return false
end

local total = 0
local passed = 0

local function makeCfg(values)
  local cfg = {}
  function cfg:get(section, key, default)
    local s = values[section]
    if not s then return default end
    local v = s[key]
    if v == nil or v == "" then return default end
    return v
  end

  function cfg:getNumber(section, key, default)
    local v = cfg:get(section, key, nil)
    if v == nil then return default end
    local n = tonumber(v)
    if not n then return default end
    return n
  end

  function cfg:getBool(section, key, default)
    local v = cfg:get(section, key, nil)
    if v == nil then return default end
    v = tostring(v):lower()
    if v == "true" or v == "1" or v == "yes" or v == "y" or v == "on" then return true end
    if v == "false" or v == "0" or v == "no" or v == "n" or v == "off" then return false end
    return default
  end

  function cfg:getList(section, key, default, sep)
    local v = cfg:get(section, key, nil)
    if v == nil then return default or {} end
    local out = {}
    local s = tostring(v)
    local delimiter = sep or ","
    for part in s:gmatch("[^" .. delimiter .. "]+") do
      local t = part:gsub("^%s+", ""):gsub("%s+$", "")
      if t ~= "" then table.insert(out, t) end
    end
    if #out == 0 then return default or {} end
    return out
  end

  return cfg
end

local tests = {
  { "config_ini_autogerado_com_defaults", function()
    local Config = require("lib.config")
    local oldFs = fs
    local writtenContent = nil
    fs = {
      exists = function(path) return false end,
      open = function(path, mode)
        if mode == "w" then
          return {
            write = function(content) writtenContent = content end,
            close = function() end
          }
        end
      end
    }
    local res = Config.ensureDefaults("config.ini")
    fs = oldFs

    assertEq(res.created, true, "deveria ter criado o arquivo")
    assertEq(type(res.defaults), "table", "deveria retornar os defaults parseados")
    assertEq(string.match(writtenContent, "%[core%]") ~= nil, true, "deveria conter a secao core")
    assertEq(string.match(writtenContent, "log_level=INFO") ~= nil, true, "deveria conter log_level=INFO")
  end },
  { "config_ini_patch_preserva_comentarios_e_insere_chaves", function()
    local Config = require("lib.config")

    local txt = table.concat({
      "[core]",
      "; comentario 1",
      "log_level=INFO",
      "unknown_key=keep",
      "",
      "[delivery]",
      "export_mode=auto",
      "; comentario 2",
      "",
    }, "\n")

    local res = Config.patchIniText(txt, {
      core = { log_level = "DEBUG", new_key = "x" },
      delivery = { export_mode = "buffer" },
    })

    assertEq(type(res), "table")
    assertEq(type(res.text), "string")
    assertEq(string.match(res.text, "; comentario 1") ~= nil, true, "deveria preservar comentarios")
    assertEq(string.match(res.text, "unknown_key=keep") ~= nil, true, "deveria preservar chaves desconhecidas")
    assertEq(string.match(res.text, "log_level=DEBUG") ~= nil, true, "deveria atualizar log_level")
    assertEq(string.match(res.text, "new_key=x") ~= nil, true, "deveria inserir chave ausente")
    assertEq(string.match(res.text, "export_mode=buffer") ~= nil, true, "deveria atualizar export_mode")
  end },
  { "config_ini_patch_cria_secao_ausente", function()
    local Config = require("lib.config")

    local txt = table.concat({
      "[core]",
      "log_level=INFO",
      "",
    }, "\n")

    local res = Config.patchIniText(txt, {
      delivery = { export_direction = "west" },
    })

    assertEq(string.match(res.text, "%[delivery%]") ~= nil, true, "deveria criar secao delivery")
    assertEq(string.match(res.text, "export_direction=west") ~= nil, true, "deveria inserir chave em secao criada")
  end },
  { "config_ini_patch_file_atomic_cria_backup_e_move", function()
    local Config = require("lib.config")

    local oldFs = fs
    local files = {}
    local existsSet = {}

    local function setFile(path, content)
      files[path] = content
      existsSet[path] = true
    end

    setFile("config.ini", table.concat({ "[core]", "log_level=INFO", "" }, "\n"))

    fs = {
      exists = function(path) return existsSet[path] == true end,
      isDir = function(path) return path == "data" or path == "data/backups" end,
      makeDir = function(path) existsSet[path] = true end,
      list = function(dir)
        dir = tostring(dir)
        local prefix = dir
        if prefix ~= "" and prefix:sub(-1) ~= "/" then prefix = prefix .. "/" end
        local out = {}
        local seen = {}
        for p, ok in pairs(existsSet) do
          if ok == true and tostring(p):sub(1, #prefix) == prefix then
            local rest = tostring(p):sub(#prefix + 1)
            local first = rest:match("^([^/]+)")
            if first and not seen[first] then
              seen[first] = true
              table.insert(out, first)
            end
          end
        end
        table.sort(out)
        return out
      end,
      getDir = function(path)
        local i = string.match(path, "^.*()/")
        if not i then return "" end
        return string.sub(path, 1, i - 1)
      end,
      getName = function(path)
        local i = string.match(path, "^.*()/")
        if not i then return path end
        return string.sub(path, i + 1)
      end,
      combine = function(a, b) return tostring(a) .. "/" .. tostring(b) end,
      open = function(path, mode)
        if mode == "r" then
          return {
            readAll = function() return files[path] end,
            close = function() end,
          }
        end
        if mode == "w" then
          local buf = ""
          return {
            write = function(s) buf = buf .. tostring(s or "") end,
            writeLine = function(s) buf = buf .. tostring(s or "") .. "\n" end,
            flush = function() end,
            close = function()
              files[path] = buf; existsSet[path] = true
            end,
          }
        end
        return nil
      end,
      delete = function(path)
        files[path] = nil; existsSet[path] = false
      end,
      move = function(src, dst)
        files[dst] = files[src]
        existsSet[dst] = true
        files[src] = nil
        existsSet[src] = false
      end,
    }

    local res = Config.patchIniFileAtomic("config.ini", { core = { log_level = "DEBUG" } },
      { backup_dir = "data/backups" })

    local backupPath = tostring(res.backup_path or "")
    local okSaved = res.ok == true
    local newTxt = files["config.ini"]
    local backupTxt = files[backupPath]
    local tmpStillThere = existsSet["config.ini.tmp"] == true

    fs = oldFs

    assertEq(okSaved, true, "deveria salvar com sucesso")
    assertEq(string.match(newTxt or "", "log_level=DEBUG") ~= nil, true, "deveria ter atualizado o arquivo")
    assertEq(backupPath ~= "", true, "deveria retornar backup_path")
    assertEq(type(backupTxt) == "string", true, "deveria escrever backup")
    assertEq(string.match(backupTxt or "", "log_level=INFO") ~= nil, true, "backup deveria conter o conteudo antigo")
    assertEq(tmpStillThere, false, "tmp nao deveria permanecer")
  end },
  { "config_schema_rejeita_valores_invalidos", function()
    local Schema = require("lib.config_schema")
    local res = Schema.validateUpdates({
      core = { poll_interval_seconds = "0", ui_refresh_seconds = "1", log_level = "INFO", log_max_files = "1", log_max_kb = "1" },
      delivery = { export_mode = "x", export_direction = "up", destination_cache_ttl_seconds = "-1" },
      peripherals = { monitor_requests = "m", monitor_status = "m" },
    })
    assertEq(res.ok, false)
    assertEq(#res.errors >= 3, true, "deveria reportar erros suficientes")
  end },
  { "semver_is_valid", function()
    local Version = require("lib.version")
    assertEq(Version.isValid("0.0.0"), true)
    assertEq(Version.isValid("1.2.3"), true)
    assertEq(Version.isValid("1.2"), false)
    assertEq(Version.isValid("1.2.3.4"), false)
    assertEq(Version.isValid("a.b.c"), false)
    assertEq(Version.isValid("01.2.3"), false)
  end },
  { "semver_compare", function()
    local Version = require("lib.version")
    local gt = Version.compare("1.0.0", "0.9.9")
    local lt = Version.compare("1.2.0", "1.2.1")
    local eq = Version.compare("1.2.3", "1.2.3")
    assertEq(gt, 1)
    assertEq(lt, -1)
    assertEq(eq, 0)
  end },
  { "update_check_build_manifest_url_defaults", function()
    local UpdateCheck = require("modules.update_check")
    local url = UpdateCheck.buildManifestUrl({})
    assertEq(url, "https://raw.githubusercontent.com/tiny-core/ColonyFlow/master/manifest.json")
  end },
  { "update_check_build_manifest_url_custom", function()
    local UpdateCheck = require("modules.update_check")
    local url = UpdateCheck.buildManifestUrl({
      base_url = "https://example.com/repo",
      ref = "main",
      manifest_path = "/m.json",
    })
    assertEq(url, "https://example.com/repo/main/m.json")
  end },
  { "update_check_normalize_cache_compat_old", function()
    local UpdateCheck = require("modules.update_check")
    local out = UpdateCheck.normalizeCache({
      status = "no_update",
      checked_at_ms = 12345,
      ttl_ms = 6000,
      available_version = "1.2.3",
    })
    assertEq(type(out), "table")
    assertEq(out.last_attempt_at_ms, 12345)
    assertEq(out.last_success_at_ms, 12345)
    assertEq(out.fail_count, 0)
    assertEq(out.next_retry_at_ms, nil)
    assertEq(out.available_version, "1.2.3")
  end },
  { "update_check_backoff_calculates_next_retry", function()
    local UpdateCheck = require("modules.update_check")
    local oldEpoch = os.epoch
    os.epoch = function() return 1000000 end

    local cfg = makeCfg({ update = { enabled = "true", ttl_hours = "6", retry_seconds = "120", error_backoff_max_seconds = "900" } })
    local state = { cfg = cfg, installed = { version = "1.0.0" }, update = UpdateCheck.defaultState({ version = "1.0.0" }) }
    state.update.status = "error"
    state.update.last_success_at_ms = 500000
    state.update.next_retry_at_ms = 1000000 + 120 * 1000

    local s1 = UpdateCheck.tick(state, { tries = 1 })
    assertEq(s1, 120)

    os.epoch = function() return 1000000 + 120 * 1000 end
    state.update.next_retry_at_ms = 1000000 + 120 * 1000 + 240 * 1000
    local s2 = UpdateCheck.tick(state, { tries = 1 })
    assertEq(s2, 240)

    os.epoch = oldEpoch
  end },
  { "update_check_success_uses_ttl", function()
    local UpdateCheck = require("modules.update_check")

    local oldEpoch = os.epoch
    os.epoch = function() return 3000000 end

    local oldHttp = http
    http = {
      checkURL = function() return true end,
      get = function()
        return {
          getResponseCode = function() return 200 end,
          readAll = function() return '{"version":"1.0.1"}' end,
          close = function() end,
        }
      end,
    }

    local oldFs = fs
    local files = {}
    local existsSet = {}
    local dirSet = { ["data"] = true }
    existsSet["data"] = true
    fs = {
      exists = function(path) return existsSet[path] == true end,
      isDir = function(path) return dirSet[path] == true end,
      makeDir = function(path)
        existsSet[path] = true; dirSet[path] = true
      end,
      getDir = function(path)
        local i = string.match(path, "^.*()/")
        if not i then return "" end
        return string.sub(path, 1, i - 1)
      end,
      open = function(path, mode)
        if mode == "r" then
          return {
            readAll = function() return files[path] end,
            close = function() end,
          }
        end
        if mode == "w" then
          local buf = ""
          return {
            write = function(s) buf = buf .. tostring(s or "") end,
            writeLine = function(s) buf = buf .. tostring(s or "") .. "\n" end,
            flush = function() end,
            close = function()
              files[path] = buf; existsSet[path] = true
            end,
          }
        end
        return nil
      end,
      delete = function(path)
        files[path] = nil; existsSet[path] = false
      end,
      move = function(src, dst)
        files[dst] = files[src]
        existsSet[dst] = true
        files[src] = nil
        existsSet[src] = false
      end,
    }

    local cfg = makeCfg({ update = { enabled = "true", ttl_hours = "6", retry_seconds = "120", error_backoff_max_seconds = "900" } })
    local state = { cfg = cfg, installed = { version = "1.0.0" }, update = UpdateCheck.defaultState({ version = "1.0.0" }) }

    local s1 = UpdateCheck.tick(state, { tries = 1 })
    assertEq(s1, 6 * 60 * 60)
    assertEq(state.update.status, "update_available")
    assertEq(state.update.stale, false)
    assertEq(state.update.fail_count, 0)
    assertEq(state.update.next_retry_at_ms, nil)
    assertEq(state.update.last_success_at_ms, 3000000)

    fs = oldFs
    http = oldHttp
    os.epoch = oldEpoch
  end },
  { "update_check_error_does_not_wait_ttl", function()
    local UpdateCheck = require("modules.update_check")

    local oldEpoch = os.epoch
    os.epoch = function() return 4000000 end

    local cfg = makeCfg({ update = { enabled = "true", ttl_hours = "6", retry_seconds = "120", error_backoff_max_seconds = "900" } })
    local state = { cfg = cfg, installed = { version = "1.0.0" }, update = UpdateCheck.defaultState({ version = "1.0.0" }) }
    state.update.status = "http_off"
    state.update.last_success_at_ms = 3999000 -- TTL diria para esperar quase 6h
    state.update.next_retry_at_ms = 4000000 + 120 * 1000

    local s1 = UpdateCheck.tick(state, { tries = 1 })
    assertEq(s1, 120)

    os.epoch = oldEpoch
  end },
  { "update_check_format_header_right", function()
    local UpdateCheck = require("modules.update_check")
    local state = {
      installed = { version = "1.2.3" },
      update = { status = "update_available", installed_version = "1.2.3", available_version = "1.2.4", stale = false }
    }
    local out = UpdateCheck.formatHeaderRight(state, 200)
    assertEq(string.match(out, "1%.2%.3%-%>1%.2%.4") ~= nil, true)

    state.update.status = "http_off"
    local out2 = UpdateCheck.formatHeaderRight(state, 200)
    assertEq(string.match(out2, "UPD:OFF") ~= nil, true)

    local out3 = UpdateCheck.formatHeaderRight({ installed = nil, update = { status = "no_installed" } }, 200)
    assertEq(string.match(out3, "NO%-VERSION") ~= nil, true)

    local out4 = UpdateCheck.formatHeaderRight(state, 10)
    assertEq(#out4 <= 10, true, "deveria truncar pelo width")
  end },
  { "mappings_json_skeleton_quando_ausente", function()
    local Equivalence = require("modules.equivalence")

    local oldFsExists = fs.exists
    local oldFsOpen = fs.open
    local oldFsMakeDir = fs.makeDir
    local oldFsIsDir = fs.isDir
    local oldFsGetDir = fs.getDir

    local writtenContent = nil
    fs.exists = function(path) return false end
    fs.open = function(path, mode)
      if mode == "w" then
        return {
          write = function(content) writtenContent = content end,
          close = function() end
        }
      end
    end
    fs.makeDir = function() end
    fs.isDir = function() return true end
    fs.getDir = function() return "data" end

    local eq = Equivalence.new({ logger = { info = function() end } })

    fs.exists = oldFsExists
    fs.open = oldFsOpen
    fs.makeDir = oldFsMakeDir
    fs.isDir = oldFsIsDir
    fs.getDir = oldFsGetDir

    assertEq(type(writtenContent), "string", "deveria ter escrito algo")
    assertEq(string.match(writtenContent, '"rules"') ~= nil, true, "deveria conter rules")
    assertEq(string.match(writtenContent, '"tier_overrides"') ~= nil, true, "deveria conter tier_overrides")
    assertEq(string.match(writtenContent, '"gating"') ~= nil, true, "deveria conter gating")
    assertEq(string.match(writtenContent, '"by_building_type"') ~= nil, true, "deveria conter by_building_type")
  end },
  { "peripherals_discover_nao_crasha_em_erro", function()
    local Peripherals = require("modules.peripherals")
    local oldPeripheral = peripheral
    peripheral = {
      find = function() error("fake find error") end,
      wrap = function() error("fake wrap error") end,
      getNames = function() error("fake getNames error") end,
      isPresent = function() error("fake isPresent error") end,
      getName = function() error("fake getName error") end
    }
    local logger = { warn = function() end, info = function() end, error = function() end }

    local cfg = makeCfg({ peripherals = {}, core = { log_dir = "logs" } })

    local devices, issues = Peripherals.discover(cfg, logger)

    peripheral = oldPeripheral

    assertEq(type(devices), "table", "devices deveria ser uma tabela")
    assertEq(type(issues), "table", "issues deveria ser uma tabela")
    assertEq(#issues > 0, true, "deveria ter reportado problemas por nao achar perifericos")
  end },
  { "equivalencias_basicas", function()
    local eq = require("modules.equivalence").new({ cache = { get = function() end, set = function() end } })
    local list = eq:getEquivalents("minecraft:iron_chestplate")
    assertEq(type(list), "table")
    assertEq(list[1], "minecraft:iron_chestplate")
  end
  },
  { "equivalencia_jetpack", function()
    local eq = require("modules.equivalence").new({ cache = { get = function() end, set = function() end } })
    local metaA = eq:getItemMeta("minecraft:iron_chestplate")
    local metaB = eq:getItemMeta("ironjetpacks:armored_jetpack")
    if metaA == nil and metaB == nil then
      return "SKIP"
    end
    local list = eq:getEquivalents("minecraft:iron_chestplate")
    local found = false
    for _, v in ipairs(list) do
      if v == "ironjetpacks:armored_jetpack" then found = true end
    end
    assertEq(found, true, "jetpack equivalente não encontrado")
  end
  },
  { "tier_por_nome", function()
    local eqMod = require("modules.equivalence").new({ cache = { get = function() end, set = function() end } })
    local tier = require("modules.tier").new({}, eqMod)
    local t = tier:infer({ name = "minecraft:diamond_pickaxe" })
    assertEq(t, "diamond")
  end
  },
  { "tier_por_tags", function()
    local eqMod = require("modules.equivalence").new({ cache = { get = function() end, set = function() end } })
    local tier = require("modules.tier").new({}, eqMod)
    local t = tier:infer({ name = "mod:tool", tags = { "forge:tools/pickaxes", "forge:ingots/netherite" } })
    assertEq(t, "netherite")
  end
  },
  { "tier_gating", function()
    local eqMod = require("modules.equivalence").new({ cache = { get = function() end, set = function() end } })
    local tier = require("modules.tier").new({}, eqMod)
    assertEq(tier:isTierAllowed("tool_pickaxe", "iron", "diamond"), true)
    assertEq(tier:isTierAllowed("tool_pickaxe", "netherite", "diamond"), false)
    assertEq(tier:isTierAllowed("armor_chestplate", "diamond", "iron"), false)
  end
  },
  { "minecolonies_id_estavel_sem_rid", function()
    local Mine = require("modules.minecolonies")
    local state = {
      devices = {
        colonyIntegrator = {
          getRequests = function()
            return {
              {
                id = nil,
                state = "requested",
                target = "builder",
                count = 4,
                items = {
                  { name = "minecraft:iron_chestplate",    count = 4, tags = { "forge:armor" }, nbt = { a = 1 } },
                  { name = "ironjetpacks:armored_jetpack", count = 4 },
                },
              },
            }
          end,
        },
      },
      logger = { error = function() end },
    }
    local mine = Mine.new(state)
    local r1 = mine:listRequests()[1]
    local r2 = mine:listRequests()[1]
    assertEq(type(r1.id), "string")
    assertEq(r1.id, r2.id, "id não é estável entre leituras")
    assertEq(r1.requiredCount, 4)
    assertEq(type(r1.accepted), "table")
    assertEq(r1.accepted[1].name, "minecraft:iron_chestplate")
  end
  },
  { "minecolonies_merge_workorders_builder_resources", function()
    local Mine = require("modules.minecolonies")
    local state = {
      devices = {
        colonyIntegrator = {
          getRequests = function()
            return {
              { id = "eq1", state = "requested", target = "guard", count = 1, items = { { name = "minecraft:iron_sword", count = 1 } } },
            }
          end,
          getWorkOrders = function()
            return {
              { id = 99, buildingName = "builder", type = "builder", workOrderType = "WorkOrderBuilding" },
            }
          end,
          getWorkOrderResources = function()
            return {
              { item = "minecraft:oak_planks", displayName = "Oak Planks", needs = 10, available = false, delivering = false },
            }
          end,
        },
      },
      logger = { error = function() end },
    }

    local mine = Mine.new(state)
    local reqs = mine:listRequests()
    assertEq(#reqs, 2)
    assertEq(reqs[1].id, "eq1")
    assertEq(reqs[2].id, "wo:99:minecraft:oak_planks")
    assertEq(reqs[2].accepted[1].name, "minecraft:oak_planks")
    assertEq(reqs[2].requiredCount, 10)
  end
  },
  { "minecolonies_merge_builder_resources_fallback", function()
    local Mine = require("modules.minecolonies")
    local state = {
      devices = {
        colonyIntegrator = {
          getRequests = function() return {} end,
          getWorkOrders = function()
            return {
              { id = 7, buildingName = "builder", type = "builder", builder = { x = 1, y = 2, z = 3 } },
            }
          end,
          getBuilderResources = function()
            return {
              { item = "minecraft:cobblestone", displayName = "Cobblestone", needs = 99, available = false, delivering = false },
            }
          end,
        },
      },
      logger = { error = function() end, warn = function() end },
    }

    local mine = Mine.new(state)
    local reqs = mine:listRequests()
    assertEq(#reqs, 1)
    assertEq(reqs[1].id, "wo:7:minecraft:cobblestone")
    assertEq(reqs[1].accepted[1].name, "minecraft:cobblestone")
    assertEq(reqs[1].requiredCount, 99)
  end
  },
  { "engine_pending_configuravel", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local invReads = 0
    local inv = {
      list = function()
        invReads = invReads + 1
        return { [1] = { name = "minecraft:iron_chestplate", count = 1 } }
      end,
    }

    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "2" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "false", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        colonyIntegrator = {
          getRequests = function()
            return {
              { id = 1, state = "requested", target = "x", count = 2, items = { { name = "minecraft:iron_chestplate", count = 2 } } },
              { id = 2, state = "completed", target = "x", count = 2, items = { { name = "minecraft:iron_chestplate", count = 2 } } },
            }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["1"].missing, 1)
    assertEq(state.work["2"], nil, "request completed não deveria ser processada")
    assertEq(invReads, 1)
    engine:tick()
    assertEq(invReads, 1, "snapshot deveria vir do cache dentro do TTL")

    peripheral = oldPeripheral
  end
  },
  { "engine_mod_nao_allowlisted_fallback_vanilla", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local inv = { list = function() return {} end }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "2" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "false", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        colonyIntegrator = {
          getRequests = function()
            return {
              {
                id = 3,
                state = "requested",
                target = "x",
                count = 1,
                items = {
                  { name = "mod:unknown_item",          count = 1 },
                  { name = "minecraft:iron_chestplate", count = 1 },
                },
              },
            }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["3"].chosen, "minecraft:iron_chestplate")

    peripheral = oldPeripheral
  end
  },
  { "engine_craft_nao_duplica_jobs", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local inv = { list = function() return {} end }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local craftCalls = 0
    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 0, isCraftable = true } end,
      isItemCraftable = function(filter) return true end,
      isItemCrafting = function(filter) return false end,
      craftItem = function(filter)
        craftCalls = craftCalls + 1; return true, "ok"
      end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "2" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "false", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              { id = 10, state = "requested", target = "x", count = 2, items = { { name = "minecraft:dirt", count = 2 } } },
            }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    engine:tick()
    assertEq(craftCalls, 1, "craftItem duplicado em ticks consecutivos")

    peripheral = oldPeripheral
  end
  },
  { "engine_entrega_valida_snapshot", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local invCount = 0
    local inv = {
      list = function()
        if invCount == 0 then return {} end
        return { [1] = { name = "minecraft:dirt", count = invCount } }
      end,
    }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local craftCalls = 0
    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 2, isCraftable = true } end,
      exportItemToPeripheral = function(filter, target)
        assertEq(target, "test_inv")
        invCount = invCount + (filter.count or 0)
        return tonumber(filter.count or 0), nil
      end,
      craftItem = function(filter)
        craftCalls = craftCalls + 1; return true, "ok"
      end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "2" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "false", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              { id = 11, state = "requested", target = "x", count = 2, items = { { name = "minecraft:dirt", count = 2 } } },
            }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["11"].status, "done")
    assertEq(state.work["11"].delivered, 2)
    assertEq(state.stats.delivered, 2)
    assertEq(craftCalls, 0, "não deveria iniciar craft quando já há estoque no ME")

    peripheral = oldPeripheral
  end
  },
  { "engine_destino_cheio_waiting_retry", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local inv = { list = function() return {} end }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 2, isCraftable = true } end,
      exportItemToPeripheral = function(filter, target) return 0, "cheio" end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "2" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "false", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              { id = 12, state = "requested", target = "x", count = 2, items = { { name = "minecraft:dirt", count = 2 } } },
            }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["12"].status, "waiting_retry")
    assertEq(type(state.work["12"].next_retry), "number")

    peripheral = oldPeripheral
  end
  },
  { "engine_gating_escolhe_tier_menor", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local inv = { list = function() return {} end }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local craftedName = nil
    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 0, isCraftable = true } end,
      isItemCraftable = function(filter) return true end,
      isItemCrafting = function(filter) return false end,
      craftItem = function(filter)
        craftedName = filter.name; return true, "ok"
      end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "2" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "true", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              {
                id = 13,
                state = "requested",
                target = "builder",
                count = 1,
                items = {
                  { name = "minecraft:diamond_pickaxe", count = 1 },
                  { name = "minecraft:iron_pickaxe",    count = 1 },
                },
              },
            }
          end,
          getBuildings = function()
            return {
              { name = "builder", type = "builder", level = 1, built = true },
            }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["13"].chosen, "minecraft:iron_pickaxe")
    assertEq(craftedName, "minecraft:iron_pickaxe")

    peripheral = oldPeripheral
  end
  },
  { "engine_guard_lv5_prefere_maior_tier_craftavel", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local inv = { list = function() return {} end }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local craftedName = nil
    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 0, isCraftable = false } end,
      isItemCraftable = function(filter)
        if filter.name == "minecraft:netherite_sword" then return false end
        if filter.name == "minecraft:diamond_sword" then return true end
        if filter.name == "minecraft:iron_sword" then return true end
        return false
      end,
      isItemCrafting = function() return false end,
      craftItem = function(filter)
        craftedName = filter.name; return true, "ok"
      end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "in_progress", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "0" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "true", tier_preference = "lowest" },
      progression = { enforce_building_gating = "true" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              {
                id = 200,
                state = "in_progress",
                target = "Knight Test",
                count = 1,
                items = {
                  { name = "minecraft:netherite_sword", count = 1 },
                  { name = "minecraft:diamond_sword",   count = 1 },
                  { name = "minecraft:iron_sword",      count = 1 },
                },
              },
            }
          end,
          getBuildings = function() return {} end,
          getCitizens = function()
            return {
              { id = "c1", name = "Test", work = { type = "guardtower", level = 5, name = "Guard Tower" } },
            }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["200"].chosen, "minecraft:diamond_sword")
    assertEq(craftedName, "minecraft:diamond_sword")

    peripheral = oldPeripheral
  end
  },
  { "engine_prefere_disponivel_ou_craftavel", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local inv = { list = function() return {} end }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local craftedName = nil
    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter)
        if filter.name == "minecraft:iron_sword" then
          return { name = filter.name, amount = 1, isCraftable = false }
        end
        return { name = filter.name, amount = 0, isCraftable = false }
      end,
      isItemCraftable = function(filter)
        if filter.name == "minecraft:netherite_sword" then return false end
        if filter.name == "minecraft:iron_sword" then return true end
        return false
      end,
      isItemCrafting = function(filter) return false end,
      craftItem = function(filter)
        craftedName = filter.name; return true, "ok"
      end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "2" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "true", tier_preference = "highest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              {
                id = 14,
                state = "requested",
                target = "builder",
                count = 1,
                items = {
                  { name = "minecraft:netherite_sword", count = 1 },
                  { name = "minecraft:iron_sword",      count = 1 },
                },
              },
            }
          end,
          getBuildings = function()
            return { { name = "builder", type = "builder", level = 5, built = true } }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["14"].chosen, "minecraft:iron_sword")
    assertEq(craftedName, nil, "não deveria craftar quando já existe em estoque")

    peripheral = oldPeripheral
  end
  },
  { "me_amount_fallback_listItems", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local invCount = 0
    local inv = {
      list = function()
        if invCount == 0 then return {} end
        return { [1] = { name = "minecraft:dirt", count = invCount } }
      end,
    }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return nil end,
      getItems = function(filter)
        return { { name = "minecraft:dirt", amount = 2, isCraftable = true } }
      end,
      exportItemToPeripheral = function(filter, target)
        invCount = invCount + (filter.count or 0)
        return tonumber(filter.count or 0), nil
      end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "2" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "true", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return { { id = 15, state = "requested", target = "x", count = 2, items = { { name = "minecraft:dirt", count = 2 } } } }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["15"].status, "done")
    assertEq(invCount, 2)

    peripheral = oldPeripheral
  end
  },
  { "engine_export_auto_buffer_fallback", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local rackCount = 0
    local bufferCount = 0

    local rackInv = {
      list = function()
        if rackCount == 0 then return {} end
        return { [1] = { name = "minecraft:dirt", count = rackCount } }
      end,
    }

    local bufferInv = {
      list = function()
        if bufferCount == 0 then return {} end
        return { [1] = { name = "minecraft:dirt", count = bufferCount } }
      end,
      pushItems = function(target, slot, limit)
        assertEq(target, "minecolonies:rack_0")
        local moved = math.min(bufferCount, limit or bufferCount)
        bufferCount = bufferCount - moved
        rackCount = rackCount + moved
        return moved
      end,
    }

    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "minecolonies:rack_0" or name == "minecraft:chest_0" end,
      wrap = function(name)
        if name == "minecolonies:rack_0" then return rackInv end
        if name == "minecraft:chest_0" then return bufferInv end
        return nil
      end,
    }

    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 2, isCraftable = false } end,
      exportItem = function(filter, dir)
        assertEq(dir, "up")
        bufferCount = bufferCount + (filter.count or 0)
        return tonumber(filter.count or 0), nil
      end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = {
        default_target_container = "minecolonies:rack_0",
        export_mode = "auto",
        export_direction = "up",
        export_buffer_container = "minecraft:chest_0",
        destination_cache_ttl_seconds = "0",
      },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "true", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return { { id = 16, state = "requested", target = "x", count = 2, items = { { name = "minecraft:dirt", count = 2 } } } }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["16"].status, "done")
    assertEq(rackCount, 2)

    peripheral = oldPeripheral
  end
  },
  { "engine_duas_requests_nao_compartilham_mesmo_item_no_destino", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local invCount = 1
    local inv = {
      list = function()
        if invCount == 0 then return {} end
        return { [1] = { name = "minecraft:iron_sword", count = invCount } }
      end,
    }

    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "minecolonies:rack_0" end,
      wrap = function() return inv end,
    }

    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 2, isCraftable = false } end,
      exportItemToPeripheral = function(filter, target)
        assertEq(target, "minecolonies:rack_0")
        invCount = invCount + (filter.count or 0)
        return tonumber(filter.count or 0), nil
      end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "minecolonies:rack_0", destination_cache_ttl_seconds = "0", export_mode = "peripheral" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "true", tier_preference = "lowest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              { id = 20, state = "requested", target = "a", count = 1, items = { { name = "minecraft:iron_sword", count = 1 } } },
              { id = 21, state = "requested", target = "b", count = 1, items = { { name = "minecraft:iron_sword", count = 1 } } },
            }
          end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()

    assertEq(state.work["20"].status, "done")
    assertEq(state.work["21"].status, "done")
    assertEq(state.stats.delivered, 1, "deveria entregar 1 item adicional para a segunda request")
    assertEq(invCount, 2)

    peripheral = oldPeripheral
  end
  },
  { "engine_nao_craftavel_vira_waiting_retry", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local inv = { list = function() return {} end }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 0, isCraftable = false } end,
      isItemCraftable = function() return false end,
      isItemCrafting = function() return false end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "0" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "true", tier_preference = "highest" },
      progression = { enforce_building_gating = "true" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              {
                id = 300,
                state = "requested",
                target = "builder",
                count = 1,
                items = { { name = "minecraft:torch", count = 1 } },
              },
            }
          end,
          getBuildings = function() return { { name = "builder", type = "builder", level = 5, built = true } } end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()

    assertEq(state.work["300"].status, "waiting_retry")
    assertEq(state.work["300"].err, "nao_craftavel")

    peripheral = oldPeripheral
  end
  },
  { "ui_falta_mostra_needed_mesmo_sem_candidato", function()
    local Engine = require("modules.engine")
    local Cache = require("lib.cache")

    local inv = { list = function() return {} end }
    local oldPeripheral = peripheral
    peripheral = {
      isPresent = function(name) return name == "test_inv" end,
      wrap = function() return inv end,
    }

    local meBridge = {
      isConnected = function() return true end,
      isOnline = function() return true end,
      getItem = function(filter) return { name = filter.name, amount = 0, isCraftable = false } end,
      isItemCraftable = function() return false end,
      isItemCrafting = function() return false end,
    }

    local cfg = makeCfg({
      minecolonies = { pending_states_allow = "requested", completed_states_deny = "completed,done" },
      delivery = { default_target_container = "test_inv", destination_cache_ttl_seconds = "0" },
      substitution = { vanilla_first = "true", allow_unmapped_mods = "true", tier_preference = "highest" },
    })

    local state = {
      cfg = cfg,
      cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }),
      logger = { warn = function() end, info = function() end, error = function() end },
      devices = {
        meBridge = meBridge,
        colonyIntegrator = {
          getRequests = function()
            return {
              { id = 310, state = "requested", target = "builder", count = 3, items = { { name = "minecraft:torch", count = 3 } } },
            }
          end,
          getBuildings = function() return { { name = "builder", type = "builder", level = 5, built = true } } end,
          getColonyName = function() return "t" end,
          amountOfCitizens = function() return 0 end,
          maxOfCitizens = function() return 0 end,
          getHappiness = function() return 0 end,
          isUnderAttack = function() return false end,
          amountOfConstructionSites = function() return 0 end,
        },
      },
      requests = {},
      stats = { processed = 0, crafted = 0, delivered = 0, substitutions = 0, errors = 0 },
    }

    local engine = Engine.new(state)
    state.work = engine.work
    engine:tick()
    assertEq(state.work["310"].missing, 3)

    peripheral = oldPeripheral
  end
  },
  { "logger_cleanup_respeita_max_files_sem_apagar_atual", function()
    local Logger = require("lib.logger")

    local oldFs = fs
    local deleted = {}
    local opened = {}
    local currentPath = nil
    local existsSet = {}

    fs = {
      exists = function(path) return existsSet[path] == true end,
      isDir = function(path) return path == "logs" end,
      makeDir = function(path) existsSet[path] = true end,
      list = function(path)
        assertEq(path, "logs")
        local out = {
          "minecolonies-me-2026-04-08.log",
          "minecolonies-me-2026-04-09.log",
          "minecolonies-me-2026-04-10.log",
        }
        for _, f in ipairs(out) do
          existsSet["logs/" .. f] = true
        end
        return out
      end,
      combine = function(a, b) return tostring(a) .. "/" .. tostring(b) end,
      open = function(path, mode)
        currentPath = path
        opened[path] = mode
        existsSet[path] = true
        return {
          writeLine = function() end,
          flush = function() end,
          close = function() end,
        }
      end,
      getSize = function() return 0 end,
      move = function() end,
      delete = function(path)
        deleted[path] = true; existsSet[path] = false
      end,
      getDir = function(path) return "logs" end,
    }

    local cfg = makeCfg({
      core = { log_dir = "logs", log_level = "INFO", log_max_files = "2", log_max_kb = "1024" },
    })

    local logger = Logger.new(cfg)
    assertEq(type(logger), "table")
    assertEq(currentPath, "logs/minecolonies-me-" .. os.date("!%Y-%m-%d") .. ".log")

    local shouldDelete = "logs/minecolonies-me-2026-04-08.log"
    assertEq(deleted[shouldDelete] == true, true, "deveria apagar o log mais antigo")
    assertEq(deleted["logs/minecolonies-me-2026-04-09.log"] == true, false, "não deveria apagar o penúltimo log")
    assertEq(deleted[currentPath] == true, false, "não deveria apagar o log atual")

    fs = oldFs
  end
  },
  { "me_bridge_api_fallbacks", function()
    local ME = require("modules.me")
    local bridge = {
      isItemCraftable = function(filter) return true end,
      isItemCrafting = function(filter) return true end,
      exportItemToPeripheral = function(filter, target)
        assertEq(target, "dest_inv")
        return tonumber(filter.count or 0), nil
      end,
    }
    local state = { devices = { meBridge = bridge } }
    local me = ME.new(state)
    local okCraftable = me:isCraftable({ name = "minecraft:dirt", count = 1 })
    assertEq(okCraftable, true)
    local okCrafting = me:isCrafting({ name = "minecraft:dirt", count = 1 })
    assertEq(okCrafting, true)
    local exported = me:exportItem({ name = "minecraft:dirt", count = 3 }, "dest_inv")
    assertEq(exported, 3)
  end
  },
  { "me_bridge_export_direction_fallback", function()
    local ME = require("modules.me")
    local bridge = {
      exportItem = function(filter, dir)
        assertEq(dir, "up")
        return tonumber(filter.count or 0), nil
      end,
    }
    local state = { devices = { meBridge = bridge } }
    local me = ME.new(state)
    local exported = me:exportItem({ name = "minecraft:dirt", count = 2 }, "up")
    assertEq(exported, 2)
  end
  },
  { "me_getItem_cache_hit_e_ttl0", function()
    local ME = require("modules.me")
    local Cache = require("lib.cache")

    local calls = 0
    local bridge = {
      getItem = function(filter)
        calls = calls + 1
        return { name = filter.name, amount = calls, isCraftable = false }
      end,
    }

    local cfgOn = makeCfg({ cache = { me_item_ttl_seconds = "10" } })
    local stateOn = { cfg = cfgOn, cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }), devices = { meBridge = bridge } }
    local meOn = ME.new(stateOn)
    local a1 = meOn:getItem({ name = "minecraft:dirt" })
    local a2 = meOn:getItem({ name = "minecraft:dirt" })
    assertEq(calls, 1, "cache deveria evitar chamada duplicada")
    assertEq(type(a1), "table")
    assertEq(type(a2), "table")
    assertEq(a2.amount, a1.amount)

    local cfgOff = makeCfg({ cache = { me_item_ttl_seconds = "0" } })
    local stateOff = { cfg = cfgOff, cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }), devices = { meBridge = bridge } }
    local meOff = ME.new(stateOff)
    local _ = meOff:getItem({ name = "minecraft:stone" })
    local _ = meOff:getItem({ name = "minecraft:stone" })
    assertEq(calls >= 3, true, "ttl=0 não deveria cachear")
  end
  },
  { "me_isCraftable_cache_hit", function()
    local ME = require("modules.me")
    local Cache = require("lib.cache")

    local calls = 0
    local bridge = {
      isItemCraftable = function(filter)
        calls = calls + 1
        return true
      end,
    }

    local cfg = makeCfg({ cache = { me_craftable_ttl_seconds = "10" } })
    local state = { cfg = cfg, cache = Cache.new({ max_entries = 2000, default_ttl_seconds = 5 }), devices = { meBridge = bridge } }
    local me = ME.new(state)

    local c1 = me:isCraftable({ name = "minecraft:dirt", count = 1 })
    local c2 = me:isCraftable({ name = "minecraft:dirt", count = 1 })
    assertEq(c1, true)
    assertEq(c2, true)
    assertEq(calls, 1, "cache deveria evitar chamada duplicada")
  end
  },
  { "mapping_v2_carrega_regras_por_item", function()
    local Equivalence = require("modules.equivalence")
    local oldFs = fs
    local json = textutils.serializeJSON({
      version = 2,
      rules = {
        { selector = "mod:item", kind = "item", class = "tool_pickaxe", prefer_equivalent = true },
      },
      items = {},
      classes = {},
      tier_overrides = {},
      gating = { by_building_type = {} }
    }, { pretty = true })

    fs = {
      exists = function(path) return path == "data/mappings.json" end,
      open = function(path, mode)
        if path ~= "data/mappings.json" or mode ~= "r" then return nil end
        return {
          readAll = function() return json end,
          close = function() end
        }
      end,
      isDir = function() return true end,
      makeDir = function() end,
      getDir = function() return "data" end,
      attributes = function() return { modified = 1 } end,
    }

    local eq = Equivalence.new({ logger = { warn = function() end, info = function() end } })
    local cls = eq:getClassFor({ name = "mod:item", tags = {} })
    local pref, has = eq:getPreferEquivalentFor({ name = "mod:item", tags = {} })

    fs = oldFs

    assertEq(cls, "tool_pickaxe")
    assertEq(pref, true)
    assertEq(has, true)
  end
  },
  { "mapping_v2_carrega_regras_por_tag", function()
    local Equivalence = require("modules.equivalence")
    local oldFs = fs
    local json = textutils.serializeJSON({
      version = 2,
      rules = {
        { selector = "#forge:tools/pickaxes", kind = "tag", class = "tool_pickaxe" },
      },
      items = {},
      classes = {},
      tier_overrides = {},
      gating = { by_building_type = {} }
    }, { pretty = true })

    fs = {
      exists = function(path) return path == "data/mappings.json" end,
      open = function(path, mode)
        if path ~= "data/mappings.json" or mode ~= "r" then return nil end
        return {
          readAll = function() return json end,
          close = function() end
        }
      end,
      isDir = function() return true end,
      makeDir = function() end,
      getDir = function() return "data" end,
      attributes = function() return { modified = 1 } end,
    }

    local eq = Equivalence.new({ logger = { warn = function() end, info = function() end } })
    local cls = eq:getClassFor({ name = "x:y", tags = { "forge:tools/pickaxes" } })
    local allowed = eq:isAllowedFor({ name = "x:y", tags = { "forge:tools/pickaxes" } })

    fs = oldFs

    assertEq(cls, "tool_pickaxe")
    assertEq(allowed, true)
  end
  },
  { "prefer_equivalent_default_e_override", function()
    local Equivalence = require("modules.equivalence")
    local oldFs = fs
    local json = textutils.serializeJSON({
      version = 2,
      rules = {
        { selector = "a:b", kind = "item", class = "armor_chestplate" },
        { selector = "c:d", kind = "item", class = "armor_chestplate", prefer_equivalent = true },
      },
      tier_overrides = {},
      gating = { by_building_type = {} }
    }, { pretty = true })

    fs = {
      exists = function(path) return path == "data/mappings.json" end,
      open = function(path, mode)
        if path ~= "data/mappings.json" or mode ~= "r" then return nil end
        return {
          readAll = function() return json end,
          close = function() end
        }
      end,
      isDir = function() return true end,
      makeDir = function() end,
      getDir = function() return "data" end,
      attributes = function() return { modified = 1 } end,
    }

    local eq = Equivalence.new({ logger = { warn = function() end, info = function() end } })

    local p1, h1 = eq:getPreferEquivalentFor({ name = "a:b" })
    assertEq(p1, false)
    assertEq(h1, true)

    local p2, h2 = eq:getPreferEquivalentFor({ name = "c:d" })
    assertEq(p2, true)
    assertEq(h2, true)

    local p3, h3 = eq:getPreferEquivalentFor({ name = "x:y" })

    fs = oldFs

    assertEq(p1, false)
    assertEq(h1, true)
    assertEq(p2, true)
    assertEq(h2, true)
    assertEq(p3, false)
    assertEq(h3, false)
  end
  },
  { "ui_status_two_col_format_normal_width", function()
    local UI = require("components.ui")
    local t = UI and UI._test or nil
    assertEq(type(t), "table")
    assertEq(type(t.formatTwoColLine), "function")

    local line, valueX, valueRendered = t.formatTwoColLine("Requisicoes: 12", "ME Bridge", "Online", 40)
    assertEq(#line, 40)
    assertEq(string.find(line, " | ", 1, true) ~= nil, true)
    assertEq(type(valueX), "number")
    assertEq(type(valueRendered), "string")
    assertEq(string.match(valueRendered, "^Online") ~= nil, true)
  end
  },
  { "ui_status_two_col_format_small_width_truncates", function()
    local UI = require("components.ui")
    local t = UI and UI._test or nil
    assertEq(type(t), "table")

    local line = t.formatTwoColLine("Substituicoes: 12345", "Mon Stat", "Offline", 16)
    assertEq(#line, 16)
    assertEq(string.find(line, " | ", 1, true) ~= nil, true)
    assertEq(string.find(line, "..", 1, true) ~= nil, true)
  end
  },
  { "ui_status_health_color_mapping", function()
    local UI = require("components.ui")
    local t = UI and UI._test or nil
    assertEq(t.healthValueColor("ok"), colors.lime)
    assertEq(t.healthValueColor("bad"), colors.red)
    assertEq(t.healthValueColor("unknown"), colors.gray)
  end
  },
  { "ui_status_health_fallback_na", function()
    local UI = require("components.ui")
    local t = UI and UI._test or nil
    local list = t.getPeripheralHealth({})
    assertEq(type(list), "table")
    assertEq(#list, 4)
    assertEq(list[1].label, "ME Bridge")
    assertEq(list[1].value, "NA")
    assertEq(list[1].level, "unknown")
    assertEq(list[3].label, "Buffer")
    assertEq(list[4].label, "Target")
  end
  },
  { "engine_health_snapshot_me_online_offline", function()
    local Engine = require("modules.engine")
    local t = Engine and Engine._test or nil
    assertEq(type(t), "table")

    local me = { isOnline = function() return true end }
    local cfg = makeCfg({
      delivery = {
        export_buffer_container = "chest_1",
        default_target_container = "rack_0",
      }
    })
    local state = {
      cfg = cfg,
      devices = {
        colonyIntegrator = {},
        colonyName = "colony_x",
      }
    }

    local oldPeripheral = peripheral
    peripheral = {
      getNames = function() return { "minecraft:chest_1", "minecolonies:rack_0" } end,
      isPresent = function(name)
        if name == "minecraft:chest_1" then return false end
        if name == "minecolonies:rack_0" then return false end
        return true
      end,
      wrap = function() return {} end,
    }

    local snap = t.buildPeripheralHealth(state, me)

    peripheral = oldPeripheral

    assertEq(type(snap), "table")
    assertEq(#snap, 4)
    assertEq(snap[1].label, "ME Bridge")
    assertEq(snap[1].value, "Online")
    assertEq(snap[1].level, "ok")
    assertEq(snap[2].label, "Colony")
    assertEq(snap[2].value, "Online")
    assertEq(snap[3].label, "Buffer")
    assertEq(snap[3].value, "Offline")
    assertEq(snap[3].level, "bad")
    assertEq(snap[4].label, "Target")
    assertEq(snap[4].value, "Offline")
    assertEq(snap[4].level, "bad")
  end
  },
}

for _, t in ipairs(tests) do
  total = total + 1
  if runTest(t[1], t[2]) then
    passed = passed + 1
  end
end

logLine(string.format("Tests: %d/%d OK", passed, total))
logLine("Relatorio: " .. reportPath)
if passed ~= total then
  if #failures > 0 then
    logLine("")
    logLine("Falhas:")
    for _, f in ipairs(failures) do
      logLine(f)
    end
  end
  if report then report.close() end
  error("Falha em testes. Veja: " .. reportPath)
end

if report then report.close() end
