--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/contact_build/publication.rs (коммит 2e16697)
--
-- Scaled Jacobian and restitution target publication, `82AE1590..82AE15F4`.

local rt = require("../../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local to_bits = rt.to_bits

type Vector3 = vector

local publication = {}

local function vector_row(words: { number }, row: number, xyz: Vector3, carry: number)
	words[row * 4 + 1] = to_bits(xyz.x)
	words[row * 4 + 2] = to_bits(xyz.y)
	words[row * 4 + 3] = to_bits(xyz.z)
	words[row * 4 + 4] = carry
end

local function float_row(words: { number }, row: number, values: { number })
	for lane = 1, 4 do
		words[row * 4 + lane] = to_bits(values[lane])
	end
end

-- pub(super) fn compile(prepared: &ContactPreparation, inverse_response: [f32; 3]) -> [u32; 64]
function publication.compile(prepared: any, inverse_response: { number }): { number }
	local words = rt.zeros(64)
	for body = 0, 1 do
		vector_row(words, body, prepared.arms[body + 1], prepared.reaction_ids[body + 1])
	end
	local axes = {}
	for axis = 1, 3 do
		local a = prepared.axes[axis]
		axes[axis] = { a.x, a.y, a.z }
	end
	local carry = { prepared.combined_state_bit_8, prepared.static_friction_bits, prepared.dynamic_friction_bits }
	for component = 1, 3 do
		local column = {}
		for axis = 1, 3 do
			column[axis] = mul_add(axes[axis][component], inverse_response[axis], 0.0)
		end
		vector_row(words, 2 + component - 1, vector.create(column[1], column[2], column[3]), carry[component])
	end
	-- Row 5 is the newly cleared accumulated impulse, including its carry.
	local separation = mul_add(prepared.separation_projection[1], inverse_response[1], 0.0)
	local restitution = mul_add(prepared.restitution_projection[1], inverse_response[1], 0.0)
	local predicted = {}
	for axis = 1, 3 do
		predicted[axis] = mul_add(prepared.predicted_separation_projection[axis], inverse_response[axis], 0.0)
	end
	local normal_adjustment = if restitution >= 0.0 then 0.0 else f32(separation + restitution)
	if separation >= 0.0 then
		normal_adjustment = restitution
	end
	if 0.0 >= predicted[1] then
		normal_adjustment = 0.0
	end
	float_row(words, 6, {
		f32(predicted[1] - normal_adjustment),
		f32(predicted[2] - 0.0),
		f32(predicted[3] - 0.0),
		separation,
	})
	local identifiers = { prepared.body_ids[1], prepared.body_ids[2], prepared.contact_tag }
	for axis = 0, 2 do
		vector_row(words, 7 + axis * 3, prepared.axes[axis + 1], identifiers[axis + 1])
		local a = table.clone(prepared.angular_response_a[axis + 1])
		local b = table.clone(prepared.angular_response_b[axis + 1])
		if axis == 0 then
			a[4] = prepared.inverse_mass[1]
			b[4] = prepared.inverse_mass[2]
		end
		float_row(words, 8 + axis * 3, a)
		float_row(words, 9 + axis * 3, b)
	end
	return words
end

return publication
