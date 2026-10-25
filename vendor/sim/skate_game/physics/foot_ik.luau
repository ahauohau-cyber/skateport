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
local Geometry = import("skate_core/animation/foot_ik/drive").Geometry
local v2 = import("skate_core/animation/foot_ik/post_physics")
local v3 = import("skate_core/animation/foot_ik/state")
local FootIkState, LIMBS = v3.FootIkState, v3.LIMBS
local inverse_rigid = import("skate_core/animation/foot_ik/transforms").inverse_rigid
local v4 = import("skate_core/physics/skeleton_animation_record")
local compose_affine, transform_point = v4.compose_affine, v4.transform_point
local Collections = import("skate_data/collections").Collections
local copy_pose_buffered = v4.copy_pose_buffered
local self = setmetatable({}, {
    __mode = "k"
})
local t1 = {
    FootIk = {},
    PhysicalInput = {},
    DriveOutput = {}
}

function t1.FootIk.load(p2, p3, p4) -- line: 66
    -- upvalues: rt (copy), Geometry (copy), FootIkState (copy), LIMBS (copy), Collections (copy), t1 (copy)
    local t4 = {}

    for i = 0, #p4.bone_indices - 1 do
        local v6 = p4.bone_indices[i + 1]
        local v7 = p3.parents[v6 + 1]

        if v7 == nil then
            error("IK bone exceeds stock hierarchy", 0)
        end

        local v8 = rt.filled(#p3.parents, false)

        while v7 >= 0 do
            if #v8 <= v7 or v8[v7 + 1] then
                error(("Invalid stock IK hierarchy ancestor for part %*"):format(i), 0)
            end

            v8[v7 + 1] = true

            local v9 = #p4.bone_indices - 1
            local v10

            for j = 0, v9 do
                if p4.bone_indices[j + 1] == v7 then
                    v10 = j
                    break
                end
            end

            if v10 == nil then
                v7 = p3.parents[v7 + 1]
                continue
            end

            t4[i + 1] = v10
            break
        end
    end

    local v11 = Geometry.new(t4, p4.physics_frames)

    Geometry.validate_limbs(v11, LIMBS)

    return {
        state = FootIkState.default(),
        geometry = v11,
        settings = t1.load_settings(p2),
        post_settings = {
            minimum_board_up = Collections.float(p2, "physics_animation", "default", "PostIKMinYAxisVal"),
            wipeout_height = Collections.float(p2, "animation", "default", "FeetRelativeHeightWipeout"),
            riding_height = Collections.float(p2, "animation", "default", "FeetRelativeHeightOnDeck")
        },
        bone_indices = rt.copy(p4.bone_indices)
    }
end

function t1.FootIk.enable_feet(p5, p6) -- line: 112
    -- upvalues: FootIkState (copy)
    FootIkState.enable_feet(p5.state, p6)
end

function t1.FootIk.physical_toe_positions(p7, p8) -- line: 119
    -- upvalues: transform_point (copy)
    return {
        transform_point(p8.pose[20], p7.geometry.inverse_part_frames[21][4]),
        transform_point(p8.pose[16], p7.geometry.inverse_part_frames[17][4])
    }
end

function t1.FootIk.post_physics(p9, p10, p11) -- line: 129
    -- upvalues: v2 (copy)
    return v2.update(p9.state, p10, p9.geometry, p9.settings, p9.post_settings, p11)
end

function t1.FootIk.update(p12, p13, p14, p15) -- line: 139
    -- upvalues: rt (copy), FootIkState (copy), inverse_rigid (copy), compose_affine (copy), copy_pose_buffered (copy), self (copy)
    local v12, v13 = copy_pose_buffered(self[p12], p13.record.pose)

    self[p12] = v13

    if p15.state_id ~= 702 then
        local pose = p13.record.pose
        local bone_indices = p12.bone_indices
        local v14 = #bone_indices
        local v16 = table.create((math.max(#pose, v14)))

        for i = 0, v14 - 1 do
            local v17 = p14[bone_indices[i + 1] + 1]

            if v17 == nil then
                error("IK original joint is absent from the current pose", 0)
            end

            v16[i + 1] = v17
        end

        for i = v14 + 1, #pose do
            v16[i] = pose[i]
        end

        local v18, v19, v20

        if p15.state_id == 503 then
            v18 = compose_affine(p13.roots.animation_to_world, p13.record.pose[1])
            v19 = v18
            v20 = inverse_rigid(v18)
        else
            v18 = p15.physical_board
            v19 = p13.roots.board
            v20 = p13.roots.inverse_board
        end

        FootIkState.update(p12.state, {
            flags_2468 = p15.flags_2468,
            flags_2472 = p15.flags_2472,
            flags_2480 = p15.flags_2480,
            animation_to_world = p13.roots.animation_to_world,
            world_to_animation = p13.roots.world_to_animation,
            physical_board = v18,
            contact_board = v19,
            inverse_contact_board = v20,
            animation = p13.record.pose,
            original_animation = v16,
            targets = p13.targets,
            hips_world_position = rt.copy(p15.hips_world_position),
            contact_bone = p15.contact_bone,
            foot_bones = {
                p12.bone_indices[16],
                p12.bone_indices[20]
            },
            current_contacts = rt.copy(p15.current_contacts)
        }, p12.geometry, p12.settings, v12)
    end

    return {
        frames = v12
    }
end

function t1.FootIk.update_reference(p16, p17, p18, p19) -- line: 216
    -- upvalues: rt (copy), FootIkState (copy), inverse_rigid (copy), compose_affine (copy)
    local v21 = rt.copy(p17.record.pose)

    if p19.state_id ~= 702 then
        local v22 = rt.copy(p17.record.pose)

        for i = 0, #p16.bone_indices - 1 do
            local v23 = p18[p16.bone_indices[i + 1] + 1]

            if v23 == nil then
                error("IK original joint is absent from the current pose", 0)
            end

            v22[i + 1] = rt.copy(v23)
        end

        local v24 = compose_affine(p17.roots.animation_to_world, p17.record.pose[1])
        local v25 = inverse_rigid(v24)
        local v26

        if p19.state_id == 503 then
            v26 = v24
        else
            v24 = p19.physical_board
            v26 = p17.roots.board
            v25 = p17.roots.inverse_board
        end

        FootIkState.update(p16.state, {
            flags_2468 = p19.flags_2468,
            flags_2472 = p19.flags_2472,
            flags_2480 = p19.flags_2480,
            animation_to_world = p17.roots.animation_to_world,
            world_to_animation = p17.roots.world_to_animation,
            physical_board = v24,
            contact_board = v26,
            inverse_contact_board = v25,
            animation = p17.record.pose,
            original_animation = v22,
            targets = p17.targets,
            hips_world_position = rt.copy(p19.hips_world_position),
            contact_bone = p19.contact_bone,
            foot_bones = {
                p16.bone_indices[16],
                p16.bone_indices[20]
            },
            current_contacts = rt.copy(p19.current_contacts)
        }, p16.geometry, p16.settings, v21)
    end

    return {
        frames = v21
    }
end

function t1.load_settings(p20) -- line: 266
    -- upvalues: v1 (copy), Collections (copy)
    local function vector(p21) -- line: 267
        -- upvalues: p20 (copy), v1 (copy), Collections (copy)
        local v27 = Collections.words(p20, "physics_skeletonik", "default", p21, 4)

        buffer.writeu32(v1, 0, v27[1])

        local v29 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[2])

        local v31 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[3])

        local v33 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v27[4])

        return {
            v29,
            v31,
            v33,
            (buffer.readf32(v1, 0))
        }
    end

    local function scalar(p22) -- line: 271
        -- upvalues: p20 (copy), Collections (copy)
        return Collections.float(p20, "physics_skeletonik", "default", p22)
    end

    local v35 = Collections.float(p20, "physicsdeck", "default", "DeckWidth") * 0.5
    local v36 = Collections.float(p20, "physicsdeck", "default", "DeckMidLength") * 0.5
    local t5 = {
        minimum_degrees = Collections.float(p20, "physics_animation", "default", "IKMinAngle"),
        maximum_degrees = Collections.float(p20, "physics_animation", "default", "IKMaxAngle")
    }
    local IKOnPadding = vector("IKOnPadding")
    local IKOffPadding = vector("IKOffPadding")
    local FeetIKMaxBlendDeltaOut = Collections.float(p20, "physics_skeletonik", "default", "FeetIKMaxBlendDeltaOut")
    local FeetIKMaxBlendDelta = Collections.float(p20, "physics_skeletonik", "default", "FeetIKMaxBlendDelta")
    local PostIKPadding = vector("PostIKPadding")
    local IKBoneOnDeckBBox = vector("IKBoneOnDeckBBox")
    local FootOnDeckPadding = vector("FootOnDeckPadding")
    local WipeoutFeetOffset = Collections.float(p20, "physics_skeletonik", "default", "WipeoutFeetOffset")
    local v37 = Collections.float(p20, "physicsdeck", "default", "DeckFrontEndSize") + v36
    local DeckFrontEndAngle = Collections.float(p20, "physicsdeck", "default", "DeckFrontEndAngle")

    return {
        angle_limits = t5,
        blend = {
            hand_inner_padding = IKOnPadding,
            hand_outer_padding = IKOffPadding,
            external_blend_step = FeetIKMaxBlendDeltaOut,
            board_blend_step = FeetIKMaxBlendDelta
        },
        post_ik_padding = PostIKPadding,
        contact_bounds = IKBoneOnDeckBBox,
        foot_on_deck_padding = FootOnDeckPadding,
        wipeout_feet_offset = WipeoutFeetOffset,
        deck_half_width = v35,
        deck_half_length = v36,
        deck_total_half_length = v37,
        deck_front_angle_degrees = DeckFrontEndAngle
    }
end

return t1
