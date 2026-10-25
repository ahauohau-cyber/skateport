-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {}
local bxor, lshift, rshift = bit32.bxor, bit32.lshift, bit32.rshift

local function sub3(p1, p2, p3, p4, p5, p6) -- line: 20
    local v1 = p2 - p4 - p6
    local v2, v3

    if not (v1 < 0) then
        v3 = v1
        v2 = 0

        return (p1 - p3 - p5 - v2) % 4294967296, v3
    end

    v2 = if v1 < -4294967296 then 2 else 1
    v3 = v1 + v2 * 4294967296

    return (p1 - p3 - p5 - v2) % 4294967296, v3
end

local function add64(p7, p8, p9, p10) -- line: 31
    local v5 = p8 + p10
    local v6 = 0

    if v5 >= 4294967296 then
        v5 -= 4294967296
        v6 = 1
    end

    return (p7 + p9 + v6) % 4294967296, v5
end

local function shr64(p11, p12, p13) -- line: 42
    -- upvalues: bxor (copy), lshift (copy), rshift (copy)
    if p13 >= 32 then
        return 0, (rshift(p11, p13 - 32))
    end

    return rshift(p11, p13), (bxor(rshift(p12, p13), (lshift(p11, 32 - p13))))
end

local function shl64(p14, p15, p16) -- line: 50
    -- upvalues: bxor (copy), lshift (copy), rshift (copy)
    if p16 >= 32 then
        return lshift(p15, p16 - 32), 0
    end

    return bxor(lshift(p14, p16), (rshift(p15, 32 - p16))), (lshift(p15, p16))
end

local t2 = {
    { 43, 9, 8 },
    { 38, 23, 5 },
    { 35, 49, 11 },
    { 12, 18, 22 }
}

function t1.mix(p17, p18, p19, p20, p21, p22) -- line: 61
    -- upvalues: bxor (copy), lshift (copy), rshift (copy), t2 (copy)
    local v17 = p18
    local v18 = p19
    local v19 = p20
    local v20 = p21
    local v21 = p22

    for _, v22 in t2 do
        local v23 = v22[1]
        local v24 = v22[2]
        local v25 = v22[3]
        local v26 = v17 - v19 - v21
        local v27

        if v26 < 0 then
            v27 = if v26 < -4294967296 then 2 else 1
            v26 += v27 * 4294967296
        else
            v27 = 0
        end

        local v28 = (p17 - v18 - v20 - v27) % 4294967296
        local v29, v30

        if v23 >= 32 then
            v29 = 0
            v30 = rshift(v20, v23 - 32)
        else
            v29 = rshift(v20, v23)
            v30 = bxor(rshift(v21, v23), (lshift(v20, 32 - v23)))
        end

        p17 = bxor(v28, v29)
        v17 = bxor(v26, v30)

        local v35 = v19 - v21 - v17
        local v36

        if v35 < 0 then
            v36 = if v35 < -4294967296 then 2 else 1
            v35 += v36 * 4294967296
        else
            v36 = 0
        end

        local v37 = (v18 - v20 - p17 - v36) % 4294967296
        local v38, v39

        if v24 >= 32 then
            v38 = lshift(v17, v24 - 32)
            v39 = 0
        else
            v38 = bxor(lshift(p17, v24), (rshift(v17, 32 - v24)))
            v39 = lshift(v17, v24)
        end

        v18 = bxor(v37, v38)
        v19 = bxor(v35, v39)

        local v44 = v21 - v17 - v19
        local v45

        if v44 < 0 then
            v45 = if v44 < -4294967296 then 2 else 1
            v44 += v45 * 4294967296
        else
            v45 = 0
        end

        local v46 = (v20 - p17 - v18 - v45) % 4294967296
        local v47, v48

        if v25 >= 32 then
            v47 = 0
            v48 = rshift(v18, v25 - 32)
        else
            v47 = rshift(v18, v25)
            v48 = bxor(rshift(v19, v25), (lshift(v18, 32 - v25)))
        end

        v20 = bxor(v46, v47)
        v21 = bxor(v44, v48)
    end

    return p17, v17, v18, v19, v20, v21
end

