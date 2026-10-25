-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local IDENTITY = import("skate_core/physics/skeleton_animation_record").IDENTITY
local v1 = import("skate_core/player/input_phase")
local assign_into = v1.assign_into
local v2 = false
local t1 = {}

function t1.set_reference(p1) -- line: 18
    -- upvalues: v2 (ref)
    v2 = p1
end

t1.PreInputResult = {}

function t1.PreInputResult.reset() -- line: 28
    -- upvalues: rt (copy), IDENTITY (copy)
    local v3 = rt.copy(IDENTITY)

    v3[4] = { 0, 0, 0, 0 }

    return {
        scalar160 = 0,
        word164 = 0,
        scalar168 = 1E+10,
        scalar172 = 1E+10,
        word176 = 0,
        flags180 = 0,
        position = { 0, 0, 0, 0 },
        normal = { 0, 1, 0, 0 },
        frame = v3,
        vector96 = { 0, 0, 0, 0 },
        vector112 = { 0, 1, 0, 0 },
        vector128 = { 0, 0, 0, 0 },
        vector144 = { 0, 0, 0, 0 }
    }
end

t1.PreInputManager = {}

function t1.PreInputManager.new() -- line: 51
    -- upvalues: t1 (copy)
    return {
        pending_geometry = false,
        result = t1.PreInputResult.reset(),
        result_counts = { 0, 0, 0 }
    }
end

local v4
local v5 = table.freeze({ 0, 0, 0 })

function t1.PreInputManager.prepare(p2, p3) -- line: 69
    -- upvalues: v1 (copy), assign_into (copy), t1 (copy), v2 (ref), v4 (ref), v5 (copy)
    local result, result_counts = p2.result, p2.result_counts
    local v6, v7

    if v2 then
        v7 = true
    elseif type(result) == "table" and type(result_counts) == "table" then
        v6 = v4

        if v6 == nil then
            v6 = v1.freeze_deep(t1.PreInputResult.reset())
            v4 = v6
        end

        v7 = false
    else
        v7 = true
    end

    if v7 then
        return t1.PreInputManager.prepare_reference(p2, p3)
    end

    assign_into(result, v6)
    assign_into(result_counts, v5)

    if p2.pending_geometry then
        error("Pending82D811C8 trajectory batch requires its complete82D81610 geometry consumer", 0)
    end

    return 30
end

function t1.PreInputManager.prepare_reference(p4, _) -- line: 89
    -- upvalues: t1 (copy)
    p4.result = t1.PreInputResult.reset()
    p4.result_counts = { 0, 0, 0 }

    if p4.pending_geometry then
        error("Pending82D811C8 trajectory batch requires its complete82D81610 geometry consumer", 0)
    end

    return 30
end

return t1
