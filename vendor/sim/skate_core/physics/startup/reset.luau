-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    word = function(p1, p2) -- word | line: 12
        return p1[p2 + 1] * 16777216 + p1[p2 + 2] * 65536 + p1[p2 + 3] * 256 + p1[p2 + 4]
    end,
    put = function(p3, p4, p5) -- put | line: 16
        p3[p4 + 1] = bit32.band(bit32.rshift(p5, 24), 255)
        p3[p4 + 2] = bit32.band(bit32.rshift(p5, 16), 255)
        p3[p4 + 3] = bit32.band(bit32.rshift(p5, 8), 255)
        p3[p4 + 4] = bit32.band(p5, 255)
    end
}

function t1.up(p6, p7) -- line: 23
    -- upvalues: t1 (copy)
    for i = p7, p7 + 16 - 1 do
        p6[i + 1] = 0
    end

    t1.put(p6, p7 + 4, 1065353216)
end

function t1.reset_collision_info(p8) -- line: 33
    -- upvalues: t1 (copy)
    t1.up(p8, 0)
    t1.up(p8, 16)

    for i = 0, 6 do
        t1.up(p8, i * 16 + 32)

        for _, v7 in { 144, 256, 368, 480 } do
            for j = v7 + i * 16, v7 + i * 16 + 16 - 1 do
                p8[j + 1] = 0
            end
        end

        for _, v8 in { 692, 720, 748 } do
            t1.put(p8, v8 + i * 4, 0)
        end

        p8[i + 780 + 1] = 0
    end

    p8[593] = 0
    p8[594] = 0
    p8[595] = 0
    p8[596] = 0
    p8[597] = 0
    p8[598] = 0
    p8[599] = 0
    p8[600] = 0
    p8[601] = 0
    p8[602] = 0
    p8[603] = 0
    p8[604] = 0
    p8[605] = 0
    p8[606] = 0
    p8[607] = 0
    p8[608] = 0

    for i = 0, 3 do
        t1.up(p8, i * 16 + 608)
        t1.put(p8, i * 4 + 672, 0)
        p8[i + 688 + 1] = 0
    end

    for _, v9 in { 776, 788, 792, 796, 800 } do
        t1.put(p8, v9, 0)
    end

    p8[805] = 0
    p8[806] = 0

    local v11 = bit32.band(t1.word(p8, 808), 33554431)

    t1.put(p8, 808, v11)
end

function t1.reset_board_body(p9, p10, p11) -- line: 74
    -- upvalues: rt (copy), t1 (copy)
    if #p10 ~= #p11 then
        error("assertion `left == right` failed", 0)
    end

    for i = 1, #p10 do
        local v12 = p10[i]
        local v13 = p11[i]

        v12[9] = 0
        v12[10] = 0
        v12[11] = 0
        v12[13] = 0
        v12[14] = 0
        v12[15] = 0
        v12[37] = v13[1]
        v12[38] = v13[2]
        v12[39] = v13[3]
        v12[41] = 0
        v12[42] = 0
        v12[43] = 0
    end

    t1.put(p9, 7680, 0)
    t1.put(p9, 7684, 0)

    local v14 = rt.slice(p9, 64, 876)

    t1.reset_collision_info(v14)

    for i = 0, 811 do
        p9[i + 64 + 1] = v14[i + 1]
    end

    local v15 = p9[8385]

    p9[8385] = bit32.band(p9[8385], 63)

    for _, v17 in { 7968, 8032 } do
        for j = v17, v17 + 52 - 1 do
            p9[j + 1] = 0
        end

        p9[v17 + 52 + 1] = 0
    end

    for i = 1008, 1043 do
        p9[i + 1] = 0
    end

    p9[1045] = 0

    return v15
end

return t1
