-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/air_reckoning/settings")
local v2 = import("skate_core/air/reckoning")
local AirState = v2.AirState
local t1 = {
    AirReckoning = {}
}

function t1.AirReckoning.adopt_mode_settings(p1, p2) -- line: 19
    p1.modes = p2.modes
end

function t1.AirReckoning.update_plant(p3, p4, p5, p6, p7) -- line: 23
    -- upvalues: v2 (copy)
    v2.update_plant(p4.reckoning, p4.reckoning_frames, p4.body_spin, p3.state, p3.settings, p6, p7, bit32.band(p5.flags_2468, 1048576) ~= 0)
end

function t1.AirReckoning.load(p8) -- line: 37
    -- upvalues: v1 (copy), AirState (copy)
    local v3, v4 = v1.load(p8)

    return {
        state = AirState.new(),
        settings = v3,
        modes = v4
    }
end

function t1.AirReckoning.fields(p9, p10) -- line: 49
    local up, ground_normal = p10.reckoning.up, p10.reckoning.ground_normal

    return {
        current_landing_normal_1152 = {
            up.x,
            up.y,
            up.z,
            0
        },
        collision_reference_normal_1216 = {
            ground_normal.x,
            ground_normal.y,
            ground_normal.z,
            0
        },
        body_spin_angle_1568 = p9.state.spin_angle,
        body_spin_speed_1572 = p9.state.spin_speed
    }
end

function t1.AirReckoning.update(p11, p12, p13, p14, p15, p16, p17, p18) -- line: 63
    -- upvalues: rt (copy), v2 (copy), t1 (copy)
    local v5 = p11.modes[p13.state_variant_index_2528 + 1]

    if v5 == nil then
        error(string.format("Undefined physics mode %d", p13.state_variant_index_2528), 0)
    end

    v2.update(p12.reckoning, p12.reckoning_frames, p12.body_spin, p11.state, p11.settings, {
        landing_normal = rt.copy(p15),
        normal_blend = p16,
        target_spin = p17,
        flip_request = p18,
        com_to_deck = rt.map(p13.animation_com_to_deck_752, rt.from_bits),
        timestep = p13.timestep_2604,
        physical_body_spin = p14,
        grind_adjusted_body_spin = p13.grind_adjusted_body_spin_2644,
        additive_spin = bit32.band(p13.flags_2484, 32768) ~= 0,
        direct_spin = bit32.band(p13.flags_2472, 268435456) ~= 0,
        reverse_stance = bit32.band(p13.flags_2468, 1048576) ~= 0,
        easy_body_spins = v5.easy_body_spins,
        perfect_body_flips = v5.perfect_body_flips
    })

    return t1.AirReckoning.fields(p11, p12)
end

return t1
