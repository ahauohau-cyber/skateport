-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {}

local function json_eq(p1, p2) -- line: 24
    -- upvalues: json_eq (copy)
    if type(p1) ~= "table" or type(p2) ~= "table" then
        return p1 == p2
    end

    for v1, v2 in p1 do
        if not json_eq(v2, p2[v1]) then
            return false
        end
    end

    for v3 in p2 do
        if p1[v3] == nil then
            return false
        end
    end

    return true
end

local function as_object(p3) -- line: 42
    return if type(p3) == "table" and #p3 == 0 then p3 else nil
end

local function as_array(p4) -- line: 50
    return if type(p4) == "table" and (#p4 > 0 or next(p4) == nil) then p4 else nil
end

local function as_str(p5) -- line: 58
    return if type(p5) == "string" then p5 else nil
end

local function sorted_keys(p6) -- line: 66
    local t2 = {}

    for v4 in p6 do
        table.insert(t2, v4)
    end

    table.sort(t2)

    return t2
end

function t1.pipeline_group_matches(p7, p8, p9, p10) -- line: 77
    -- upvalues: json_eq (copy)
    if p7 ~= nil and json_eq(p7, p8) then
        return true
    end

    local v5 = if type(p7) == "string" then p7 else nil
    local v6 = if type(p8) == "string" then p8 else nil

    if v5 ~= nil and v6 ~= nil then
        if v5 == v6 then
            return true
        end

        local v7

        if type(p10) == "table" then
            v7 = p10[p9]

            if type(v7) ~= "table" or not (#v7 > 0) and next(v7) ~= nil then
                v7 = nil
            end
        end

        if v7 ~= nil then
            for _, v8 in ipairs(v7) do
                local v9 = if type(v8) == "table" and (#v8 > 0 or next(v8) == nil) then v8 else nil

                if v9 ~= nil and #v9 == 2 then
                    local v10 = v9[1]

                    if type(v10) ~= "string" then
                        v10 = nil
                    end

                    if v10 == v5 then
                        local v11 = v9[2]

                        if type(v11) ~= "string" then
                            v11 = nil
                        end

                        if v11 == v6 then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function t1.pipelines_current(p11, p12, p13) -- line: 111
    -- upvalues: t1 (copy), json_eq (copy)
    local pipelines = if type(p11) == "table" then p11.pipelines else nil

    if pipelines == nil or not json_eq(pipelines, p12) then
        if type(pipelines) ~= "table" or #pipelines ~= 0 then
            pipelines = nil
        end

        local v12 = if type(p12) ~= "table" or #p12 ~= 0 then nil else p12

        if v12 == nil then
            return false
        end

        local _ipairs = ipairs
        local t3 = {}

        for v13 in v12 do
            table.insert(t3, v13)
        end

        table.sort(t3)

        for _, v14 in _ipairs(t3) do
            local v15 = v12[v14]
            local v16 = if pipelines == nil then nil else pipelines[v14]

            if not t1.pipeline_group_matches(v16, v15, v14, p13) then
                return false
            end
        end
    end

    return true
end

function t1.asset_root(p14, p15) -- line: 139
    if p14 ~= nil then
        for _, v17 in ipairs(p14) do
            if v17 == "--assets" then
                return "assets"
            end
        end
    end

    if p15 ~= nil then
        return p15
    end

    error("This copy has not been set up. Use the complete Windows package, pass --assets DIRECTORY, or set SKATE3_ASSETS for development.", 0)
end

return t1
