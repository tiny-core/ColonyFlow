local Util = require("lib.util")

local Version = {}

local function parse(semver)
    if type(semver) ~= "string" then return nil end
    local a, b, c = semver:match("^(%d+)%.(%d+)%.(%d+)$")
    if not a then return nil end
    if #a > 1 and a:sub(1, 1) == "0" then return nil end
    if #b > 1 and b:sub(1, 1) == "0" then return nil end
    if #c > 1 and c:sub(1, 1) == "0" then return nil end
    return tonumber(a), tonumber(b), tonumber(c)
end

function Version.isValid(semver)
    return parse(semver) ~= nil
end

function Version.compare(a, b)
    local a1, a2, a3 = parse(a)
    local b1, b2, b3 = parse(b)
    if not a1 or not b1 then return nil, "invalid_semver" end
    if a1 ~= b1 then return a1 < b1 and -1 or 1 end
    if a2 ~= b2 then return a2 < b2 and -1 or 1 end
    if a3 ~= b3 then return a3 < b3 and -1 or 1 end
    return 0
end

function Version.readInstalled()
    local txt = Util.readFile("data/version.json")
    if txt == nil then return nil end
    local obj = Util.jsonDecode(txt)
    if type(obj) ~= "table" then return nil end
    if type(obj.version) ~= "string" or not Version.isValid(obj.version) then
        return nil
    end
    return {
        version = obj.version,
        ref = obj.ref,
        manifest_url = obj.manifest_url,
    }
end

return Version
