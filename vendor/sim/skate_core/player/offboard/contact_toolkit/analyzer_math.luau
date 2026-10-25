-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2

local function toolkit() -- line: 11
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2
end

local function cross(p1, p2) -- line: 17
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.cross(p1, p2)
end

local function dot(p3, p4) -- line: 20
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.dot(p3, p4)
end

local function length(p5) -- line: 23
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.length(p5)
end

local function scale(p6, p7) -- line: 26
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.scale(p6, p7)
end

local function sub(p8, p9) -- line: 29
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.sub(p8, p9)
end

local function round_ties_even(p10) -- line: 34
    local v3 = math.floor(p10)
    local v4 = p10 - v3

    if not (v4 > 0.5) and (v4 < 0.5 or v3 % 2 == 0) then
        return v3
    end

    return v3 + 1
end

local t1 = {
    madd = function(p11, p12, p13) -- madd | line: 49
        return {
            p11[1] * p12 + p13[1],
            p11[2] * p12 + p13[2],
            p11[3] * p12 + p13[3],
            p11[4] * p12 + p13[4]
        }
    end
}
local madd = t1.madd

function t1.reciprocal(p14) -- line: 54
    -- upvalues: v1 (copy)
    local v5 = v1.reciprocal_estimate(p14)
    local v6 = v5 * (-v5 * p14 + 1) + v5

    return v6 * (-v6 * p14 + 1) + v6
end

local reciprocal = t1.reciprocal

function t1.normalize(p15, p16) -- line: 63
    -- upvalues: rt (copy), import (copy), v2 (ref), scale (copy), reciprocal (copy)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v7 = v2.length(p15)

    if v7 > 9.999999974752427E-07 then
        return scale(p15, reciprocal(v7))
    end

    return rt.copy(p16)
end

local normalize = t1.normalize
local v8 = false

function t1.set_reference(p17) -- line: 77
    -- upvalues: v8 (ref)
    v8 = p17
end

local reciprocal_estimate = import("skate_core/physics/native_arithmetic").reciprocal_estimate
local estimate = import("skate_core/physics/reciprocal_sqrt").estimate

local function length3(p18, p19, p20) -- line: 93
    -- upvalues: estimate (copy)
    local v9 = p18 * p18 + p19 * p19 + p20 * p20

    if v9 == 0 then
        return 0
    end

    local v10 = estimate(v9)
    local v11 = v10 * 0.5 * (-v9 * (v10 * v10) + 1) + v10

    return v9 * (v11 * 0.5 * (-v9 * (v11 * v11) + 1) + v11)
end

local function reciprocal2(p21) -- line: 103
    -- upvalues: reciprocal_estimate (copy)
    local v12 = reciprocal_estimate(p21)
    local v13 = v12 * (-v12 * p21 + 1) + v12

    return v13 * (-v13 * p21 + 1) + v13
end

function t1.plane_segment(p22, p23, p24, p25) -- line: 114
    -- upvalues: t1 (copy), v8 (ref)
    if v8 then
        return t1.plane_segment_reference(p22, p23, p24, p25)
    end

    local v14 = p23[1]
    local v15 = p23[2]
    local v16 = p23[3]
    local v17 = p22[1]
    local v18 = p22[2]
    local v19 = p22[3]
    local v20 = v14 * (p24[1] - v17) + v15 * (p24[2] - v18) + v16 * (p24[3] - v19)
    local v21 = v14 * (p25[1] - v17) + v15 * (p25[2] - v18) + v16 * (p25[3] - v19)

    if v20 * v21 >= 0 then
        return nil
    end

    local v22 = math.abs(v20)
    local v23 = math.abs(v21)
    local v24 = v22 + v23
    local v25 = v23 / v24
    local v26 = v22 / v24

    return {
        p24[1] * v25 + p25[1] * v26,
        p24[2] * v25 + p25[2] * v26,
        p24[3] * v25 + p25[3] * v26,
        p24[4] * v25 + p25[4] * v26
    }
end

function t1.plane_segment_reference(p26, p27, p28, p29) -- line: 132
    -- upvalues: import (copy), v2 (ref), scale (copy), madd (copy)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v27 = v2.sub(p28, p26)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v28 = v2.dot(p27, v27)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v29 = v2.sub(p29, p26)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v30 = v2.dot(p27, v29)

    if v28 * v30 >= 0 then
        return nil
    end

    local v31 = math.abs(v28)
    local v32 = math.abs(v30)
    local v33 = v31 + v32

    return madd(p28, v32 / v33, scale(p29, v31 / v33))
