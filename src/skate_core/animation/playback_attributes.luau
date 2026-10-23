--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/playback_attributes.rs (коммит 2e16697)
--
-- PhaseBlend attribute intersection 82D161B0 and Scale/AddWeighted 82D16370/428.

local rt = require("../../rt")
local attributes = require("./output/attributes")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local playback_attributes = {}

type AnimationAttribute = attributes.AnimationAttribute

-- Bone-name mapping supplied by the stock hierarchy. A native excluded bone
-- (mirror index -1) maps to itself; missing names remain a data error.
-- ROBLOX: AttributeMirror(pub Vec<(AttributeName, AttributeName)>) -> { pairs = { { source, target } } }.
export type AttributeMirror = { pairs: { { attributes.AttributeName } } }

local AttributeMirror = {}
playback_attributes.AttributeMirror = AttributeMirror

local function lane(attribute: AnimationAttribute, i: number, message: string): number
	local w = attribute.payload[i]
	if w == false then
		rt.raise(message)
	end
	return w :: number
end

-- Attribute::Mirror 82530F48 changes payload identity, never the event key.
-- ROBLOX: Result<(), String> -> rt.raise(строка).
function AttributeMirror.apply(self: AttributeMirror, attribute: AnimationAttribute)
	if attribute.kind == 1 then
		local x = lane(attribute, 1, "Uninitialized mirrored vector attribute")
		attribute.payload[1] = bit32.bxor(x, 0x80000000)
	elseif attribute.kind == 3 then
		local name = {}
		for i = 1, 5 do
			name[i] = lane(attribute, i, "Uninitialized mirrored bone reference")
		end
		local mirrored: { number }? = nil
		for _, pair in self.pairs do
			if attributes.name_eq(pair[1], name) then
				mirrored = pair[2]
				break
			end
		end
		if mirrored == nil then
			rt.raise("Animation event bone is absent from its hierarchy")
		end
		-- ROBLOX: zip шести слотов с пятью словами имени — меняются только первые 5.
		for i = 1, 5 do
			attribute.payload[i] = (mirrored :: any)[i]
		end
	end
end

local function numeric_lanes(kind: number): { number }
	if kind == 0 or kind == 2 then
		return { 1 }
	elseif kind == 1 then
		return { 1, 2, 3, 4 }
	elseif kind == 3 then
		return { 6 }
	end
	return {}
end

function playback_attributes.blend(left: AnimationAttribute, right: AnimationAttribute, weight: number)
	local left_weight = f32(1.0 - weight)
	if bit32.band(left.status, 2) ~= 0 then
		left.begin_time = -1.0
		left.end_time = -1.0
	else
		-- Time fields use separate multiply/add instructions, not fused math.
		left.begin_time = f32(f32(right.begin_time * weight) + f32(left.begin_time * left_weight))
		left.end_time = f32(f32(right.end_time * weight) + f32(left.end_time * left_weight))
	end
	for _, i in numeric_lanes(left.kind) do
		local l = from_bits(lane(left, i, "Uninitialized blended attribute payload"))
		local r = from_bits(lane(right, i, "Uninitialized blended attribute payload"))
		left.payload[i] = to_bits(mul_add(r, weight, f32(l * left_weight)))
	end
end

-- 82D16370. Keep reference names and event flags; scale only numeric payload.
function playback_attributes.scale(attribute: AnimationAttribute, weight: number)
	if bit32.band(attribute.status, 2) ~= 0 then
		attribute.begin_time = -1.0
		attribute.end_time = -1.0
	else
		attribute.begin_time = f32(attribute.begin_time * weight)
		attribute.end_time = f32(attribute.end_time * weight)
	end
	for _, i in numeric_lanes(attribute.kind) do
		local value = from_bits(lane(attribute, i, "Uninitialized weighted attribute"))
		attribute.payload[i] = to_bits(f32(value * weight))
	end
end

-- 82D16428. Time adds are separate instructions; numeric payload uses FMA.
function playback_attributes.add_weighted(left: AnimationAttribute, right: AnimationAttribute, weight: number)
	if bit32.band(left.status, 2) == 0 then
		left.begin_time = f32(left.begin_time + f32(right.begin_time * weight))
		left.end_time = f32(left.end_time + f32(right.end_time * weight))
	end
	for _, i in numeric_lanes(left.kind) do
		local a = from_bits(lane(left, i, "Uninitialized weighted attribute"))
		local b = from_bits(lane(right, i, "Uninitialized weighted attribute"))
		left.payload[i] = to_bits(mul_add(b, weight, a))
	end
end

local function less(a: { number }, b: { number }): boolean
	for i = 1, 5 do
		if a[i] ~= b[i] then
			return a[i] < b[i]
		end
	end
	return false
end

local function copy_attr(a: AnimationAttribute): AnimationAttribute
	local c = table.clone(a)
	c.payload = table.clone(a.payload)
	c.name = table.clone(a.name)
	return c
end

-- Native uses a forward-only intersection, retaining left order/metadata.
-- It does not append right-only attributes or replace the left reference name.
function playback_attributes.intersection(left: { AnimationAttribute }, right: { AnimationAttribute }, weight: number): { AnimationAttribute }
	local result = {}
	local next_ = 1
	for _, a in left do
		local attribute = copy_attr(a)
		while next_ <= #right and less(right[next_].name, attribute.name) do
			next_ += 1
		end
		local other = right[next_]
		if other == nil then
			break
		end
		if attributes.name_eq(other.name, attribute.name) then
			playback_attributes.blend(attribute, other, weight)
			table.insert(result, attribute)
		end
	end
	return result
end

return playback_attributes
