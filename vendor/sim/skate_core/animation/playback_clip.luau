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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local ClipClock = import("skate_core/animation/clip_clock").ClipClock
local eq = import("skate_core/animation/output/attributes").AttributeName.eq
local t1 = {}

t1.ClipAttribute = {}
t1.PlaybackClip = {}

function t1.PlaybackClip.new(p4, p5, p6, p7, p8) -- line: 50
    return {
        clock = {
            speed = 1,
            time = 0,
            previous_time = 0,
            loops_since_evaluation = 0,
            frames = p4,
            fps = p5,
            base_speed = p6,
            length = (p4 - 1) / (p6 * 1 * p5),
            looping = bit32.band(p7, 268435456) ~= 0,
            phase_controlled = bit32.band(p7, 1073741824) ~= 0
        },
        attributes = p8
    }
end

function t1.PlaybackClip.advance(p9, p10, p11) -- line: 69
    -- upvalues: ClipClock (copy)
    local t2 = {
        crossed_end = false,
        overshoot = -1,
        remaining_before_wrap = -1
    }

    ClipClock.advance(p9.clock, p10, p11, t2)

    return t2
end

function t1.PlaybackClip.attributes(p12, p13) -- line: 81
    -- upvalues: ClipClock (copy), t1 (copy)
    local t3 = {}

    for _, v8 in p12.attributes do
        local v9 = if v8.begin == -1 then 4 else ClipClock.attribute_status(p12.clock, v8.begin, v8["end"])

        if v8.begin == -1 or bit32.band(p13, 28, v9) ~= 0 and bit32.band(p13, 3, v9) ~= 0 then
            table.insert(t3, t1.PlaybackClip.materialize(p12, v8, v9))
        end
    end

    return t3
end

function t1.PlaybackClip.attribute(p14, p15, p16) -- line: 103
    -- upvalues: ClipClock (copy), t1 (copy), eq (copy)
    for _, v10 in p14.attributes do
        if eq(v10.name, p15) then
            local v11 = ClipClock.attribute_status(p14.clock, v10.begin, v10["end"])

            if bit32.band(p16, 28, v11) ~= 0 and bit32.band(p16, 3, v11) ~= 0 then
                return t1.PlaybackClip.materialize(p14, v10, v11)
            end
        end
    end

    return nil
end

function t1.PlaybackClip.query_into(p17, p18, p19, p20) -- line: 128
    -- upvalues: rt (copy), v1 (copy), ClipClock (copy), t1 (copy)
    local v12, v13, v14, v15, v16
    local v17 = false

    for _, v18 in p17.attributes do
        local v19 = v18.name[1]

        if not v17 then
            local v20 = p18[1]

            v12 = v20[1]
            v13 = v20[2]
            v14 = v20[3]
            v15 = v20[4]
            v16 = v20[5]
            v17 = true
        end

        if v19[1] == v12 and v19[2] == v13 and v19[3] == v14 and v19[4] == v15 and v19[5] == v16 then
            local v21 = ClipClock.attribute_status(p17.clock, v18.begin, v18["end"])

            if bit32.band(p19, 28, v21) ~= 0 and bit32.band(p19, 3, v21) ~= 0 then
                local kind, payload = v18.kind, v18.payload
                local v22 = if kind == 0 then 1
                    elseif kind == 1 then 4
                    elseif kind == 3 then 6
                    else 0

                if #payload < v22 then
                    error("Truncated clip attribute payload", 0)
                end

                local v23

                if kind == 2 then
                    local v24 = p17.clock.time * p17.clock.fps * p17.clock.speed
                    local v25 = t1.sample_curve(payload, v24)

                    if v25 == 0 then
                        buffer.writef32(v1, 0, v25)
                        v23 = buffer.readu32(v1, 0)
                    elseif v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
                        local v26 = math.abs(v25) * 7.1362384635298E+44

                        v23 = math.floor(v26)

                        local v27 = v26 - v23

                        if v27 > 0.5 or v27 == 0.5 and v23 % 2 == 1 then
                            v23 += 1
                        end

                        if v25 < 0 then
                            v23 += 2147483648
                        end
                    else
                        buffer.writef32(v1, 0, v25)
                        v23 = buffer.readu32(v1, 0)
                    end
                end

                local v28 = if p20.scratch then v18.name else rt.copy(v18.name)
                local v29 = if bit32.band(v21, 2) == 0 then v18.begin * p17.clock.length else -1
                local v30 = if bit32.band(v21, 2) == 0 then v18["end"] * p17.clock.length else -1

                p20.kind = kind
                p20.name = v28
                p20.begin_time = v29
                p20.end_time = v30
                p20.status = v21
                p20.sequence_id = -1

                local v31 = p20.payload[1]

                if kind == 2 then
                    v31[1] = v23
                else
                    for i = 1, v22 do
                        v31[i] = payload[i]
                    end
                end

                return true
            end
        end
    end

    return false
end

