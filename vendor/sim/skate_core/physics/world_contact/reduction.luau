-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/physics/world_contact/arithmetic")
local cross, dot, scale, sub = v1.cross, v1.dot, v1.scale, v1.sub
local vector = v1.vector
local t1 = {}
local v2 = false

local function coplanar_contacts_reference(p1, p2) -- line: 22
    -- upvalues: dot (copy), sub (copy), vector (copy)
    local v3 = vector(p1, 8)

    if dot(v3, vector(p2, 8)) < 0.9990000128746033 then
        return false
    end

    local v5 = math.abs((dot(v3, sub(vector(p1, 0), vector(p2, 0)))))
    local v7 = math.abs((dot(v3, sub(vector(p1, 4), vector(p2, 4)))))

    if not (v5 - v7 >= 0) then
        v7 = v5
    end

    return v7 < 0.009999999776482582
end

t1.coplanar_contacts_reference = coplanar_contacts_reference

function t1.set_reference(p3) -- line: 34
    -- upvalues: v2 (ref)
    local v8 = v2

    v2 = p3

    return v8
end

local v9 = buffer.create(8)

local function fb(p4) -- line: 45
    -- upvalues: v9 (copy)
    buffer.writeu32(v9, 0, p4)

    return (buffer.readf32(v9, 0))
end

buffer.writeu32(v9, 0, 1065336439)

local v10 = buffer.readf32(v9, 0)

buffer.writeu32(v9, 0, 1008981770)

local v11 = buffer.readf32(v9, 0)

function t1.coplanar_contacts(p5, p6) -- line: 51
    -- upvalues: v2 (ref), coplanar_contacts_reference (copy), v9 (copy), v10 (copy), v11 (copy)
    if v2 then
        return (coplanar_contacts_reference(p5, p6))
    end

    buffer.writeu32(v9, 0, p5[9])

    local v13 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p5[10])

    local v15 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p5[11])

    local v17 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[9])

    local v19 = v13 * buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[10])

    local v21 = v19 + v15 * buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[11])

    if v21 + v17 * buffer.readf32(v9, 0) < v10 then
        return false
    end

    buffer.writeu32(v9, 0, p5[1])

    local v24 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[1])

    local v26 = v13 * (v24 - buffer.readf32(v9, 0))

    buffer.writeu32(v9, 0, p5[2])

    local v28 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[2])

    local v30 = v26 + v15 * (v28 - buffer.readf32(v9, 0))

    buffer.writeu32(v9, 0, p5[3])

    local v32 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[3])

    local v35 = math.abs(v30 + v17 * (v32 - buffer.readf32(v9, 0)))

    buffer.writeu32(v9, 0, p5[5])

    local v37 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[5])

    local v39 = v13 * (v37 - buffer.readf32(v9, 0))

    buffer.writeu32(v9, 0, p5[6])

    local v41 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[6])

    local v43 = v39 + v15 * (v41 - buffer.readf32(v9, 0))

    buffer.writeu32(v9, 0, p5[7])

    local v45 = buffer.readf32(v9, 0)

    buffer.writeu32(v9, 0, p6[7])

    local v48 = math.abs(v43 + v17 * (v45 - buffer.readf32(v9, 0)))

    if not (v35 - v48 >= 0) then
        v48 = v35
    end

    return v48 < v11
end

