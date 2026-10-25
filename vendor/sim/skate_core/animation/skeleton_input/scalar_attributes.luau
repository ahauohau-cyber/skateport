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

local import = require(sim.import)
local v2 = import("skate_core/animation/skeleton_input/catalog")
local v3 = import("skate_core/animation/output/attributes")
local v4 = import("skate_core/animation/output/setup_physics")
local t1 = {
    ScalarAttributeInputs = {}
}

function t1.ScalarAttributeInputs.reset(p2, p3) -- line: 40
    return {
        flags2472 = 0,
        flags2476 = 0,
        flags2484 = 0,
        board_adjust = 0,
        balance = 0,
        spin = 0,
        body_spin = 0,
        brake = 0,
        turn = 0,
        turn_scale = 1,
        magnitude_scale = 1,
        animation_time = 0,
        animation_physics_blend_seconds = 0,
        cadence_end_percent = -1,
        raw_turn = 0,
        hard_turn = 0,
        slide = 0,
        flags2468 = bit32.bor(bit32.band(p2, 8), 8192),
        flags2488 = bit32.band(p3, 2097151),
        animation_end_com = { 0, 0, 0, 0 },
        animation_translation = { 0, 0, 0, 0 }
    }
end

t1.AnimationControlOutput = {}
t1.DispatchError = {}
t1.PacketDispatchError = {}

function t1.dispatch_supported_packet(p4, p5, p6) -- line: 87
    -- upvalues: v3 (copy), v4 (copy), t1 (copy)
    local v6 = v4.PhysicsPacketBinding.packet(p4)

    for v7, v8 in (v3.PacketAttributes.entries(v6.attributes)) do
        local v9 = v7 - 1
        local dispatch_attribute = t1.dispatch_attribute
        local ok, result = pcall(dispatch_attribute, v8, p5, p6)

        if not ok then
            error({
                attribute_index = v9,
                cause = result
            }, 0)
        end
    end
end

