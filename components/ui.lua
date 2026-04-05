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

local function renderRequests(state, mon)
  withTerm(mon, function()
    local w, h = term.getSize()
    term.setCursorPos(1, 1)
    term.write("Requisições (MineColonies)")
    term.setCursorPos(1, 2)
    term.write(string.rep("-", math.max(0, w)))

    local y = 3
    for i = 1, math.min(#state.requests, h - 2) do
      local r = state.requests[i]
      term.setCursorPos(1, y)
      local line = string.format("%s | %s | %s", tostring(r.state), tostring(r.id), tostring(r.target))
      term.write(line:sub(1, w))
      y = y + 1
      if y > h then break end
    end
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
