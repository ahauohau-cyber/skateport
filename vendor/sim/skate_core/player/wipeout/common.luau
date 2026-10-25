-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Requests = import("skate_core/player/wipeout/requests").Requests
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local t1 = {}

function t1.length(p3) -- line: 34
    -- upvalues: v1 (copy), inverse_length_squared (copy), dot3 (copy)
    local v9 = dot3(p3, p3)
    local v10

    if v9 ~= 0 and v9 > -1.1754943508222875E-38 and v9 < 1.1754943508222875E-38 then
        local v11 = math.abs(v9) * 7.1362384635298E+44
        local v12 = math.floor(v11)
        local v13 = v11 - v12

        v10 = (if v13 > 0.5 or v13 == 0.5 and v12 % 2 == 1 then v12 + 1 else v12) * 1.401298464324817E-45

        if v9 < 0 then
            v10 = -v10
        end
    else
        buffer.writef32(v1, 0, v9)
        v10 = buffer.readf32(v1, 0)
    end

    local v14 = inverse_length_squared(v10, 2)

    if v10 == 0 then
        return 0
    end

    return v10 * v14
end

function t1.selected_max(p4, p5) -- line: 44
    if p4 - p5 >= 0 then
        return p4
    end

    return p5
end

local selected_max2 = t1.selected_max

function t1.force(p6, p7, p8) -- line: 54
    -- upvalues: selected_max2 (copy)
    local regions_force = p6.regions_force
    local v15 = selected_max2(regions_force[1], regions_force[2])
    local v16 = selected_max2(regions_force[6], regions_force[5])
    local v17 = selected_max2(regions_force[8], regions_force[7])

    if p7 < selected_max2(selected_max2(v15, v16), v17) then
        return true
    end

    return p8 < selected_max2(regions_force[3], regions_force[4])
end

function t1.vehicle(p9, p10, p11) -- line: 62
    -- upvalues: Requests (copy)
    if (if bit32.band(p11.flags_2476, 8) == 0 then p10.ground.vehicle_contact else p10.ground.skitch_contact) < p11.vehicle_force then
        Requests.request(p9, 7, 0)
    end
end

function t1.closing(p12, p13, p14, p15) -- line: 75
    -- upvalues: Requests (copy), t1 (copy)
    if p13.board_contact then
        local closing_velocity, world_to_animation = p13.closing_velocity, p13.world_to_animation
        local v18 = world_to_animation[1]
        local v19 = world_to_animation[2]
        local v20 = world_to_animation[3]
        local v21 = closing_velocity[1]
        local v22 = closing_velocity[2]
        local v23 = closing_velocity[3]
        local t2 = {
            v20[1] * v23 + (v19[1] * v22 + v18[1] * v21),
            v20[2] * v23 + (v19[2] * v22 + v18[2] * v21),
            v20[3] * v23 + (v19[3] * v22 + v18[3] * v21),
            v20[4] * v23 + (v19[4] * v22 + v18[4] * v21)
        }
        local v24 = p14 < t1.length({
            t2[1],
            0,
            t2[3],
            t2[4]
        })
        local v25 = if not v24 then p15 < math.abs(t2[2]) else nil

        if v24 or v25 then
            Requests.request(p12, 2, 0)

            if t1.force(p13, 1, 20) then
                Requests.request(p12, 0, 0)
            end
        end
    end
end

function t1.leaning(p16, p17, p18) -- line: 98
    -- upvalues: Requests (copy)
    if p18.animation_up[2] < p17.lean_contact_y and p18.compliant and p18.highest_normal[2] > 0.7070000171661377 then
        Requests.request(p16, 19, 0)
    end
end

return t1
