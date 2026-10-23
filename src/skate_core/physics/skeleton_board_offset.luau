--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_board_offset.rs (коммит 2e16697)
--
-- Complete Skeleton::UpdateSkateboardOffsetTransform82BDD630 and
-- SkeletonIK::AddOffsetTransform82BF1C68. Counters are animation updates.

local rt = require("../../rt")
local board_motion_output = require("./board_motion_output")
local native_arithmetic = require("./native_arithmetic")
local sar = require("./skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add
local inverse_length_squared = board_motion_output.inverse_length_squared
local dot3 = native_arithmetic.dot3
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine
local copy_transform = sar.copy_transform

type AnimationPartTransform = sar.AnimationPartTransform

local skeleton_board_offset = {}

export type SkateboardOffset = {
	transform: AnimationPartTransform,
	orientation_frames: number,
	height_frames: number,
	orientation_refreshed: boolean,
	height_refreshed: boolean,
}

local SkateboardOffset = {}
skeleton_board_offset.SkateboardOffset = SkateboardOffset

-- ROBLOX: impl Default.
function SkateboardOffset.default(): SkateboardOffset
	-- Skeleton constructor82BD76E8..7708 and82BD79A0..79BC.
	return {
		transform = IDENTITY(),
		orientation_frames = 0.0,
		height_frames = 0.0,
		orientation_refreshed = false,
		height_refreshed = false,
	}
end

-- /// The offboard, landing-on-board and grind-air producers refresh both
-- /// channels for15 updates after writing their independently calculated frame.
function SkateboardOffset.refresh_transform(self: SkateboardOffset, transform: AnimationPartTransform)
	self.transform = copy_transform(transform)
	self.orientation_frames = 15.0
	self.height_frames = 15.0
	self.orientation_refreshed = true
	self.height_refreshed = true
end

-- /// LandingAdjust writes only Y and its own duration, preserving X/Z/basis.
function SkateboardOffset.refresh_height(self: SkateboardOffset, height: number, frames: number)
	self.transform[4][2] = height
	self.height_frames = frames
	self.height_refreshed = true
end

-- /// Update decay first, then apply the resulting offset to the board and
-- /// four IK targets. Positive counters select application before decrement.
-- ROBLOX: board_pose: &mut -> ячейка { value }; targets меняются на месте.
function SkateboardOffset.update(self: SkateboardOffset, board_pose: { value: AnimationPartTransform }, targets: { AnimationPartTransform })
	local apply = false
	if self.orientation_frames > 0.0 then
		apply = true
		if not self.orientation_refreshed then
			local ratio = f32(f32(self.orientation_frames - 1.0) / self.orientation_frames)
			local weight = f32(ratio * ratio)
			local identity_weight = f32(1.0 - weight)
			local identity = IDENTITY()
			for axis = 1, 3 do
				local column = self.transform[axis]
				for lane = 1, 4 do
					column[lane] = mul_add(column[lane], weight, f32(identity[axis][lane] * identity_weight))
				end
			end
			-- vrlimi mask4 retains Y. X/Z/W belong to orientation decay.
			for _, lane in { 1, 3, 4 } do
				self.transform[4][lane] = f32(self.transform[4][lane] * weight)
			end
			local unnormalized = copy_transform(self.transform)
			-- Native Gram-Schmidt traverses At,Up,Ri in that order.
			for axis = 3, 1, -1 do
				local vector = table.clone(unnormalized[axis])
				for prior = 3, axis + 1, -1 do
					local projection = dot3(self.transform[prior], unnormalized[axis])
					for lane = 1, 4 do
						vector[lane] = f32(vector[lane] - f32(self.transform[prior][lane] * projection))
					end
				end
				local reciprocal = inverse_length_squared(dot3(vector, vector), 2)
				self.transform[axis] = { f32(vector[1] * reciprocal), f32(vector[2] * reciprocal), f32(vector[3] * reciprocal), f32(vector[4] * reciprocal) }
			end
			self.orientation_frames = f32(self.orientation_frames - 1.0)
		end
	end
	if self.height_frames > 0.0 then
		apply = true
		if not self.height_refreshed then
			local ratio = f32(f32(self.height_frames - 1.0) / self.height_frames)
			self.transform[4][2] = f32(self.transform[4][2] * f32(ratio * ratio))
			self.height_frames = f32(self.height_frames - 1.0)
		end
	end
	if apply then
		board_pose.value = compose_affine(self.transform, board_pose.value)
		for i, target in targets do
			targets[i] = compose_affine(self.transform, target)
		end
	end
	self.orientation_refreshed = false
	self.height_refreshed = false
end

return skeleton_board_offset
