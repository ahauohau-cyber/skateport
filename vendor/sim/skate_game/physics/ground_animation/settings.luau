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

local Collections = require(sim.import)("skate_data/collections").Collections
local graph
local t1 = {}

t1.GroundAnimationSettings = {}

function t1.GroundAnimationSettings.load(p2) -- line: 29
    -- upvalues: rt (copy), v1 (copy), Collections (copy), graph (ref)
    local function f(p3) -- line: 30
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "physics_jump", "default", p3)
    end

    local v2 = Collections.words(p2, "physics_jump", "default", "VerticalResponse", 32)
    local v3 = rt.filled(5, {
        minimum_height_64 = 0,
        minimum_height_68 = 0,
        maximum_height = 0
    })
    local t2 = {
        "easy",
        "normal",
        "hardcore",
        "motorized",
        "test"
    }

    for i = 1, 5 do
        local v4 = t2[i]

        v3[i] = {
            minimum_height_64 = Collections.float(p2, "physics_mode", v4, "Hash_BE3F74F978D777E5"),
            minimum_height_68 = Collections.float(p2, "physics_mode", v4, "JumpMinHeight"),
            maximum_height = Collections.float(p2, "physics_mode", v4, "JumpMaxHeight")
        }
    end

    local t3 = {}
    local t4 = {}

    buffer.writeu32(v1, 0, v2[1])

    local v6 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[2])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[3])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[4])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[5])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[6])

    local v16 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[7])

    local v18 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[8])

    local v20 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[9])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[10])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[11])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[12])

    local v28 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[13])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[14])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[15])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[16])
    t4.x = {
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
        v34,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v2[17])

    local v37 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[18])

    local v39 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[19])

    local v41 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[20])

    local v43 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[21])

    local v45 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[22])

    local v47 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[23])

    local v49 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[24])

    local v51 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[25])

    local v53 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[26])

    local v55 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[27])

    local v57 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[28])

    local v59 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[29])

    local v61 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[30])

    local v63 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[31])

    local v65 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[32])
    t4.y = {
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
        v65,
        (buffer.readf32(v1, 0))
    }
    t3.vertical_response = t4
    t3.y_scalar_vs_normal_y = graph(p2, "JumpYScalarVsGroundNormalY", true)
    t3.speed_scalar_vs_angle = graph(p2, "JumpSpeedScalarVsAngle", true)
    t3.minimum_height_vs_speed = graph(p2, "MinHeightVsSpeed", false)
    t3.maximum_height_vs_speed = graph(p2, "MaxHeightVsSpeed", false)
    t3.speed_response_max_speed = Collections.float(p2, "physics_jump", "default", "SpeedResponseMaxSpeed")
    t3.minimum_scalar = Collections.float(p2, "physics_jump", "default", "MinScalar")
    t3.maximum_y_bonus = Collections.float(p2, "physics_jump", "default", "JumpYBonusMax")
    t3.adjust_z_factor = Collections.float(p2, "physics_jump", "default", "JumpAdjustZFactor")
    t3.adjust_x_factor = Collections.float(p2, "physics_jump", "default", "JumpAdjustXFactor")
    t3.absolute_minimum_height = Collections.float(p2, "physics_jump", "default", "AbsoluteMinHeight")
    t3.hippy_minimum_height = Collections.float(p2, "physics_jump", "default", "HippyJumpMinHeight")
    t3.hippy_maximum_height = Collections.float(p2, "physics_jump", "default", "HippyJumpMaxHeight")

    return {
        modes = v3,
        jump = t3
    }
end

function graph(p4, p5, p6) -- line: 106
    -- upvalues: v1 (copy), Collections (copy)
    local t5, t6

    if p6 then
        local v67 = Collections.words(p4, "physics_jump", "default", p5, 20)

        buffer.writeu32(v1, 0, v67[5])

        local v69 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[6])

        local v71 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[7])

        local v73 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[8])

        local v75 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[9])

        local v77 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[10])

        local v79 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[11])

        local v81 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[12])
        t5 = {
            v69,
            v71,
            v73,
            v75,
            v77,
            v79,
            v81,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v67[13])

        local v84 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[14])

        local v86 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[15])

        local v88 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[16])

        local v90 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[17])

        local v92 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[18])

        local v94 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[19])

        local v96 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v67[20])
        t6 = {
            v84,
            v86,
            v88,
            v90,
            v92,
            v94,
            v96,
            (buffer.readf32(v1, 0))
        }
    else
        local v98 = Collections.words(p4, "physics_jump", "default", p5, 16)

        buffer.writeu32(v1, 0, v98[1])

        local v100 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[2])

        local v102 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[3])

        local v104 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[4])

        local v106 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[5])

        local v108 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[6])

        local v110 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[7])

        local v112 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[8])
        t5 = {
            v100,
            v102,
            v104,
            v106,
            v108,
            v110,
            v112,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v98[9])

        local v115 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[10])

        local v117 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[11])

        local v119 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[12])

        local v121 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[13])

        local v123 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[14])

        local v125 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[15])

        local v127 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v98[16])
        t6 = {
            v115,
            v117,
            v119,
            v121,
            v123,
            v125,
            v127,
            (buffer.readf32(v1, 0))
        }
    end

    return {
        x = t5,
        y = t6
    }
end

t1.graph = graph

return t1
