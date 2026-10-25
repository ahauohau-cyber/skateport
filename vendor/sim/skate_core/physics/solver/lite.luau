-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/solver/contact")
local v2 = import("skate_core/physics/solver/drive")

import("skate_core/physics/solver/joint")

local t1 = {
    RIDER_FIRST = 8,
    RIDER_LAST = 37,
    stats = {
        solves = 0,
        split = 0,
        stopped = 0,
        rider_passes = 0,
        checks = 0,
        passes = 0
    }
}

function t1.reset_stats() -- line: 63
    -- upvalues: t1 (copy)
    local stats = t1.stats

    stats.solves = 0
    stats.split = 0
    stats.stopped = 0
    stats.rider_passes = 0
    stats.checks = 0
    stats.passes = 0
end

local v3
local n1 = 1E-05
local v4 = false

function t1.configure(p1) -- line: 74
    -- upvalues: v3 (ref), n1 (ref), v4 (ref)
    v3 = nil
    n1 = 1E-05
    v4 = false

    if type(p1) ~= "table" then
        return false
    end

    local rider_passes = p1.rider_passes

    if rider_passes == "auto" then
        v3 = 6
        n1 = 1E-05
    elseif type(rider_passes) == "number" and rider_passes >= 1 then
        v3 = math.floor(rider_passes)
        n1 = 1E-04
    end

    if v3 ~= nil then
        if type(p1.rider_floor) == "number" then
            v3 = math.max(1, (math.floor(p1.rider_floor)))
        end

        if type(p1.rider_tolerance) == "number" then
            n1 = p1.rider_tolerance
        end

        if v3 < 2 then
            v3 = 2
        end
    end

    v4 = p1.vector_kernels == true

    if v3 == nil then
        return v4
    end

    return true
end

function t1.describe() -- line: 102
    -- upvalues: v3 (ref), n1 (ref), v4 (ref)
    local t2 = {}

    if v3 ~= nil then
        table.insert(t2, string.format("rider floor %d tol %g", v3, n1))
    end

    if v4 then
        table.insert(t2, "vector kernels")
    end

    if #t2 > 0 then
        return (table.concat(t2, ", "))
    end

    return "off"
end

local t3 = {}

local function classify(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) -- line: 122
    -- upvalues: v1 (copy), v2 (copy), t1 (copy), t3 (copy)
    local RIDER_FIRST, RIDER_LAST = t1.RIDER_FIRST, t1.RIDER_LAST
    local solve_w3_b0 = v1.solve_w3_b0
    local n2 = 0
    local n3 = 0

    for i = 1, p3 do
        local v8 = p4[i]
        local v9 = RIDER_FIRST <= v8 and v8 <= RIDER_LAST

        if p2[i] ~= solve_w3_b0 then
            local v10 = p5[i]

            if v9 ~= (RIDER_FIRST <= v10 and v10 <= RIDER_LAST) then
                return false
            end
        end

        t3[i] = not v9

        if v9 then
            n2 += 1
        else
            n3 += 1
        end
    end

    for i = 1, p6 do
        local v11 = p7[i]
        local v12 = p8[i]
        local v13 = RIDER_FIRST <= v11 and v11 <= RIDER_LAST

        if v13 ~= (RIDER_FIRST <= v12 and v12 <= RIDER_LAST) then
            return false
        end

        t3[p3 + i] = not v13

        if v13 then
            n2 += 1
        else
            n3 += 1
        end
    end

    local v14 = p3 + p6
    local solve_w3_inert = v2.solve_w3_inert

    for i = 1, p9 do
        local v15 = p10[i]
        local v16 = p11[i]
        local v17 = RIDER_FIRST <= v15 and v15 <= RIDER_LAST

        if v17 ~= (RIDER_FIRST <= v16 and v16 <= RIDER_LAST) then
            if p2[v14 + i] ~= solve_w3_inert then
                return false
            end

            v17 = false
        end

        t3[v14 + i] = not v17

        if v17 then
            n2 += 1
        else
            n3 += 1
        end
    end

    if n2 > 0 then
        return n3 > 0
    end

    return false
end

t1.classify = classify

local t4 = {}

