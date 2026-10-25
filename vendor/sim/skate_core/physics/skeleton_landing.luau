-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_board_offset")
local v2 = import("skate_core/point_graph")
local SkateboardOffset = v1.SkateboardOffset
local PointGraph = v2.PointGraph
local t1 = {
    STEP = 0.01666666753590107
}
local STEP = t1.STEP

t1.LandingSettings = {}
t1.LandingInput = {}
t1.LandingAdjustment = {}

function t1.LandingAdjustment.default() -- line: 39
    -- upvalues: rt (copy)
    return {
        active = false,
        kind = 0,
        time = 0,
        position = 0,
        velocity = 0,
        previous_com_velocity = 0,
        previous_filtered_state = 0,
        desired_grind_com = 0,
        previous_animation_height = rt.F32_MAX
    }
end

function t1.LandingAdjustment.update(p1, p2, p3, p4) -- line: 54
    -- upvalues: rt (copy), SkateboardOffset (copy), PointGraph (copy), t1 (copy), STEP (copy)
    local select = t1.select
    local v3 = p1.previous_filtered_state == 6 and p2.filtered_state == 1
    local v4 = p1.previous_filtered_state == 2 and p2.filtered_state == 1
    local v5 = if v3 or v4 then bit32.band(p2.flags_2476, 268435456) ~= 0 else v4
    local v6 = v4 and p2.balance ~= 0
    local v7 = p1.previous_filtered_state == 2 and p2.filtered_state == 3 and bit32.band(p2.flags_2468, 32) == 0
    local v8 = bit32.band(p2.flags_2472, 1) ~= 0
    local v9 = v8 and (v7 or v4)
    local flags_2476 = p2.flags_2476
    local v10

    if bit32.band(flags_2476, 1073741824) ~= 0 and not v8 then
        v10 = false
        p1.active = false
    elseif p1.active then
        v10 = false
    elseif v5 or v9 or v6 or v7 then
        p1.time = 0
        p1.active = true

        if v9 then
            p1.kind = 3
        elseif v6 then
            p1.kind = 2
        elseif v5 then
            p1.kind = 0
        else
            p1.kind = 1
        end

        v10 = p1.kind == 0

        local v11 = if v7 or v9 then p1.previous_com_velocity else p2.physical_com_velocity_along_up
        local v12 = select(-p3.maximum_velocity - v11, -p3.maximum_velocity, v11)

        p1.velocity = select(-v12, v12, 0)
        p1.previous_animation_height = rt.F32_MAX
        p1.position = p2.physical_com_height
    else
        v10 = false
    end

    if p1.active then
        local ground_spring, ground_damping, v13, v14, v15

        if p1.kind == 0 then
            ground_spring = p3.ground_spring
            ground_damping = p3.ground_damping
            v13 = p2.filtered_state ~= 1 or bit32.band(p2.flags_2476, 268435456) == 0
            v14 = false
            v15 = 1
        else
            if p1.kind == 1 then
                ground_spring = p3.grind_spring
                ground_damping = p3.grind_damping
                v15 = PointGraph.evaluate(p3.grind_blend, p1.time)
                v13 = p2.filtered_state ~= 3
            elseif p1.kind == 2 then
                ground_spring = p3.manual_spring
                ground_damping = p3.manual_damping
                v15 = PointGraph.evaluate(p3.manual_blend, p1.time)
                v13 = p2.filtered_state ~= 1
            else
                if p1.kind == 3 then
                    v13 = p2.filtered_state ~= 1 or p1.time > p3.coffin_time or not v8
                    v15 = 1
                else
                    v13 = false
                    v15 = 0
                end

                ground_damping = 0
                ground_spring = 0
            end

            v14 = true
        end

        local animation_com_height = p2.animation_com_height

        if p1.kind == 3 then
            local v16 = math.abs(p1.velocity) / p3.coffin_maximum_velocity
            local v17 = select(-v16, 0, v16)
            local v18 = select(1 - v17, v17, 1)

            p1.position = PointGraph.evaluate(p3.coffin_height, p1.time / p3.coffin_time) * v18 + p3.coffin_base_height
        else
            local desired_com_height = p3.desired_com_height

            if p1.kind == 1 then
                if p1.time > p3.grind_animation_target_time then
                    local v19 = p1.desired_grind_com - p3.grind_target_delta
                    local v20 = p1.desired_grind_com + p3.grind_target_delta
                    local v21 = select(v19 - animation_com_height, v19, animation_com_height)

                    desired_com_height = select(v20 - v21, v21, v20)
                end

                p1.desired_grind_com = desired_com_height
            end

            local v22 = p1.position - desired_com_height
            local velocity = p1.velocity
            local v23 = -(v22 * ground_spring)
            local v24 = -(velocity * ground_damping + -v23) * STEP + velocity
            local v25 = select(-p3.maximum_velocity - v24, -p3.maximum_velocity, v24)
            local v26 = if v14 then p3.maximum_velocity else 0

            p1.velocity = select(v26 - v25, v25, v26)

            local v27 = (p1.velocity + velocity) * 0.5 * STEP + v22 + desired_com_height

            p1.position = select(v27 - p3.minimum_height, v27, p3.minimum_height)
        end

        local v28 = animation_com_height - p1.position

        if v10 then
            local v29 = p1.velocity * 0.014999999664723873
            local v30 = select(-0.1 - v29, -0.1, v29)
            local v31 = select(-v30, v30, 0) + v28

            v28 = select(v31, v31, 0)
        end

        if p1.kind == 0 and p1.time > p3.ground_minimum_compression_time and p1.previous_animation_height < animation_com_height and v28 > 0 then
            v13 = true
        end

        if p1.kind == 1 and bit32.band(p2.flags_2468, 32) ~= 0 then
            v13 = true
        end

        if p1.time > 1.5 then
            v13 = true
        end

        local v32 = bit32.band(p2.flags_2468, 2097152) ~= 0

        if (v13 or not (v15 >= 0.05)) and not v32 then
            p1.active = false
        else
            local v33 = if p1.kind == 3 then p3.coffin_blend_frames else 15

            if v32 then
                v33 = 6
                p1.active = false
            end

            SkateboardOffset.refresh_height(p4, v28 * v15, v33)
        end

        p1.time += STEP
        p1.previous_animation_height = animation_com_height
    end

    p1.previous_com_velocity = p2.physical_com_velocity_along_up
    p1.previous_filtered_state = p2.filtered_state
end

function t1.select(p5, p6, p7) -- line: 201
    if p5 >= 0 then
        return p6
    end

    return p7
end

return t1
