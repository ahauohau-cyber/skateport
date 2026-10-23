--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/external.rs (коммит 2e16697)
--
-- SkeletonIK::CalculateExternalIKOffset82BEE390.

local rt = require("../../../rt")
local m = require("./math")
local status = require("./status")
local transforms = require("./transforms")
local sar = require("../../physics/skeleton_animation_record")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local axis_rotation, cross, length, limit_length, reciprocal = m.axis_rotation, m.cross, m.length, m.limit_length, m.reciprocal
local inverse_rigid = transforms.inverse_rigid
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine
local transform_point = sar.transform_point
local asin = trigonometry.asin

type Transform = sar.AnimationPartTransform
type F4 = { number }

local external = {}

export type ExternalTarget = {
	-- SkeletonIK544 /608; setters distinguish the supplied coordinate space.
	world_position: F4,
	animation_position: F4,
	-- SkeletonIK736,800,828. The normal is measured against world up.
	normal: F4,
	normal_set: boolean,
	normal_blend: number,
}

local ExternalTarget = {}
external.ExternalTarget = ExternalTarget

-- ROBLOX: #[derive(Default)].
function ExternalTarget.default(): ExternalTarget
	return {
		world_position = { 0.0, 0.0, 0.0, 0.0 },
		animation_position = { 0.0, 0.0, 0.0, 0.0 },
		normal = { 0.0, 0.0, 0.0, 0.0 },
		normal_set = false,
		normal_blend = 0.0,
	}
end

function external.update(target: ExternalTarget, limb: status.LimbStatus, frames: transforms.LimbFrames, binding: transforms.LimbBinding, animation: { Transform }, animation_to_world: Transform, world_to_animation: Transform)
	local animated = animation[binding.part + 1]
	local original = compose_affine(animation_to_world, animated)
	local rotation = IDENTITY()
	if target.normal_blend > 0.0 then
		-- Native v16 is the fixed Y basis82139A20, not the animated limb's up.
		local axis = cross({ 0.0, 1.0, 0.0, 0.0 }, target.normal)
		local magnitude = length(axis)
		if magnitude > f32(0.05) then
			local inverse = reciprocal(magnitude, 2)
			local unit = { f32(inverse * axis[1]), f32(inverse * axis[2]), f32(inverse * axis[3]), f32(inverse * axis[4]) }
			local angle = asin(magnitude)
			angle = if f32(f32(-0.71) - angle) >= 0.0 then f32(-0.71) else angle
			angle = if f32(f32(0.71) - angle) >= 0.0 then angle else f32(0.71)
			rotation = axis_rotation(unit, f32(angle * target.normal_blend))
		end
		if not target.normal_set then
			local next_ = f32(target.normal_blend - f32(0.2))
			target.normal_blend = if -next_ >= 0.0 then 0.0 else next_
		end
	end
	if limb.mode == "Local" then
		local weight = limb.target_blend
		local desired = {}
		for lane = 1, 4 do
			desired[lane] = mul_add(f32(target.animation_position[lane] - animated[4][lane]), weight, f32(limb.external_target_local_delta[lane] * f32(1.0 - weight)))
		end
		local diff = {}
		for lane = 1, 4 do
			diff[lane] = f32(desired[lane] - limb.external_target_local_delta[lane])
		end
		local change = limit_length(diff, f32(0.025))
		for lane = 1, 4 do
			limb.external_target_local_delta[lane] = f32(limb.external_target_local_delta[lane] + change[lane])
			-- The source publishes desired before its history limit. Do not
			-- replace this with the separately limited retained delta.
			target.animation_position[lane] = f32(animated[4][lane] + desired[lane])
		end
		target.world_position = transform_point(animation_to_world, target.animation_position)
	else
		target.animation_position = transform_point(world_to_animation, target.world_position)
	end
	local diff = {}
	for lane = 1, 4 do
		diff[lane] = f32(target.world_position[lane] - original[4][lane])
	end
	local offset = limit_length(diff, f32(0.7))
	local from_origin = IDENTITY()
	local o = original[4]
	from_origin[4] = {}
	for i = 1, 4 do
		from_origin[4][i] = from_bits(bit32.bxor(to_bits(o[i]), 0x8000_0000))
	end
	local rotated = compose_affine(rotation, from_origin)
	local to_origin = IDENTITY()
	to_origin[4] = { f32(o[1] + offset[1]), f32(o[2] + offset[2]), f32(o[3] + offset[3]), f32(o[4] + offset[4]) }
	local adjustment = compose_affine(to_origin, rotated)
	frames.external_world = compose_affine(adjustment, original)
	local parent = binding.parent_part
	if parent ~= nil then
		local relative = compose_affine(inverse_rigid(animated), animation[parent + 1])
		frames.external_parent_world = compose_affine(frames.external_world, relative)
	end
end

return external
