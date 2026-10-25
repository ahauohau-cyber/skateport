-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local Parent = script.Parent
local t1 = {}
local t2 = {}

local function import(p1) -- line: 9
    -- upvalues: Parent (copy), t1 (copy), t2 (copy)
    local v1 = t2[p1]

    if v1 ~= nil then
        return v1
    end

    if t1[p1] then
        error(("import cycle through \"%*\" - import it lazily inside the function that needs it"):format(p1), 2)
    end

    local v2 = Parent

    for match in string.gmatch(p1, "[^/]+") do
        local v3 = v2:FindFirstChild(match)

        if not v3 then
            error(("import: no module \"%*\" (missing \"%*\" under %*)"):format(p1, match, (v2:GetFullName())), 2)
        end

        v2 = v3
    end

    if not v2:IsA("ModuleScript") then
        error(("import: no module \"%*\" (\"%*\" is a %*: the directory has no init.luau)"):format(p1, v2.Name, v2.ClassName), 2)
    end

    t1[p1] = true

    local _require = require
    local ok, result = pcall(_require, v2)

    t1[p1] = nil

    if not ok then
        error(result, 0)
    end

    t2[p1] = result

    return result
end

return import
