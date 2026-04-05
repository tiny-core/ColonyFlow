local function assertEq(a, b, msg)
  if a ~= b then
    error((msg or "assertEq falhou") .. ": esperado=" .. tostring(b) .. " obtido=" .. tostring(a), 2)
  end
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
