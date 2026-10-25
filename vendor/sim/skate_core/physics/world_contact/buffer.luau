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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/physics/world_contact/arithmetic")
local v10 = import("skate_core/physics/world_contact/reduction")
local dot, sub, vector = v9.dot, v9.sub, v9.vector
local reduce = v10.reduce
local t1 = {
    ContactBuffer = {}
}

function t1.ContactBuffer.allocate(p3, p4) -- line: 52
    -- upvalues: rt (copy), t1 (copy)
    if not (p3.count <= 50) then
        error("assertion failed: self.count <= 50", 0)
    end

    if rt.wrapping_add_u32(p3.count, p3.flushed) >= p3.capacity then
        if p3.full == 0 then
            if p3.deferred_reduction ~= 0 then
                t1.ContactBuffer.reduce(p3)
            end

            if rt.wrapping_add_u32(p3.count, p3.flushed) >= p3.capacity then
                p3.full = 1
            end
        end

        if p3.full ~= 0 then
            p3.dropped = rt.wrapping_add_u32(p3.dropped, 1)

            return nil
        end
    end

    if p3.count >= 50 then
        if p3.allow_flush == 0 then
            p3.full = 1

            return nil
        end

        t1.ContactBuffer.flush(p3, p4)
    end

    local count = p3.count

    p3.count += 1

    return count
end

function t1.ContactBuffer.last_is_duplicate_reference(p5) -- line: 84
    -- upvalues: rt (copy), v1 (copy), dot (copy), sub (copy), vector (copy)
    local v11 = true

    if p5.distance_squared_threshold < 0 then
    elseif p5.deferred_reduction == 0 then
        if not (p5.count > 0) or not (p5.count <= 50) then
            error("assertion failed: self.count > 0 && self.count <= 50", 0)
        end

        v11 = false
    end

    if v11 then
        return false
    end

    local v12 = p5.records[p5.count - 1 + 1]

    for i = 0, p5.count - 1 - 1 do
        local v13 = p5.records[i + 1]

        if v13[4] == v12[4] and v13[8] == v12[8] then
            local v15 = sub(vector(v13, 0), vector(v12, 0))
            local v16 = sub(vector(v13, 4), vector(v12, 4))
            local v14

            if p5.distance_squared_threshold > dot(v15, v15) and dot(v16, v16) < p5.distance_squared_threshold then
                local v17 = dot(vector(v13, 8), vector(v12, 8))

                if v17 == 0 then
                    buffer.writef32(v1, 0, v17)
                    v14 = buffer.readf32(v1, 0)
                elseif v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
                    local v18 = math.abs(v17) * 7.1362384635298E+44
                    local v19 = math.floor(v18)
                    local v20 = v18 - v19

                    if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then
                        v19 += 1
                    end

                    v14 = v19 * 1.401298464324817E-45

                    if v17 < 0 then
                        v14 = -v14
                    end
                else
                    buffer.writef32(v1, 0, v17)
                    v14 = buffer.readf32(v1, 0)
                end

                if v14 > 0.94 then
                    p5.dropped = rt.wrapping_add_u32(p5.dropped, 1)

                    return true
                end
            end
        end
    end

    return false
end

local v21 = buffer.create(8)

local function fb(p6) -- line: 119
    -- upvalues: v21 (copy)
    buffer.writeu32(v21, 0, p6)

    return (buffer.readf32(v21, 0))
end

