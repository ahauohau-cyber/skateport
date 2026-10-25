-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/input/animation_packet")
local ExternalPhysicsInput = import("skate_core/animation/output/actor_packet").ExternalPhysicsInput
local v9 = import("skate_core/player/input_phase/types")
local _ = v9.assign_into
local _ = rt.copy
local v10 = false
local t1 = {}

function t1.set_reference(p4) -- line: 46
    -- upvalues: v10 (ref)
    v10 = p4
end

local copy_into = v9.copy_into

t1.copy_into = copy_into

local v11 = table.freeze({ 0, 0, 0, 0 })

function t1.publish_player_flags(p5, p6) -- line: 60
    -- upvalues: t1 (copy), v10 (ref), copy_into (copy), v11 (copy)
    if v10 then
        return t1.publish_player_flags_reference(p5, p6)
    end

    p6.flags_2472 = t1.transfer_bit(p6.flags_2472, 14, p5.flags_1296, 27)
    p6.flags_2488 = t1.transfer_bit(p6.flags_2488, 26, p5.flags_1296, 20)
    copy_into(p6.vectors_880_896_912_928_944, 4, p5.queued_vector_1280)
    p6.flags_2488 = t1.transfer_bit(p6.flags_2488, 22, p5.flags_1296, 18)
    p6.flags_2480 = t1.transfer_bit(p6.flags_2480, 16, p5.flags_1296, 17)
    copy_into(p5, "queued_vector_1280", v11)
    p5.flags_1296 = bit32.band(p5.flags_1296, 4293918719)
end

function t1.publish_player_flags_reference(p7, p8) -- line: 74
    -- upvalues: rt (copy), t1 (copy)
    p8.flags_2472 = t1.transfer_bit(p8.flags_2472, 14, p7.flags_1296, 27)
    p8.flags_2488 = t1.transfer_bit(p8.flags_2488, 26, p7.flags_1296, 20)
    p8.vectors_880_896_912_928_944[4] = rt.copy(p7.queued_vector_1280)
    p8.flags_2488 = t1.transfer_bit(p8.flags_2488, 22, p7.flags_1296, 18)
    p8.flags_2480 = t1.transfer_bit(p8.flags_2480, 16, p7.flags_1296, 17)
    p7.queued_vector_1280 = table.create(4, 0)
    p7.flags_1296 = bit32.band(p7.flags_1296, 4293918719)
end

function t1.publish_force_braking(p9, p10, p11, p12) -- line: 84
    -- upvalues: rt (copy), t1 (copy)
    local v12 = p11.force_braking_10796 ~= 0 and rt.to_i32(p9.state_count_1312) > 5 and p10.skateboard.scalar_160 < 0.10000000149011612 and p10.state.state_16 == 100 and rt.to_i32(p10.collision.wheel_count_0) > 2

    p12.flags_2476 = t1.replace_bool(p12.flags_2476, 24, v12)
end

function t1.publish_collision_prefix(p13, p14, p15) -- line: 93
    -- upvalues: t1 (copy), v10 (ref), copy_into (copy)
    if v10 then
        return t1.publish_collision_prefix_reference(p13, p14, p15)
    end

    p15.flags_2484 = t1.replace_byte(p15.flags_2484, 26, p14.collision.flag_215)
    p15.flags_2484 = t1.replace_byte(p15.flags_2484, 22, p14.collision.flag_216)
    copy_into(p15.vectors_720_784_800_816_832_864, 6, p13.manager_1852_vector_176)
end

function t1.publish_collision_prefix_reference(p16, p17, p18) -- line: 103
    -- upvalues: rt (copy), t1 (copy)
    p18.flags_2484 = t1.replace_byte(p18.flags_2484, 26, p17.collision.flag_215)
    p18.flags_2484 = t1.replace_byte(p18.flags_2484, 22, p17.collision.flag_216)
    p18.vectors_720_784_800_816_832_864[6] = rt.copy(p16.manager_1852_vector_176)
end

