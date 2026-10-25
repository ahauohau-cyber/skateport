-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local SlideLatch = import("skate_core/input/set_turning").SlideLatch
local PointGraph = import("skate_core/point_graph").PointGraph
local Collections = import("skate_data/collections").Collections
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v9 = import("skate_core/riding/ground_correction_math")
local v10

local function motion_animation() -- line: 44
    -- upvalues: import (copy), v10 (ref)
    local v11 = v10

    if v11 == nil then
        v11 = import("skate_game/graph_host/motion_animation")
        v10 = v11
    end

    return v11
end

local t1 = {
    Settings = {}
}

function t1.Settings.load(p4) -- line: 64
    -- upvalues: v1 (copy), Collections (copy)
    local function float(p5) -- line: 65
        -- upvalues: p4 (copy), Collections (copy)
        return Collections.float(p4, "anim_motion", "power_slide", p5)
    end

    local function curve(p6) -- line: 68
        -- upvalues: p4 (copy), v1 (copy), Collections (copy)
        local v12 = Collections.words(p4, "anim_motion", "power_slide", p6, 12)
        local t2 = {}

        buffer.writeu32(v1, 0, v12[5])

        local v14 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[6])

        local v16 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[7])

        local v18 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[8])
        t2.x = {
            v14,
            v16,
            v18,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v12[9])

        local v21 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[10])

        local v23 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[11])

        local v25 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[12])
        t2.y = {
            v21,
            v23,
            v25,
            (buffer.readf32(v1, 0))
        }

        return t2
    end

    local function curve8(p7) -- line: 85
        -- upvalues: p4 (copy), v1 (copy), Collections (copy)
        local v27 = Collections.words(p4, "anim_motion", "power_slide", p7, 20)
        local t3 = {}

        buffer.writeu32(v1, 0, v27[5])

        local v29 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[6])

        local v31 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[7])

        local v33 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[8])

        local v35 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[9])

        local v37 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[10])

        local v39 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[11])

        local v41 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[12])
        t3.x = {
            v29,
            v31,
            v33,
            v35,
            v37,
            v39,
            v41,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v27[13])

        local v44 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[14])

        local v46 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[15])

        local v48 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[16])

        local v50 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[17])

        local v52 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[18])

        local v54 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[19])

        local v56 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[20])
        t3.y = {
            v44,
            v46,
            v48,
            v50,
            v52,
            v54,
            v56,
            (buffer.readf32(v1, 0))
        }

        return t3
    end

    return {
        speed_threshold = Collections.float(p4, "anim_motion", "power_slide", "slide_speed_threshold"),
        well_into_slide = Collections.float(p4, "anim_motion", "power_slide", "well_into_slide_time"),
        speed_factor = curve("slide_speed_factor"),
        time_threshold = curve("not_sliding_time_thresh"),
        threshold = curve("not_sliding_threshold"),
        speed_to_lean = curve8("slide_speed_to_lean"),
        phys_to_anim_spin = curve8("slide_phys_to_anim_spin"),
        smooth = Collections.float(p4, "anim_motion", "power_slide", "slide_smooth"),
        minimum_entry = Collections.float(p4, "anim_motion", "power_slide", "slide_min_entry"),
        turn = Collections.float(p4, "anim_motion", "power_slide", "slide_turn_value")
    }
end

t1.Operation = {}

function t1.Operation.eq(p8, p9) -- line: 140
    if p8.tag == p9.tag then
        return p8.right == p9.right
    end

    return false
end

function t1.Operation.parse(p10) -- line: 145
    -- upvalues: Attributes (copy)
    local name = Attributes.text(p10, "name")

    if name ~= nil then
        if name == "PowerSliding" then
            return {
                tag = "Update"
            }
        end

        if name == "CreateSlide" then
            return {
                tag = "Create",
                right = Attributes.boolean_byte(p10, "right", 1) ~= 0
            }
        end

        if name == "PowerSlideManualAtt" then
            return {
                tag = "ManualAttribute"
            }
        end

        if name == "PowerSlideDecel" then
            return {
                tag = "Deceleration"
            }
        end

        if name == "PowerSlideSpin" then
            return {
                tag = "Spin"
            }
        end

        if name == "InCandidateSlidingState" then
            return {
                tag = "Candidate"
            }
        end

        if name == "IsPowerSliding" then
            return {
                tag = "IsPowerSliding"
            }
        end
    end

    return nil
end

t1.State = {}

function t1.State.default() -- line: 174
    return {
        not_sliding_time = 0,
        previous_right = 0,
        previous_left = 0,
        was_ground = false,
        was_right_start = false,
        was_left_start = false
    }
end

