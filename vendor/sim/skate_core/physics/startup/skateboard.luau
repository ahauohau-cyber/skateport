-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/board_pose")

local function startup() -- line: 9
    -- upvalues: import (copy)
    return import("skate_core/physics/startup")
end

local t1 = {}

function t1.reset_skateboard(p1, p2, p3, p4, p5, p6, p7, p8, p9) -- line: 28
    -- upvalues: rt (copy), import (copy), v1 (copy), t1 (copy)
    local v2 = rt.copy(p7)

    for i = 1, 7 do
        if p4[i].body == nil then
            error("assertion failed: parts.iter().all(|part| part.body.is_some())", 0)
        end
    end

    for _, v3 in { 6, 0, 1, 2, 3, 4, 5 } do
        v1.set_part_transform(p4[v3 + 1], rt.copy(p6[v3 + 1]))
    end

    if bit32.band(p8, 1048576) ~= 0 then
        for _, v4 in { 0, 1, 2, 3, 8, 9, 10, 11 } do
            v2[v4 + 1] = bit32.bxor(v2[v4 + 1], 2147483648)
        end
    end

    v1.set_board_transform(p4, p5, v2)

    local v7 = rt.from_fn(7, function(p10) -- line: 54
        -- upvalues: p4 (copy), rt (copy)
        local body = p4[p10 + 1].body

        if body == nil then
            error("called `Option::unwrap()` on a `None` value", 0)
        end

        return rt.copy(body)
    end)

    import("skate_core/physics/startup").reset_board_body(p3, v7, p9)
    p4[1].body = v7[1]
    p4[2].body = v7[2]
    p4[3].body = v7[3]
    p4[4].body = v7[4]
    p4[5].body = v7[5]
    p4[6].body = v7[6]
    p4[7].body = v7[7]
    t1.put(p1, 256, 0)
    t1.put(p3, 7680, 0)
    t1.put(p3, 7684, 0)
    p1[241] = 0
    p1[242] = 0
    p1[243] = 0
    p1[244] = 0
    p1[245] = 0
    p1[246] = 0
    p1[247] = 0
    p1[248] = 0
    p1[249] = 0
    p1[250] = 0
    p1[251] = 0
    p1[252] = 0
    p1[253] = 0
    p1[254] = 0
    p1[255] = 0
    p1[256] = 0
    t1.put(p1, 252, 1065353216)
    p1[291] = 0

    for i = 960, 991 do
        p3[i + 1] = 0
    end

    t1.put(p3, 972, 2)
    t1.put(p3, 988, 2)
    t1.put(p1, 324, rt.wrapping_add_u32(p2, 352))
    t1.put(p1, 320, rt.wrapping_add_u32(p2, 352))
    t1.put(p1, 328, rt.wrapping_add_u32(p2, 1360))
    t1.put(p1, 260, 0)
    p1[193] = 0
    p1[194] = 0
    p1[195] = 0
    p1[196] = 0
    p1[197] = 0
    p1[198] = 0
    p1[199] = 0
    p1[200] = 0
    p1[201] = 0
    p1[202] = 0
    p1[203] = 0
    p1[204] = 0
    p1[205] = 0
    p1[206] = 0
    p1[207] = 0
    p1[208] = 0
    t1.put(p1, 196, 1065353216)
    p1[292] = 0

    return 240
end

function t1.put(p11, p12, p13) -- line: 90
    p11[p12 + 1] = bit32.band(bit32.rshift(p13, 24), 255)
    p11[p12 + 2] = bit32.band(bit32.rshift(p13, 16), 255)
    p11[p12 + 3] = bit32.band(bit32.rshift(p13, 8), 255)
    p11[p12 + 4] = bit32.band(p13, 255)
end

return t1
