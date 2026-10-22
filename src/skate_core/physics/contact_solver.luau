--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact_solver.rs (коммит 2e16697)
--
-- TU3 ContactBatchBuild and the shared Horus contact solver.
-- Typed contacts are encoded only at the compiled-row boundary.

local rt = require("../../rt")
local contact = require("./contact")
local contact_layout = require("./contact_layout")
local rigid_body = require("./rigid_body")

local from_bits = rt.from_bits

type Vector3 = vector

local contact_solver = {}

contact_solver.tu3 = {
	CONTACT_BATCH_BUILD = 0x82AE_10C8,
	ITERATIVE_CONSTRAINT_SOLVER = 0x82AE_27D0,
}
contact_solver.ACTIVE_BODY = 4

-- pub struct RetailContactJacobian
-- ROBLOX: индексы реакций с нуля, как в Rust.
export type RetailContactJacobian = {
	words: { number },
	reaction_index_a: number,
	reaction_index_b: number,
}

local RetailContactJacobian = {}
contact_solver.RetailContactJacobian = RetailContactJacobian

local function lanes(self: RetailContactJacobian, v: number): { number }
	return {
		from_bits(self.words[v * 4 + 1]),
		from_bits(self.words[v * 4 + 2]),
		from_bits(self.words[v * 4 + 3]),
		from_bits(self.words[v * 4 + 4]),
	}
end

local function xyz(self: RetailContactJacobian, v: number): Vector3
	local l = lanes(self, v)
	return vector.create(l[1], l[2], l[3])
end

-- Native compiled layout, for inspection and independent comparisons.
function RetailContactJacobian.words(self: RetailContactJacobian): { number }
	return self.words
end
function RetailContactJacobian.accumulated_impulse(self: RetailContactJacobian): { number }
	return lanes(self, 5)
end
-- Weighted velocity targets in xyz and position-only target in w.
function RetailContactJacobian.target_impulse(self: RetailContactJacobian): { number }
	return lanes(self, 6)
end
function RetailContactJacobian.static_friction(self: RetailContactJacobian): number
	return from_bits(self.words[16])
end
function RetailContactJacobian.dynamic_friction(self: RetailContactJacobian): number
	return from_bits(self.words[20])
end
function RetailContactJacobian.angular_response_a(self: RetailContactJacobian): { Vector3 }
	return { xyz(self, 8), xyz(self, 11), xyz(self, 14) }
end
function RetailContactJacobian.angular_response_b(self: RetailContactJacobian): { Vector3 }
	return { xyz(self, 9), xyz(self, 12), xyz(self, 15) }
end

-- Requests native contact construction. Each input body workspace must
-- include forces accumulated for this tick.
-- pub fn build_contact_jacobian(contact: RetailContact, time_step: f32) -> RetailContactJacobian
function contact_solver.build_contact_jacobian(c: contact.RetailContact, time_step: number): RetailContactJacobian
	assert(rt.is_finite(time_step) and time_step > 0.0)
	local words = contact_layout.encode(c)
	local solver = require("./solver") :: any
	solver.compile_contact(words, time_step)
	return {
		words = words,
		reaction_index_a = c.body_a_workspace.reaction_id,
		reaction_index_b = c.body_b_workspace.reaction_id,
	}
end

-- Contact-only entry point uses the same kernel and reaction layout as the
-- complete contact -> joint -> drive iteration. Friction reads the preceding
-- normal impulse, before this pass publishes its new normal impulse.
function contact_solver.solve_contact_jacobians(
	contacts: { RetailContactJacobian },
	reactions: { rigid_body.RetailReactionCorrections },
	maximum_iterations: number
)
	local solver = require("./solver") :: any
	solver.solve_constraints(contacts, {}, {}, reactions, maximum_iterations)
end

function contact_solver.solve_contact_jacobian_iteration(contacts: { RetailContactJacobian }, reactions: { rigid_body.RetailReactionCorrections })
	contact_solver.solve_contact_jacobians(contacts, reactions, 1)
end

return contact_solver