function t1.State.update(p11, p12, p13, p14, p15, p16, p17, p18) -- line: 187
    -- upvalues: import (copy), SlideLatch (copy), PointGraph (copy), v10 (ref)
    local v58 = v10

    if v58 == nil then
        v58 = import("skate_game/graph_host/motion_animation")
        v10 = v58
    end

    local MotionAnimation = v58.MotionAnimation
    local RightSlide = MotionAnimation.motion_intent(p12, "RightSlide")
    local LeftSlide = MotionAnimation.motion_intent(p12, "LeftSlide")
    local v59 = if RightSlide == nil then 0 else RightSlide
    local v60 = if LeftSlide == nil then 0 else LeftSlide
    local v61 = p13 == 1

    if v61 and not p11.was_ground then
        p11.not_sliding_time = 0
        p11.previous_right = v59
        p11.previous_left = v60
        p11.was_right_start = false
        p11.was_left_start = false
    end

    p11.was_ground = v61

    if not v61 then
        return
    end

    local v62 = p17.speed_threshold < p14
    local v63 = MotionAnimation.motion_intent(p12, "RightSlideStart") ~= nil

    SlideLatch.set_start(p18, true, v62 and v63 and not p11.was_right_start and p11.previous_right < v59)
    p11.previous_right = v59
    p11.was_right_start = v63

    local v64 = MotionAnimation.motion_intent(p12, "LeftSlideStart") ~= nil

    SlideLatch.set_start(p18, false, v62 and v64 and not p11.was_left_start and v60 < p11.previous_left)
    p11.previous_left = v60
    p11.was_left_start = v64

    local v65 = PointGraph.evaluate(p17.time_threshold, p15)

    if PointGraph.evaluate(p17.speed_factor, p14) * (1 - math.abs(p15)) >= PointGraph.evaluate(p17.threshold, p15) then
        p11.not_sliding_time = 0
    else
        p11.not_sliding_time += p16
    end

    local v66 = v65 < p11.not_sliding_time

    SlideLatch.advance_elapsed(p18, true, p16)
    SlideLatch.advance_elapsed(p18, false, p16)
    SlideLatch.set_end(p18, true, SlideLatch.elapsed(p18, true) > p17.well_into_slide and (RightSlide == nil or not v62 or v66))
    SlideLatch.set_end(p18, false, SlideLatch.elapsed(p18, false) > p17.well_into_slide and (LeftSlide == nil or not v62 or v66))
end

function t1.direction(p19, p20, p21) -- line: 247
    -- upvalues: v9 (copy)
    local dot_product = v9.dot_product
    local v67 = dot_product(p19, p19)

    if not (v67 > 0.0010000000474974513) then
        return 1
    end

    local v68 = if p21 then {
        -p20[1],
        -p20[2],
        -p20[3],
        -p20[4]
    } else p20
    local v69 = 1 / math.sqrt(v67)
    local v70 = -v67 * (v69 * v69) + 1
    local v71 = v69 * 0.5 * v70 + v69
    local v72 = -v67 * (v71 * v71) + 1
    local v73 = v67 * (v71 * 0.5 * v72 + v71)
    local v74 = 1 / v73
    local v75 = v74 * (-v74 * v73 + 1) + v74
    local v76 = v75 * (-v75 * v73 + 1) + v75

    return dot_product({
        p19[1] * v76,
        p19[2] * v76,
        p19[3] * v76,
        p19[4] * v76
    }, v68)
end

function t1.create(p22, p23, p24, p25, p26) -- line: 279
    -- upvalues: SlideLatch (copy)
    local v77 = p23 ~= SlideLatch.captured_fakie(p22)
    local v78 = if v77 then p24 else p25

    if v78 == nil then
        v78 = 0
    end

    if not (SlideLatch.elapsed(p22, v77) > p26.well_into_slide) then
        if v77 then
            if p26.minimum_entry - v78 >= 0 then
                v78 = p26.minimum_entry
            end
        else
            local v79 = -p26.minimum_entry

            if not (v79 - v78 >= 0) then
                v78 = v79
            end
        end
    end

    local v80 = if v77 then p26.turn else -p26.turn
    local v81, v82

    if not SlideLatch.captured_fakie(p22) then
        v82 = v80
        v81 = v78

        return { v81, v82 }
    end

    local v83 = -v80
    local v84 = -v78
    local v85 = math.abs(v84)

    if v85 > 0.5 then
        v85 = 1 - v85
    end

    v82 = v83
    v81 = if v84 >= 0 then v85 else -v85

    return { v81, v82 }
end

function t1.deceleration(p27, p28, p29, p30) -- line: 319
    -- upvalues: rt (copy), v1 (copy), PointGraph (copy), v9 (copy)
    local v86 = rt.from_fn(4, function(p31) -- line: 320
        -- upvalues: p28 (copy), p29 (copy)
        local v87 = p29[p31 + 1][1] * p28[1]
        local v88 = p29[p31 + 1][2] * p28[2] + v87

        return p29[p31 + 1][3] * p28[3] + v88
    end)

    v86[2] = 0

    local v89 = v9.dot_product(v86, v86)
    local v90

    if v89 ~= 0 and v89 > -1.1754943508222875E-38 and v89 < 1.1754943508222875E-38 then
        local v91 = math.abs(v89) * 7.1362384635298E+44
        local v92 = math.floor(v91)
        local v93 = v91 - v92

        v90 = (if v93 > 0.5 or v93 == 0.5 and v92 % 2 == 1 then v92 + 1 else v92) * 1.401298464324817E-45

        if v89 < 0 then
            v90 = -v90
        end
    else
        buffer.writef32(v1, 0, v89)
        v90 = buffer.readf32(v1, 0)
    end

    local v94

    if v90 == 0 then
        v94 = 0
    else
        local v95 = 1 / math.sqrt(v90)
        local v96 = -v90 * (v95 * v95) + 1
        local v97 = v95 * 0.5 * v96 + v95
        local v98 = -v90 * (v97 * v97) + 1

        v94 = v90 * (v97 * 0.5 * v98 + v97)
    end

    local v99 = PointGraph.evaluate(p30.speed_to_lean, v94)
    local v100 = (1 - p30.smooth) * p27
    local v101 = v99 * p30.smooth + v100

    return v101, v101
end

function t1.spin(p32, p33) -- line: 346
    -- upvalues: PointGraph (copy)
    return -PointGraph.evaluate(p33.phys_to_anim_spin, p32)
end

return t1
