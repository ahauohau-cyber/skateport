--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/joints.rs (коммит 2e16697)
--
-- SkeletonBody::InitJoints82BE5B30 and SetUpNormalJointLimits82BE58A8.
-- Frames attach the child to its nearest physical ancestor; the initial
-- animation bone poses and authored volume frames are distinct inputs.

local rt = require("../../../rt")
local assembly = require("../assembly")
local constraint_batch = require("../constraint_batch")
local drive_frames = require("../drive_frames")
local joint_builder = require("../joint_builder")
local joint_records = require("../joint_records")
local native_arithmetic = require("../native_arithmetic")
local rigid_body = require("../rigid_body")
local sar = require("../skeleton_animation_record")
local skeleton_root = require("../skeleton_root")
local solver = require("../solver")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local compose_affine = sar.compose_affine
local physics_bone_frame = sar.physics_bone_frame
local inverse_rigid = skeleton_root.inverse_rigid

type AnimationPartTransform = sar.AnimationPartTransform
type BodySnapshot = assembly.BodySnapshot

-- ROBLOX: константы из mod.rs продублированы, чтобы не было циклического require.
local ANIMATION_PART_COUNT = 24
local JOINT_COUNT = 22

local joints = {}

export type JointBone = {
	parent_orientation: { number },
	joint_orientation: { number },
	volume_frame: AnimationPartTransform,
	swing_limit: number,
	twist_limit: number,
}

export type JointSettings = {
	ball_joint: boolean,
	swing_angle: number,
	twist_angle: number,
	swing_ragdoll: number,
	twist_ragdoll: number,
}

export type SkeletonJointSettings = {
	displacement_limit: { number },
	twist_displacement_limit: number,
	swing_displacement_limit: number,
	enforce_swing_free: boolean,
	enforce_twist_free: boolean,
}

-- ROBLOX: parent/child — индексы частей с нуля.
export type SkeletonJoint = {
	parent: number,
	child: number,
	parameters: joint_records.RetailJointParametersRaw,
	frames: joint_records.RetailJointFramesRaw,
}

export type SkeletonJoints = {
	records: { SkeletonJoint },
}

local SkeletonJoints = {}
joints.SkeletonJoints = SkeletonJoints

local function inverse_native_step(): number
	local step = from_bits(0x3C88_8889) --820849C8
	local reciprocal = native_arithmetic.reciprocal_estimate(step)
	for _ = 1, 2 do
		reciprocal = mul_add(reciprocal, mul_add(-reciprocal, step, 1.0), reciprocal)
	end
	return reciprocal
end

local function minimum_angle(value: number): number
	local minimum = from_bits(0x3C23_D70A)
	return if f32(value - minimum) >= 0.0 then value else minimum
end

-- ROBLOX: words[offset..offset+8] -> запись в таблицу с явным смещением (с нуля).
local function pack_frame(words: { number }, offset: number, frame: AnimationPartTransform, anchor: { number })
	local q = drive_frames.retail_quaternion_from_basis({
		columns = {
			{ frame[1][1], frame[1][2], frame[1][3] },
			{ frame[2][1], frame[2][2], frame[2][3] },
			{ frame[3][1], frame[3][2], frame[3][3] },
		},
	})
	words[offset + 1], words[offset + 2], words[offset + 3], words[offset + 4] = to_bits(q.x), to_bits(q.y), to_bits(q.z), to_bits(q.w)
	for i = 1, 4 do
		words[offset + 4 + i] = to_bits(anchor[i])
	end
end

local function joint_body(body: BodySnapshot): joint_builder.RetailJointBodyInput
	local rates = body.rates
	return {
		reaction_guest_address = 0,
		state = body.state_flags,
		orientation = rates.orientation,
		center_of_mass = rates.position,
		basis = rates.basis,
		linear_velocity = rates.linear_velocity,
		angular_velocity = rates.angular_velocity,
		force_acceleration = rates.force_acceleration,
		torque_acceleration = rates.torque_acceleration,
		inverse_mass = body.inertia.inverse_mass,
		world_inverse_inertia = rigid_body.pack_world_inverse_inertia(rates.world_inverse_inertia),
	}
end

