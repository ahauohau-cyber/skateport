-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local ProcessedStateInput = import("skate_core/player/selector/input").ProcessedStateInput
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local t1 = {
    StateSelector = {}
}

function t1.StateSelector.select_ground_family(p1, p2, p3, p4) -- line: 18
    -- upvalues: rt (copy), ProcessedStateInput (copy), PhysicalStateId (copy)
    local v1 = ProcessedStateInput.read(p3.processed)

    if p2 == PhysicalStateId.PhysicsGround then
        if not (not ProcessedStateInput.has_2480(v1, 4096) or ProcessedStateInput.has_2480(v1, 1024) and ProcessedStateInput.has_2480(v1, 512)) then
            return PhysicalStateId.LandingOnDeck
        end

        local v2 = ProcessedStateInput.has_2480(v1, 1073741824) and p3.skateboard_contact_count_869 <= 2

        if ProcessedStateInput.has_2476(v1, 1) and (v2 or p3.skateboard_contact_count_869 == 0) then
            return PhysicalStateId.HandPlant
        end

        if ProcessedStateInput.has_2476(v1, 32768) then
            return PhysicalStateId.BipedGround
        end

        if ProcessedStateInput.has_2476(v1, 128) then
            return PhysicalStateId.BipedAir
        end

        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if v1.field_2572 == 1 then
            return ProcessedStateInput.air_variant_from_2468(v1)
        end

        if v1.field_2744 ~= 0 then
            return PhysicalStateId.RevertGround
        end

        if p4.grind ~= nil then
            return p4.grind
        end

        if not p4.colliding and p4.off_ground and p1.teleport_countdown == 0 then
            return PhysicalStateId.PhysicsAir
        end

        if p4.skateboard_animated and p1.teleport_countdown == 0 then
            return PhysicalStateId.GroundAnimation
        end

        if ProcessedStateInput.has_2476(v1, 2097152) and ProcessedStateInput.has_2480(v1, 4194304) and p1.skitch_exit_countdown == 0 then
            return PhysicalStateId.Skitching
        end

        if v1.field_2732 == 0 then
            return p2
        end

        return PhysicalStateId.SlideGround
    end

    if p2 == PhysicalStateId.SlideGround then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if v1.field_2744 ~= 0 then
            return PhysicalStateId.RevertGround
        end

        if p4.grind ~= nil then
            return p4.grind
        end

        if not p4.colliding and p4.off_ground then
            return PhysicalStateId.PhysicsAir
        end

        if v1.field_2732 == 0 then
            return PhysicalStateId.PhysicsGround
        end

        return p2
    end

    if p2 == PhysicalStateId.RevertGround then
        if not p4.colliding and p4.off_ground then
            return PhysicalStateId.PhysicsAir
        end

        if not (ProcessedStateInput.has_2468(v1, 65536) or ProcessedStateInput.has_2472(v1, 131072)) then
            if ProcessedStateInput.has_2472(v1, 2097152) then
                if p4.wipeout then
                    return PhysicalStateId.WipeoutGround
                end

                return p2
            end

            p1.revert_exited_normally = true
        end

        return PhysicalStateId.PhysicsGround
    end

    if p2 == PhysicalStateId.GroundAnimation then
        if p4.wipeout then
            return PhysicalStateId.WipeoutGround
        end

        if ProcessedStateInput.has_2480(v1, 16384) then
            return PhysicalStateId.Boneless
        end

        if ProcessedStateInput.has_2476(v1, 32768) then
            return PhysicalStateId.BipedGround
        end

        if ProcessedStateInput.has_2476(v1, 128) then
            return PhysicalStateId.BipedAir
        end

        if v1.field_2572 == 1 then
            return ProcessedStateInput.air_variant_from_2468(v1)
        end

        if not p4.colliding and p4.off_ground then
            return PhysicalStateId.PhysicsAir
        end

        if p4.skateboard_animated then
            return p2
        end

        return PhysicalStateId.PhysicsGround
    end

    if p2 == PhysicalStateId.Skitching then
        if ProcessedStateInput.has_2476(v1, 2097152) then
            if p4.wipeout then
                return PhysicalStateId.WipeoutGround
            end

            if not p4.off_ground_skitching or p1.teleport_countdown ~= 0 then
                return p2
            end
        end

        return PhysicalStateId.PhysicsGround
    end

    if p2 == PhysicalStateId.FollowPath then
        if bit32.band(rt.to_u32(v1.field_1776), 33554432) == 0 then
            return p2
        end

        return PhysicalStateId.PhysicsGround
    end

    error("ground-family dispatch accepts only states 100..105", 0)
end

return t1