function t1.publish_animation_packet(p19, p20) -- line: 114
    -- upvalues: v8 (copy), t1 (copy), v10 (ref), copy_into (copy)
    if v10 then
        return t1.publish_animation_packet_reference(p19, p20)
    end

    local publication = p19.publication
    local replace_bit = v8.replace_bit
    local v13 = replace_bit(p20.flags_2468, 20, publication.stance_byte)
    local timestep, scalar_10388 = publication.timestep, publication.scalar_10388
    local v14 = replace_bit(replace_bit(v13, 3, publication.flags_10375_10496_10784[1]), 2, publication.flags_10375_10496_10784[2])
    local vector_10480 = publication.vector_10480
    local v15 = replace_bit(v14, 1, publication.flags_10375_10496_10784[3])
    local matrix_10704, byte_10768, truck_tightness, scalar_10792 = publication.matrix_10704, publication.byte_10768, publication.truck_tightness, publication.scalar_10792
    local v16 = replace_bit(p20.flags_2476, 20, publication.flag_10371)

    p20.flags_2468 = v15
    p20.flags_2476 = v16
    p20.timestep_2604 = timestep
    p20.scalar_2668 = scalar_10388
    copy_into(p20, "vector_1520", vector_10480)
    copy_into(p20, "matrix_1536", matrix_10704)
    p20.byte_1600 = byte_10768
    p20.truck_tightness_2760 = truck_tightness
    p20.scalar_2764 = scalar_10792
end

function t1.publish_animation_packet_reference(p21, p22) -- line: 145
    -- upvalues: rt (copy), v8 (copy)
    local t2 = {
        flags_2468 = p22.flags_2468,
        flags_2476 = p22.flags_2476,
        timestep = p22.timestep_2604,
        scalar_2668 = p22.scalar_2668,
        vector_1520 = rt.copy(p22.vector_1520),
        matrix_1536 = rt.copy(p22.matrix_1536),
        byte_1600 = p22.byte_1600,
        truck_tightness = p22.truck_tightness_2760,
        scalar_2764 = p22.scalar_2764
    }

    v8.publish(p21.publication, t2)
    p22.flags_2468 = t2.flags_2468
    p22.flags_2476 = t2.flags_2476
    p22.timestep_2604 = t2.timestep
    p22.scalar_2668 = t2.scalar_2668
    p22.vector_1520 = rt.copy(t2.vector_1520)
    p22.matrix_1536 = rt.copy(t2.matrix_1536)
    p22.byte_1600 = t2.byte_1600
    p22.truck_tightness_2760 = t2.truck_tightness
    p22.scalar_2764 = t2.scalar_2764
end

function t1.select_surface(p23, p24, p25, p26) -- line: 171
    -- upvalues: t1 (copy)
    local state_variant_10928 = p24.state_variant_10928
    local v17 = p23.state_variants_1408[state_variant_10928 + 1]

    if v17 == nil then
        p26.state_variant_index_2528 = state_variant_10928
        error(state_variant_10928, 0)
    end

    p26.state_variant_ref_2548 = {
        base = "Player",
        offset = 1408 + 16 * state_variant_10928
    }
    p26.state_variant_index_2528 = state_variant_10928

    local v18 = if v17.surface_override_enabled_60 == 0 then p25
        elseif p25 >= 1 and p25 <= 3 then 1
        elseif p25 == 5 then 3
        elseif p25 == 13 then 2
        else p25

    t1.select_surface_mode(v18, p26)
end

function t1.select_surface_mode(p27, p28) -- line: 201
    local v19 = if p27 >= 1 and p27 <= 5 then p27 elseif p27 == 6 then 3 else 1
    local v20, v21

    if v19 == 1 then
        v20 = 24
        v21 = 104
    elseif v19 == 2 then
        v20 = 40
        v21 = 116
    elseif v19 == 3 then
        v20 = 56
        v21 = 128
    elseif v19 == 4 then
        v20 = 72
        v21 = 140
    elseif v19 == 5 then
        v20 = 88
        v21 = 152
    else
        error("surface mode normalization is exhaustive", 0)
    end

    p28.surface_mode_2540 = v19
    p28.surface_primary_ref_2544 = {
        base = "SurfaceSelector",
        offset = v20
    }
    p28.surface_secondary_ref_2552 = {
        base = "SurfaceSelector",
        offset = v21
    }
end

