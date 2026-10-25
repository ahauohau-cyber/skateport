-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/camera/shot")
local v2 = import("skate_core/camera/orientation_math")
local v3 = import("skate_core/camera/shot_orientation")
local v4 = import("skate_core/trigonometry")
local v5 = import("skate_core/physics/reciprocal_sqrt")
local Shot = v1.Shot
local basis_from_angles, look_basis = v2.basis_from_angles, v2.look_basis
local slerp = v3.slerp
local t1 = {
    FrameSettings = {},
    FrameSubject = {},
    FrameComposer = {}
}

function t1.FrameComposer.new() -- line: 36
    return {
        roll = 0,
        yaw = 0,
        pitch = 0,
        reference = { 0, 0, 0, 0 }
    }
end

function t1.FrameComposer.compose_reference(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) -- line: 47
    -- upvalues: slerp (copy), t1 (copy)
    local v6 = t1.FrameComposer.single(p1, p6, p7, p8, p4, p9, p10)
    local v8 = slerp(t1.FrameComposer.single(p1, p5, p7, p8, p4, p9, p10), v6, p3)

    if p2 > 0 then
        p1.roll = (p6.framing[1] - p1.roll) * p10.roll_response * p2 + p1.roll
    else
        p1.roll = p6.framing[1]
    end

    return v8
end

function t1.FrameComposer.single_reference(p11, p12, p13, p14, p15, p16, p17) -- line: 71
    -- upvalues: v2 (copy), v4 (copy), Shot (copy), basis_from_angles (copy), look_basis (copy), t1 (copy)
    p11.reference = Shot.reference_point(p12, p16.positions, p16.board_offset_direction, p13)
    p11.yaw = p12.framing[2] * p15
    p11.pitch = -p12.framing[3]

    local v9 = basis_from_angles(p11.pitch, p11.yaw, 0)
    local t2 = {
        p11.reference[1] - p14[1],
        p11.reference[2] - p14[2],
        p11.reference[3] - p14[3]
    }
    local v10 = t2[1]
    local v11 = math.abs(v10) > 1.1920928955078125E-07 or math.abs(t2[2]) > 1.1920928955078125E-07 or math.abs(t2[3]) > 1.1920928955078125E-07
    local v14

    if v11 then
        v14 = v2.normalize(t2)

        local v15 = v4.sin(p17.maximum_pitch_degrees * 0.01745329238474369)

        if v15 < v14[2] then
            v14[2] = v15
            v14 = v2.normalize(v14)
        end
    else
        v14 = { 0, 0, 1 }
    end

    local v16 = look_basis(v14)
    local t3 = {}

    for i = 0, 2 do
        local v17 = v9.columns[i + 1]
        local t4 = {}

        for j = 0, 2 do
            t4[j + 1] = v16.columns[3][j + 1] * v17[3] + (v16.columns[2][j + 1] * v17[2] + v16.columns[1][j + 1] * v17[1])
        end

        t3[i + 1] = t4
    end

    local t5 = {
        columns = t3
    }

    return t1.quaternion_from_basis(t5)
end

function t1.quaternion_from_basis_reference(p18) -- line: 125
    -- upvalues: v5 (copy)
    local v18 = p18.columns[1]
    local v19 = p18.columns[2]
    local v20 = p18.columns[3]
    local v21 = v18[1]
    local v22 = v19[2]
    local v23 = v20[3]
    local v24, t6, v25

    if v21 + v22 + v23 > 0 then
        v24 = v21 + v22 + (v23 + 1)
        t6 = {
            v19[3] - v20[2],
            v20[1] - v18[3],
            v18[2] - v19[1],
            0.5
        }
        v25 = 3
    elseif v22 < v21 and v23 < v21 then
        v24 = v21 + -v22 + (-v23 + 1)
        t6 = {
            0.5,
            v19[1] + v18[2],
            v20[1] + v18[3],
            v19[3] - v20[2]
        }
        v25 = 0
    elseif v23 < v22 then
        v24 = -v21 + v22 + (-v23 + 1)
        t6 = {
            v19[1] + v18[2],
            0.5,
            v20[2] + v19[3],
            v20[1] - v18[3]
        }
        v25 = 1
    else
        v24 = -v21 + -v22 + (v23 + 1)
        t6 = {
            v20[1] + v18[3],
            v20[2] + v19[3],
            0.5,
            v18[2] - v19[1]
        }
        v25 = 2
    end

    local v26 = v5.estimate(v24)
    local v27 = v26 * 0.5 * (-v24 * (v26 * v26) + 1) + v26
    local v28 = v27 * 0.5 * (-v24 * (v27 * v27) + 1) + v27
    local v29 = v24 * v28
    local v30 = 0.5 * v28
    local t7 = {}

    t7[1] = t6[1] * (if v25 == 0 then v29 else v30)
    t7[2] = t6[2] * (if v25 == 1 then v29 else v30)
    t7[3] = t6[3] * (if v25 == 2 then v29 else v30)

    local v31 = t6[4]

    if v25 ~= 3 then
        v29 = v30
    end

    t7[4] = v31 * v29

    return t7
