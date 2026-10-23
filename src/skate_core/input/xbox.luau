--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/xbox.rs (коммит 2e16697)
--
-- Complete TU3 Xbox pad conversion 8296D5F8, after successful platform polling.

local rt = require("../../rt")
local controller = require("./controller")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local magnitude = controller.magnitude

local xbox = {}

-- Fields of the native Xbox state passed by value to 8296D5F8.
export type XboxState = { buttons: number, triggers: { number }, left: { number }, right: { number } }

local function positive(value: number): number
	-- fsel(-value, +0, value), including the native signed-zero selection.
	return if -value >= 0.0 then 0.0 else value
end

local function condition(stick: { number }): { number }
	local x = f32(stick[1] * from_bits(0x38000000))
	local y = f32(stick[2] * from_bits(0x38000000))
	local squared = mul_add(y, y, f32(x * x))
	local length = magnitude(squared)
	local factor
	if length < from_bits(0x3a83126f) then
		factor = 0.0
	else
		local scaled = f32(f32(length - 0.25) * from_bits(0x3fb6db6e))
		local bounded = if scaled < 0.0 then 0.0 elseif scaled > 1.0 then 1.0 else scaled
		factor = f32(bounded / length)
	end
	x = f32(factor * x)
	y = f32(factor * y)
	return { positive(x), positive(-x), positive(y), positive(-y) }
end

-- Returns all 24 native button values. `device_byte_13` is explicit because
-- its producer/meaning is not inferred from the conversion's four clear stores.
function xbox.convert(state: XboxState, device_byte_13: number): { number }
	local result = table.create(24, 0.0)
	for bit = 0, 9 do
		result[bit + 1] = if bit32.btest(state.buttons, bit32.lshift(1, bit)) then 1.0 else 0.0
	end
	result[11] = f32(state.triggers[1] * from_bits(0x3b808081))
	result[12] = f32(state.triggers[2] * from_bits(0x3b808081))
	for slot = 12, 15 do
		result[slot + 1] = if bit32.btest(state.buttons, bit32.lshift(1, slot)) then 1.0 else 0.0
	end
	local left = condition(state.left)
	local right = condition(state.right)
	for i = 1, 4 do
		result[16 + i] = left[i]
		result[20 + i] = right[i]
	end
	if device_byte_13 ~= 0 then
		for _, slot in { 10, 11, 21, 22 } do
			result[slot + 1] = 0.0
		end
	end
	return result
end

return xbox
