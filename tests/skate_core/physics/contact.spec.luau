--!strict
-- Перенос Rust-тестов crates/skate-core/src/physics/tests/contact.rs.

local harness = require("../../harness")
local rt = require("../../../src/rt")
local contact = require("../../../src/skate_core/physics/contact")

local fb = rt.from_bits

local function body(contact_body_id: number, center_of_mass: vector): contact.RetailContactBodyState
	return {
		contact_body_id = contact_body_id,
		center_of_mass = center_of_mass,
		reaction_id = contact_body_id + 10,
		inverse_inertia_full = vector.create(1, 2, 3),
		inverse_mass = 0.25,
		inverse_inertia_split = vector.create(4, 5, 6),
		state = 7,
		force_acceleration = vector.create(8, 9, 10),
		kinetic_energy = 11.0,
		torque_acceleration = vector.create(12, 13, 14),
		cool_down = 15,
		linear_velocity = vector.zero,
		angular_velocity = vector.zero,
	}
end

local function input(normal: vector): contact.RetailContactInput
	return {
		position_on_a = vector.create(2, 3, 4),
		position_on_b = vector.create(2, 3, 4),
		normal = normal,
		-- ROBLOX: литералы f32 в Rust (0.1, 0.8, 0.7) -> округляем до f32.
		restitution = rt.f32(0.1),
		static_friction = rt.f32(0.8),
		dynamic_friction = rt.f32(0.7),
		tag = 0x1234_5678,
	}
end

local function close(actual: number, expected: number): boolean
	return math.abs(actual - expected) <= 1.0e-6
end

local function vec_close(actual: vector, expected: vector): boolean
	return close(actual.x, expected.x) and close(actual.y, expected.y) and close(actual.z, expected.z)
end

return function(report: harness.Report)
	harness.test(report, "contact: material_combine_matches_tu3_branch_directions", function()
		local combined = contact.combine_contact_materials({
			static_friction = fb(0x3F4C_CCCD),
			dynamic_friction = fb(0x3F33_3333),
			restitution = fb(0x3E4C_CCCD),
		}, {
			static_friction = fb(0x3F00_0000),
			dynamic_friction = fb(0x3F66_6666),
			restitution = fb(0x3DCC_CCCD),
		})
		harness.check(rt.to_bits(combined.static_friction) == 0x3F4C_CCCD, "static")
		harness.check(rt.to_bits(combined.dynamic_friction) == 0x3F66_6666, "dynamic")
		harness.check(rt.to_bits(combined.restitution) == 0x3DCC_CCCD, "restitution")
	end)

	harness.test(report, "contact: material_combine_is_commutative_for_finite_values", function()
		local a = { static_friction = rt.f32(0.8), dynamic_friction = rt.f32(0.7), restitution = 0.0 }
		local b = { static_friction = 0.5, dynamic_friction = rt.f32(0.9), restitution = rt.f32(0.2) }
		local ab = contact.combine_contact_materials(a, b)
		local ba = contact.combine_contact_materials(b, a)
		harness.check(
			ab.static_friction == ba.static_friction
				and ab.dynamic_friction == ba.dynamic_friction
				and ab.restitution == ba.restitution,
			"not commutative"
		)
	end)

	harness.test(report, "contact: angular_contact_rates_use_omega_cross_arm", function()
		local body_a = body(1, vector.create(1, 3, 4))
		body_a.angular_velocity = vector.create(0, 0, 2)
		local c = contact.generate_contact(input(vector.create(0, -1, 0)), body_a, body(2, vector.create(2, 3, 4)))
		harness.check(vec_close(c.relative_velocity, vector.create(0, -2, 0)), "relative velocity")
	end)

	harness.test(report, "contact: contact_frame_is_orthogonal", function()
		local normal = vector.create(0.36, 0.48, 0.8)
		local body_b = body(2, vector.zero)
		body_b.linear_velocity = vector.create(2, -1, 0.5)
		local c = contact.generate_contact(input(normal), body(1, vector.zero), body_b)
		harness.check(close(contact.dot(c.normal, c.tangent_0), 0), "n.t0")
		harness.check(close(contact.dot(c.normal, c.tangent_1), 0), "n.t1")
		harness.check(close(contact.dot(c.tangent_0, c.tangent_1), 0), "t0.t1")
		harness.check(vec_close(contact.cross(c.normal, c.tangent_0), c.tangent_1), "n x t0 = t1")
	end)

	harness.test(report, "contact: contact_copies_header_ids_materials_tag_and_body_workspaces", function()
		local body_a = body(41, vector.create(1, 2, 3))
		local body_b = body(52, vector.create(4, 5, 6))
		local collision = input(vector.create(0, 1, 0))
		local c = contact.generate_contact(collision, body_a, body_b)
		harness.check(c.body_a_id == 41 and c.body_b_id == 52, "ids")
		harness.check(c.restitution == collision.restitution, "restitution")
		harness.check(c.static_friction == collision.static_friction, "static")
		harness.check(c.dynamic_friction == collision.dynamic_friction, "dynamic")
		harness.check(c.tag == collision.tag, "tag")
		harness.check(contact.workspace_eq(c.body_a_workspace, contact.workspace_from_body(body_a)), "workspace a")
		harness.check(contact.workspace_eq(c.body_b_workspace, contact.workspace_from_body(body_b)), "workspace b")
		harness.check(c.body_a_workspace.reaction_id == 51 and c.body_b_workspace.reaction_id == 62, "reaction ids")
	end)

	harness.test(report, "contact: recovered_tangent_constants_keep_their_exact_binary32_bits", function()
		harness.check(rt.to_bits(contact.CONTACT_TANGENT_MINIMUM_SQUARED) == 0x0080_0000, "min squared")
		harness.check(rt.to_bits(contact.CONTACT_FALLBACK_HALF) == 0x3F00_0000, "half")
	end)
end
