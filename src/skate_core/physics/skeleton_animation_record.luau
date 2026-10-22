--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_animation_record.rs (коммит 2e16697)
--
-- Animation-record COM producer82BEBF88 and mass normalization82BEBAA8.
-- Skeleton embeds this source state at6464, so com_to_deck_world4544 is the
-- ProcessData82BD8918 input published from Skeleton11008 to Processed752.

local rt = require("../../rt")
local rigid_body = require("./rigid_body")

local f32 = rt.f32
local mul_add = rt.mul_add

type Vector3 = vector
type F4 = { number }

local skeleton_animation_record = {}

-- Native affine columns X,Y,Z,translation. Keep all four stored lanes;
-- UpdateAnimRecord copies24 complete transforms, not just the positions.
-- ROBLOX: [[f32; 4]; 4] -> таблица из 4 столбцов по 4 числа, индексы с 1.
export type AnimationPartTransform = { F4 }

function skeleton_animation_record.IDENTITY(): AnimationPartTransform
	return {
		{ 1.0, 0.0, 0.0, 0.0 },
		{ 0.0, 1.0, 0.0, 0.0 },
		{ 0.0, 0.0, 1.0, 0.0 },
		{ 0.0, 0.0, 0.0, 0.0 },
	}
end
local IDENTITY = skeleton_animation_record.IDENTITY

local function copy_transform(t: AnimationPartTransform): AnimationPartTransform
	return { table.clone(t[1]), table.clone(t[2]), table.clone(t[3]), table.clone(t[4]) }
end
skeleton_animation_record.copy_transform = copy_transform

function skeleton_animation_record.transform_point(transform: AnimationPartTransform, point: F4): F4
	local out = {}
	for i = 1, 4 do
		local x = mul_add(transform[1][i], point[1], transform[4][i])
		local y = mul_add(transform[2][i], point[2], x)
		out[i] = mul_add(transform[3][i], point[3], y)
	end
	return out
end
local transform_point = skeleton_animation_record.transform_point

-- Forward PhysicsParamBoneData frame from SkeletonData::Init82BD6E24..6E98.
-- The same sqrt(2), fused negative product and lane permutations are used by
-- RigidBody::DynamicUpdate. Keep the otherwise unused fourth rotation lanes:
-- native permute masks822FB8A0/B0/C0 duplicate Z.z, Y.x and X.y respectively.
-- This is the forward frame, not the inverse stored by the later init slice.
function skeleton_animation_record.physics_bone_frame(quaternion: F4, translation: F4): AnimationPartTransform
	local columns = rigid_body.basis_from_quaternion({ x = quaternion[1], y = quaternion[2], z = quaternion[3], w = quaternion[4] }).columns
	local ri, up, at = columns[1], columns[2], columns[3]
	return {
		{ ri[1], ri[2], ri[3], at[3] },
		{ up[1], up[2], up[3], up[1] },
		{ at[1], at[2], at[3], ri[2] },
		table.clone(translation),
	}
end

local function rotate_columns(parent: AnimationPartTransform, child: AnimationPartTransform): AnimationPartTransform
	local out = {}
	for column = 1, 4 do
		if column == 4 then
			out[4] = transform_point(parent, child[4])
		else
			local c = child[column]
			local col = {}
			for lane = 1, 4 do
				local x = f32(c[1] * parent[1][lane])
				local y = mul_add(c[2], parent[2][lane], x)
				col[lane] = mul_add(c[3], parent[3][lane], y)
			end
			out[column] = col
		end
	end
	return out
end

-- ProcessData82BD8BB4..8CAC: gather each named global animation bone, then
-- right-multiply its forward physics frame. Native maps names to hierarchy
-- indices in82BD6CB4..6CE4; the host loader provides those verified indices.
-- The result is the input to the following skeleton IK and adjustment stages,
-- which must run before UpdateAnimRecord for the final physical pose.
-- ROBLOX: bone_indices с нуля, как в Rust; Result -> (значение) или (nil, ошибка).
function skeleton_animation_record.map_animation_parts(
	global_bones: { AnimationPartTransform },
	bone_indices: { number },
	physics_frames: { AnimationPartTransform }
): ({ AnimationPartTransform }?, string?)
	for _, i in bone_indices do
		if i >= #global_bones then
			return nil, "physics skeleton bone index is outside the animation hierarchy"
		end
	end
	local out = {}
	for part = 1, 24 do
		out[part] = rotate_columns(global_bones[bone_indices[part] + 1], physics_frames[part])
	end
	return out, nil
end

-- Native affine product used by ProcessData and board-offset application.
function skeleton_animation_record.compose_affine(parent: AnimationPartTransform, child: AnimationPartTransform): AnimationPartTransform
	return rotate_columns(parent, child)
end

export type SkeletonAnimationMasses = {
	-- Native misleadingly calls these part masses. They are bone-box volumes
	-- before density and animated/ragdoll physical mass scaling.
	part_weights: { number },
	total: number,
	fractional: { number },
}

local SkeletonAnimationMasses = {}
skeleton_animation_record.SkeletonAnimationMasses = SkeletonAnimationMasses

