-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/input/angle")
local v3 = import("skate_core/input/controller")
local v4 = import("skate_core/input/steering_intentions")
local left_stick_angle = v2.left_stick_angle
local DerivedControllerInput, magnitude = v3.DerivedControllerInput, v3.magnitude
local t1 = {}

t1.PushPreferences = {}

function t1.PushPreferences.default() -- line: 32
    return {
        automatic_push_enabled = false,
        automatic_push_right = false
    }
end

t1.RidingIntent = {}

function t1.RidingIntent.eq(p2, p3) -- line: 40
    if p2.name == p3.name then
        return p2.value == p3.value
    end

    return false
end

function t1.produce(p4, p5, p6) -- line: 45
    -- upvalues: rt (copy), v1 (copy), v4 (copy), left_stick_angle (copy), DerivedControllerInput (copy), magnitude (copy)
    local v5 = DerivedControllerInput.words(p4)
    local v6 = v5[7]
    local v7 = v5[14]

    buffer.writeu32(v1, 0, v5[8])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[9])

    local t2 = {
        v9,
        (buffer.readf32(v1, 0))
    }
    local v11 = bit32.band(p5, 2048) == 0

    local function held(p7) -- line: 51
        -- upvalues: v7 (copy), v11 (copy)
        if bit32.band(v7, (bit32.lshift(1, p7))) == 0 then
            return false
        end

        return v11
    end

    local function new(p8, p9) -- line: 54
        -- upvalues: v5 (copy), v6 (copy), v7 (copy), v11 (copy), v1 (copy)
        local v14 = bit32.band(v7, (bit32.lshift(1, p8))) ~= 0 and v11

        if v14 then
            if bit32.band(v6, (bit32.lshift(1, p8))) == 0 then
                v14 = true
            else
                buffer.writeu32(v1, 0, v5[p9 + 1])
                v14 = buffer.readf32(v1, 0) < 0.3
            end
        end

        return v14
    end

    local v17 = bit32.band(v7, 2097152) ~= 0 and v11
    local v18 = bit32.band(v7, 8388608) ~= 0 and v11
    local v19 = bit32.band(v7, 2097152) ~= 0 and v11

    if v19 then
        if bit32.band(v6, 2097152) == 0 then
            v19 = true
        else
            buffer.writeu32(v1, 0, v5[21])
            v19 = buffer.readf32(v1, 0) < 0.3
        end
    end

    local v21 = bit32.band(v7, 8388608) ~= 0 and v11

    if v21 then
        if bit32.band(v6, 8388608) == 0 then
            v21 = true
        else
            buffer.writeu32(v1, 0, v5[23])
            v21 = buffer.readf32(v1, 0) < 0.3
        end
    end

    local v23 = left_stick_angle(t2[1], t2[2])
    local v24 = if v23 >= 0 then 3.1415927410125732 - v23 else -3.1415927410125732 - v23
    local v25 = magnitude(t2[2] * t2[2] + t2[1] * t2[1])

    if p6.automatic_push_enabled and v11 and not (v17 or v18 or v19 or v21) and math.abs(v24) < 0.6 and v25 > 0.8 then
        if p6.automatic_push_right then
            v17 = true
            v19 = true
        else
            v18 = true
            v21 = true
        end
    end

    local v26 = v19
    local v27 = v21
    local v28 = v17
    local v29 = v18

    if bit32.band(p5, 64) == 0 then
    elseif (v17 or v19) and (v18 or v21) then
        v28 = false
        v29 = false
        v26 = false
        v27 = false
    end

    local t3 = {}

    local function emit(p10, p11) -- line: 92
        -- upvalues: t3 (copy)
        table.insert(t3, {
            name = p10,
            value = p11
        })
    end

    if bit32.band(v7, 1048576) ~= 0 and bit32.band(p5, 128) == 0 then
        table.insert(t3, {
            name = "Brake",
            value = 1
        })
    end

    if v26 or v27 then
        table.insert(t3, {
            name = "NewPush",
            value = 1
        })
    end

    if v28 then
        table.insert(t3, {
            name = "RightPush",
            value = 1
        })
        table.insert(t3, {
            name = "Pushing",
            value = 1
        })
    end

    if v29 then
        table.insert(t3, {
            name = "LeftPush",
            value = 1
        })
        table.insert(t3, {
            name = "Pushing",
            value = 1
        })
    end

    if t2[1] ~= 0 and bit32.band(p5, 2) == 0 then
        table.insert(t3, {
            name = "BodySpin",
            value = t2[1]
        })
        table.insert(t3, {
            name = "PhysBodySpin",
            value = t2[1]
        })
    end

    if t2[1] ~= 0 and bit32.band(p5, 1) == 0 then
        table.insert(t3, {
            name = "KickTurn",
            value = t2[1]
        })
    end

    local v30 = v4.produce(rt.copy(t2), p5)

    if v30.hard_turn_crouch ~= nil then
        table.insert(t3, {
            name = "HardTurnCrouch",
            value = v30.hard_turn_crouch
        })
    end

    if v30.hard_turn ~= nil then
        table.insert(t3, {
            name = "HardTurn",
            value = v30.hard_turn
        })
    end

    local v31 = math.abs(v23)
    local v32 = (if v31 <= 1.9199999570846558 then 0 elseif v31 < 2.3499999046325684 then (v31 - 1.9199999570846558) * 2.3255817890167236 * v25 else v25) * 0

    buffer.writeu32(v1, 0, v5[12])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v5[13])

    local v36 = buffer.readf32(v1, 0)

    if v31 > 1.9199999570846558 or v34 > 0 or v36 ~= 0 then
        if not (v34 - v36 >= -0) then
            v34 = v36
        end

        if not (v32 - v34 >= -0) then
            v32 = v34
        end

        table.insert(t3, {
            name = "Crouch",
            value = v32
        })
    end

    if v30.turn ~= nil then
        table.insert(t3, {
            name = "Turn",
            value = v30.turn
        })
    end

    if bit32.band(p5, 256) == 0 and v25 > 0.89999998 then
        if v23 > 0 and v23 < 0.91000003 then
            table.insert(t3, {
                name = "RightSlideStart",
                value = 1
            })
        end

        if v23 > -0.91000003 and v23 < 0 then
            table.insert(t3, {
                name = "LeftSlideStart",
                value = 1
            })
        end

        if v23 > -2 and v23 < 1.5707963705062866 then
            table.insert(t3, {
                name = "LeftSlide",
                value = -((v23 + 2) * 0.28004956)
            })
        end

        if v23 > -1.5707963705062866 and v23 < 2 then
            table.insert(t3, {
                name = "RightSlide",
                value = (2 - v23) * 0.28004956
            })
        end
    end

    if bit32.band(v7, 268435456) ~= 0 then
        table.insert(t3, {
            name = "GrabWorld",
            value = 1
        })
    end

    return t3
end

return t1
