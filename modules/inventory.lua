local Util = require("lib.util")

local M = {}

local function safeList(inv)
  if not inv then return nil, "inventário ausente" end
  if type(inv.list) ~= "function" then return nil, "inventário sem list()" end
  local ok, res = Util.safeCall(inv.list)
  if not ok then return nil, tostring(res) end
  return res, nil
end

function M.countItem(inv, itemName)
  local list, err = safeList(inv)
  if not list then return nil, err end
  local total = 0
  for _, stack in pairs(list) do
    if stack and stack.name == itemName then
      total = total + (stack.count or 0)
    end
  end
  return total, nil
end

function M.countAny(inv, names)
  local list, err = safeList(inv)
  if not list then return nil, err end
  local set = {}
  for _, n in ipairs(names or {}) do set[n] = true end
  local total = 0
  for _, stack in pairs(list) do
    if stack and stack.name and set[stack.name] then
      total = total + (stack.count or 0)
    end
  end
  return total, nil
end

return M
