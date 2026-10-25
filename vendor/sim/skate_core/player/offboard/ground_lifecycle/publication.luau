-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)

local function ground_lifecycle() -- line: 8
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/ground_lifecycle")
end

local t1 = {
    PublicationInput = {},
    Publication = {}
}

function t1.Publication.eq(p1, p2) -- line: 50
    if p1.animation_vector_144[1] ~= p2.animation_vector_144[1]
        or p1.animation_vector_144[2] ~= p2.animation_vector_144[2]
        or p1.animation_vector_144[3] ~= p2.animation_vector_144[3]
        or p1.animation_vector_144[4] ~= p2.animation_vector_144[4]
        or p1.physics_counter_36 ~= p2.physics_counter_36
        or p1.physics_counter_40 ~= p2.physics_counter_40
        or p1.physics_flag_86 ~= p2.physics_flag_86
        or p1.offboard_flag_304 ~= p2.offboard_flag_304
        or p1.offboard_kind_88 ~= p2.offboard_kind_88
        or p1.offboard_scalar_112 ~= p2.offboard_scalar_112
        or p1.offboard_flag_329 ~= p2.offboard_flag_329
        or p1.offboard_flag_330 ~= p2.offboard_flag_330
        or p1.offboard_distance_116 ~= p2.offboard_distance_116
        or p1.offboard_flag_334 ~= p2.offboard_flag_334
        or p1.offboard_scalar_32 ~= p2.offboard_scalar_32
        or p1.offboard_flag_328 ~= p2.offboard_flag_328
        or p1.animation_flag_164 ~= p2.animation_flag_164
        or p1.offboard_hand_flags_306_307[1] ~= p2.offboard_hand_flags_306_307[1] then
        return false
    end

    return p1.offboard_hand_flags_306_307[2] == p2.offboard_hand_flags_306_307[2]
end

function t1.publish(p3, p4) -- line: 74
    -- upvalues: import (copy)
    local v1 = import("skate_core/player/offboard/ground_lifecycle")
    local length = v1.length
    local v2 = p4.ground_flags_752_to_754[2] or not (p3.distance_164 >= 0.0833333358168602)
    local v3 = p3.flags_144_to_150[4]

    if not v3 then
        v3 = bit32.band(p4.contact_flags_368, 8) ~= 0
    end

    local v4 = p4.ground_flags_752_to_754[1]
    local v5 = if v4 then bit32.band(p4.contact_flags_368, 1) == 0 else nil
    local v6 = if not v4 or v5 then 1E+10 else length({
        p4.contact_position_192[1] - p4.query_position_816[1],
        p4.contact_position_192[2] - p4.query_position_816[2],
        p4.contact_position_192[3] - p4.query_position_816[3],
        p4.contact_position_192[4] - p4.query_position_816[4]
    })
    local v7 = v1.dot(p4.motion_up_864, p4.motion_vector_1040)
    local v8 = table.create(2)
    local v9 = p4.hand_flags[1]

    v8[1] = v9[1] and not v9[2] or v9[3]

    local v10 = p4.hand_flags[2]

    v8[2] = v10[1] and not v10[2] or v10[3]

    return {
        animation_flag_164 = true,
        physics_counter_36 = p3.counter_152,
        physics_counter_40 = p3.counter_156,
        physics_flag_86 = bit32.band(p4.processed_flags_2476, 4194304) ~= 0 and not p3.flags_144_to_150[1],
        offboard_flag_304 = p3.flags_144_to_150[1],
        offboard_kind_88 = p4.ground_kind_356,
        offboard_scalar_112 = p4.ground_scalar_360,
        offboard_flag_329 = v3,
        offboard_flag_330 = v2 and not v3,
        offboard_distance_116 = v6,
        offboard_flag_334 = p4.ground_flags_752_to_754[3],
        offboard_scalar_32 = p3.flags_144_to_150[3] and 1 or 0,
        offboard_flag_328 = p3.flags_144_to_150[3],
        animation_vector_144 = {
            p4.motion_vector_1040[1] - p4.motion_up_864[1] * v7,
            p4.motion_vector_1040[2] - p4.motion_up_864[2] * v7,
            p4.motion_vector_1040[3] - p4.motion_up_864[3] * v7,
            p4.motion_vector_1040[4] - p4.motion_up_864[4] * v7
        },
        offboard_hand_flags_306_307 = v8
    }
end

return t1