function t1.publish_external_physics(p29, p30, p31) -- line: 235
    -- upvalues: rt (copy), ExternalPhysicsInput (copy), t1 (copy)
    if p30.use_external_physics_10688 ~= 0 then
        p31.flags_2472 = bit32.bor(p31.flags_2472, 536870912)
        ExternalPhysicsInput.copy_from(p31.external_physics_1616, p30.external_physics_10512)

        if bit32.band(p31.external_physics_1616.flags, 67108864) == 0 then
            for i = 5, 8 do
                p31.external_physics_1616.vectors[i + 1] = rt.copy(p29.external_physics_cache_1008.vectors[i + 1])
            end

            p31.external_physics_1616.vectors[10] = rt.copy(p29.external_physics_cache_1008.vectors[10])
            p31.external_physics_1616.flags = t1.transfer_bit(p31.external_physics_1616.flags, 27, p29.external_physics_cache_1008.flags, 27)
            p31.external_physics_1616.flags = bit32.bor(p31.external_physics_1616.flags, 67108864)
        else
            ExternalPhysicsInput.copy_from(p29.external_physics_cache_1008, p30.external_physics_10512)
        end
    end

    p31.flags_2472 = t1.replace_byte(p31.flags_2472, 28, p30.external_physics_flag_10689)
end

function t1.publish_state_prefix(p32, p33, p34, p35, p36) -- line: 255
    -- upvalues: rt (copy), t1 (copy), v10 (ref), copy_into (copy)
    if v10 then
        return t1.publish_state_prefix_reference(p32, p33, p34, p35, p36)
    end

    p36.flags_2468 = t1.transfer_bit(p36.flags_2468, 13, p32.flags_1296, 31)

    local v22 = bit32.band(p36.flags_2468, 4) ~= 0 or p36.probe_1792.byte_104 ~= 0

    p36.flags_2468 = t1.replace_bool(p36.flags_2468, 18, v22)

    if bit32.band(p32.flags_1296, 536870912) == 0 then
        p32.frames_since_teleport_1328 = rt.wrapping_add_u32(p32.frames_since_teleport_1328, 1)
    else
        p32.frames_since_teleport_1328 = 0
    end

    p36.frames_since_teleport_2584 = p32.frames_since_teleport_1328
    p32.flags_1296 = bit32.band(p32.flags_1296, 3758096383)
    p36.state_count_2564 = p32.state_count_1312
    p36.state_timer_2664 = p32.state_timer_1344
    p36.update_count_2568 = p32.update_count_1316
    p36.flags_2472 = t1.replace_byte(p36.flags_2472, 12, p34.flag_10373)
    p36.flags_2468 = t1.replace_byte(p36.flags_2468, 0, p34.flag_10786)
    p36.flags_2472 = t1.replace_byte(p36.flags_2472, 31, p34.flag_10787)
    p36.state_2508 = p35
    p36.state_2504 = p35
    p36.category_2512 = p33.state.category_12
    p36.flags_2472 = t1.replace_byte(p36.flags_2472, 30, p33.state.flag_61)
    p36.flags_2472 = t1.replace_byte(p36.flags_2472, 18, p33.state.flag_69)
    p36.flags_2480 = t1.replace_byte(p36.flags_2480, 31, p33.state.flag_74)
    copy_into(p36, "grind_words_2532_2536", p33.grinds.words_136_140)
    p36.category_2516 = p33.state.category_12
    p36.player_state_value_2520 = p32.state_value_1336
end

function t1.publish_state_prefix_reference(p37, p38, p39, p40, p41) -- line: 288
    -- upvalues: rt (copy), t1 (copy)
    p41.flags_2468 = t1.transfer_bit(p41.flags_2468, 13, p37.flags_1296, 31)

    local v23 = bit32.band(p41.flags_2468, 4) ~= 0 or p41.probe_1792.byte_104 ~= 0

    p41.flags_2468 = t1.replace_bool(p41.flags_2468, 18, v23)

    if bit32.band(p37.flags_1296, 536870912) == 0 then
        p37.frames_since_teleport_1328 = rt.wrapping_add_u32(p37.frames_since_teleport_1328, 1)
    else
        p37.frames_since_teleport_1328 = 0
    end

    p41.frames_since_teleport_2584 = p37.frames_since_teleport_1328
    p37.flags_1296 = bit32.band(p37.flags_1296, 3758096383)
    p41.state_count_2564 = p37.state_count_1312
    p41.state_timer_2664 = p37.state_timer_1344
    p41.update_count_2568 = p37.update_count_1316
    p41.flags_2472 = t1.replace_byte(p41.flags_2472, 12, p39.flag_10373)
    p41.flags_2468 = t1.replace_byte(p41.flags_2468, 0, p39.flag_10786)
    p41.flags_2472 = t1.replace_byte(p41.flags_2472, 31, p39.flag_10787)
    p41.state_2508 = p40
    p41.state_2504 = p40
    p41.category_2512 = p38.state.category_12
    p41.flags_2472 = t1.replace_byte(p41.flags_2472, 30, p38.state.flag_61)
    p41.flags_2472 = t1.replace_byte(p41.flags_2472, 18, p38.state.flag_69)
    p41.flags_2480 = t1.replace_byte(p41.flags_2480, 31, p38.state.flag_74)
    p41.grind_words_2532_2536 = rt.copy(p38.grinds.words_136_140)
    p41.category_2516 = p38.state.category_12
    p41.player_state_value_2520 = p37.state_value_1336