function t1.PlaybackClip.query_word(p21, p22, p23) -- line: 202
    -- upvalues: v1 (copy), ClipClock (copy), t1 (copy)
    local v32, v33, v34, v35, v36
    local v37 = false

    for _, v38 in p21.attributes do
        local v39 = v38.name[1]

        if not v37 then
            local v40 = p22[1]

            v32 = v40[1]
            v33 = v40[2]
            v34 = v40[3]
            v35 = v40[4]
            v36 = v40[5]
            v37 = true
        end

        if v39[1] == v32 and v39[2] == v33 and v39[3] == v34 and v39[4] == v35 and v39[5] == v36 then
            local v41 = ClipClock.attribute_status(p21.clock, v38.begin, v38["end"])

            if bit32.band(p23, 28, v41) ~= 0 and bit32.band(p23, 3, v41) ~= 0 then
                local kind, payload = v38.kind, v38.payload
                local v42 = if kind == 0 then 1
                    elseif kind == 1 then 4
                    elseif kind == 3 then 6
                    else 0

                if #payload < v42 then
                    error("Truncated clip attribute payload", 0)
                end

                if kind == 2 then
                    local v43 = p21.clock.time * p21.clock.fps * p21.clock.speed
                    local v44 = t1.sample_curve(payload, v43)

                    if v44 ~= 0 and v44 > -1.1754943508222875E-38 and v44 < 1.1754943508222875E-38 then
                        local v45 = math.abs(v44) * 7.1362384635298E+44
                        local v46 = math.floor(v45)
                        local v47 = v45 - v46

                        if v47 > 0.5 or v47 == 0.5 and v46 % 2 == 1 then
                            v46 += 1
                        end

                        if v44 < 0 then
                            return v46 + 2147483648
                        end

                        return v46
                    end

                    buffer.writef32(v1, 0, v44)

                    return (buffer.readu32(v1, 0))
                end

                if v42 == 0 then
                    return 0
                end

                return payload[1]
            end
        end
    end

    return 0
end

function t1.PlaybackClip.materialize(p24, p25, p26) -- line: 246
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local t4 = {}
    local v48 = if p25.kind == 0 then 1
        elseif p25.kind == 1 then 4
        elseif p25.kind == 3 then 6
        else 0

    if #p25.payload < v48 then
        error("Truncated clip attribute payload", 0)
    end

    for i = 0, v48 - 1 do
        t4[i + 1] = p25.payload[i + 1]
    end

    if p25.kind == 2 then
        local v49 = p24.clock.time * p24.clock.fps * p24.clock.speed
        local v50 = t1.sample_curve(p25.payload, v49)
        local v51

        if v50 == 0 then
            buffer.writef32(v1, 0, v50)
            v51 = buffer.readu32(v1, 0)
        elseif v50 > -1.1754943508222875E-38 and v50 < 1.1754943508222875E-38 then
            local v52 = math.abs(v50) * 7.1362384635298E+44

            v51 = math.floor(v52)

            local v53 = v52 - v51

            if v53 > 0.5 or v53 == 0.5 and v51 % 2 == 1 then
                v51 += 1
            end

            if v50 < 0 then
                v51 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v50)
            v51 = buffer.readu32(v1, 0)
        end

        t4[1] = v51
    end

    return {
        sequence_id = -1,
        name = rt.copy(p25.name),
        kind = p25.kind,
        payload = { t4 },
        status = p26,
        begin_time = if bit32.band(p26, 2) == 0 then p25.begin * p24.clock.length else -1,
        end_time = if bit32.band(p26, 2) == 0 then p25["end"] * p24.clock.length else -1
    }
end

function t1.sample_curve(p27, p28) -- line: 284
    -- upvalues: rt (copy), v1 (copy)
    local v54 = p27[2]

    if v54 == nil then
        error("Missing animation curve count", 0)
    end

    local v55 = v54 == 0
    local v56 = if not v55 then rt.idiv(math.max(#p27 - 2, 0), 2) < v54 else nil

    if v55 or v56 then
        error("Truncated/empty animation curve", 0)
    end

    local function point(p29) -- line: 293
        -- upvalues: p27 (copy), v1 (copy)
        buffer.writeu32(v1, 0, p27[p29 * 2 + 2 + 1])

        local v59 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p27[p29 * 2 + 3 + 1])

        return v59, (buffer.readf32(v1, 0))
    end

    local v61 = v54 - 1

    buffer.writeu32(v1, 0, p27[0 * 2 + 2 + 1])

    local v63 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p27[0 * 2 + 3 + 1])

    local v65 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p27[v61 * 2 + 2 + 1])

    local v67 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p27[v61 * 2 + 3 + 1])

    local v69 = buffer.readf32(v1, 0)

    if not (v63 < p28) then
        return v65
    end

    if p28 < v67 then
        local n1 = 0
        local v70

        while true do
            if v67 < v63 then
                return (v65 - v69) / (v63 - v67) * (p28 - v67) + v69
            end

            local v71 = rt.idiv(n1 + v61, 2)

            buffer.writeu32(v1, 0, p27[v71 * 2 + 2 + 1])

            local v73 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, p27[v71 * 2 + 3 + 1])
            v70 = buffer.readf32(v1, 0)

            if v73 < p28 then
                local v75 = v71 + 1

                if v54 <= v75 then
                    error("Malformed animation curve search bounds", 0)
                end

                buffer.writeu32(v1, 0, p27[v75 * 2 + 2 + 1])
                v63 = buffer.readf32(v1, 0)
                buffer.writeu32(v1, 0, p27[v75 * 2 + 3 + 1])
                n1 = v75
                v65 = buffer.readf32(v1, 0)
                continue
            end

            if not (p28 < v73) then
                break
            end

            if v71 < 1 then
                error("Malformed animation curve search bounds", 0)
            end

            v61 = v71 - 1
            buffer.writeu32(v1, 0, p27[v61 * 2 + 2 + 1])
            v67 = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, p27[v61 * 2 + 3 + 1])
            v69 = buffer.readf32(v1, 0)
        end

        return v70
    end

    return v69
end

return t1
