--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/contact_build/input.rs (коммит 2e16697)
--
-- Decodes the uncompiled contact copied by the native contact producer.

local rt = require("../../../../rt")

local from_bits = rt.from_bits

type Vector3 = vector

local input = {}

export type BodyInput = {
	center: Vector3,
	inverse_inertia_full: Vector3,
	inverse_inertia_split: Vector3,
	inverse_mass: number,
	state: number,
	force_acceleration: Vector3,
	torque_acceleration: Vector3,
	reaction_id: number,
}

export type ContactInput = {
	positions: { Vector3 },
	axes: { Vector3 },
	relative_velocity: Vector3,
	restitution: number,
	bodies: { BodyInput },
	body_ids: { number },
	static_friction_bits: number,
	dynamic_friction_bits: number,
	contact_tag: number,
}

-- ROBLOX: words — таблица из 64 слов u32, слово k лежит в [k + 1].
local function vec(words: { number }, row: number): Vector3
	return vector.create(from_bits(words[row * 4 + 1]), from_bits(words[row * 4 + 2]), from_bits(words[row * 4 + 3]))
end

local ContactInput = {}
input.ContactInput = ContactInput

-- pub fn decode(words: &[u32; 64]) -> Self
function ContactInput.decode(words: { number }): ContactInput
	local bodies = {}
	for body = 0, 1 do
		bodies[body + 1] = {
			center = vec(words, 6 + body),
			inverse_inertia_full = vec(words, 8 + body),
			inverse_inertia_split = vec(words, 10 + body),
			inverse_mass = from_bits(words[(8 + body) * 4 + 3 + 1]),
			state = words[(10 + body) * 4 + 3 + 1],
			force_acceleration = vec(words, 12 + body),
			torque_acceleration = vec(words, 14 + body),
			reaction_id = words[(6 + body) * 4 + 3 + 1],
		}
	end
	return {
		positions = { vec(words, 0), vec(words, 1) },
		axes = { vec(words, 2), vec(words, 3), vec(words, 4) },
		relative_velocity = vec(words, 5),
		restitution = from_bits(words[12]),
		bodies = bodies,
		body_ids = { words[4], words[8] },
		static_friction_bits = words[16],
		dynamic_friction_bits = words[20],
		contact_tag = words[24],
	}
end

return input
