-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/ground_sync/math")
local dot, scale, sub, madd = v1.dot, v1.scale, v1.sub, v1.madd
local cross, normalize_unchecked, normalize_or = v1.cross, v1.normalize_unchecked, v1.normalize_or
local v2 = import("skate_core/player/offboard/ground_query")
local Vector3 = import("skate_core/math").Vector3
local v3 = import("skate_core/trigonometry")
local t1 = {
    CompletedMotion = {},
    Processed = {},
    BoardSettings = {},
    Bounds = {},
    BoardLimits = {},
    ToolkitInput = {},
    Services = {},
    wants_air = function(p1, p2, p3) -- wants_air | line: 80
        local v4 = bit32.band(p2.contact_flags_368, 1) == 0 and p3.elapsed_2664 > 0.05000000074505806 or p2.launch_1076
        local contact_flags_368_2 = p2.contact_flags_368
        local v5
        local v6 = v4

        if bit32.band(contact_flags_368_2, 8) == 0 then
            if bit32.band(p3.flags_2480, 131456) == 0 and not p1.flags_144_to_150[7] then
                v5 = v4 or bit32.band(p3.flags_2476, 524288) ~= 0
                v6 = v5
            end
        end

        return v6
    end,
    board_bounds = function(p4, p5, p6) -- board_bounds | line: 94
        -- upvalues: rt (copy), madd (copy), cross (copy), normalize_or (copy)
        local v7 = rt.copy(p4[3])

        v7[2] = 0

        local v8 = normalize_or(v7, { 0, 0, 1, 0 })
        local t2 = {
            0, 1, 0, 0
        }

        return {
            frame = {
                cross(t2, v8),
                t2,
                v8,
                (madd(t2, p5[2], madd(v8, p5[3] + p6[3], p4[4])))
            },
            extents = rt.copy(p6)
        }
    end
}

function t1.update_board(p7, p8) -- line: 105
    -- upvalues: rt (copy), scale (copy), t1 (copy)
    local v9 = p8.board_settings(p8)
    local v10 = rt.copy(p8.processed(p8).frame_192)
    local v11 = t1.board_bounds(v10, v9.offset_32, v9.extent_16)
    local v12 = rt.copy(p8.processed(p8).position_592)

    if bit32.band(p8.board_flags_12836(p8), 64) ~= 0 then
        local v14 = p8.probe_board(p8, v12)

        if v14 ~= nil then
            local v15 = p8.board_settings(p8)
            local v16 = rt.copy(p8.processed(p8).frame_192)
            local v17 = t1.board_bounds(v16, v15.offset_32, scale(v15.extent_0, 0.949999988079071))
            local v18 = p8.board_settings(p8)
            local v19 = t1.limits(v18.margin_444, v18.angle_452, v18.angle_436)
            local v20 = p8.bone_23_position(p8)

            p7.flags_144_to_150[1] = p8.classify_board(p8, v14, v20, v17, v19)

            if p7.flags_144_to_150[1] then
                local v21 = p8.candidate_key_188(p8, v14)

                p7.counter_152 = v21[1]
                p7.counter_156 = v21[2]
            end
        end
    end

    local v22 = p8.board_settings(p8)

    p8.query_board(p8, v12, v11, t1.limits(v22.margin_444, v22.angle_456, v22.angle_440))

    if p7.flags_144_to_150[1] then
        p8.bind_board(p8, {
            p7.counter_152,
            p7.counter_156
        })
        p8.commit_bound_board(p8)
    else
        p8.commit_free_board(p8, v10)
    end
end

function t1.limits(p9, p10, p11) -- line: 144
    return {
        margin = p9,
        angle_a = p10 * 0.01745329238474369,
        angle_b = p11 * 0.01745329238474369
    }
end

