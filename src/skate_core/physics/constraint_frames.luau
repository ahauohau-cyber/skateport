--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/constraint_frames.rs (коммит 2e16697)
--
-- Original TU3 constraint-frame arithmetic shared by joint and drive builders.
-- 82AE0DB0 constructs quaternion-component rows directly from bilinear products.
-- The builders compose frames and construct bases without normalizing inputs.

local rt = require("../../rt")
local math_mod = require("../math")
local native_arithmetic = require("./native_arithmetic")
local rigid_body = require("./rigid_body")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector3 = vector
type Basis3 = math_mod.Basis3
type RetailQuaternion = rigid_body.RetailQuaternion
type RetailPackedWorldInverseInertia = rigid_body.RetailPackedWorldInverseInertia

local constraint_frames = {}

export type QuaternionRows = {
	axes: { Vector3 },
	relative: RetailQuaternion,
}

-- 82AE0DB0..0F88. Keep each rounded product and the original addition order;
-- rotating a relative quaternion's axes is only algebraically equivalent for
-- exact unit quaternions and has different finite-precision behavior.
function constraint_frames.quaternion_rows(a: RetailQuaternion, b: RetailQuaternion): QuaternionRows
	local xx, xy, xz, xw = f32(a.x * b.x), f32(a.x * b.y), f32(a.x * b.z), f32(a.x * b.w)
	local yx, yy, yz, yw = f32(a.y * b.x), f32(a.y * b.y), f32(a.y * b.z), f32(a.y * b.w)
	local zx, zy, zz, zw = f32(a.z * b.x), f32(a.z * b.y), f32(a.z * b.z), f32(a.z * b.w)
	local wx, wy, wz, ww = f32(a.w * b.x), f32(a.w * b.y), f32(a.w * b.z), f32(a.w * b.w)
	-- ((p + q) ± r) ± s, каждое действие округляется до f32
	local function s4(p: number, q: number, r: number, s: number): number
		return f32(f32(f32(p + q) + r) + s)
	end
	return {
		axes = {
			vector.create(s4(ww, xx, -yy, -zz), s4(yx, xy, wz, zw), s4(xz, zx, -wy, -yw)),
			vector.create(s4(yx, xy, -wz, -zw), s4(ww, yy, -zz, -xx), s4(yz, zy, wx, xw)),
			vector.create(s4(xz, zx, yw, wy), s4(zy, yz, -wx, -xw), s4(ww, zz, -xx, -yy)),
		},
		relative = {
			x = s4(wx, -xw, zy, -yz),
			y = s4(wy, -yw, xz, -zx),
			z = s4(wz, -zw, yx, -xy),
			w = s4(ww, zz, yy, xx),
		},
	}
end

function constraint_frames.cross(a: Vector3, b: Vector3): Vector3
	return vector.create(
		mul_add(-a.z, b.y, f32(a.y * b.z)),
		mul_add(-a.x, b.z, f32(a.z * b.x)),
		mul_add(-a.y, b.x, f32(a.x * b.y))
	)
end
local cross = constraint_frames.cross

-- Original quaternion multiplication at 82AE3C10..3C60 / 82AE1B94..1C4C.
function constraint_frames.compose(a: RetailQuaternion, b: RetailQuaternion): RetailQuaternion
	local c = cross(vector.create(a.x, a.y, a.z), vector.create(b.x, b.y, b.z))
	return {
		x = mul_add(a.x, b.w, mul_add(b.x, a.w, c.x)),
		y = mul_add(a.y, b.w, mul_add(b.y, a.w, c.y)),
		z = mul_add(a.z, b.w, mul_add(b.z, a.w, c.z)),
		w = f32(f32(a.w * b.w) - native_arithmetic.dot3({ a.x, a.y, a.z, 0.0 }, { b.x, b.y, b.z, 0.0 })),
	}
end

