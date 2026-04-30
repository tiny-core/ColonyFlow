# Phase 23: Padrões do Codebase

## modules/engine.lua — flush periódico (análogo: _persistWorkMaybe)

```lua
-- Constantes existentes (ll.19–21):
local PERSIST_PATH = "data/state.json"
local PERSIST_INTERVAL_MS = 2000
local PERSIST_MAX_AGE_MS = 6 * 60 * 60 * 1000

-- Padrão de função gated com contagem de ticks (análogo ao PERSIST_INTERVAL_MS mas em ticks):
function Engine:_persistWorkMaybe()
  local now = Util.nowUtcMs()
  if self._persist_next_at_ms and now < self._persist_next_at_ms then return end
  self._persist_next_at_ms = now + PERSIST_INTERVAL_MS
  -- ...salva...
end

-- Chamada ao final de tick() (l.1277):
  publishSnapshot(state)
  self:_persistWorkMaybe()
end  -- fim de tick()
```

**Padrão para _metricsFlushMaybe**: mesma posição — chamada após `_persistWorkMaybe` no final de `tick()`.
Gatilho: `state.stats.processed % interval == 0` (sem campo extra no Engine).

## lib/util.lua — I/O atômico

```lua
-- Utilitários relevantes (nomes reais):
M.ensureDir(path)            -- cria diretório se não existe
M.readFile(path)             -- retorna string ou nil
M.writeFileAtomic(path, txt) -- escreve atomicamente
M.jsonDecode(txt)            -- wraps textutils.unserialiseJSON
M.nowUtcMs()                 -- os.epoch("utc")
```

**Padrão de escrita (usado em Persistence.save)**:
```lua
Util.ensureDir("data")
local json = textutils.serializeJSON(obj)
Util.writeFileAtomic(path, json)
```

**Padrão de leitura (usado em Persistence.load)**:
```lua
local txt = Util.readFile(path)
local ok, obj = pcall(Util.jsonDecode, txt)
if not ok then return nil end
```

## startup.lua — despacho de modos CLI

```lua
-- Padrão existente (ll.40–54):
local function runDoctor()
  if fs.exists("modules/doctor.lua") then
    shell.run("modules/doctor.lua")
    return
  end
  print("Doctor nao encontrado.")
end

-- Despacho (l.72–76):
if mode == "doctor" then
  runDoctor()
  return
end
```

**Padrão para `startup metrics`**: copiar estrutura de `runDoctor`/`runUpdate`.

## modules/doctor.lua — CLI standalone (referência de estrutura)

```lua
-- Cabeçalho:
local Config = require("lib.config")
local ME     = require("modules.me")

-- Helpers locais, função principal, chamada direta ao final:
local function main()
  -- lê estado, imprime saída formatada
end
main()
```

## lib/config.lua — DEFAULT_INI [observability]

```ini
[observability]
enabled=false
ui_enabled=false
debug_log_enabled=false
debug_log_interval_seconds=30
alert_stuck_minutes=5
-- PHASE 23: adicionar aqui:
-- metrics_flush_interval_ticks=60
```

## state.metrics — estrutura (bootstrap.lua ll.48–67)

```lua
local metrics = {
  enabled  = obsEnabled,            -- bool
  ui_enabled = ...,
  debug_log_enabled = ...,
  debug_log_interval_seconds = ...,
  timing = {},                      -- só quando obsEnabled=true
  io = {
    me  = { total = 0, methods = {} },
    mc  = { total = 0, methods = {} },
    inv = { total = 0, methods = {} },
  },
  cache = {
    hit_total  = 0,
    miss_total = 0,
    hit_by_namespace  = {},
    miss_by_namespace = {},
  },
}
-- state.metrics = nil quando obsEnabled=false
```
