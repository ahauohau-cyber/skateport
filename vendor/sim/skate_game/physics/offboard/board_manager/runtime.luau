-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/board_possession")
local v2 = import("skate_game/physics/offboard/board_possession/settings")

import("skate_core/player/offboard/board_possession")

local v3 = import("skate_core/player/offboard/board_possession/math")
local BodyId = import("skate_core/physics/board").BodyId
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local Collections = import("skate_data/collections").Collections
local vector = v1.vector

local function solve() -- line: 23
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function board_manager() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager")
end

local v4 = false
local t1 = {}

function t1.set_reference(p1) -- line: 33
    -- upvalues: v4 (ref)
    v4 = p1
end

t1.LiveState = {}

function t1.LiveState.load(p2, p3) -- line: 49
    -- upvalues: rt (copy), v2 (copy), Collections (copy)
    local settings = p3.settings
    local SkateboardFriction = Collections.float(p2, "physics_wipeout", "default", "SkateboardFriction")
    local t2 = {}

    for v5, v6 in settings.deck_geometry.children do
        t2[v5] = v6.collision_enabled
    end

    local SkateboardRestitution = Collections.float(p2, "physics_wipeout", "default", "SkateboardRestitution")
    local v7 = v2.standard_angular_drag(p2)

    return {
        alignment_active = false,
        output = nil,
        volumes = {
            deck = true,
            wheels = true,
            trucks = settings.truck_collisions,
            deck_children = t2
        },
        alignment = {
            factor_1040 = 0,
            flag_1044 = false,
            first_1008 = { 0, 0, 0, 0 },
            second_1024 = { 0, 0, 0, 0 }
        },
        standard_materials = {
            rt.copy(settings.standard_wheel_material),
            rt.copy(settings.truck_material),
            rt.copy(settings.deck_material)
        },
        released_material = {
            static_friction = SkateboardFriction,
            dynamic_friction = SkateboardFriction,
            restitution = SkateboardRestitution
        },
        standard_drag = v7
    }
end

function t1.LiveState.effects(p4, p5, p6, p7) -- line: 92
    -- upvalues: rt (copy)
    return {
        board = p5.board,
        animated_290 = p6,
        wiping_out = p5.board_wiping_out,
        alignment = p4.alignment,
        alignment_active = p4.alignment_active,
        volumes = p4.volumes,
        materials = {
            wheels = p5.settings.wheel_material,
            trucks = p5.settings.truck_material,
            deck = p5.settings.deck_material
        },
        standard_materials = rt.copy(p4.standard_materials),
        released_material = rt.copy(p4.released_material),
        standard_angular_drag = p4.standard_drag,
        processed_dt_2604 = p7,
        refs = {
            wiping_out = { p5, "board_wiping_out" },
            alignment_active = { p4, "alignment_active" }
        }
    }
end