end

function t1.publish_physical_outputs(p42, p43, p44) -- line: 317
    -- upvalues: t1 (copy), v10 (ref), copy_into (copy)
    if v10 then
        return t1.publish_physical_outputs_reference(p42, p43, p44)
    end

    copy_into(p44.vectors_400_416, 1, p42.skateboard.vector_80)
    copy_into(p44.vectors_400_416, 2, p42.skateboard.vector_96)
    p44.scalar_2736 = p42.skateboard.scalar_172
    p44.scalar_2612 = p42.skateboard.scalar_168
    p44.scalar_2656 = p42.skateboard.scalar_164
    p44.scalar_2652 = p42.skateboard.scalar_160
    copy_into(p44.vectors_720_784_800_816_832_864, 1, p42.skateboard.vector_64)
    copy_into(p44.vectors_720_784_800_816_832_864, 2, p42.skateboard.vector_128)
    copy_into(p44.vectors_720_784_800_816_832_864, 3, p42.skateboard.vector_144)
    copy_into(p44.vectors_624_640_656_672, 1, p43.vector_10816)
    copy_into(p44.vectors_624_640_656_672, 2, p43.vector_10832)
    p44.flags_2476 = t1.transfer_bit(p44.flags_2476, 6, p43.flags_10932, 31)
    p44.flags_2476 = t1.transfer_bit(p44.flags_2476, 5, p43.flags_10932, 30)
    p44.flags_2476 = t1.transfer_bit(p44.flags_2476, 4, p43.flags_10932, 29)
    p44.scalar_2696 = p43.scalar_10912
    copy_into(p44.vectors_624_640_656_672, 3, p43.vector_10848)
    p44.scalar_2700 = p43.scalar_10916
    copy_into(p44.vectors_624_640_656_672, 4, p43.vector_10864)
    p44.flags_2480 = t1.replace_byte(p44.flags_2480, 0, p43.flag_10369)
    copy_into(p44.vectors_880_896_912_928_944, 1, p43.vector_10880)
    copy_into(p44.vectors_880_896_912_928_944, 2, p43.vector_10896)
    p44.flags_2488 = t1.transfer_bit(p44.flags_2488, 24, p43.flags_10932, 22)
    copy_into(p44.vectors_544_560_592_608, 3, p42.reckoning.vector_64)
    copy_into(p44.vectors_880_896_912_928_944, 5, p42.reckoning.vector_144)
    p44.flags_2488 = t1.replace_byte(p44.flags_2488, 21, p42.reckoning.flag_164)

    if p42.air.use_air_reckoning_452 == 0 then
        copy_into(p44.vectors_544_560_592_608, 4, p42.reckoning.vector_16)
    else
        copy_into(p44.vectors_544_560_592_608, 4, p42.air.vector_160)
    end

    copy_into(p44.vectors_544_560_592_608, 1, p42.reckoning.vector_96)
    copy_into(p44.vectors_544_560_592_608, 2, p42.board_reckoning_side_176)
    copy_into(p44.vectors_464_480_496_512_528, 1, p42.ground.vector_96)
    copy_into(p44.vectors_464_480_496_512_528, 5, p42.ground.vector_64)
    copy_into(p44.vectors_720_784_800_816_832_864, 5, p42.ground.vector_128)
    p44.flags_2476 = t1.replace_byte(p44.flags_2476, 27, p42.ground.flag_317)
    p44.flags_2476 = t1.replace_byte(p44.flags_2476, 23, p42.ground.flag_318)
    p44.air_scalar_2772 = p42.air.scalar_184
    p44.flags_2476 = t1.replace_byte(p44.flags_2476, 26, p42.air.flag_441)
    p44.flags_2476 = t1.replace_byte(p44.flags_2476, 0, p42.air.flag_446)
    p44.flags_2480 = t1.replace_byte(p44.flags_2480, 25, p42.air.flag_447)
    p44.flags_2480 = t1.replace_byte(p44.flags_2480, 24, p42.air.flag_448)
    p44.flags_2480 = t1.transfer_bit(p44.flags_2480, 30, p42.component_1832_word_1876, 28)
    p44.flags_2468 = t1.replace_byte(p44.flags_2468, 9, p42.grinds.flag_318)
    p44.flags_2468 = t1.replace_byte(p44.flags_2468, 8, p42.grinds.flag_322)
    p44.flags_2468 = t1.replace_byte(p44.flags_2468, 15, p42.collision.flag_3478)
    p44.flags_2468 = t1.replace_byte(p44.flags_2468, 16, p42.collision.flag_3475)
    p44.flags_2468 = t1.replace_byte(p44.flags_2468, 17, p42.collision.flag_3472)
    p44.wheel_count_2556 = p42.collision.wheel_count_0
    p44.flags_2468 = t1.replace_byte(p44.flags_2468, 14, p42.collision.flag_3477)
    p44.collision_scalar_2924 = p42.collision.scalar_28
    p44.flags_2488 = t1.replace_byte(p44.flags_2488, 30, p42.collision.flag_3481)
    p44.flags_2472 = t1.replace_byte(p44.flags_2472, 11, p42.physics.flag_32)
    copy_into(p44.vectors_720_784_800_816_832_864, 4, p42.physics.vector_16)
    p44.flags_2472 = t1.replace_byte(p44.flags_2472, 9, p42.skeleton.flag_597)
    p44.flags_2480 = t1.replace_byte(p44.flags_2480, 10, p42.skeleton.flag_600)
    p44.flags_2480 = t1.replace_byte(p44.flags_2480, 9, p42.skeleton.flag_601)
    p44.filtered_state_2524 = p42.filtered_state_0
    p44.flags_2476 = t1.replace_byte(p44.flags_2476, 21, p42.off_board.flag_304)
    p44.flags_2476 = t1.replace_bool(p44.flags_2476, 17, p42.off_board.scalar_32 <= 0)
    p44.flags_2480 = t1.replace_byte(p44.flags_2480, 15, p42.off_board.flag_311)
    p44.flags_2476 = t1.replace_byte(p44.flags_2476, 16, p42.off_board.flag_315)
    p44.flags_2476 = t1.replace_byte(p44.flags_2476, 8, p42.off_board.flag_316)
    p44.off_board_scalar_2832 = p42.off_board.scalar_32
    p44.flags_2480 = t1.replace_byte(p44.flags_2480, 1, p42.off_board.flag_318)
    p44.flags_2484 = t1.replace_byte(p44.flags_2484, 23, p42.off_board.flag_314)
    copy_into(p44.vectors_880_896_912_928_944, 3, p42.off_board.vector_64)
    p44.flags_2484 = t1.replace_byte(p44.flags_2484, 16, p42.off_board.flag_328)
    t1.publish_wheel_contacts(p42, p44)
