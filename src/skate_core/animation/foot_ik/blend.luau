--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/blend.rs (коммит 2e16697)
--
-- SkeletonIK::BlendTransforms82BEEEB8.

local rt = require("../../../rt")
local m = require("./math")
local status = require("./status")
local transforms = require("./transforms")
local sar = require("../../physics/skeleton_animation_record")
local skeleton_root = require("../../physics/skeleton_root")

local f32 = rt.f32
local mul_add = rt.mul_add
local interpolate, interpolate_affine = m.interpolate, m.interpolate_affine
local compose_affine = sar.compose_affine
local transform_point = sar.transform_point
local copy_transform = sar.copy_transform
local orthonormalize = skeleton_root.orthonormalize

type Transform = sar.AnimationPartTransform

local blend = {}

local function board_blend(original: Transform, target: Transform, weight: number): Transform
	local translation = {}
	for lane = 1, 4 do
		translation[lane] = mul_add(target[4][lane], weight, f32(original[4][lane] * f32(1.0 - weight)))
	end
	-- Each source frame is orthonormalized independently in Z/Y/X order before
	-- the matrix interpolation call; translation is replaced afterwards.
	local a = orthonormalize(original)
	local b = orthonormalize(target)
	a[4] = { 0.0, 0.0, 0.0, 0.0 }
	b[4] = { 0.0, 0.0, 0.0, 0.0 }
	local output = interpolate(a, b, weight)
	output[4] = translation
	return output
end

function blend.update(statuses: { status.LimbStatus }, frames: { transforms.LimbFrames }, bindings: { transforms.LimbBinding }, physical_board: Transform, animation_to_world: Transform, animated_board: Transform)
	-- IK160 supplies only the physical board rotation. Translation comes from
	-- the actual animation record's board transformed through IK32.
	local board = copy_transform(physical_board)
	board[4] = transform_point(animation_to_world, animated_board[4])
	for i, limb in statuses do
		local frame = frames[i]
		local binding = bindings[i]
		if limb.mode == "Disabled" then
			continue
		end
		if limb.board_blend > 0.0 then
			local target = compose_affine(board, frame.board)
			frame.world = board_blend(frame.world, target, limb.board_blend)
			if binding.parent_part ~= nil then
				local parent_target = compose_affine(board, frame.parent_board)
				frame.parent_world = board_blend(frame.parent_world, parent_target, limb.board_blend)
			end
		end
		if limb.mode == "External" or limb.mode == "Local" then
			if limb.external_blend >= 1.0 then
				frame.world = copy_transform(frame.external_world)
				frame.parent_world = copy_transform(frame.external_parent_world)
			else
				-- The native external stage also updates the retained parent
				-- frame for a limb without a parent, including at zero weight.
				frame.world = interpolate_affine(frame.world, frame.external_world, limb.external_blend)
				frame.parent_world = interpolate_affine(frame.parent_world, frame.external_parent_world, limb.external_blend)
			end
		end
	end
end

return blend