function t1.sync(p12, p13, p14) -- line: 152
    -- upvalues: rt (copy), dot (copy), scale (copy), sub (copy), madd (copy), cross (copy), normalize_unchecked (copy), v2 (copy), v3 (copy), t1 (copy)
    p12.flags_144_to_150[3] = t1.wants_air(p12, p13, p14.processed(p14))

    if p12.flags_144_to_150[3] then
        local v23 = p14.prepare_biped_launch(p14)
        local v24 = p14.skeleton_point_10960(p14)
        local v25 = rt.copy(p13.animation_frame_912)
        local v26 = madd(v25[3], v24[3], madd(v25[2], v24[2], madd(v25[1], v24[1], v25[4])))

        p14.launch_air(p14, v23, v26)
    end

    p12.flags_144_to_150[1] = false
    p12.flags_144_to_150[4] = p13.flag_1077
    p12.frame_80 = rt.copy(p13.physical_frame_848)

    if bit32.band(p13.contact_flags_368, 1) ~= 0 then
        local v27 = rt.copy(p12.frame_80[2])
        local v28 = dot(sub(p13.contact_position_192, p12.frame_80[4]), v27)

        if not (v28 <= 0) then
            p12.frame_80[4] = madd(v27, v28, p12.frame_80[4])
        end
    end

    local v29 = rt.copy(p13.animation_frame_912)

    if p12.flags_144_to_150[7] then
        p12.duration_180 -= 0.01666666753590107

        if not (p12.duration_180 > 0) then
            p12.duration_180 = 0
            p12.flags_144_to_150[7] = false
        end

        p12.angle_172 *= 0.8999999761581421

        local v30 = -p12.angular_velocity_176 * p12.duration_180 + p12.angle_172
        local v31, v32 = v3.sin_cos(v30)
        local v33 = madd({ v31, 0, v32, v31 }, v29[3][3], madd({ 0, 1, 0, 0 }, v29[3][2], scale({ v32, 0, -v31, v32 }, v29[3][1])))
        local v34 = normalize_unchecked(cross(v29[2], v33))

        v29[1] = rt.copy(v34)
        v29[2] = normalize_unchecked(cross(v33, v34))
        v29[3] = v33
    end

    p14.update_skeleton(p14, rt.copy(v29), rt.copy(p13.vector_1056))

    local v35 = p14.processed(p14)

    if bit32.band(v35.flags_2484, 536870912) == 0 and bit32.band(v35.flags_2480, 262144) == 0 and not (v35.value_2852 > 0) then
        if bit32.band(v35.flags_2476, 4194304) == 0 then
            p14.reset_board(p14)
        elseif p12.flags_144_to_150[5] then
            if not (v35.elapsed_2664 <= 0.5) then
                p12.flags_144_to_150[5] = false
            end
        else
            t1.update_board(p12, p14)
        end
    end

    p14.update_toolkit(p14, {
        {
            rt.copy(p12.frame_80[4]),
            rt.copy(p13.vector_1008),
            rt.copy(p13.vector_992),
            rt.copy(p13.vector_976),
            rt.copy(p13.vector_1040),
            rt.copy(v29[2]),
            rt.copy(v29[1])
        }
    })

    local v36 = p14.processed(p14)
    local v37 = t1.query_frame(p12.frame_80)
    local v38 = v2.edge_search(v37, v36.query_context, t1.xyz(p13.vector_1040), v36.flags_2488)
    local v39 = p14.edge_candidates(p14, v38)
    local v40 = v2.select_edge(v38, v39)
    local v41 = v40 == nil
    local v42, v43

    if not v41 then
        v42 = v2.prepare_packet(v37, v36.query_context, v40, p14.deck_half_wheelbase(p14))
        v43 = v42 == nil
    end

    if v41 or v43 then
        return false
    end

    p14.submit_ground_query(p14, v42)

    return true
end

function t1.xyz(p15) -- line: 236
    -- upvalues: Vector3 (copy)
    return Vector3.new(p15[1], p15[2], p15[3])
end

function t1.query_frame(p16) -- line: 240
    -- upvalues: t1 (copy)
    return {
        right = t1.xyz(p16[1]),
        up = t1.xyz(p16[2]),
        forward = t1.xyz(p16[3]),
        position = t1.xyz(p16[4])
    }
end

return t1
