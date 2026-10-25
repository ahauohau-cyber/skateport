-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local GroundLaunchInfo = import("skate_game/physics/ground_runtime/launch").GroundLaunchInfo
local GroundSettings = import("skate_game/physics/ground_runtime/settings").GroundSettings
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local Requests = import("skate_core/player/wipeout").Requests
local signed_angle = import("skate_core/riding/collision_response").signed_angle
local wall_ride_response = import("skate_core/riding/ground_contact_response").wall_ride_response
local v1 = import("skate_core/riding/ground_correction_math")
local v2 = import("skate_core/riding/grounded/state/board")

local function parent() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local vector
local t1 = {}

t1.GroundControllers = {}
t1.GroundPhysicalFrame = {}
t1.BoardServices = {}

local t2 = {
    "angle_between",
    "dot3",
    "scale_to_magnitude",
    "build_hang_force",
    "apply_hang_force",
    "detect_hung_up_geometry",
    "request_wipeout",
    "angular_displacement",
    "apply_angular_displacement",
    "pin_to_captured_position",
    "center_of_mass_height_82d38838",
    "set_contact_wheel_materials",
    "contact_response_82d93df0",
    "update_body_accumulator_82d389dc",
    "set_animated_velocity_82c04168",
    "write_processed_velocity_400",
    "build_animated_pose_82d33448",
    "publish_animated_pose_82be33d0",
    "update_external_player_82d67848",
    "commit_external_player_82d68800",
    "finalize_animated_board_sk83_na_f_01a4",
    "collision_force_82d944e8",
    "collision_force_dot_velocity_82d38e18",
    "apply_vector_82c07000",
    "apply_angular_displacement_82c075b8"
}

local function board_services_trait(p1) -- line: 110
    -- upvalues: t1 (copy), t2 (copy)
    local t3 = {}

    for _, v3 in t2 do
        local v4 = t1.BoardServices[v3]

        t3[v3] = function(_, ...) -- line: 114
            -- upvalues: p1 (copy), v4 (copy)
            return v4(p1, ...)
        end
    end

    return t3
end

local function debug_format(p3) -- line: 124
    -- upvalues: debug_format (copy)
    if type(p3) ~= "table" then
        return (tostring(p3))
    end

    if p3.tag == "Service" then
        local source = p3.source
        local v5 = if type(source) == "string" then "\"" .. source .. "\"" else debug_format(source)

        return "Service { stage: " .. tostring(p3.stage) .. ", source: " .. v5 .. " }"
    end

    if p3.tag == nil then
        return (tostring(p3))
    end

    local t4 = {}
    local n1 = 1

    while p3[n1] ~= nil do
        t4[n1] = debug_format(p3[n1])
        n1 += 1
    end

    if #t4 > 0 then
        return tostring(p3.tag) .. "(" .. table.concat(t4, ", ") .. ")"
    end

    local t5 = {}

    for v6 in p3 do
        if v6 ~= "tag" then
            table.insert(t5, (tostring(v6)))
        end
    end

    table.sort(t5)

    if #t5 == 0 then
        return (tostring(p3.tag))
    end

    local t6 = {}

    for v8, v9 in t5 do
        t6[v8] = v9 .. ": " .. debug_format(p3[v9])
    end

    return tostring(p3.tag) .. " { " .. table.concat(t6, ", ") .. " }"
end

t1.GroundRuntime = {}

local function move_into(p4, p5) -- line: 173
    for v10 in p4 do
        if p5[v10] == nil then
            p4[v10] = nil
        end
    end

    for v11, v12 in p5 do
        p4[v11] = v12
    end
end

local v13

function t1.GroundRuntime.update_board(p6, p7, p8, p9, p10, p11, p12, p13) -- line: 201
    -- upvalues: GroundSettings (copy), BoardRuntime (copy), BoardForceQueue (copy), v2 (copy), t1 (copy), t2 (copy), debug_format (copy), v13 (ref)
    p12.speed_wobble.activation_threshold = p9.wobble_activation
    p12.speed_wobble.amplitude_multiplier = p9.wobble_amplitude

    local v14 = BoardRuntime.forces_mut(p7)
    local v15 = BoardForceQueue.take(v14)
    local v16 = BoardRuntime.bodies(p7)
    local t7 = {
        {
            linear_drag = v16[1].inertia.linear_drag
        },
        {
            linear_drag = v16[2].inertia.linear_drag
        },
        {
            linear_drag = v16[3].inertia.linear_drag
        },
        {
            linear_drag = v16[4].inertia.linear_drag
        },
        {
            linear_drag = v16[5].inertia.linear_drag
        },
        {
            linear_drag = v16[6].inertia.linear_drag
        },
        {
            linear_drag = v16[7].inertia.linear_drag
        }
    }
    local t8 = {
        part_inertia_indices = { 0, 1, 2, 3, 4, 5, 6 },
        inertias = t7
    }
    local v17 = v13

    if v17 == nil then
        v17 = {}

        for _, v18 in t2 do
            v17[v18] = t1.BoardServices[v18]
        end

        v13 = v17
    end

    local v19 = table.clone(v17)

    v19.runtime = p6
    v19.board = p7
    v19.world = p8
    v19.settings = p9
    v19.physical = p13
    v19.launch = nil

    local t9 = {
        speed_wobble = p11.speed_wobble,
        truck_steering = p11.truck_steering,
        speed_model = p11.speed_model,
        manual = p11.manual,
        heading_previous = p11.heading_previous,
        force_queue = v15,
        inertias = t8
    }
    local update = v2.update
    local v20 = GroundSettings.board(p9)
    local ok, result = pcall(update, p10, t9, v20, p12, v19)

    p11.heading_previous = t9.heading_previous

    local v21 = BoardRuntime.bodies_mut(v19.board)

    for i = 1, #v21 do
        v21[i].inertia.linear_drag = t7[i].linear_drag
    end

    BoardForceQueue.restore(BoardRuntime.forces_mut(v19.board), v15)

    if not ok then
        error("Native Ground board update: " .. debug_format(result), 0)
    end

    return result
