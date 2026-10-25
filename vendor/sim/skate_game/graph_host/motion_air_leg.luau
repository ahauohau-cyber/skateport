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

local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local Collections = import("skate_data/collections").Collections
local Attributes = import("skate_data/state_graph/attributes").Attributes
local t1 = {
    Operation = {}
}

function t1.Operation.parse(p2) -- line: 26
    -- upvalues: encode (copy), Attributes (copy)
    local driveDistToCom = Attributes.text(p2, "driveDistToCom")

    if driveDistToCom == nil then
        driveDistToCom = "disttocog"
    end

    local bone = Attributes.text(p2, "bone")

    if bone == nil then
        bone = "Skateboard_Root"
    end

    local v2 = if bone == "LeftToeBase" then "LeftToe" elseif bone == "RightToeBase" then "RightToe" else "Board"

    return {
        height = encode(driveDistToCom),
        bone = v2
    }
end

function t1.load(p3) -- line: 50
    -- upvalues: v1 (copy), Collections (copy)
    local function value(p4) -- line: 51
        -- upvalues: p3 (copy), Collections (copy)
        return Collections.float(p3, "anim_motion", "inair_disttocog", p4)
    end

    local v3 = Collections.words(p3, "anim_motion", "inair_disttocog", "lo_air_arm_extend", 12)
    local t2 = {
        going_up_speed = Collections.float(p3, "anim_motion", "inair_disttocog", "goingup_disttocog_speed"),
        going_down_speed = Collections.float(p3, "anim_motion", "inair_disttocog", "goingdown_disttocog_speed"),
        minimum_height = Collections.float(p3, "anim_motion", "inair_disttocog", "min_inair_disttocog"),
        preland_velocity = Collections.float(p3, "anim_motion", "inair_disttocog", "preland_disttocom_vel"),
        preland_final_height = Collections.float(p3, "anim_motion", "inair_disttocog", "preland_final_disttocom"),
        offboard_multiplier = Collections.float(p3, "anim_motion", "inair_disttocog", "offboard_preland_disttocom_vel_multiplier")
    }
    local t3 = {}

    buffer.writeu32(v1, 0, v3[5])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[6])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[7])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[8])
    t3.x = {
        v5,
        v7,
        v9,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v3[9])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[10])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[11])

    local v16 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v3[12])
    t3.y = {
        v12,
        v14,
        v16,
        (buffer.readf32(v1, 0))
    }
    t2.arm_extension = t3

    return t2
end

return t1
