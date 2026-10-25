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
local v2 = import("skate_game/graph_host/motion_animation")
local v3 = import("skate_game/graph_host/motion_channels")
local PointGraph = import("skate_core/point_graph").PointGraph
local Collections = import("skate_data/collections").Collections
local MotionAnimation = v2.MotionAnimation
local MotionChannels = v3.MotionChannels
local t1 = {}

t1.FRONT = "IA_BODYSPIN_OLLIE_FS_0_N"
t1.BACK = "IA_BODYSPIN_OLLIE_BS_0_N"
t1.Settings = {}

function t1.Settings.load(p2) -- line: 36
    -- upvalues: v1 (copy), Collections (copy)
    local function float(p3) -- line: 38
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "anim_motion", "body_spin", p3)
    end

    local v4 = Collections.words(p2, "anim_motion", "body_spin", "spin_map", 16)
    local v5 = Collections.words(p2, "animation", "default", "LandingDistanceScalarVsNormalY", 16)
    local t2 = {}
    local t3 = {}

    buffer.writeu32(v1, 0, v4[1])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[2])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[3])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[4])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[5])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[6])

    local v17 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[7])

    local v19 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[8])
    t3.x = {
        v7,
        v9,
        v11,
        v13,
        v15,
        v17,
        v19,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v4[9])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[10])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[11])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[12])

    local v28 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[13])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[14])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[15])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[16])
    t3.y = {
        v22,
        v24,
        v26,
        v28,
        v30,
        v32,
        v34,
        (buffer.readf32(v1, 0))
    }
    t2.map = t3
    t2.blend_out = Collections.float(p2, "anim_motion", "body_spin", "spin_influence_blendout")
    t2.blend_in = Collections.float(p2, "anim_motion", "body_spin", "spin_influence_blendin")
    t2.maximum_acceleration = Collections.float(p2, "anim_motion", "body_spin", "spin_clamp_influence_deltadelta")
    t2.maximum_delta = Collections.float(p2, "anim_motion", "body_spin", "spin_clamp_influence_delta")
    t2.final_height = Collections.float(p2, "anim_motion", "inair_disttocog", "preland_final_disttocom")
    t2.height_velocity = Collections.float(p2, "anim_motion", "inair_disttocog", "preland_disttocom_vel")
    t2.on_deck_height = Collections.float(p2, "anim_motion", "inair_disttocog", "landingondeck_disttocog")
    t2.override_x = Collections.float(p2, "anim_motion", "body_tilt", "overide_preland_x")
    t2.override_velocity_y = Collections.float(p2, "anim_motion", "body_tilt", "overide_preland_velY")

    local t4 = {}

    buffer.writeu32(v1, 0, v5[1])

    local v37 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[2])

    local v39 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[3])

    local v41 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[4])

    local v43 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[5])

    local v45 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[6])

    local v47 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[7])

    local v49 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[8])
    t4.x = {
        v37,
        v39,
        v41,
        v43,
        v45,
        v47,
        v49,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v5[9])

    local v52 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[10])

    local v54 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[11])

    local v56 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[12])

    local v58 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[13])

    local v60 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[14])

    local v62 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[15])

    local v64 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[16])
    t4.y = {
        v52,
        v54,
        v56,
        v58,
        v60,
        v62,
        v64,
        (buffer.readf32(v1, 0))
    }
    t2.landing_distance = t4

    return t2
end

t1.PrelandingPhysical = {}

function t1.PrelandingPhysical.override_prelanding(p4, p5) -- line: 110
    local air_444 = p4.air_444

    if not air_444 then
        air_444 = false

        if p4.air_normal_144_y <= 0.5 and math.abs(p4.animation_16_x) > p5.override_x then
            air_444 = p4.com_velocity_y > p5.override_velocity_y
        end
    end

    return air_444
end

function t1.PrelandingPhysical.near_landing(p6, p7) -- line: 119
    -- upvalues: PointGraph (copy), t1 (copy)
    if t1.PrelandingPhysical.override_prelanding(p6, p7) or p6.com_velocity_y >= 0 then
        return false
    end

    if p6.offboard_316 then
        return p6.offboard_time_32 < (p7.final_height - p7.on_deck_height) / p7.height_velocity
    end

    if p6.air_437 then
        return (p7.final_height - p6.animation_height_72) / p7.height_velocity * PointGraph.evaluate(p7.landing_distance, t1.clamp(p6.air_normal_36, 0, 1)) > p6.air_remaining_184
    end

    return p6.offboard_319 and p6.offboard_time_32 < 1.2000000476837158
end

t1.State = {}

function t1.State.default() -- line: 138
    return {
        mode = 0,
        previous_spin = 0,
        back = 0,
        back_delta = 0,
        front = 0,
        front_delta = 0
    }
end

