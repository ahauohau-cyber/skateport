-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/skeleton_input_general")
local v2 = import("skate_game/physics/skeleton_input_teleport")
local v3 = import("skate_core/physics/board")
local v4 = import("skate_core/physics/board_runtime")
local v5 = import("skate_core/physics/grind_air")
local v6 = import("skate_core/physics/skeleton_animation_record")
local v7 = import("skate_core/physics/skeleton_body")
local v8 = import("skate_core/riding/ground_correction_math")
local BodyId = v3.BodyId
local BoardRuntime = v4.BoardRuntime
local GrindAir = v5.GrindAir
local IDENTITY = v6.IDENTITY
local SkeletonBody = v7.SkeletonBody
local dot_product = v8.dot_product

local function animated_skeleton() -- line: 30
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

local function animation_input() -- line: 33
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_input")
end

local function foot_ik() -- line: 36
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik")
end

local function grind_air_settings() -- line: 39
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_air_settings")
end

local function pose_adjust() -- line: 42
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/pose_adjust")
end

local function skeleton_grind_air() -- line: 45
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_grind_air")
end

local copy_pose_buffered = v6.copy_pose_buffered
local self = setmetatable({}, {
    __mode = "k"
})
local t1 = {}

t1.CollisionInput = {}
t1.SkeletonOwners = {}
t1.SkeletonPoseInput = {}
t1.SkeletonInputRuntime = {}

local SkeletonInputRuntime = t1.SkeletonInputRuntime

function t1.SkeletonInputRuntime.default() -- line: 101
    -- upvalues: rt (copy), GrindAir (copy), IDENTITY (copy)
    return {
        reenable_requested = false,
        invalid_target_reset = false,
        teleporting = false,
        force_mode = 0,
        head_tracking_active = false,
        grind_air_started = false,
        grind_air_active = false,
        grind_air_adjusting = false,
        grind_air_settings = nil,
        deck_velocity = { 0, 0, 0, 0 },
        root_velocity = { 0, 0, 0, 0 },
        previous_root_position = { 0, 0, 0, 0 },
        animation_board_to_physics = rt.copy(IDENTITY),
        extra_target_positions = rt.filled(3, { 0, 0, 0, 0 }),
        reset_local_hips = { 0, 0, 0, 0 },
        drive_frames = rt.filled(24, IDENTITY),
        head_tracking_history = rt.filled(8, { 0, 0, 0, 0 }),
        grind_air = GrindAir.default()
    }
end

function t1.SkeletonInputRuntime.load(p1) -- line: 127
    -- upvalues: import (copy), SkeletonInputRuntime (copy)
    local v10 = import("skate_game/physics/grind_air_settings").load(p1)
    local v11 = SkeletonInputRuntime.default()

    v11.grind_air_settings = v10

    return v11
end

