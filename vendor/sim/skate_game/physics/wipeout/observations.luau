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

require(sim.import)

local vector
local t1 = {}

t1.Observations = {}

function t1.Observations.frame(p2) -- line: 38
    -- upvalues: rt (copy), vector (ref)
    local processed, collision, board = p2.processed, p2.collision, p2.board
    local v2 = rt.map(collision.regions, function(p3) -- line: 42
        return p3.force
    end)
    local maximum_pose_error = p2.maximum_pose_error

    if maximum_pose_error == nil then
        error("Wipeout requires completed Skeleton pose-error feedback", 0)
    end

    return {
        flags_2468 = processed.flags_2468,
        flags_2472 = processed.flags_2472,
        flags_2476 = processed.flags_2476,
        flags_2480 = processed.flags_2480,
        flags_2484 = processed.flags_2484,
        category = processed.category_2512,
        timestep = processed.timestep_2604,
        time_on_ground = processed.time_on_ground_2752,
        speed = processed.scalar_2652,
        animation_up = rt.map(processed.vectors_544_560_592_608[1], rt.from_bits),
        landing_angle = processed.scalar_2736,
        deck_velocity = rt.map(processed.vectors_400_416[1], rt.from_bits),
        com_velocity = rt.map(processed.vectors_544_560_592_608[4], rt.from_bits),
        jump_fix_frames = rt.to_i32(p2.jump_fix_frames),
        deck = rt.copy(p2.deck),
        input_board = rt.copy(p2.input_board),
        world_to_animation = rt.copy(p2.world_to_animation),
        closing_velocity = vector(board.closing_velocity),
        board_material_flags = board.collision_flags,
        board_contact = board.part_contact_count ~= 0,
        wheel_contact = board.wheel_contact_count ~= 0,
        board_contact_normal = vector(board.overall_normal),
        opposing_contact = board.opposing_contact,
        regions_force = v2,
        maximum_skater_force = collision.maximum_skater_force,
        vehicle_force = collision.maximum_group_8_force,
        group_8 = collision.flags.group_8,
        conflicting = collision.flags.conflicting,
        compliant = collision.flags.compliant,
        highest_normal = rt.copy(collision.highest_normal),
        pose_error = rt.copy(p2.pose_error),
        maximum_pose_error = maximum_pose_error,
        flip_active = p2.air.flip_active,
        flip_requested_speed = p2.air.flip_requested_speed,
        system_up_y = p2.system_up_y,
        grind_selected = p2.grind_locked_to_middle,
        grind_normal_valid = p2.grind_normal ~= nil,
        grind_normal = if p2.grind_normal == nil then { 0, 1, 0, 0 } else rt.copy(p2.grind_normal)
    }
end

local t3 = {
    animation_up = {},
    deck_velocity = {},
    com_velocity = {},
    closing_velocity = { 0, 0, 0, 0 },
    board_contact_normal = { 0, 0, 0, 0 },
    regions_force = {}
}
local v3 = table.freeze({ 0, 1, 0, 0 })
local from_bits = rt.from_bits

local function from_bits_into(p4, p5) -- line: 120
    -- upvalues: from_bits (copy)
    local v4 = #p5

    for i = 1, v4 do
        p4[i] = from_bits(p5[i])
    end

    for i = #p4, v4 + 1, -1 do
        p4[i] = nil
    end

    return p4
end

