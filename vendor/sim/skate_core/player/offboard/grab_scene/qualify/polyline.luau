-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/grab_scene/qualify/math")

local function grab_scene() -- line: 10
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/grab_scene")
end

local inverse_point, closest_point, sub, dot = v1.inverse_point, v1.closest_point, v1.sub, v1.dot
local length, reciprocal, transform = v1.length, v1.reciprocal, v1.transform
local t1 = {}

function t1.frame(p1) -- line: 27
    -- upvalues: import (copy)
    local Record = import("skate_core/player/offboard/grab_scene").Record

    return {
        Record.vector(p1, 0),
        Record.vector(p1, 16),
        Record.vector(p1, 32),
        Record.vector(p1, 48)
    }
end

local frame = t1.frame

function t1.indices(p2) -- line: 34
    -- upvalues: import (copy)
    local Record = import("skate_core/player/offboard/grab_scene").Record
    local v2 = #Record.points(p2)
    local v4 = bit32.band(Record.byte(p2, 200), 32) ~= 0
    local v5 = table.create(v2)

    for i = 0, v2 - 1 do
        local v6 = i + 1

        if v4 then
            v5[v6] = v2 - 1 - i
        else
            v5[v6] = i
        end
    end

    return v5
end

local indices = t1.indices

function t1.nearest_distance(p3, p4) -- line: 47
    -- upvalues: rt (copy), import (copy), inverse_point (copy), closest_point (copy), sub (copy), dot (copy), length (copy), frame (copy), indices (copy)
    local v7 = import("skate_core/player/offboard/grab_scene").Record.points(p3)

    if #v7 <= 1 then
        return 0
    end

    local v8 = inverse_point(frame(p3), p4)
    local v9 = indices(p3)

    if v9[1] == nil then
        error("nonempty source spline", 0)
    end

    local v10 = rt.copy(v7[v9[1] + 1])
    local v11 = rt.F32_MAX
    local n1 = 0
    local n2 = 0

    for i = 2, #v9 do
        local v13 = v9[i]
        local v14 = rt.copy(v7[v13 + 1])
        local v15 = closest_point(v8, { v10, v14 })
        local v16 = sub(v8, v15)
        local v17 = dot(v16, v16)

        if v17 < v11 then
            local v18 = sub(v15, v10)

            v11 = v17
            n2 = if dot(v18, v18) == 0 then 0 else n1 + length(v18)
        end

        local v19 = sub(v14, v10)

        v10 = v14

        if dot(v19, v19) == 0 then
            n1 = 0
        else
            n1 += length(v19)
        end
    end

    return n2
end

function t1.at_distance(p5, p6) -- line: 83
    -- upvalues: rt (copy), import (copy), sub (copy), length (copy), reciprocal (copy), transform (copy), frame (copy), indices (copy)
    local Record = import("skate_core/player/offboard/grab_scene").Record
    local v20 = Record.endpoints(p5)
    local v21 = Record.points(p5)

    if #v21 <= 1 or p6 <= 0 then
        return v20[1]
    end

    local v22 = indices(p5)

    if v22[1] == nil then
        error("nonempty source spline", 0)
    end

    local v23 = rt.copy(v21[v22[1] + 1])
    local n3 = 0

    for i = 2, #v22 do
        local v25 = v22[i]
        local v26 = rt.copy(v21[v25 + 1])
        local v27 = sub(v26, v23)
        local v28 = length(v27)

        n3 += v28

        if p6 < n3 then
            if v28 <= 0 then
                return transform(frame(p5), v26)
            end

            local v29 = reciprocal(v28) * (n3 - p6)
            local t2 = {
                v26[1] - v27[1] * v29,
                v26[2] - v27[2] * v29,
                v26[3] - v27[3] * v29,
                v26[4] - v27[4] * v29
            }

            return transform(frame(p5), t2)
        end

        v23 = v26
    end

    return v20[2]
end

return t1
