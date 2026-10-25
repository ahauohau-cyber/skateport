-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local v1 = require(sim.import)("skate_core/player/offboard/air_launch")
local t1 = {
    LaunchInput = {},
    Owner = {}
}

function t1.Owner.prepare_air(p2, p3) -- line: 32
    -- upvalues: rt (copy), v1 (copy)
    if p2.result == nil then
        error("Ground Sync requires completed Ground job", 0)
    end

    local v2 = rt.copy(p2.result)
    local processed = p3.processed
    local flags_176 = p2.contact.flags_176
    local v3 = bit32.band(flags_176, 1) == 0 and p3.elapsed_2664 > 0.05000000074505806 or v2.alternate
    local v4
    local v5 = v3

    if bit32.band(flags_176, 8) == 0 then
        if bit32.band(processed.flags_2480, 131456) == 0 and not p2.ground.flags_144_to_150[7] then
            v4 = v3 or bit32.band(processed.flags_2476, 524288) ~= 0
            v5 = v4
        end
    end

    p2.ground.flags_144_to_150[3] = v5

    if not v5 then
        return nil
    end

    local v6 = v1.Packet.initialized(0)

    v1.produce(v6, p2.controller.state, p2.controller.settings.movement_velocity.turn_vs_speed, rt.copy(p2.air_launch), processed, false)

    local animation_frame = v2.animation_frame
    local v7 = rt.copy(p3.skeleton_point_10960)

    v6.position_32 = {
        animation_frame[3][1] * v7[3] + (animation_frame[2][1] * v7[2] + (animation_frame[1][1] * v7[1] + animation_frame[4][1])),
        animation_frame[3][2] * v7[3] + (animation_frame[2][2] * v7[2] + (animation_frame[1][2] * v7[1] + animation_frame[4][2])),
        animation_frame[3][3] * v7[3] + (animation_frame[2][3] * v7[2] + (animation_frame[1][3] * v7[1] + animation_frame[4][3])),
        animation_frame[3][4] * v7[3] + (animation_frame[2][4] * v7[2] + (animation_frame[1][4] * v7[1] + animation_frame[4][4]))
    }

    local v8 = v6.position_32[4]

    if v8 ~= v8 or v8 == 1e999 or v8 == (-1e999) then
        v6.position_32[4] = 0
    end

    return v6
end

return t1