local function hash_parts(p23) -- line: 82
    -- upvalues: t1 (copy), lshift (copy)
    if #p23 == 0 then
        return 0, 0
    end

    local v53 = buffer.fromstring(p23)
    local v54 = #p23
    local v55 = v54 - v54 % 24
    local n1 = 2882400000
    local n2 = 287454020
    local n3 = 2882400000
    local n4 = 287454020
    local n5 = 2654435769
    local n6 = 2135587859
    local n7 = 0

    while n7 < v55 do
        local v57 = buffer.readu32(v53, n7 + 4)
        local v58 = n2 + buffer.readu32(v53, n7)
        local v59 = 0

        if v58 >= 4294967296 then
            v58 -= 4294967296
            v59 = 1
        end

        local v60 = (n1 + v57 + v59) % 4294967296
        local v62 = buffer.readu32(v53, n7 + 12)
        local v64 = n4 + buffer.readu32(v53, n7 + 8)
        local v65 = 0

        if v64 >= 4294967296 then
            v64 -= 4294967296
            v65 = 1
        end

        local v66 = (n3 + v62 + v65) % 4294967296
        local v68 = buffer.readu32(v53, n7 + 20)
        local v70 = n6 + buffer.readu32(v53, n7 + 16)
        local v71 = 0

        if v70 >= 4294967296 then
            v70 -= 4294967296
            v71 = 1
        end

        local v72 = (n5 + v68 + v71) % 4294967296

        n1, n2, n3, n4, n5, n6 = t1.mix(v60, v58, v66, v64, v72, v70)
        n7 += 24
    end

    local v74 = math.floor(v54 / 4294967296)
    local v75 = n6 + v54 % 4294967296
    local v76 = 0

    if v75 >= 4294967296 then
        v75 -= 4294967296
        v76 = 1
    end

    local v77 = (n5 + v74 + v76) % 4294967296

    for i = 0, v54 - v55 - 1 do
        local v79 = buffer.readu8(v53, v55 + i)

        if i <= 7 then
            local v80 = i * 8

            if v80 >= 32 then
                local v81 = lshift(v79, v80 - 32)
                local v82 = n2 + 0
                local v83 = 0

                if v82 >= 4294967296 then
                    v82 -= 4294967296
                    v83 = 1
                end

                n2 = v82
                n1 = (n1 + v81 + v83) % 4294967296
            else
                n2 += lshift(v79, v80)

                local v84 = 0

                if n2 >= 4294967296 then
                    n2 -= 4294967296
                    v84 = 1
                end

                n1 = (n1 + 0 + v84) % 4294967296
            end
        elseif i <= 15 then
            local v85 = (i - 8) * 8

            if v85 >= 32 then
                local v86 = lshift(v79, v85 - 32)
                local v87 = n4 + 0
                local v88 = 0

                if v87 >= 4294967296 then
                    v87 -= 4294967296
                    v88 = 1
                end

                n4 = v87
                n3 = (n3 + v86 + v88) % 4294967296
            else
                n4 += lshift(v79, v85)

                local v89 = 0

                if n4 >= 4294967296 then
                    n4 -= 4294967296
                    v89 = 1
                end

                n3 = (n3 + 0 + v89) % 4294967296
            end
        else
            local v90 = (i - 15) * 8

            if v90 >= 32 then
                local v91 = lshift(v79, v90 - 32)
                local v92 = v75 + 0
                local v93 = 0

                if v92 >= 4294967296 then
                    v92 -= 4294967296
                    v93 = 1
                end

                v75 = v92
                v77 = (v77 + v91 + v93) % 4294967296
            else
                v75 += lshift(v79, v90)

                local v94 = 0

                if v75 >= 4294967296 then
                    v75 -= 4294967296
                    v94 = 1
                end

                v77 = (v77 + 0 + v94) % 4294967296
            end
        end
    end

    local _, _, _, _, v95, v96 = t1.mix(n1, n2, n3, n4, v77, v75)

    return v95, v96
end

function t1.hash(p24) -- line: 135
    -- upvalues: hash_parts (copy)
    local v97, v98 = hash_parts(p24)

    return string.format("0x%08X%08X", v97, v98)
end

local function parse_u64_hex(p25) -- line: 141
    local v99 = if string.sub(p25, 1, 1) == "+" then string.sub(p25, 2) else p25

    if #v99 == 0 or string.find(v99, "^%x+$") == nil then
        return nil
    end

    local v100 = string.gsub(v99, "^0+", "")

    return if not (#v100 > 16) then string.rep("0", 16 - #v100) .. string.upper(v100) else nil
end

local t3 = {}
local v101 = false

local function seed() -- line: 159
    -- upvalues: sim (copy), t3 (copy), v101 (ref)
    v101 = true

    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local index = sim_data and sim_data:FindFirstChild("index")

    if index then
        for _, v102 in require(index).names do
            local v103 = sim_data:FindFirstChild(v102)

            if v103 then
                for v104, v105 in require(v103) do
                    t3[v104] = v105
                end
            end
        end
    end
end

function t1.numeric_name(p26) -- line: 178
    -- upvalues: hash_parts (copy), parse_u64_hex (copy), t3 (copy), v101 (ref), seed (copy)
    local v106 = t3[p26]

    if v106 ~= nil then
        return v106
    end

    local v107 = v101
    local v108, v109

    if not v107 then
        seed()
        v108 = t3[p26]
        v109 = v108 == nil
    end

    if not (v107 or v109) then
        return v108
    end

    local v110 = if string.sub(p26, 1, 5) == "Hash_" then string.sub(p26, 6) elseif string.sub(p26, 1, 2) == "0x" then string.sub(p26, 3) else nil
    local v111 = if v110 == nil then nil else parse_u64_hex(v110)

    if v111 == nil then
        local v112, v113 = hash_parts(p26)

        v111 = string.format("%08X%08X", v112, v113)
    end

    local v114 = "Hash_" .. v111

    t3[p26] = v114

    return v114
end

return t1
