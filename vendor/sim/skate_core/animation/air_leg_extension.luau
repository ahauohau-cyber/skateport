-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local PointGraph = import("skate_core/point_graph").PointGraph
local t1 = {
    Bone = {},
    Settings = {},
    Physical = {},
    State = {}
}

function t1.State.default() -- line: 41
    return {
        mode = 0,
        height = 0,
        descending_time = 0
    }
end

local maximum, minimum

function t1.State.needs_initial_attribute(p2) -- line: 48
    return p2.mode == 0
end

function t1.State.needs_prelanding_query(p3, p4) -- line: 53
    if p3.mode == 2 then
        return true
    end

    if p3.mode == 1 then
        return p4.com_velocity[2] < 0
    end

    return false
end

function t1.State.update(p5, p6, p7, p8, p9, p10, p11) -- line: 59
    -- upvalues: v1 (copy), dot3 (copy), PointGraph (copy), t1 (copy), maximum (ref), minimum (ref)
    local v2 = p7.com_velocity[2] > 0
    local mode = p5.mode

    if mode == 0 then
        p5.mode = v2 and 1 or 2

        if p10 ~= nil then
            if p10.kind == 0 then
                local v3 = p10.payload[1][1]

                if v3 == nil then
                    v3 = 0
                end

                buffer.writeu32(v1, 0, v3)
                p5.height = buffer.readf32(v1, 0)
            end
        else
            local right_toe = if p7.offboard_316 or p6 == "RightToe" then p7.right_toe elseif p6 == "LeftToe" then p7.left_toe else nil

            if right_toe ~= nil then
                p5.height = dot3({
                    p7.com_position[1] - right_toe[1],
                    p7.com_position[2] - right_toe[2],
                    p7.com_position[3] - right_toe[3],
                    p7.com_position[4] - right_toe[4]
                }, p7.system_up)
            else
                p5.height = p7.animation_height
            end
        end
    elseif mode == 1 and p7.com_velocity[2] >= 0 then
        p5.height = maximum(-p9 * p8.going_up_speed + p5.height, p8.minimum_height)
    elseif mode == 1 or mode == 2 then
        p5.mode = 2

        if p11 then
            p5.mode = 3
            t1.State.preland(p5, p6, p8, p9)
        else
            local v4 = -dot3(p7.com_velocity, p7.system_up)
            local v6 = math.abs((dot3(p7.system_up, { 0, 1, 0, 0 })))
            local v7 = maximum(v4, 0) * v6 + (1 - v6) * p8.going_down_speed
            local v8 = minimum(v7, p8.going_down_speed)

            p5.height = maximum(-v8 * p9 + p5.height, p8.minimum_height)
        end
    elseif mode == 3 then
        t1.State.preland(p5, p6, p8, p9)
    end

    if v2 then
        p5.descending_time = 0
    else
        p5.descending_time += p9
    end

    return {
        p5.height,
        PointGraph.evaluate(p8.arm_extension, p5.descending_time)
    }
end

function t1.State.preland(p12, p13, p14, p15) -- line: 124
    p12.height = p15 * p14.preland_velocity + p12.height

    if p13 ~= "Board" then
        p12.height *= p14.offboard_multiplier
    end
end

function t1.prepare_to_land(p16, p17, p18, p19) -- line: 133
    -- upvalues: v1 (copy)
    if not p16 then
        return false
    end

    if p17 == nil then
        return true
    end

    local v9 = 0

    if p17.kind == 0 then
        local v10 = p17.payload[1][1]

        if v10 == nil then
            v10 = 0
        end

        buffer.writeu32(v1, 0, v10)
        v9 = buffer.readf32(v1, 0)
    end

    if v9 < p19.preland_final_height - 0.10000000149011612 then
        return true
    end

    return (v9 - p18.animation_height) / p19.preland_velocity > p18.remaining_air_time - 0.05999999865889549
end

function t1.maximum(p20, p21) -- line: 159
    if p20 - p21 >= 0 then
        return p20
    end

    return p21
end

maximum = t1.maximum

function t1.minimum(p22, p23) -- line: 168
    if p23 - p22 >= 0 then
        return p22
    end

    return p23
end

minimum = t1.minimum

return t1
