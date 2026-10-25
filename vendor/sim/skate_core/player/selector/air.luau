-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local ProcessedStateInput = import("skate_core/player/selector/input").ProcessedStateInput
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local t1 = {
    STATE_SETTLE_SECONDS = 0.07999999821186066,
    KNOWN_AIR_COLLISION_GRACE_SECONDS = 0.03999999910593033,
    TRAJECTORY_WIPEOUT_SECONDS = 0.05000000074505806,
    TRAJECTORY_EXPIRED_SECONDS = -0.20000000298023224,
    StateSelector = {}
}

function t1.StateSelector.select_physics_air(p1, p2, p3, p4) -- line: 23
    -- upvalues: ProcessedStateInput (copy), PhysicalStateId (copy), t1 (copy)
    local v1 = ProcessedStateInput.read(p3.processed)

    if p4.wipeout then
        return PhysicalStateId.WipeoutGround
    end

    if ProcessedStateInput.has_2476(v1, 32768) then
        return PhysicalStateId.BipedGround
    end

    if ProcessedStateInput.has_2476(v1, 128) and not ProcessedStateInput.has_2484(v1, 16777216) then
        return PhysicalStateId.BipedAir
    end

    if p4.force_known_air then
        if p4.colliding or ProcessedStateInput.has_2468(v1, 32768) then
            return PhysicalStateId.WipeoutGround
        end
    elseif v1.state_timer_2664 > t1.STATE_SETTLE_SECONDS then
        if p4.colliding then
            if ProcessedStateInput.has_2472(v1, 4) then
                return PhysicalStateId.PhysicsAir
            end

            if p4.skateboard_animated then
                return PhysicalStateId.GroundAnimation
            end

            return PhysicalStateId.PhysicsGround
        end

        if p1.post_grind_jump_counter > 10 and p4.grind ~= nil then
            return p4.grind
        end
    end

    if ProcessedStateInput.has_2468(v1, 1024) then
        return PhysicalStateId.KnownAir
    end

    return p2
end

function t1.StateSelector.select_known_air(p5, p6, p7, p8) -- line: 70
    -- upvalues: ProcessedStateInput (copy), PhysicalStateId (copy), t1 (copy)
    local v2 = ProcessedStateInput.read(p7.processed)

    if ProcessedStateInput.has_2480(v2, 33554432) then
        return PhysicalStateId.FootPlant
    end

    if v2.trajectory_collision_time_2772 < t1.TRAJECTORY_WIPEOUT_SECONDS and (ProcessedStateInput.has_2476(v2, 128) or ProcessedStateInput.has_2476(v2, 32768)) then
        return PhysicalStateId.WipeoutGround
    end

    if ProcessedStateInput.has_2476(v2, 128) and not ProcessedStateInput.has_2484(v2, 16777216) then
        return PhysicalStateId.BipedAir
    end

    if ProcessedStateInput.has_2476(v2, 32768) then
        return PhysicalStateId.BipedGround
    end

    if not p8.wipeout then
        if p8.force_known_air then
            if p8.colliding or ProcessedStateInput.has_2468(v2, 32768) then
                return PhysicalStateId.WipeoutGround
            end

            return p6
        end

        if v2.state_timer_2664 > t1.STATE_SETTLE_SECONDS and p5.post_grind_jump_counter > 10 and p8.grind ~= nil then
            return p8.grind
        end

        if not p8.colliding or v2.state_timer_2664 < t1.KNOWN_AIR_COLLISION_GRACE_SECONDS then
            if v2.trajectory_collision_time_2772 < t1.TRAJECTORY_EXPIRED_SECONDS then
                if ProcessedStateInput.has_2476(v2, 67108864) then
                    return PhysicalStateId.KnownAir
                end
            else
                if not ProcessedStateInput.has_2468(v2, 32768) then
                    return p6
                end

                if ProcessedStateInput.has_2476(v2, 67108864) then
                    return PhysicalStateId.WipeoutGround
                end
            end

            return PhysicalStateId.PhysicsAir
        end

        if ProcessedStateInput.has_2472(v2, 4) then
            return PhysicalStateId.PhysicsAir
        end

        if not ProcessedStateInput.has_2480(v2, 262144) and not ProcessedStateInput.has_2480(v2, 131072) and not ProcessedStateInput.has_2480(v2, 65536) then
            if ProcessedStateInput.has_2472(v2, 32768) or ProcessedStateInput.has_2472(v2, 16384) then
                return PhysicalStateId.GroundAnimation
            end

            return PhysicalStateId.PhysicsGround
        end
    end

    return PhysicalStateId.WipeoutGround
end

function t1.StateSelector.select_grind(_, _, p11, p12) -- line: 138
    -- upvalues: ProcessedStateInput (copy), PhysicalStateId (copy)
    local v3 = ProcessedStateInput.read(p11.processed)

    if p12.wipeout then
        return PhysicalStateId.WipeoutGround
    end

    if ProcessedStateInput.has_2484(v3, 1048576) then
        return PhysicalStateId.PhysicsAirSecondary
    end

    if ProcessedStateInput.has_2476(v3, 128) then
        return PhysicalStateId.BipedAir
    end

    if ProcessedStateInput.has_2476(v3, 32768) then
        return PhysicalStateId.BipedGround
    end

    if ProcessedStateInput.has_2468(v3, 256) then
        return ProcessedStateInput.air_variant_from_2468(v3)
    end

    if p12.grind == nil then
        return PhysicalStateId.Nonspecific
    end

    return p12.grind
end

return t1
