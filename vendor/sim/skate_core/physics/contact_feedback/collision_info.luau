-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    word = function(p1, p2) -- word | line: 11
        return p1[p2 + 1] * 16777216 + p1[p2 + 2] * 65536 + p1[p2 + 3] * 256 + p1[p2 + 4]
    end,
    put = function(p3, p4, p5) -- put | line: 15
        p3[p4 + 1] = bit32.band(bit32.rshift(p5, 24), 255)
        p3[p4 + 2] = bit32.band(bit32.rshift(p5, 16), 255)
        p3[p4 + 3] = bit32.band(bit32.rshift(p5, 8), 255)
        p3[p4 + 4] = bit32.band(p5, 255)
    end
}

function t1.up(p6, p7) -- line: 22
    -- upvalues: t1 (copy)
    for i = p7, p7 + 15 do
        p6[i + 1] = 0
    end

    t1.put(p6, p7 + 4, 1065353216)
end

function t1.reset_frame_collision_info(p8) -- line: 31
    -- upvalues: t1 (copy)
    t1.up(p8, 0)

    for i = 0, 6 do
        t1.up(p8, i * 16 + 32)

        for _, v7 in { 144, 368, 480 } do
            for j = v7 + i * 16, v7 + i * 16 + 15 do
                p8[j + 1] = 0
            end
        end

        p8[i + 780 + 1] = 0
    end

    for i = 4, 6 do
        for _, v8 in { 692, 720, 748 } do
            t1.put(p8, v8 + i * 4, 0)
        end
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
    p8[689] = 1
    p8[690] = 1
    p8[691] = 1
    p8[692] = 1

    for _, v9 in { 776, 788, 796, 800 } do
        t1.put(p8, v9, 0)
    end

    p8[805] = 0
    p8[806] = 0

    local v11 = bit32.band(t1.word(p8, 808), 33554431)

    t1.put(p8, 808, v11)
end

function t1.choose_physics_surface(p9) -- line: 65
    -- upvalues: t1 (copy)
    local t2 = {
        t1.word(p9, 692),
        t1.word(p9, 696),
        t1.word(p9, 700),
        t1.word(p9, 704)
    }
    local t3 = {
        p9[781] ~= 0,
        p9[782] ~= 0,
        p9[783] ~= 0,
        p9[784] ~= 0
    }
    local v17 = t1.choose_surface(t2, t3, bit32.band(t1.word(p9, 808), 33554432) ~= 0)

    t1.put(p9, 776, v17)
end

function t1.choose_surface(p10, p11, p12) -- line: 79
    local v18 = table.create(16, 0)

    for i = 0, 3 do
        local v19 = p10[i + 1]

        if v19 ~= 0 then
            if not (v19 < 16) then
                error("native surface histogram index exceeded", 0)
            end

            v18[v19 + 1] += p11[i + 1] and 4 or 1
        end
    end

    local n1 = 1
    local n2 = 0

    for i = 1, 13 do
        local v20 = v18[i + 1]

        if n2 < v20 then
            n2 = v20
            n1 = i
        end
    end

    if p12 then
        return 12
    end

    return n1
end

return t1