-- Independently verified at Drive Build 82AE1CC4..1D90: sqrt(2) scaling,
-- 0.5 - component squared, paired residuals, and masks 822FB8A0/B0/C0.
function constraint_frames.basis(q: RetailQuaternion): Basis3
	local root_two = from_bits(0x3fb5_04f3)
	local x, y, z, w = f32(q.x * root_two), f32(q.y * root_two), f32(q.z * root_two), f32(q.w * root_two)
	local dx = mul_add(-x, x, 0.5)
	local dy = mul_add(-y, y, 0.5)
	local dz = mul_add(-z, z, 0.5)
	local xy, yz, zx = f32(x * y), f32(y * z), f32(z * x)
	local wz, wx, wy = f32(w * z), f32(w * x), f32(w * y)
	return {
		columns = {
			{ f32(dy + dz), f32(xy + wz), f32(zx - wy) },
			{ f32(xy - wz), f32(dz + dx), f32(yz + wx) },
			{ f32(zx + wy), f32(yz - wx), f32(dx + dy) },
		},
	}
end

function constraint_frames.transform_direction(b: Basis3, v: Vector3): Vector3
	local c = b.columns
	return vector.create(
		mul_add(c[3][1], v.z, mul_add(c[2][1], v.y, f32(c[1][1] * v.x))),
		mul_add(c[3][2], v.z, mul_add(c[2][2], v.y, f32(c[1][2] * v.x))),
		mul_add(c[3][3], v.z, mul_add(c[2][3], v.y, f32(c[1][3] * v.x)))
	)
end

-- Source adds both cross-product terms directly into the incoming rate.
function constraint_frames.point_rate(linear: Vector3, angular: Vector3, arm: Vector3): Vector3
	return vector.create(
		mul_add(arm.z, angular.y, mul_add(-arm.y, angular.z, linear.x)),
		mul_add(arm.x, angular.z, mul_add(-arm.z, angular.x, linear.y)),
		mul_add(arm.y, angular.x, mul_add(-arm.x, angular.y, linear.z))
	)
end

function constraint_frames.multiply_add(v: Vector3, scalar: number, addend: Vector3): Vector3
	return vector.create(mul_add(v.x, scalar, addend.x), mul_add(v.y, scalar, addend.y), mul_add(v.z, scalar, addend.z))
end

function constraint_frames.reciprocal(value: number): number
	local r = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		local residual = mul_add(-r, value, 1.0)
		r = mul_add(r, residual, r)
	end
	return r
end

function constraint_frames.reciprocal_sqrt(value: number): number
	local r = native_arithmetic.reciprocal_square_root_estimate(value)
	for _ = 1, 2 do
		local squared = f32(r * r)
		local half = f32(r * 0.5)
		local residual = mul_add(-value, squared, 1.0)
		r = mul_add(half, residual, r)
	end
	return r
end

local function inertia_tail(t: RetailPackedWorldInverseInertia, v: Vector3, first: Vector3): Vector3
	return vector.create(
		mul_add(t.full.z, v.z, mul_add(t.full.y, v.y, first.x)),
		mul_add(t.split.z, v.z, mul_add(t.split.y, v.y, first.y)),
		mul_add(t.split.x, v.z, mul_add(t.split.z, v.y, first.z))
	)
end

-- Drive 82AE2430..2490: X product, then the Y and Z fused additions.
function constraint_frames.multiply_inertia(t: RetailPackedWorldInverseInertia, v: Vector3): Vector3
	return inertia_tail(t, v, vector.create(f32(t.full.x * v.x), f32(t.full.y * v.x), f32(t.full.z * v.x)))
end

-- Joint 82AE470C..4758 starts the same contraction with a fused +zero.
function constraint_frames.multiply_inertia_from_zero(t: RetailPackedWorldInverseInertia, v: Vector3): Vector3
	return inertia_tail(
		t,
		v,
		vector.create(mul_add(t.full.x, v.x, 0.0), mul_add(t.full.y, v.x, 0.0), mul_add(t.full.z, v.x, 0.0))
	)
end

return constraint_frames