end

function t1.publish_physical_outputs_reference(p45, p46, p47) -- line: 398
    -- upvalues: rt (copy), t1 (copy)
    p47.vectors_400_416[1] = rt.copy(p45.skateboard.vector_80)
    p47.vectors_400_416[2] = rt.copy(p45.skateboard.vector_96)
    p47.scalar_2736 = p45.skateboard.scalar_172
    p47.scalar_2612 = p45.skateboard.scalar_168
    p47.scalar_2656 = p45.skateboard.scalar_164
    p47.scalar_2652 = p45.skateboard.scalar_160
    p47.vectors_720_784_800_816_832_864[1] = rt.copy(p45.skateboard.vector_64)
    p47.vectors_720_784_800_816_832_864[2] = rt.copy(p45.skateboard.vector_128)
    p47.vectors_720_784_800_816_832_864[3] = rt.copy(p45.skateboard.vector_144)
    p47.vectors_624_640_656_672[1] = rt.copy(p46.vector_10816)
    p47.vectors_624_640_656_672[2] = rt.copy(p46.vector_10832)
    p47.flags_2476 = t1.transfer_bit(p47.flags_2476, 6, p46.flags_10932, 31)
    p47.flags_2476 = t1.transfer_bit(p47.flags_2476, 5, p46.flags_10932, 30)
    p47.flags_2476 = t1.transfer_bit(p47.flags_2476, 4, p46.flags_10932, 29)
    p47.scalar_2696 = p46.scalar_10912
    p47.vectors_624_640_656_672[3] = rt.copy(p46.vector_10848)
    p47.scalar_2700 = p46.scalar_10916
    p47.vectors_624_640_656_672[4] = rt.copy(p46.vector_10864)
    p47.flags_2480 = t1.replace_byte(p47.flags_2480, 0, p46.flag_10369)
    p47.vectors_880_896_912_928_944[1] = rt.copy(p46.vector_10880)
    p47.vectors_880_896_912_928_944[2] = rt.copy(p46.vector_10896)
    p47.flags_2488 = t1.transfer_bit(p47.flags_2488, 24, p46.flags_10932, 22)
    p47.vectors_544_560_592_608[3] = rt.copy(p45.reckoning.vector_64)
    p47.vectors_880_896_912_928_944[5] = rt.copy(p45.reckoning.vector_144)
    p47.flags_2488 = t1.replace_byte(p47.flags_2488, 21, p45.reckoning.flag_164)

    if p45.air.use_air_reckoning_452 == 0 then
        p47.vectors_544_560_592_608[4] = rt.copy(p45.reckoning.vector_16)
    else
        p47.vectors_544_560_592_608[4] = rt.copy(p45.air.vector_160)
    end

    p47.vectors_544_560_592_608[1] = rt.copy(p45.reckoning.vector_96)
    p47.vectors_544_560_592_608[2] = rt.copy(p45.board_reckoning_side_176)
    p47.vectors_464_480_496_512_528[1] = rt.copy(p45.ground.vector_96)
    p47.vectors_464_480_496_512_528[5] = rt.copy(p45.ground.vector_64)
    p47.vectors_720_784_800_816_832_864[5] = rt.copy(p45.ground.vector_128)
    p47.flags_2476 = t1.replace_byte(p47.flags_2476, 27, p45.ground.flag_317)
    p47.flags_2476 = t1.replace_byte(p47.flags_2476, 23, p45.ground.flag_318)
    p47.air_scalar_2772 = p45.air.scalar_184
    p47.flags_2476 = t1.replace_byte(p47.flags_2476, 26, p45.air.flag_441)
    p47.flags_2476 = t1.replace_byte(p47.flags_2476, 0, p45.air.flag_446)
    p47.flags_2480 = t1.replace_byte(p47.flags_2480, 25, p45.air.flag_447)
    p47.flags_2480 = t1.replace_byte(p47.flags_2480, 24, p45.air.flag_448)
    p47.flags_2480 = t1.transfer_bit(p47.flags_2480, 30, p45.component_1832_word_1876, 28)
    p47.flags_2468 = t1.replace_byte(p47.flags_2468, 9, p45.grinds.flag_318)
    p47.flags_2468 = t1.replace_byte(p47.flags_2468, 8, p45.grinds.flag_322)
    p47.flags_2468 = t1.replace_byte(p47.flags_2468, 15, p45.collision.flag_3478)
    p47.flags_2468 = t1.replace_byte(p47.flags_2468, 16, p45.collision.flag_3475)
    p47.flags_2468 = t1.replace_byte(p47.flags_2468, 17, p45.collision.flag_3472)
    p47.wheel_count_2556 = p45.collision.wheel_count_0
    p47.flags_2468 = t1.replace_byte(p47.flags_2468, 14, p45.collision.flag_3477)
    p47.collision_scalar_2924 = p45.collision.scalar_28
    p47.flags_2488 = t1.replace_byte(p47.flags_2488, 30, p45.collision.flag_3481)
    p47.flags_2472 = t1.replace_byte(p47.flags_2472, 11, p45.physics.flag_32)
    p47.vectors_720_784_800_816_832_864[4] = rt.copy(p45.physics.vector_16)
    p47.flags_2472 = t1.replace_byte(p47.flags_2472, 9, p45.skeleton.flag_597)
    p47.flags_2480 = t1.replace_byte(p47.flags_2480, 10, p45.skeleton.flag_600)
    p47.flags_2480 = t1.replace_byte(p47.flags_2480, 9, p45.skeleton.flag_601)
    p47.filtered_state_2524 = p45.filtered_state_0
    p47.flags_2476 = t1.replace_byte(p47.flags_2476, 21, p45.off_board.flag_304)
    p47.flags_2476 = t1.replace_bool(p47.flags_2476, 17, p45.off_board.scalar_32 <= 0)
    p47.flags_2480 = t1.replace_byte(p47.flags_2480, 15, p45.off_board.flag_311)
    p47.flags_2476 = t1.replace_byte(p47.flags_2476, 16, p45.off_board.flag_315)
    p47.flags_2476 = t1.replace_byte(p47.flags_2476, 8, p45.off_board.flag_316)
    p47.off_board_scalar_2832 = p45.off_board.scalar_32
    p47.flags_2480 = t1.replace_byte(p47.flags_2480, 1, p45.off_board.flag_318)
    p47.flags_2484 = t1.replace_byte(p47.flags_2484, 23, p45.off_board.flag_314)
    p47.vectors_880_896_912_928_944[3] = rt.copy(p45.off_board.vector_64)
    p47.flags_2484 = t1.replace_byte(p47.flags_2484, 16, p45.off_board.flag_328)
    t1.publish_wheel_contacts(p45, p47)