function t1.State.update(p8, p9, p10, p11, p12, p13, p14, p15, p16) -- line: 152
    -- upvalues: rt (copy), PointGraph (copy), t1 (copy), MotionAnimation (copy), MotionChannels (copy)
    local FRONT, BACK = t1.FRONT, t1.BACK
    local v66 = p11 == 503
    local v67 = p10 == 2 or v66
    local v68 = v67 or p12
    local v69 = p13[1] ~= 0 or p13[2] ~= 0
    local BodySpin = MotionAnimation.motion_intent(p9, "BodySpin")

    if BodySpin == nil then
        BodySpin = 0
    end

    if p14 then
        BodySpin = -BodySpin
    end

    local v70 = PointGraph.evaluate(p16.map, (math.abs(BodySpin)))

    if not (BodySpin >= 0) then
        v70 = -v70
    end

    local v71 = false

    if v67 then
        if p15 == nil then
            error("BodySpin airborne branch requires actual prelanding physical outputs", 0)
        end

        v71 = t1.PrelandingPhysical.near_landing(p15, p16)
    end

    local mode = p8.mode

    if mode == 0 then
        local v72 = if p10 == 3 then 4 else mode

        mode = if not v68 then v72 elseif v69 then 4 else 1
    elseif mode == 1 then
        local v73 = if v68 then mode else 0

        mode = if v69 then 4 else v73

        if math.abs(BodySpin) > 0.30000001192092896 then
            mode = 2
        end
    elseif mode == 2 then
        local v74 = if v68 then mode else 0

        mode = if v69 then 4 else v74

        if v67 then
            mode = 3
        end
    elseif mode == 3 then
        local v75 = if v69 or v71 and v66 then 4 else mode

        mode = if v67 then v75 else 0
    elseif mode == 4 and not v68 and p10 == 1 then
        mode = 0
    end

    if mode == 0 or mode == 4 then
        MotionChannels.end_with(p9.channels, FRONT, 0.20000000298023224, false)
        MotionChannels.end_with(p9.channels, BACK, 0.20000000298023224, false)
    elseif mode == 1 then
        p8.front = 0
        p8.front_delta = 0
        p8.back = 0
        p8.back_delta = 0
    else
        local v76 = false
        local v77 = false
        local v78 = false
        local v79 = false
        local v80 = false

        if mode == 2 then
            v77 = true
        else
            v76 = true
        end

        if v76 then
            if mode == 3 then
                v77 = true
            else
                v80 = true
            end
        end

        v76 = false

        if v77 then
            if mode == 2 then
                v76 = true
            else
                v80 = false
            end
        end

        v77 = false

        local t5

        if v76 then
            t5 = {
                priority = 0,
                keep_alive = false,
                mirrored = false,
                speed = 1,
                blend_in = 0.20000000298023224,
                hold_during_blend_in = false,
                blend_out = 0.30000001192092896,
                hold_during_blend_out = false,
                use_attributes = false
            }

            if BodySpin > 0.30000001192092896 then
                v77 = true
            else
                v78 = true
            end
        end

        v76 = false

        if v77 then
            if MotionChannels.has(p9.channels, FRONT) then
                v79 = true
            else
                v76 = true
            end
        end

        v77 = false

        if v76 then
            if v71 then
                v79 = true
            else
                v77 = true
            end
        end

        if v77 then
            v79 = true
            MotionAnimation.new_channel(p9, FRONT, FRONT, rt.copy(t5))
        end

        v77 = false

        if v79 then
            v78 = true
            MotionChannels.end_with(p9.channels, BACK, 0.15000000596046448, false)
        end

        v79 = false

        if v78 then
            if BodySpin < -0.30000001192092896 then
                v77 = true
            else
                v80 = false
            end
        end

        v78 = false

        if v77 then
            if MotionChannels.has(p9.channels, BACK) then
                v79 = true
            else
                v78 = true
            end
        end

        v77 = false

        if v78 then
            if v71 then
                v79 = true
            else
                v77 = true
            end
        end

        if v77 then
            v79 = true
            MotionAnimation.new_channel(p9, BACK, BACK, rt.copy(t5))
        end

        if v79 then
            v80 = false
            MotionChannels.end_with(p9.channels, FRONT, 0.15000000596046448, false)
        end

        if not v80 then
            if MotionChannels.has(p9.channels, FRONT) then
                local v81 = t1.clamp(v70, 0, 1)
                local v82 = if v81 < p8.front then p16.blend_out else p16.blend_in
                local v83, v84 = t1.update_influence(p8.front, p8.front_delta, v81, v82, p16)

                p8.front = v83
                p8.front_delta = v84
                MotionChannels.influence(p9.channels, FRONT, p8.front)
            end

            if MotionChannels.has(p9.channels, BACK) then
                local v85 = -t1.clamp(v70, -1, 0)
                local v86 = if p8.back < v85 then p16.blend_out else p16.blend_in
                local v87, v88 = t1.update_influence(p8.back, p8.back_delta, v85, v86, p16)

                p8.back = v87
                p8.back_delta = v88
                MotionChannels.influence(p9.channels, BACK, p8.back)
            end
        end
    end

    p8.mode = mode
    p8.previous_spin = BodySpin
end

function t1.update_influence(p17, p18, p19, p20, p21) -- line: 300
    -- upvalues: t1 (copy)
    local v89 = p20 * p19 + (1 - p20) * p17 - p17
    local v90 = t1.clamp(v89, p18 - p21.maximum_acceleration, p18 + p21.maximum_acceleration)
    local v91 = t1.clamp(p17 + v90, p17 - p21.maximum_delta, p17 + p21.maximum_delta)

    return t1.clamp(v91, 0, 1), v90
end

function t1.clamp(p22, p23, p24) -- line: 310
    local v92 = if p23 - p22 >= 0 then p23 else p22

    if p24 - v92 >= 0 then
        return v92
    end

    return p24
end

return t1
