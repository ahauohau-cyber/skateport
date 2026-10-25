-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function skate_map() -- line: 10
    -- upvalues: import (copy)
    return import("skate_data/skate_map")
end

return {
    decode = function(p1, p2, p3) -- decode | line: 17
        -- upvalues: rt (copy), import (copy)
        local v1 = import("skate_data/skate_map")
        local Reader, StoredBlock = v1.Reader, v1.StoredBlock
        local t2 = {
            at = 0,
            bytes = p2
        }
        local v2 = Reader.u(t2)

        if p3 * 3 + 16 < v2 or v2 > 2147483648 then
            error("SKATE transformed block exceeds size limit", 0)
        end

        local v3 = StoredBlock.decode({
            expected = v2,
            method = p1 <= 6 and 2 or 1,
            bytes = rt.slice(p2, 4)
        })
        local t4 = {
            at = 0,
            bytes = v3
        }
        local v4 = {}

        if p1 == 3 or p1 == 7 then
            local v5 = Reader.u(t4)
            local v6 = Reader.u(t4)
            local v7 = v5 * 4

            if v7 * v6 ~= p3 or v5 > 16384 or v6 > 16384 then
                error("SKATE filtered dimensions mismatch", 0)
            end

            v4 = table.create(p3, 0)

            for i = 0, v6 - 1 do
                local v8 = Reader.take(t4, 1)[1]

                if v8 > 4 then
                    error("Invalid SKATE RGBA filter", 0)
                end

                local v9 = Reader.take(t4, v7)

                for j = 0, v7 - 1 do
                    local v10 = v9[j + 1]
                    local v11 = i * v7 + j
                    local v12 = if j >= 4 then v4[v11 - 4 + 1] else 0
                    local v13 = if i > 0 then v4[v11 - v7 + 1] else 0
                    local v14 = if not (j >= 4 and i > 0) then 0 else v4[v11 - v7 - 4 + 1]

                    if v8 ~= 1 then
                        if v8 == 2 then
                            v12 = v13
                        elseif v8 == 3 then
                            v12 = rt.idiv(v12 + v13, 2)
                        elseif v8 == 4 then
                            local v15 = v12 + v13 - v14
                            local v17 = math.abs(v15 - v12)
                            local v19 = math.abs(v15 - v13)
                            local v21 = math.abs(v15 - v14)

                            if not (v17 <= v19 and v17 <= v21) then
                                v12 = if v19 <= v21 then v13 else v14
                            end
                        else
                            v12 = 0
                        end
                    end

                    v4[v11 + 1] = (v10 + v12 % 256) % 256
                end
            end
        elseif p1 == 4 or p1 == 8 then
            if rt.irem(p3, 56) ~= 0 or #v3 ~= p3 then
                error("Invalid SKATE vertex streams", 0)
            end

            v4 = table.create(p3, 0)

            for _, v22 in {
                    { 0, 12 },
                    { 12, 12 },
                    { 24, 8 },
                    { 32, 8 },
                    { 40, 4 },
                    { 44, 8 },
                    { 52, 4 }
                } do
                local v23 = v22[1]
                local v24 = v22[2]

                for k = 0, rt.idiv(p3, 56) - 1 do
                    local v25 = k * 56 + v23
                    local v26 = Reader.take(t4, v24)

                    table.move(v26, 1, v24, v25 + 1, v4)
                end
            end
        elseif p1 == 5 or p1 == 9 then
            if rt.irem(p3, 4) ~= 0 then
                error("Invalid SKATE index block size", 0)
            end

            local v27 = rt.idiv(p3, 4) - 1
            local n1 = 0

            for _ = 0, v27 do
                local n2 = 0

                for i = 0, 28, 7 do
                    local v28 = Reader.take(t4, 1)[1]

                    if i == 28 and v28 > 31 then
                        error("Invalid SKATE index varint", 0)
                    end

                    n2 += bit32.band(v28, 127) * 2 ^ i

                    if bit32.band(v28, 128) == 0 then
                        break
                    end
                end

                local v30 = math.floor(n2 / 2)

                if n2 % 2 == 1 then
                    v30 = -v30 - 1
                end

                n1 += v30

                if n1 < 0 or n1 > 4294967295 then
                    error("SKATE index delta overflow", 0)
                end

                table.insert(v4, (bit32.band(n1, 255)))
                table.insert(v4, (bit32.band(bit32.rshift(n1, 8), 255)))
                table.insert(v4, (bit32.band(bit32.rshift(n1, 16), 255)))
                table.insert(v4, (bit32.rshift(n1, 24)))
            end
        elseif p1 == 6 or p1 == 10 then
            if rt.irem(p3, 48) ~= 0 then
                error("Invalid SKATE collision block size", 0)
            end

            local v37 = Reader.u(t4)
            local v38 = Reader.take(t4, v37 * 12)

            for _ = 0, rt.idiv(p3, 48) - 1 do
                for _ = 0, 2 do
                    local v39 = Reader.u(t4)

                    if v37 <= v39 then
                        error("Invalid SKATE collision vertex reference", 0)
                    end

                    table.move(v38, v39 * 12 + 1, v39 * 12 + 12, #v4 + 1, v4)
                end

                local v40 = Reader.take(t4, 12)

                table.move(v40, 1, 12, #v4 + 1, v4)
            end
        else
            error("Invalid SKATE storage transform", 0)
        end

        if t4.at ~= #v3 or #v4 ~= p3 then
            error("SKATE transformed size mismatch or trailing data", 0)
        end

        return v4
    end
}
