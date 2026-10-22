--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/contact_build/geometry.rs (коммит 2e16697)
--
-- Contact arms and inverse-inertia response, `82AE11BC..82AE1588`.

local rt = require("../../../../rt")
local input_mod = require("./input")

local f32 = rt.f32
local mul_add = rt.mul_add

type Vector3 = vector

local geometry = {}

-- ROBLOX: ContactPreparation объявлен в contact_build/init.luau; здесь только
-- сборка таблицы с теми же полями (init подключает этот файл).

local function components(v: Vector3): { number }
	return { v.x, v.y, v.z }
end

local function difference(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x - b.x), f32(a.y - b.y), f32(a.z - b.z))
end

local function cross(arm: Vector3, axis: Vector3): { number }
	return {
		mul_add(-arm.z, axis.y, mul_add(arm.y, axis.z, 0.0)),
		mul_add(-arm.x, axis.z, mul_add(arm.z, axis.x, 0.0)),
		mul_add(-arm.y, axis.x, mul_add(arm.x, axis.y, 0.0)),
	}
end

local function inertia_response(full: Vector3, split: Vector3, mass: number, jacobian: { number }): { number }
	local columns = {
		{ full.x, full.y, full.z, mass },
		{ full.y, split.y, split.z, mass },
		{ full.z, split.z, split.x, mass },
	}
	local out = {}
	for component = 1, 4 do
		local first = mul_add(columns[1][component], jacobian[1], 0.0)
		local second = mul_add(columns[2][component], jacobian[2], first)
		out[component] = mul_add(columns[3][component], jacobian[3], second)
	end
	return out
end

local function project(axes: { Vector3 }, value: Vector3): { number }
	local out = {}
	for i, axis in axes do
		local x = mul_add(axis.x, value.x, 0.0)
		local xy = mul_add(axis.y, value.y, x)
		out[i] = mul_add(axis.z, value.z, xy)
	end
	return out
end

-- pub(super) fn prepare(input: ContactInput, time_step: f32) -> ContactPreparation
function geometry.prepare(input: input_mod.ContactInput, time_step: number): any
	local arms = {
		difference(input.positions[1], input.bodies[1].center),
		difference(input.positions[2], input.bodies[2].center),
	}
	local active = {
		bit32.band(input.bodies[1].state, 4) == 4,
		bit32.band(input.bodies[2].state, 4) == 4,
	}
	local inverse_mass = {
		if active[1] then input.bodies[1].inverse_mass else 0.0,
		if active[2] then input.bodies[2].inverse_mass else 0.0,
	}
	local jacobians = {}
	for body = 1, 2 do
		jacobians[body] = {}
		for axis = 1, 3 do
			jacobians[body][axis] = cross(arms[body], input.axes[axis])
		end
	end
	local zero = vector.create(0, 0, 0)
	local responses = {}
	for body = 1, 2 do
		local full = if active[body] then input.bodies[body].inverse_inertia_full else zero
		local split = if active[body] then input.bodies[body].inverse_inertia_split else zero
		responses[body] = {}
		for axis = 1, 3 do
			responses[body][axis] = inertia_response(full, split, inverse_mass[body], jacobians[body][axis])
		end
	end
	local effective_mass = {}
	for axis = 1, 3 do
		local products = {}
		for component = 1, 3 do
			local a = mul_add(jacobians[1][axis][component], responses[1][axis][component], 0.0)
			products[component] = mul_add(jacobians[2][axis][component], responses[2][axis][component], a)
		end
		effective_mass[axis] =
			f32(f32(products[3] + f32(products[1] + inverse_mass[1])) + f32(products[2] + inverse_mass[2]))
	end
	local point_acceleration = {}
	for body = 1, 2 do
		if not active[body] then
			point_acceleration[body] = zero
		else
			local arm = arms[body]
			local force = input.bodies[body].force_acceleration
			local torque = input.bodies[body].torque_acceleration
			point_acceleration[body] = vector.create(
				mul_add(arm.z, torque.y, mul_add(-arm.y, torque.z, force.x)),
				mul_add(arm.x, torque.z, mul_add(-arm.z, torque.x, force.y)),
				mul_add(arm.y, torque.x, mul_add(-arm.x, torque.y, force.z))
			)
		end
	end
	local separation = difference(input.positions[2], input.positions[1])
	local relative_acceleration = difference(point_acceleration[2], point_acceleration[1])
	local time_squared = f32(time_step * time_step)
	local scaled_velocity, acceleration = {}, {}
	local rv, ra, sep = components(input.relative_velocity), components(relative_acceleration), components(separation)
	for i = 1, 3 do
		scaled_velocity[i] = mul_add(time_step, rv[i], 0.0)
		acceleration[i] = mul_add(ra[i], time_squared, 0.0)
	end
	local predicted, restitution = {}, {}
	for i = 1, 3 do
		predicted[i] = f32(scaled_velocity[i] + f32(sep[i] + acceleration[i]))
		restitution[i] = mul_add(-scaled_velocity[i], input.restitution, 0.0)
	end
	return {
		arms = arms,
		axes = input.axes,
		active = active,
		inverse_mass = inverse_mass,
		point_acceleration = point_acceleration,
		angular_response_a = responses[1],
		angular_response_b = responses[2],
		effective_mass = effective_mass,
		separation_projection = project(input.axes, separation),
		restitution_projection = project(input.axes, vector.create(restitution[1], restitution[2], restitution[3])),
		predicted_separation_projection = project(input.axes, vector.create(predicted[1], predicted[2], predicted[3])),
		reaction_ids = { input.bodies[1].reaction_id, input.bodies[2].reaction_id },
		body_ids = input.body_ids,
		static_friction_bits = input.static_friction_bits,
		dynamic_friction_bits = input.dynamic_friction_bits,
		contact_tag = input.contact_tag,
		combined_state_bit_8 = bit32.band(bit32.bor(input.bodies[1].state, input.bodies[2].state), 8),
	}
end

return geometry