local function rider_change(p12, p13, p14, p15) -- line: 197
    -- upvalues: t4 (copy)
    local abs = math.abs
    local n4 = 0
    local n5 = 0

    for i = p13, p14 do
        local v18 = p12[i]
        local v19 = v18[1]
        local v20 = v18[2]
        local v21 = v18[3]
        local v22 = v18[5]
        local v23 = v18[6]
        local v24 = v18[7]
        local v25 = v18[9]
        local v26 = v18[10]
        local v27 = v18[11]
        local v28 = v18[13]
        local v29 = v18[14]
        local v30 = v18[15]
        local v31, v32, v33

        if p15 then
            v31 = math.max(abs(v19 - t4[n5 + 1]), abs(v20 - t4[n5 + 2]), abs(v21 - t4[n5 + 3]), abs(v22 - t4[n5 + 4]), abs(v23 - t4[n5 + 5]), abs(v24 - t4[n5 + 6]), abs(v25 - t4[n5 + 7]), abs(v26 - t4[n5 + 8]), abs(v27 - t4[n5 + 9]), abs(v28 - t4[n5 + 10]), abs(v29 - t4[n5 + 11]), (abs(v30 - t4[n5 + 12])))

            if n4 < v31 then
                v33 = false
            elseif v31 == v31 then
                v32 = n4
                v33 = true
            else
                v33 = false
            end
        else
            v32 = n4
            v33 = true
        end

        if not v33 then
            v32 = if v31 == v31 then v31 else 1e999
        end

        local v46 = n5 + 1
        local v47 = n5 + 2
        local v48 = n5 + 3
        local v49 = n5 + 4
        local v50 = n5 + 5
        local v51 = n5 + 6

        t4[v46] = v19
        t4[v47] = v20
        t4[v48] = v21
        t4[v49] = v22
        t4[v50] = v23
        t4[v51] = v24

        local v52 = n5 + 7
        local v53 = n5 + 8
        local v54 = n5 + 9
        local v55 = n5 + 10
        local v56 = n5 + 11
        local v57 = n5 + 12

        t4[v52] = v25
        t4[v53] = v26
        t4[v54] = v27
        t4[v55] = v28
        t4[v56] = v29
        t4[v57] = v30
        n4 = v32
        n5 += 12
    end

    return n4
end

local function passes_needed(p16, p17) -- line: 239
    if not (p17 > 0) or p16 == 1e999 then
        return 8
    end

    local v60 = math.ceil(math.log(p16 / p17) / 0.6931471805599453)

    if v60 < 1 then
        return 1
    end

    if v60 > 8 then
        return 8
    end

    return v60
end

local t5 = {}
local t6 = {}
local t7 = {}
local t8 = {}

local function passes_scalar(p18, p19, p20, p21, p22, p23, p24, p25, p26) -- line: 252
    -- upvalues: t1 (copy), v3 (ref), n1 (ref), t3 (copy), rider_change (copy), t5 (copy), t6 (copy), t7 (copy), t8 (copy)
    local stats = t1.stats

    if p23 then
        local v61 = v3
        local v62 = n1
        local v63 = t1.RIDER_FIRST + 1
        local v65 = math.min(t1.RIDER_LAST + 1, p24)
        local v66 = v61 - 1
        local v67 = false
        local v68 = true
        local n6 = 0
        local v69 = p25

        for i = 1, p25 do
            if v68 then
                for j = 1, p18 do
                    p19[j](p20[j], p21[j], p22[j])
                end

                if i < p25 and v66 <= i then
                    local v70 = rider_change(p26, v63, v65, v67)

                    if v67 then
                        stats.checks += 1

                        if v70 <= v62 then
                            v68 = false
                            v69 = i

                            for k = 1, p18 do
                                v69 = i

                                if t3[k] then
                                    n6 += 1

                                    local v71 = p19[k]
                                    local v72 = p20[k]
                                    local v73 = p21[k]
                                    local v74 = p22[k]

                                    t5[n6] = v71
                                    t6[n6] = v72
                                    t7[n6] = v73
                                    t8[n6] = v74
                                end

                                v68 = false
                            end
                        else
                            local v75

                            if not (v62 > 0) or v70 == 1e999 then
                                v75 = 8
                            else
                                v75 = math.ceil(math.log(v70 / v62) / 0.6931471805599453)

                                if v75 < 1 then
                                    v75 = 1
                                elseif v75 > 8 then
                                    v75 = 8
                                end
                            end

                            if v75 >= 2 then
                                v67 = false
                                v66 = i + v75 - 1
                            end
                        end
                    else
                        v67 = true
                    end
                end
            else
                for n = 1, n6 do
                    t5[n](t6[n], t7[n], t8[n])
                end
            end
        end

        if n6 > 0 then
            for i = 1, n6 do
                t5[i] = nil
                t6[i] = nil
                t7[i] = nil
                t8[i] = nil
            end

            stats.stopped += 1
        end

        stats.split += 1
        stats.rider_passes += v69
    else
        for _ = 1, p25 do
            for i = 1, p18 do
                p19[i](p20[i], p21[i], p22[i])
            end
        end
    end
