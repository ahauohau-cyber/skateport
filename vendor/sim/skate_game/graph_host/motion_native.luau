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
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v2 = import("skate_core/riding/ground_correction_math")
local v3

local function motion_channels() -- line: 24
    -- upvalues: import (copy), v3 (ref)
    local v4 = v3

    if v4 == nil then
        v4 = import("skate_game/graph_host/motion_channels")
        v3 = v4
    end

    return v4
end

local v5

local function motion_scoring_trick() -- line: 33
    -- upvalues: import (copy), v5 (ref)
    local v6 = v5

    if v6 == nil then
        v6 = import("skate_game/graph_host/motion_scoring_trick")
        v5 = v6
    end

    return v6
end

local t1 = {
    Physical = {},
    GesturePhysical = {},
    Operation = {}
}

function t1.Operation.parse(p2) -- line: 63
    -- upvalues: v1 (copy), Attributes (copy)
    local name = Attributes.text(p2, "name")

    if name == nil then
        name = ""
    end

    if name == "StoreLandingData" then
        return {
            tag = "StoreLandingData"
        }
    end

    if name == "EndShimmy" then
        buffer.writeu32(v1, 0, (Attributes.float_bits(p2, "blendtime", 1045220557)))

        return {
            tag = "EndShimmy",
            (buffer.readf32(v1, 0))
        }
    end

    if name ~= "SetScoreAugmentation" then
        return nil
    end

    local function decode(p3) -- line: 74
        local t3 = {
            "FSPowerslide",
            "BSPowerslide",
            "FSRevert",
            "BSRevert",
            "NoseManual",
            "TailManual",
            "Wipeout",
            "Landing",
            "RideIdle",
            "Switching"
        }

        for i = 0, #t3 - 1 do
            if t3[i + 1] == p3 then
                return i
            end
        end

        error("Unknown authored score augmentation " .. p3, 0)
    end

    local augment = Attributes.text(p2, "augment")

    if augment == nil then
        augment = ""
    end

    local v8 = decode(augment)
    local mirrorAugment = Attributes.text(p2, "mirrorAugment")
    local v9

    if mirrorAugment == "Switching" then
        error("Native mirrorAugment=Switching has no initialized mirrored value", 0)
    else
        v9 = if mirrorAugment ~= nil then decode(mirrorAugment) else v8
    end

    return {
        tag = "Score",
        regular = v8,
        mirrored = v9
    }
end

t1.ScorePacket = {}

function t1.ScorePacket.default() -- line: 126
    -- upvalues: import (copy), v5 (ref)
    local t4 = {
        handplant = nil,
        grab = nil,
        name = nil,
        flags = 0
    }
    local v10 = v5

    if v10 == nil then
        v10 = import("skate_game/graph_host/motion_scoring_trick")
        v5 = v10
    end

    t4.trick_names = v10.Names.default()

    return t4
end

function t1.ScorePacket.set(p4, p5) -- line: 137
    local n1 = 20

    if p5 == 0 then
        n1 = 31
    elseif p5 == 1 then
        n1 = 30
    elseif p5 == 2 then
        n1 = 29
    elseif p5 == 3 then
        n1 = 28
    elseif p5 == 4 then
        n1 = 27
    elseif p5 == 5 then
        n1 = 26
    elseif p5 == 6 then
        n1 = 23
    elseif p5 == 7 then
        n1 = 21
    elseif p5 == 8 then
        n1 = 22
    elseif p5 ~= 9 then
        return
    end

    p4.flags = bit32.bor(p4.flags, (bit32.lshift(1, n1)))

    if p5 ~= 2 and p5 ~= 3 then
        p4.name = p5
    end
end

t1.LandingData = {}

function t1.LandingData.default() -- line: 172
    return {
        previous_velocity = 0,
        was_air = false
    }
end

function t1.LandingData.update(p6, p7, p8, p9) -- line: 177
    -- upvalues: v2 (copy)
    local v12 = p7 == 2

    if not p6.was_air and v12 then
        p9.last_good_landing_velocity = 0
    end

    p6.was_air = v12

    local v13 = v2.dot_product(p8.centre_of_mass_velocity, p8.system_up)

    if v13 < 0 and v13 < p6.previous_velocity then
        p9.last_good_landing_velocity = math.abs(v13)
    end

    p6.previous_velocity = v13
end

function t1.end_shimmy(p10, p11) -- line: 191
    -- upvalues: import (copy), v3 (ref)
    local v14 = v3

    if v14 == nil then
        v14 = import("skate_game/graph_host/motion_channels")
        v3 = v14
    end

    local MotionChannels = v14.MotionChannels

    for _, v15 in { "SKCH_2H_SHIMMY_LEFT_CHANNEL", "SKCH_2H_SHIMMY_RIGHT_CHANNEL" } do
        MotionChannels.end_with(p10.channels, v15, p11, false)
    end
end

return t1
