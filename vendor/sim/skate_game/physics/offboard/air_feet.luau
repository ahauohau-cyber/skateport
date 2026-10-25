-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local v1 = import("skate_core/player/offboard/biped_air/feet")
local v2 = import("skate_core/player/offboard/board_possession/manager")
local FootIkState = import("skate_core/animation/foot_ik/state").FootIkState

return {
    update_air = function(p1, p2) -- update_air | line: 21
        -- upvalues: rt (copy), compose_affine (copy), v1 (copy)
        local processed = p1.player_input.processed
        local v3 = rt.copy(p1.animated_skeleton.roots.animation_to_world)
        local v4 = rt.copy(v3)

        if bit32.band(processed.flags_2476, 4) ~= 0 then
            for _, v5 in { 0, 2 } do
                local t2 = {}

                for v6, v7 in v4[v5 + 1] do
                    t2[v6] = -v7
                end

                v4[v5 + 1] = t2
            end
        end

        local pose = p1.animated_skeleton.record.pose
        local t3 = {}

        for v8, v9 in { 15, 19 } do
            t3[v8] = {
                rt.copy(pose[v9 + 1][4]),
                rt.copy(pose[v9 + 2][4])
            }
        end

        local t4 = {}

        for v10, v11 in { 15, 19 } do
            t4[v10] = {
                compose_affine(v3, pose[v11 + 1])[4],
                compose_affine(v3, pose[v11 + 2])[4]
            }
        end

        for _, v12 in p2.hands do
            v12.scalars_96_100[2] = 0
        end

        p2.words_308_to_316 = { 0, 0, 0 }

        local v14 = v1.update(p2, {
            lines = rt.from_fn(2, function(p3) -- line: 55
                -- upvalues: processed (copy), rt (copy)
                local v13 = processed.line_tests_960_1008_1056[p3 + 1]

                return {
                    position = rt.map(v13.position, rt.from_bits),
                    normal = rt.map(v13.normal, rt.from_bits),
                    surface = v13.surface,
                    valid = v13.valid ~= 0
                }
            end),
            root = v3,
            inverse_root = rt.copy(p1.animated_skeleton.roots.world_to_animation),
            effective_root = v4,
            local_foot_pairs = t3,
            world_foot_pairs = t4,
            position = rt.map(processed.vectors_544_560_592_608[3], rt.from_bits),
            velocity = rt.map(processed.vectors_544_560_592_608[4], rt.from_bits),
            flags_2476 = processed.flags_2476,
            flags_2480 = processed.flags_2480,
            flags_2484 = processed.flags_2484,
            state = processed.state_2508
        })

        if bit32.band(processed.flags_2484, 2147483648) == 0 then
            for i = 0, #v14 - 1 do
                local v15 = v14[i + 1]
                local v16 = p1.foot_ik.state.limbs[i + 1]
                local v17 = p1.foot_ik.state.external_targets[i + 1]

                if v15.world then
                    v17.world_position = rt.copy(v15.position)
                    v16.external_target_set = true
                else
                    v17.animation_position = rt.copy(v15.position)
                    v16.local_target_set = true
                end

                v16.target_blend = v15.blend

                local normal = v15.normal

                if normal ~= nil then
                    v1.set_normal(v17, normal)
                end
            end
        end
    end,
    enter = function(p4, p5) -- enter | line: 99
        -- upvalues: v2 (copy), FootIkState (copy)
        local processed = p4.player_input.processed

        if processed.state_2504 ~= 500 and processed.state_2504 ~= 501 and processed.state_2504 ~= 502 then
            v2.State.reset(p5)
            FootIkState.enable_feet(p4.foot_ik.state, false)

            for _, v18 in p4.foot_ik.state.limbs do
                v18.board_blend = 0
                v18.external_blend = 0
                v18.mode = "Disabled"
            end
        end

        p5.flags_304_to_307[1] = processed.state_2508 == 502
    end,
    publish = function(p6, p7) -- publish | line: 115
        local t6 = {}

        for v19, v20 in p6.hands do
            if v20.flags_104_to_107[2] and not v20.flags_104_to_107[3] or v20.flags_104_to_107[4] then
                t6[v19] = 1
            else
                t6[v19] = 0
            end
        end

        p7.flags_306_307 = t6
    end
}
