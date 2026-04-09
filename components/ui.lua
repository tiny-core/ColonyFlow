local UI = {}
UI.__index = UI

local function shorten(s, maxLen)
  s = tostring(s or "")
  if #s <= maxLen then return s end
  if maxLen <= 2 then return s:sub(1, maxLen) end
  return s:sub(1, maxLen - 2) .. ".."
end

function UI.new(state)
  return setmetatable({
    state = state,
    buffers = { requests = {}, status = {} },
    sizes = { requests = nil, status = nil },
    page = 1,
    lastAutoRotation = os.epoch("utc")
  }, UI)
end

function UI:drawText(deviceKey, mon, x, y, text, fg, bg)
  if not mon then return end
  fg = fg or colors.white
  bg = bg or colors.black

  self.buffers[deviceKey] = self.buffers[deviceKey] or {}
  local key = tostring(y) .. ":" .. tostring(x)
  local current = self.buffers[deviceKey][key]

  if current and current.text == text and current.fg == fg and current.bg == bg then
    return -- No change needed
  end

  self.buffers[deviceKey][key] = { text = text, fg = fg, bg = bg }

  local old = term.current()
  term.redirect(mon)
  term.setTextColor(fg)
  term.setBackgroundColor(bg)
  term.setCursorPos(1, y)
  term.clearLine()
  term.setCursorPos(x, y)
  local w, _ = term.getSize()
  local maxLen = math.max(0, w - x + 1)
  term.write(shorten(text, maxLen))

  term.redirect(old)
end

