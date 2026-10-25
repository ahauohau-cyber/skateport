-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local PointGraph = import("skate_core/point_graph").PointGraph
local v1 = import("skate_game/physics/footplant/math")
local STEP, dot, sub, madd = v1.STEP, v1.dot, v1.sub, v1.madd
local length, normalize, point, clamp01 = v1.length, v1.normalize, v1.point, v1.clamp01
local t1 = {}

local function handplant() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

function t1.update(p1, p2) -- line: 29
    -- upvalues: rt (copy), import (copy), PointGraph (copy), STEP (copy), dot (copy), sub (copy), madd (copy), length (copy), normalize (copy), point (copy), clamp01 (copy)
    local processed = p1.player_input.processed
    local handplant = p1.handplant

    if p2 and (bit32.band(processed.flags_2480, 536870912) ~= 0 or bit32.band(processed.flags_2480, 268435456) == 0) then
        import("skate_game/physics/handplant").Handplant.reset_ik(handplant)
    end

    local v4 = if bit32.band(handplant.flags, 536870912) ~= 0 ~= (bit32.band(processed.flags_2476, 4) ~= 0) then 1 else 0
    local v5 = v4 + 2
    local animated_skeleton = p1.animated_skeleton

    local function world(p3) -- line: 45
        -- upvalues: animated_skeleton (copy), point (copy)
        return point(animated_skeleton.roots.animation_to_world, animated_skeleton.record.pose[p3 + 1][4])
    end

    local v6 = v4 * 4 + 3
    local v7 = point(animated_skeleton.roots.animation_to_world, animated_skeleton.record.pose[v6 + 1][4])
    local v8 = v4 * 4 + 6
    local v9 = point(animated_skeleton.roots.animation_to_world, animated_skeleton.record.pose[v8 + 1][4])
    local v10 = handplant.phase > -handplant.settings.hand_release

    if not v10 then
        handplant.ik_released = true
    end

    local v11 = sub(v9, handplant.anchor)
    local v12, v13
    local v14 = v7

    if handplant.ik_released then
    elseif length(v11) > 1.52587890625E-05 then
        v12 = normalize(v11)

        local v15 = dot(sub(v7, handplant.anchor), v12)

        v13 = v7

        if v15 <= 0 then
            handplant.ik_released = true
        else
            v13 = madd(v12, v15, handplant.anchor)

            if not handplant.ik_latched then
                local v16 = sub(v7, v13)
                local v17 = PointGraph.evaluate(handplant.settings.hand_radius, v15)

                v13 = if v17 < length(v16) then madd(normalize(v16), v17, v13) else v7
            end
        end

        local v18 = sub(v13, handplant.anchor)
        local v19 = length(v18)

        if handplant.ik_distance < 0 then
            handplant.ik_distance = v19
        end

        handplant.ik_distance = rt.fmin(v19, handplant.ik_distance - handplant.settings.hand_approach)

        if handplant.ik_distance < 1.52587890625E-05 or v19 < 1.52587890625E-05 then
            v14 = v13
            handplant.ik_released = true
        else
            v14 = madd(normalize(v18), handplant.ik_distance, handplant.anchor)
        end

        if not handplant.ik_released and not handplant.ik_latched and length(sub(v14, (madd(v12, dot(sub(v14, handplant.anchor), v12), handplant.anchor)))) < 0.02 then
            handplant.ik_latched = true
        end
    end

    if handplant.ik_released then
        v14 = rt.copy(handplant.anchor)
    end

    local v21 = sub(v14, v9)

    if length(v21) > 0.65 then
        v14 = madd(normalize(v21), 0.65, v9)
    end

    handplant.ik_blend = clamp01(handplant.ik_blend + (if v10 then STEP / handplant.settings.hand_into else -STEP / handplant.settings.hand_out))

    if not (handplant.ik_blend > 0) then
        return
    end

    local v23 = point(animated_skeleton.roots.animation_to_world, animated_skeleton.targets[v5 + 1][4])
    local v24 = sub(v14, v23)
    local v25 = if length(v24) > 0.65 then madd(normalize(v24), 0.65, v23) else v14

    p1.foot_ik.state.external_targets[v5 + 1].world_position = v25
    p1.foot_ik.state.limbs[v5 + 1].external_target_set = true
    p1.foot_ik.state.limbs[v5 + 1].target_blend = handplant.ik_blend
end

return t1
