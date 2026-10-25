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

t1.SelectionParameterMetadata = {}
t1.SelectionCandidateMetadata = {}
t1.SelectionSpaceMetadata = {}

function t1.SelectionSpaceMetadata.validate(p5, p6) -- line: 40
    -- upvalues: v1 (copy), import (copy)
    local name = p5.name

    import("skate_data/animation_metadata").validate_name(name, 36)

    if p6 <= p5.source_offset or #p5.parameters > 10 or #p5.candidates == 0 then
        error(string.format("%s: invalid selection space dimensions", p5.name), 0)
    end

    for _, v3 in p5.parameters do
        local name = v3.name

        import("skate_data/animation_metadata").validate_name(name, 30)
        buffer.writeu32(v1, 0, v3.weight_bits)

        local v4 = buffer.readf32(v1, 0)

        if v4 == v4 and v4 ~= 1e999 and v4 ~= (-1e999) then
            buffer.writeu32(v1, 0, v3.minimum_bits)

            local v5 = buffer.readf32(v1, 0)

            if v5 == v5 and v5 ~= 1e999 and v5 ~= (-1e999) then
                buffer.writeu32(v1, 0, v3.maximum_bits)

                local v6 = buffer.readf32(v1, 0)

                if v6 ~= v6 or v6 == 1e999 or v6 == (-1e999) then
                    error(string.format("%s: nonfinite selection metric", p5.name), 0)
                end
            else
                error(string.format("%s: nonfinite selection metric", p5.name), 0)
            end
        else
            error(string.format("%s: nonfinite selection metric", p5.name), 0)
        end
    end

    for _, v7 in p5.candidates do
        local child = v7.child

        import("skate_data/animation_metadata").validate_name(child, 36)

        local v8 = #v7.value_bits ~= #p5.parameters

        if not v8 then
            for _, v9 in v7.value_bits do
                buffer.writeu32(v1, 0, v9)

                local v10 = buffer.readf32(v1, 0)

                if v10 ~= v10 or v10 == 1e999 or v10 == (-1e999) then
                    v8 = true
                    break
                end
            end
        end

        if v8 then
            error(string.format("%s: invalid selection candidate", p5.name), 0)
        end
    end
end

function t1.read(p7, p8) -- line: 73
    -- upvalues: Error (copy), Reader (copy)
    local payload_offset = p8.payload_offset
    local v11 = Reader.u32(p7, payload_offset)

    if v11 > 10 then
        error(Error.new(payload_offset, "selection parameter array exceeds native capacity"), 0)
    end

    local start = Reader.relative(p7, payload_offset, Reader.u32(p7, payload_offset + 4), v11 * 40).start
    local v12 = Reader.u32(p7, payload_offset + 8)
    local start2 = Reader.relative(p7, payload_offset, Reader.u32(p7, payload_offset + 12), 4).start
    local v13 = Reader.u32(p7, start2)
    local v14 = v13 * v12

    Reader.take(p7, start2, v14)

    if v13 < 32 then
        error(Error.new(start2, "selection candidate header too small"), 0)
    end

    local v15 = table.create(v11)

    for i = 0, v11 - 1 do
        local v16 = start + i * 40

        v15[i + 1] = {
            name = Reader.name(p7, v16, 6),
            mode = Reader.u32(p7, v16 + 24),
            weight_bits = Reader.u32(p7, v16 + 28),
            minimum_bits = Reader.u32(p7, v16 + 32),
            maximum_bits = Reader.u32(p7, v16 + 36)
        }
    end

    local v17 = table.create(v12)

    for i = 0, v12 - 1 do
        local v18 = start2 + i * v13
        local v19 = Reader.bounded(p7, {
            start = v18,
            ["end"] = v18 + v13
        })
        local start = Reader.relative(v19, v18, Reader.u32(v19, v18 + 28), v11 * 4).start
        local v20 = Reader.name(v19, v18 + 4, 6)
        local v21 = table.create(v11)

        for j = 0, v11 - 1 do
            v21[j + 1] = Reader.u32(v19, start + j * 4)
        end

        v17[i + 1] = {
            child = v20,
            value_bits = v21
        }
    end

    return {
        name = p8.name,
        source_offset = p8.offset,
        parameters = v15,
        candidates = v17
    }
end

return t1