function t1.LiveState.publish_volumes(p8, p9) -- line: 119
    p9.settings.truck_collisions = p8.volumes.trucks

    local children = p9.settings.deck_geometry.children
    local deck_children = p8.volumes.deck_children

    for i = 1, math.min(#children, #deck_children) do
        children[i].collision_enabled = deck_children[i]
    end
end

function t1.LiveState.volume_enabled(p10, p11) -- line: 129
    -- upvalues: BodyId (copy)
    if p11.tag ~= "Board" then
        return true
    end

    if p11[1] == BodyId.Deck then
        return p10.volumes.deck
    end

    if p11[1] == BodyId.FrontTruck or p11[1] == BodyId.BackTruck then
        return p10.volumes.trucks
    end

    return p10.volumes.wheels
end

function t1.observe(p12, p13) -- line: 144
    -- upvalues: rt (copy), import (copy), compose_affine (copy), t1 (copy)
    local processed = p13.player_input.processed
    local drive_frames = p13.skeleton_input.drive_frames
    local v10 = import("skate_game/physics/solve").deck_frame(p12.board)
    local toolkit = p13.player_input.toolkit

    if toolkit ~= nil then
        v10 = rt.copy(toolkit.deck)
    end

    return {
        processed = {
            board_frame_64 = v10,
            player_frame_192 = rt.map(processed.effective_anim_transform_192, function(p14) -- line: 157
                -- upvalues: rt (copy)
                return rt.map(p14, rt.from_bits)
            end),
            position_592 = rt.map(processed.vectors_544_560_592_608[3], rt.from_bits),
            velocity_912 = rt.map(processed.vectors_880_896_912_928_944[3], rt.from_bits),
            direction_400 = rt.map(processed.vectors_400_416[1], rt.from_bits),
            hide_direction_464 = rt.map(processed.vectors_464_480_496_512_528[1], rt.from_bits),
            flags_2476 = processed.flags_2476,
            flags_2480 = processed.flags_2480,
            flags_2488 = processed.flags_2488
        },
        board_collision_flags_872 = p12.riding.ground.collision_flags,
        board_state_840 = t1.surface(p12),
        hand_contacts = {
            p13.collision_feedback.bones[4].groups[4],
            p13.collision_feedback.bones[8].groups[4]
        },
        physical_hand_positions = {
            rt.copy(p13.skeleton.record.pose[4][4]),
            rt.copy(p13.skeleton.record.pose[8][4])
        },
        animation_board_frame_12624 = rt.copy(drive_frames[1]),
        animation_hand_frames = {
            rt.copy(drive_frames[4]),
            rt.copy(drive_frames[8])
        },
        attachment_frame_0 = compose_affine(p13.animated_skeleton.roots.animation_to_world, drive_frames[1])
    }
end

local v11 = table.create(32, 0)

function t1.surface(p15) -- line: 193
    -- upvalues: t1 (copy), v4 (ref), v11 (copy)
    if v4 then
        return t1.surface_reference(p15)
    end

    if bit32.band(p15.riding.ground.collision_flags, 33554432) ~= 0 then
        return 12
    end

    for i = 1, 32 do
        v11[i] = 0
    end

    for i = 0, 3 do
        local v12 = p15.riding.wheel_lines.physics_surfaces[i + 1]

        if v12 ~= 0 then
            if v11[v12 + 1] == nil then
                error(string.format("index out of bounds: the len is 32 but the index is %d", v12), 0)
            end

            v11[v12 + 1] += p15.riding.ground.parts[i + 1].in_contact and 4 or 1
        end
    end

    local n1 = 1
    local n2 = 0

    for i = 1, 13 do
        if n2 < v11[i + 1] then
            n1 = i
            n2 = v11[i + 1]
        end
    end

    return n1
end

function t1.surface_reference(p16) -- line: 228
    if bit32.band(p16.riding.ground.collision_flags, 33554432) ~= 0 then
        return 12
    end

    local v14 = table.create(32, 0)

    for i = 0, 3 do
        local v15 = p16.riding.wheel_lines.physics_surfaces[i + 1]

        if v15 ~= 0 then
            if v14[v15 + 1] == nil then
                error(string.format("index out of bounds: the len is 32 but the index is %d", v15), 0)
            end

            v14[v15 + 1] += p16.riding.ground.parts[i + 1].in_contact and 4 or 1
        end
    end

    local n3 = 1
    local n4 = 0

    for i = 1, 13 do
        if n4 < v14[i + 1] then
            n3 = i
            n4 = v14[i + 1]
        end
    end

    return n3
end

function t1.update(p17, p18) -- line: 258
    -- upvalues: import (copy), t1 (copy)
    if p18.skateboard_controller.fields.system_on_452 then
        local v16 = t1.observe(p17, p18)
        local v17 = t1.LiveState.effects(p18.board_possession_live, p17, p18.ground_lifecycle.board_animated_290, p18.player_input.processed.timestep_2604)

        import("skate_game/physics/offboard/board_manager").Owner.update(p18.board_possession, p18.skateboard_controller.fields, v16, v17)
        p18.ground_lifecycle.board_animated_290 = v17.animated_290
        t1.LiveState.publish_volumes(p18.board_possession_live, p17)
    end
end

function t1.reset_for_teleport(p19, p20) -- line: 282
    -- upvalues: import (copy), t1 (copy)
    local v18 = t1.observe(p19, p20)
    local v19 = t1.LiveState.effects(p20.board_possession_live, p19, p20.ground_lifecycle.board_animated_290, p20.player_input.processed.timestep_2604)

    import("skate_game/physics/offboard/board_manager").Owner.reset_for_teleport(p20.board_possession, p20.skateboard_controller.fields, v18, v19)
    p20.ground_lifecycle.board_animated_290 = v19.animated_290
    p20.board_possession_live.output = nil
    t1.LiveState.publish_volumes(p20.board_possession_live, p19)
end

function t1.finish_teleport(p21, p22) -- line: 304
    -- upvalues: v1 (copy), t1 (copy)
    local v20 = t1.LiveState.effects(p22.board_possession_live, p21, p22.ground_lifecycle.board_animated_290, p22.player_input.processed.timestep_2604)

    v1.Effects.standard_board(v20)
    p22.ground_lifecycle.board_animated_290 = v20.animated_290
    t1.LiveState.publish_volumes(p22.board_possession_live, p21)
end

local t3 = {
    player_frame_192 = {}
}
local v21
local from_bits = rt.from_bits

function t1.publish(p23, p24) -- line: 336
    -- upvalues: rt (copy), import (copy), v3 (copy), compose_affine (copy), vector (copy), t1 (copy), v4 (ref), t3 (copy), v21 (ref), from_bits (copy)
    if v4 then
        return t1.publish_reference(p23, p24)
    end

    local board_possession_live = p24.board_possession_live

    if board_possession_live.alignment_active then
        local dot = v3.dot

        for _, v22 in p23.riding.ground.parts do
            if v22.in_contact and (dot(vector(v22.normal), rt.map(board_possession_live.alignment.first_1008, function(p25) -- line: 347
                return -p25
            end)) > board_possession_live.alignment.factor_1040 or dot(vector(v22.normal), rt.map(board_possession_live.alignment.second_1024, function(p26) -- line: 351
                return -p26
            end)) > board_possession_live.alignment.factor_1040) then
                p23.riding.ground.collision_flags = bit32.bor(p23.riding.ground.collision_flags, 67108864)
            end
        end
    end

    local processed, toolkit = p24.player_input.processed, p24.player_input.toolkit

    if toolkit ~= nil then
        t3.board_frame_64 = toolkit.deck
    else
        v21 = import("skate_game/physics/solve").deck_frame_into(p23.board, v21)
        t3.board_frame_64 = v21
    end

    local effective_anim_transform_192 = processed.effective_anim_transform_192
    local player_frame_192 = t3.player_frame_192
    local v23 = #effective_anim_transform_192

    for i = 1, v23 do
        local v24 = effective_anim_transform_192[i]
        local v25 = player_frame_192[i]

        if v25 == nil then
            v25 = {}
            player_frame_192[i] = v25
        end

        local v26 = #v24

        for j = 1, v26 do
            v25[j] = from_bits(v24[j])
        end

        for k = #v25, v26 + 1, -1 do
            v25[k] = nil
        end
    end

    for i = #player_frame_192, v23 + 1, -1 do
        player_frame_192[i] = nil
    end

    t3.flags_2476 = processed.flags_2476
    t1.surface(p23)

    local v27 = compose_affine(p24.animated_skeleton.roots.animation_to_world, p24.skeleton_input.drive_frames[12])
    local v28 = import("skate_game/physics/offboard/board_manager").Owner.fill(p24.board_possession, p24.skateboard_controller.fields, t3, v27)

    t3.board_frame_64 = nil

    local off_board = p24.player_input.physical.off_board

    off_board.angle_36 = v28.angle_36
    off_board.angle_40 = v28.angle_40
    off_board.flag_311 = v28.held_311 and 1 or 0
    off_board.free_board_312 = v28.free_312 and 1 or 0
    off_board.returning_board_313 = v28.returning_313 and 1 or 0
    off_board.hiding_board_321 = v28.hiding_321 and 1 or 0
    off_board.dropping_board_322 = v28.flag_322 and 1 or 0
    off_board.retrieving_board_323 = v28.flag_323 and 1 or 0
    off_board.flag_324 = v28.flag_324 and 1 or 0
    p24.board_possession_live.output = v28

    return v28
end

function t1.publish_reference(p27, p28) -- line: 423
    -- upvalues: rt (copy), import (copy), v3 (copy), compose_affine (copy), vector (copy), t1 (copy)
    local board_possession_live = p28.board_possession_live

    if board_possession_live.alignment_active then
        local dot = v3.dot

        for _, v29 in p27.riding.ground.parts do
            if v29.in_contact and (dot(vector(v29.normal), rt.map(board_possession_live.alignment.first_1008, function(p29) -- line: 431
                return -p29
            end)) > board_possession_live.alignment.factor_1040 or dot(vector(v29.normal), rt.map(board_possession_live.alignment.second_1024, function(p30) -- line: 435
                return -p30
            end)) > board_possession_live.alignment.factor_1040) then
                p27.riding.ground.collision_flags = bit32.bor(p27.riding.ground.collision_flags, 67108864)
            end
        end
    end

    local v30 = t1.observe(p27, p28)
    local v31 = compose_affine(p28.animated_skeleton.roots.animation_to_world, p28.skeleton_input.drive_frames[12])
    local v32 = import("skate_game/physics/offboard/board_manager").Owner.fill(p28.board_possession, p28.skateboard_controller.fields, v30.processed, v31)
    local off_board = p28.player_input.physical.off_board

    off_board.angle_36 = v32.angle_36
    off_board.angle_40 = v32.angle_40
    off_board.flag_311 = v32.held_311 and 1 or 0
    off_board.free_board_312 = v32.free_312 and 1 or 0
    off_board.returning_board_313 = v32.returning_313 and 1 or 0
    off_board.hiding_board_321 = v32.hiding_321 and 1 or 0
    off_board.dropping_board_322 = v32.flag_322 and 1 or 0
    off_board.retrieving_board_323 = v32.flag_323 and 1 or 0
    off_board.flag_324 = v32.flag_324 and 1 or 0
    p28.board_possession_live.output = rt.copy(v32)

    return v32
end

return t1