function t1.SkeletonInputRuntime.process_data(p2, p3, p4, p5, _, p7, p8, p9, p10) -- line: 140
    -- upvalues: rt (copy), import (copy), v1 (copy), BodyId (copy), BoardRuntime (copy), SkeletonBody (copy), dot_product (copy), t1 (copy), copy_pose_buffered (copy), self (copy)
    local linear_velocity = BoardRuntime.bodies(p3)[BodyId.index(BodyId.Deck) + 1].rates.linear_velocity

    p2.deck_velocity = {
        linear_velocity.x,
        linear_velocity.y,
        linear_velocity.z,
        0
    }

    for _, v12 in ipairs(SkeletonBody.bodies_mut(p8.body)) do
        if bit32.band(v12.state_flags, 7) == 2 then
            v12.state_flags = bit32.bor(bit32.band(v12.state_flags, 8), 4)
        end

        v12.rates.cool_down = 0
    end

    local animation_input = p8.animation_input
    local AnimationInput = import("skate_game/physics/animation_input").AnimationInput

    AnimationInput.reset_processed(animation_input)
    animation_input.fields.flags2468 = p7.flags_2468
    animation_input.fields.flags2472 = p7.flags_2472
    animation_input.fields.flags2476 = p7.flags_2476
    animation_input.fields.flags2484 = p7.flags_2484
    animation_input.fields.flags2488 = p7.flags_2488
    animation_input.extra.flags2480 = p7.flags_2480
    AnimationInput.process(animation_input, p9.attributes, p9.globals, p5.publication.timestep, p5.flags_10932, p5.publication.flags_10375_10496_10784[2] ~= 0, p9.actions)
    t1.publish_attribute_flags(animation_input, p7)
    p7.spin_input_2672 = animation_input.fields.spin

    local AnimatedSkeleton = import("skate_game/physics/animated_skeleton").AnimatedSkeleton
    local v14 = AnimatedSkeleton.reparented_hand_indices(p8.animated)

    import("skate_game/physics/offboard/pose_adjust").update(p8.animated, p9.globals, v14, p7)

    local flags_2476 = p7.flags_2476

    if bit32.band(flags_2476, 256) == 0 then
        p2.grind_air_adjusting = false

        local grind_air_settings

        if p2.grind_air_active then
            grind_air_settings = p2.grind_air_settings

            if grind_air_settings == nil then
                error("GrindAirAdjust stock settings were not loaded", 0)
            end

            p2.grind_air_adjusting = import("skate_game/physics/skeleton_grind_air").update(p2.grind_air, grind_air_settings, rt.copy(p4.deck), p7, p8.animated, p9.globals)
        end
    end

    local v15 = rt.map(p7.vectors_544_560_592_608[1], rt.from_bits)
    local v16 = rt.map(p7.vectors_544_560_592_608[4], rt.from_bits)
    local t4 = {
        p8.body.record.centre_of_mass[1] - p8.body.record.positions[1][1],
        p8.body.record.centre_of_mass[2] - p8.body.record.positions[1][2],
        p8.body.record.centre_of_mass[3] - p8.body.record.positions[1][3],
        p8.body.record.centre_of_mass[4] - p8.body.record.positions[1][4]
    }
    local t5 = {
        filtered_state = p7.filtered_state_2524,
        flags_2468 = p7.flags_2468,
        flags_2472 = p7.flags_2472,
        flags_2476 = p7.flags_2476,
        balance = animation_input.fields.balance,
        physical_com_velocity_along_up = dot_product(v16, v15),
        physical_com_height = dot_product(t4, v15),
        animation_com_height = p8.animated.record.centre_of_mass[2]
    }
    local t6 = if bit32.band(p7.flags_2476, 65792) == 256 then {
        rt.copy(p4.deck),
        rt.map(p7.vectors_720_784_800_816_832_864[6], rt.from_bits),
        p7.flags_2480,
        p7.off_board_scalar_2832
    } else nil
    local v17, v18 = AnimatedSkeleton.process_pose(p8.animated, p9.globals, t5, p5.publication.timestep, p7.flags_2468, p7.flags_2472, t6)

    p7.flags_2468 = v17
    p7.flags_2472 = v18

    local v19, v20 = copy_pose_buffered(self[p2], p8.animated.record.pose)

    self[p2] = v20
    p2.drive_frames = v19
    p7.board_at_y_delta_2768 = p8.animated.board_at_y_delta
    p7.flags_2472 = bit32.bor(bit32.band(p7.flags_2472, 4294836223), (bit32.lshift(if p10.contact_4070 then 1 else 0, 17)))

    if p10.has_pose_error_4077 then
        p7.collision_pose_error_736 = rt.map(p10.pose_error_16272, rt.to_bits)
    end

    p7.animation_com_to_deck_752 = rt.map(p8.animated.record.com_to_deck_world, rt.to_bits)
    p7.animation_com_to_deck_delta_768 = rt.map(p8.animated.record.com_to_deck_world_delta, rt.to_bits)
    animation_input.fields.flags2468 = p7.flags_2468
    animation_input.fields.flags2472 = p7.flags_2472

    if p2.reenable_requested then
        p2.reenable_requested = false
        import("skate_game/physics/foot_ik").FootIk.enable_feet(p8.ik, true)
        v1.restore_board_target_drives(p8.drives)
        p8.animated.roots.supplied_prediction = nil
    end
end

for v24, v25 in v1.SkeletonInputRuntime do
    t1.SkeletonInputRuntime[v24] = v25
end

for v26, v27 in v2.SkeletonInputRuntime do
    t1.SkeletonInputRuntime[v26] = v27
end

local t7 = {
    "skate_game/physics/skeleton_air",
    "skate_game/physics/offboard/skeleton_air",
    "skate_game/physics/offboard/skeleton_ground"
}
local v28 = false

setmetatable(t1.SkeletonInputRuntime, {
    __index = function(p11, p12) -- __index | line: 301
        -- upvalues: import (copy), t7 (copy), v28 (ref)
        if v28 then
            return nil
        end

        v28 = true

        for _, v29 in ipairs(t7) do
            local ok, result = pcall(import, v29)

            if ok then
                if type(result) == "table" and type(result.SkeletonInputRuntime) == "table" then
                    for v30, v31 in result.SkeletonInputRuntime do
                        if rawget(p11, v30) == nil then
                            rawset(p11, v30, v31)
                        end
                    end
                end
            else
                v28 = false
            end
        end

        return (rawget(p11, p12))
    end
})

function t1.publish_attribute_flags(p13, p14) -- line: 325
    local fields = p13.fields

    p14.flags_2468 = fields.flags2468
    p14.flags_2472 = fields.flags2472
    p14.flags_2476 = fields.flags2476
    p14.flags_2484 = fields.flags2484
    p14.flags_2488 = fields.flags2488
    p14.flags_2480 = p13.extra.flags2480
end

return t1