function t1.ContactBuffer.last_is_duplicate(p7) -- line: 123
    -- upvalues: rt (copy), v1 (copy), v21 (copy)
    local distance_squared_threshold = p7.distance_squared_threshold
    local count, v22

    if distance_squared_threshold < 0 then
        v22 = true
    elseif p7.deferred_reduction == 0 then
        count = p7.count

        if not (count > 0) or not (count <= 50) then
            error("assertion failed: self.count > 0 && self.count <= 50", 0)
        end

        v22 = false
    else
        v22 = true
    end

    if v22 then
        return false
    end

    local records = p7.records
    local v23 = records[count - 1 + 1]
    local v24 = v23[4]
    local v25 = v23[8]

    for i = 0, count - 1 - 1 do
        local v26 = records[i + 1]

        if v26[4] == v24 and v26[8] == v25 then
            buffer.writeu32(v21, 0, v26[1])

            local v29 = buffer.readf32(v21, 0)

            buffer.writeu32(v21, 0, v23[1])

            local v31 = v29 - buffer.readf32(v21, 0)

            buffer.writeu32(v21, 0, v26[2])

            local v33 = buffer.readf32(v21, 0)

            buffer.writeu32(v21, 0, v23[2])

            local v35 = v33 - buffer.readf32(v21, 0)

            buffer.writeu32(v21, 0, v26[3])

            local v37 = buffer.readf32(v21, 0)

            buffer.writeu32(v21, 0, v23[3])

            local v39 = v37 - buffer.readf32(v21, 0)
            local v27

            if v31 * v31 + v35 * v35 + v39 * v39 < distance_squared_threshold then
                buffer.writeu32(v21, 0, v26[5])

                local v41 = buffer.readf32(v21, 0)

                buffer.writeu32(v21, 0, v23[5])

                local v43 = v41 - buffer.readf32(v21, 0)

                buffer.writeu32(v21, 0, v26[6])

                local v45 = buffer.readf32(v21, 0)

                buffer.writeu32(v21, 0, v23[6])

                local v47 = v45 - buffer.readf32(v21, 0)

                buffer.writeu32(v21, 0, v26[7])

                local v49 = buffer.readf32(v21, 0)

                buffer.writeu32(v21, 0, v23[7])

                local v51 = v49 - buffer.readf32(v21, 0)

                if v43 * v43 + v47 * v47 + v51 * v51 < distance_squared_threshold then
                    buffer.writeu32(v21, 0, v26[9])

                    local v53 = buffer.readf32(v21, 0)

                    buffer.writeu32(v21, 0, v23[9])

                    local v55 = v53 * buffer.readf32(v21, 0)

                    buffer.writeu32(v21, 0, v26[10])

                    local v57 = buffer.readf32(v21, 0)

                    buffer.writeu32(v21, 0, v23[10])

                    local v59 = v55 + v57 * buffer.readf32(v21, 0)

                    buffer.writeu32(v21, 0, v26[11])

                    local v61 = buffer.readf32(v21, 0)

                    buffer.writeu32(v21, 0, v23[11])

                    local v63 = v59 + v61 * buffer.readf32(v21, 0)

                    if v63 == 0 then
                        buffer.writef32(v1, 0, v63)
                        v27 = buffer.readf32(v1, 0)
                    elseif v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
                        local v64 = math.abs(v63) * 7.1362384635298E+44
                        local v65 = math.floor(v64)
                        local v66 = v64 - v65

                        if v66 > 0.5 or v66 == 0.5 and v65 % 2 == 1 then
                            v65 += 1
                        end

                        v27 = v65 * 1.401298464324817E-45

                        if v63 < 0 then
                            v27 = -v27
                        end
                    else
                        buffer.writef32(v1, 0, v63)
                        v27 = buffer.readf32(v1, 0)
                    end

                    if v27 > 0.94 then
                        p7.dropped = rt.wrapping_add_u32(p7.dropped, 1)

                        return true
                    end
                end
            end
        end
    end

    return false
end

function t1.ContactBuffer.reduce(p8) -- line: 169
    -- upvalues: reduce (copy)
    p8.count = reduce(p8.records, p8.count)
end

function t1.ContactBuffer.flush(p9, p10) -- line: 175
    -- upvalues: rt (copy), t1 (copy)
    if p9.count == 0 then
        return
    end

    if p9.deferred_reduction ~= 0 then
        t1.ContactBuffer.reduce(p9)
    end

    p10(rt.slice(p9.records, 0, p9.count))
    p9.flushed = rt.wrapping_add_u32(p9.flushed, p9.count)
    p9.count = 0
end

return t1
