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
local t1 = {
    Settings = {}
}

function t1.Settings.load(p2) -- line: 39
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    local function float(p3) -- line: 40
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "physics_footplantmanager", "default", p3)
    end

    local v2 = Collections.words(p2, "physics_footplantmanager", "default", "Hash_8A8887218466ED15", 20)
    local v3 = table.create(20)

    for i = 1, 20 do
        buffer.writeu32(v1, 0, v2[i])
        v3[i] = buffer.readf32(v1, 0)
    end

    local v5 = Collections.words(p2, "physics_footplantmanager", "default", "DeckBB", 4)
    local v6 = table.create(4)

    buffer.writeu32(v1, 0, v5[1])
    v6[1] = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v5[2])
    v6[2] = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v5[3])
    v6[3] = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v5[4])
    v6[4] = buffer.readf32(v1, 0)

    return {
        deck_bounds = v6,
        max_leg_angle_error = Collections.float(p2, "physics_footplantmanager", "default", "MaxLegAngleError"),
        leg_length_on_landing = Collections.float(p2, "physics_footplantmanager", "default", "LegLengthOnLanding"),
        foot_volume_y_offset = Collections.float(p2, "physics_footplantmanager", "default", "FootVolumeYOffset"),
        deck_bounds_y_offset = Collections.float(p2, "physics_footplantmanager", "default", "DeckBBYOffset"),
        radial_speed_scale = {
            x = rt.slice(v3, 4, 12),
            y = rt.slice(v3, 12, 20)
        },
        max_horizontal_speed = Collections.float(p2, "physics_footplantmanager", "default", "Hash_149A5D0D4768D2B1"),
        max_descending_speed = Collections.float(p2, "physics_footplantmanager", "default", "Hash_52436D9F4FE56BCB"),
        release_outward_speed = Collections.float(p2, "physics_footplantmanager", "default", "Hash_C5F92168DFAFD0B8"),
        end_handle = Collections.float(p2, "physics_footplantmanager", "default", "Hash_628C228DCC7B6ED5"),
        end_angle = Collections.float(p2, "physics_footplantmanager", "default", "Hash_4F45DA86685CF029"),
        end_leg_length = Collections.float(p2, "physics_footplantmanager", "default", "Hash_0DE0027B9913C5D5"),
        start_handle = Collections.float(p2, "physics_footplantmanager", "default", "Hash_5C4341EF35F4B2B0"),
        min_duration = Collections.float(p2, "physics_footplantmanager", "default", "Hash_D6224B710A36D643"),
        max_duration = Collections.float(p2, "physics_footplantmanager", "default", "Hash_68C05A7FCC6BB718")
    }
end

return t1