-- 82BEBAA8: ordered24 scalar additions, one scalar single-precision divide,
-- then24 multiplies. No clamping, epsilon, density or re-normalization.
function SkeletonAnimationMasses.normalize(part_weights: { number }): SkeletonAnimationMasses
	local total = 0.0
	for i0 = 0, 23 do
		local weight = part_weights[i0 + 1]
		-- Preserve native operand order, including signed zero/NaN cases.
		-- ROBLOX: в Luau сложение коммутативно и для NaN; порядок оставлен как в Rust.
		if i0 % 8 == 0 or i0 % 8 == 7 then
			total = f32(weight + total)
		else
			total = f32(total + weight)
		end
	end
	local reciprocal = f32(1.0 / total)
	local fractional = {}
	for i = 1, 24 do
		fractional[i] = f32(part_weights[i] * reciprocal)
	end
	return { part_weights = table.clone(part_weights), total = total, fractional = fractional }
end

-- Full weight assignment slice82BE4900/82BE5428. Board part0 is weight0;
-- other parts use original PhysicsParamBoneData.size32, not collider size.
-- Shapes0/1/2 all use the same box product. Native unrecognized shapes>=3
-- retain the iteration's initialized0. A hat on head1 takes its own branch
-- and still uses the original head box product, excluding the hat volume.
function SkeletonAnimationMasses.from_bone_data(sizes: { Vector3 }, collision_shapes: { number }, head_has_hat: boolean): SkeletonAnimationMasses
	local weights = {}
	for i0 = 0, 23 do
		local i = i0 + 1
		if i0 == 0 or collision_shapes[i] >= 3 and not (i0 == 1 and head_has_hat) then
			weights[i] = 0.0
		else
			weights[i] = f32(f32(sizes[i].x * sizes[i].y) * sizes[i].z)
		end
	end
	return SkeletonAnimationMasses.normalize(weights)
end

export type SkeletonAnimationRecord = {
	pose: { AnimationPartTransform },
	centre_of_mass: F4,
	centre_of_mass_delta: F4,
	com_to_deck_world: F4,
	com_to_deck_world_delta: F4,
	reset_scalar: number,
}

local SkeletonAnimationRecord = {}
skeleton_animation_record.SkeletonAnimationRecord = SkeletonAnimationRecord

-- Constructor82BEB8C8 initializes24 animation transforms via82BF30C0,
-- then all four vectors and resetScalar5224 to0.
function SkeletonAnimationRecord.default(): SkeletonAnimationRecord
	local pose = {}
	for i = 1, 24 do
		pose[i] = IDENTITY()
	end
	return {
		pose = pose,
		centre_of_mass = { 0.0, 0.0, 0.0, 0.0 },
		centre_of_mass_delta = { 0.0, 0.0, 0.0, 0.0 },
		com_to_deck_world = { 0.0, 0.0, 0.0, 0.0 },
		com_to_deck_world_delta = { 0.0, 0.0, 0.0, 0.0 },
		reset_scalar = 0.0,
	}
end

-- Animation fields of SkeletonState::Reset82BEBBB0. The function leaves
-- animation transforms, fractional masses and resetScalar unchanged.
function SkeletonAnimationRecord.reset_history(self: SkeletonAnimationRecord)
	self.centre_of_mass = { 0.0, 0.0, 0.0, 0.0 }
	self.centre_of_mass_delta = { 0.0, 0.0, 0.0, 0.0 }
	self.com_to_deck_world = { 0.0, 0.0, 0.0, 0.0 }
	self.com_to_deck_world_delta = { 0.0, 0.0, 0.0, 0.0 }
end

function SkeletonAnimationRecord.update(
	self: SkeletonAnimationRecord,
	pose: { AnimationPartTransform },
	animation_to_board: AnimationPartTransform,
	masses: SkeletonAnimationMasses
)
	local copied = {}
	for i = 1, 24 do
		copied[i] = copy_transform(pose[i])
	end
	self.pose = copied
	local com = { 0.0, 0.0, 0.0, 0.0 }
	for p = 1, 24 do
		local part, weight = copied[p], masses.fractional[p]
		for lane = 1, 4 do
			com[lane] = mul_add(part[4][lane], weight, com[lane])
		end
	end
	local delta = {}
	for i = 1, 4 do
		delta[i] = f32(com[i] - self.centre_of_mass[i])
	end
	self.centre_of_mass_delta = delta
	self.centre_of_mass = com
	-- Native transforms both points separately then subtracts, retaining
	-- each affine FMA's rounding; do not rotate their difference instead.
	local transformed_com = transform_point(animation_to_board, com)
	local transformed_deck = transform_point(animation_to_board, copied[1][4])
	local relative, relative_delta = {}, {}
	for i = 1, 4 do
		relative[i] = f32(transformed_com[i] - transformed_deck[i])
		relative_delta[i] = f32(f32(relative[i] - self.com_to_deck_world[i]) * self.reset_scalar)
	end
	self.com_to_deck_world_delta = relative_delta
	self.com_to_deck_world = relative
	self.reset_scalar = 1.0
end

function SkeletonAnimationRecord.com_to_deck(self: SkeletonAnimationRecord): Vector3
	local v = self.com_to_deck_world
	return vector.create(v[1], v[2], v[3])
end

return skeleton_animation_record