end

function t1.clamp_normal(p30, p31, p32) -- line: 156
    -- upvalues: rt (copy), import (copy), v2 (ref), t1 (copy), v8 (ref), reciprocal_estimate (copy), estimate (copy)
    if v8 then
        return t1.clamp_normal_reference(p30, p31, p32)
    end

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local ZERO = v2.ZERO
    local v34 = ZERO[1]
    local v35 = ZERO[2]
    local v36 = ZERO[3]
    local v37 = ZERO[4]
    local v38 = p30[1]
    local v39 = p30[2]
    local v40 = p30[3]
    local v41 = p30[4]
    local v42 = v38 * v38 + v39 * v39 + v40 * v40
    local v43

    if v42 == 0 then
        v43 = 0
    else
        local v44 = estimate(v42)
        local v45 = v44 * 0.5 * (-v42 * (v44 * v44) + 1) + v44

        v43 = v42 * (v45 * 0.5 * (-v42 * (v45 * v45) + 1) + v45)
    end

    local v46, v47, v48, v49

    if v43 > 9.999999974752427E-07 then
        local v50 = reciprocal_estimate(v43)
        local v51 = v50 * (-v50 * v43 + 1) + v50
        local v52 = v51 * (-v51 * v43 + 1) + v51

        v46 = v38 * v52
        v47 = v39 * v52
        v48 = v40 * v52
        v49 = v41 * v52
    else
        v49 = v37
        v46 = v34
        v47 = v35
        v48 = v36
    end

    local v53 = p31[1]
    local v54 = p31[2]
    local v55 = p31[3]
    local v56 = p31[4]
    local v57 = v53 * v53 + v54 * v54 + v55 * v55
    local v58

    if v57 == 0 then
        v58 = 0
    else
        local v59 = estimate(v57)
        local v60 = v59 * 0.5 * (-v57 * (v59 * v59) + 1) + v59

        v58 = v57 * (v60 * 0.5 * (-v57 * (v60 * v60) + 1) + v60)
    end

    local v61, v62, v63, v64

    if v58 > 9.999999974752427E-07 then
        local v65 = reciprocal_estimate(v58)
        local v66 = v65 * (-v65 * v58 + 1) + v65
        local v67 = v66 * (-v66 * v58 + 1) + v66

        v63 = v53 * v67
        v61 = v54 * v67
        v62 = v55 * v67
        v64 = v56 * v67
    else
        v64 = v37
        v63 = v34
        v61 = v35
        v62 = v36
    end

    local v68 = -v48 * v61 + v47 * v62
    local v69 = -v46 * v62 + v48 * v63
    local v70 = -v47 * v63 + v46 * v61
    local v71 = v68 * v68 + v69 * v69 + v70 * v70
    local v72

    if v71 == 0 then
        v72 = 0
    else
        local v73 = estimate(v71)
        local v74 = v73 * 0.5 * (-v71 * (v73 * v73) + 1) + v73

        v72 = v71 * (v74 * 0.5 * (-v71 * (v74 * v74) + 1) + v74)
    end

    local v75, v76, v77, v78

    if v72 > 9.999999974752427E-07 then
        local v79 = reciprocal_estimate(v72)
        local v80 = v79 * (-v79 * v72 + 1) + v79
        local v81 = v80 * (-v80 * v72 + 1) + v80

        v75 = v68 * v81
        v76 = v69 * v81
        v77 = v70 * v81
        v78 = 0 * v81
    else
        v78 = v37
        v75 = v34
        v76 = v35
        v77 = v36
    end

    local v82 = p32[1]
    local v83 = p32[2]
    local v84 = p32[3]
    local v85 = p32[4]
    local v86 = v75 * v82 + v76 * v83 + v77 * v84
    local v87 = v82 - v75 * v86
    local v88 = v83 - v76 * v86
    local v89 = v84 - v77 * v86
    local v90 = v85 - v78 * v86
    local v91 = v87 * v87 + v88 * v88 + v89 * v89
    local v92

    if v91 == 0 then
        v92 = 0
    else
        local v93 = estimate(v91)
        local v94 = v93 * 0.5 * (-v91 * (v93 * v93) + 1) + v93

        v92 = v91 * (v94 * 0.5 * (-v91 * (v94 * v94) + 1) + v94)
    end

    if v92 > 9.999999974752427E-07 then
        local v95 = reciprocal_estimate(v92)
        local v96 = v95 * (-v95 * v92 + 1) + v95
        local v97 = v96 * (-v96 * v92 + 1) + v96

        v34 = v87 * v97
        v35 = v88 * v97
        v36 = v89 * v97
        v37 = v90 * v97
    end

    if (v75 * v75 + v76 * v76 + v77 * v77) * (v34 * v34 + v35 * v35 + v36 * v36) * (v46 * v46 + v47 * v47 + v48 * v48) * (v63 * v63 + v61 * v61 + v62 * v62) < 0.1 then
        return rt.copy(p32)
    end

    if (-v48 * v35 + v47 * v36) * v75 + (-v46 * v36 + v48 * v34) * v76 + (-v47 * v34 + v46 * v35) * v77 > 0 and (-v36 * v61 + v35 * v62) * v75 + (-v34 * v62 + v36 * v63) * v76 + (-v35 * v63 + v34 * v61) * v77 > 0 then
        return { v34, v35, v36, v37 }
    end

    if v34 * v46 + v35 * v47 + v36 * v48 > v34 * v63 + v35 * v61 + v36 * v62 then
        return { v46, v47, v48, v49 }
    end

    return { v63, v61, v62, v64 }
