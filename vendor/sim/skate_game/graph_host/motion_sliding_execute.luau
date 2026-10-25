-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/graph_host/motion_animation")
local v2 = import("skate_game/graph_host/motion_sliding")
local v3 = import("skate_core/input/set_turning")
local encode = import("skate_core/animation/skeleton_input/name").encode
local MotionAnimation = v1.MotionAnimation
local SlideLatch = v3.SlideLatch
local t1 = {
    MotionHost = {}
}

function t1.MotionHost.execute_slide(p1, p2, p3, p4, p5) -- line: 28
    -- upvalues: rt (copy), v2 (copy), encode (copy), t1 (copy), MotionAnimation (copy), SlideLatch (copy)
    local tag = p3.tag

    if tag == "Update" and p5 == 1 then
        local physical_state = p1.condition_inputs.physical_state

        if physical_state == nil then
            error("PowerSliding requires actual filtered physical category", 0)
        end

        local category = physical_state.category
        local v4, v5

        if category == 1 then
            local fakie_physical = p1.fakie_physical

            if fakie_physical == nil then
                error("PowerSliding requires actual Motion164 speed", 0)
            end

            v4 = fakie_physical.ground_projected_speed
            v5 = t1.MotionHost.slide_direction(p1)
        else
            v4 = 0
            v5 = 0
        end

        local v6 = p1.instances[p2 + 1]

        if v6 == nil then
            error(string.format("index out of bounds: the len is %d but the index is %d", #p1.instances, p2), 0)
        end

        if v6.tag ~= "Sliding" then
            error("PowerSliding has an invalid instance", 0)
        end

        local v7 = v6[1]

        v2.State.update(v7, p1.animation, category, v4, v5, p4.dt, p1.sliding, p1.slide_latch)
    elseif tag == "Create" then
        local right = p3.right

        if p5 == 0 then
            local skater_animation_flags = p1.animation.skater_animation_flags

            if skater_animation_flags == nil then
                error("CreateSlide requires actual animation stance flags", 0)
            end

            local v8 = bit32.band(skater_animation_flags, 536870912) ~= 0

            SlideLatch.begin_slide(p1.slide_latch, v8)
        elseif p5 == 1 then
            local v9 = v2.create(p1.slide_latch, right, MotionAnimation.motion_intent(p1.animation, "RightSlide"), MotionAnimation.motion_intent(p1.animation, "LeftSlide"), p1.sliding)

            MotionAnimation.emit_packet(p1.animation, encode("slide"), v9[1])
            MotionAnimation.emit_packet(p1.animation, encode("turn"), v9[2])
        end
    elseif tag == "ManualAttribute" and p5 == 1 then
        local Manual = MotionAnimation.motion_intent(p1.animation, "Manual")

        if Manual ~= nil and Manual < 0 then
            MotionAnimation.emit_packet(p1.animation, encode("balance"), Manual)
        end
    elseif tag == "Deceleration" then
        local v10 = p1.instances[p2 + 1]

        if v10 == nil then
            error(string.format("index out of bounds: the len is %d but the index is %d", #p1.instances, p2), 0)
        end

        if v10.tag ~= "SlideDeceleration" then
            error("PowerSlideDecel has an invalid instance", 0)
        end

        if p5 == 0 then
            v10[1] = 0
        elseif p5 == 1 then
            local fakie_physical = p1.fakie_physical

            if fakie_physical == nil then
                error("PowerSlideDecel requires actual Motion80 velocity", 0)
            end

            local v11 = rt.copy(fakie_physical.deck_velocity)
            local native_physical = p1.native_physical

            if native_physical == nil then
                error("PowerSlideDecel requires actual Reckoning Ground frame", 0)
            end

            local v12 = rt.copy(native_physical.board_reckoning)
            local v13, v14 = v2.deceleration(v10[1], v11, v12, p1.sliding)

            v10[1] = v14
            MotionAnimation.set_attribute(p1.animation, {
                normalized = false,
                sequence_id = -1,
                name = encode("decel"),
                value = v13
            })
        end
    elseif tag == "Spin" and p5 == 0 then
        local v15 = v2.spin(t1.MotionHost.slide_direction(p1), p1.sliding)

        MotionAnimation.set_attribute(p1.animation, {
            normalized = false,
            sequence_id = -1,
            name = encode("slidespin"),
            value = v15
        })
    else
        local set_candidate_enabled, slide_latch, v16

        if tag ~= "Candidate" or p5 == 1 then
            if tag == "IsPowerSliding" and p5 ~= 1 then
                local v18 = p5 == 0

                p1.is_power_sliding = v18
            end
        else
            set_candidate_enabled = SlideLatch.set_candidate_enabled
            slide_latch = p1.slide_latch
            v16 = p5 == 0
            set_candidate_enabled(slide_latch, v16)
        end
    end
end

function t1.MotionHost.slide_direction(p6) -- line: 149
    -- upvalues: rt (copy), v2 (copy)
    local fakie_physical = p6.fakie_physical

    if fakie_physical == nil then
        error("Slide direction requires actual Motion80 velocity", 0)
    end

    local v19 = rt.copy(fakie_physical.deck_velocity)
    local foot_frame = if p6.physical == nil then nil else p6.physical.foot_frame

    if foot_frame == nil then
        error("Slide direction requires actual Motion273 orientation flag", 0)
    end

    local skateboard_flipped = foot_frame.skateboard_flipped
    local native_physical = p6.native_physical

    if native_physical == nil then
        error("Slide direction requires actual Reckoning Ground Z", 0)
    end

    local v20 = rt.copy(native_physical.board_reckoning_z)

    return v2.direction(v19, v20, skateboard_flipped)
end

return t1