end

function t1.publish_wheel_contacts(p48, p49) -- line: 476
    -- upvalues: t1 (copy), v10 (ref)
    if v10 then
        return t1.publish_wheel_contacts_reference(p48, p49)
    end

    local wheel_contact_3296_3299 = p48.collision.wheel_contact_3296_3299
    local v24 = wheel_contact_3296_3299[3] ~= 0 or wheel_contact_3296_3299[4] ~= 0
    local v25 = wheel_contact_3296_3299[1] ~= 0 or wheel_contact_3296_3299[2] ~= 0
    local v26 = wheel_contact_3296_3299[3] ~= 0 or wheel_contact_3296_3299[1] ~= 0
    local v27 = wheel_contact_3296_3299[4] ~= 0 or wheel_contact_3296_3299[2] ~= 0
    local v28 = bit32.band(p49.flags_2468, 1048576) ~= 0

    p49.flags_2472 = t1.replace_bool(p49.flags_2472, 27, if v28 then v25 else v24)

    local replace_bool = t1.replace_bool
    local flags_2472 = p49.flags_2472

    if not v28 then
        v24 = v25
    end

    p49.flags_2472 = replace_bool(flags_2472, 26, v24)
    p49.flags_2472 = t1.replace_bool(p49.flags_2472, 25, if v28 then v27 else v26)

    local replace_bool2 = t1.replace_bool
    local flags_2472_2 = p49.flags_2472

    if not v28 then
        v26 = v27
    end

    p49.flags_2472 = replace_bool2(flags_2472_2, 24, v26)