end

function t1.GroundRuntime.update_board_reference(p14, p15, p16, p17, p18, p19, p20, p21) -- line: 316
    -- upvalues: rt (copy), GroundSettings (copy), BoardRuntime (copy), BoardForceQueue (copy), v2 (copy), board_services_trait (copy), debug_format (copy)
    p20.speed_wobble.activation_threshold = p17.wobble_activation
    p20.speed_wobble.amplitude_multiplier = p17.wobble_amplitude

    local v22 = BoardRuntime.forces_mut(p15)
    local v23 = rt.copy(v22)

    rt.assign(v22, BoardForceQueue.default())

    local t10 = {
        rt.copy(BoardRuntime.bodies(p15)[1].inertia),
        rt.copy(BoardRuntime.bodies(p15)[2].inertia),
        rt.copy(BoardRuntime.bodies(p15)[3].inertia),
        rt.copy(BoardRuntime.bodies(p15)[4].inertia),
        rt.copy(BoardRuntime.bodies(p15)[5].inertia),
        rt.copy(BoardRuntime.bodies(p15)[6].inertia),
        rt.copy(BoardRuntime.bodies(p15)[7].inertia)
    }
    local t11 = {
        part_inertia_indices = { 0, 1, 2, 3, 4, 5, 6 },
        inertias = t10
    }
    local t12 = {
        launch = nil,
        runtime = p14,
        board = p15,
        world = p16,
        settings = p17,
        physical = p21
    }
    local t13 = {
        speed_wobble = p19.speed_wobble,
        truck_steering = p19.truck_steering,
        speed_model = p19.speed_model,
        manual = p19.manual,
        heading_previous = p19.heading_previous,
        force_queue = v23,
        inertias = t11
    }
    local update = v2.update
    local v24 = GroundSettings.board(p17)
    local v25 = board_services_trait(t12)
    local ok, result = pcall(update, p18, t13, v24, p20, v25)

    p19.heading_previous = t13.heading_previous

    local v26 = BoardRuntime.bodies_mut(t12.board)

    for i = 1, #v26 do
        v26[i].inertia.linear_drag = t10[i].linear_drag
    end

    rt.assign(BoardRuntime.forces_mut(t12.board), v23)

    if not ok then
        error("Native Ground board update: " .. debug_format(result), 0)
    end

    return result
end

function t1.BoardServices.angle_between(_, p23, p24, p25) -- line: 379
    -- upvalues: import (copy), signed_angle (copy)
    local xyz = import("skate_game/physics/ground_runtime").xyz

    return signed_angle(xyz(p23), xyz(p24), xyz(p25))
end

function t1.BoardServices.dot3(_, p27, p28) -- line: 385
    -- upvalues: v1 (copy)
    return v1.dot_product(p27, p28)
end

function t1.BoardServices.scale_to_magnitude(_, p30, p31, p32) -- line: 389
    -- upvalues: v1 (copy)
    return v1.scale_to_magnitude(p30, p31, p32)
end

function t1.BoardServices.build_hang_force(p33) -- line: 394
    -- upvalues: import (copy), vector (ref)
    local hang_geometry = p33.physical.hang_geometry

    return import("skate_game/physics/ground_runtime").GroundRuntime.build_hang_force(p33.runtime, p33.board, vector(hang_geometry.edge_start), vector(hang_geometry.edge_end))
end

function t1.BoardServices.apply_hang_force(p34, p35) -- line: 399
    -- upvalues: import (copy)
    import("skate_game/physics/ground_runtime").GroundRuntime.apply_hang_force(p34.runtime, p34.board, p35)
end

function t1.BoardServices.detect_hung_up_geometry(p36) -- line: 403
    -- upvalues: rt (copy), import (copy)
    return import("skate_game/physics/ground_runtime").GroundRuntime.detect_hung_up_geometry(p36.runtime, p36.world, rt.copy(p36.physical.hang_geometry))
end

function t1.BoardServices.request_wipeout(p37) -- line: 407
    -- upvalues: Requests (copy)
    Requests.request(p37.physical.wipeout, 12, 0)
end

local v27 = BoardRuntime.transform_scratch()

