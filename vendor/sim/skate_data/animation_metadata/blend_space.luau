-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

local import = require(sim.import)
local v2 = import("skate_data/abin")
local Error, Reader = v2.Error, v2.Reader
local t1 = {}

local function validate_name(p3, p4) -- line: 25
    -- upvalues: import (copy)
    return import("skate_data/animation_metadata").validate_name(p3, p4)
end

t1.BlendSimplexMetadata = {}
t1.BlendSpaceMetadata = {}

local function finite_bits(p5) -- line: 39
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p5)

    local v3 = buffer.readf32(v1, 0)

    if v3 ~= v3 or v3 == 1e999 then
        return false
    end

    return v3 ~= (-1e999)
end

function t1.BlendSpaceMetadata.validate(p6, p7) -- line: 44
    -- upvalues: v1 (copy), import (copy)
    local name = p6.name

    import("skate_data/animation_metadata").validate_name(name, 36)

    local v4 = #p6.parameters

    if p7 <= p6.source_offset or v4 == 0 or v4 > 4 or #p6.children < v4 + 1 or #p6.simplexes == 0 then
        error(string.format("%s: invalid BlendSpace dimensions/offset", p6.name), 0)
    end

    for _, v5 in p6.parameters do
        import("skate_data/animation_metadata").validate_name(v5, 30)
    end

    for _, v6 in p6.children do
        import("skate_data/animation_metadata").validate_name(v6, 36)
    end

    for _, v7 in p6.simplexes do
        local v8 = #v7.children ~= v4 + 1 or #v7.scale_bits ~= v4 + 1 or #v7.vertex_bits ~= v4 + 1 or #v7.normal_bits ~= v4 + 1

        if not v8 then
            for _, v9 in v7.children do
                if #p6.children <= v9 then
                    v8 = true
                    break
                end
            end
        end

        if not v8 then
            for _, v10 in v7.vertex_bits do
                if #v10 ~= v4 then
                    v8 = true
                    break
                end
            end
        end

        if not v8 then
            for _, v11 in v7.normal_bits do
                if #v11 ~= v4 then
                    v8 = true
                    break
                end
            end
        end

        if not v8 then
            for _, v12 in v7.vertex_bits do
                for _, v14 in v12 do
                    buffer.writeu32(v1, 0, v14)

                    local v15 = buffer.readf32(v1, 0)

                    if v15 ~= v15 or v15 == 1e999 or v15 == (-1e999) then
                        v8 = true
                    end
                end
            end

            for _, v16 in v7.normal_bits do
                for _, v18 in v16 do
                    buffer.writeu32(v1, 0, v18)

                    local v19 = buffer.readf32(v1, 0)

                    if v19 ~= v19 or v19 == 1e999 or v19 == (-1e999) then
                        v8 = true
                    end
                end
            end

            for _, v21 in v7.scale_bits do
                buffer.writeu32(v1, 0, v21)

                local v22 = buffer.readf32(v1, 0)

                if v22 ~= v22 or v22 == 1e999 or v22 == (-1e999) then
                    v8 = true
                end
            end
        end

        if v8 then
            error(string.format("%s: invalid BlendSpace simplex", p6.name), 0)
        end
    end
end

function t1.read(p8, p9) -- line: 121
    -- upvalues: Error (copy), Reader (copy)
    local payload_offset = p9.payload_offset
    local v23 = Reader.u32(p8, payload_offset)
    local v24 = v23 * 24
    local start = Reader.relative(p8, payload_offset, Reader.u32(p8, payload_offset + 4), v24).start
    local start2 = Reader.relative(p8, payload_offset, Reader.u32(p8, payload_offset + 12), 44).start
    local v25 = Reader.bounded(p8, Reader.relative(p8, start2, 0, Reader.u32(p8, start2)))
    local v26 = Reader.u32(v25, start2 + 28)

    if v26 == 0 or v26 > 4 or Reader.u32(p8, payload_offset + 16) < v26 then
        error(Error.new(start2 + 28, "invalid BlendSpace dimension"), 0)
    end

    local start3 = Reader.relative(v25, start2, Reader.u32(v25, start2 + 32), v26 * 20).start
    local v27 = Reader.u32(v25, start2 + 36)

    Reader.relative(v25, start2, Reader.u32(v25, start2 + 40), v27 * 20)

    local v28 = Reader.relative(v25, start2, Reader.u32(v25, start2 + 40), 20).start
    local t2 = {}

    for _ = 0, v27 - 1 do
        local v29 = Reader.u32(v25, v28)
        local v30 = Reader.bounded(v25, Reader.relative(v25, v28, 0, v29))

        if Reader.u32(v30, v28 + 16) ~= v26 + 1 then
            error(Error.new(v28 + 16, "BlendSpace matrix dimension mismatch"), 0)
        end

        Reader.take(v30, v28 + 20, (v26 + 1) * (v26 + 1) * 4)

        local start = Reader.relative(v30, v28, Reader.u32(v30, v28 + 4), (v26 + 1) * 4).start
        local start2 = Reader.relative(v30, v28, Reader.u32(v30, v28 + 8), (v26 + 1) * 4).start
        local start3 = Reader.relative(v30, v28, Reader.u32(v30, v28 + 12), (v26 + 1) * (v26 + 1) * 4).start
        local t3 = {
            children = {},
            vertex_bits = {},
            normal_bits = {},
            scale_bits = {}
        }

        for i = 0, v26 do
            local v31 = start3 + i * (v26 + 1) * 4

            if Reader.u32(v30, v31) ~= v26 then
                error(Error.new(v31, "BlendSpace normal dimension mismatch"), 0)
            end

            table.insert(t3.children, Reader.u32(v30, start + i * 4))
            table.insert(t3.scale_bits, Reader.u32(v30, start2 + i * 4))

            local v34 = table.create(v26)

            for j = 0, v26 - 1 do
                v34[j + 1] = Reader.u32(v30, v28 + 20 + (i * (v26 + 1) + j) * 4)
            end

            table.insert(t3.vertex_bits, v34)

            local v35 = table.create(v26)

            for k = 0, v26 - 1 do
                v35[k + 1] = Reader.u32(v30, v31 + 4 + k * 4)
            end

            table.insert(t3.normal_bits, v35)
        end

        table.insert(t2, t3)
        v28 += v29
    end

    local name, offset = p9.name, p9.offset
    local v36 = table.create(v26)

    for i = 0, v26 - 1 do
        v36[i + 1] = Reader.name(v25, start3 + i * 20, 5)
    end

    local v37 = table.create(v23)

    for i = 0, v23 - 1 do
        v37[i + 1] = Reader.name(p8, start + i * 24, 6)
    end

    return {
        name = name,
        source_offset = offset,
        parameters = v36,
        children = v37,
        simplexes = t2
    }
end

return t1
