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
local t1 = {}

t1.TrickIntent = {}

function t1.TrickIntent.eq(p2, p3) -- line: 29
    if p2.name == p3.name then
        return p2.value == p3.value
    end

    return false
end

function t1.produce(p4) -- line: 38
    -- upvalues: v1 (copy), DerivedControllerInput (copy)
    local v3 = DerivedControllerInput.words(p4)

    buffer.writeu32(v1, 0, v3[12])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[13])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[10])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[11])

    local v11 = buffer.readf32(v1, 0)
    local v12 = v5 == 1
    local v13 = v7 == 1
    local v14 = v5 > 0
    local v15 = v7 > 0
    local t2 = {}

    local function emit(p5, p6) -- line: 53
        -- upvalues: t2 (copy)
        table.insert(t2, {
            name = p5,
            value = p6
        })
    end

    if v12 then
        table.insert(t2, {
            name = "LeftGroundGrab",
            value = 1
        })
    end

    if v14 then
        table.insert(t2, {
            name = "LeftAirGrab",
            value = 1
        })
    end

    if v13 then
        table.insert(t2, {
            name = "RightGroundGrab",
            value = 1
        })
    end

    if v15 then
        table.insert(t2, {
            name = "RightAirGrab",
            value = 1
        })
    end

    local v16 = v3[7]
    local v17 = v3[14]

    if bit32.band(v17, 1048576) ~= 0 then
        table.insert(t2, {
            name = "Dismount",
            value = 1
        })

        if bit32.band(v16, 1048576) == 0 then
            table.insert(t2, {
                name = "NewDismount",
                value = 1
            })
        end
    end

    if bit32.band(v17, 269484032) ~= 0 then
        table.insert(t2, {
            name = "DarkCatch",
            value = 1
        })
    end

    if bit32.band(v17, 269484032) ~= 0 and bit32.band(v16, 269484032) == 0 then
        table.insert(t2, {
            name = "NewDarkCatch",
            value = 1
        })
    end

    local v19 = math.sqrt(v9 * v9 + v11 * v11)

    if v19 > 0 then
        table.insert(t2, {
            name = "BoardAdjustAngle",
            value = math.atan2(v9, -v11)
        })
        table.insert(t2, {
            name = "BoardAdjustMag",
            value = v19
        })
    end

    if v9 ~= 0 then
        table.insert(t2, {
            name = "TweakX",
            value = v9
        })
    end

    if v11 ~= 0 then
        table.insert(t2, {
            name = "TweakY",
            value = v11
        })
    end

    if bit32.band(v17, 268435456) ~= 0 then
        table.insert(t2, {
            name = "GrabWorld",
            value = 1
        })
    end

    if v9 ~= 0 then
        table.insert(t2, {
            name = "HandPlantTweakX",
            value = v9
        })
    end

    if v11 ~= 0 then
        table.insert(t2, {
            name = "HandPlantTweakY",
            value = v11
        })
    end

    for _, v21 in {
            { 20, "HandPlantDismount" },
            { 21, "HandPlantOneFootRight" },
            { 23, "HandPlantOneFootLeft" }
        } do
        local v22 = v21[1]
        local v23 = v21[2]

        if bit32.band(v17, (bit32.lshift(1, v22))) ~= 0 then
            table.insert(t2, {
                value = 1,
                name = v23
            })
        end
    end

    return t2
end

return t1
