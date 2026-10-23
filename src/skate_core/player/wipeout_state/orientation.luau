--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/orientation.rs (коммит 2e16697)
--
-- Original Wipeout alignment82D3C770: Euler X/Y degrees -> rotated up axis.

local rt = require("../../../rt")
local m = require("./math")
local trigonometry = require("../../trigonometry")
local board_motion_output = require("../../physics/board_motion_output")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local sin_cos = trigonometry.sin_cos

type V = m.V

local orientation = {}

-- 82D3C8CC..C8F8 and82D3CF84..CFFC retain the two fused cross stages.
function orientation.rotate(quaternion: V, v: V): V
	local first = m.cross(quaternion, v)
	local middle = m.madd(v, quaternion[4], first)
	return m.madd(m.cross(quaternion, middle), 2.0, v)
end

function orientation.alignment_up(x_degrees: number, y_degrees: number): V
	local radians = from_bits(0x3C8E_FA35)
	local sx, cx = sin_cos(f32(f32(x_degrees * radians) * 0.5))
	local sy, cy = sin_cos(f32(f32(y_degrees * radians) * 0.5))
	local sz, cz = sin_cos(0.0)
	local cxcz = f32(cx * cz)
	local sxcz = f32(sx * cz)
	local sxsz = f32(sx * sz)
	local cxsz = f32(cx * sz)
	-- 82D3C8B0 word114D4AAE: D10=A13*C10+B9, not A13*B9+C10.
	local qy = mul_add(cy, sxsz, f32(sy * cxcz))
	-- 82D3C8B4 word11AD42EE: D13=A13*C11+B8.
	local qw = mul_add(cy, cxcz, f32(sy * sxsz))
	local qz = f32(f32(cy * cxsz) - f32(sy * sxcz))
	local qx = f32(f32(cy * sxcz) - f32(sy * cxsz))
	return orientation.rotate({ qx, qy, qz, qw }, { 0.0, 1.0, 0.0, 0.0 })
end

-- 8296EC98: both vectors require squared length >0.0001, then one
-- reciprocal-square-root refinement. The negative half returns 2pi-angle.
function orientation.signed_angle(left: V, right: V, axis: V): number
	local inverse_length_squared = board_motion_output.inverse_length_squared
	local a = m.dot(left, left)
	local b = m.dot(right, right)
	if not (a > from_bits(0x38D1_B717) and b > from_bits(0x38D1_B717)) then
		return 0.0
	end
	local l = m.scale(left, inverse_length_squared(a, 1))
	local r = m.scale(right, inverse_length_squared(b, 1))
	local angle = trigonometry.acos(m.clamp(m.dot(l, r), -1.0, 1.0))
	if m.dot(m.cross(l, r), axis) < 0.0 then
		return f32(from_bits(0x40C9_0FDB) - angle)
	end
	return angle
end

-- 8286CD88 checks the original lengths before projecting onto the axis plane.
function orientation.projected_angle(left: V, right: V, axis: V): number
	if not (f32(m.dot(left, left) * m.dot(right, right)) > from_bits(0x3780_0000)) then
		return 0.0
	end
	return orientation.signed_angle(
		m.sub(left, m.scale(axis, m.dot(axis, left))),
		m.sub(right, m.scale(axis, m.dot(axis, right))),
		axis
	)
end

return orientation
