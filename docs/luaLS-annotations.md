# LuaLS — Referência Completa de Anotações

> **LuaLS** (lua-language-server) — anotações com `---@` (três hífenes).
> Compatível com VS Code + extensão **Lua** (sumneko).

---

## Sistema de tipos

### Tipos primitivos

```lua
nil  boolean  number  integer  string  table  function  thread  userdata
any     -- aceita qualquer tipo (sem verificação)
unknown -- tipo desconhecido (mais seguro que any; requer narrowing antes de usar)
never   -- impossível (sem retorno, loop infinito, error())
```

### Modificadores de tipo

```lua
---@type string?          -- opcional: string | nil
---@type string | number  -- união de tipos
---@type string[]         -- array de strings
---@type string[][]       -- array de arrays

---@type { x: number, y: number }           -- tabela anónima inline
---@type { [string]: number }               -- mapa string → number
---@type { [1]: string, [2]: number }       -- tuple posicional

---@type fun(x: number, y: number): string  -- função tipada
---@type fun(name: string, ...any): void    -- variadic
```

---

## Anotações de declaração

### `---@class`

Define uma classe ou tipo estruturado.

```lua
---@class Vec2
---@field x number
---@field y number
local Vec2 = {}

---@class Vec2
---@field x number
---@field y number
---@field z number?  -- campo opcional
local Vec3 = {}

-- Herança
---@class Animal
---@field name string

---@class Dog : Animal   -- Dog herda de Animal
---@field breed string
```

### `---@field`

Campo de uma classe. Sempre a seguir a `---@class`.

```lua
---@class Config
---@field width    number          -- obrigatório
---@field height   number          -- obrigatório
---@field title    string?         -- opcional
---@field bg       number | nil    -- equivalente a string?
---@field align    "left"|"right"|"center"  -- literal union
---@field onClose  fun(): void     -- função sem retorno
---@field tags     string[]        -- array
---@field meta     table<string, any>  -- mapa genérico

-- Visibilidade
---@field public  name string      -- padrão; acessível fora
---@field private _id  number      -- só dentro da classe
---@field protected _ref table     -- classe e sub-classes
```

### `---@alias`

Cria um alias de tipo (nome alternativo).

```lua
---@alias Color number          -- colors.white, colors.red, etc.
---@alias Path string | string[]
---@alias Callback fun(err: string?, data: any): void
---@alias Side "top"|"bottom"|"left"|"right"|"front"|"back"
```

### `---@enum`

Define um tipo enum. O LSP valida os valores usados.

```lua
---@enum Direction
local Direction = {
    NORTH = "NORTH",
    SOUTH = "SOUTH",
    EAST  = "EAST",
    WEST  = "WEST",
}

---@enum Status
local Status = {
    IDLE    = 0,
    RUNNING = 1,
    DONE    = 2,
}
```

### `---@type`

Anota o tipo de uma variável, campo ou expressão.

```lua
---@type number
local width = 0

---@type string[]
local lines = {}

---@type table<string, fun(): void>
local handlers = {}

---@type Color
local bg = colors.black

-- Inline (sem linha própria)
local x = value --[[@as number]]
```

---

## Anotações de função

### `---@param`

Tipo de um parâmetro. `?` indica opcional.

```lua
---@param name string
---@param width number
---@param height number?           -- opcional
---@param callback fun(n: number)  -- função como parâmetro
---@param ... any                  -- variadic
function draw(name, width, height, callback, ...) end

-- Com descrição inline
---@param side "top"|"bottom"|"left"|"right"  posição do painel
---@param color Color  cor CC (potência de 2)
function setPanel(side, color) end
```

### `---@return`

Tipo(s) de retorno. Múltiplos retornos = múltiplas linhas.

```lua
---@return number
function getWidth() return 51 end

---@return number width
---@return number height
function getSize() return 51, 19 end

---@return string | nil   -- pode retornar nil
function findLine() end

---@return number, number  -- dois retornos sem nome
function getPos() end

-- Retorno condicional
---@return boolean ok
---@return string? err   -- nil se ok == true
function validate() end
```

### `---@overload`

Sobrecargas de função — múltiplas assinaturas para uma mesma função.

```lua
---@overload fun(path: string): string
---@overload fun(path: string, encoding: string): string
---@overload fun(path: string[]): string[]
function read(path, encoding) end

---@overload fun(x: number, y: number)
---@overload fun(pos: Vec2)
function moveTo(x, y) end
```

### `---@generic`

Tipos genéricos (templates).

```lua
---@generic T
---@param t T[]
---@return T
function first(t) return t[1] end

---@generic K, V
---@param t table<K, V>
---@param key K
---@return V
function get(t, key) return t[key] end

-- Com constraint
---@generic T : number | string
---@param a T
---@param b T
---@return T
function max(a, b) return a > b and a or b end
```

### `---@vararg` *(deprecated — usar `---@param ... type`)*

```lua
-- Moderno:
---@param ... string
function log(...) end

-- Antigo (ainda suportado):
---@vararg string
function log(...) end
```

---

## Anotações de módulo e visibilidade

### `---@module`

Declara o tipo de um módulo importado via `require`.

```lua
---@module "cclib.core.guard"
local guard = require("cclib.core.guard")
```

### `---@private` / `---@protected` / `---@package`

Visibilidade de funções e campos.

```lua
---@private
function MyClass:_internalHelper() end

---@protected
function MyClass:_sharedMethod() end

---@package
-- Acessível só dentro do ficheiro/package
local function _util() end
```

---

## Anotações de comportamento

### `---@nodiscard`

O valor de retorno NÃO deve ser ignorado.

```lua
---@nodiscard
---@return Result
function validate(data) end

-- O LSP avisa se o consumer escrever:
-- validate(data)       ← warning: resultado descartado
-- local r = validate(data)  ← ok
```