function t1.select_contact_points(p7, p8, p9, p10) -- line: 69
    -- upvalues: rt (copy), cross (copy), dot (copy), scale (copy), sub (copy)
    if #p7 == 0 or #p7 ~= #p8 then
        error("assertion failed: !a.is_empty() && a.len() == b.len()", 0)
    end

    local v49 = rt.copy(p7[1])
    local v50 = dot(p9, sub(p7[1], p8[1]))
    local v51 = #p7 - 1
    local n1 = 0

    for i = 1, v51 do
        local v52 = dot(p9, sub(p7[i + 1], p8[i + 1]))

        if v52 < v50 then
            n1 = i
            v49 = rt.copy(p7[i + 1])
            v50 = v52
        end
    end

    local v53 = sub(p7[1], v49)
    local v54 = rt.copy(v53)
    local v55 = dot(v54, v54)
    local v56 = #p7 - 1
    local n2 = 0

    for i = 1, v56 do
        local v58 = sub(p7[i + 1], v49)
        local v59 = dot(v58, v58)

        if v55 < v59 then
            v55 = v59
            v54 = v58
            n2 = i
        end
    end

    if n1 == n2 then
        p10[1] = n1

        return 1
    end

    local v60 = cross(v53, v54)
    local v61 = dot(v60, v60)
    local v62 = #p7 - 1
    local n3 = 0

    for i = 1, v62 do
        local v64 = sub(p7[i + 1], v49)
        local v65 = cross(v64, v54)
        local v66 = dot(v65, v65)

        if v61 < v66 then
            v61 = v66
            v53 = v64
            n3 = i
        end
    end

    p10[1] = n1
    p10[2] = n2
    p10[3] = n3

    if n3 == n1 or n3 == n2 then
        return 2
    end

    local v67 = cross(p9, v54)
    local v68 = if dot(v67, v53) >= 0 then 1 else -1
    local v69 = scale(v67, v68)
    local v70 = scale(cross(p9, v53), v68)
    local v71 = sub(v53, v54)
    local v72 = #p7 - 1
    local n4 = 9999
    local n5 = -1

    for i = 0, v72 do
        local v74 = sub(p7[i + 1], v49)
        local v75 = if not (dot(v74, v69) > 0) then cross(v74, v54) elseif dot(v74, v70) > 0 then cross(v74, v53) else cross(sub(v74, v54), v71)
        local v76 = dot(v75, v75)

        if n5 < v76 then
            n5 = v76
            n4 = i
        end
    end

    p10[4] = n4

    return (if n4 ~= n1 and n4 ~= n2 and n4 ~= n3 and n4 ~= 9999 then 1 else 0) + 3
end

function t1.reduce(p11, p12) -- line: 156
    -- upvalues: vector (copy), t1 (copy)
    if not (p12 <= 50) then
        error("assertion failed: original <= 50", 0)
    end

    local v77 = table.create(50, false)
    local v78 = table.create(p12)

    for i = 0, p12 - 1 do
        if not v77[i + 1] then
            v77[i + 1] = true

            local t2 = {
                i
            }

            for j = i + 1, p12 - 1 do
                if not v77[j + 1] and p11[i + 1][4] == p11[j + 1][4] and p11[i + 1][8] == p11[j + 1][8] and t1.coplanar_contacts(p11[i + 1], p11[j + 1]) then
                    v77[j + 1] = true
                    t2[#t2 + 1] = j
                end
            end

            if #t2 <= 4 then
                for _, v79 in t2 do
                    v78[#v78 + 1] = v79
                end
            else
                local v80 = table.create(#t2)

                for v81, v82 in t2 do
                    v80[v81] = vector(p11[v82 + 1], 0)
                end

                local v83 = table.create(#t2)

                for v84, v85 in t2 do
                    v83[v84] = vector(p11[v85 + 1], 4)
                end

                local t3 = {
                    0, 1, 2, 3
                }

                for k = 1, t1.select_contact_points(v80, v83, vector(p11[i + 1], 8), t3) do
                    v78[#v78 + 1] = t2[t3[k] + 1]
                end
            end
        end
    end

    local v86

    if not (#v78 < p12) then
        v86 = p12

        return v86
    end

    table.sort(v78)
    v86 = #v78

    for i = 0, #v78 - 1 do
        local v87 = v78[i + 1]

        if i ~= v87 then
            local v88 = p11[v87 + 1]
            local v89 = table.create(64)

            for j = 1, 64 do
                local v90 = v88[j]

                if bit32.band(v90, 2139095040) ~= 2139095040 or bit32.band(v90, 8388607) == 0 then
                    v89[j] = v90
                else
                    v89[j] = bit32.bor(v90, 4194304)
                end
            end

            p11[i + 1] = v89

            for _, v91 in { 3, 7, 23 } do
                p11[i + 1][v91 + 1] = p11[v87 + 1][v91 + 1]
            end
        end
    end

    return v86
end

return t1