function t1.Observations.frame_view(p6) -- line: 131
    -- upvalues: rt (copy), t3 (copy), v3 (copy), from_bits (copy)
    local processed, collision, board = p6.processed, p6.collision, p6.board
    local regions = collision.regions
    local regions_force = t3.regions_force
    local v5 = #regions

    for i = 1, v5 do
        regions_force[i] = regions[i].force
    end

    for i = #regions_force, v5 + 1, -1 do
        regions_force[i] = nil
    end

    local maximum_pose_error = p6.maximum_pose_error

    if maximum_pose_error == nil then
        error("Wipeout requires completed Skeleton pose-error feedback", 0)
    end

    t3.flags_2468 = processed.flags_2468
    t3.flags_2472 = processed.flags_2472
    t3.flags_2476 = processed.flags_2476
    t3.flags_2480 = processed.flags_2480
    t3.flags_2484 = processed.flags_2484
    t3.category = processed.category_2512
    t3.timestep = processed.timestep_2604
    t3.time_on_ground = processed.time_on_ground_2752
    t3.speed = processed.scalar_2652

    local animation_up = t3.animation_up
    local v6 = processed.vectors_544_560_592_608[1]
    local v7 = #v6

    for i = 1, v7 do
        animation_up[i] = from_bits(v6[i])
    end

    for i = #animation_up, v7 + 1, -1 do
        animation_up[i] = nil
    end

    t3.landing_angle = processed.scalar_2736

    local deck_velocity = t3.deck_velocity
    local v8 = processed.vectors_400_416[1]
    local v9 = #v8

    for i = 1, v9 do
        deck_velocity[i] = from_bits(v8[i])
    end

    for i = #deck_velocity, v9 + 1, -1 do
        deck_velocity[i] = nil
    end

    local com_velocity = t3.com_velocity
    local v10 = processed.vectors_544_560_592_608[4]
    local v11 = #v10

    for i = 1, v11 do
        com_velocity[i] = from_bits(v10[i])
    end

    for i = #com_velocity, v11 + 1, -1 do
        com_velocity[i] = nil
    end

    t3.jump_fix_frames = rt.to_i32(p6.jump_fix_frames)
    t3.deck = p6.deck
    t3.input_board = p6.input_board
    t3.world_to_animation = p6.world_to_animation

    local closing_velocity = board.closing_velocity
    local closing_velocity2 = t3.closing_velocity
    local x, y, z = closing_velocity.x, closing_velocity.y, closing_velocity.z

    closing_velocity2[1] = x
    closing_velocity2[2] = y
    closing_velocity2[3] = z
    closing_velocity2[4] = 0
    t3.board_material_flags = board.collision_flags
    t3.board_contact = board.part_contact_count ~= 0
    t3.wheel_contact = board.wheel_contact_count ~= 0

    local overall_normal = board.overall_normal
    local board_contact_normal = t3.board_contact_normal
    local x2, y2, z2 = overall_normal.x, overall_normal.y, overall_normal.z

    board_contact_normal[1] = x2
    board_contact_normal[2] = y2
    board_contact_normal[3] = z2
    board_contact_normal[4] = 0
    t3.opposing_contact = board.opposing_contact
    t3.maximum_skater_force = collision.maximum_skater_force
    t3.vehicle_force = collision.maximum_group_8_force
    t3.group_8 = collision.flags.group_8
    t3.conflicting = collision.flags.conflicting
    t3.compliant = collision.flags.compliant
    t3.highest_normal = collision.highest_normal
    t3.pose_error = p6.pose_error
    t3.maximum_pose_error = maximum_pose_error
    t3.flip_active = p6.air.flip_active
    t3.flip_requested_speed = p6.air.flip_requested_speed
    t3.system_up_y = p6.system_up_y
    t3.grind_selected = p6.grind_locked_to_middle

    local grind_normal = p6.grind_normal

    t3.grind_normal_valid = grind_normal ~= nil
    t3.grind_normal = if grind_normal == nil then v3 else grind_normal

    return t3
end

function t1.request_input(p7) -- line: 197
    -- upvalues: v1 (copy)
    local t4 = {
        flags_2468 = p7.flags_2468,
        flags_2476 = p7.flags_2476,
        flags_2480 = p7.flags_2480,
        flags_2484 = p7.flags_2484
    }

    buffer.writeu32(v1, 0, p7.vectors_544_560_592_608[1][2])
    t4.animation_up_y = buffer.readf32(v1, 0)
    t4.category = p7.category_2512

    return t4
end

local t5 = {}

function t1.request_input_view(p8) -- line: 213
    -- upvalues: from_bits (copy), t5 (copy)
    t5.flags_2468 = p8.flags_2468
    t5.flags_2476 = p8.flags_2476
    t5.flags_2480 = p8.flags_2480
    t5.flags_2484 = p8.flags_2484
    t5.animation_up_y = from_bits(p8.vectors_544_560_592_608[1][2])
    t5.category = p8.category_2512

    return t5
end

function vector(p9) -- line: 225
    return {
        p9.x,
        p9.y,
        p9.z,
        0
    }
end

t1.vector = vector

return t1