end

local create, cross, dot, min = vector.create, vector.cross, vector.dot, vector.min
local max, abs = vector.max, vector.abs
local F32_MAX = rt.F32_MAX

local function drive_row(p27, p28) -- line: 355
    -- upvalues: create (copy)
    p28[1] = create(p27[1], p27[2], p27[3])
    p28[2] = create(p27[5], p27[6], p27[7])
    p28[3] = create(p27[9], p27[10], p27[11])
    p28[4] = create(p27[13], p27[14], p27[15])
    p28[5] = create(p27[17], p27[18], p27[19])
    p28[6] = create(p27[25], p27[26], p27[27])
    p28[7] = create(p27[33], p27[34], p27[35])
    p28[8] = create(p27[21], p27[22], p27[23])
    p28[9] = create(p27[29], p27[30], p27[31])
    p28[10] = create(p27[37], p27[38], p27[39])
    p28[11] = create(p27[41], p27[42], p27[43])
    p28[12] = create(p27[45], p27[46], p27[47])
    p28[13] = create(p27[28], p27[32], p27[44])
    p28[14] = create(p27[36], p27[40], p27[48])
    p28[15] = create(p27[49], p27[50], p27[51])
    p28[16] = create(p27[53], p27[54], p27[55])
    p28[17] = create(p27[57], p27[58], p27[59])
    p28[18] = create(p27[61], p27[62], p27[63])
    p28[19] = create(p27[65], p27[66], p27[67])
    p28[20] = create(p27[69], p27[70], p27[71])
    p28[21] = create(p27[73], p27[74], p27[75])
    p28[22] = create(p27[77], p27[78], p27[79])
    p28[23] = create(p27[81], p27[82], p27[83])
    p28[24] = create(p27[85], p27[86], p27[87])
    p28[25] = create(p27[89], p27[90], p27[91])
    p28[26] = create(p27[93], p27[94], p27[95])
    p28[27] = p27[12]
    p28[28] = p27[16]
    p28[29] = p27[76]
    p28[30] = p27[88]
end

t1.drive_row = drive_row

local function drive_row_angular(p29, p30) -- line: 390
    -- upvalues: create (copy)
    p30[4] = create(p29[13], p29[14], p29[15])
    p30[8] = create(p29[21], p29[22], p29[23])
    p30[9] = create(p29[29], p29[30], p29[31])
    p30[10] = create(p29[37], p29[38], p29[39])
    p30[12] = create(p29[45], p29[46], p29[47])
    p30[14] = create(p29[36], p29[40], p29[48])
    p30[18] = create(p29[61], p29[62], p29[63])
    p30[19] = create(p29[65], p29[66], p29[67])
    p30[20] = create(p29[69], p29[70], p29[71])
    p30[21] = create(p29[73], p29[74], p29[75])
    p30[22] = create(p29[77], p29[78], p29[79])
    p30[23] = create(p29[81], p29[82], p29[83])
    p30[24] = create(p29[85], p29[86], p29[87])
    p30[25] = create(p29[89], p29[90], p29[91])
    p30[26] = create(p29[93], p29[94], p29[95])
    p30[28] = p29[16]
end

t1.drive_row_angular = drive_row_angular

local function drive_kernel(p31, p32, p33) -- line: 410
    -- upvalues: cross (copy), min (copy), max (copy)
    local v201 = p32[3]
    local v202 = p33[3]
    local v203 = p31[1]
    local v204 = p31[2]
    local v205 = cross(v202, v204) + p33[1] - (cross(v201, v203) + p32[1])
    local v206 = v202 - v201
    local v207 = p31[3]
    local v208 = p31[4]
    local v209 = p31[7] * v205.z + (p31[6] * v205.y + (p31[5] * v205.x + v207))
    local v210 = p31[10] * v206.z + (p31[9] * v206.y + (p31[8] * v206.x + v208))
    local v211 = p31[13]
    local v212 = p31[14]
    local v216 = max(min(v209 * p31[27] + p31[11], v211), -v211)
    local v220 = max(min(v210 * p31[28] + p31[12], v212), -v212)
    local v221 = v216 - v207
    local v222 = v220 - v208

    p31[3] = v216
    p31[4] = v220

    local v223 = p31[17] * v221.z + (p31[16] * v221.y + p31[15] * v221.x)
    local v224 = p31[20] * v222.z + (p31[19] * v222.y + p31[18] * v222.x)
    local v225 = cross(v203, v223) + v224
    local v226 = cross(v204, v223) + v224

    p32[1] = v223 * p31[29] + p32[1]
    p33[1] -= v223 * p31[30]
    p32[3] = p31[23] * v225.z + (p31[22] * v225.y + (p31[21] * v225.x + v201))
    p33[3] = v202 - p31[24] * v226.x - p31[25] * v226.y - p31[26] * v226.z
