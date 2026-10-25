-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    ExternalPhysicsInput = {}
}

function t1.ExternalPhysicsInput.eq(p1, p2) -- line: 20
    if p1.flags ~= p2.flags then
        return false
    end

    for i = 1, 10 do
        for j = 1, 4 do
            if p1.vectors[i][j] ~= p2.vectors[i][j] then
                return false
            end
        end
    end

    return true
end

function t1.ExternalPhysicsInput.copy_from(p3, p4) -- line: 36
    -- upvalues: rt (copy)
    p3.vectors = rt.copy(p4.vectors)
    p3.flags = bit32.bor(bit32.band(p3.flags, 33554431), (bit32.band(p4.flags, 4261412864)))
end

t1.ExternalReset = {}

function t1.ExternalReset.eq(p5, p6) -- line: 47
    if p5.byte64 ~= p6.byte64 then
        return false
    end

    for i = 1, 4 do
        for j = 1, 4 do
            if p5.transform[i][j] ~= p6.transform[i][j] then
                return false
            end
        end
    end

    return true
end

t1.ActorPacketFields = {}
t1.ActorPublicationState = {}
t1.PlayerPhysicsSettingsSource = {}
t1.ActorPublicationEnvironment = {}

function t1.publish(p7, p8, p9, p10, p11) -- line: 109
    -- upvalues: rt (copy), t1 (copy)
    p9.actor_flag_1904_bit23 = bit32.band(p7.flags1904, 8388608) ~= 0
    p9.actor_flag_1908_bit2 = bit32.band(p7.flags1908, 4) ~= 0
    p9.external_impulse_active = bit32.band(p7.flags1904, 1073741824) ~= 0
    p10.external_impulse = rt.copy(p7.external_impulse)
    t1.ExternalPhysicsInput.copy_from(p10.external_physics, p7.external_physics)
    p9.external_physics_input_active = bit32.band(p7.flags1904, 134217728) ~= 0

    local v3, v4

    if p7.external_controller_present then
        v4 = false
    elseif bit32.band(p7.flags1904, 67108864) == 0 then
        local v5 = p11.current_scene_mode(p11)

        v3 = v5 == 19 or v5 == 20
        v4 = v3
    else
        v4 = false
    end

    p8.flags = t1.replace_flag(p8.flags, 22, v4)
    p9.externally_controlled = p7.external_controller_present
    p10.external_reset = rt.copy(p7.external_reset)
    p10.actor_flag_1904_bit29 = bit32.band(p7.flags1904, 536870912) ~= 0
    p9.prevent_manual_respawn = bit32.band(p7.flags1904, 268435456) ~= 0
    p9.force_braking = bit32.band(p7.flags1904, 67108864) ~= 0
    p8.flags = t1.replace_flag(p8.flags, 24, bit32.band(p7.flags1904, 33554432) ~= 0)
    p7.flags1904 = bit32.band(p7.flags1904, 4261412863)
    p9.ignore_respawn_reset_button = p11.ignore_respawn_reset_button(p11)
    p7.flags1904 = bit32.band(p7.flags1904, 4026531839)

    local v6 = p11.capture_physics_settings(p11)

    if p11.actor_subobject56_slot16(p11, p7) ~= 0 then
        p9.truck_tightness = 0.699999988079071
        p9.wheel_hardness = 0.699999988079071
    else
        p9.truck_tightness = v6.truck_tightness(v6, p7.player_index)
        p9.wheel_hardness = v6.wheel_hardness(v6, p7.player_index)
    end

    p9.requested_physics_mode = v6.requested_physics_mode(v6, p7.player_index)
end

function t1.replace_flag(p12, p13, p14) -- line: 145
    return (bit32.bor(bit32.band(p12, (bit32.bnot((bit32.lshift(1, p13))))), (bit32.lshift(if p14 then 1 else 0, p13))))
end

return t1
