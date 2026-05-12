---@meta
---@version 1.0.0

-- cclib / types / core.class.d.lua
-- Definições de tipo para core/class.lua

-- ── Classe base ───────────────────────────────────────────────────────────────

---@class CCLib.ClassInstance
---Verifica se esta instância é da classe `klass` ou de uma subclasse dela.
---@field isA fun(self: CCLib.ClassInstance, klass: CCLib.Class): boolean

-- ── Classe (resultado de Class.new) ──────────────────────────────────────────

---@class CCLib.Class : CCLib.ClassInstance
---@field __name string -- Nome da classe (para tostring e debug)
---@field __index CCLib.Class
---@field super CCLib.Class | nil -- Classe pai, ou nil se não há herança
---@field new fun(self: CCLib.Class, ...): CCLib.ClassInstance -- Cria uma nova instância. Chama `:init(...)` automaticamente se definido.
---@field isA fun(self: CCLib.Class, klass: CCLib.Class): boolean -- Verifica herança.

-- ── Módulo ────────────────────────────────────────────────────────────────────

---@class CCLib.ClassModule
local ClassModule = {}

---Cria uma nova classe, opcionalmente com herança simples.
---
---```lua
---local Animal = Class.new()
---local Dog = Class.new(Animal)
---
---function Dog:init(name) self.name = name end
---function Dog:bark() return "Woof!" end
---
---local d = Dog:new("Rex")
---print(d:isA(Animal)) --> true
---```
---@param base? CCLib.Class -- Classe pai para herança
---@return CCLib.Class
function ClassModule.new(base) end

---Copia métodos de um mixin para uma classe sem herança formal.
---Não sobrescreve métodos existentes na classe de destino.
---
---```lua
---local Serializable = { serialize = function(self) return textutils.serialize(self) end }
---Class.mixin(MyClass, Serializable)
---```
---@param cls CCLib.Class -- Classe de destino
---@param mixin table -- Tabela com métodos a copiar
---@return CCLib.Class -- A mesma `cls` (para encadeamento)
function ClassModule.mixin(cls, mixin) end

---Verifica de forma segura se um valor qualquer é instância de uma classe.
---Não lança erro em valores não-tabela (retorna false).
---@param value any
---@param klass CCLib.Class
---@return boolean
function ClassModule.isInstance(value, klass) end
