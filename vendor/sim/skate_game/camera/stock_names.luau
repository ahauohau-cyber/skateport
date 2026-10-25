-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {}
local bxor, lshift, rshift = bit32.bxor, bit32.lshift, bit32.rshift

local function sub3(p1, p2, p3, p4, p5, p6) -- line: 19
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

local function add64(p7, p8, p9, p10) -- line: 30
    local v5 = p8 + p10
    local v6 = 0

    if v5 >= 4294967296 then
        v5 -= 4294967296
        v6 = 1
    end

    return (p7 + p9 + v6) % 4294967296, v5
end

local function shr64(p11, p12, p13) -- line: 41
    -- upvalues: bxor (copy), lshift (copy), rshift (copy)
    if p13 >= 32 then
        return 0, (rshift(p11, p13 - 32))
    end

    return rshift(p11, p13), (bxor(rshift(p12, p13), (lshift(p11, 32 - p13))))
end

local function shl64(p14, p15, p16) -- line: 49
    -- upvalues: bxor (copy), lshift (copy), rshift (copy)
    if p16 >= 32 then
        return lshift(p15, p16 - 32), 0
    end

    return bxor(lshift(p14, p16), (rshift(p15, 32 - p16))), (lshift(p15, p16))
end

local function byte_shl(p17, p18) -- line: 57
    -- upvalues: lshift (copy), rshift (copy)
    if p18 >= 32 then
        return lshift(p17, p18 - 32), 0
    end

    if p18 == 0 then
        return 0, p17
    end

    return rshift(p17, 32 - p18), (lshift(p17, p18))
end

local t2 = {
    { 43, 9, 8 },
    { 38, 23, 5 },
    { 35, 49, 11 },
    { 12, 18, 22 }
}
local mix

function t1.lookup8(p19) -- line: 73
    -- upvalues: lshift (copy), rshift (copy), mix (ref)
    if #p19 == 0 then
        return "0x0000000000000000"
    end

    local v18 = buffer.fromstring(p19)
    local v19 = #p19
    local v20 = v19 - v19 % 24
    local n1 = 2882400000
    local n2 = 287454020
    local n3 = 2882400000
    local n4 = 287454020
    local n5 = 2654435769
    local n6 = 2135587859
    local n7 = 0

    while n7 < v20 do
        local v22 = buffer.readu32(v18, n7 + 4)
        local v23 = n2 + buffer.readu32(v18, n7)
        local v24 = 0

        if v23 >= 4294967296 then
            v23 -= 4294967296
            v24 = 1
        end

        local v25 = (n1 + v22 + v24) % 4294967296
        local v27 = buffer.readu32(v18, n7 + 12)
        local v29 = n4 + buffer.readu32(v18, n7 + 8)
        local v30 = 0

        if v29 >= 4294967296 then
            v29 -= 4294967296
            v30 = 1
        end

        local v31 = (n3 + v27 + v30) % 4294967296
        local v33 = buffer.readu32(v18, n7 + 20)
        local v35 = n6 + buffer.readu32(v18, n7 + 16)
        local v36 = 0

        if v35 >= 4294967296 then
            v35 -= 4294967296
            v36 = 1
        end

        local v37 = (n5 + v33 + v36) % 4294967296

        n1, n2, n3, n4, n5, n6 = mix(v25, v23, v31, v29, v37, v35)
        n7 += 24
    end

    local v39 = math.floor(v19 / 4294967296)
    local v40 = n6 + v19 % 4294967296
    local v41 = 0

    if v40 >= 4294967296 then
        v40 -= 4294967296
        v41 = 1
    end

    local v42 = (n5 + v39 + v41) % 4294967296

    for i = 0, v19 - v20 - 1 do
        local v44 = buffer.readu8(v18, v20 + i)

        if i <= 7 then
            local v45 = i * 8
            local v46, v47

            if v45 >= 32 then
                v47 = lshift(v44, v45 - 32)
                v46 = 0
            elseif v45 == 0 then
                v46 = v44
                v47 = 0
            else
                v47 = rshift(v44, 32 - v45)
                v46 = lshift(v44, v45)
            end

            n2 += v46

            local v48 = 0

            if n2 >= 4294967296 then
                n2 -= 4294967296
                v48 = 1
            end

            n1 = (n1 + v47 + v48) % 4294967296
        elseif i <= 15 then
            local v49 = (i - 8) * 8
            local v50, v51

            if v49 >= 32 then
                v51 = lshift(v44, v49 - 32)
                v50 = 0
            elseif v49 == 0 then
                v50 = v44
                v51 = 0
            else
                v51 = rshift(v44, 32 - v49)
                v50 = lshift(v44, v49)
            end

            n4 += v50

            local v52 = 0

            if n4 >= 4294967296 then
                n4 -= 4294967296
                v52 = 1
            end

            n3 = (n3 + v51 + v52) % 4294967296
        else
            local v53 = (i - 15) * 8
            local v54

            if v53 >= 32 then
                v54 = lshift(v44, v53 - 32)
                v44 = 0
            elseif v53 == 0 then
                v54 = 0
            else
                v54 = rshift(v44, 32 - v53)
                v44 = lshift(v44, v53)
            end

            v40 += v44

            local v55 = 0

            if v40 >= 4294967296 then
                v40 -= 4294967296
                v55 = 1
            end

            v42 = (v42 + v54 + v55) % 4294967296
        end
    end

    local _, _, _, _, v56, v57 = mix(n1, n2, n3, n4, v42, v40)

    return string.format("0x%08X%08X", v56, v57)
