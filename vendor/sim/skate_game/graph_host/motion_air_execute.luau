-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/air_leg_extension")
local AttributeName = import("skate_core/animation/output/attributes").AttributeName
local encode = import("skate_core/animation/skeleton_input/name").encode
local v2

local function motion_animation() -- line: 16
    -- upvalues: import (copy), v2 (ref)
    local v3 = v2

    if v3 == nil then
        v3 = import("skate_game/graph_host/motion_animation")
        v2 = v3
    end

    return v3
end

local v4

local function motion_spin() -- line: 25
    -- upvalues: import (copy), v4 (ref)
    local v5 = v4

    if v5 == nil then
        v5 = import("skate_game/graph_host/motion_spin")
        v4 = v5
    end

    return v5
end

local t1 = {
    MotionHost = {}
}

function t1.MotionHost.execute_air(p1, p2, p3, p4, p5) -- line: 45
    -- upvalues: rt (copy), import (copy), v1 (copy), AttributeName (copy), encode (copy), v2 (ref), v4 (ref)
    local v6 = p1.instances[p2 + 1]

    if v6 == nil then
        error("Unallocated airborne MotionGraph behavior", 0)
    end

    if p3.tag == "ClearTrickAttr" then
        if p5 == 2 then
            local construction_values = p1.animation.construction_values
            local Trick = encode("Trick")
            local v7 = #construction_values
            local n1 = 0

            for i = 1, v7 do
                local v8 = construction_values[i]

                if not AttributeName.eq(v8[1], Trick) then
                    n1 += 1
                    construction_values[n1] = v8
                end
            end

            for i = v7, n1 + 1, -1 do
                construction_values[i] = nil
            end
        end
    elseif p3.tag == "AirLeg" and v6.tag == "AirLeg" then
        local v9 = p3[1]
        local v10 = v6[1]

        if p5 == 1 then
            local v11 = v2

            if v11 == nil then
                v11 = import("skate_game/graph_host/motion_animation")
                v2 = v11
            end

            local MotionAnimation = v11.MotionAnimation

            if p1.air_leg_physical == nil then
                error("Air leg extension requires completed physical output", 0)
            end

            local v12 = rt.copy(p1.air_leg_physical)
            local v13 = if v1.State.needs_initial_attribute(v10) then MotionAnimation.last_attribute(p1.animation, rt.copy(v9.height)) else nil
            local v14 = false

            if v1.State.needs_prelanding_query(v10, v12) then
                if p1.prelanding_physical == nil then
                    error("Air leg extension requires actual prelanding output", 0)
                end

                local v15 = v4

                if v15 == nil then
                    v15 = import("skate_game/graph_host/motion_spin")
                    v4 = v15
                end

                local v16 = v15.PrelandingPhysical.near_landing(rt.copy(p1.prelanding_physical), p1.spin)
                local v17 = if v16 then MotionAnimation.last_attribute(p1.animation, encode("FullExtension")) else nil

                v14 = v1.prepare_to_land(v16, v17, v12, p1.air_leg)
            end

            local v18 = v1.State.update(v10, v9.bone, v12, p1.air_leg, p4.dt, v13, v14)
            local v19 = v18[1]
            local v20 = v18[2]

            for _, v21 in {
                    {
                        rt.copy(v9.height),
                        v19
                    },
                    {
                        encode("extend"),
                        v20
                    }
                } do
                MotionAnimation.set_attribute(p1.animation, {
                    normalized = false,
                    sequence_id = -1,
                    name = v21[1],
                    value = v21[2]
                })
            end
        end
    elseif p3.tag ~= "BodySpin" or v6.tag ~= "BodySpin" then
        error("Airborne MotionGraph operation/instance mismatch", 0)
    else
        local v22 = v6[1]

        if p5 == 1 then
            local physical_state = p1.condition_inputs.physical_state

            if physical_state == nil then
                error("BodySpin requires physicalcategory", 0)
            end

            local category = physical_state.category

            if p1.gameplay_conditions == nil then
                error("BodySpin requires physicalstate", 0)
            end

            local state = p1.gameplay_conditions.state
            local doing_trick = p1.flags.doing_trick
            local v23 = rt.copy(p1.hand_services.busy_hands)
            local is_mirrored = p1.playback_context.is_mirrored

            if is_mirrored == nil then
                error("BodySpin requires animstance", 0)
            end

            local v24 = v4

            if v24 == nil then
                v24 = import("skate_game/graph_host/motion_spin")
                v4 = v24
            end

            v24.State.update(v22, p1.animation, category, state, doing_trick, v23, is_mirrored, rt.copy(p1.prelanding_physical), p1.spin)
        end
    end
end

return t1
