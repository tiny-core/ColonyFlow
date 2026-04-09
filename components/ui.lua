local UI = {}
UI.__index = UI

local VERSION = "v1"

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
    statusView = "main",
    noCraftPage = 1,
    lastAutoRotation = os.epoch("utc")
  }, UI)
end

function UI:drawText(deviceKey, mon, x, y, text, fg, bg)
  if not mon then return end
  fg = fg or colors.white
  bg = bg or colors.black

  self.buffers[deviceKey] = self.buffers[deviceKey] or {}
  local key = tostring(y) .. ":" .. tostring(x)
  local w, _ = mon.getSize()
  local maxLen = math.max(0, w - x + 1)
  local rendered = shorten(text, maxLen)
  local current = self.buffers[deviceKey][key]

  if current and current.text == rendered and current.fg == fg and current.bg == bg then
    return -- No change needed
  end

  self.buffers[deviceKey][key] = { text = rendered, fg = fg, bg = bg, len = #rendered }

  local old = term.current()
  term.redirect(mon)
  term.setTextColor(fg)
  term.setBackgroundColor(bg)
  if x == 1 then
    term.setCursorPos(1, y)
    term.clearLine()
  elseif current and type(current.len) == "number" and current.len > #rendered then
    term.setCursorPos(x, y)
    term.write(string.rep(" ", math.min(current.len, maxLen)))
  end
  term.setCursorPos(x, y)
  term.write(rendered)

  term.redirect(old)
end

local function padRight(s, len)
  s = tostring(s or "")
  if #s >= len then return s end
  return s .. string.rep(" ", len - #s)
end

local function centerText(s, width)
  s = tostring(s or "")
  if width <= 0 then return "" end
  if #s >= width then return s:sub(1, width) end
  local left = math.floor((width - #s) / 2)
  local right = width - #s - left
  return string.rep(" ", left) .. s .. string.rep(" ", right)
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

local function formatDecimal2(v)
  local n = tonumber(v)
  if not n then return "-" end
  local s = string.format("%.2f", n)
  return (s:gsub("%.", ","))
end

local function happinessColor(v)
  local n = tonumber(v)
  if not n then return colors.white end
  if n >= 8 then return colors.lime end
  if n >= 6 then return colors.green end
  if n >= 4 then return colors.yellow end
  if n >= 2 then return colors.orange end
  return colors.red
end

local function boolLabel(v)
  return v and "SIM" or "NAO"
end

local function errCode(err)
  if type(err) ~= "string" then return nil end
  local code = err:match("^([^:]+):") or err
  return tostring(code):lower()
end

local function formatAlert(err, job)
  if err == nil then return nil end
  if type(err) ~= "string" then
    return "Erro interno"
  end

  local s = err
  local code, detail = s:match("^([^:]+):(.+)$")
  code = (code or s):lower()
  detail = detail or ""

  local item = nil
  if type(job) == "table" then
    item = job.chosen or job.requested or nil
  end
  local itemTxt = item and itemLabel(item) or nil

  if code == "nao_craftavel" then
    local msg = "Nao craftavel agora (sem padrao/receita no ME)"
    if itemTxt then msg = msg .. ": " .. itemTxt end
    return msg
  end
  if code == "me_offline" then
    return "ME offline"
  end
  if code == "destino_indisponivel" then
    return "Destino indisponivel"
  end
  if code == "destino_cheio_capacidade" then
    return "Destino cheio (sem espaco)"
  end
  if code == "erro_capacidade_destino" then
    return "Falha ao calcular espaco no destino"
  end
  if code == "destino_cheio_ou_export_falhou" then
    local msg = "Entrega falhou ou destino cheio"
    if itemTxt then msg = msg .. ": " .. itemTxt end
    return msg
  end
  if code == "craft_falhou" then
    local msg = "Falha ao iniciar craft"
    if itemTxt then msg = msg .. ": " .. itemTxt end
    return msg
  end
  if code == "blocked_by_tier" then
    local msg = "Bloqueado por tier"
    if itemTxt then msg = msg .. ": " .. itemTxt end
    return msg
  end
  if code == "unsupported" or code == "nao_suportado" then
    local msg = "Item nao suportado"
    if itemTxt then msg = msg .. ": " .. itemTxt end
    return msg
  end

  local msg = code:gsub("_", " ")
  if msg == "" then msg = "Alerta" end
  if itemTxt then msg = msg .. ": " .. itemTxt end
  if detail ~= "" and #detail <= 24 then
    msg = msg .. " (" .. detail:gsub("[%c]", "") .. ")"
  end
  return msg
end

function UI:collectNoCraftItems(state)
  local out = {}
  local seen = {}
  for _, r in ipairs(state.requests or {}) do
    local job = state.work and state.work[r.id] or nil
    if job and errCode(job.err) == "nao_craftavel" then
      local tag = tostring(job.chosen or job.requested or "")
      if tag ~= "" and not seen[tag] then
        seen[tag] = true
        table.insert(out, { tag = tag, name = itemLabel(tag) })
      end
    end
  end
  table.sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
  return out
end

function UI:renderNoCraft(state, mon)
  if not mon then return end
  local w, h = mon.getSize()
  local list = self:collectNoCraftItems(state)

  self:drawText("status", mon, 1, 1, padRight(centerText("ITENS SEM CRAFT", w), w))
  local right = os.date("!%H:%M:%SZ") .. " " .. VERSION
  self:drawText("status", mon, math.max(1, w - #right + 1), 1, right, colors.gray)
  self:drawText("status", mon, 1, 2, string.rep("-", math.max(0, w)))

  local sepW = 3
  local minName, minTag = 8, 12
  local maxName = 26
  local nameW = #"NOME"
  local tagW = #"TAG"

  local pageSize = math.max(1, h - 5)
  local pages = math.max(1, math.ceil(#list / pageSize))
  if self.noCraftPage > pages then self.noCraftPage = pages end
  if self.noCraftPage < 1 then self.noCraftPage = 1 end

  local startIdx = (self.noCraftPage - 1) * pageSize + 1
  local endIdx = math.min(#list, startIdx + pageSize - 1)

  for i = startIdx, endIdx do
    local it = list[i]
    if it then
      if #tostring(it.name or "") > nameW then nameW = #tostring(it.name or "") end
      if #tostring(it.tag or "") > tagW then tagW = #tostring(it.tag or "") end
    end
  end

  if nameW > maxName then nameW = maxName end
  if nameW < minName then nameW = minName end

  local available = w - sepW
  local desiredTag = tagW
  if desiredTag < minTag then desiredTag = minTag end
  local desiredName = nameW

  if desiredName + desiredTag > available then
    desiredTag = available - desiredName
  end
  if desiredTag < minTag then
    desiredTag = minTag
    desiredName = available - desiredTag
  end
  if desiredName < minName then
    desiredName = minName
    desiredTag = available - desiredName
  end
  if desiredTag < 1 then desiredTag = 1 end
  if desiredName < 1 then desiredName = 1 end

  nameW = desiredName
  tagW = desiredTag

  local header = string.format("%-" .. nameW .. "s | %-" .. tagW .. "s", "NOME", "TAG")
  self:drawText("status", mon, 1, 3, padRight(header, w))
  self:drawText("status", mon, 1, 4, string.rep("-", math.max(0, w)))

  local y = 5
  for i = startIdx, endIdx do
    local it = list[i]
    local line = string.format("%-" .. nameW .. "s | %-" .. tagW .. "s", shorten(it.name, nameW), shorten(it.tag, tagW))
    self:drawText("status", mon, 1, y, padRight(line, w))
    y = y + 1
  end
  for i = y, h - 1 do
    self:drawText("status", mon, 1, i, padRight("", w))
  end

  local left = "[VOLTAR]"
  local right = "PAG " .. tostring(self.noCraftPage) .. "/" .. tostring(pages) .. "  TOTAL " .. tostring(#list)
  local footer = padRight(left, w)
  footer = footer:sub(1, math.max(0, w - #right)) .. right
  self:drawText("status", mon, 1, h, padRight(footer, w), colors.lightGray, colors.black)
end

local function jobSymbol(jobState)
  local s = tostring(jobState or "")
  s = s:lower()
  if s == "" then return "--" end
  if s == "done" then return "CONCLUIDO" end
  if s:find("wait") or s:find("retry") or s:find("await") then return "AGUARDANDO" end
  if s:find("craft") then return "CRAFTANDO" end
  if s:find("pend") then return "PENDENTE" end
  if s:find("blocked_by_tier") or s:find("blocked") then return "BLOQUEADO TIER" end
  if s:find("unsupport") or s:find("nao_suport") then return "NAO SUPORTADO" end
  if s:find("err") or s:find("fail") then return "ERRO" end
  return shorten((s:gsub("_", " ")):upper(), 14)
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
  local right = os.date("!%H:%M:%SZ") .. " " .. VERSION
  self:drawText("requests", mon, math.max(1, w - #right + 1), 1, right, colors.gray)
  self:drawText("requests", mon, 1, 2, string.rep("-", math.max(0, w)))

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

  local faltW = 5
  local sepW = 3
  local seps = 3 * sepW
  local reqMin, choMin, jobMin = 12, 10, 5
  local choMax = #"ESCOLHIDO"
  local jobMax = #"ETAPA"

  for i = startIdx, endIdx do
    local r = state.requests[i]
    local job = state.work and state.work[r.id] or nil
    local reqItem = (r.items[1] and r.items[1].name) or ""
    local chosen = job and job.chosen or ""
    local jobState = job and job.status or ""

    local reqLabel = itemLabel(reqItem)
    local chosenLabel = itemLabel(chosen)
    local chosenDisplay = "-"
    if chosenLabel ~= "" and chosen ~= reqItem then
      chosenDisplay = chosenLabel
    end

    local etapa = jobSymbol(jobState)
    if #chosenDisplay > choMax then choMax = #chosenDisplay end
    if #etapa > jobMax then jobMax = #etapa end
  end

  if choMax > 24 then choMax = 24 end
  if jobMax > 14 then jobMax = 14 end

  local reqW = w - (choMax + jobMax + faltW + seps)
  if reqW < reqMin then
    local need = reqMin - reqW
    local takeCho = math.min(need, math.max(0, choMax - choMin))
    choMax = choMax - takeCho
    need = need - takeCho
    local takeJob = math.min(need, math.max(0, jobMax - jobMin))
    jobMax = jobMax - takeJob
    reqW = w - (choMax + jobMax + faltW + seps)
  end
  if reqW < 1 then reqW = 1 end
  if choMax < 1 then choMax = 1 end
  if jobMax < 1 then jobMax = 1 end

  local header = string.format(
    "%-" .. reqW .. "s | %-" .. choMax .. "s | %" .. faltW .. "s | %-" .. jobMax .. "s",
    "PEDIDO", centerText("ESCOLHIDO", choMax), "FALTA", centerText("ETAPA", jobMax)
  )
  self:drawText("requests", mon, 1, 3, header)
  self:drawText("requests", mon, 1, 4, string.rep("-", math.max(0, w)))

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
      "%-" .. reqW .. "s | %-" .. choMax .. "s | %" .. faltW .. "s | %-" .. jobMax .. "s",
      shorten(displayItem, reqW),
      centerText(shorten(chosenDisplay, choMax), choMax),
      shorten(missingLabel, faltW),
      centerText(shorten(jobSymbol(jobState), jobMax), jobMax)
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

  self:drawText("status", mon, 1, 1, padRight(centerText("STATUS", w), w))
  local right = os.date("!%H:%M:%SZ") .. " " .. VERSION
  self:drawText("status", mon, math.max(1, w - #right + 1), 1, right, colors.gray)
  self:drawText("status", mon, 1, 2, string.rep("-", math.max(0, w)))

  local y = 3
  local cs = state.colonyStats or {}
  self:drawText("status", mon, 1, y, centerText("COLONIA", w), colors.cyan); y = y + 1
  self:drawText("status", mon, 1, y, string.rep("-", math.max(0, w))); y = y + 1

  self:drawText("status", mon, 1, y, shorten("Colonia: " .. tostring(cs.name or "-"), w)); y = y + 1
  self:drawText("status", mon, 1, y,
    shorten("Cidadaos: " .. tostring(cs.citizens or "-") .. "/" .. tostring(cs.maxCitizens or "-"), w)); y = y + 1

  do
    local label = "Felicidade: "
    self:drawText("status", mon, 1, y, shorten(label, w))
    local hv = formatDecimal2(cs.happiness)
    self:drawText("status", mon, #label + 1, y, shorten(hv, math.max(0, w - #label)), happinessColor(cs.happiness))
    y = y + 1
  end

  do
    local label = "Ataque: "
    local under = cs.underAttack == true
    self:drawText("status", mon, 1, y, shorten(label, w))
    self:drawText("status", mon, #label + 1, y, boolLabel(under), under and colors.red or colors.lime)
    y = y + 1
  end

  self:drawText("status", mon, 1, y, shorten("Obras: " .. tostring(cs.constructionSites or "-"), w)); y = y + 2

  self:drawText("status", mon, 1, y, centerText("OPERACAO", w), colors.cyan); y = y + 1
  self:drawText("status", mon, 1, y, string.rep("-", math.max(0, w))); y = y + 1

  self:drawText("status", mon, 1, y, shorten("Requisicoes: " .. tostring(#state.requests), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Entregues: " .. tostring(state.stats.delivered), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Crafts: " .. tostring(state.stats.crafted), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Substituicoes: " .. tostring(state.stats.substitutions), w)); y = y + 1
  self:drawText("status", mon, 1, y, shorten("Erros: " .. tostring(state.stats.errors), w)); y = y + 2

  self:drawText("status", mon, 1, y, shorten("Estoque Critico: [heuristica]", w)); y = y + 1

  -- Clear remaining lines until bottom button
  for i = y, h - 1 do
    self:drawText("status", mon, 1, i, padRight("", w))
  end

  local noCraft = self:collectNoCraftItems(state)
  local btn = "SEM CRAFT: " .. tostring(#noCraft) .. "  (TOQUE)"
  local btnFg = (#noCraft > 0) and colors.red or colors.gray
  self:drawText("status", mon, 1, h, padRight(btn, w), btnFg, colors.black)
end

function UI:handleEvent(event, side, x, y)
  if event == "monitor_touch" then
    local reqMonName = nil
    if self.state.devices.monitorRequests then
      reqMonName = peripheral.getName(self.state.devices.monitorRequests)
    end
    local statusMonName = nil
    if self.state.devices.monitorStatus then
      statusMonName = peripheral.getName(self.state.devices.monitorStatus)
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
    if side == statusMonName then
      local w, h = self.state.devices.monitorStatus.getSize()
      if y == h then
        if self.statusView == "nocraft" then
          if x <= (#"[VOLTAR]" + 2) then
            self.statusView = "main"
          else
            if x < w / 2 then
              self.noCraftPage = (self.noCraftPage or 1) - 1
            else
              self.noCraftPage = (self.noCraftPage or 1) + 1
            end
          end
        else
          local list = self:collectNoCraftItems(self.state)
          if #list > 0 then
            self.statusView = "nocraft"
            self.noCraftPage = 1
          end
        end
        self:tick()
      end
    end
  end
end

function UI:tick()
  local state = self.state
  self:renderRequests(state, state.devices.monitorRequests)
  if self.statusView == "nocraft" then
    self:renderNoCraft(state, state.devices.monitorStatus)
  else
    self:renderStatus(state, state.devices.monitorStatus)
  end
end

return {
  new = UI.new,
}