end

function t1.publish_wheel_contacts_reference(p50, p51) -- line: 493
    -- upvalues: rt (copy), t1 (copy)
    local v29 = rt.copy(p50.collision.wheel_contact_3296_3299)
    local v30 = v29[3] ~= 0 or v29[4] ~= 0
    local v31 = v29[1] ~= 0 or v29[2] ~= 0
    local v32 = v29[3] ~= 0 or v29[1] ~= 0
    local v33 = v29[4] ~= 0 or v29[2] ~= 0
    local v34 = bit32.band(p51.flags_2468, 1048576) ~= 0

    p51.flags_2472 = t1.replace_bool(p51.flags_2472, 27, if v34 then v31 else v30)

    local replace_bool = t1.replace_bool
    local flags_2472 = p51.flags_2472

    if not v34 then
        v30 = v31
    end

    p51.flags_2472 = replace_bool(flags_2472, 26, v30)
    p51.flags_2472 = t1.replace_bool(p51.flags_2472, 25, if v34 then v33 else v32)

    local replace_bool2 = t1.replace_bool
    local flags_2472_2 = p51.flags_2472

    if not v34 then
        v32 = v33
    end

    p51.flags_2472 = replace_bool2(flags_2472_2, 24, v32)
end

function t1.effective_animation_transform(p52, p53) -- line: 506
    -- upvalues: rt (copy), v1 (copy)
    local v35 = rt.copy(p52)

    if bit32.band(p53, 4) ~= 0 then
        for _, v36 in { 0, 2 } do
            local v37 = v35[v36 + 1]

            for i = 1, #v37 do
                buffer.writeu32(v1, 0, v37[i])

                local v39 = -buffer.readf32(v1, 0)

                if v39 ~= 0 and v39 > -1.1754943508222875E-38 and v39 < 1.1754943508222875E-38 then
                    local v40 = math.abs(v39) * 7.1362384635298E+44
                    local v41 = math.floor(v40)
                    local v42 = v40 - v41
                    local v43 = if v42 > 0.5 or v42 == 0.5 and v41 % 2 == 1 then v41 + 1 else v41

                    if v39 < 0 then
                        v37[i] = v43 + 2147483648
                    else
                        v37[i] = v43
                    end
                else
                    buffer.writef32(v1, 0, v39)
                    v37[i] = buffer.readu32(v1, 0)
                end
            end
        end
    end

    return v35
