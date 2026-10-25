-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/air_launch")
local Packet = v1.Packet
local BipedCadence = import("skate_core/player/offboard/cadence").BipedCadence
local t1 = {}

local function vec_eq(p1, p2) -- line: 26
    if p1[1] == p2[1] and p1[2] == p2[2] and p1[3] == p2[3] then
        return p1[4] == p2[4]
    end

    return false
end

t1.Input = {}

function t1.Input.eq(p3, p4) -- line: 57
    -- upvalues: v1 (copy)
    for _, v2 in { "position_592", "velocity_608", "up_544", "forward_224", "board_position_112", "velocity_912" } do
        local v3 = p3[v2]
        local v4 = p4[v2]

        if v3[1] ~= v4[1] or v3[2] ~= v4[2] or v3[3] ~= v4[3] or v3[4] ~= v4[4] then
            return false
        end
    end

    local departure_geometry = p3.departure_geometry
    local departure_geometry2 = p4.departure_geometry

    if departure_geometry == nil ~= (departure_geometry2 == nil) or departure_geometry ~= nil and not v1.DepartureGeometry.eq(departure_geometry, departure_geometry2) then
        return false
    end

    if p3.flags_2472 == p4.flags_2472 and p3.flags_2476 == p4.flags_2476 and p3.flags_2480 == p4.flags_2480 and p3.previous_state_2504 == p4.previous_state_2504 and p3.current_state_2508 == p4.current_state_2508 and p3.current_category_2512 == p4.current_category_2512 and p3.previous_category_2516 == p4.previous_category_2516 and p3.raw_x_2692 == p4.raw_x_2692 and p3.raw_z_2688 == p4.raw_z_2688 then
        return p3.current == p4.current
    end

    return false
end

t1.Output = {}

function t1.Output.eq(p5, p6) -- line: 95
    -- upvalues: Packet (copy)
    local v5 = Packet.eq(p5.packet, p6.packet)

    if not v5 then
        return v5
    end

    local position_288 = p5.position_288
    local position_288_2 = p6.position_288
    local v6 = position_288[1] == position_288_2[1] and position_288[2] == position_288_2[2] and position_288[3] == position_288_2[3] and position_288[4] == position_288_2[4]

    if not v6 then
        return v6
    end

    local velocity_304 = p5.velocity_304
    local velocity_304_2 = p6.velocity_304
    local v7 = velocity_304[1] == velocity_304_2[1] and velocity_304[2] == velocity_304_2[2] and velocity_304[3] == velocity_304_2[3] and velocity_304[4] == velocity_304_2[4]

    if not v7 then
        return v7
    end

    if p5.phase_444 == p6.phase_444 and p5.phase_counter_448 == p6.phase_counter_448 and p5.update_count_452 == p6.update_count_452 and p5.landed_404 == p6.landed_404 then
        return p5.wipeout_547 == p6.wipeout_547
    end

    return false
end

t1.State = {}

function t1.State.default() -- line: 120
    -- upvalues: Packet (copy), BipedCadence (copy)
    return {
        phase_444 = 0,
        phase_counter_448 = 0,
        update_count_452 = 0,
        landed_404 = false,
        wipeout_547 = false,
        active = false,
        packet = Packet.initialized(0),
        cadence = BipedCadence.default(),
        position_288 = { 0, 0, 0, 0 },
        velocity_304 = { 0, 0, 0, 0 }
    }
end

function t1.State.enter(p7, p8, p9) -- line: 137
    -- upvalues: rt (copy), Packet (copy)
    p7.packet = Packet.initialized(p8)
    p7.position_288 = rt.copy(p9)
    p7.velocity_304 = { 0, 0, 0, 0 }
    p7.phase_444 = 0
    p7.phase_counter_448 = 0
    p7.update_count_452 = 0
    p7.landed_404 = false
    p7.wipeout_547 = false
    p7.active = true
end

function t1.State.exit(p10) -- line: 151
    p10.active = false
    p10.landed_404 = false
end

function t1.State.update(p11, p12, p13, p14, p15) -- line: 157
    -- upvalues: rt (copy), v1 (copy)
    if p11.active then
        local t2 = {
            board_position_112 = rt.copy(p12.board_position_112),
            forward_224 = rt.copy(p12.forward_224),
            up_544 = rt.copy(p12.up_544),
            position_592 = rt.copy(p12.position_592),
            velocity_608 = rt.copy(p12.velocity_608),
            velocity_912 = rt.copy(p12.velocity_912),
            departure_geometry = rt.copy(p12.departure_geometry),
            flags_2472 = p12.flags_2472,
            flags_2476 = p12.flags_2476,
            flags_2480 = p12.flags_2480,
            previous_state_2504 = p12.previous_state_2504,
            current_state_2508 = p12.current_state_2508,
            current_category_2512 = p12.current_category_2512,
            previous_category_2516 = p12.previous_category_2516,
            raw_x_2692 = p12.raw_x_2692,
            raw_z_2688 = p12.raw_z_2688
        }

        v1.produce(p11.packet, p13, p14, p15, t2, p12.current)
        p11.position_288 = rt.copy(p11.packet.position_32)
        p11.velocity_304 = rt.copy(p11.packet.velocity_0)
        p11.phase_counter_448 += 0.01666666753590107
        p11.update_count_452 = rt.wrapping_add_u32(p11.update_count_452, 1)
    end
end

function t1.State.output(p16) -- line: 186
    -- upvalues: rt (copy)
    return {
        packet = rt.copy(p16.packet),
        position_288 = rt.copy(p16.position_288),
        velocity_304 = rt.copy(p16.velocity_304),
        phase_444 = p16.phase_444,
        phase_counter_448 = p16.phase_counter_448,
        update_count_452 = p16.update_count_452,
        landed_404 = p16.landed_404,
        wipeout_547 = p16.wipeout_547
    }
end

return t1
