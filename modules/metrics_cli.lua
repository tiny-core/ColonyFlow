local Util = require("lib.util")

local METRICS_PATH = "data/metrics.json"

local function round0(v)
  return math.floor((tonumber(v or 0) or 0) + 0.5)
end

local function fmtMs(ms)
  local n = tonumber(ms or 0) or 0
  if n == 0 then return "0ms" end
  return tostring(round0(n)) .. "ms"
end

local function fmtTime(ms)
  if not ms or ms == 0 then return "---" end
  local s = math.floor(ms / 1000)
  local m = math.floor(s / 60)
  local h = math.floor(m / 60)
  s = s % 60; m = m % 60
  return string.format("%dh %02dm %02ds", h, m, s)
end

local function printSection(title)
  print("")
  print("[" .. title .. "]")
end

local function main()
  if not fs.exists(METRICS_PATH) then
    print("Nenhuma metrica disponivel.")
    print("Execute o loop com observability.enabled=true primeiro.")
    return
  end

  local txt = Util.readFile(METRICS_PATH)
  if not txt then
    print("Erro ao ler " .. METRICS_PATH)
    return
  end
  local ok, data = pcall(Util.jsonDecode, txt)
  if not ok or type(data) ~= "table" then
    print("Arquivo de metricas invalido ou corrompido.")
    return
  end

  local m = type(data.metrics) == "table" and data.metrics or {}
  local nowMs = Util.nowUtcMs()
  local flushedAt = tonumber(data.flushed_at_ms or 0) or 0
  local startedAt = tonumber(data.started_at_ms or 0) or 0

  print("=== Metricas ColonyFlow ===")
  if flushedAt > 0 then
    local agoSec = math.floor((nowMs - flushedAt) / 1000)
    print("Salvo: " .. tostring(agoSec) .. "s atras")
  end
  if startedAt > 0 then
    print("Sessao ativa por: " .. fmtTime(nowMs - startedAt))
  end

  local timing = type(m.timing) == "table" and m.timing or {}
  printSection("Timing")
  print("  Engine ultimo: " .. fmtMs(timing.engine_tick_ms_last))
  print("  Engine media:  " .. fmtMs(timing.engine_tick_ms_avg))
  print("  Engine max:    " .. fmtMs(timing.engine_tick_ms_max))
  print("  UI ultimo:     " .. fmtMs(timing.ui_tick_ms_last))
  print("  UI media:      " .. fmtMs(timing.ui_tick_ms_avg))
  print("  UI max:        " .. fmtMs(timing.ui_tick_ms_max))

  local io = type(m.io) == "table" and m.io or {}
  local meTotal  = tonumber(type(io.me)  == "table" and io.me.total  or 0) or 0
  local mcTotal  = tonumber(type(io.mc)  == "table" and io.mc.total  or 0) or 0
  local invTotal = tonumber(type(io.inv) == "table" and io.inv.total or 0) or 0
  printSection("Chamadas I/O")
  print("  ME:  " .. tostring(meTotal))
  print("  MC:  " .. tostring(mcTotal))
  print("  INV: " .. tostring(invTotal))

  local cache = type(m.cache) == "table" and m.cache or {}
  local hits   = tonumber(cache.hit_total  or 0) or 0
  local misses = tonumber(cache.miss_total or 0) or 0
  local total  = hits + misses
  local hitPct = total > 0 and math.floor(hits * 100 / total) or 0
  printSection("Cache")
  print("  Hits:   " .. tostring(hits))
  print("  Misses: " .. tostring(misses))
  print("  Taxa:   " .. tostring(hitPct) .. "%")
end

main()
