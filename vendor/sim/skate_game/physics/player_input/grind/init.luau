-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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
local v8 = import("skate_game/physics/player_input/grind/history")
local v9 = import("skate_game/physics/player_input/grind/post")
local v10 = import("skate_game/physics/player_input/grind/pre")
local v11 = import("skate_game/physics/player_input/grind/settings")
local v12 = import("skate_core/physics/grind_contact/balance")
local v13 = import("skate_core/physics/grind_contact/control")
local v14 = import("skate_core/physics/grind_contact/entry")
local v15 = import("skate_core/physics/grind_contact/manager")
local GrindInvestigationFields = import("skate_core/player/input_phase").GrindInvestigationFields
local t1 = {
    V = {},
    PreContext = {},
    PostContext = {},
    MaterialMode = {},
    PrimitiveMetadata = {},
    Host = {},
    Pending = {},
    GeometryWork = {},
    PostResult = {},
    GrindInputState = {}
}

function t1.GrindInputState.load(p4) -- line: 124
    -- upvalues: v11 (copy), v12 (copy), v13 (copy), v14 (copy), v15 (copy), GrindInvestigationFields (copy)
    return {
        previous_state = 0,
        engagement_counter = 0,
        cooldown = 0,
        disabled = false,
        suppressed = false,
        elapsed = 0,
        friction_vs_time = 0,
        grind_history = 0,
        secondary_history = 0,
        grounded_frames = 0,
        air_frames = 0,
        low_wheel_frames = 0,
        previous_proximity = false,
        previous_air_target = false,
        gravity_timer = 0,
        previous_velocity = { 0, 0, 0, 0 },
        previous_direction = { 0, 0, 0, 0 },
        balance = v12.BalanceState.default(),
        engagement = v14.Engagement.default(),
        control = v13.Control.default(),
        jumper = v15.Jumper.default(),
        investigation = GrindInvestigationFields.default(),
        settings = v11.Settings.load(p4)
    }
end

function t1.GrindInputState.reset(p5) -- line: 154
    -- upvalues: GrindInvestigationFields (copy)
    p5.previous_state = 0
    p5.engagement_counter = 0
    p5.cooldown = 0
    p5.disabled = false
    p5.suppressed = false
    p5.elapsed = 0
    p5.gravity_timer = 0
    p5.friction_vs_time = 0
    p5.previous_direction = { 0, 0, 0, 0 }
    p5.investigation = GrindInvestigationFields.default()
end

for _, v16 in { v8, v9, v10 } do
    for v17, v18 in v16.GrindInputState do
        t1.GrindInputState[v17] = v18
    end
end

function t1.float(p6) -- line: 175
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p6[1])

    local v20 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[2])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[3])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[4])

    return {
        v20,
        v22,
        v24,
        (buffer.readf32(v1, 0))
    }
end

function t1.raw(p7) -- line: 180
    -- upvalues: v1 (copy)
    local v26 = p7[1]
    local v27

    if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
        local v28 = math.abs(v26) * 7.1362384635298E+44
        local v29 = math.floor(v28)
        local v30 = v28 - v29

        v27 = if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29

        if v26 < 0 then
            v27 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v26)
        v27 = buffer.readu32(v1, 0)
    end

    local v31 = p7[2]
    local v32

    if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
        local v33 = math.abs(v31) * 7.1362384635298E+44
        local v34 = math.floor(v33)
        local v35 = v33 - v34

        v32 = if v35 > 0.5 or v35 == 0.5 and v34 % 2 == 1 then v34 + 1 else v34

        if v31 < 0 then
            v32 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v31)
        v32 = buffer.readu32(v1, 0)
    end

    local v36 = p7[3]
    local v37

    if v36 ~= 0 and v36 > -1.1754943508222875E-38 and v36 < 1.1754943508222875E-38 then
        local v38 = math.abs(v36) * 7.1362384635298E+44
        local v39 = math.floor(v38)
        local v40 = v38 - v39

        v37 = if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39

        if v36 < 0 then
            v37 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v36)
        v37 = buffer.readu32(v1, 0)
    end

    local v41 = p7[4]
    local v42

    if v41 ~= 0 and v41 > -1.1754943508222875E-38 and v41 < 1.1754943508222875E-38 then
        local v43 = math.abs(v41) * 7.1362384635298E+44
        local v44 = math.floor(v43)
        local v45 = v43 - v44

        v42 = if v45 > 0.5 or v45 == 0.5 and v44 % 2 == 1 then v44 + 1 else v44

        if v41 < 0 then
            v42 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v41)
        v42 = buffer.readu32(v1, 0)
    end

    return {
        v27,
        v32,
        v37,
        v42
    }
end

return t1
