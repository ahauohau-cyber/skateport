--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/grind_surface/orientation.rs (коммит 2e16697)

local rt = require("../../../../rt")
local m = require("../math")
local trigonometry = require("../../../trigonometry")

local f32 = rt.f32
local from_bits = rt.from_bits
local scale, cross, madd = m.scale, m.cross, m.madd

type V = { number }

local orientation = {}

-- 82C21828. Strict straddling test and nearest-limit tie-to-high branch.
function orientation.tilted_normal(direction: V, up: V, limits: { number }): V
	local lo, hi = limits[1], limits[2]
	local pi = from_bits(0x4049_0fdb)
	local angle
	if lo < hi then
		if lo < pi and hi > pi then
			return up
		end
		angle = if math.abs(f32(pi - lo)) < math.abs(f32(pi - hi)) then lo else hi
	else
		angle = f32(f32(hi + lo) * 0.5)
	end
	return orientation.rotate(direction, scale(up, -1.0), angle)
end

-- 82C1E220: half-angle sine/cosine quaternion; existing independent PC
-- trigonometry supplies its numerical leaves, not a generated SIMD helper.
function orientation.rotate(axis: V, value: V, angle: number): V
	local sin, cos = trigonometry.sin_cos(f32(angle * 0.5))
	local q = scale(axis, sin)
	return madd(cross(q, madd(value, cos, cross(q, value))), 2.0, value)
end

return orientation
