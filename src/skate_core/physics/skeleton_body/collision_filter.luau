--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/collision_filter.rs (коммит 2e16697)
--
-- Original82BD5A00: select the angular interval of active contact planes.
-- ROBLOX: `impl SkeletonCollisionFeedback` в другом файле -> функция добавляется
-- в таблицу SkeletonCollisionFeedback из collision_feedback.luau при загрузке.

local rt = require("../../../rt")
local collision_feedback = require("./collision_feedback")
local cv = require("./collision_vector")
local collision_response = require("../../riding/collision_response")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot, scale, sub, normalize = cv.dot, cv.scale, cv.sub, cv.normalize
local signed_angle = collision_response.signed_angle
local cos, sin = trigonometry.cos, trigonometry.sin

type V = collision_feedback.V

local collision_filter = {}
local SkeletonCollisionFeedback = collision_feedback.SkeletonCollisionFeedback

local function to_vector(v: V): vector
	return vector.create(v[1], v[2], v[3])
end

function collision_filter.filter_error(self: collision_feedback.SkeletonCollisionFeedback, error_: V, axis: V): V
	local projected = sub(error_, scale(axis, dot(error_, axis)))
	local direction = normalize(projected)
	if dot(direction, direction) < f32(0.1) then
		return projected
	end
	local half_pi = from_bits(0x3fc9_0fdb)
	local minimum = half_pi
	local maximum = -half_pi
	local found = false
	for _, plane in self.planes do
		local normal = normalize(sub(plane.normal, scale(axis, dot(plane.normal, axis))))
		if dot(normal, normal) < f32(0.1) then
			continue
		end
		local angle = signed_angle(to_vector(direction), to_vector(normal), to_vector(axis))
		local turns = f32(angle * from_bits(0x3e22_f983))
		local fractional = f32(turns - math.floor(turns))
		local centered = f32(fractional - (if fractional > 0.5 then 1.0 else 0.0))
		local wrapped = f32(centered * from_bits(0x40c9_0fdb))
		if wrapped > -half_pi and wrapped < half_pi then
			if wrapped < minimum then
				minimum = wrapped
			end
			if wrapped > maximum then
				maximum = wrapped
			end
			found = true
		end
	end
	local angle = f32(f32(maximum + minimum) * 0.5)
	local magnitude = if found then cos(angle) else 0.0
	--82BD35B8 rotates identity around the supplied axis before applying
	--the projected error. Preserve its product/FMA and standalone trig.
	local c = cos(angle)
	local s = sin(angle)
	local x, y, z = axis[1], axis[2], axis[3]
	local sx = f32(s * x)
	local sy = f32(s * y)
	local sz = f32(s * z)
	local t = f32(1.0 - c)
	local tx = f32(t * x)
	local ty = f32(t * y)
	local tz = f32(t * z)
	local rotation = {
		{ mul_add(x, tx, c), mul_add(tx, y, sz), f32(f32(tx * z) - sy) },
		{ f32(f32(ty * x) - sz), mul_add(ty, y, c), mul_add(ty, z, sx) },
		{ mul_add(tz, x, sy), f32(f32(tz * y) - sx), mul_add(z, tz, c) },
	}
	local result = { 0.0, 0.0, 0.0, 0.0 }
	for i = 1, 3 do
		result[i] = f32(mul_add(rotation[3][i], projected[3], mul_add(rotation[2][i], projected[2], f32(rotation[1][i] * projected[1]))) * magnitude)
	end
	return result
end

-- ROBLOX: метод impl-блока.
;(SkeletonCollisionFeedback :: any).filter_error = collision_filter.filter_error

return collision_filter
