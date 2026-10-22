--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/rigid_body/dynamic_update.rs (коммит 2e16697)
--
-- RigidBody::DynamicUpdate82AE6590 reconstruction candidate.
-- Guest pointers are opaque metadata; the caller supplies their referenced data.

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local native_arithmetic = require("../native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

-- ROBLOX: `type V = [f32; 4]` -> таблица из 4 чисел, лейн i лежит в [i + 1].
type V = { number }

local dynamic_update = {}

-- pub struct DynamicUpdateResult
export type DynamicUpdateResult = {
	orientation_displacement: { number },
	-- Native cap-selected squared speeds used by the sleep metric.
	linear_speed_squared: number,
	angular_speed_squared: number,
}

-- ROBLOX: RetailSimulationStep определён в rigid_body.luau; здесь — только
-- поля, которые читает эта функция (так разорван цикл require).
type SimulationStep = {
	time_step: number,
	frequency: number,
	cool_down: number,
	minimum_energy: number,
	gravity_acceleration: vector,
}

local function splat(value: number): V
	return { value, value, value, value }
end

local function load(words: { number }, offset: number): V
	return {
		from_bits(words[offset + 1]),
		from_bits(words[offset + 2]),
		from_bits(words[offset + 3]),
		from_bits(words[offset + 4]),
	}
end

local function store_xyz(words: { number }, offset: number, value: V)
	for i = 1, 3 do
		words[offset + i] = to_bits(value[i])
	end
end

-- ROBLOX: индексы перестановки даны как в Rust (с нуля).
local function perm(value: V, indices: { number }): V
	return { value[indices[1] + 1], value[indices[2] + 1], value[indices[3] + 1], value[indices[4] + 1] }
end

local function mul(a: V, b: V): V
	return { f32(a[1] * b[1]), f32(a[2] * b[2]), f32(a[3] * b[3]), f32(a[4] * b[4]) }
end

local function add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

local function madd(a: V, b: V, c: V): V
	return {
		mul_add(a[1], b[1], c[1]),
		mul_add(a[2], b[2], c[2]),
		mul_add(a[3], b[3], c[3]),
		mul_add(a[4], b[4], c[4]),
	}
end

local function nmsub(a: V, b: V, c: V): V
	return {
		mul_add(-a[1], b[1], c[1]),
		mul_add(-a[2], b[2], c[2]),
		mul_add(-a[3], b[3], c[3]),
		mul_add(-a[4], b[4], c[4]),
	}
end

local function dot(a: V, b: V, four: boolean): number
	if four then
		return native_arithmetic.dot4(a, b)
	end
	return native_arithmetic.dot3(a, b)
end

local function refined_rsqrt(value: number): number
	local estimate = reciprocal_sqrt.estimate(value)
	for _ = 1, 2 do
		local square = f32(estimate * estimate)
		local half_estimate = f32(estimate * 0.5)
		local residual = mul_add(-value, square, 1.0)
		estimate = mul_add(half_estimate, residual, estimate)
	end
	return estimate
end

-- pub(super) fn orientation(q: V, rotation: V) -> V
function dynamic_update.orientation(q: V, rotation: V): V
	-- S3 82AE6668..66C8 / S2 82AE455C..45C8: cross product then normalization.
	local cross = perm(nmsub(perm(rotation, { 1, 2, 0, 3 }), q, mul(rotation, perm(q, { 1, 2, 0, 3 }))), { 1, 2, 0, 3 })
	local increment = mul(madd(rotation, splat(q[4]), cross), splat(0.5))
	increment[4] = f32(dot(rotation, q, false) * -0.5)
	local candidate = add(q, increment)
	return mul(candidate, splat(refined_rsqrt(dot(candidate, candidate, true))))
end

-- pub(super) fn quaternion_basis(q: V) -> [V; 3]
function dynamic_update.quaternion_basis(q: V): { V }
	-- 82139A00 contains sqrt(2) rounded to binary32. Replacing these products
	-- with 2*q_i*q_j changes the native basis words.
	local s = mul(q, splat(from_bits(0x3FB5_04F3)))
	local d = nmsub(s, s, splat(0.5))
	local diagonal = add(d, perm(d, { 1, 2, 0, 0 }))
	local products = mul(s, perm(s, { 1, 2, 0, 0 }))
	local w_products = mul(splat(s[4]), perm(s, { 2, 0, 1, 0 }))
	local plus = add(products, w_products)
	local minus = sub(products, w_products)
	return {
		{ diagonal[2], plus[1], minus[3], 0.0 },
		{ minus[1], diagonal[3], plus[2], 0.0 },
		{ plus[3], minus[2], diagonal[1], 0.0 },
	}
end

-- pub(super) fn inverse_inertia(basis: [V; 3], tensor: [u32; 3]) -> (V, V)
function dynamic_update.inverse_inertia(basis: { V }, tensor: { number }): (V, V)
	local ri, up, at = basis[1], basis[2], basis[3]
	local r = mul(ri, splat(from_bits(tensor[1])))
	local u = mul(up, splat(from_bits(tensor[2])))
	local a = mul(at, splat(from_bits(tensor[3])))
	local full = madd(a, splat(at[1]), madd(r, splat(ri[1]), mul(u, splat(up[1]))))
	local function p(v: V): V
		return perm(v, { 2, 1, 1, 3 })
	end
	local function s(v: V): V
		return perm(v, { 2, 1, 2, 3 })
	end
	local split = madd(p(at), s(a), madd(p(ri), s(r), mul(p(up), s(u))))
	return full, split
end

local function cap(value: V, maximum: number): (V, number)
	local squared = dot(value, value, false)
	local maximum_squared = f32(maximum * maximum)
	-- S3 82AE6888/68FC and S2 82AE478C/4804 skip on GT clear (ble),
	-- including unordered. Thus ordered >, not !(<=), enters the cap path.
	if squared > maximum_squared then
		local ratio = f32(maximum_squared / squared)
		local root = f32(ratio * refined_rsqrt(ratio))
		local scale = if ratio == 0.0 then 0.0 else root
		return mul(value, splat(scale)), maximum_squared
	end
	return value, squared
end

-- Update every native body field and clear all 64 reaction bytes. `body` is the
-- 176-byte RigidBody prefix; `inertia` is its 40-byte Inertia record. Metadata
-- lanes, including pointers and IDs, are preserved. No activation is performed.
-- ROBLOX: `&mut [u32; 44]` и `&mut [u32; 16]` — таблицы слов, меняются на месте.
-- pub fn dynamic_update_packed(body, inertia, simulation, reactions) -> DynamicUpdateResult
function dynamic_update.dynamic_update_packed(
	body: { number },
	inertia: { number },
	simulation: SimulationStep,
	reactions: { number }
): DynamicUpdateResult
	local dt = splat(simulation.time_step)
	local linear = madd(madd(load(body, 36), dt, load(body, 8)), dt, load(reactions, 0))
	local angular = madd(madd(load(body, 40), dt, load(body, 12)), dt, load(reactions, 8))
	local position = add(add(load(body, 4), load(reactions, 4)), linear)
	store_xyz(body, 4, position)
	local rotation = add(angular, load(reactions, 12))
	local q = dynamic_update.orientation(load(body, 0), rotation)
	for i = 1, 4 do
		body[i] = to_bits(q[i])
	end
	local basis = dynamic_update.quaternion_basis(q)
	store_xyz(body, 16, basis[1])
	store_xyz(body, 20, basis[2])
	store_xyz(body, 24, basis[3])
	local tensor = { inertia[1], inertia[2], inertia[3] }
	local full, split = dynamic_update.inverse_inertia(basis, tensor)
	store_xyz(body, 28, full)
	store_xyz(body, 32, split)
	local function rate(drag: number): number
		local difference = f32(simulation.frequency - from_bits(drag))
		return if difference > 0.0 then difference else 0.0
	end
	local omega, angular_squared = cap(mul(angular, splat(rate(inertia[10]))), from_bits(inertia[8]))
	local velocity, linear_squared = cap(mul(linear, splat(rate(inertia[9]))), from_bits(inertia[7]))
	-- Scalar fmuls followed by fmadds; cap branches publish the squared cap,
	-- rather than recalculating squared speed from the rounded scaled vector.
	local factor = f32(from_bits(inertia[6]) * from_bits(body[32]))
	local energy = mul_add(factor, angular_squared, linear_squared)
	-- S3 82AE6974 / S2 82AE487C: bge tests LT clear, including unordered.
	-- Do not replace this with >=; the host predicate below is intentional.
	if not (energy < simulation.minimum_energy) then
		body[44] = 0
	else
		local cooldown = if not (energy > from_bits(body[40])) then rt.wrapping_add_u32(body[44], 1) else body[44]
		body[44] = math.min(cooldown, simulation.cool_down)
	end
	body[40] = to_bits(energy)
	store_xyz(body, 8, velocity)
	store_xyz(body, 12, omega)
	rt.fill(reactions, 0, #reactions, 0)
	local gravity = simulation.gravity_acceleration
	store_xyz(body, 36, { gravity.x, gravity.y, gravity.z, 0.0 })
	store_xyz(body, 40, splat(0.0))
	return {
		orientation_displacement = { rotation[1], rotation[2], rotation[3] },
		linear_speed_squared = linear_squared,
		angular_speed_squared = angular_squared,
	}
end

return dynamic_update