end

t1.drive = drive_kernel

local function drive_angular_kernel(p34, p35, p36) -- line: 438
    -- upvalues: min (copy), max (copy)
    local v227 = p35[3]
    local v228 = p36[3]
    local v229 = v228 - v227
    local v230 = p34[4]
    local v231 = p34[10] * v229.z + (p34[9] * v229.y + (p34[8] * v229.x + v230))
    local v232 = p34[14]
    local v236 = max(min(v231 * p34[28] + p34[12], v232), -v232)
    local v237 = v236 - v230

    p34[4] = v236

    local v238 = p34[20] * v237.z + (p34[19] * v237.y + p34[18] * v237.x)

    p35[3] = p34[23] * v238.z + (p34[22] * v238.y + (p34[21] * v238.x + v227))
    p36[3] = v228 - p34[24] * v238.x - p34[25] * v238.y - p34[26] * v238.z
end

t1.drive_angular = drive_angular_kernel

local function joint_row(p37, p38) -- line: 453
    -- upvalues: create (copy)
    p38[1] = create(p37[1], p37[2], p37[3])
    p38[2] = create(p37[5], p37[6], p37[7])
    p38[3] = create(p37[9], p37[10], p37[11])
    p38[4] = create(p37[13], p37[14], p37[15])
    p38[5] = create(p37[17], p37[18], p37[19])
    p38[6] = create(p37[25], p37[26], p37[27])
    p38[7] = create(p37[33], p37[34], p37[35])
    p38[8] = create(p37[21], p37[22], p37[23])
    p38[9] = create(p37[29], p37[30], p37[31])
    p38[10] = create(p37[37], p37[38], p37[39])
    p38[11] = create(p37[41], p37[42], p37[43])
    p38[12] = create(p37[45], p37[46], p37[47])
    p38[13] = create(p37[28], p37[32], p37[44])
    p38[14] = create(p37[36], p37[40], p37[48])
    p38[15] = create(p37[49], p37[50], p37[51])
    p38[16] = create(p37[53], p37[54], p37[55])
    p38[17] = create(p37[57], p37[58], p37[59])
    p38[18] = create(p37[61], p37[62], p37[63])
    p38[19] = create(p37[65], p37[66], p37[67])
    p38[20] = create(p37[69], p37[70], p37[71])
    p38[21] = create(p37[73], p37[74], p37[75])
    p38[22] = create(p37[77], p37[78], p37[79])
    p38[23] = create(p37[81], p37[82], p37[83])
    p38[24] = create(p37[85], p37[86], p37[87])
    p38[25] = create(p37[89], p37[90], p37[91])
    p38[26] = create(p37[93], p37[94], p37[95])
    p38[27] = p37[12]
    p38[28] = p37[16]
    p38[29] = p37[76]
    p38[30] = p37[88]
    p38[31] = p37[44]
    p38[32] = p37[48]
    p38[33] = p37[20]
    p38[34] = p37[28]
    p38[35] = p37[36]
    p38[36] = p37[24]
    p38[37] = p37[32]
    p38[38] = p37[40]
end

t1.joint_row = joint_row

