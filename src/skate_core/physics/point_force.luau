--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/point_force.rs (коммит 2e16697)
--
-- TU3 queued point-force application, 0x82C037DC..0x82C03908.

local rt = require("../../rt")
local math_mod = require("../math")

local f32 = rt.f32
local mul_add = rt.mul_add

type Vector3 = vector
type Basis3 = math_mod.Basis3

local point_force = {}

-- pub struct RetailForceAccumulator
export type RetailForceAccumulator = {
	force_acceleration: Vector3,
	torque_acceleration: Vector3,
	cool_down: number,
}

local function multiply_basis(basis: Basis3, v: Vector3): Vector3
	-- Native multiplies column 0, then fuses column 1, then column 2.
	local c = basis.columns
	local function lane(i: number): number
		return mul_add(c[3][i], v.z, mul_add(c[2][i], v.y, f32(c[1][i] * v.x)))
	end
	return vector.create(lane(1), lane(2), lane(3))
end

-- Apply one queued force using the native multiply / fused-add order.
-- `application_point_body` already includes the collection's force-point Y
-- offset (added by the queue consumer at 0x82C037EC).
-- ROBLOX: `mut accumulator` по значению -> возвращаем новую таблицу,
-- аргумент не меняется.
-- pub fn accumulate_point_force(...) -> RetailForceAccumulator
function point_force.accumulate_point_force(
	accumulator: RetailForceAccumulator,
	force_world: Vector3,
	application_point_body: Vector3,
	deck_basis: Basis3,
	inverse_mass: number,
	world_inverse_inertia: Basis3
): RetailForceAccumulator
	-- 0x82C03850: vmulfp; 0x82C03878..0x82C03894: scalar adds.
	local fa = accumulator.force_acceleration
	local force_acceleration = vector.create(
		f32(fa.x + f32(force_world.x * inverse_mass)),
		f32(fa.y + f32(force_world.y * inverse_mass)),
		f32(fa.z + f32(force_world.z * inverse_mass))
	)
	local arm = multiply_basis(deck_basis, application_point_body)
	-- 0x82C0387C / 0x82C038B0 / 0x82C038B4: multiply, fused negative
	-- multiply-add, permutation. Fusing the positive term instead differs.
	local torque = vector.create(
		mul_add(-arm.z, force_world.y, f32(arm.y * force_world.z)),
		mul_add(-arm.x, force_world.z, f32(arm.z * force_world.x)),
		mul_add(-arm.y, force_world.x, f32(arm.x * force_world.y))
	)
	local angular = multiply_basis(world_inverse_inertia, torque)
	local ta = accumulator.torque_acceleration
	return {
		force_acceleration = force_acceleration,
		torque_acceleration = vector.create(f32(ta.x + angular.x), f32(ta.y + angular.y), f32(ta.z + angular.z)),
		cool_down = 0,
	}
end

return point_force
