--- =====================================================================================================================
-- Arquivo: cclib/core/const.lua
-- Descrição: Constantes da biblioteca
-- Autor: CCLib - Tiny Core
-- =====================================================================================================================

---@version 1.0.0

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.Const
local M = {
  LIB_NAME = "CCLib.const",
  SCHEMA_VER = 1,
  DEV = true,
  SIDE = {
    TOP    = "top",
    BOTTOM = "bottom",
    LEFT   = "left",
    RIGHT  = "right",
    FRONT  = "front",
    BACK   = "back",
    ALL    = { "top", "bottom", "left", "right", "front", "back" },
  },
  MONITOR = {
    DEFAULT_W = 51,
    DEFAULT_H = 19,
    SMALL_W   = 7,
    SMALL_H   = 5,
    -- tamanho mínimo que a lib suporta renderizar
    MIN_W     = 10,
    MIN_H     = 5,
  },
  COLOR = {
    WHITE      = 1,
    ORANGE     = 2,
    MAGENTA    = 4,
    LIGHT_BLUE = 8,
    YELLOW     = 16,
    LIME       = 32,
    PINK       = 64,
    GRAY       = 128,
    LIGHT_GRAY = 256,
    CYAN       = 512,
    PURPLE     = 1024,
    BLUE       = 2048,
    BROWN      = 4096,
    GREEN      = 8192,
    RED        = 16384,
    BLACK      = 32768,
  },
  KEY = {
    ENTER     = 28,
    BACKSPACE = 14,
    TAB       = 15,
    SPACE     = 57,
    ESCAPE    = 1,
    UP        = 200,
    DOWN      = 208,
    LEFT      = 203,
    RIGHT     = 205,
    HOME      = 199,
    END       = 207,
    PAGE_UP   = 201,
    PAGE_DOWN = 209,
    DELETE    = 211,
    F1        = 59,
    F2        = 60,
    F3        = 61,
    F4        = 62,
    F5        = 63,
    F12       = 88,
  },
  PERIPHERAL = {
    MONITOR  = "monitor",
    MODEM    = "modem",
    SPEAKER  = "speaker",
    DRIVE    = "drive",
    PRINTER  = "printer",
    COMPUTER = "computer",
  },
  LOG = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4,
    FATAL = 5,
  },
  LOG_NAMES = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
    [5] = "FATAL",
  },
  PATH = {
    LOGS   = "/logs/",
    DATA   = "/data/",
    CONFIG = "/config.lua",
  },
  EVENT = {
    PERIPHERAL_FOUND = "cclib:peripheral_found",
    PERIPHERAL_LOST  = "cclib:peripheral_lost",
    ROUTE_CHANGED    = "cclib:route_changed",
    STORE_CHANGED    = "cclib:store_changed",
    SESSION_START    = "cclib:session_start",
    SESSION_STOP     = "cclib:session_stop",
    RENDER_REQUEST   = "cclib:render_request",
  },
  TIME = {
    PERSIST_DEBOUNCE = 2.0,
    TOAST_DURATION   = 3.0,
    SPINNER_INTERVAL = 0.2,
    BLINK_INTERVAL   = 0.5,
  },
  LIMIT = {
    LOG_FILE_LINES = 500,
    STORE_WATCHERS = 64,
    TIMER_MAX      = 128,
    TOAST_QUEUE    = 4,
    ROUTER_HISTORY = 16,
    SNAPSHOT_DEPTH = 12,
  }
}

--#endregion

return M
