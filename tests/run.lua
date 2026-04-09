local function assertEq(a, b, msg)
  if a ~= b then
    error((msg or "assertEq falhou") .. ": esperado=" .. tostring(b) .. " obtido=" .. tostring(a), 2)
  end
end

if type(package) == "table" and type(package.path) == "string" then
  package.path = "/?.lua;/?/init.lua;" .. package.path
end

local function runTest(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("[OK] " .. name)
    return true
  end
  print("[FAIL] " .. name .. " -> " .. tostring(err))
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
  { "equivalencias_basicas", function()
    local eq = require("modules.equivalence").new({ cache = { get = function() end, set = function() end } })
    local list = eq:getEquivalents("minecraft:iron_chestplate")
    assertEq(type(list), "table")
    assertEq(list[1], "minecraft:iron_chestplate")
  end
  },
  { "equivalencia_jetpack", function()
    local eq = require("modules.equivalence").new({ cache = { get = function() end, set = function() end } })
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
    assertEq(tier:isTierAllowed("TOOL_PICKAXE", "iron", "diamond"), true)
    assertEq(tier:isTierAllowed("TOOL_PICKAXE", "netherite", "diamond"), false)
    assertEq(tier:isTierAllowed("ARMOR_CHEST", "diamond", "iron"), false)
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
}

for _, t in ipairs(tests) do
  total = total + 1
  if runTest(t[1], t[2]) then
    passed = passed + 1
  end
end

print(string.format("Tests: %d/%d OK", passed, total))
if passed ~= total then
  error("Falha em testes.")
end