local function padRight(s, len)
  s = tostring(s or "")
  if #s >= len then return s end
  return s .. string.rep(" ", len - #s)
end

local function itemLabel(name)
  local s = tostring(name or "")
  local mod, item = s:match("^([^:]+):(.+)$")
  if mod and item then
    s = item
  end
  s = s:gsub("_", " ")
  s = s:gsub("%s+", " ")
  return s
end

local function stateSymbol(state)
  local s = tostring(state or "")
  s = s:lower()
  if s:find("in_prog") or s:find("progress") or s:find("running") then return "A" end
  if s:find("done") or s:find("complete") or s:find("deliv") then return "OK" end
  if s:find("error") or s:find("fail") then return "ER" end
  if s:find("req") or s:find("request") then return "P" end
  if s == "" then return "--" end
  return shorten(s, 2)
end

local function jobSymbol(jobState)
  local s = tostring(jobState or "")
  s = s:lower()
  if s == "" then return "--" end
  if s == "done" then return "OK" end
  if s:find("wait") or s:find("await") then return "AG" end
  if s:find("craft") then return "CR" end
  if s:find("pend") then return "PD" end
  if s:find("err") or s:find("fail") then return "ER" end
  return shorten(s, 2)
end

local function computeColumns(w)
  local stateW = 3
  local faltW = 5
  local sepW = 3
  local seps = 4 * sepW

  local remaining = w - (stateW + faltW + seps)
  if remaining < 0 then remaining = 0 end

  local minReq, minCho, minJob = 12, 12, 5
  local reqW = math.max(minReq, math.floor(remaining * 0.45))
  local choW = math.max(minCho, math.floor(remaining * 0.35))
  local jobW = remaining - reqW - choW

  if jobW < minJob then
    local deficit = minJob - jobW
    jobW = minJob
    local takeReq = math.min(deficit, math.max(0, reqW - minReq))
    reqW = reqW - takeReq
    deficit = deficit - takeReq
    local takeCho = math.min(deficit, math.max(0, choW - minCho))
    choW = choW - takeCho
  end

  return stateW, reqW, choW, faltW, jobW
end

function UI:renderRequests(state, mon)
  if not mon then return end
  local w, h = mon.getSize()

  local sizeKey = tostring(w) .. "x" .. tostring(h)
  if self.sizes.requests ~= sizeKey then
    self.sizes.requests = sizeKey
    self.buffers.requests = {}
    local old = term.current()
    term.redirect(mon)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.redirect(old)
  end

  self:drawText("requests", mon, 1, 1, padRight("Requisicoes (MineColonies)", w))
  self:drawText("requests", mon, 1, 2, string.rep("-", math.max(0, w)))

  local stateW, reqW, choW, faltW, jobW = computeColumns(w)
  local header = string.format(
    "%-" .. stateW .. "s | %-" .. reqW .. "s | %-" .. choW .. "s | %" .. faltW .. "s | %-" .. jobW .. "s",
    "SIT", "PEDIDO", "ESCOLHIDO", "FALTA", "ETAPA"
  )
  self:drawText("requests", mon, 1, 3, header)
  self:drawText("requests", mon, 1, 4, string.rep("-", math.max(0, w)))

  local pageSize = math.max(1, h - 5)
  local total = #state.requests
  local pages = math.max(1, math.ceil(total / pageSize))

  local now = os.epoch("utc")
  if now - self.lastAutoRotation > 10000 then
    self.page = self.page + 1
    self.lastAutoRotation = now
  end

  if self.page > pages then self.page = 1 end
  if self.page < 1 then self.page = pages end

  local startIdx = (self.page - 1) * pageSize + 1
  local endIdx = math.min(total, startIdx + pageSize - 1)

  local y = 5
  for i = startIdx, endIdx do
    local r = state.requests[i]
    local job = state.work and state.work[r.id] or nil
    local reqItem = (r.items[1] and r.items[1].name) or ""
    local chosen = job and job.chosen or ""
    local missing = job and job.missing or ""
    local jobState = job and job.status or ""

    local reqLabel = itemLabel(reqItem)
    local chosenLabel = itemLabel(chosen)
    local displayItem = reqLabel
    local fg = colors.white
    if chosen ~= "" and chosen ~= reqItem then
      displayItem = shorten(reqLabel, math.max(1, reqW - 3)) .. "(S)"
      fg = colors.yellow
    end

    local missingLabel = tostring(missing or "")
    if missingLabel == "" then missingLabel = "-" end
    local chosenDisplay = "-"
    if chosenLabel ~= "" and chosen ~= reqItem then
      chosenDisplay = chosenLabel
    end

    local doneState = false
    do
      local st = tostring(r.state or ""):lower()
      if st:find("done") or st:find("complete") or st:find("fulfill") or st:find("success") then
        doneState = true
      end
      if tostring(jobState or ""):lower() == "done" then
        doneState = true
      end
    end
    if doneState then
      fg = colors.green
    end

    local line = string.format(
      "%-" .. stateW .. "s | %-" .. reqW .. "s | %-" .. choW .. "s | %" .. faltW .. "s | %-" .. jobW .. "s",
      stateSymbol(r.state),
      shorten(displayItem, reqW),
      shorten(chosenDisplay, choW),
      shorten(missingLabel, faltW),
      jobSymbol(jobState)
    )
    self:drawText("requests", mon, 1, y, line, fg)
    y = y + 1
    if y > h then break end
  end

  -- Clear remaining lines in buffer if any
  for i = y, h - 1 do
    self:drawText("requests", mon, 1, i, padRight("", w))
  end

  self:drawText("requests", mon, 1, h, shorten(string.format("Pagina %d/%d | Total %d", self.page, pages, total), w))
end

function UI:renderStatus(state, mon)
  if not mon then return end
  local w, h = mon.getSize()

  local sizeKey = tostring(w) .. "x" .. tostring(h)
  if self.sizes.status ~= sizeKey then
    self.sizes.status = sizeKey
    self.buffers.status = {}
    local old = term.current()
    term.redirect(mon)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.redirect(old)
  end

  self:drawText("status", mon, 1, 1, padRight("Status", w))
  self:drawText("status", mon, 1, 2, string.rep("-", math.max(0, w)))

  local y = 3
  local cs = state.colonyStats or {}
  self:drawText("status", mon, 1, y, shorten("Colonia: " .. tostring(cs.name or "-"), w)); y = y + 1
  self:drawText("status", mon, 1, y,
    shorten("Cidadaos: " .. tostring(cs.citizens or "-") .. "/" .. tostring(cs.maxCitizens or "-"), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Felicidade: " .. tostring(cs.happiness or "-"), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Ataque: " .. tostring(cs.underAttack or false), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Obras: " .. tostring(cs.constructionSites or "-"), w)); y = y + 2

  self:drawText("status", mon, 1, y, shorten("Reqs: " .. tostring(#state.requests), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Ciclos: " .. tostring(state.stats.processed), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Entregues: " .. tostring(state.stats.delivered), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Craft req.: " .. tostring(state.stats.crafted), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Subst: " .. tostring(state.stats.substitutions), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Erros: " .. tostring(state.stats.errors), w)); y = y + 2

  self:drawText("status", mon, 1, y, shorten("Estoque Critico: [heuristica]", w)); y = y + 1

  -- Clear remaining lines until bottom banner
  for i = y, h - 2 do
    self:drawText("status", mon, 1, i, padRight("", w))
  end

  -- Active alerts (from job.err)
  local activeError = nil
  for _, r in ipairs(state.requests) do
    local job = state.work and state.work[r.id]
    if job and job.err then
      activeError = job.err
      break
    end
  end

  if activeError then
    self:drawText("status", mon, 1, h - 1, padRight("! " .. shorten(activeError, w - 2), w), colors.white, colors.red)
  else
    self:drawText("status", mon, 1, h - 1, padRight("", w), colors.white, colors.black)
  end

  self:drawText("status", mon, 1, h, shorten("v1 | " .. os.date("!%H:%M:%SZ"), w), colors.white, colors.black)
end

function UI:handleEvent(event, side, x, y)
  if event == "monitor_touch" then
    local reqMonName = nil
    if self.state.devices.monitorRequests then
      reqMonName = peripheral.getName(self.state.devices.monitorRequests)
    end
    if side == reqMonName then
      local w, _ = self.state.devices.monitorRequests.getSize()
      if x < w / 2 then
        self.page = self.page - 1
      else
        self.page = self.page + 1
      end
      self.lastAutoRotation = os.epoch("utc") + 5000 -- delay auto rotation after touch
      self:tick()                                    -- immediate visual update
    end
  end
end

function UI:tick()
  local state = self.state
  self:renderRequests(state, state.devices.monitorRequests)
  self:renderStatus(state, state.devices.monitorStatus)
end

return {
  new = UI.new,
}