local function joint_kernel(p39, p40, p41) -- line: 495
    -- upvalues: create (copy), cross (copy), min (copy), max (copy)
    local v317 = p40[3]
    local v318 = p41[3]
    local v319 = p39[1]
    local v320 = p39[2]
    local v321 = cross(v318, v320) + p41[1] - (cross(v317, v319) + p40[1])
    local v322 = v318 - v317
    local v323 = p39[3]
    local v324 = p39[4]
    local x, y, z = v321.x, v321.y, v321.z
    local x2, y2, z2 = v322.x, v322.y, v322.z
    local v325 = p39[7] * z + (p39[6] * y + (p39[5] * x + v323))
    local v326 = p39[10] * z2 + (p39[9] * y2 + (p39[8] * x2 + v324))
    local v327 = p39[31]
    local v328 = p39[32]
    local v329 = p39[35] * z + (p39[34] * y + (p39[33] * x + p39[27]))
    local v330 = p39[38] * z2 + (p39[37] * y2 + (p39[36] * x2 + p39[28]))
    local v334 = max(p39[13] + v326, (Vector3.new(0, 0, 0))) + min(p39[14] + v326, (Vector3.new(0, 0, 0)))
    local v338 = max(p39[11] + v325, (Vector3.new(0, 0, 0))) + min(p39[12] + v325, (Vector3.new(0, 0, 0)))
    local v339 = v328 + v330
    local v340 = v327 + v330

    if not (v340 > 0) then
        v340 = 0
    end

    if not (v339 < 0) then
        v339 = 0
    end

    p39[28] = create(v340 + v339, 0, 0).x

    local v342 = v328 + v329
    local v343 = v327 + v329

    if not (v343 > 0) then
        v343 = 0
    end

    if not (v342 < 0) then
        v342 = 0
    end

    p39[27] = create(v343 + v342, 0, 0).x

    local v345 = v334 - v324
    local v346 = v338 - v323

    p39[4] = v334
    p39[3] = v338

    local v347 = p39[17] * v346.z + (p39[16] * v346.y + p39[15] * v346.x)
    local v348 = p39[20] * v345.z + (p39[19] * v345.y + p39[18] * v345.x)
    local v349 = cross(v319, v347) + v348
    local v350 = cross(v320, v347) + v348

    p40[1] = v347 * p39[29] + p40[1]
    p41[1] -= v347 * p39[30]
    p40[3] = p39[23] * v349.z + (p39[22] * v349.y + (p39[21] * v349.x + v317))
    p41[3] = v318 - p39[24] * v350.x - p39[25] * v350.y - p39[26] * v350.z
end

t1.joint = joint_kernel

local function contact_row(p42, p43) -- line: 532
    -- upvalues: create (copy)
    p43[1] = create(p42[1], p42[2], p42[3])
    p43[2] = create(p42[5], p42[6], p42[7])
    p43[3] = create(p42[9], p42[10], p42[11])
    p43[4] = create(p42[13], p42[14], p42[15])
    p43[5] = create(p42[17], p42[18], p42[19])
    p43[6] = create(p42[9], p42[13], p42[17])
    p43[7] = create(p42[21], p42[22], p42[23])
    p43[8] = create(p42[25], p42[26], p42[27])
    p43[9] = create(p42[29], p42[30], p42[31])
    p43[10] = create(p42[41], p42[42], p42[43])
    p43[11] = create(p42[53], p42[54], p42[55])
    p43[12] = create(p42[33], p42[34], p42[35])
    p43[13] = create(p42[45], p42[46], p42[47])
    p43[14] = create(p42[57], p42[58], p42[59])
    p43[15] = create(p42[37], p42[38], p42[39])
    p43[16] = create(p42[49], p42[50], p42[51])
    p43[17] = create(p42[61], p42[62], p42[63])
    p43[18] = p42[24]
    p43[19] = p42[28]
    p43[20] = p42[16]
    p43[21] = p42[20]
    p43[22] = p42[36]
    p43[23] = p42[40]
    p43[24] = p42[65] == 1
end

t1.contact_row = contact_row

local function contact_kernel(p44, p45, p46) -- line: 561
    -- upvalues: create (copy), cross (copy), dot (copy), F32_MAX (copy)
    local v402 = p45[1]
    local v403 = p45[2]
    local v404 = p45[3]
    local v405 = p45[4]
    local v406 = p46[1]
    local v407 = p46[2]
    local v408 = p46[3]
    local v409 = p46[4]
    local v410 = p44[1]
    local v411 = p44[2]
    local v412 = cross(v409, v411) + v407 - (cross(v405, v410) + v403)
    local v413 = cross(v408, v411) + v406 - (cross(v404, v410) + v402) + v412
    local v414 = p44[7]
    local v415 = p44[18]
    local v416 = p44[5] * v413.z + (p44[4] * v413.y + (p44[3] * v413.x + (v414 + p44[8])))
    local v418 = dot(p44[6], v412) + (v415 + p44[19])
    local v419 = p44[20]
    local v420 = p44[21]
    local x = v414.x
    local x2 = v416.x
    local v421 = if x2 >= 0 then x2 else 0

    if not (x2 <= F32_MAX) then
        v421 = F32_MAX
    end

    local v422 = if v418 >= 0 then v418 else 0

    if not (v418 <= F32_MAX) then
        v422 = F32_MAX
    end

    local v423 = v419 * x
    local v424 = v420 * x
    local y, z = v416.y, v416.z
    local v425 = if -v423 <= y then y else -v424

    if not (y <= v423) then
        v425 = v424
    end

    local v426 = if -v423 <= z then z else -v424

    if not (z <= v423) then
        v426 = v424
    end

    local v427 = create(v421, v425, v426)
    local x3 = create(v422, 0, 0).x
    local v428 = v427 - v414
    local x4 = create(x3 - v415, 0, 0).x

    p44[7] = v427
    p44[18] = x3

    if x4 == 0 and v428 == Vector3.new(0, 0, 0) and p44[24] then
        return
    end

    local x5, y2, z2 = v428.x, v428.y, v428.z
    local v430 = p44[9]
    local v431 = p44[11] * z2 + (p44[10] * y2 + v430 * x5)
    local v432 = v430 * x4
    local v433 = p44[22]
    local v434 = p44[23]
    local v435 = p44[12]
    local v436 = p44[15]

    p45[3] = p44[14] * z2 + (p44[13] * y2 + (v435 * x5 + v404))
    p45[4] = v435 * x4 + v405
    p45[1] = v431 * v433 + v402
    p45[2] = v432 * v433 + v403
    p46[3] = v408 - v436 * x5 - p44[16] * y2 - p44[17] * z2
    p46[4] = v409 - v436 * x4
    p46[1] = v406 - v431 * v434
    p46[2] = v407 - v432 * v434