end

function t1.effective_animation_transform_into(p54, p55, p56, p57) -- line: 521
    -- upvalues: v1 (copy), copy_into (copy)
    copy_into(p54, p55, p56)

    if bit32.band(p57, 4) ~= 0 then
        local v44 = p54[p55]

        for i = 0, 2, 2 do
            local v45 = v44[i + 1]

            for j = 1, #v45 do
                buffer.writeu32(v1, 0, v45[j])

                local v47 = -buffer.readf32(v1, 0)

                if v47 ~= 0 and v47 > -1.1754943508222875E-38 and v47 < 1.1754943508222875E-38 then
                    local v48 = math.abs(v47) * 7.1362384635298E+44
                    local v49 = math.floor(v48)
                    local v50 = v48 - v49
                    local v51 = if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49

                    if v47 < 0 then
                        v45[j] = v51 + 2147483648
                    else
                        v45[j] = v51
                    end
                else
                    buffer.writef32(v1, 0, v47)
                    v45[j] = buffer.readu32(v1, 0)
                end
            end
        end
    end
end

function t1.publish_line_tests(p58, p59) -- line: 536
    -- upvalues: rt (copy), t1 (copy), v10 (ref), copy_into (copy)
    if v10 then
        return t1.publish_line_tests_reference(p58, p59)
    end

    local line_tests_960_1008_1056 = p59.line_tests_960_1008_1056

    if type(line_tests_960_1008_1056) == "table" then
        copy_into(line_tests_960_1008_1056, 1, p58.left_line_test_1536)
        copy_into(line_tests_960_1008_1056, 2, p58.right_line_test_1584)
        copy_into(line_tests_960_1008_1056, 3, p58.hips_line_test_1488)

        for v52 in line_tests_960_1008_1056 do
            if v52 ~= 1 and v52 ~= 2 and v52 ~= 3 then
                line_tests_960_1008_1056[v52] = nil
            end
        end
    else
        line_tests_960_1008_1056 = {
            rt.copy(p58.left_line_test_1536),
            rt.copy(p58.right_line_test_1584),
            rt.copy(p58.hips_line_test_1488)
        }
        p59.line_tests_960_1008_1056 = line_tests_960_1008_1056
    end

    if line_tests_960_1008_1056[1].valid ~= 0 then
        p59.left_surface_2596 = line_tests_960_1008_1056[1].surface
    end

    if line_tests_960_1008_1056[2].valid ~= 0 then
        p59.right_surface_2600 = line_tests_960_1008_1056[2].surface
    end
end

function t1.publish_line_tests_reference(p60, p61) -- line: 567
    -- upvalues: rt (copy)
    p61.line_tests_960_1008_1056 = {
        rt.copy(p60.left_line_test_1536),
        rt.copy(p60.right_line_test_1584),
        rt.copy(p60.hips_line_test_1488)
    }

    if p61.line_tests_960_1008_1056[1].valid ~= 0 then
        p61.left_surface_2596 = p61.line_tests_960_1008_1056[1].surface
    end

    if p61.line_tests_960_1008_1056[2].valid ~= 0 then
        p61.right_surface_2600 = p61.line_tests_960_1008_1056[2].surface
    end
end

function t1.replace_byte(p62, p63, p64) -- line: 582
    return (bit32.bor(bit32.band(p62, (bit32.bnot((bit32.lshift(1, p63))))), (bit32.lshift(bit32.band(p64, 1), p63))))
end

function t1.replace_bool(p65, p66, p67) -- line: 590
    return (bit32.bor(bit32.band(p65, (bit32.bnot((bit32.lshift(1, p66))))), (bit32.lshift(if p67 then 1 else 0, p66))))
end

function t1.transfer_bit(p68, p69, p70, p71) -- line: 595
    return (bit32.bor(bit32.band(p68, (bit32.bnot((bit32.lshift(1, p69))))), (bit32.lshift(bit32.band(bit32.rshift(p70, p71), 1), p69))))
end

return t1