### `---@async`

Marca função como assíncrona (usa `coroutine.yield` internamente).

```lua
---@async
function waitForKey()
    os.pullEvent("key")
end
```

### `---@deprecated`

Marca função como obsoleta. O LSP sublinha o uso.

```lua
---@deprecated Usar timer.after() em vez disso
function setTimeout(fn, ms) end
```

### `---@see`

Referência a outra função, tipo ou documentação.

```lua
---@see timer.after
---@see https://tweaked.cc/module/os.html
function myTimer() end
```

### `---@version`

Versão de Lua ou ambiente em que está disponível.

```lua
---@version 5.2
function bitAnd(a, b) return bit32.band(a, b) end

---@version JIT
function fastPath() end
```

---

## Controlo de diagnósticos

### `---@diagnostic`

Activa, desactiva ou suprime avisos do LSP.

```lua
---@diagnostic disable-next-line: undefined-global
local term = term   -- suprime "undefined-global" na linha seguinte

---@diagnostic disable: unused-local
local _unused = 42  -- suprime no bloco até enable

---@diagnostic enable: unused-local

-- Suprimir num ficheiro inteiro (no topo):
---@diagnostic disable

-- Avisos comuns:
---@diagnostic disable-next-line: undefined-global
---@diagnostic disable-next-line: undefined-field
---@diagnostic disable-next-line: unused-local
---@diagnostic disable-next-line: missing-return
---@diagnostic disable-next-line: redundant-parameter
---@diagnostic disable-next-line: need-check-nil
```

---

## Inline cast

### `--[[@as type]]` / `---@cast`

Forçar tipo numa expressão sem criar variável.

```lua
-- Inline (sem linha extra)
local n = getValue() --[[@as number]]

-- Cast em variável existente
---@cast n number           -- reinterpreta n como number
---@cast n number | string  -- alarga o tipo
---@cast n -nil             -- remove nil da union (narrowing)
---@cast n +string          -- adiciona string à union
```

---

## Exemplo completo — módulo CCLib

```lua
-- ──────────────────────────────────────────────────────────────────────────
-- CCLib ▸ cclib/system/timer.lua
-- ──────────────────────────────────────────────────────────────────────────

---@meta  -- este ficheiro é só definição; não gera código executável

-- ── Tipos ─────────────────────────────────────────────────────────────────

---@alias TimerId    number   -- ID interno do timer (não é o ID CC)
---@alias Seconds    number   -- duração em segundos
---@alias TimerKind  "after" | "every"

---@class TimerEntry
---@field id        TimerId
---@field fn        fun(): void
---@field kind      TimerKind
---@field interval  Seconds?
---@field cancelled boolean

---@class DebouncedFn
---@overload fun(self: DebouncedFn, ...: any): void
local DebouncedFn = {}

---@return boolean
function DebouncedFn:isPending() end

function DebouncedFn:cancel() end

-- ── Módulo ────────────────────────────────────────────────────────────────

---@class Timer
local timer = {}

--- Chama fn uma vez após `seconds` segundos.
---@param  seconds Seconds   tempo de espera (>= 0)
---@param  fn      fun(): void
---@return TimerId            id para timer.cancel
---@nodiscard
function timer.after(seconds, fn) end

--- Chama fn a cada `seconds` segundos.
---@param  seconds Seconds   intervalo (> 0)
---@param  fn      fun(): void
---@return TimerId
---@nodiscard
function timer.every(seconds, fn) end

--- Cancela um timer. Idempotente.
---@param id TimerId
function timer.cancel(id) end

--- Cancela todos os timers activos.
function timer.cancelAll() end

--- Retorna número de timers activos.
---@return integer
function timer.count() end

--- Debounce: adia a chamada até `wait` segundos após a última invocação.
---@param  fn   fun(...: any): void
---@param  wait Seconds  tempo de espera (> 0)
---@return DebouncedFn
---@nodiscard
function timer.debounce(fn, wait) end

--- Throttle: máximo uma chamada por `limit` segundos.
---@param  fn    fun(...: any): void
---@param  limit Seconds  intervalo mínimo (> 0)
---@return fun(...: any): void
---@nodiscard
function timer.throttle(fn, limit) end

--- Countdown com tick a cada segundo.
---@param  seconds number    duração (>= 1)
---@param  onTick  fun(remaining: integer): void?
---@param  onDone  fun(): void?
---@return TimerId
---@nodiscard
function timer.countdown(seconds, onTick, onDone) end

return timer
```

---

## Cheat sheet rápido

| Anotação | Uso |
|---|---|
| `---@class Name` | declara tipo/classe |
| `---@class Name : Parent` | com herança |
| `---@field name type` | campo de classe |
| `---@field name type?` | campo opcional |
| `---@alias Name type` | alias de tipo |
| `---@enum Name` | enum tipado |
| `---@type type` | anota variável |
| `---@param name type` | parâmetro de função |
| `---@param name type?` | parâmetro opcional |
| `---@param ... type` | variadic |
| `---@return type` | retorno |
| `---@return type name` | retorno com nome |
| `---@overload fun(...): ...` | sobrecarga |
| `---@generic T` | tipo genérico |
| `---@nodiscard` | retorno obrigatório |
| `---@deprecated` | obsoleto |
| `---@async` | função assíncrona |
| `---@private` | privado |
| `---@protected` | protegido |
| `---@package` | interno ao package |
| `---@see ref` | referência |
| `---@version ver` | versão Lua |
| `---@cast var type` | força tipo |
| `expr --[[@as type]]` | cast inline |
| `---@diagnostic disable-next-line: code` | suprime aviso |
| `---@module "path"` | tipo de módulo require |
