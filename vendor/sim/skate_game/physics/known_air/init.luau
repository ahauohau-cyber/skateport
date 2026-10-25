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
local v2 = import("skate_game/physics/known_air/output")
local v3 = import("skate_game/physics/known_air/runtime")
local v4 = import("skate_game/physics/known_air/settings")
local v5 = import("skate_core/air/known")
local TrajectorySelector = import("skate_core/air/trajectory").TrajectorySelector
local Collections = import("skate_data/collections").Collections

local function wipeout_requests() -- line: 24
    -- upvalues: import (copy)
    return import("skate_core/player/wipeout")
end

local t1 = {}
local Runtime = v3.Runtime

local function from_bits4(p2) -- line: 35
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v7,
        v9,
        v11,
        (buffer.readf32(v1, 0))
    }
end

local function as_trait_reference(p3) -- line: 41
    -- upvalues: Runtime (copy)
    local t2 = {}

    for v13, v14 in Runtime do
        t2[v13] = function(_, ...) -- line: 44
            -- upvalues: p3 (copy), v14 (copy)
            return v14(p3, ...)
        end
    end

    return t2
end

local v15 = false

function t1.set_reference(p5) -- line: 65
    -- upvalues: v15 (ref)
    v15 = p5
end

local v16, t3

local function build_trait() -- line: 70
    -- upvalues: Runtime (copy), v16 (ref), t3 (ref)
    local t4 = {}

    for v17 in Runtime do
        t4[v17] = function(_, ...) -- line: 73
            -- upvalues: v17 (copy), Runtime (copy), v16 (ref)
            return Runtime[v17](v16, ...)
        end
    end

    t3 = t4

    return t4
end

function t1.rebuild_trait() -- line: 80
    -- upvalues: t3 (ref)
    t3 = nil
end

function t1.bind_trait(p7) -- line: 85
    -- upvalues: v16 (ref), t3 (ref), build_trait (copy)
    v16 = p7

    return t3 or build_trait()
end

t1.as_trait_reference = as_trait_reference
t1.KnownAir = {}

function t1.KnownAir.adopt_mode_settings(p8, p9) -- line: 100
    p8.modes = p9.modes
end

function t1.KnownAir.load(p10) -- line: 105
    -- upvalues: v4 (copy), Collections (copy), from_bits4 (copy)
    local v18, v19 = v4.load(p10)

    return {
        settings = v18,
        modes = v19,
        wipeout = {
            air_falling_min_up_y_260 = Collections.float(p10, "physics_wipeout", "default", "Wipeout_AirFallingMinUpY"),
            air_falling_max_angle_264 = Collections.float(p10, "physics_wipeout", "default", "Wipeout_AirFallingMaxAngle")
        },
        flip_axis_adjustment = from_bits4(Collections.words(p10, "physics_reckoning", "default", "FlipAxisAdjustment", 4)),
        state = {
            collision_normal_speed_176 = 0,
            time_in_state_180 = 0,
            start_y_184 = 0,
            max_y_188 = 0,
            com_max_y_192 = 0,
            collision_time_196 = 0,
            time_to_apex_200 = 0,
            body_flip_target_speed_204 = 0,
            reached_apex_208 = false,
            landing_heading_valid_209 = false,
            start_flipped_210 = false,
            body_flipping_211 = false,
            grind_air_adjust_activated_212 = false,
            targeting_grind_213 = false,
            trajectory_index_216 = 0,
            landing_normal_64 = { 0, 1, 0, 0 },
            landing_heading_80 = { 0, 0, 0, 0 },
            trajectory_apex_96 = { 0, 0, 0, 0 },
            collision_position_112 = { 0, 0, 0, 0 },
            selector_vector_128 = { 0, 0, 0, 0 },
            trajectory_follow_offset_144 = { 0, 0, 0, 0 },
            target_com_position_160 = { 0, 0, 0, 0 }
        }
    }
end

function t1.KnownAir.mode(p11, p12) -- line: 147
    -- upvalues: rt (copy)
    local v20 = p11.modes[p12 + 1]

    if v20 == nil then
        error(("Undefined KnownAir physics mode %*"):format(p12), 0)
    end

    return rt.copy(v20)
end

function t1.frame(p13, p14) -- line: 156
    -- upvalues: rt (copy), v1 (copy), TrajectorySelector (copy), from_bits4 (copy)
    local processed, toolkit = p13.player_input.processed, p13.player_input.toolkit

    if toolkit == nil then
        error("KnownAir requires current BoardToolkit", 0)
    end

    local v21 = TrajectorySelector.selection(p13.trajectory.selector)

    if v21 == nil then
        error("KnownAir requires a completed selected trajectory", 0)
    end

    local t5 = {
        start_flip_reference_96 = rt.copy(toolkit.deck[3]),
        alternate_head_target_112 = rt.copy(toolkit.deck[4]),
        velocity_400 = from_bits4(processed.vectors_400_416[1]),
        ground_normal_464 = from_bits4(processed.vectors_464_480_496_512_528[1])
    }

    buffer.writeu32(v1, 0, processed.vectors_464_480_496_512_528[2][2])
    t5.start_height_484 = buffer.readf32(v1, 0)
    t5.skater_up_544 = from_bits4(processed.vectors_544_560_592_608[1])
    t5.flags_2468 = processed.flags_2468
    t5.flags_2472 = processed.flags_2472
    t5.flags_2476 = processed.flags_2476
    t5.flags_2480 = processed.flags_2480
    t5.flags_2484 = processed.flags_2484
    t5.flags_2488 = processed.flags_2488
    t5.next_physics_state_2500 = rt.to_i32(p14)
    t5.delta_time_2604 = processed.timestep_2604
    t5.forward_speed_2612 = processed.scalar_2612
    t5.body_spin_input_2640 = p13.animation_input.fields.body_spin
    t5.selector_landing_normal_2656 = rt.copy(v21.landing_normal)

    return t5
