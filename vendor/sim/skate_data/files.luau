-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {}
local t2 = {}

local function misc_folder() -- line: 23
    -- upvalues: sim (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")

    return sim_data and sim_data:FindFirstChild("misc")
end

local function misc_index() -- line: 28
    -- upvalues: sim (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local misc = sim_data and sim_data:FindFirstChild("misc")
    local index = misc and misc:FindFirstChild("index")

    if index then
        return require(index)
    end

    return nil
end

function t1.normalize(p1) -- line: 38
    local v1 = string.gsub(p1, "\\", "/")

    while string.sub(v1, 1, 2) == "./" do
        v1 = string.sub(v1, 3)
    end

    return v1
end

function t1.exists(p2) -- line: 47
    -- upvalues: sim (copy), t1 (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local misc = sim_data and sim_data:FindFirstChild("misc")
    local index = misc and misc:FindFirstChild("index")
    local v2 = if index then require(index) else nil

    return v2 ~= nil and v2.files[t1.normalize(p2)] ~= nil
end

function t1.read(p3) -- line: 53
    -- upvalues: sim (copy), t1 (copy), t2 (copy)
    local v3 = t1.normalize(p3)
    local v4 = t2[v3]

    if v4 ~= nil then
        return v4
    end

    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local misc = sim_data and sim_data:FindFirstChild("misc")
    local index = misc and misc:FindFirstChild("index")
    local v5 = if index then require(index) else nil

    if v5 == nil then
        return nil
    end

    local v6 = v5.files[v3]

    if v6 == nil then
        return nil
    end

    local sim_data2 = sim.Parent:FindFirstChild("sim_data")
    local misc2 = sim_data2 and sim_data2:FindFirstChild("misc")

    local function data_module(p4) -- line: 68
        -- upvalues: v3 (copy), misc2 (copy)
        local v7 = misc2:FindFirstChild(p4)

        if not v7 then
            error(("skate_data/files: sim_data.misc.%* is listed for \"%*\" but is not installed"):format(p4, v3), 0)
        end

        return require(v7)
    end

    local v8

    if v6.parts ~= nil then
        local v10 = table.create(#v6.parts)

        for v11, v12 in v6.parts do
            local v13 = misc2:FindFirstChild(v12)

            if not v13 then
                error(("skate_data/files: sim_data.misc.%* is listed for \"%*\" but is not installed"):format(v12, v3), 0)
            end

            v10[v11] = require(v13)
        end

        v8 = table.concat(v10)
    else
        local module = v6.module
        local v9 = misc2:FindFirstChild(module)

        if not v9 then
            error(("skate_data/files: sim_data.misc.%* is listed for \"%*\" but is not installed"):format(module, v3), 0)
        end

        v8 = require(v9)[v6.key]
    end

    if type(v8) ~= "string" then
        error(("skate_data/files: sim_data.misc holds no text for \"%*\""):format(v3), 0)
    end

    t2[v3] = v8

    return v8
end

return t1
