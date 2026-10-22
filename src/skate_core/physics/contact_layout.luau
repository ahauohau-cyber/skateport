--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact_layout.rs (коммит 2e16697)
--
-- Serialization of the uncompiled TU3 256-byte contact, in guest word order.

local rt = require("../../rt")
local contact = require("./contact")

local to_bits = rt.to_bits

type Vector3 = vector

local contact_layout = {}

local function lanes(v: Vector3, w: number): { number }
	return { to_bits(v.x), to_bits(v.y), to_bits(v.z), w }
end

local function workspace(w: contact.RetailContactWorkspace): { { number } }
	return {
		lanes(w.center_of_mass, w.reaction_id),
		lanes(w.inverse_inertia_full, to_bits(w.inverse_mass)),
		lanes(w.inverse_inertia_split, w.state),
		lanes(w.force_acceleration, to_bits(w.kinetic_energy)),
		lanes(w.torque_acceleration, w.cool_down),
	}
end

-- pub(super) fn encode(c: RetailContact) -> [u32; 64]
function contact_layout.encode(c: contact.RetailContact): { number }
	local words = rt.zeros(64)
	local header = {
		lanes(c.position_on_a, c.body_a_id),
		lanes(c.position_on_b, c.body_b_id),
		lanes(c.normal, to_bits(c.restitution)),
		lanes(c.tangent_0, to_bits(c.static_friction)),
		lanes(c.tangent_1, to_bits(c.dynamic_friction)),
		lanes(c.relative_velocity, c.tag),
	}
	for i, v in header do
		rt.copy_into(words, (i - 1) * 4, v)
	end
	local a, b = workspace(c.body_a_workspace), workspace(c.body_b_workspace)
	for i = 1, 5 do
		rt.copy_into(words, 24 + (i - 1) * 8, a[i])
		rt.copy_into(words, 28 + (i - 1) * 8, b[i])
	end
	return words
end

return contact_layout