function t1.BoardServices.angular_displacement(p38) -- line: 417
    -- upvalues: BodyId (copy), BoardRuntime (copy), v1 (copy), v27 (copy)
    local columns = BoardRuntime.part_transform_into(p38.board, BodyId.index(BodyId.Deck), v27).basis.columns

    return v1.wheel_catch_displacement({
        columns[2][1],
        columns[2][2],
        columns[2][3],
        0
    }, {
        columns[3][1],
        columns[3][2],
        columns[3][3],
        0
    })
end

function t1.BoardServices.apply_angular_displacement(p39, p40) -- line: 430
    -- upvalues: import (copy)
    import("skate_game/physics/ground_runtime").GroundRuntime.apply_angular_displacement(p39.runtime, p39.board, p40)
end

function t1.BoardServices.pin_to_captured_position(p41, p42, p43) -- line: 435
    -- upvalues: import (copy)
    import("skate_game/physics/ground_runtime").GroundRuntime.pin_to_position(p41.runtime, p41.board, p42, p43, p41.physical.time_step)
end

function t1.BoardServices.center_of_mass_height_82d38838(p44) -- line: 440
    -- upvalues: v1 (copy)
    return v1.center_of_mass_height(p44.physical.skeleton_record.com_to_deck_world)
end

function t1.BoardServices.set_contact_wheel_materials(p45) -- line: 444
    -- upvalues: rt (copy)
    rt.assign(p45.physical.wheel_material, p45.settings.wheel_material)
end

function t1.BoardServices.contact_response_82d93df0(p46, p47, p48) -- line: 448
    -- upvalues: rt (copy), wall_ride_response (copy)
    p46.runtime.contact = wall_ride_response(p46.runtime.wall_ride, rt.copy(p46.physical.wall_ride), p47, p48)

    return rt.copy(p46.runtime.contact)
end

function t1.BoardServices.update_body_accumulator_82d389dc(p49) -- line: 453
    -- upvalues: import (copy)
    import("skate_game/physics/ground_runtime").GroundRuntime.update_body_accumulator(p49.runtime, p49.board)
end

function t1.BoardServices.set_animated_velocity_82c04168(p50, p51) -- line: 457
    -- upvalues: import (copy)
    import("skate_game/physics/ground_runtime").GroundRuntime.set_animated_velocity(p50.runtime, p50.board, p51)
end

function t1.BoardServices.write_processed_velocity_400(p52, p53) -- line: 461
    -- upvalues: rt (copy)
    rt.assign(p52.physical.processed_velocity, p53)
end

function t1.BoardServices.build_animated_pose_82d33448(_) -- line: 465
    -- upvalues: GroundLaunchInfo (copy)
    return GroundLaunchInfo.default()
end

function t1.BoardServices.publish_animated_pose_82be33d0(p55, p56) -- line: 469
    -- upvalues: rt (copy), GroundLaunchInfo (copy)
    local launch_physical = p55.physical.launch_physical

    if launch_physical == nil then
        error("Ground wall jump requires actual Skeleton/Reckoning launch observations82BE33D0", 0)
    end

    local v28 = rt.copy(p56)

    GroundLaunchInfo.fill(v28, launch_physical, p55.runtime.launch_cone_x, p55.runtime.launch_cone_z)
    p55.launch = v28
end

function t1.BoardServices.update_external_player_82d67848(p57, _, p59) -- line: 479
    -- upvalues: GroundLaunchInfo (copy)
    if p57.launch == nil then
        error("Ground launch packet was not filled", 0)
    end

    GroundLaunchInfo.wall_jump(p57.launch, p59)
end

function t1.BoardServices.commit_external_player_82d68800(p60) -- line: 486
    local launch = p60.launch

    if launch == nil then
        error("Ground launch packet was not prepared", 0)
    end

    return p60.physical.launch_and_update(launch)
end

function t1.BoardServices.finalize_animated_board_sk83_na_f_01a4(_) -- line: 494
end

function t1.BoardServices.collision_force_82d944e8(p62, p63) -- line: 500
    -- upvalues: rt (copy), import (copy)
    local v29 = rt.copy(p62.physical.collision)

    v29.ground_normal = rt.copy(p63)

    return import("skate_game/physics/ground_runtime").GroundRuntime.calculate_collision_force(p62.runtime, v29)
end

function t1.BoardServices.collision_force_dot_velocity_82d38e18(p64, p65, p66) -- line: 506
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime").GroundRuntime.collision_force_projection(p64.runtime, p65, p66)
end

function t1.BoardServices.apply_vector_82c07000(p67, p68) -- line: 510
    -- upvalues: import (copy)
    import("skate_game/physics/ground_runtime").GroundRuntime.apply_angular_target(p67.runtime, p67.board, p68)
end

function t1.BoardServices.apply_angular_displacement_82c075b8(p69, p70) -- line: 514
    -- upvalues: import (copy)
    import("skate_game/physics/ground_runtime").GroundRuntime.apply_angular_displacement(p69.runtime, p69.board, p70)
end

function vector(p71) -- line: 519
    return {
        p71.x,
        p71.y,
        p71.z,
        0
    }
end

t1.vector = vector

return t1
