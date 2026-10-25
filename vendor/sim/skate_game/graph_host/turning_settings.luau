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
    local function float(p3) -- line: 23
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "anim_carving", "default", p3)
    end

    local quickMagMap = t1.curve16(p2, "quickMagMap")
    local quickAngleMap = t1.curve16(p2, "quickAngleMap")
    local quickAngleOffset = Collections.float(p2, "anim_carving", "default", "quickAngleOffset")
    local slowMagMap = t1.curve16(p2, "slowMagMap")
    local slowAngleMap = t1.curve16(p2, "slowAngleMap")
    local slowAngleOffset = Collections.float(p2, "anim_carving", "default", "slowAngleOffset")

    return {
        remaps = {
            {
                magnitude = quickMagMap,
                angle = quickAngleMap,
                angle_offset = quickAngleOffset
            },
            {
                magnitude = slowMagMap,
                angle = slowAngleMap,
                angle_offset = slowAngleOffset
            }
        },
        speed_tuck = t1.curve8(p2, "speed_tuck"),
        blend = t1.curve8(p2, "blend_lean_in"),
        speed_threshold = Collections.float(p2, "anim_carving", "default", "speed_tuck_start"),
        maximum_delta = Collections.float(p2, "anim_carving", "default", "clamp_curr_lean"),
        override_turn = Collections.float(p2, "anim_motion", "power_slide", "slide_turn_value")
    }
end

function t1.curve16(p4, p5) -- line: 49
    -- upvalues: v1 (copy), Collections (copy)
    local v2 = Collections.words(p4, "anim_carving", "default", p5, 36)
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

    local v18 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[13])

    local v20 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[14])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[15])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[16])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[17])

    local v28 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[18])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[19])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[20])
    t2.x = {
        v4,
        v6,
        v8,
        v10,
        v12,
        v14,
        v16,
        v18,
        v20,
        v22,
        v24,
        v26,
        v28,
        v30,
        v32,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v2[21])

    local v35 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[22])

    local v37 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[23])

    local v39 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[24])

    local v41 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[25])

    local v43 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[26])

    local v45 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[27])

    local v47 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[28])

    local v49 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[29])

    local v51 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[30])

    local v53 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[31])

    local v55 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[32])

    local v57 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[33])

    local v59 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[34])

    local v61 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[35])

    local v63 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[36])
    t2.y = {
        v35,
        v37,
        v39,
        v41,
        v43,
        v45,
        v47,
        v49,
        v51,
        v53,
        v55,
        v57,
        v59,
        v61,
        v63,
        (buffer.readf32(v1, 0))
    }

    return t2
end

function t1.curve8(p6, p7) -- line: 92
    -- upvalues: v1 (copy), Collections (copy)
    local v65 = Collections.words(p6, "anim_carving", "default", p7, 20)
    local t3 = {}

    buffer.writeu32(v1, 0, v65[5])

    local v67 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[6])

    local v69 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[7])

    local v71 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[8])

    local v73 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[9])

    local v75 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[10])

    local v77 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[11])

    local v79 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[12])
    t3.x = {
        v67,
        v69,
        v71,
        v73,
        v75,
        v77,
        v79,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v65[13])

    local v82 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[14])

    local v84 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[15])

    local v86 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[16])

    local v88 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[17])

    local v90 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[18])

    local v92 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[19])

    local v94 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v65[20])
    t3.y = {
        v82,
        v84,
        v86,
        v88,
        v90,
        v92,
        v94,
        (buffer.readf32(v1, 0))
    }

    return t3
end

return t1