end

local PERF = import("skate_core/camera/tracker").PERF
local basis_from_angles_lanes, normalize3 = v2.basis_from_angles_lanes, v2.normalize3
local slerp_lanes = v3.slerp_lanes

local function quaternion_from_basis_lanes(p19, p20, p21, p22, p23, p24, p25, p26, p27) -- line: 180
    local v32, v33, v34, v35, v36, v37

    if p19 + p23 + p27 > 0 then
        v32 = p19 + p23 + (p27 + 1)
        v34 = p24 - p26
        v35 = p25 - p21
        v36 = p20 - p22
        v37 = 0.5
        v33 = 3
    elseif p23 < p19 and p27 < p19 then
        v32 = p19 + -p23 + (-p27 + 1)
        v34 = 0.5
        v35 = p22 + p20
        v36 = p25 + p21
        v37 = p24 - p26
        v33 = 0
    elseif p27 < p23 then
        v32 = -p19 + p23 + (-p27 + 1)
        v34 = p22 + p20
        v35 = 0.5
        v36 = p26 + p24
        v37 = p25 - p21
        v33 = 1
    else
        v32 = -p19 + -p23 + (p27 + 1)
        v34 = p25 + p21
        v35 = p26 + p24
        v36 = 0.5
        v37 = p20 - p22
        v33 = 2
    end

    local v38 = 1 / math.sqrt(v32)
    local v39 = v38 * 0.5 * (-v32 * (v38 * v38) + 1) + v38
    local v40 = v39 * 0.5 * (-v32 * (v39 * v39) + 1) + v39
    local v41 = v32 * v40
    local v42 = v40 * 0.5
    local v43 = v34 * (if v33 == 0 then v41 else v42)
    local v44 = v35 * (if v33 == 1 then v41 else v42)
    local v45 = v36 * (if v33 == 2 then v41 else v42)

    if v33 ~= 3 then
        v41 = v42
    end

    return v43, v44, v45, v37 * v41
end

function t1.quaternion_from_basis(p28) -- line: 223
    -- upvalues: t1 (copy), PERF (copy), quaternion_from_basis_lanes (copy)
    if PERF.reference then
        return t1.quaternion_from_basis_reference(p28)
    end

    local columns = p28.columns
    local v46 = columns[1]
    local v47 = columns[2]
    local v48 = columns[3]
    local v49, v50, v51, v52 = quaternion_from_basis_lanes(v46[1], v46[2], v46[3], v47[1], v47[2], v47[3], v48[1], v48[2], v48[3])

    return { v49, v50, v51, v52 }
end

