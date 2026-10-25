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

function t1.Settings.load(p2) -- line: 48
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    local function floats(p3, p4) -- line: 50
        -- upvalues: v1 (copy)
        local v2 = table.create(p4)

        for i = 1, p4 do
            buffer.writeu32(v1, 0, p3[i])
            v2[i] = buffer.readf32(v1, 0)
        end

        return v2
    end

    local function graph4(p5, p6) -- line: 58
        -- upvalues: p2 (copy), floats (copy), rt (copy), Collections (copy)
        local v4 = floats(Collections.words(p2, p5, "default", p6, 12), 12)

        return {
            x = rt.slice(v4, 4, 8),
            y = rt.slice(v4, 8, 12)
        }
    end

    local function graph8(p7) -- line: 66
        -- upvalues: p2 (copy), floats (copy), rt (copy), Collections (copy)
        local v5 = floats(Collections.words(p2, "physics_handplantmanager", "default", p7, 20), 20)

        return {
            x = rt.slice(v5, 4, 12),
            y = rt.slice(v5, 12, 20)
        }
    end

    local function f(p8) -- line: 73
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "physics_handplantmanager", "default", p8)
    end

    local DeckCenterToTruck = Collections.float(p2, "physics_grinds", "default", "DeckCenterToTruck")

    return {
        window = {
            graph4("Hash_55B5940075F78842", "Hash_FF0DE8A42210E8C0"),
            graph4("Hash_55B5940075F78842", "Hash_B90C78786ED04A7D"),
            graph4("Hash_55B5940075F78842", "Hash_DC7947C6DD03CDAA"),
            graph4("Hash_55B5940075F78842", "Hash_0ACB7AAE2662FBB2"),
            graph4("Hash_55B5940075F78842", "Hash_CF7F668AB995380D"),
            graph4("Hash_55B5940075F78842", "Hash_8348DA199CC87B7A"),
            (graph4("Hash_55B5940075F78842", "Hash_F27F622CAE33BD50"))
        },
        depth = Collections.float(p2, "Hash_55B5940075F78842", "default", "Hash_3D9138A04C6D43F6"),
        window_drop = Collections.float(p2, "Hash_55B5940075F78842", "default", "Hash_A046D0516C0BD62B"),
        time_warp = graph8("Hash_F551DF3289124FB0"),
        out_heading = graph8("Hash_8FC9A4F9002CF9E0"),
        into_rotation = graph8("Hash_F61B0FB73C39311B"),
        out_rotation = graph8("Hash_D4EF764AF4D5F1CA"),
        hand_radius = graph4("physics_handplantmanager", "Hash_5494E3F9BE572D6B"),
        curve_half_time = Collections.float(p2, "physics_handplantmanager", "default", "Hash_2460D6544C3B64B7"),
        entry_blend = Collections.float(p2, "physics_handplantmanager", "default", "Hash_CCD7A82CE1BBFFF2"),
        hand_out = Collections.float(p2, "physics_handplantmanager", "default", "Hash_E0895C189D77CE16"),
        hand_into = Collections.float(p2, "physics_handplantmanager", "default", "Hash_01EB855A0ACBD84C"),
        hand_release = Collections.float(p2, "physics_handplantmanager", "default", "Hash_9C02B9E6998D1321"),
        minimum_speed = Collections.float(p2, "physics_handplantmanager", "default", "Hash_63303CA6C611DC79"),
        minimum_slope = Collections.float(p2, "physics_handplantmanager", "default", "Hash_D1622917F6DD215F"),
        rotation_time = Collections.float(p2, "physics_handplantmanager", "default", "Hash_D595A32C5F02178F"),
        committed_time = Collections.float(p2, "physics_handplantmanager", "default", "Hash_B5EC5A0941B407A4"),
        minimum_out_speed = Collections.float(p2, "physics_handplantmanager", "default", "Hash_49C91803479B9BED"),
        hand_approach = Collections.float(p2, "physics_handplantmanager", "default", "Hash_7C8B87F7435221C4"),
        direction_frames = rt.to_i32(Collections.words(p2, "physics_handplantmanager", "default", "Hash_DDE5BFBCB6A1AFD5", 1)[1]),
        apex_radius = Collections.float(p2, "physics_handplantmanager", "default", "Hash_A046D0516C0BD62B"),
        apex_angle = Collections.float(p2, "physics_handplantmanager", "default", "Hash_90CDD541098AB4B5"),
        animation = {
            Collections.float(p2, "anim_handplant", "default", "Hash_B9012B86EB5258FE"),
            Collections.float(p2, "anim_handplant", "default", "Hash_512342FB1D4A7D57"),
            Collections.float(p2, "anim_handplant", "default", "Hash_673F3B1BD056C39E")
        },
        truck_distance = DeckCenterToTruck
    }
end

return t1