end

function t1.reckoning(p15, p16) -- line: 188
    -- upvalues: rt (copy)
    local up = p15.riding.reckoning.up

    return {
        landing_normal_1152 = {
            up.x,
            up.y,
            up.z,
            0
        },
        heading_axis_1200 = rt.copy(p15.riding.reckoning_frames.heading),
        body_spin_angle_1568 = p16.air_reckoning.state.spin_angle,
        body_spin_speed_1572 = p16.air_reckoning.state.spin_speed
    }
end

function t1.enter(p17, p18) -- line: 199
    -- upvalues: rt (copy), v5 (copy), t1 (copy), Runtime (copy), as_trait_reference (copy), v15 (ref), v16 (ref), t3 (ref), build_trait (copy)
    local v23 = t1.frame(p18, 201)
    local v24 = rt.copy(p18.known_air.state)
    local v25 = rt.copy(p18.known_air.settings)
    local v26 = t1.KnownAir.mode(p18.known_air, p18.player_input.processed.state_variant_index_2528)
    local v27 = Runtime.new(p17, p18)

    if v15 then
        v5.enter(v24, v23, v25, v26, (as_trait_reference(v27)))
    else
        local v28 = v16

        v16 = v27
        v5.enter(v24, v23, v25, v26, t3 or build_trait())
        v16 = v28
    end

    Runtime.finish(v27)
    p18.known_air.state = v24
end

function t1.update(p19, p20) -- line: 218
    -- upvalues: rt (copy), v5 (copy), t1 (copy), Runtime (copy), as_trait_reference (copy), v15 (ref), v16 (ref), t3 (ref), build_trait (copy)
    local v29 = t1.frame(p20, 201)
    local v30 = rt.copy(p20.known_air.state)
    local v31 = rt.copy(p20.known_air.settings)
    local v32 = t1.KnownAir.mode(p20.known_air, p20.player_input.processed.state_variant_index_2528)
    local v33 = t1.reckoning(p19, p20)
    local v34 = Runtime.new(p19, p20)

    if v15 then
        v5.update(v30, v29, v31, v32, v33, (as_trait_reference(v34)))
    else
        local v35 = v16

        v16 = v34
        v5.update(v30, v29, v31, v32, v33, t3 or build_trait())
        v16 = v35
    end

    Runtime.finish(v34)
    p20.known_air.state = v30
end

function t1.exit(p21, p22, p23) -- line: 238
    -- upvalues: rt (copy), v5 (copy), t1 (copy), Runtime (copy), as_trait_reference (copy), v15 (ref), v16 (ref), t3 (ref), build_trait (copy)
    local v36 = t1.frame(p22, p23)
    local v37 = rt.copy(p22.known_air.state)
    local v38 = rt.copy(p22.known_air.settings)
    local v39 = t1.reckoning(p21, p22)
    local v40 = Runtime.new(p21, p22)

    if v15 then
        v5.exit(v37, v36, v38, v39, (as_trait_reference(v40)))
    else
        local v41 = v16

        v16 = v40
        v5.exit(v37, v36, v38, v39, t3 or build_trait())
        v16 = v41
    end

    Runtime.finish(v40)
    p22.player_input.processed.scalar_2612 = v36.forward_speed_2612
    p22.air_reckoning.state.spin_angle = v39.body_spin_angle_1568
    p22.air_reckoning.state.spin_speed = v39.body_spin_speed_1572
    p22.known_air.state = v37
end

function t1.post_physics(p24, p25) -- line: 261
    -- upvalues: rt (copy), import (copy), v5 (copy), t1 (copy), Runtime (copy), as_trait_reference (copy), v15 (ref), v16 (ref), t3 (ref), build_trait (copy)
    local v42 = t1.frame(p25, 201)
    local v43 = rt.copy(p25.known_air.state)
    local v44 = rt.copy(p25.known_air.wipeout)
    local v45 = t1.KnownAir.mode(p25.known_air, p25.player_input.processed.state_variant_index_2528)
    local t6 = {
        requested_35 = false,
        scalar_116 = 0,
        counter_200 = 0
    }
    local v46 = Runtime.new(p24, p25)

    if v15 then
        v5.update_post_physics(v43, v42, v45, v44, t6, (as_trait_reference(v46)))
    else
        local v47 = v16

        v16 = v46
        v5.update_post_physics(v43, v42, v45, v44, t6, t3 or build_trait())
        v16 = v47
    end

    Runtime.finish(v46)

    if t6.counter_200 ~= 0 then
        import("skate_core/player/wipeout").Requests.request(p25.wipeout.state, 15, t6.scalar_116)
    end

    p25.known_air.state = v43
end

function t1.fill(p26, p27) -- line: 288
    -- upvalues: rt (copy), v2 (copy), v5 (copy), t1 (copy), Runtime (copy), as_trait_reference (copy), v15 (ref), v16 (ref), t3 (ref), build_trait (copy)
    local v48 = t1.frame(p27, 201)
    local v49 = rt.copy(p27.known_air.state)
    local v50 = v2.storage(p27.player_input.physical.air)
    local v51 = Runtime.new(p26, p27)

    if v15 then
        v5.fill_physics_output(v49, v48, v50, (as_trait_reference(v51)))
    else
        local v52 = v16

        v16 = v51
        v5.fill_physics_output(v49, v48, v50, t3 or build_trait())
        v16 = v52
    end

    Runtime.finish(v51)
    v2.publish(v50, p27.player_input.physical.air)

    return v50
end

return t1