end

function t1.clamp_normal_reference(p33, p34, p35) -- line: 223
    -- upvalues: rt (copy), import (copy), v2 (ref), normalize (copy)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local ZERO = v2.ZERO
    local v98 = normalize(p33, ZERO)
    local v99 = normalize(p34, ZERO)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v100 = normalize(v2.cross(v98, v99), ZERO)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v101 = v2.dot(v100, p35)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v102 = v2.scale(v100, v101)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v103 = normalize(v2.sub(p35, v102), ZERO)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v104 = v2.dot(v100, v100)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v105 = v104 * v2.dot(v103, v103)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v106 = v105 * v2.dot(v98, v98)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    if v106 * v2.dot(v99, v99) < 0.1 then
        return rt.copy(p35)
    end

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v107 = v2.cross(v98, v103)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    if v2.dot(v107, v100) > 0 then
        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v108 = v2.cross(v103, v99)

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        if v2.dot(v108, v100) > 0 then
            return v103
        end
    end

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v109 = v2.dot(v103, v98)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    if v2.dot(v103, v99) < v109 then
        return v98
    end

    return v99
end

function t1.intersection(p36, p37, p38, p39) -- line: 242
    local t2 = {
        p37[1] - p36[1],
        p37[2] - p36[2]
    }
    local t3 = {
        p39[1] - p38[1],
        p39[2] - p38[2]
    }
    local v110 = t3[2] * t2[1] - t3[1] * t2[2]

    if math.abs(v110) < 1E-05 then
        return 1E+10
    end

    return 1 / v110 * (t3[1] * (p36[2] - p38[2]) - t3[2] * (p36[1] - p38[1]))
end

function t1.tangent(p40) -- line: 252
    -- upvalues: rt (copy), reciprocal (copy)
    if p40 == 0 then
        return 0
    end

    local from_bits = rt.from_bits
    local v111 = p40 * from_bits(1059256707)
    local v112 = math.floor(v111)
    local v113 = v111 - v112

    if v113 > 0.5 or not (v113 < 0.5) and v112 % 2 ~= 0 then
        v112 += 1
    end

    local v114 = -v112 * from_bits(780509961) + (-v112 * from_bits(1070141403) + p40)
    local v115 = v114 * v114
    local v116 = v115 * (v115 * (v115 * (v115 * from_bits(889568168) + from_bits(3114498853)) + from_bits(1020411125)) + from_bits(3203331458)) + 1
    local v117 = v114 * (v115 * (v115 * (v115 * from_bits(3080050105) + from_bits(996176917)) + from_bits(3188233647))) + v114

    if math.abs(v114) <= from_bits(964689920) then
        v116 = 1
    else
        v114 = v117
    end

    if bit32.band(rt.f_to_i32((math.abs(v112))), 1) == 0 then
        return v114 * reciprocal(v116)
    end

    return v116 * reciprocal(-v114)
end

return t1
