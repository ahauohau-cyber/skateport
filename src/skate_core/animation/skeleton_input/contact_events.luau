--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/skeleton_input/contact_events.rs (коммит 2e16697)
--
-- Complete kind3/status&12 dispatch 82BDAAA0..82BDACE4.
-- Bone identity is resolved even for an unknown event name. Push speed comes
-- from the evaluated trajectory displacement, not a button-driven force.

local rt = require("../../../rt")
local native_arithmetic = require("../../physics/native_arithmetic")
local name_mod = require("./name")
local attributes = require("../output/attributes")
local scalar_attributes = require("./scalar_attributes")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local contact_events = {}

export type ContactEventState = {
	-- ProcessedPhysIn 2560, including native GetBone's -1 result.
	bone: number,
	-- ProcessedPhysIn 2608, consumed by the native push-force calculation.
	push_speed: number,
}

-- ROBLOX: trajectory_bone — индекс кости с нуля.
export type ContactEventPose = {
	bone_names: { { number } },
	hierarchy: { { { number } } },
	-- Skeleton 11716, assigned by SkeletonData initialization.
	trajectory_bone: number,
	-- Skeleton 4748: animation index of physical part 19 (RIGHTTOEBASE).
	right_toe_bone: number,
	-- Skeleton 11704: current animation/physics input timestep.
	timestep: number,
}

local PUSH = name_mod.encode("push_contact")
local BRAKE = name_mod.encode("brake_contact")
local RIGHT_GRAB = name_mod.encode("right_hand_grab")
local LEFT_GRAB = name_mod.encode("left_hand_grab")
local RIGHT_HAND = name_mod.encode("righthand")
local eq = attributes.name_eq

local function replace(flags: number, bit: number, set: boolean): number
	return bit32.bor(bit32.band(flags, bit32.bnot(bit32.lshift(1, bit))), if set then bit32.lshift(1, bit) else 0)
end

-- ROBLOX: Result<(), String> -> rt.raise(строка).
function contact_events.dispatch(attribute: attributes.AnimationAttribute, pose: ContactEventPose, fields: scalar_attributes.ScalarAttributeInputs, state: ContactEventState)
	if attribute.kind ~= 3 or bit32.band(attribute.status, 12) == 0 then
		return
	end
	local words = {}
	for i = 1, 6 do
		local w = attribute.payload[i]
		if w == false or w == nil then
			rt.raise("Active animation bone event has incomplete payload")
		end
		words[i] = w :: number
	end
	local name = { words[1], words[2], words[3], words[4], words[5] }
	local strength = from_bits(words[6])
	state.bone = -1
	for i, bone in pose.bone_names do
		if eq(bone, name) then
			state.bone = i - 1
			break
		end
	end
	if eq(attribute.name, PUSH) then
		fields.flags2468 = bit32.bor(fields.flags2468, bit32.lshift(1, 27))
		fields.flags2468 = replace(fields.flags2468, 26, state.bone == pose.right_toe_bone)
		fields.flags2468 = replace(fields.flags2468, 25, strength == 1.0)
		fields.flags2468 = replace(fields.flags2468, 24, strength == -1.0)
		local m = pose.hierarchy[pose.trajectory_bone + 1]
		if m == nil then
			rt.raise("Push contact requires the actual animation trajectory bone")
		end
		local translation = m[4]
		local squared = native_arithmetic.dot3(translation, translation)
		local inverse = native_arithmetic.reciprocal_square_root_estimate(squared)
		for _ = 1, 2 do
			inverse = mul_add(f32(inverse * 0.5), mul_add(-squared, f32(inverse * inverse), 1.0), inverse)
		end
		-- Native clears a zero-length result before multiplying by scalar
		-- fdivs(1,dt). Estimate arithmetic remains hardware-unverified.
		local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
		local speed = f32(length * f32(1.0 / pose.timestep))
		state.push_speed = if strength == 1.0 then speed else 0.0
	elseif eq(attribute.name, BRAKE) then
		fields.flags2468 = bit32.bor(fields.flags2468, bit32.lshift(1, 28))
		fields.flags2468 = replace(fields.flags2468, 30, strength == 1.0)
		fields.flags2468 = replace(fields.flags2468, 23, strength == -1.0)
	elseif eq(attribute.name, RIGHT_GRAB) or eq(attribute.name, LEFT_GRAB) then
		-- The payload bone name, not the event's left/right label, selects it.
		fields.flags2472 = bit32.bor(fields.flags2472, if eq(name, RIGHT_HAND) then 0x100 else 0x80)
	end
end

return contact_events
