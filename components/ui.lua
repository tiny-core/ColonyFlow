-- UI ASCII (2 monitores).
-- Renderiza a operação em tempo real consumindo o snapshot publicado pelo engine.
-- Invariantes:
-- - UI não deve fazer IO de periféricos; apenas ler `state.snapshot` (ou fallback) e renderizar
-- - Saída deve ser sanitizada para ASCII (ver cleanAscii) para evitar caracteres inválidos no monitor
-- - Render deve minimizar flicker (buffers + diff por linha)

local UI = {}
UI.__index = UI

local UpdateCheck = require("modules.update_check")

local function shorten(s, maxLen)
  s = tostring(s or "")
  if #s <= maxLen then return s end
  if maxLen <= 2 then return s:sub(1, maxLen) end
  return s:sub(1, maxLen - 2) .. ".."
end

local function cleanAscii(s)
  s = tostring(s or "")
  s = s:gsub("[%c]", "")
  s = s:gsub("[^\x20-\x7E]", "?")
  return s
end

local function formatTs(ms)
  local n = tonumber(ms)
  if not n then return "-" end
  local sec = math.floor(n / 1000)
  if sec <= 0 then return "-" end
  return os.date("!%Y-%m-%d %H:%M:%SZ", sec)
end

function UI.new(state)
  return setmetatable({
    state = state,
    buffers = { requests = {}, status = {} },
    sizes = { requests = nil, status = nil },
    page = 1,
    statusView = "main",
    _lastStatusView = "main",
    statusPage = 1,
    _statusPages = 1,
    noCraftPage = 1,
    lastAutoRotation = os.epoch("utc")
  }, UI)
end

local function clearMonitor(mon)
  if not mon then return end
  local old = term.current()
  term.redirect(mon)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.redirect(old)
end

function UI:drawText(deviceKey, mon, x, y, text, fg, bg, force)
  if not mon then return end
  fg = fg or colors.white
  bg = bg or colors.black

  self.buffers[deviceKey] = self.buffers[deviceKey] or {}
  local key = tostring(y) .. ":" .. tostring(x)
  local w, _ = mon.getSize()
  local maxLen = math.max(0, w - x + 1)
  local rendered = shorten(text, maxLen)
  local current = self.buffers[deviceKey][key]

  if force ~= true and current and current.text == rendered and current.fg == fg and current.bg == bg then
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

local function healthValueColor(level)
  if level == "ok" then return colors.lime end
  if level == "bad" then return colors.red end
  return colors.gray
end

local function defaultPeripheralHealth()
  return {
    { label = "ME Bridge", value = "NA", level = "unknown" },
    { label = "Colony",    value = "NA", level = "unknown" },
    { label = "Buffer",    value = "NA", level = "unknown" },
    { label = "Targets",   value = "NA", level = "unknown" },
  }
end

local function getPeripheralHealth(state)
  local list = (type(state) == "table" and type(state.health) == "table") and state.health.peripherals or nil
  local fallback = defaultPeripheralHealth()
  if type(list) ~= "table" then
    return fallback
  end

  local byLabel = {}
  for _, it in pairs(list) do
    if type(it) == "table" then
      local lbl = tostring(it.label or "")
      if lbl ~= "" then
        byLabel[lbl] = it
      end
    end
  end

  local out = {}
  for i = 1, #fallback do
    local base = fallback[i]
    local src = byLabel[base.label]
    if src then
      out[i] = {
        label = base.label,
        value = tostring(src.value or base.value),
        level = tostring(src.level or base.level),
      }
    else
      out[i] = base
    end
  end
  return out
end

