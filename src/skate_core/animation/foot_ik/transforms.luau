--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/transforms.rs (коммит 2e16697)
--
-- Animated portion of CalculateInitialPartTransforms82BEDF08.

local rt = require("../../../rt")
local status = require("./status")
local sar = require("../../physics/skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine

type Transform = sar.AnimationPartTransform

local transforms = {}

-- ROBLOX: part/parent_part — индексы частей с нуля; Option -> число или nil.
export type LimbBinding = {
	-- SkeletonIK1120: the physics volume driven by this target.
	part: number,
	-- SkeletonIK1136: optional adjacent volume receiving the same adjustment.
	parent_part: number?,
}

export type LimbFrames = {
	-- SkeletonIK864, from the actual reparented animation target.
	target: Transform,
	-- SkeletonIK1152; animated world frame, then blended/contact-adjusted.
	world: Transform,
	-- SkeletonIK1408: externally supplied target in world space.
	external_world: Transform,
	-- SkeletonIK1664: target relative to the animated board.
	board: Transform,
	-- SkeletonIK2240, optional adjacent volume in world space.
	parent_world: Transform,
	-- SkeletonIK2496: adjacent volume's external target.
	external_parent_world: Transform,
	-- SkeletonIK2752: adjacent volume relative to the animated board.
	parent_board: Transform,
	-- SkeletonIK3120: animated target lies within the cached contact box.
	within_contact_bounds: boolean,
}

local LimbFrames = {}
transforms.LimbFrames = LimbFrames

-- ROBLOX: impl Default.
function LimbFrames.default(): LimbFrames
	--82BED780 initializes every retained affine frame to identity.
	return {
		target = IDENTITY(),
		world = IDENTITY(),
		external_world = IDENTITY(),
		board = IDENTITY(),
		parent_world = IDENTITY(),
		external_parent_world = IDENTITY(),
		parent_board = IDENTITY(),
		within_contact_bounds = false,
	}
end

-- ///82BEDF5C..DFEC and E1B4..E260: rigid inverse, transpose XYZ and zero W;
-- /// translation uses negative position with Z multiply, Y FMA, then X FMA.
-- /// This deliberately does not introduce a general scale/shear inverse.
function transforms.inverse_rigid(source: Transform): Transform
	local result = IDENTITY()
	for axis = 1, 3 do
		result[axis] = { source[1][axis], source[2][axis], source[3][axis], 0.0 }
	end
	local s = source[4]
	local translation = { f32(0.0 - s[1]), f32(0.0 - s[2]), f32(0.0 - s[3]), f32(0.0 - s[4]) }
	local out = {}
	for i = 1, 4 do
		local z = f32(translation[3] * result[3][i])
		local y = mul_add(translation[2], result[2][i], z)
		out[i] = mul_add(translation[1], result[1][i], y)
	end
	result[4] = out
	return result
end
local inverse_rigid = transforms.inverse_rigid

-- /// Prepare the animated frames after this limb's CalculateExternalIKOffset
-- /// stage. External/local modes retain their separately calculated frames.
-- /// The full controller calls both stages in native limb order.
function transforms.prepare_animation_target(limb: status.LimbStatus, frames: LimbFrames, binding: LimbBinding, animation: { Transform }, animation_to_world: Transform, inverse_animation_board: Transform, contact_bounds: { number })
	if limb.mode ~= "OnDeck" and not (limb.board_blend > 0.0) and limb.external_blend >= 1.0 then
		return
	end
	local animated = animation[binding.part + 1]
	frames.board = compose_affine(inverse_animation_board, frames.target)
	limb.part_position = table.clone(frames.board[4])
	frames.world = compose_affine(animation_to_world, animated)
	-- Native comparisons reject only a strict bound violation; NaNs do not
	-- become a host-side exclusion. The fourth stored lane is excluded.
	local within = true
	for i = 1, 3 do
		if limb.part_position[i] > contact_bounds[i] or -contact_bounds[i] > limb.part_position[i] then
			within = false
		end
	end
	frames.within_contact_bounds = within
	local parent = binding.parent_part
	if parent ~= nil then
		local relative = compose_affine(inverse_rigid(animated), animation[parent + 1])
		frames.parent_board = compose_affine(frames.board, relative)
		frames.parent_world = compose_affine(frames.world, relative)
	end
end

return transforms
