--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver.rs (коммит 2e16697)
--
-- Shared TU3 constraint iteration (`0x82AE27D0`).
--
-- Constraint families must exchange reactions on every pass. Solving each
-- family to completion independently changes the physical result.

local contact_build = require("@self/contact_build")
local joint = require("@self/joint")
local packed = require("@self/packed")
local packing = require("@self/packing")

local solver = {}

-- pub(crate) fn compile_contact(record: &mut [u32; 64], time_step: f32)
function solver.compile_contact(record: { number }, time_step: number)
	contact_build.build(record, time_step)
end

-- pub(crate) fn solve_joint_record(record, a, b)
function solver.solve_joint_record(record: { number }, a: { number }, b: { number })
	joint.solve(record, a, b)
end

-- Host indices replace the two guest reaction pointers stored in a Jacobian.
-- ROBLOX: индексы реакций с нуля, как в Rust.
export type JointConstraint = {
	jacobian: { words: { number } },
	reaction_a: number,
	reaction_b: number,
}

-- Runs the retail contact → joint → drive ordering. The caller clears the
-- reaction workspace and builds fresh rows once per simulation step.
-- ROBLOX: `&mut [T]` — таблицы меняются на месте (как запись обратно в Rust).
function solver.solve_constraints(contacts: { any }, joints: { JointConstraint }, drives: { any }, reactions: { any }, iterations: number)
	local c = {}
	for i, contact in contacts do
		c[i] = packing.contact(contact)
	end
	local j = {}
	for i, jn in joints do
		j[i] = { words = table.clone(jn.jacobian.words), reaction_a = jn.reaction_a, reaction_b = jn.reaction_b }
	end
	local d = {}
	for i, drive in drives do
		d[i] = packing.drive(drive)
	end
	local r = {}
	for i, reaction in reactions do
		r[i] = packing.reaction(reaction)
	end
	packed.solve(c, j, d, r, iterations)
	for i, contact in contacts do
		contact.words = c[i].words
	end
	for i, jn in joints do
		jn.jacobian.words = j[i].words
	end
	for i, drive in drives do
		drive.accumulated_linear_impulse = packing.read_xyz(d[i].words, 2)
		drive.accumulated_angular_impulse = packing.read_xyz(d[i].words, 3)
	end
	for i = 1, #reactions do
		local u = packing.unpack_reaction(r[i])
		-- ROBLOX: `*reaction = ...` — переписываем поля той же таблицы.
		local reaction = reactions[i]
		reaction.linear_displacement = u.linear_displacement
		reaction.position_displacement = u.position_displacement
		reaction.angular_displacement = u.angular_displacement
		reaction.orientation_displacement = u.orientation_displacement
	end
end

return solver
