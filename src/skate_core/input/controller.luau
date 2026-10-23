--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/controller.rs (коммит 2e16697)
--
-- TU3 RawControllerInput 82598FE0 and DerivedControllerInput 825992D8.
-- Native action-map evaluation is an explicit boundary, not a platform mapping.

local rt = require("../../rt")
local reciprocal_sqrt = require("../physics/reciprocal_sqrt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local estimate = reciprocal_sqrt.estimate

local controller = {}

-- Evaluated native cInputMap actions. IDs are TU3 map indices, not XInput
-- buttons. Implementations must preserve the call order; the stock expression
-- evaluator 8296C350 and loaded mapping still determine deadzones and scaling.
-- ROBLOX: трейт ActionMap -> таблица с методами value(action) и state(action).
export type ActionMap = {
	value: (self: any, action: number) -> number,
	state: (self: any, action: number) -> number,
}

-- Six binary32 axes/triggers followed by native packed button bits.
-- ROBLOX: words: [u32; 7] -> таблица, слово k лежит в [k + 1].
export type RawControllerInput = { words: { number } }

local RawControllerInput = {}
controller.RawControllerInput = RawControllerInput

function RawControllerInput.from_words(words: { number }): RawControllerInput
	return { words = table.clone(words) }
end

function RawControllerInput.words(self: RawControllerInput): { number }
	return self.words
end

local function set_bit(self: RawControllerInput, bit: number, value: number)
	self.words[7] = bit32.bor(bit32.band(self.words[7], bit32.bnot(bit32.lshift(1, bit))), bit32.lshift(bit32.band(value, 1), bit))
end

-- Complete 82598FE0, including simultaneous bumper arbitration and
-- retention of the low twenty bits of the destination flags word.
function RawControllerInput.update(self: RawControllerInput, previous: RawControllerInput, map: ActionMap, state_502: boolean, state_104: boolean)
	for slot, action in { 64, 65, 67, 68, 70, 71 } do
		self.words[slot] = to_bits(map:value(action))
	end
	for _, pair in { { 66, 31 }, { 69, 30 }, { 72, 29 }, { 73, 28 } } do
		set_bit(self, pair[2], map:state(pair[1]))
	end
	local both = bit32.bor(bit32.lshift(1, 29), bit32.lshift(1, 28))
	if bit32.band(self.words[7], both) == both then
		local prior = bit32.band(previous.words[7], both)
		if (prior == bit32.lshift(1, 29) or prior == bit32.lshift(1, 28)) and (state_502 or state_104) then
			self.words[7] = bit32.bor(bit32.band(self.words[7], bit32.bnot(both)), prior)
		else
			self.words[7] = bit32.band(self.words[7], bit32.bnot(bit32.lshift(1, 28)))
		end
	end
	for action = 74, 81 do
		set_bit(self, 101 - action, map:state(action))
	end
end

-- Actual inputlistener attribute result for key 1F3C1C1C68AF4C23.
-- Missing collection/attribute uses the live 830D0850 fallback.
export type MagnitudeHeldSettings = { attribute: number?, missing_attribute_value: number }

-- ROBLOX: words: [u32; 26] -> таблица, слово k лежит в [k + 1].
export type DerivedControllerInput = { words: { number } }

local DerivedControllerInput = {}
controller.DerivedControllerInput = DerivedControllerInput

-- Requires native initialized state. No reset or inferred default supplied.
function DerivedControllerInput.from_words(words: { number }): DerivedControllerInput
	return { words = table.clone(words) }
end

function DerivedControllerInput.words(self: DerivedControllerInput): { number }
	return self.words
end

-- Prefix construction recovered from TU3 `82599718`. The native
-- constructor clears the controller axes and timers, preserves the low
-- twenty flag bits in the two packed raw words, and seeds the four
-- edge-timer fields from `flt_822F8B34` (`0x7effffff`). This is only the
-- controller prefix; listener registration/reset belongs to its owner.
function DerivedControllerInput.initialize(self: DerivedControllerInput)
	local flags_last = bit32.band(self.words[7], 0x000f_ffff)
	local flags_current = bit32.band(self.words[14], 0x000f_ffff)
	self.words = rt.zeros(26)
	self.words[7] = flags_last
	self.words[14] = flags_current
	for i = 17, 20 do
		self.words[i] = 0x7eff_ffff
	end
end

local function advance_or_reset(self: DerivedControllerInput, slot: number, advance: boolean, timestep: number)
	self.words[slot + 1] = if advance then to_bits(f32(from_bits(self.words[slot + 1]) + timestep)) else 0
end

-- Independent reciprocal-square-root estimate followed by the original two
-- refinement steps. Host arithmetic is not claimed to be bit-exact Xenon math.
-- pub(super) fn magnitude(squared: f32) -> f32
function controller.magnitude(squared: number): number
	local inverse = estimate(squared)
	for _ = 1, 2 do
		local correction = mul_add(-squared, f32(inverse * inverse), 1.0)
		inverse = mul_add(f32(inverse * 0.5), correction, inverse)
	end
	if squared == 0.0 then
		return 0.0
	end
	return f32(squared * inverse)
end
local magnitude = controller.magnitude

-- Complete 825992D8: raw history, trigger/button edge timers and stick
-- magnitude-held timers. Timing uses caller dt without an imposed rate.
function DerivedControllerInput.update(self: DerivedControllerInput, map: ActionMap, timestep: number, state_502: boolean, state_104: boolean, settings: MagnitudeHeldSettings)
	local previous = RawControllerInput.from_words(table.move(self.words, 8, 14, 1, {}))
	for i = 1, 7 do
		self.words[i] = previous.words[i]
	end
	local current = RawControllerInput.from_words(previous.words)
	RawControllerInput.update(current, previous, map, state_502, state_104)
	for i = 1, 7 do
		self.words[7 + i] = current.words[i]
	end
	for _, pair in { { 14, 4 }, { 15, 5 } } do
		advance_or_reset(self, pair[1], from_bits(current.words[pair[2] + 1]) == 1.0, timestep)
	end
	local before = previous.words[7]
	local now = current.words[7]
	for _, triple in { { 31, 16, 17 }, { 30, 18, 19 } } do
		local bit = bit32.lshift(1, triple[1])
		local was_down = bit32.band(before, bit) ~= 0
		local is_down = bit32.band(now, bit) ~= 0
		advance_or_reset(self, triple[2], not (not was_down and is_down), timestep)
		advance_or_reset(self, triple[3], not (was_down and not is_down), timestep)
	end
	for _, pair in { { 20, 80 }, { 21, 81 }, { 22, 78 }, { 23, 79 } } do
		advance_or_reset(self, pair[1], map:state(pair[2]) ~= 0, timestep)
	end
	-- Native evaluates these actions again after the button timers.
	local lx = map:value(64)
	local ly = map:value(65)
	local rx = map:value(67)
	local ry = map:value(68)
	local right = magnitude(mul_add(ry, ry, f32(rx * rx)))
	local left = magnitude(mul_add(ly, ly, f32(lx * lx)))
	local threshold = if settings.attribute ~= nil then settings.attribute else settings.missing_attribute_value
	-- PPC ble treats unordered as false; retain that branch direction.
	advance_or_reset(self, 24, not (left <= threshold), timestep)
	advance_or_reset(self, 25, not (right <= threshold), timestep)
end

return controller