end

t1.contact = contact_kernel

local function contact_b0_kernel(p47, p48) -- line: 624
    -- upvalues: create (copy), cross (copy), dot (copy), F32_MAX (copy)
    local v437 = p48[1]
    local v438 = p48[2]
    local v439 = p48[3]
    local v440 = p48[4]
    local v441 = p47[1]
    local v442 = -(cross(v440, v441) + v438)
    local v443 = v442 - (cross(v439, v441) + v437)
    local v444 = p47[7]
    local v445 = p47[18]
    local v446 = p47[5] * v443.z + (p47[4] * v443.y + (p47[3] * v443.x + (v444 + p47[8])))
    local v448 = dot(p47[6], v442) + (v445 + p47[19])
    local v449 = p47[20]
    local v450 = p47[21]
    local x = v444.x
    local x2 = v446.x
    local v451 = if x2 >= 0 then x2 else 0

    if not (x2 <= F32_MAX) then
        v451 = F32_MAX
    end

    local v452 = if v448 >= 0 then v448 else 0

    if not (v448 <= F32_MAX) then
        v452 = F32_MAX
    end

    local v453 = v449 * x
    local v454 = v450 * x
    local y, z = v446.y, v446.z
    local v455 = if -v453 <= y then y else -v454

    if not (y <= v453) then
        v455 = v454
    end

    local v456 = if -v453 <= z then z else -v454

    if not (z <= v453) then
        v456 = v454
    end

    local v457 = create(v451, v455, v456)
    local x3 = create(v452, 0, 0).x
    local v458 = v457 - v444
    local x4 = create(x3 - v445, 0, 0).x

    p47[7] = v457
    p47[18] = x3

    if x4 == 0 and v458 == Vector3.new(0, 0, 0) and p47[24] then
        return
    end

    local x5, y2, z2 = v458.x, v458.y, v458.z
    local v460 = p47[9]
    local v461 = p47[11] * z2 + (p47[10] * y2 + v460 * x5)
    local v462 = v460 * x4
    local v463 = p47[22]
    local v464 = p47[12]

    p48[3] = p47[14] * z2 + (p47[13] * y2 + (v464 * x5 + v439))
    p48[4] = v464 * x4 + v440
    p48[1] = v461 * v463 + v437
    p48[2] = v462 * v463 + v438
end

t1.contact_b0 = contact_b0_kernel

local t9 = {}
local t10 = {}
local t11 = {}
local t12 = {}
local t13 = {}
local t14 = {}
local t15 = {}
local t16 = {}
local t17 = {}

local function pooled(p49, p50, p51) -- line: 692
    local v465 = p49[p50]

    if v465 == nil then
        v465 = table.create(p51, false)
        p49[p50] = v465
    end

    return v465
end