local function formatTwoColLine(leftText, rightLabel, rightValue, w)
  local sep = " | "
  local available = math.max(0, (tonumber(w) or 0) - #sep)
  local leftW = math.floor(available / 2)
  local rightW = available - leftW
  if leftW < 1 then leftW = 1 end
  if rightW < 1 then rightW = 1 end

  leftText = tostring(leftText or "")
  rightLabel = tostring(rightLabel or "")
  rightValue = tostring(rightValue or "")

  local rightPrefix = (rightLabel ~= "") and (rightLabel .. ": ") or ""
  local fullRight = rightPrefix .. rightValue

  local leftRendered = padRight(shorten(leftText, leftW), leftW)
  local fullRightShort = shorten(fullRight, rightW)
  local rightRendered = padRight(fullRightShort, rightW)
  local line = leftRendered .. sep .. rightRendered

  local valueStartInRight = #rightPrefix + 1
  local rightColStart = leftW + #sep + 1
  local valueX = rightColStart + valueStartInRight - 1
  local valueRendered = ""
  if valueStartInRight <= #fullRightShort then
    valueRendered = fullRightShort:sub(valueStartInRight)
  end

  return line, valueX, valueRendered, leftW, rightW
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
    local job = state.work and state.work[tostring(r.id)] or nil
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
  local right = UpdateCheck.formatHeaderRight(state, w)
  self:drawText("status", mon, math.max(1, w - #right + 1), 1, right, colors.gray)
  self:drawText("status", mon, 1, 2, string.rep("-", math.max(0, w)))

  local sepW = 3
  local minName, minTag = 8, 12
  local maxName = 26
  local nameW = #"NOME"
  local tagW = #"TAG"

  local pageSize = math.max(1, h - 6)
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
    local bg = (((y - 5) % 2) == 0) and colors.black or colors.gray
    self:drawText("status", mon, 1, y, padRight(line, w), colors.white, bg)
    y = y + 1
  end
  for i = y, h - 2 do
    self:drawText("status", mon, 1, i, padRight("", w))
  end

  self:drawText("status", mon, 1, h - 1, string.rep("-", math.max(0, w)), colors.gray, colors.black)

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
  if s == "done" then return "OK" end
  if s:find("wait") or s:find("retry") or s:find("await") then return "AG" end
  if s:find("craft") then return "CR" end
  if s:find("pend") then return "PD" end
  if s:find("blocked_by_tier") or s:find("blocked") then return "BT" end
  if s:find("unsupport") or s:find("nao_suport") then return "NS" end
  if s:find("err") or s:find("fail") then return "ER" end
  return shorten(s, 2)
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

  self:drawText("requests", mon, 1, 1, padRight("Requisicoes (ColonyFlow)", w))
  local right = UpdateCheck.formatHeaderRight(state, w)
  self:drawText("requests", mon, math.max(1, w - #right + 1), 1, right, colors.gray)
  self:drawText("requests", mon, 1, 2, string.rep("-", math.max(0, w)))

  local pageSize = math.max(1, h - 6)
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
    local job = state.work and state.work[tostring(r.id)] or nil
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
  if jobMax > 10 then jobMax = 10 end

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
    local job = state.work and state.work[tostring(r.id)] or nil
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

    local bg = (((y - 5) % 2) == 0) and colors.black or colors.gray
    if bg == colors.gray and fg == colors.gray then
      fg = colors.white
    end
    local line = string.format(
      "%-" .. reqW .. "s | %-" .. choMax .. "s | %" .. faltW .. "s | %-" .. jobMax .. "s",
      shorten(displayItem, reqW),
      centerText(shorten(chosenDisplay, choMax), choMax),
      shorten(missingLabel, faltW),
      centerText(shorten(jobSymbol(jobState), jobMax), jobMax)
    )
    self:drawText("requests", mon, 1, y, line, fg, bg)
    y = y + 1
    if y > h then break end
  end

  -- Clear remaining lines in buffer if any
  for i = y, h - 2 do
    self:drawText("requests", mon, 1, i, padRight("", w))
  end

  self:drawText("requests", mon, 1, h - 1, string.rep("-", math.max(0, w)), colors.gray, colors.black)
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
  local right = UpdateCheck.formatHeaderRight(state, w)
  self:drawText("status", mon, math.max(1, w - #right + 1), 1, right, colors.gray)
  self:drawText("status", mon, 1, 2, string.rep("-", math.max(0, w)))

  local compact = (tonumber(h) or 0) < 20
  local pages = 1
  if compact then
    pages = 2
  end
  self._statusPages = pages
  if not self.statusPage or self.statusPage < 1 then self.statusPage = 1 end
  if self.statusPage > pages then self.statusPage = pages end

  local y = 3
  if self.statusPage == 1 then
    if UpdateCheck.isUpdateAvailable(state) then
      local upd = type(state.update) == "table" and state.update or {}
      local inst = tostring(upd.installed_version or "NO-VERSION")
      local avail = tostring(upd.available_version or "?")
      local staleMark = upd.stale == true and "*" or ""
      local line = "UPDATE: " .. inst .. "->" .. avail .. staleMark .. "  Run: tools/install.lua update"
      self:drawText("status", mon, 1, y, padRight(shorten(line, w), w), colors.yellow, colors.black)
      y = y + 1
    elseif not (type(state.installed) == "table" and type(state.installed.version) == "string") then
      local upd = type(state.update) == "table" and state.update or {}
      local avail = (type(upd.available_version) == "string") and upd.available_version or nil
      local line = "NO VERSION  Run: tools/install.lua install"
      if avail then
        line = "NO VERSION  Avail: " .. avail .. "  Run: tools/install.lua install"
      end
      self:drawText("status", mon, 1, y, padRight(shorten(line, w), w), colors.lightGray, colors.black)
      y = y + 1
    end
  end

  local throttle = type(state.throttle) == "table" and state.throttle or nil
  if throttle and throttle.active == true and y <= h - 2 then
    local reason = cleanAscii(throttle.reason or throttle.group or "unknown")
    local line = "THROTTLED: " .. reason
    self:drawText("status", mon, 1, y, padRight(shorten(line, w), w), colors.orange, colors.black)
    y = y + 1
  end

  local cs = state.colonyStats or {}
  local m = state.metrics
  local perfEnabled = type(m) == "table" and m.enabled == true and m.ui_enabled == true

  local colonyRowsBase = {
    { label = "Colonia",    value = tostring(cs.name or "-"),                                               color = colors.white },
    { label = "Cidadaos",   value = tostring(cs.citizens or "-") .. "/" .. tostring(cs.maxCitizens or "-"), color = colors.white },
    { label = "Felicidade", value = formatDecimal2(cs.happiness),                                           color = happinessColor(cs.happiness) },
    { label = "Obras",      value = tostring(cs.constructionSites or "-"),                                  color = colors.white },
  }

  local health = getPeripheralHealth(state)
  local healthByLabel = {}
  for _, it in ipairs(health or {}) do
    if type(it) == "table" then
      local lbl = tostring(it.label or "")
      if lbl ~= "" then
        healthByLabel[lbl] = {
          label = lbl,
          value = tostring(it.value or "NA"),
          level = tostring(it.level or "unknown"),
        }
      end
    end
  end
  local healthRows = {
    healthByLabel["ME Bridge"] or { label = "ME Bridge", value = "NA", level = "unknown" },
    healthByLabel["Colony"] or { label = "Colony", value = "NA", level = "unknown" },
    healthByLabel["Buffer"] or { label = "Buffer", value = "NA", level = "unknown" },
    healthByLabel["Target"] or { label = "Target", value = "NA", level = "unknown" },
  }

  if self.statusPage == 1 or pages == 1 then
    self:drawText("status", mon, 1, y, centerText("COLONIA", w), colors.cyan)
    local perHdr = "PERIF"
    self:drawText("status", mon, math.max(1, w - #perHdr + 1), y, perHdr, colors.gray, colors.black, true)
    y = y + 1
    self:drawText("status", mon, 1, y, string.rep("-", math.max(0, w))); y = y + 1

    local leftLabelW = 0
    for _, it in ipairs(colonyRowsBase) do
      local lbl = tostring(it.label or "")
      if #lbl > leftLabelW then leftLabelW = #lbl end
    end
    local rightLabelW = 0
    for _, it in ipairs(healthRows) do
      local lbl = tostring(it.label or "")
      if #lbl > rightLabelW then rightLabelW = #lbl end
    end

    local sep = " | "
    local available = math.max(0, (tonumber(w) or 0) - #sep)
    local leftW = math.floor(available / 2)
    local rightW = available - leftW
    if leftW < 1 then leftW = 1 end
    if rightW < 1 then rightW = 1 end
    local rightColStart = leftW + #sep + 1

    local rows = math.max(#colonyRowsBase, #healthRows)
    for i = 1, rows do
      if y > h - 2 then break end
      local c = colonyRowsBase[i]
      local hr = healthRows[i]

      local leftPrefix = ""
      local leftVal = ""
      local leftColor = colors.white
      if type(c) == "table" then
        leftPrefix = padRight(tostring(c.label or ""), leftLabelW) .. ": "
        leftVal = tostring(c.value or "")
        leftColor = c.color or colors.white
      end
      local leftText = leftPrefix .. leftVal
      local leftRendered = padRight(shorten(leftText, leftW), leftW)

      local rLabel = ""
      local rVal = ""
      local rLevel = "unknown"
      if type(hr) == "table" then
        rLabel = tostring(hr.label or "")
        rVal = tostring(hr.value or "")
        rLevel = tostring(hr.level or "unknown")
      end
      local rLabelShort = shorten(rLabel, rightLabelW)
      local rPrefix = padRight(rLabelShort, rightLabelW) .. ": "
      local maxRVal = math.max(0, rightW - #rPrefix)
      local rRendered = rPrefix .. shorten(rVal, maxRVal)
      rRendered = padRight(shorten(rRendered, rightW), rightW)

      local line = leftRendered .. sep .. rRendered
      self:drawText("status", mon, 1, y, padRight(line, w))

      if leftVal ~= "" then
        local maxLeftValueLen = math.max(0, leftW - #leftPrefix)
        local leftValueRendered = shorten(leftVal, maxLeftValueLen)
        local leftValueX = #leftPrefix + 1
        if leftValueRendered ~= "" and leftValueX <= leftW then
          self:drawText("status", mon, leftValueX, y, leftValueRendered, leftColor, colors.black, true)
        end
      end

      local valueX = rightColStart + #rPrefix
      local rValueRendered = shorten(rVal, maxRVal)
      if rValueRendered ~= "" and valueX <= w then
        self:drawText("status", mon, valueX, y, shorten(rValueRendered, math.max(0, w - valueX + 1)), healthValueColor(rLevel),
          colors.black, true)
      end

      y = y + 1
    end

    if y <= h - 2 then
      self:drawText("status", mon, 1, y, padRight("", w)); y = y + 1
    end
  end

  local opPage = pages
  if self.statusPage == opPage or pages == 1 then
    local perfSummary = nil
    if perfEnabled then
      local t = type(m.timing) == "table" and m.timing or {}
      local function round0(v) return math.floor((tonumber(v or 0) or 0) + 0.5) end
      local engLast = round0(t.engine_tick_ms_last)
      local uiLast = round0(t.ui_tick_ms_last)
      perfSummary = "PERF e/u " .. tostring(engLast) .. "/" .. tostring(uiLast) .. "ms"
    end

    self:drawText("status", mon, 1, y, centerText("OPERACAO", w), colors.cyan)
    if perfSummary then
      local x = math.max(1, w - #perfSummary + 1)
      self:drawText("status", mon, x, y, perfSummary, colors.gray, colors.black, true)
    end
    y = y + 1
    self:drawText("status", mon, 1, y, string.rep("-", math.max(0, w))); y = y + 1

    local reqCount = (type(state.requests) == "table") and #state.requests or 0
    local counters = {
      { label = "Requisicoes",   value = tostring(reqCount) },
      { label = "Entregues",     value = tostring(state.stats.delivered) },
      { label = "Crafts",        value = tostring(state.stats.crafted) },
      { label = "Substituicoes", value = tostring(state.stats.substitutions) },
      { label = "Erros",         value = tostring(state.stats.errors) },
    }
    local counterLabelW = 0
    for i = 1, #counters do
      local lbl = tostring(counters[i].label or "")
      if #lbl > counterLabelW then counterLabelW = #lbl end
    end
    for i = 1, #counters do
      if y > h - 2 then break end
      local it = counters[i]
      local leftPrefix = padRight(tostring(it.label or ""), counterLabelW) .. ": "
      local val = tostring(it.value or "")
      local line = shorten(leftPrefix, w)
      self:drawText("status", mon, 1, y, padRight(line, w))
      local startX = #leftPrefix + 1
      if startX <= w then
        self:drawText("status", mon, startX, y, shorten(val, math.max(0, w - #leftPrefix)), colors.white, colors.black, true)
      end
      y = y + 1
    end

    if y <= h - 2 then
      self:drawText("status", mon, 1, y, padRight("", w)); y = y + 1
    end

    if perfEnabled then
      local t = type(m.timing) == "table" and m.timing or {}
      local io = type(m.io) == "table" and m.io or {}
      local cache = type(m.cache) == "table" and m.cache or {}

      local function round0(v)
        return math.floor((tonumber(v or 0) or 0) + 0.5)
      end

      local engLast = round0(t.engine_tick_ms_last)
      local engAvg = round0(t.engine_tick_ms_avg)
      local engMax = round0(t.engine_tick_ms_max)
      local uiLast = round0(t.ui_tick_ms_last)
      local uiAvg = round0(t.ui_tick_ms_avg)
      local uiMax = round0(t.ui_tick_ms_max)

      local meTotal = type(io.me) == "table" and (tonumber(io.me.total) or 0) or 0
      local mcTotal = type(io.mc) == "table" and (tonumber(io.mc.total) or 0) or 0
      local invTotal = type(io.inv) == "table" and (tonumber(io.inv.total) or 0) or 0

      local hit = tonumber(cache.hit_total) or 0
      local miss = tonumber(cache.miss_total) or 0

      local line1 = "[PERF] tick_ms eng=" .. engLast .. "/" .. engAvg .. "/" .. engMax .. " ui=" .. uiLast .. "/" .. uiAvg .. "/" .. uiMax
      local line2 = "[PERF] io me=" .. meTotal .. " mc=" .. mcTotal .. " inv=" .. invTotal .. " cache " .. hit .. "/" .. miss

      if y <= h - 2 then
        self:drawText("status", mon, 1, y, padRight(shorten(line1, w), w), colors.lightGray, colors.black); y = y + 1
      end
      if y <= h - 2 then
        self:drawText("status", mon, 1, y, padRight(shorten(line2, w), w), colors.lightGray, colors.black); y = y + 1
      end
    end

    if y <= h - 2 then
      self:drawText("status", mon, 1, y, shorten("Estoque Critico: [heuristica]", w)); y = y + 1
    end
  end

  -- Clear remaining lines until bottom button
  for i = y, h - 2 do
    self:drawText("status", mon, 1, i, padRight("", w))
  end

  local noCraft = self:collectNoCraftItems(state)
  local btn = "SEM CRAFT: " .. tostring(#noCraft)
  local btnFg = (#noCraft > 0) and colors.red or colors.gray
  local updBtn = "[UPD]"
  local updFg = UpdateCheck.isUpdateAvailable(state) and colors.yellow or colors.gray
  self:drawText("status", mon, 1, h - 1, string.rep("-", math.max(0, w)), colors.gray, colors.black)
  self:drawText("status", mon, 1, h, padRight(btn, w), btnFg, colors.black)
  if pages > 1 then
    local p = tostring(self.statusPage) .. "/" .. tostring(pages)
    local pg = "[P" .. p .. "]"
    local xPg = math.max(1, math.floor((w - #pg) / 2) + 1)
    self:drawText("status", mon, xPg, h, pg, colors.gray, colors.black, true)
  end
  self:drawText("status", mon, math.max(1, w - #updBtn + 1), h, updBtn, updFg, colors.black)
end

function UI:renderUpdateDetails(state, mon)
  if not mon then return end
  local w, h = mon.getSize()

  self:drawText("status", mon, 1, 1, padRight(centerText("UPDATE CHECK", w), w))
  local right = UpdateCheck.formatHeaderRight(state, w)
  self:drawText("status", mon, math.max(1, w - #right + 1), 1, right, colors.gray)
  self:drawText("status", mon, 1, 2, string.rep("-", math.max(0, w)))

  local upd = type(state.update) == "table" and state.update or {}
  local installed = cleanAscii(upd.installed_version or (state.installed and state.installed.version) or "NO-VERSION")
  local available = cleanAscii(upd.available_version or "-")
  local status = cleanAscii(upd.status or "-")
  local stale = upd.stale == true and "SIM" or "NAO"

  local lastChecked = formatTs(upd.last_attempt_at_ms or upd.checked_at_ms)
  local lastSuccess = formatTs(upd.last_success_at_ms)
  local lastErr = shorten(cleanAscii(upd.err or "-"), math.max(0, w - #"Last err: "))
  local manifestUrl = shorten(cleanAscii(upd.manifest_url or "-"), math.max(0, w - #"Manifest: "))

  local y = 3
  self:drawText("status", mon, 1, y, padRight("Installed: " .. installed, w)); y = y + 1
  self:drawText("status", mon, 1, y, padRight("Available: " .. available, w)); y = y + 1
  self:drawText("status", mon, 1, y, padRight("Status: " .. status, w)); y = y + 1
  self:drawText("status", mon, 1, y, padRight("Stale: " .. stale, w)); y = y + 1
  self:drawText("status", mon, 1, y, padRight("Last checked: " .. lastChecked, w)); y = y + 1
  self:drawText("status", mon, 1, y, padRight("Last success: " .. lastSuccess, w)); y = y + 1
  self:drawText("status", mon, 1, y, padRight("Last err: " .. lastErr, w)); y = y + 1
  self:drawText("status", mon, 1, y, padRight("Manifest: " .. manifestUrl, w)); y = y + 1

  for i = y, h - 2 do
    self:drawText("status", mon, 1, i, padRight("", w))
  end

  self:drawText("status", mon, 1, h - 1, string.rep("-", math.max(0, w)), colors.gray, colors.black)
  self:drawText("status", mon, 1, h, padRight("[VOLTAR]", w), colors.lightGray, colors.black)
end

function UI:handleEvent(event, side, x, y)
  if event == "monitor_touch" then
    local devices = type(self.state) == "table" and self.state.devices or nil
    local reqMonName = devices and devices.monitorRequestsName or nil
    local statusMonName = devices and devices.monitorStatusName or nil
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
      if self.statusView == "nocraft" then
        if y == h then
          self.statusView = "main"
        else
          if x < w / 2 then
            self.noCraftPage = (self.noCraftPage or 1) - 1
          else
            self.noCraftPage = (self.noCraftPage or 1) + 1
          end
        end
        self:tick()
      elseif self.statusView == "update" then
        if y == h then
          self.statusView = "main"
          self:tick()
        end
      else
        local pages = tonumber(self._statusPages) or 1
        if y == h then
          local updBtn = "[UPD]"
          local updStart = math.max(1, w - #updBtn + 1)
          if x >= updStart then
            self.statusView = "update"
            self:tick()
            return
          end

          local noCraft = self:collectNoCraftItems(self.state)
          local btn = "SEM CRAFT: " .. tostring(#noCraft)
          if x <= #btn + 1 and #noCraft > 0 then
            self.statusView = "nocraft"
            self.noCraftPage = 1
            self:tick()
            return
          end
        end

        if pages > 1 then
          local p = tonumber(self.statusPage) or 1
          p = p + 1
          if p > pages then p = 1 end
          self.statusPage = p
          self:tick()
        end
      end
    end
  end
end

function UI:tick()
  local state = self.state
  local view = (type(state) == "table" and type(state.snapshot) == "table") and state.snapshot or state

  self:renderRequests(view, state.devices.monitorRequests)
  if self._lastStatusView ~= self.statusView then
    self.buffers.status = {}
    self.sizes.status = nil
    clearMonitor(state.devices.monitorStatus)
    self._lastStatusView = self.statusView
  end
  if self.statusView == "nocraft" then
    self:renderNoCraft(view, state.devices.monitorStatus)
  elseif self.statusView == "update" then
    self:renderUpdateDetails(view, state.devices.monitorStatus)
  else
    self:renderStatus(view, state.devices.monitorStatus)
  end
end

return {
  new = UI.new,
  _test = {
    defaultPeripheralHealth = defaultPeripheralHealth,
    formatTwoColLine = formatTwoColLine,
    getPeripheralHealth = getPeripheralHealth,
    healthValueColor = healthValueColor,
  },
}
