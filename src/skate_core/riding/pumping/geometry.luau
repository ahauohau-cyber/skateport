--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/pumping/geometry.rs (коммит 2e16697)
--
-- TU3 Pumping geometry82D8F280 and82D8F4A0..6AC. The reciprocal and
-- reciprocal-square-root estimate primitives retain their documented host
-- approximation boundary; source refinements, fused crosses and gates remain.

local rt = require("../../../rt")
local bmo = require("../../physics/board_motion_output")
local native_arithmetic = require("../../physics/native_arithmetic")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local inverse_length_squared = bmo.inverse_length_squared
local dot3 = native_arithmetic.dot3

type F4 = { number }

local geometry = {}

local function reciprocal(value: number): number
	local inverse = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		local error = mul_add(-inverse, value, 1.0)
		inverse = mul_add(inverse, error, inverse)
	end
	return inverse
end

local CYCLIC = { 1, 2, 0, 3 }
local function cross(a: F4, b: F4): F4
	local product = {}
	for i0 = 0, 3 do
		local c = CYCLIC[i0 + 1]
		product[i0] = mul_add(-a[c + 1], b[i0 + 1], f32(a[i0 + 1] * b[c + 1]))
	end
	return { product[CYCLIC[1]], product[CYCLIC[2]], product[CYCLIC[3]], product[CYCLIC[4]] }
end

-- ROBLOX: трейт PumpingGeometry -> таблица функций; каждая возвращает
-- (значение) или (nil, ошибка). NativePumpingGeometry не ошибается (Infallible).
geometry.NativePumpingGeometry = {
	height = function(_self: any, normal: F4, com: F4): (number?, string?)
		return dot3(normal, com), nil
	end,
	speed = function(_self: any, previous: F4, current: F4, dt: number): (number?, string?)
		local inverse = reciprocal(dt)
		local velocity = {}
		for i = 1, 4 do
			velocity[i] = f32(f32(current[i] - previous[i]) * inverse)
		end
		local squared = dot3(velocity, velocity)
		local length = f32(squared * inverse_length_squared(squared, 2))
		return if squared == 0.0 then 0.0 else length, nil
	end,
	angular_speed = function(_self: any, previous_position: F4, previous_normal: F4, sample: any, dt: number): (number?, string?)
		local displacement = {}
		for i = 1, 4 do
			displacement[i] = f32(sample.position[i] - previous_position[i])
		end
		local axis = cross(displacement, sample.normal)
		local squared = dot3(axis, axis)
		local inverse = inverse_length_squared(squared, 2)
		local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
		if length > from_bits(0x3586_37bd) then
			axis = { f32(axis[1] * inverse), f32(axis[2] * inverse), f32(axis[3] * inverse), f32(axis[4] * inverse) }
		else
			axis = { 0.0, 0.0, 0.0, 0.0 }
		end
		local inverse_dt = reciprocal(dt)
		local c = cross(previous_normal, sample.normal)
		local angular = { f32(c[1] * inverse_dt), f32(c[2] * inverse_dt), f32(c[3] * inverse_dt), f32(c[4] * inverse_dt) }
		return dot3(angular, axis), nil
	end,
	inclination_radians = function(_self: any, y: number): (number?, string?)
		return trigonometry.acos(y), nil
	end,
}

return geometry