local function rider_change_vector(p52, p53, p54) -- line: 701
    -- upvalues: max (copy), abs (copy), t12 (copy), t17 (copy)
    local v466 = Vector3.new(0, 0, 0)
    local n7 = 0
    local v467 = false

    for i = p52, p53 do
        local v468 = t12[i]
        local v469 = v468[1]
        local v470 = v468[2]
        local v471 = v468[3]
        local v472 = v468[4]
        local v473, v474

        if p54 then
            local v485 = max(max(abs(v469 - t17[n7 + 1]), (abs(v470 - t17[n7 + 2]))), (max(abs(v471 - t17[n7 + 3]), (abs(v472 - t17[n7 + 4])))))

            v474 = v485 ~= v485 or v467
            v473 = max(v466, v485)
        else
            v474 = v467
            v473 = v466
        end

        v467 = v474

        local v486 = n7 + 1
        local v487 = n7 + 2
        local v488 = n7 + 3
        local v489 = n7 + 4

        t17[v486] = v469
        t17[v487] = v470
        t17[v488] = v471
        t17[v489] = v472
        v466 = v473
        n7 += 4
    end

    if v467 then
        return 1e999
    end

    return (math.max(v466.x, v466.y, v466.z))
end

local function passes_vector(_, p56, p57, p58, p59, p60, p61, p62, p63, p64, p65, p66, p67, p68, p69, p70) -- line: 726
    -- upvalues: v1 (copy), v2 (copy), t1 (copy), v3 (ref), n1 (ref), t3 (copy), t5 (copy), create (copy), drive_row (copy), drive_row_angular (copy), drive_kernel (copy), drive_angular_kernel (copy), joint_row (copy), joint_kernel (copy), contact_row (copy), contact_kernel (copy), contact_b0_kernel (copy), t9 (copy), t10 (copy), t11 (copy), t12 (copy), t13 (copy), t14 (copy), t15 (copy), t16 (copy), rider_change_vector (copy)
    local stats = t1.stats

    for i = 1, p68 do
        local v490 = p70[i]
        local v491 = t12[i]

        if v491 == nil then
            v491 = table.create(4, (Vector3.new(0, 0, 0)))
            t12[i] = v491
        end

        v491[1] = create(v490[1], v490[2], v490[3])
        v491[2] = create(v490[5], v490[6], v490[7])
        v491[3] = create(v490[9], v490[10], v490[11])
        v491[4] = create(v490[13], v490[14], v490[15])
    end

    local solve_w3_b0 = v1.solve_w3_b0
    local n8 = 0
    local n9 = 0

    for i = 1, p58 do
        local v504 = t9[i]

        if v504 == nil then
            v504 = table.create(24, false)
            t9[i] = v504
        end

        contact_row(p57[i], v504)
        n8 += 1
        t13[n8] = if p56[i] == solve_w3_b0 then contact_b0_kernel else contact_kernel
        t14[n8] = v504
        t15[n8] = t12[p59[i] + 1]
        t16[n8] = t12[p60[i] + 1]

        if p67 and t3[i] then
            n9 += 1
            t5[n9] = n8
        end
    end

    for i = 1, p61 do
        local v506 = t10[i]

        if v506 == nil then
            v506 = table.create(38, false)
            t10[i] = v506
        end

        joint_row(p57[p58 + i], v506)
        n8 += 1
        t13[n8] = joint_kernel
        t14[n8] = v506
        t15[n8] = t12[p62[i] + 1]
        t16[n8] = t12[p63[i] + 1]

        if p67 and t3[p58 + i] then
            n9 += 1
            t5[n9] = n8
        end
    end

    local v507 = p58 + p61
    local solve_w3_inert, solve_w3_angular = v2.solve_w3_inert, v2.solve_w3_angular

    for i = 1, p64 do
        local v508 = p56[v507 + i]
        local v509
        local v510 = n9

        if v508 == solve_w3_inert then
            v509 = n8
        else
            local v511 = t11[i]

            if v511 == nil then
                v511 = table.create(30, false)
                t11[i] = v511
            end

            v509 = n8 + 1

            if v508 == solve_w3_angular then
                drive_row_angular(p57[v507 + i], v511)
                t13[v509] = drive_angular_kernel
            else
                drive_row(p57[v507 + i], v511)
                t13[v509] = drive_kernel
            end

            t14[v509] = v511
            t15[v509] = t12[p65[i] + 1]
            t16[v509] = t12[p66[i] + 1]

            if p67 and t3[v507 + i] then
                v510 = n9 + 1
                t5[v510] = v509
            end
        end

        n9 = v510
        n8 = v509
    end

    if p67 then
        local v512 = v3
        local v513 = n1
        local v514 = t1.RIDER_FIRST + 1
        local v516 = math.min(t1.RIDER_LAST + 1, p68)
        local v517 = false
        local v518 = v512 - 1
        local v519 = true
        local v520 = p69

        for i = 1, p69 do
            if v519 then
                for j = 1, n8 do
                    t13[j](t14[j], t15[j], t16[j])
                end

                if i < p69 and v518 <= i then
                    local v521 = rider_change_vector(v514, v516, v517)

                    if v517 then
                        stats.checks += 1

                        if v521 <= v513 then
                            v520 = i
                            v519 = false
                        else
                            local v522

                            if not (v513 > 0) or v521 == 1e999 then
                                v522 = 8
                            else
                                v522 = math.ceil(math.log(v521 / v513) / 0.6931471805599453)

                                if v522 < 1 then
                                    v522 = 1
                                elseif v522 > 8 then
                                    v522 = 8
                                end
                            end

                            if v522 >= 2 then
                                v517 = false
                                v518 = i + v522 - 1
                            end
                        end
                    else
                        v517 = true
                    end
                end
            else
                for k = 1, n9 do
                    local v525 = t5[k]

                    t13[v525](t14[v525], t15[v525], t16[v525])
                end
            end
        end

        if not v519 then
            stats.stopped += 1
        end

        stats.split += 1
        stats.rider_passes += v520
    else
        for _ = 1, p69 do
            for i = 1, n8 do
                t13[i](t14[i], t15[i], t16[i])
            end
        end
    end

    for i = 1, n9 do
        t5[i] = nil
    end

    for i = 1, p58 do
        local v526 = t9[i]
        local v527 = p57[i]
        local v528 = v526[7]
        local x, y, z = v528.x, v528.y, v528.z
        local v529 = v526[18]

        v527[21] = x
        v527[22] = y
        v527[23] = z
        v527[24] = v529
    end

    for i = 1, p61 do
        local v530 = t10[i]
        local v531 = p57[p58 + i]
        local v532 = v530[3]
        local v533 = v530[4]
        local x, y, z = v532.x, v532.y, v532.z
        local v534 = v530[27]

        v531[9] = x
        v531[10] = y
        v531[11] = z
        v531[12] = v534

        local x2, y2, z2 = v533.x, v533.y, v533.z
        local v535 = v530[28]

        v531[13] = x2
        v531[14] = y2
        v531[15] = z2
        v531[16] = v535
    end

    local v536 = p58 + p61

    for i = 1, p64 do
        local v537 = p56[v536 + i]

        if v537 ~= solve_w3_inert then
            local v538 = t11[i]
            local v539 = p57[v536 + i]
            local v540 = v538[4]
            local x, y, z = v540.x, v540.y, v540.z

            v539[13] = x
            v539[14] = y
            v539[15] = z

            if v537 ~= solve_w3_angular then
                local v541 = v538[3]
                local x, y, z = v541.x, v541.y, v541.z

                v539[9] = x
                v539[10] = y
                v539[11] = z
            end
        end
    end

    for i = 1, p68 do
        local v542 = t12[i]
        local v543 = p70[i]
        local v544 = v542[1]
        local v545 = v542[2]
        local v546 = v542[3]
        local v547 = v542[4]
        local x, y, z = v544.x, v544.y, v544.z

        v543[1] = x
        v543[2] = y
        v543[3] = z

        local x2, y2, z2 = v545.x, v545.y, v545.z

        v543[5] = x2
        v543[6] = y2
        v543[7] = z2

        local x3, y3, z3 = v546.x, v546.y, v546.z

        v543[9] = x3
        v543[10] = y3
        v543[11] = z3

        local x4, y4, z4 = v547.x, v547.y, v547.z

        v543[13] = x4
        v543[14] = y4
        v543[15] = z4
    end

    for i = 1, n8 do
        t13[i] = nil
        t14[i] = nil
        t15[i] = nil
        t16[i] = nil
    end
end

function t1.passes(p71, p72, p73, p74, p75, p76, p77, p78, p79, p80, p81, p82, p83, p84, p85, p86, p87) -- line: 915
    -- upvalues: t1 (copy), v3 (ref), v4 (ref), classify (copy), passes_scalar (copy), passes_vector (copy)
    local stats = t1.stats

    stats.solves += 1
    stats.passes += p86

    local v548 = v3 ~= nil and v3 < p86 and t1.RIDER_FIRST < p85 and classify(p72, p76, p77, p78, p79, p80, p81, p82, p83, p84)

    if v4 then
        passes_vector(p71, p72, p73, p76, p77, p78, p79, p80, p81, p82, p83, p84, v548, p85, p86, p87)
    else
        passes_scalar(p71, p72, p73, p74, p75, v548, p85, p86, p87)
    end
end

return t1
