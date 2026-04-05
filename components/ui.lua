local UI = {}
UI.__index = UI

local function withTerm(target, fn)
  if not target then return end
  local old = term.current()
  term.redirect(target)
  term.setCursorPos(1, 1)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  fn()
  term.redirect(old)
end

function UI.new(state)
  return setmetatable({ state = state }, UI)
end

local function shorten(s, maxLen)
  s = tostring(s or "")
  if #s <= maxLen then return s end
  if maxLen <= 1 then return s:sub(1, maxLen) end
  return s:sub(1, maxLen - 1) .. "…"
end

local function renderRequests(state, mon)
  withTerm(mon, function()
    local w, h = term.getSize()
    term.setCursorPos(1, 1)
    term.write("Requisições (MineColonies)")
    term.setCursorPos(1, 2)
    term.write(string.rep("-", math.max(0, w)))

    local header = string.format("%-8s %-6s %-14s %-14s %6s %-10s", "STATE", "ID", "REQ", "ESCOLH", "FALT", "JOB")
    term.setCursorPos(1, 3)
    term.write(shorten(header, w))
    term.setCursorPos(1, 4)
    term.write(string.rep("-", math.max(0, w)))

    local pageSize = math.max(1, h - 5)
    local total = #state.requests
    local pages = math.max(1, math.ceil(total / pageSize))
    local page = (math.floor(os.epoch("utc") / 10000) % pages) + 1
    local startIdx = (page - 1) * pageSize + 1
    local endIdx = math.min(total, startIdx + pageSize - 1)

    local y = 5
    for i = startIdx, endIdx do
      local r = state.requests[i]
      local job = state.work and state.work[r.id] or nil
      local reqItem = (r.items[1] and r.items[1].name) or ""
      local chosen = job and job.chosen or ""
      local missing = job and job.missing or ""
      local jobState = job and job.status or ""

      term.setCursorPos(1, y)
      local line = string.format(
        "%-8s %-6s %-14s %-14s %6s %-10s",
        shorten(r.state, 8),
        shorten(r.id, 6),
        shorten(reqItem, 14),
        shorten(chosen, 14),
        shorten(missing, 6),
        shorten(jobState, 10)
      )
      term.write(shorten(line, w))
      y = y + 1
      if y > h then break end
    end

    term.setCursorPos(1, h)
    term.write(shorten(string.format("Página %d/%d | Total %d", page, pages, total), w))
  end)
end

local function renderStatus(state, mon)
  withTerm(mon, function()
    local w, _ = term.getSize()
    term.setCursorPos(1, 1)
    term.write("Status")
    term.setCursorPos(1, 2)
    term.write(string.rep("-", math.max(0, w)))
    term.setCursorPos(1, 3)
    term.write("Processados: " .. tostring(state.stats.processed))
    term.setCursorPos(1, 4)
    term.write("Erros: " .. tostring(state.stats.errors))
    term.setCursorPos(1, 5)
    term.write("Reqs: " .. tostring(#state.requests))
    term.setCursorPos(1, 6)
    term.write("Entregues: " .. tostring(state.stats.delivered))
    term.setCursorPos(1, 7)
    term.write("Craft: " .. tostring(state.stats.crafted))
    term.setCursorPos(1, 8)
    term.write("Subst: " .. tostring(state.stats.substitutions))
  end)
end

function UI:tick()
  local state = self.state
  renderRequests(state, state.devices.monitorRequests)
  renderStatus(state, state.devices.monitorStatus)
end

return {
  new = UI.new,
}
