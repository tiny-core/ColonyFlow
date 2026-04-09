local UI = {}
UI.__index = UI

function UI.new(state)
  return setmetatable({
    state = state,
    buffers = { requests = {}, status = {} },
    page = 1,
    lastAutoRotation = os.epoch("utc")
  }, UI)
end

function UI:drawText(deviceKey, mon, x, y, text, fg, bg)
  if not mon then return end
  fg = fg or colors.white
  bg = bg or colors.black

  self.buffers[deviceKey] = self.buffers[deviceKey] or {}
  local current = self.buffers[deviceKey][y]

  if current and current.text == text and current.fg == fg and current.bg == bg then
    return -- No change needed
  end

  self.buffers[deviceKey][y] = { text = text, fg = fg, bg = bg }

  local old = term.current()
  term.redirect(mon)
  term.setCursorPos(x, y)
  term.setTextColor(fg)
  term.setBackgroundColor(bg)
  term.write(text)

  -- Clear the rest of the line if the new text is shorter
  local w, _ = term.getSize()
  if #text < w then
    term.write(string.rep(" ", w - #text))
  end

  term.redirect(old)
end

local function shorten(s, maxLen)
  s = tostring(s or "")
  if #s <= maxLen then return s end
  if maxLen <= 1 then return s:sub(1, maxLen) end
  return s:sub(1, maxLen - 1) .. "…"
end

local function padRight(s, len)
  s = tostring(s or "")
  if #s >= len then return s end
  return s .. string.rep(" ", len - #s)
end

function UI:renderRequests(state, mon)
  if not mon then return end
  local w, h = mon.getSize()

  self:drawText("requests", mon, 1, 1, padRight("Requisicoes (MineColonies)", w))
  self:drawText("requests", mon, 1, 2, string.rep("-", math.max(0, w)))

  local header = string.format("%-8s %-6s %-14s %-14s %6s %-10s", "STATE", "ID", "REQ", "ESCOLH", "FALT", "JOB")
  self:drawText("requests", mon, 1, 3, shorten(header, w))
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

    local displayItem = reqItem
    local fg = colors.white
    if chosen ~= "" and chosen ~= reqItem then
      displayItem = shorten(reqItem, 10) .. "(S)"
      fg = colors.yellow
    end

    local line = string.format(
      "%-8s %-6s %-14s %-14s %6s %-10s",
      shorten(r.state, 8),
      shorten(r.id, 6),
      shorten(displayItem, 14),
      shorten(chosen, 14),
      shorten(missing, 6),
      shorten(jobState, 10)
    )
    self:drawText("requests", mon, 1, y, shorten(line, w), fg)
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
