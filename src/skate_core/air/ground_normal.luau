--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/ground_normal.rs (коммит 2e16697)
--
-- TU3 Reckoning::UpdateGroundNormal 82D8E0F8, including filter 82D7A018.

local rt = require("../../rt")
local reciprocal_sqrt = require("../physics/reciprocal_sqrt")
local native_arithmetic = require("../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate

local ground_normal = {}

-- Native reckoning +1280..1376: control, position, previous input, filtered
-- error, output delta and filtered input delta. All four vector lanes persist.
-- Initial values must come from the native constructor/entry path.
-- ROBLOX: words: [u32; 24] -> таблица, слово k лежит в [k + 1]; [f32; 4] -> таблица из 4.
export type GroundNormalFilter = { words: { number } }

local GroundNormalFilter = {}
ground_normal.GroundNormalFilter = GroundNormalFilter

local function put(words: { number }, offset: number, values: { number })
	for lane = 1, 4 do
		words[offset + lane] = to_bits(values[lane])
	end
end

-- TU3 constructor82D8DA68 initializes current/last target to the seed,
-- and all three accumulated difference vectors to zero.
function GroundNormalFilter.initialized(control: { number }, initial: { number }): GroundNormalFilter
	local words = rt.zeros(24)
	put(words, 0, control)
	put(words, 4, initial)
	put(words, 8, initial)
	return { words = words }
end

-- The up-vector filters publish the final corrected up vector only after
-- both filter updates and acceleration/damping in82D8C8F0.
function GroundNormalFilter.publish_current(self: GroundNormalFilter, current: { number })
	put(self.words, 4, current)
end

function GroundNormalFilter.filter_raw(self: GroundNormalFilter, control: { number }, input: { number }): { number }
	put(self.words, 0, control)
	return GroundNormalFilter.filter(self, input)
end

function GroundNormalFilter.from_words(words: { number }): GroundNormalFilter
	return { words = table.clone(words) }
end

function GroundNormalFilter.words(self: GroundNormalFilter): { number }
	return self.words
end

-- ROBLOX: #[derive(Clone, PartialEq)].
function GroundNormalFilter.clone(self: GroundNormalFilter): GroundNormalFilter
	return { words = table.clone(self.words) }
end
function GroundNormalFilter.eq(a: GroundNormalFilter, b: GroundNormalFilter): boolean
	for i = 1, 24 do
		if a.words[i] ~= b.words[i] then
			return false
		end
	end
	return true
end

-- Copies live layout+1216 control words before each native filter call.
-- Returns the normal published at reckoning+1216 and +1296. There is no
-- invented zero-vector fallback; native degenerate arithmetic is preserved.
function GroundNormalFilter.update(self: GroundNormalFilter, control: { number }, input: { number }): { number }
	put(self.words, 0, control)
	local filtered = GroundNormalFilter.filter(self, input)
	local squared = native_arithmetic.dot3(filtered, filtered)
	local inverse = estimate(squared)
	for _ = 1, 2 do
		local correction = mul_add(-squared, f32(inverse * inverse), 1.0)
		inverse = mul_add(f32(inverse * 0.5), correction, inverse)
	end
	local normal = {}
	for lane = 1, 4 do
		normal[lane] = f32(filtered[lane] * inverse)
	end
	put(self.words, 4, normal)
	return normal
end

-- Full vector filter 82D7A018, with publication order before normalization.
-- pub(crate) fn filter(&mut self, input: [f32; 4]) -> [f32; 4]
function GroundNormalFilter.filter(self: GroundNormalFilter, input: { number }): { number }
	local words = self.words
	local previous = {}
	for i = 1, 24 do
		previous[i - 1] = from_bits(words[i])
	end
	local blend = previous[3]
	local retained = f32(1.0 - blend)
	local output = { 0.0, 0.0, 0.0, 0.0 }
	for lane = 0, 3 do
		local error = f32(input[lane + 1] - previous[4 + lane])
		local error_blend = mul_add(previous[12 + lane], retained, f32(error * blend))
		local input_delta = f32(input[lane + 1] - previous[8 + lane])
		local input_blend = mul_add(previous[20 + lane], retained, f32(input_delta * blend))
		local predicted = mul_add(error_blend, previous[1], previous[4 + lane])
		predicted = mul_add(error, previous[0], predicted)
		local value = mul_add(f32(input_blend - previous[16 + lane]), previous[2], predicted)
		output[lane + 1] = value
		words[12 + lane + 1] = to_bits(error_blend)
		words[20 + lane + 1] = to_bits(input_blend)
		words[16 + lane + 1] = to_bits(f32(value - previous[4 + lane]))
		words[4 + lane + 1] = to_bits(value)
		words[8 + lane + 1] = to_bits(input[lane + 1])
	end
	return output
end

return ground_normal
