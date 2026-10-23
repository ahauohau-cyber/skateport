--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/contact.rs (коммит 2e16697)
--
-- Foot contact history and correction82BEFC80, helpers82BF04C8/82BF0558.

local rt = require("../../../rt")
local status = require("./status")
local transforms = require("./transforms")
local sar = require("../../physics/skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local transform_point = sar.transform_point

type Transform = sar.AnimationPartTransform
type F4 = { number }

local contact_mod = {}

export type FootContact = {
	-- SkeletonIK3104:0 pending,1 previous query hit,2 previous query missed.
	query_state: number,
	position: F4,
	desired_offset: number,
	offset: number,
}

export type ContactState = {
	feet: { FootContact },
	--3184 persists until Reset;3185 is cleared at each UpdateContact entry.
	support_failed: boolean,
	support_failed_this_update: boolean,
}

local FootContact = {}
contact_mod.FootContact = FootContact

-- ROBLOX: #[derive(Default)].
function FootContact.default(): FootContact
	return { query_state = 0, position = { 0.0, 0.0, 0.0, 0.0 }, desired_offset = 0.0, offset = 0.0 }
end

local ContactState = {}
contact_mod.ContactState = ContactState

function ContactState.default(): ContactState
	return { feet = { FootContact.default(), FootContact.default() }, support_failed = false, support_failed_this_update = false }
end

-- ROBLOX: current_contacts: [Option<[f32; 4]>; 2] -> массив, где отсутствие — false.
export type ContactInput = {
	flags_2468: number,
	contact_bone: number,
	foot_bones: { number },
	hips_world_position: F4,
	inverse_board: Transform,
	board: Transform,
	-- Actual cached line tests from Processed960/1008. Current observations
	-- replace the retained query only AFTER the previous query is consumed.
	current_contacts: { F4 | false },
}

local function contact_offset(board: Transform, offset: number): F4
	local out = {}
	for i = 1, 4 do
		local x = f32(board[1][i] * 0.0)
		local y = mul_add(board[2][i], offset, x)
		out[i] = mul_add(board[3][i], 0.0, y)
	end
	return out
end

-- ///82BF0558: compare both positions in inverse-board space, retaining the
-- ///separate point transforms and the .025 foot-surface distance adjustment.
local function distance_to_contact(contact: FootContact, frame: transforms.LimbFrames, board: Transform, inverse: Transform): number
	local local_contact = transform_point(inverse, contact.position)
	local delta = contact_offset(board, contact.offset)
	local foot = {}
	for i = 1, 4 do
		foot[i] = f32(frame.world[4][i] + delta[i])
	end
	local local_foot = transform_point(inverse, foot)
	return f32(f32(local_foot[2] - from_bits(0x3CCC_CCCD)) - local_contact[2])
end

local function add_offset(frame: transforms.LimbFrames, board: Transform, offset: number)
	local delta = contact_offset(board, offset)
	for i, value in delta do
		frame.world[4][i] = f32(frame.world[4][i] + value)
		frame.parent_world[4][i] = f32(frame.parent_world[4][i] + value)
	end
end

local function select(test: number, nonnegative: number, negative: number): number
	return if test >= 0.0 then nonnegative else negative
end

local function limit_offset(value: number): number
	local min = from_bits(0xBDCC_CCCD)
	local max = from_bits(0x3DCC_CCCD)
	local lower = select(f32(min - value), min, value)
	return select(f32(max - lower), lower, max)
end

local function approach(contact: FootContact)
	local min = from_bits(0xBC75_C28F)
	local max = from_bits(0x3C75_C28F)
	local delta = f32(contact.desired_offset - contact.offset)
	local lower = select(f32(min - delta), min, delta)
	contact.offset = f32(select(f32(max - lower), lower, max) + contact.offset)
end

function ContactState.update(self: ContactState, statuses: { status.LimbStatus }, frames: { transforms.LimbFrames }, input: ContactInput)
	self.support_failed_this_update = false
	local requires_support = bit32.band(input.flags_2468, 0x4200_0000) ~= 0
	for foot = 1, 2 do
		local contact = self.feet[foot]
		local frame = frames[foot]
		local failed = false
		if statuses[foot].mode == "OnDeck" and input.contact_bone == input.foot_bones[foot] then
			local q = contact.query_state
			if q == 1 then
				local loc = transform_point(input.inverse_board, contact.position)
				local height = f32(loc[2] + from_bits(0x3DA8_F5C3))
				if height <= from_bits(0x3E99_999A) then
					contact.desired_offset = if bit32.band(input.flags_2468, 0x0180_0000) == 0 then limit_offset(height) else 0.0
					approach(contact)
					local distance = distance_to_contact(contact, frame, input.board, input.inverse_board)
					--82BEFFB4..FFCC: fix modest penetration immediately;
					--larger separations retain the bounded transition.
					if distance < 0.0 and distance > from_bits(0xBE99_999A) then
						contact.offset = f32(contact.offset - distance)
					end
					add_offset(frame, input.board, contact.offset)
					failed = requires_support and distance > from_bits(0x3CF5_C28F) and contact.offset < from_bits(0xBC23_D70A)
				else
					contact.desired_offset = limit_offset(contact.desired_offset)
					approach(contact)
					add_offset(frame, input.board, contact.offset)
					failed = requires_support or input.hips_world_position[2] > from_bits(0x3F33_3333)
				end
			elseif q == 0 or q == 2 then
				contact.desired_offset = limit_offset(contact.desired_offset)
				approach(contact)
				add_offset(frame, input.board, contact.offset)
				failed = contact.query_state == 2 and requires_support
			end
			local position = input.current_contacts[foot]
			if position ~= false and position ~= nil then
				contact.position = table.clone(position :: F4)
				contact.query_state = 1
			else
				contact.query_state = 2
			end
		else
			contact.query_state = 0
			contact.desired_offset = 0.0
			approach(contact)
			add_offset(frame, input.board, contact.offset)
		end
		if failed then
			self.support_failed = true
			self.support_failed_this_update = true
		end
	end
end

return contact_mod
