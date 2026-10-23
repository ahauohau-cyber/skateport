--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_general.rs (коммит 2e16697)
--
-- Original Skeleton::GeneralUpdate82BDCA38 and discontinuity reset82BE2798.
-- This operates on the same physical bodies later borrowed by the solver.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local rigid_body = require("./rigid_body")
local sar = require("./skeleton_animation_record")
local skeleton_body = require("./skeleton_body")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local compose_affine = sar.compose_affine
local transform_point = sar.transform_point
local SkeletonBody = skeleton_body.SkeletonBody
local SkeletonPhysicalRecord = skeleton_body.SkeletonPhysicalRecord

type Transform = sar.AnimationPartTransform
type F4 = { number }

local skeleton_general = {}

-- ///82BDCA50..CAB8: root-position derivative, two reciprocal refinements,
-- ///then history replacement. It is distinct from animation trajectory velocity.
-- ROBLOX: previous: &mut [f32; 4] -> таблица меняется на месте.
function skeleton_general.root_velocity(previous: F4, current: F4, dt: number): F4
	local difference = {}
	for i = 1, 4 do
		difference[i] = f32(current[i] - previous[i])
	end
	local inverse = native_arithmetic.reciprocal_estimate(dt)
	for _ = 1, 2 do
		inverse = mul_add(inverse, mul_add(-inverse, dt, 1.0), inverse)
	end
	local velocity = {}
	for i = 1, 4 do
		velocity[i] = f32(difference[i] * inverse)
		previous[i] = current[i]
	end
	return velocity
end

-- ///82BDCB50..CC18 uses its fixed-step literal, not the caller timestep.
-- ///The resulting displacement enters ApplyDisplacementToPart82BE7788, which
-- ///updates force accumulators and cooldown, rather than body translations.
function skeleton_general.apply_gravity_displacement(body: skeleton_body.SkeletonBody, processed_gravity: number)
	local step = from_bits(0x3C88_8889)
	local displacement = {}
	for i, value in { 0.0, -processed_gravity, 0.0, 0.0 } do
		displacement[i] = f32(f32(f32(value * 0.5) * step) * step)
	end
	for part = 0, 23 do
		SkeletonBody.apply_part_displacement(body, part, displacement)
	end
end

export type ResetObservation = {
	--Skeleton16208, current adjusted animation hips translation.
	local_hips: F4,
	--Skeleton16144 and16160 receive this value;16176 is zeroed.
	world_hips: F4,
}

local function reset_rates(body: skeleton_body.SkeletonBody, part: number, simulation: rigid_body.RetailSimulationStep)
	local rates = SkeletonBody.bodies_mut(body)[part + 1].rates
	rates.linear_velocity = vector.zero
	rates.angular_velocity = vector.zero
	--Original Reset copies the Simulation+144 gravity vector into forceXYZ;
	--it does not clear force to zero or reset energy/cooldown.
	rates.force_acceleration = simulation.gravity_acceleration
	rates.torque_acceleration = vector.zero
end

-- ///82BE2798: reset physical pose to the current mapped animation after a
-- ///target discontinuity. Reset rates exactly here; ordinary postphysics pose
-- ///correction must preserve rates and uses SkeletonBody::set_part_transform.
function skeleton_general.reset_to_animation(body: skeleton_body.SkeletonBody, animation: any, drive_pose: { Transform }, animation_to_world: Transform, com_frame: Transform, simulation: rigid_body.RetailSimulationStep): ResetObservation
	for part = 0, 23 do
		local world = compose_affine(animation_to_world, drive_pose[part + 1])
		SkeletonBody.set_part_transform(body, part, world)
		reset_rates(body, part, simulation)
	end
	for _, part in { 24, 25 } do
		SkeletonBody.set_part_transform(body, part, com_frame)
		reset_rates(body, part, simulation)
	end
	local local_hips = table.clone(drive_pose[24][4])
	local world_hips = transform_point(animation_to_world, local_hips)
	--82BEBBB0 obtains all26 current GetPartTransform results before clearing
	--their position/velocity histories and the four animation COM histories.
	local current = SkeletonBody.part_transforms(body)
	SkeletonPhysicalRecord.reset(body.record, current)
	sar.SkeletonAnimationRecord.reset_history(animation)
	return { local_hips = local_hips, world_hips = world_hips }
end

return skeleton_general
