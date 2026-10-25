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

local Collections = require(sim.import)("skate_data/collections").Collections
local t1 = {}

function t1.load(p2) -- line: 22
    -- upvalues: Collections (copy), t1 (copy)
    local function c(p3) -- line: 23
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "anim_motion", "crouching", p3)
    end

    local function a(p4) -- line: 26
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "anim_motion", "auto_pump", p4)
    end

    return {
        maximum_height = t1.negative8(p2, "crouching", "crouching_max_height"),
        absorption_upforce = t1.plain8(p2, "crouching", "absorption_upforce"),
        pump_maxspeed = t1.plain8(p2, "crouching", "pump_maxspeed"),
        minimum_height = Collections.float(p2, "anim_motion", "crouching", "crouching_min_height"),
        maximum_ratio = Collections.float(p2, "anim_motion", "crouching", "crouch_max_ratio"),
        maximum_delta_delta = Collections.float(p2, "anim_motion", "crouching", "crouch_max_delta_delta"),
        maximum_delta = Collections.float(p2, "anim_motion", "crouching", "crouch_max_delta"),
        input_blend = Collections.float(p2, "anim_motion", "crouching", "crouch_blend_input"),
        pump_vertical_speed = Collections.float(p2, "anim_motion", "crouching", "pump_maxspeed_yaxis"),
        maximum_crouch_from_deck = Collections.float(p2, "anim_motion", "crouching", "MaxCrouchFromDeckAngle"),
        skateboard_damping = Collections.float(p2, "anim_motion", "crouching", "absorption_skateboard_damping"),
        maximum_force = Collections.float(p2, "anim_motion", "crouching", "absorption_maxforce"),
        maximum_ground_force = Collections.float(p2, "anim_motion", "crouching", "absorption_ground_maxforce"),
        absorption_factor = Collections.float(p2, "anim_motion", "crouching", "absorption_factor"),
        auto_pump = {
            maximum_crouch = t1.negative4(p2, "auto_pump", "auto_pump_max_crouch"),
            sufficient_crouch = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_sufficient_crouch"),
            standing_threshold = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_standing_thresh"),
            rise_speed = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_rise_speed"),
            pump_speed = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_pump_speed"),
            potential_threshold = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_potential_thresh"),
            potential_blend = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_potential_blend"),
            intent_magnitude_start = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_intent_mag_start"),
            intent_angle_region = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_intent_angle_region"),
            crouch_time = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_crouch_time"),
            crouch_speed = Collections.float(p2, "anim_motion", "auto_pump", "auto_pump_crouch_speed")
        }
    }
end

function t1.negative8(p5, p6, p7) -- line: 91
    -- upvalues: v1 (copy), Collections (copy)
    local v2 = Collections.words(p5, "anim_motion", p6, p7, 20)
    local t2 = {}

    buffer.writeu32(v1, 0, v2[5])

    local v4 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[6])

    local v6 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[7])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[8])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[9])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[10])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[11])

    local v16 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[12])
    t2.x = {
        v4,
        v6,
        v8,
        v10,
        v12,
        v14,
        v16,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v2[13])

    local v19 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[14])

    local v21 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[15])

    local v23 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[16])

    local v25 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[17])

    local v27 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[18])

    local v29 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[19])

    local v31 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[20])
    t2.y = {
        v19,
        v21,
        v23,
        v25,
        v27,
        v29,
        v31,
        (buffer.readf32(v1, 0))
    }

    return t2
end

function t1.negative4(p8, p9, p10) -- line: 118
    -- upvalues: v1 (copy), Collections (copy)
    local v33 = Collections.words(p8, "anim_motion", p9, p10, 12)
    local t3 = {}

    buffer.writeu32(v1, 0, v33[5])

    local v35 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v33[6])

    local v37 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v33[7])

    local v39 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v33[8])
    t3.x = {
        v35,
        v37,
        v39,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v33[9])

    local v42 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v33[10])

    local v44 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v33[11])

    local v46 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v33[12])
    t3.y = {
        v42,
        v44,
        v46,
        (buffer.readf32(v1, 0))
    }

    return t3
end

function t1.plain8(p11, p12, p13) -- line: 137
    -- upvalues: v1 (copy), Collections (copy)
    local v48 = Collections.words(p11, "anim_motion", p12, p13, 16)
    local t4 = {}

    buffer.writeu32(v1, 0, v48[1])

    local v50 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[2])

    local v52 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[3])

    local v54 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[4])

    local v56 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[5])

    local v58 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[6])

    local v60 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[7])

    local v62 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[8])
    t4.x = {
        v50,
        v52,
        v54,
        v56,
        v58,
        v60,
        v62,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v48[9])

    local v65 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[10])

    local v67 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[11])

    local v69 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[12])

    local v71 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[13])

    local v73 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[14])

    local v75 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[15])

    local v77 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v48[16])
    t4.y = {
        v65,
        v67,
        v69,
        v71,
        v73,
        v75,
        v77,
        (buffer.readf32(v1, 0))
    }

    return t4
end

return t1
