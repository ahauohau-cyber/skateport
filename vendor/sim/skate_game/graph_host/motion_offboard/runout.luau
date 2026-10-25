-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/skeleton_input/name")
local v2 = import("skate_core/player/wipeout_state/math")
local v3 = import("skate_core/player/wipeout_state/orientation")
local Attributes = import("skate_data/state_graph/attributes").Attributes
local encode = v1.encode
local t1 = {
    Operation = {}
}

function t1.Operation.eq(_, _) -- line: 23
    return true
end

function t1.Operation.parse(p3) -- line: 28
    -- upvalues: Attributes (copy)
    return if Attributes.text(p3, "name") == "AddRunoutAttribs" then {} else nil
end

t1.Observation = {}
t1.State = {}

function t1.State.default() -- line: 54
    return {
        angle_degrees_8 = 0,
        speed_12 = nil
    }
end

function t1.State.eq(p4, p5) -- line: 62
    if p4.angle_degrees_8 == p5.angle_degrees_8 then
        return p4.speed_12 == p5.speed_12
    end

    return false
end

function t1.State.begin(p6, p7) -- line: 69
    -- upvalues: rt (copy), v2 (copy), v3 (copy)
    if p7 == nil then
        return
    end

    local v4 = if p7.offboard_flag_331 then rt.copy(p7.offboard_velocity_128) else rt.copy(p7.reckoning_velocity_16)
    local v5 = v3.projected_angle(rt.copy(p7.skeleton_vector_0), rt.copy(v4), rt.copy(p7.reckoning_up_96))

    if p7.animation_mirrored then
        v5 = -v5
    end

    p6.speed_12 = v2.length(v4)
    p6.angle_degrees_8 = v2.wrap_angle(v5) * 57.295780181884766
end

function t1.State.update(p8, p9) -- line: 95
    -- upvalues: encode (copy)
    if p9 == nil then
        return
    end

    local speed_12 = p8.speed_12

    if speed_12 == nil then
        error("AddRunoutAttribs speed12 has no successful Begin observation", 0)
    end

    local angle_degrees_8 = p8.angle_degrees_8

    p9.set_attribute(p9, {
        normalized = false,
        sequence_id = -1,
        name = encode("BipedStartAngle"),
        value = angle_degrees_8
    })
    p9.set_attribute(p9, {
        normalized = false,
        sequence_id = -1,
        name = encode("BipedSpeed"),
        value = speed_12
    })
end

return t1
