--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/attributes.rs (коммит 2e16697)
--
-- Attribute copying and ordered packet merge from TU3 8258EED0/8258F210.
-- Binary names stay at this typed boundary. This module does not interpret
-- Skeleton attributes or invent a physics effect from their names.

local rt = require("../../../rt")

local attributes = {}

-- ROBLOX: AttributeName(pub [u32; 5]) -> таблица из 5 слов.
export type AttributeName = { number }

function attributes.name_eq(a: AttributeName, b: AttributeName): boolean
	for i = 1, 5 do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

-- The six union lanes retain initialization separately from value. Copying a
-- scalar must not fabricate values for the other five lanes. Words preserve
-- all floating-point payload bits across non-arithmetic publication.
-- ROBLOX: [Option<u32>; 6] -> таблица из 6 элементов, None -> false.
export type AttributePayload = { number | false }

export type AnimationAttribute = {
	payload: AttributePayload,
	begin_time: number,
	end_time: number,
	name: AttributeName,
	status: number,
	-- Native+53: 0/2 scalar, 1 vector, 3 six-word payload; other kinds copy none.
	kind: number,
	sequence_id: number,
}

local AnimationAttribute = {}
attributes.AnimationAttribute = AnimationAttribute

-- Complete observable field assignment 8258EED0. Native padding at 54/55
-- and 60..63 is not copied and has no represented domain field.
function AnimationAttribute.copy_from(self: AnimationAttribute, source: AnimationAttribute)
	self.kind = source.kind
	self.name = table.clone(source.name)
	self.begin_time = source.begin_time
	self.end_time = source.end_time
	self.status = source.status
	self.sequence_id = source.sequence_id
	local lanes
	if self.kind == 0 or self.kind == 2 then
		lanes = 1
	elseif self.kind == 1 then
		lanes = 4
	elseif self.kind == 3 then
		lanes = 6
	else
		lanes = 0
	end
	for i = 1, lanes do
		self.payload[i] = source.payload[i]
	end
end

-- Copy-construction 8258EE68 initializes name storage then performs the
-- assignment above. Its inactive union lanes are unspecified, not zero.
local function copy_construct(source: AnimationAttribute): AnimationAttribute
	local result = table.clone(source)
	result.payload = { false, false, false, false, false, false }
	AnimationAttribute.copy_from(result, source)
	return result
end

export type MotionGraphAttribute = {
	-- Native 24-byte MG record: 20-byte name followed by scalar.
	name: AttributeName,
	value: number,
}

local MotionGraphAttribute = {}
attributes.MotionGraphAttribute = MotionGraphAttribute

-- 8258F210 makes an untimed scalar attribute with status 6 and sequence -1.
function MotionGraphAttribute.to_animation(self: MotionGraphAttribute): AnimationAttribute
	return {
		payload = { rt.to_bits(self.value), false, false, false, false, false },
		begin_time = -1.0,
		end_time = -1.0,
		name = self.name,
		status = 6,
		kind = 0,
		sequence_id = -1,
	}
end

-- Active entries plus retained slots model native end=begin list reset.
-- Capacity allocation policy is host-owned; active ordering and union-lane
-- preservation follow native append/copy semantics. No sorting/deduplication.
export type PacketAttributes = { slots: { AnimationAttribute }, active_len: number }

local PacketAttributes = {}
attributes.PacketAttributes = PacketAttributes

function PacketAttributes.default(): PacketAttributes
	return { slots = {}, active_len = 0 }
end
function PacketAttributes.entries(self: PacketAttributes): { AnimationAttribute }
	return table.move(self.slots, 1, self.active_len, 1, {})
end
function PacketAttributes.clear(self: PacketAttributes)
	self.active_len = 0
end
function PacketAttributes.append(self: PacketAttributes, source: AnimationAttribute)
	local slot = self.slots[self.active_len + 1]
	if slot then
		AnimationAttribute.copy_from(slot, source)
	else
		table.insert(self.slots, copy_construct(source))
	end
	self.active_len += 1
end

-- Exact list operation order at 82593750..825937E4: discard prior active
-- list, append converted MG records, then tree records in stored order.
-- Duplicate names remain distinct records for the later Skeleton dispatch.
function PacketAttributes.replace_from(self: PacketAttributes, motion_graph: { MotionGraphAttribute }, tree: { AnimationAttribute })
	PacketAttributes.clear(self)
	for _, attribute in motion_graph do
		PacketAttributes.append(self, MotionGraphAttribute.to_animation(attribute))
	end
	for _, attribute in tree do
		PacketAttributes.append(self, attribute)
	end
end

return attributes
