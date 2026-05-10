--- =====================================================================================================================
-- Arquivo: cclib/core/class.lua
-- Descrição:
-- =====================================================================================================================

--#region Definições ----------------------------------------------------------------------------------------------------

---@type CCLib.ClassModule
local M = {}

--#endregion

--#region Métodos públicos ---------------------------------------------------------------------------------------------

function M.new(base)
    local cls = {}
    cls.__index = cls
    cls.__name = "Class"

    -- Herança: se base existir, cls herda todos os seus métodos
    if base then
        setmetatable(cls, { __index = base })
        cls.__base = base
    else
        cls.__base = nil
    end

    -- Instanciar: cls:new(...) → chama cls:init(...)
    function cls:new(...)
        local instance = setmetatable({}, cls)
        if instance.init then
            instance:init(...)
        end
        return instance
    end

    -- Verificar se uma instância é de uma determinada classe (ou subclasse)
    function cls:isA(klass)
        ---@type table|nil
        local mt = getmetatable(self)
        while mt do
            if mt == klass then return true end
            local parent = getmetatable(mt)
            mt = parent and parent.__index or nil
        end
        return false
    end

    -- Representação textual (pode ser sobrescrita)
    function cls:__tostring()
        return string.format("<%s>", cls.__name or "Instance")
    end

    return cls
end

function M.mixin(cls, mixin)
    for k, v in pairs(mixin) do
        if cls[k] == nil then -- não sobrescreve métodos existentes
            cls[k] = v
        end
    end
    return cls
end

function M.isInstance(value, klass)
    if type(value) ~= "table" then return false end
    ---@type CCLib.Class
    return value:isA() and (value:isA(klass) or false)
end

--#endregion

return M
