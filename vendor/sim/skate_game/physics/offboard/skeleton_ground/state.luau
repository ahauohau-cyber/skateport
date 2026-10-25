-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/physics/skeleton_animation_record")
local v3 = import("skate_core/player/offboard/ground_reckoning")
local v4 = import("skate_data/collections")
local IDENTITY = v2.IDENTITY
local Collections = v4.Collections
local t1 = {
    State = {}
}

function t1.State.load(p2) -- line: 36
    -- upvalues: rt (copy), v1 (copy), IDENTITY (copy), Collections (copy)
    local function graph(p3) -- line: 37
        -- upvalues: p2 (copy), rt (copy), v1 (copy), Collections (copy)
        local v5 = Collections.words(p2, "physics_reckoning", "default", p3, 16)
        local v6 = table.create(16)

        for i = 1, 16 do
            buffer.writeu32(v1, 0, v5[i])
            v6[i] = buffer.readf32(v1, 0)
        end

        return {
            x = rt.slice(v6, 0, 8),
            y = rt.slice(v6, 8, 16)
        }
    end

    local v8 = Collections.words(p2, "physics_reckoning", "default", "GroundNormalSmoothing", 4)

    buffer.writeu32(v1, 0, v8[1])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v8[2])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v8[3])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v8[4])

    local t2 = {
        v10,
        v12,
        v14,
        (buffer.readf32(v1, 0))
    }
    local TiltVsRotGround = graph("TiltVsRotGround")
    local TiltVsSlopeGround = graph("TiltVsSlopeGround")

    return {
        retained_board = rt.copy(IDENTITY),
        ground_normal_smoothing = t2,
        tilt_vs_rotation = TiltVsRotGround,
        tilt_vs_slope = TiltVsSlopeGround
    }
end

function t1.State.finish_reckoning(p4, p5, p6, p7, p8, p9) -- line: 71
    -- upvalues: rt (copy), v3 (copy)
    local up = p6.reckoning.up

    return v3.update(p6.reckoning, p6.reckoning_frames, p6.body_spin, p7.state, {
        ground_normal_smoothing = rt.copy(p4.ground_normal_smoothing),
        tilt_vs_rotation = p4.tilt_vs_rotation,
        tilt_vs_slope = p4.tilt_vs_slope
    }, {
        enable_body_spin_input = true,
        previous_up = {
            up.x,
            up.y,
            up.z,
            0
        },
        requested_up = rt.copy(p5.up),
        requested_forward = rt.copy(p5.forward),
        blend = p5.blend,
        reverse_stance = bit32.band(p8.flags_2468, 1048576) ~= 0,
        physical_body_spin_2812 = p9
    })
end

return t1
