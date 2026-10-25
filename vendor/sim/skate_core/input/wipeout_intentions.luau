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

local DerivedControllerInput = require(sim.import)("skate_core/input/controller").DerivedControllerInput

return {
    produce = function(p2, p3, p4) -- produce | line: 23
        -- upvalues: v1 (copy), DerivedControllerInput (copy)
        local v3 = DerivedControllerInput.words(p2)
        local v4 = v3[7]
        local v5 = v3[14]

        local function axis(p5) -- line: 27
            -- upvalues: v3 (copy), v1 (copy)
            buffer.writeu32(v1, 0, v3[p5 + 1])

            return (buffer.readf32(v1, 0))
        end

        local function rising(p6) -- line: 30
            -- upvalues: v4 (copy), v5 (copy)
            if bit32.band(v4, (bit32.lshift(1, p6))) ~= 0 then
                return false
            end

            return bit32.band(v5, (bit32.lshift(1, p6))) ~= 0
        end

        local function trigger_edge(p7, p8) -- line: 33
            -- upvalues: v3 (copy), v1 (copy)
            buffer.writeu32(v1, 0, v3[p7 + 1])

            if buffer.readf32(v1, 0) == 1 then
                return false
            end

            buffer.writeu32(v1, 0, v3[p8 + 1])

            return buffer.readf32(v1, 0) == 1
        end

        local t2 = {}

        local function emit(p9, p10) -- line: 37
            -- upvalues: t2 (copy)
            table.insert(t2, {
                name = p9,
                value = p10
            })
        end

        local v11 = bit32.band(p4, 128) ~= 0
        local v12 = 0

        if v11 then
            buffer.writeu32(v1, 0, v3[10])
            v12 = buffer.readf32(v1, 0)
        end

        table.insert(t2, {
            name = "WipeoutGestureX",
            value = v12
        })

        local v14 = 0

        if v11 then
            buffer.writeu32(v1, 0, v3[11])
            v14 = buffer.readf32(v1, 0)
        end

        table.insert(t2, {
            name = "WipeoutGestureY",
            value = v14
        })

        local v16, v17

        if bit32.band(p4, 256) ~= 0 then
            buffer.writeu32(v1, 0, v3[8])
            v16 = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v3[9])
            v17 = buffer.readf32(v1, 0)
        else
            v16 = 0
            v17 = 0
        end

        if v16 ~= 0 then
            table.insert(t2, {
                name = "WipeoutControlX",
                value = v16
            })
        end

        if v17 ~= 0 then
            table.insert(t2, {
                name = "WipeoutControlY",
                value = v17
            })
        end

        if bit32.band(v4, 2097152) == 0 and bit32.band(v5, 2097152) ~= 0 or bit32.band(v4, 8388608) == 0 and bit32.band(v5, 8388608) ~= 0 then
            table.insert(t2, {
                name = "WipeOutRecover",
                value = 1
            })
        end

        if bit32.band(p3, 64) == 0 then
            buffer.writeu32(v1, 0, v3[12])

            local v20

            if buffer.readf32(v1, 0) == 1 then
                buffer.writeu32(v1, 0, v3[13])

                if buffer.readf32(v1, 0) == 1 and bit32.band(v5, 3221225472) == 3221225472 then
                    buffer.writeu32(v1, 0, v3[5])

                    if buffer.readf32(v1, 0) == 1 then
                        v20 = false
                    else
                        buffer.writeu32(v1, 0, v3[12])
                        v20 = buffer.readf32(v1, 0) == 1
                    end

                    local v25 = false
                    local v26 = false
                    local v27 = false
                    local v28 = false
                    local v29 = false

                    if v20 then
                    else
                        v25 = true
                    end

                    local v30

                    if v25 then
                        buffer.writeu32(v1, 0, v3[6])

                        if buffer.readf32(v1, 0) == 1 then
                            v30 = false
                            v27 = true
                        else
                            v26 = true
                        end
                    end

                    v25 = false

                    if v26 then
                        buffer.writeu32(v1, 0, v3[13])

                        if buffer.readf32(v1, 0) == 1 then
                            v28 = true
                        else
                            v25 = true
                        end
                    end

                    v26 = false

                    if v25 then
                        v30 = false
                        v27 = true
                    end

                    v25 = false

                    if v28 then
                        v30 = true
                        v27 = true
                    end

                    v28 = false

                    if v27 then
                        if v30 then
                            v29 = false
                        else
                            v28 = true
                        end
                    end

                    v27 = false

                    local v33

                    if v28 then
                        if bit32.band(v4, 2147483648) == 0 then
                            v27 = true
                        else
                            v33 = false
                            v25 = true
                        end
                    end

                    v28 = false

                    if v27 then
                        if bit32.band(v5, 2147483648) == 0 then
                            v26 = true
                        else
                            v28 = true
                        end
                    end

                    v27 = false

                    if v28 then
                        v33 = true
                        v25 = true
                    end

                    v28 = false

                    if v26 then
                        v33 = false
                        v25 = true
                    end

                    v26 = false

                    if v25 then
                        if v33 then
                            v29 = false
                        else
                            v26 = true
                        end
                    end

                    v25 = false

                    local v34

                    if v26 then
                        if bit32.band(v4, 1073741824) == 0 then
                            v25 = true
                        else
                            v34 = false
                            v28 = true
                        end
                    end

                    v26 = false

                    if v25 then
                        if bit32.band(v5, 1073741824) == 0 then
                            v27 = true
                        else
                            v26 = true
                        end
                    end

                    if v26 then
                        v34 = true
                        v28 = true
                    end

                    if v27 then
                        v34 = false
                        v28 = true
                    end

                    if v28 then
                        v29 = not v34
                    end

                    if not v29 then
                        table.insert(t2, {
                            name = "WipeOutRequest",
                            value = 1
                        })
                    end
                end
            end
        end

        if bit32.band(p4, 64) ~= 0 then
            buffer.writeu32(v1, 0, v3[6])

            if buffer.readf32(v1, 0) ~= 1 then
                buffer.writeu32(v1, 0, v3[13])

                if buffer.readf32(v1, 0) == 1 then
                    table.insert(t2, {
                        name = "WipeOutPushOff",
                        value = 1
                    })
                end
            end
        end

        return t2
    end
}