function t1.dispatch_attribute(p7, p8, p9) -- line: 100
    -- upvalues: rt (copy), v1 (copy), v2 (copy)
    if p7.kind ~= 0 then
        if p7.kind == 3 and bit32.band(p7.status, 12) ~= 0 then
            error({
                tag = "EventConsumerUnavailable",
                name = rt.copy(p7.name)
            }, 0)
        end
    else
        local v10 = v2.lookup(p7.name)

        if v10 == nil then
            return
        end

        local function scalar() -- line: 111
            -- upvalues: p7 (copy), v10 (copy), rt (copy), v1 (copy)
            local v11 = p7.payload[1][1]

            if v11 == nil then
                error({
                    tag = "UninitializedScalar",
                    attribute = rt.copy(v10)
                }, 0)
            end

            buffer.writeu32(v1, 0, v11)

            return (buffer.readf32(v1, 0))
        end

        local name = v10.name

        if name ~= "SlideBoard" and name ~= "SlideNose" and name ~= "SlideTail" and name ~= "Grind5050" and name ~= "Grind5_O" and name ~= "GrindNose" then
            if name == "GrabWorld" then
                p8.flags2476 = bit32.bor(p8.flags2476, 4194304)
            elseif name == "BoardAdjustLeft" then
                p8.board_adjust = 1
            elseif name == "BoardAdjustRight" then
                p8.board_adjust = 2
            elseif name == "BoardAdjustUp" then
                p8.board_adjust = 3
            elseif name == "BoardAdjustDown" then
                p8.board_adjust = 4
            elseif name == "GrindFacingForwards" then
                p9.flags = bit32.bor(p9.flags, 2147483648)
            elseif name == "GrindFacingBackwards" then
                p9.flags = bit32.band(p9.flags, 2147483647)
            elseif name == "NoInput" then
                p9.flags = bit32.bor(p9.flags, 1073741824)
                p8.flags2472 = bit32.bor(p8.flags2472, 8388608)
            elseif name == "ExitGrind" then
                p8.flags2476 = bit32.bor(p8.flags2476, 536870912)
            elseif name == "NewAutoPump" then
                p9.flags = bit32.bor(p9.flags, 536870912)
            else
                if name == "PlayerControlledPump" then
                    p8.flags2476 = bit32.bor(p8.flags2476, 2)

                    return
                end

                if name == "EnteringCoffin" then
                    p8.flags2472 = bit32.bor(p8.flags2472, 2)
                    p8.flags2476 = bit32.bor(p8.flags2476, 1073741824)

                    return
                end

                if name == "InCoffin" then
                    p8.flags2472 = bit32.bor(p8.flags2472, 1)
                    p8.flags2476 = bit32.bor(p8.flags2476, 1073741824)

                    return
                end

                if name == "LeavingCoffin" then
                    p8.flags2476 = bit32.bor(p8.flags2476, 3221225472)

                    return
                end

                if name == "PlayingLanding" then
                    p8.flags2476 = bit32.bor(p8.flags2476, 268435456)

                    return
                end

                if name == "Balance" then
                    p8.balance = -scalar()

                    return
                end

                if name == "Spin" then
                    p8.spin = -scalar()

                    return
                end

                if name == "KickTurn" then
                    p9.flags = bit32.bor(p9.flags, 268435456)

                    return
                end

                if name == "Anticipating" then
                    p9.flags = bit32.bor(p9.flags, 134217728)

                    return
                end

                if name == "BodySpin" then
                    p8.body_spin = -scalar()

                    return
                end

                if name == "ManualBrake" then
                    p8.flags2468 = bit32.bor(p8.flags2468, 536870912)

                    return
                end

                if name == "Brake" then
                    p8.brake = scalar()

                    return
                end

                if name == "Turn" then
                    p8.turn = -scalar()

                    return
                end

                if name == "IsStumbling" then
                    p8.flags2484 = bit32.bor(p8.flags2484, 1024)

                    return
                end

                if name == "IsWipeoutPushOffImpulse" then
                    p8.flags2484 = bit32.bor(p8.flags2484, 256)

                    return
                end

                if name == "IsWipeoutPushOff" then
                    p8.flags2484 = bit32.bor(p8.flags2484, 512)

                    return
                end

                if name == "IsMuteRFoot" then
                    p8.flags2484 = bit32.bor(p8.flags2484, 128)

                    return
                end

                if name == "IsMuteLFoot" then
                    p8.flags2484 = bit32.bor(p8.flags2484, 64)

                    return
                end

                if name == "IsForceDownRFoot" then
                    p8.flags2484 = bit32.bor(p8.flags2484, 8)

                    return
                end

                if name == "IsForceDownLFoot" then
                    p8.flags2484 = bit32.bor(p8.flags2484, 4)

                    return
                end

                if name == "TurnScale" then
                    p8.turn_scale = scalar()

                    return
                end

                if name == "MagScale" then
                    p8.magnitude_scale = scalar()

                    return
                end

                if name == "AnimEndCOMX" then
                    p8.animation_end_com[1] = scalar()

                    return
                end

                if name == "AnimEndCOMY" then
                    p8.animation_end_com[2] = scalar()

                    return
                end

                if name == "AnimEndCOMZ" then
                    p8.animation_end_com[3] = scalar()

                    return
                end

                if name == "AnimTransX" then
                    p8.animation_translation[1] = scalar()

                    return
                end

                if name == "AnimTransY" then
                    p8.animation_translation[2] = scalar()

                    return
                end

                if name == "AnimTransZ" then
                    p8.animation_translation[3] = scalar()

                    return
                end

                if name == "AnimTime" then
                    p8.animation_time = scalar()

                    return
                end

                if name == "AnimPhysBlendSec" then
                    p8.animation_physics_blend_seconds = scalar()

                    return
                end

                if name == "IsAnimInterpToEdge" then
                    p8.flags2488 = bit32.bor(p8.flags2488, 134217728)

                    return
                end

                if name == "CadenceEndPercent" then
                    p8.cadence_end_percent = scalar()

                    return
                end

                if name == "OB_Traj" then
                    p8.flags2476 = bit32.bor(p8.flags2476, 32768)

                    return
                end

                if name == "OB_Air" then
                    p8.flags2476 = bit32.bor(p8.flags2476, 128)

                    return
                end

                if name == "Carving" then
                    p8.flags2468 = bit32.bor(p8.flags2468, 2147483648)

                    return
                end

                if name == "RawTurn" then
                    p8.raw_turn = -scalar()

                    return
                end

                if name == "HardTurn" then
                    p8.hard_turn = -scalar()

                    return
                end

                if name == "Slide" then
                    p8.slide = -scalar()

                    return
                end

                if name == "FrontFlip" then
                    p8.flags2468 = bit32.bor(p8.flags2468, 128)

                    return
                end

                if name == "BackFlip" then
                    p8.flags2468 = bit32.bor(p8.flags2468, 64)

                    return
                end

                if name == "Grabbing" then
                    p8.flags2468 = bit32.bor(p8.flags2468, 32)

                    return
                end

                if name == "WantsLeftAirGrab" or name == "WantsRightAirGrab" then
                    local flags2468 = p8.flags2468

                    p8.flags2468 = bit32.bor(flags2468, 16)

                    return
                end

                if name == "FlipTrick" then
                    p8.flags2472 = bit32.bor(p8.flags2472, 4194304)
                elseif name == "WipeOutRecover" then
                    p8.flags2472 = bit32.bor(p8.flags2472, 1048576)
                elseif name == "ControlledWipeout" then
                    p8.flags2472 = bit32.bor(p8.flags2472, 524288)
                elseif name == "PushContact" then
                    p8.flags2488 = bit32.bor(p8.flags2488, 536870912)
                elseif name == "PushSpeed" then
                    p8.flags2488 = bit32.bor(p8.flags2488, 8388608)
                else
                    error({
                        tag = "KnownScalarUnavailable",
                        attribute = rt.copy(v10)
                    }, 0)
                end
            end
        else
            p9.grind_name = rt.copy(p7.name)
        end
    end
end

return t1
