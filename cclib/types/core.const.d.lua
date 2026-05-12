---@meta
-- cclib / types / core.const.d.lua
-- Definições de tipo para core/const.lua
-- Compatível com lua-language-server (LuaLS) v3+

-- ── Sub-tipos ────────────────────────────────────────────────────────────────

-- ── Enum de sides ────────────────────────────────────────────────────────────

---Tipo union com todos os sides válidos do CC:Tweaked.
---Usa em assinaturas de função para garantir que só passam strings válidas.
---
---```lua
----- Correto — o LSP autocompleta e valida:
---Peripheral.get("monitor", Const.SIDE.TOP)
---
----- Também válido com o alias direto:
-----@param side CCLib.Side
---local function render(side) end
---```
---@alias CCLib.Side "top" | "bottom" | "left" | "right" | "front" | "back"

---@class CCLib.Const.Side
---@field TOP    CCLib.Side
---@field BOTTOM CCLib.Side
---@field LEFT   CCLib.Side
---@field RIGHT  CCLib.Side
---@field FRONT  CCLib.Side
---@field BACK   CCLib.Side
---@field ALL    CCLib.Side[]  Array ordenado de todos os sides, para iteração

---@class CCLib.Const.Monitor -- Monitor CC
---@field DEFAULT_W  integer  -- Largura padrão do monitor CC
---@field DEFAULT_H  integer  -- Altura padrão do monitor CC
---@field SMALL_W    integer  -- Largura do monitor pequeno
---@field SMALL_H    integer  -- Altura do monitor pequeno
---@field MIN_W      integer  -- Largura mínima suportada pela lib
---@field MIN_H      integer  -- Altura mínima suportada pela lib

---@class CCLib.Const.Color
---@field WHITE      integer
---@field ORANGE     integer
---@field MAGENTA    integer
---@field LIGHT_BLUE integer
---@field YELLOW     integer
---@field LIME       integer
---@field PINK       integer
---@field GRAY       integer
---@field LIGHT_GRAY integer
---@field CYAN       integer
---@field PURPLE     integer
---@field BLUE       integer
---@field BROWN      integer
---@field GREEN      integer
---@field RED        integer
---@field BLACK      integer

---@class CCLib.Const.Key
---@field ENTER     integer
---@field BACKSPACE integer
---@field TAB       integer
---@field SPACE     integer
---@field ESCAPE    integer
---@field UP        integer
---@field DOWN      integer
---@field LEFT      integer
---@field RIGHT     integer
---@field HOME      integer
---@field END       integer
---@field PAGE_UP   integer
---@field PAGE_DOWN integer
---@field DELETE    integer
---@field F1        integer
---@field F2        integer
---@field F3        integer
---@field F4        integer
---@field F5        integer
---@field F12       integer

---@class CCLib.Const.Peripheral
---@field MONITOR  string
---@field MODEM    string
---@field SPEAKER  string
---@field DRIVE    string
---@field PRINTER  string
---@field COMPUTER string

---@class CCLib.Const.Log
---@field DEBUG integer
---@field INFO  integer
---@field WARN  integer
---@field ERROR integer
---@field FATAL integer

---@class CCLib.Const.Path
---@field LOGS   string
---@field DATA   string
---@field CONFIG string

---@class CCLib.Const.Event
---@field PERIPHERAL_FOUND string
---@field PERIPHERAL_LOST  string
---@field ROUTE_CHANGED    string
---@field STORE_CHANGED    string
---@field SESSION_START    string
---@field SESSION_STOP     string
---@field RENDER_REQUEST   string

---@class CCLib.Const.Time
---@field PERSIST_DEBOUNCE number  -- Segundos antes de salvar no disco
---@field TOAST_DURATION   number  -- Duração padrão de toast
---@field SPINNER_INTERVAL number  -- Intervalo de animação do spinner
---@field BLINK_INTERVAL   number  -- Intervalo do cursor piscante

---@class CCLib.Const.Limit
---@field LOG_FILE_LINES  integer  -- Máximo de linhas por ficheiro de log
---@field STORE_WATCHERS  integer  -- Máximo de watchers por chave
---@field TIMER_MAX       integer  -- Máximo de timers ativos
---@field TOAST_QUEUE     integer  -- Máximo de toasts em fila
---@field ROUTER_HISTORY  integer  -- Máximo de entradas no histórico do router
---@field SNAPSHOT_DEPTH  integer  -- Profundidade máxima no deepCopy

-- ── Módulo principal ─────────────────────────────────────────────────────────

---@class CCLib.Const
---@field LIB_NAME   string                 -- Nome da lib: "CCLib"
---@field SCHEMA_VER integer                -- Versão do schema de dados para migrate.lua
---@field DEV        boolean                -- Ativa logs verbose e ferramentas de debug
---@field MONITOR    CCLib.Const.Monitor
---@field COLOR      CCLib.Const.Color
---@field KEY        CCLib.Const.Key
---@field SIDE       CCLib.Const.Side      -- Enum de sides: .TOP .BOTTOM .LEFT .RIGHT .FRONT .BACK .ALL
---@field PERIPHERAL CCLib.Const.Peripheral
---@field LOG        CCLib.Const.Log
---@field LOG_NAMES  table<integer, string>  -- Mapa de nível → nome: {[1]="DEBUG", ...}
---@field PATH       CCLib.Const.Path
---@field EVENT      CCLib.Const.Event
---@field TIME       CCLib.Const.Time
---@field LIMIT      CCLib.Const.Limit