end

function t1.mix(p20, p21, p22, p23, p24, p25) -- line: 115
    -- upvalues: bxor (copy), lshift (copy), rshift (copy), t2 (copy)
    local v59 = p21
    local v60 = p22
    local v61 = p23
    local v62 = p24
    local v63 = p25

    for _, v64 in t2 do
        local v65 = v64[1]
        local v66 = v64[2]
        local v67 = v64[3]
        local v68 = v59 - v61 - v63
        local v69

        if v68 < 0 then
            v69 = if v68 < -4294967296 then 2 else 1
            v68 += v69 * 4294967296
        else
            v69 = 0
        end

        local v70 = (p20 - v60 - v62 - v69) % 4294967296
        local v71, v72

        if v65 >= 32 then
            v71 = 0
            v72 = rshift(v62, v65 - 32)
        else
            v71 = rshift(v62, v65)
            v72 = bxor(rshift(v63, v65), (lshift(v62, 32 - v65)))
        end

        p20 = bxor(v70, v71)
        v59 = bxor(v68, v72)

        local v77 = v61 - v63 - v59
        local v78

        if v77 < 0 then
            v78 = if v77 < -4294967296 then 2 else 1
            v77 += v78 * 4294967296
        else
            v78 = 0
        end

        local v79 = (v60 - v62 - p20 - v78) % 4294967296
        local v80, v81

        if v66 >= 32 then
            v80 = lshift(v59, v66 - 32)
            v81 = 0
        else
            v80 = bxor(lshift(p20, v66), (rshift(v59, 32 - v66)))
            v81 = lshift(v59, v66)
        end

        v60 = bxor(v79, v80)
        v61 = bxor(v77, v81)

        local v86 = v63 - v59 - v61
        local v87

        if v86 < 0 then
            v87 = if v86 < -4294967296 then 2 else 1
            v86 += v87 * 4294967296
        else
            v87 = 0
        end

        local v88 = (v62 - p20 - v60 - v87) % 4294967296
        local v89, v90

        if v67 >= 32 then
            v89 = 0
            v90 = rshift(v60, v67 - 32)
        else
            v89 = rshift(v60, v67)
            v90 = bxor(rshift(v61, v67), (lshift(v60, 32 - v67)))
        end

        v62 = bxor(v88, v89)
        v63 = bxor(v86, v90)
    end

    return p20, v59, v60, v61, v62, v63
end

mix = t1.mix

return t1
