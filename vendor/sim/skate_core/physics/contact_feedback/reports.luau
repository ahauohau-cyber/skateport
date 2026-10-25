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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

require(sim.import)

local t1 = {
    ContactTarget = {},
    ContactReportBuffer = {},
    get_contact_reports = function(p4, p5) -- get_contact_reports | line: 52
        p5.lock(p5)

        local v8 = p5.get_or_insert_reports(p5, p4)

        p5.unlock(p5)

        return v8
    end,
    resolve_contact_reports = function(p6) -- resolve_contact_reports | line: 67
        local v9 = p6.first_report_entry(p6)

        while v9 ~= nil do
            if p6.report_count(p6, v9) ~= 0 then
                p6.dispatch_reports(p6, v9)
            end

            v9 = p6.next_report_entry(p6, v9)
        end
    end
}

function t1.create_contact_reports(p7, p8, p9) -- line: 82
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    p9.lock(p9)
    p9.clear_report_counts(p9)

    for i = 0, #p7 - 1 do
        local v10 = p7[i + 1]
        local v11 = p9.lookup_target(p9, v10[25])
        local v12 = p9.lookup_target(p9, v10[26])
        local v13 = if v11 == nil then 0 else v11.body
        local v14 = if v12 == nil then 0 else v12.body
        local v15 = if v11 == nil then 0 else v11.owner
        local v16 = if v12 == nil then 0 else v12.owner
        local v17 = v11 ~= nil and v12 ~= nil and v13 == v14

        if not v17 then
            v17 = v15 ~= 0 and v15 == v16
        end

        for j = 1, 2 do
            local v18, v19

            if j == 1 then
                v18 = v11
                v19 = true
            else
                v18 = v12
                v19 = false
            end

            local v20, count, v21

            if v18 ~= nil then
                v20 = p9.get_or_insert_reports(p9, v18.body)
                count = p9.reports(p9, v20).count

                if not (count >= 16) and not v17 then
                    v21 = if v19 then v10[26] else v10[25]

                    local v22 = if v19 then v10[25] else v10[26]
                    local v23 = rt.map(p9.linear_velocity(p9, v21), rt.from_bits)
                    local v24 = rt.map(p9.linear_velocity(p9, v22), rt.from_bits)

                    buffer.writeu32(v1, 0, v10[1])

                    local v26 = buffer.readf32(v1, 0) * (if v19 then 1 else -1)
                    local v27

                    if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
                        local v28 = math.abs(v26) * 7.1362384635298E+44
                        local v29 = math.floor(v28)
                        local v30 = v28 - v29
                        local v31 = if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29

                        v27 = if v26 < 0 then v31 + 2147483648 else v31
                    else
                        buffer.writef32(v1, 0, v26)
                        v27 = buffer.readu32(v1, 0)
                    end

                    buffer.writeu32(v1, 0, v10[2])

                    local v33 = buffer.readf32(v1, 0) * (if v19 then 1 else -1)
                    local v34

                    if v33 ~= 0 and v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
                        local v35 = math.abs(v33) * 7.1362384635298E+44
                        local v36 = math.floor(v35)
                        local v37 = v35 - v36
                        local v38 = if v37 > 0.5 or v37 == 0.5 and v36 % 2 == 1 then v36 + 1 else v36

                        v34 = if v33 < 0 then v38 + 2147483648 else v38
                    else
                        buffer.writef32(v1, 0, v33)
                        v34 = buffer.readu32(v1, 0)
                    end

                    buffer.writeu32(v1, 0, v10[3])

                    local v40 = buffer.readf32(v1, 0) * (if v19 then 1 else -1)
                    local v41

                    if v40 ~= 0 and v40 > -1.1754943508222875E-38 and v40 < 1.1754943508222875E-38 then
                        local v42 = math.abs(v40) * 7.1362384635298E+44
                        local v43 = math.floor(v42)
                        local v44 = v42 - v43
                        local v45 = if v44 > 0.5 or v44 == 0.5 and v43 % 2 == 1 then v43 + 1 else v43

                        v41 = if v40 < 0 then v45 + 2147483648 else v45
                    else
                        buffer.writef32(v1, 0, v40)
                        v41 = buffer.readu32(v1, 0)
                    end

                    buffer.writeu32(v1, 0, v10[4])

                    local v47 = buffer.readf32(v1, 0) * (if v19 then 1 else -1)
                    local v48

                    if v47 ~= 0 and v47 > -1.1754943508222875E-38 and v47 < 1.1754943508222875E-38 then
                        local v49 = math.abs(v47) * 7.1362384635298E+44
                        local v50 = math.floor(v49)
                        local v51 = v49 - v50
                        local v52 = if v51 > 0.5 or v51 == 0.5 and v50 % 2 == 1 then v50 + 1 else v50

                        v48 = if v47 < 0 then v52 + 2147483648 else v52
                    else
                        buffer.writef32(v1, 0, v47)
                        v48 = buffer.readu32(v1, 0)
                    end

                    local t2 = {
                        v27,
                        v34,
                        v41,
                        v48
                    }
                    local v53 = v24[1] - v23[1]
                    local v54

                    if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
                        local v55 = math.abs(v53) * 7.1362384635298E+44
                        local v56 = math.floor(v55)
                        local v57 = v55 - v56
                        local v58 = if v57 > 0.5 or v57 == 0.5 and v56 % 2 == 1 then v56 + 1 else v56

                        v54 = if v53 < 0 then v58 + 2147483648 else v58
                    else
                        buffer.writef32(v1, 0, v53)
                        v54 = buffer.readu32(v1, 0)
                    end

                    local v59 = v24[2] - v23[2]
                    local v60

                    if v59 ~= 0 and v59 > -1.1754943508222875E-38 and v59 < 1.1754943508222875E-38 then
                        local v61 = math.abs(v59) * 7.1362384635298E+44
                        local v62 = math.floor(v61)
                        local v63 = v61 - v62
                        local v64 = if v63 > 0.5 or v63 == 0.5 and v62 % 2 == 1 then v62 + 1 else v62

                        v60 = if v59 < 0 then v64 + 2147483648 else v64
                    else
                        buffer.writef32(v1, 0, v59)
                        v60 = buffer.readu32(v1, 0)
                    end

                    local v65 = v24[3] - v23[3]
                    local v66

                    if v65 ~= 0 and v65 > -1.1754943508222875E-38 and v65 < 1.1754943508222875E-38 then
                        local v67 = math.abs(v65) * 7.1362384635298E+44
                        local v68 = math.floor(v67)
                        local v69 = v67 - v68
                        local v70 = if v69 > 0.5 or v69 == 0.5 and v68 % 2 == 1 then v68 + 1 else v68

                        v66 = if v65 < 0 then v70 + 2147483648 else v70
                    else
                        buffer.writef32(v1, 0, v65)
                        v66 = buffer.readu32(v1, 0)
                    end

                    local v71 = v24[4] - v23[4]
                    local v72

                    if v71 ~= 0 and v71 > -1.1754943508222875E-38 and v71 < 1.1754943508222875E-38 then
                        local v73 = math.abs(v71) * 7.1362384635298E+44
                        local v74 = math.floor(v73)
                        local v75 = v73 - v74
                        local v76 = if v75 > 0.5 or v75 == 0.5 and v74 % 2 == 1 then v74 + 1 else v74

                        v72 = if v71 < 0 then v76 + 2147483648 else v76
                    else
                        buffer.writef32(v1, 0, v71)
                        v72 = buffer.readu32(v1, 0)
                    end

                    local t3 = {
                        v54,
                        v60,
                        v66,
                        v72
                    }
                    local v77 = p9.reports(p9, v20)
                    local v78 = v77.records[count + 1]

                    t1.put(v78, 0, rt.wrapping_add_u32(p8, rt.wrapping_mul_u32(i, 112)))

                    for k = 0, 3 do
                        t1.put(v78, k * 4 + 16, t2[k + 1])
                        t1.put(v78, k * 4 + 32, v10[k + 12 + 1])
                        t1.put(v78, k * 4 + 48, t3[k + 1])
                    end

                    t1.put(v78, 64, v18.tag)
                    t1.put(v78, 68, if v19 then bit32.band(v10[27], 65535) else bit32.rshift(v10[27], 16))
                    t1.put(v78, 72, v18.body)
                    t1.put(v78, 76, if v19 then v14 else v13)
                    v78[81] = 0
                    v78[82] = v19 and 1 or 0
                    v77.count += 1
                end
            end
        end
    end

    p9.unlock(p9)
end

function t1.put(p10, p11, p12) -- line: 148
    p10[p11 + 1] = bit32.band(bit32.rshift(p12, 24), 255)
    p10[p11 + 2] = bit32.band(bit32.rshift(p12, 16), 255)
    p10[p11 + 3] = bit32.band(bit32.rshift(p12, 8), 255)
    p10[p11 + 4] = bit32.band(p12, 255)
end

return t1