local function single_lanes(p29, p30, p31, p32, p33, p34, p35) -- line: 235
    -- upvalues: v4 (copy), Shot (copy), basis_from_angles_lanes (copy), normalize3 (copy), quaternion_from_basis_lanes (copy)
    local v53, v54, v55, v56 = Shot.reference_point_lanes(p30, p34.positions, p34.board_offset_direction, p31)
    local reference = p29.reference

    reference[1] = v53
    reference[2] = v54
    reference[3] = v55
    reference[4] = v56

    local framing = p30.framing
    local v57 = framing[2] * p33
    local v58 = -framing[3]

    p29.yaw = v57
    p29.pitch = v58

    local v59, v60, v61, v62, v63, v64, v65, v66, v67 = basis_from_angles_lanes(v58, v57, 0)
    local v68 = v53 - p32[1]
    local v69 = v54 - p32[2]
    local v70 = v55 - p32[3]
    local v71, v72, v73

    if not (math.abs(v68) > 1.1920928955078125E-07) and not (math.abs(v69) > 1.1920928955078125E-07) and not (math.abs(v70) > 1.1920928955078125E-07) then
        v71 = 0
        v72 = 0
        v73 = 1
    else
        v71, v72, v73 = normalize3(v68, v69, v70)

        local v74 = v4.sin(p35.maximum_pitch_degrees * 0.01745329238474369)

        if v74 < v72 then
            v71, v72, v73 = normalize3(v71, v74, v73)
        end
    end

    local v75, v76, v77 = normalize3(-0 * v72 + 1 * v73, -0 * v73 + 0 * v71, -1 * v71 + 0 * v72)
    local v78, v79, v80 = normalize3(-v73 * v76 + v72 * v77, -v71 * v77 + v73 * v75, -v72 * v75 + v71 * v76)

    return quaternion_from_basis_lanes(v71 * v61 + (v78 * v60 + v75 * v59), v72 * v61 + (v79 * v60 + v76 * v59), v73 * v61 + (v80 * v60 + v77 * v59), v71 * v64 + (v78 * v63 + v75 * v62), v72 * v64 + (v79 * v63 + v76 * v62), v73 * v64 + (v80 * v63 + v77 * v62), v71 * v67 + (v78 * v66 + v75 * v65), v72 * v67 + (v79 * v66 + v76 * v65), v73 * v67 + (v80 * v66 + v77 * v65))
end

function t1.FrameComposer.single(p36, p37, p38, p39, p40, p41, p42) -- line: 284
    -- upvalues: t1 (copy), PERF (copy), single_lanes (copy)
    if PERF.reference then
        return t1.FrameComposer.single_reference(p36, p37, p38, p39, p40, p41, p42)
    end

    local v81, v82, v83, v84 = single_lanes(p36, p37, p38, p39, p40, p41, p42)

    return { v81, v82, v83, v84 }
end

local function compose_lanes(p43, p44, p45, p46, p47, p48, p49, p50, p51, p52) -- line: 301
    -- upvalues: slerp_lanes (copy), single_lanes (copy)
    local v85, v86, v87, v88 = single_lanes(p43, p48, p49, p50, p46, p51, p52)
    local v89, v90, v91, v92 = single_lanes(p43, p47, p49, p50, p46, p51, p52)
    local v93, v94, v95, v96 = slerp_lanes(v89, v90, v91, v92, v85, v86, v87, v88, p45)
    local v97 = p48.framing[1]

    if p44 > 0 then
        p43.roll = (v97 - p43.roll) * p52.roll_response * p44 + p43.roll
    else
        p43.roll = v97
    end

    return v93, v94, v95, v96
end

function t1.FrameComposer.compose(p53, p54, p55, p56, p57, p58, p59, p60, p61, p62) -- line: 327
    -- upvalues: t1 (copy), PERF (copy), compose_lanes (copy)
    if PERF.reference then
        return t1.FrameComposer.compose_reference(p53, p54, p55, p56, p57, p58, p59, p60, p61, p62)
    end

    local v98, v99, v100, v101 = compose_lanes(p53, p54, p55, p56, p57, p58, p59, p60, p61, p62)

    return { v98, v99, v100, v101 }
end

function t1.FrameComposer.compose_into(p63, p64, p65, p66, p67, p68, p69, p70, p71, p72, p73) -- line: 359
    -- upvalues: compose_lanes (copy)
    local v102, v103, v104, v105 = compose_lanes(p63, p65, p66, p67, p68, p69, p70, p71, p72, p73)

    p64[1] = v102
    p64[2] = v103
    p64[3] = v104
    p64[4] = v105
end

return t1
