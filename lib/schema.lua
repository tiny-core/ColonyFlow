local M = {}

local VALID_CLASSES = {
  armor_helmet = true, armor_chestplate = true, armor_leggings = true, armor_boots = true,
  tool_pickaxe = true, tool_shovel = true, tool_axe = true, tool_hoe = true,
  tool_sword = true, tool_bow = true, tool_shield = true,
}

local VALID_KINDS = { item = true, tag = true }

local function addErr(errors, msg)
  table.insert(errors, tostring(msg or "erro"))
end

function M.validateMappings(db)
  local errors = {}
  if type(db) ~= "table" then
    addErr(errors, "mappings: deve ser tabela")
    return { ok = false, errors = errors }
  end

  if db.version ~= 2 then
    addErr(errors, "mappings.version: esperado 2, obtido " .. tostring(db.version))
  end

  if type(db.rules) ~= "table" then
    addErr(errors, "mappings.rules: deve ser array")
  else
    for i, r in ipairs(db.rules) do
      local pfx = "mappings.rules[" .. i .. "]"
      if type(r) ~= "table" then
        addErr(errors, pfx .. ": deve ser tabela")
      else
        if type(r.selector) ~= "string" or r.selector == "" then
          addErr(errors, pfx .. ".selector: obrigatorio, string nao vazia")
        end
        if r.kind ~= nil and not VALID_KINDS[r.kind] then
          addErr(errors, pfx .. ".kind: valor invalido (" .. tostring(r.kind) .. ")")
        end
        if r.class ~= nil and not VALID_CLASSES[r.class] then
          addErr(errors, pfx .. ".class: valor invalido (" .. tostring(r.class) .. ")")
        end
        if r.prefer_equivalent ~= nil and type(r.prefer_equivalent) ~= "boolean" then
          addErr(errors, pfx .. ".prefer_equivalent: deve ser boolean")
        end
      end
    end
  end

  if type(db.tier_overrides) ~= "table" then
    addErr(errors, "mappings.tier_overrides: deve ser tabela")
  else
    for k, v in pairs(db.tier_overrides) do
      if tonumber(v) == nil then
        addErr(errors, "mappings.tier_overrides[" .. tostring(k) .. "]: deve ser numero")
      end
    end
  end

  if type(db.gating) ~= "table" then
    addErr(errors, "mappings.gating: deve ser tabela")
  else
    if type(db.gating.by_building_type) ~= "table" then
      addErr(errors, "mappings.gating.by_building_type: deve ser tabela")
    else
      for btype, classTiers in pairs(db.gating.by_building_type) do
        if type(classTiers) ~= "table" then
          addErr(errors, "mappings.gating.by_building_type[" .. tostring(btype) .. "]: deve ser tabela")
        else
          for className, maxTier in pairs(classTiers) do
            if tonumber(maxTier) == nil then
              addErr(errors, "mappings.gating.by_building_type[" .. tostring(btype) .. "][" .. tostring(className) .. "]: deve ser numero")
            end
          end
        end
      end
    end
  end

  return { ok = #errors == 0, errors = errors }
end

return M