-- ROBLOX: Result<Self, &str> -> SkeletonJoints или rt.raise(строка).
-- parents: [Option<usize>; 24] -> массив, где отсутствие родителя — false.
function SkeletonJoints.new(initial_bones: { AnimationPartTransform }, parents: { number | false }, bones: { JointBone }, settings: { JointSettings }, global: SkeletonJointSettings): SkeletonJoints
	local records: { SkeletonJoint } = {}
	for child = 0, ANIMATION_PART_COUNT - 1 do
		local parent = parents[child + 1]
		if parent == false then
			continue
		end
		local p = parent :: number
		if p >= ANIMATION_PART_COUNT or p == child then
			rt.raise("Invalid physical skeleton joint parent")
		end
		local setting = settings[#records + 1]
		if setting == nil then
			rt.raise("Too many physical skeleton joints")
		end
		local bone = bones[child + 1]
		local inverse_child_volume = inverse_rigid(bone.volume_frame)
		local inverse_parent_volume = inverse_rigid(bones[p + 1].volume_frame)
		local parent_orientation = physics_bone_frame(bone.parent_orientation, { 0.0, 0.0, 0.0, 0.0 })
		local joint_orientation = physics_bone_frame(bone.joint_orientation, { 0.0, 0.0, 0.0, 0.0 })
		local parent_joint = compose_affine(inverse_parent_volume, inverse_rigid(parent_orientation))
		local relative_bones = compose_affine(inverse_rigid(initial_bones[p + 1]), initial_bones[child + 1])
		local parent_anchor = compose_affine(inverse_parent_volume, relative_bones)[4]
		local child_frame = compose_affine(inverse_child_volume, joint_orientation)
		local parent_frame = compose_affine(parent_joint, joint_orientation)
		local frames = { words = table.create(20, 0) }
		pack_frame(frames.words, 0, child_frame, inverse_child_volume[4])
		pack_frame(frames.words, 8, parent_frame, parent_anchor)
		-- InitJoints passes the identity matrix to SetLinearFrame82BD3858.
		frames.words[20] = to_bits(1.0)

		local parameters = { words = table.create(16, 0) }
		local frequency = inverse_native_step()
		for i = 1, 4 do
			parameters.words[4 + i] = to_bits(f32(global.displacement_limit[i] * frequency))
		end
		local scalar_frequency = from_bits(0x426F_FFFF)
		parameters.words[9] = to_bits(f32(global.twist_displacement_limit * scalar_frequency))
		parameters.words[10] = to_bits(f32(global.swing_displacement_limit * scalar_frequency))
		parameters.words[15] = if setting.ball_joint or global.enforce_swing_free then 4 else 1
		parameters.words[16] = if setting.ball_joint or global.enforce_twist_free then 2 else 1
		-- SetUpNormal runs after InitJoints and writes limits even for a
		-- free/ball joint. It does not replace the mode selectors.
		local swing = minimum_angle(f32(bone.swing_limit * setting.swing_angle))
		local twist = minimum_angle(f32(bone.twist_limit * setting.twist_angle))
		parameters.words[11] = to_bits(swing)
		parameters.words[12] = to_bits(twist)
		parameters.words[13] = to_bits(trigonometry.cos(swing))
		parameters.words[14] = to_bits(trigonometry.cos(twist))
		table.insert(records, { parent = p, child = child, parameters = parameters, frames = frames })
	end
	if #records ~= JOINT_COUNT then
		rt.raise("Physical skeleton requires22 joints")
	end
	return { records = records }
end

-- /// Append these to the same constraint pass as board contacts/joints/drives.
-- /// Reaction indices are supplied by the unified simulation owner.
function SkeletonJoints.build(self: SkeletonJoints, bodies: { BodySnapshot }, reaction_base: number, time_step: number): { solver.JointConstraint }
	return constraint_batch.compile_active(self.records, function(record: SkeletonJoint)
		return bodies[record.child + 1].state_flags, bodies[record.parent + 1].state_flags
	end, function(record: SkeletonJoint): solver.JointConstraint
		return {
			jacobian = joint_builder.build_retail_joint_jacobian({
				parameters = record.parameters,
				frames = record.frames,
				body_a = joint_body(bodies[record.child + 1]),
				body_b = joint_body(bodies[record.parent + 1]),
				time_step = time_step,
				joint_guest_address = 0,
			}),
			reaction_a = reaction_base + record.child,
			reaction_b = reaction_base + record.parent,
		}
	end)
end

return joints
