--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/post_physics.rs (коммит 2e16697)
--
-- PostWipeoutCheck's feet82BF0680, hands82BF0C28 and external82BEDC10.

local rt = require("../../../rt")
local drive = require("./drive")
local physical_solve = require("./physical_solve")
local post_contact = require("./post_contact")
local settings_mod = require("./settings")
local state_mod = require("./state")
local native_arithmetic = require("../../physics/native_arithmetic")
local sar = require("../../physics/skeleton_animation_record")
local skeleton_body = require("../../physics/skeleton_body")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3
local compose_affine = sar.compose_affine
local copy_transform = sar.copy_transform
local SkeletonBody = skeleton_body.SkeletonBody
local LIMBS = state_mod.LIMBS

type Transform = sar.AnimationPartTransform
type F4 = { number }

local post_physics = {}

export type Input = {
	state_id: number,
	category_id: number,
	--Actual BoardBody868, used by original state200/201 hand/foot gates.
	board_body_flag_868: boolean,
	wipeout: boolean,
	flags_2468: number,
	flags_2484: number,
	--Processed2664 and2520, read only when2468bit18 is set.
	value_2664: number,
	state_2520: number,
	world_to_animation: Transform,
	--Actual board GetPartTransform, replaced by wobble-adjusted record when sampled.
	board: Transform,
}

local function sub(a: F4, b: F4): F4
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

local function feet(state: state_mod.FootIkState, body: skeleton_body.SkeletonBody, geometry: drive.Geometry, settings: settings_mod.Settings, post: post_contact.SettingsPost, input: Input, updated: { boolean })
	local effective_board = copy_transform(input.board)
	if bit32.band(input.flags_2484, bit32.lshift(1, 21)) ~= 0 then
		for _, axis in { 1, 2 } do
			local c = effective_board[axis]
			effective_board[axis] = { f32(c[1] * -1.0), f32(c[2] * -1.0), f32(c[3] * -1.0), f32(c[4] * -1.0) }
		end
	end
	local up = effective_board[2]
	local up_y = f32(up[1] * input.world_to_animation[1][2])
	up_y = mul_add(up[2], input.world_to_animation[2][2], up_y)
	up_y = mul_add(up[3], input.world_to_animation[3][2], up_y)
	local constrained = bit32.band(input.flags_2468, bit32.lshift(1, 18)) ~= 0
	if bit32.band(input.flags_2484, bit32.lshift(1, 20)) ~= 0 or post.minimum_board_up > up_y or (constrained and input.value_2664 > from_bits(0x3D23_D70A)) or (constrained and input.state_2520 == 500) then
		return
	end
	for limb = 1, 2 do
		local binding = LIMBS[limb]
		local adjacent = binding.parent_part :: number
		local frame = state.frames[limb]
		if frame.within_contact_bounds and not input.wipeout then
			frame.world = compose_affine(input.board, frame.board)
			frame.parent_world = compose_affine(input.board, frame.parent_board)
			local offset = sub(frame.parent_world[4], body.record.pose[adjacent + 1][4])
			if physical_solve.solve(body, geometry, adjacent, offset) then
				SkeletonBody.set_part_transform(body, binding.part, frame.world)
				SkeletonBody.set_part_transform(body, adjacent, frame.parent_world)
				updated[limb] = true
			end
		elseif not state.limbs[limb].external_target_set then
			local foot = copy_transform(body.record.pose[binding.part + 1])
			if dot3(foot[2], up) <= 0.0 then
				continue
			end
			local target = post_contact.target(effective_board, foot[4], body.record.pose[adjacent + 1][4], state.limbs[limb].part_position, input.wipeout, settings, post)
			if target == nil then
				continue
			end
			local distance = dot3(up, sub(target, foot[4]))
			local offset = { f32(up[1] * distance), f32(up[2] * distance), f32(up[3] * distance), f32(up[4] * distance) }
			if physical_solve.solve(body, geometry, adjacent, offset) then
				foot[4] = target
				SkeletonBody.set_part_transform(body, binding.part, foot)
				local adjacent_frame = copy_transform(body.record.pose[adjacent + 1])
				for lane = 1, 4 do
					adjacent_frame[4][lane] = f32(adjacent_frame[4][lane] + offset[lane])
				end
				SkeletonBody.set_part_transform(body, adjacent, adjacent_frame)
				updated[limb] = true
			end
		end
	end
end

function post_physics.update(state: state_mod.FootIkState, body: skeleton_body.SkeletonBody, geometry: drive.Geometry, settings: settings_mod.Settings, post: post_contact.SettingsPost, input: Input): { boolean }
	local updated = { false, false, false, false }
	if input.state_id ~= 702 then
		local airborne = input.state_id == 200 or input.state_id == 201
		if (not airborne or input.board_body_flag_868) and input.category_id ~= 500 then
			feet(state, body, geometry, settings, post, input, updated)
		end
		if airborne and input.board_body_flag_868 then
			for limb = 3, 4 do
				local frame = state.frames[limb]
				if frame.within_contact_bounds then
					frame.world = compose_affine(input.board, frame.board)
					local part = LIMBS[limb].part
					local offset = sub(frame.world[4], body.record.pose[part + 1][4])
					if physical_solve.solve(body, geometry, part, offset) then
						SkeletonBody.set_part_transform(body, part, frame.world)
						updated[limb] = true
					end
				end
			end
		end
	end
	--Always run the external-target pass, including state702.
	for limb = 1, 2 do
		if not (state.limbs[limb].external_blend <= 0.0) then
			local binding = LIMBS[limb]
			local adjacent = binding.parent_part :: number
			local offset = sub(state.frames[limb].parent_world[4], body.record.pose[adjacent + 1][4])
			if physical_solve.solve(body, geometry, adjacent, offset) then
				SkeletonBody.set_part_transform(body, binding.part, state.frames[limb].world)
				SkeletonBody.set_part_transform(body, adjacent, state.frames[limb].parent_world)
				updated[limb] = true
			end
		end
	end
	for limb = 1, 4 do
		state.external_targets[limb].normal_set = false
		state.limbs[limb].external_target_set = false
		state.limbs[limb].local_target_set = false
	end
	return updated
end

return post_physics
