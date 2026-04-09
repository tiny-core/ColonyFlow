local c = peripheral.find("colonyIntegrator") or peripheral.find("colony_integrator")
local f = fs.open("logs/ap_dump.txt", "w")

local function wln(s)
  f.write(tostring(s or ""))
  f.write("\n")
end

local function safeSerialize(v)
  local ok, out = pcall(textutils.serialize, v, { compact = false, allow_repetitions = true })
  if ok then return out end
  return "<serialize_error: " .. tostring(out) .. ">"
end

local function tableLenPairs(t)
  local n = 0
  for _, _ in pairs(t or {}) do n = n + 1 end
  return n
end

local function shallowKeys(t, limit)
  local keys = {}
  for k, _ in pairs(t or {}) do
    table.insert(keys, tostring(k))
    if #keys >= (limit or 20) then break end
  end
  table.sort(keys)
  return table.concat(keys, ", ")
end

if not c then
  wln("no integrator")
  f.close()
  print("Saved to ap_dump.txt")
  return
end

do
  local methods = {}
  for k, _ in pairs(c) do table.insert(methods, k) end
  table.sort(methods)
  wln("Methods:")
  wln(safeSerialize(methods))
end

wln("")
wln("Requests (summary):")
do
  local ok, reqs = pcall(c.getRequests)
  if not ok then
    wln("getRequests ERROR: " .. tostring(reqs))
  elseif type(reqs) ~= "table" then
    wln("getRequests NON_TABLE: " .. tostring(reqs))
  else
    wln("count=" .. tostring(#reqs) .. " pairs=" .. tostring(tableLenPairs(reqs)))
    for i = 1, math.min(#reqs, 5) do
      local r = reqs[i]
      if type(r) == "table" then
        wln("  [" ..
          i ..
          "] id=" ..
          tostring(r.id) ..
          " state=" ..
          tostring(r.state) .. " target=" .. tostring(r.target) .. " count=" .. tostring(r.count or r.minCount))
        if type(r.items) == "table" and r.items[1] then
          local it = r.items[1]
          wln("       item1 keys=" .. shallowKeys(it, 30))
          wln("       item1.name=" .. tostring(it.name) .. " displayName=" .. tostring(it.displayName))
        else
          wln("       items=" .. tostring(type(r.items)))
        end
      else
        wln("  [" .. i .. "] " .. tostring(r))
      end
    end
  end
end

wln("")
wln("WorkOrders (summary):")
do
  local ok, wo = pcall(c.getWorkOrders)
  if not ok then
    wln("getWorkOrders ERROR: " .. tostring(wo))
  elseif type(wo) ~= "table" then
    wln("getWorkOrders NON_TABLE: " .. tostring(wo))
  else
    wln("count=" .. tostring(#wo) .. " pairs=" .. tostring(tableLenPairs(wo)))
    for i = 1, math.min(#wo, 3) do
      local w = wo[i]
      if type(w) == "table" then
        wln("  [" ..
          i ..
          "] id=" ..
          tostring(w.id) ..
          " buildingName=" ..
          tostring(w.buildingName) .. " type=" .. tostring(w.type) .. " workOrderType=" .. tostring(w.workOrderType))
        wln("       builder=" .. safeSerialize(w.builder))

        if type(c.getWorkOrderResources) == "function" then
          local okR, res = pcall(c.getWorkOrderResources, w.id)
          wln("       getWorkOrderResources ok=" .. tostring(okR) .. " type=" .. tostring(type(res)))
          if okR and type(res) == "table" then
            wln("       resources count=" .. tostring(#res) .. " pairs=" .. tostring(tableLenPairs(res)))
            local first = nil
            for _, v in pairs(res) do
              if type(v) == "table" then
                first = v; break
              end
            end
            if first then
              wln("       resource1 keys=" .. shallowKeys(first, 40))
              wln("       resource1.item=" .. safeSerialize(first.item))
              wln("       resource1.displayName=" .. tostring(first.displayName))
              wln("       resource1.needed=" ..
                tostring(first.needed) ..
                " available=" ..
                tostring(first.available) ..
                " delivering=" .. tostring(first.delivering) .. " status=" .. tostring(first.status))
            end
          else
            wln("       getWorkOrderResources res=" .. tostring(res))
          end
        end

        if type(c.getBuilderResources) == "function" then
          local okB, resB = pcall(c.getBuilderResources, w.builder)
          wln("       getBuilderResources ok=" .. tostring(okB) .. " type=" .. tostring(type(resB)))
          if okB and type(resB) == "table" then
            wln("       builderResources count=" .. tostring(#resB) .. " pairs=" .. tostring(tableLenPairs(resB)))
            local first = nil
            for _, v in pairs(resB) do
              if type(v) == "table" then
                first = v; break
              end
            end
            if first then
              wln("       bres1 keys=" .. shallowKeys(first, 40))
              wln("       bres1.item=" .. safeSerialize(first.item))
              wln("       bres1.displayName=" .. tostring(first.displayName))
              wln("       bres1.needed=" ..
                tostring(first.needed) ..
                " available=" ..
                tostring(first.available) ..
                " delivering=" .. tostring(first.delivering) .. " status=" .. tostring(first.status))
            end
          else
            wln("       getBuilderResources res=" .. tostring(resB))
          end
        end
      else
        wln("  [" .. i .. "] " .. tostring(w))
      end
    end
  end
end

f.close()
print("Saved to ap_dump.txt")
