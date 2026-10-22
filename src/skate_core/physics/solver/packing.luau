--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/packing.rs (коммит 2e16697)
--
-- Semantic builder outputs → native compiled-record layout.

local rt = require("../../../rt")
local packed = require("./packed")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type Vector3 = vector

local packing = {}

local function row(words: { number }, i: number, v: { number }, w: number)
	words[4 * i + 1] = to_bits(v[1])
	words[4 * i + 2] = to_bits(v[2])
	words[4 * i + 3] = to_bits(v[3])
	words[4 * i + 4] = to_bits(w)
end

local function xyz(v: Vector3): { number }
	return { v.x, v.y, v.z }
end

local function vec(words: { number }, i: number, v: Vector3, w: number)
	row(words, i, xyz(v), w)
end

local function inertia_columns(i: any): { Vector3 }
	return {
		vector.create(i.full.x, i.full.y, i.full.z),
		vector.create(i.full.y, i.split.y, i.split.z),
		vector.create(i.full.z, i.split.z, i.split.x),
	}
end

-- pub(super) fn contact(c: &RetailContactJacobian) -> packed::Contact
function packing.contact(c: any): packed.Contact
	return { words = table.clone(c.words), reaction_a = c.reaction_index_a, reaction_b = c.reaction_index_b }
end

-- pub(super) fn drive(d: &RetailDriveRows) -> packed::Drive
function packing.drive(d: any): packed.Drive
	local words = rt.zeros(96)
	vec(words, 0, d.arm_a, 0.0)
	vec(words, 1, d.arm_b, 0.0)
	row(words, 2, d.accumulated_linear_impulse, d.linear_softness)
	row(words, 3, d.accumulated_angular_impulse, d.angular_softness)
	for component = 1, 3 do
		local lin, ang = {}, {}
		for r = 1, 3 do
			lin[r] = f32(xyz(d.linear_axes[r])[component] * d.linear_inverse_effective_mass[r])
			ang[r] = f32(xyz(d.angular_axes[r])[component] * d.angular_inverse_effective_mass[r])
		end
		row(words, 4 + (component - 1) * 2, lin, 0.0)
		row(words, 5 + (component - 1) * 2, ang, 0.0)
		vec(words, 12 + component - 1, d.linear_axes[component], 0.0)
		vec(words, 15 + component - 1, d.angular_axes[component], 0.0)
	end
	row(words, 10, d.linear_target_impulse, d.linear_maximum_impulse[3])
	row(words, 11, d.angular_target_impulse, d.angular_maximum_impulse[3])
	words[6 * 4 + 3 + 1] = to_bits(d.linear_maximum_impulse[1])
	words[7 * 4 + 3 + 1] = to_bits(d.linear_maximum_impulse[2])
	words[8 * 4 + 3 + 1] = to_bits(d.angular_maximum_impulse[1])
	words[9 * 4 + 3 + 1] = to_bits(d.angular_maximum_impulse[2])
	for _, item in { { 18, d.frame_a_body }, { 21, d.frame_b_body } } do
		local index, body = item[1], item[2]
		if bit32.band(body.state, 4) ~= 0 then
			for i, column in inertia_columns(body.world_inverse_inertia) do
				vec(words, index + i - 1, column, if i == 1 then body.inverse_mass else 0.0)
			end
		end
	end
	return { words = words, reaction_a = d.frame_a_body.reaction_index, reaction_b = d.frame_b_body.reaction_index }
end

-- pub(super) fn reaction(r: RetailReactionCorrections) -> packed::Reaction
function packing.reaction(r: any): packed.Reaction
	local words = rt.zeros(16)
	for i, v in { r.linear_displacement, r.position_displacement, r.angular_displacement, r.orientation_displacement } do
		vec(words, i - 1, v, 0.0)
	end
	return words
end

function packing.read_xyz(words: { number }, i: number): { number }
	return { from_bits(words[4 * i + 1]), from_bits(words[4 * i + 2]), from_bits(words[4 * i + 3]) }
end

function packing.unpack_reaction(words: packed.Reaction): any
	local function v(i: number): Vector3
		local x = packing.read_xyz(words, i)
		return vector.create(x[1], x[2], x[3])
	end
	return {
		linear_displacement = v(0),
		position_displacement = v(1),
		angular_displacement = v(2),
		orientation_displacement = v(3),
	}
end

return packing
