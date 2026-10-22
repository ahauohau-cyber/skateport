--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/joint_solver.rs (коммит 2e16697)
--
-- Semantic port of Skate 3 TU3's six-degree joint iteration.
--
-- Skate 3 builds one 384-byte `JointJacobian` for each of the six skateboard
-- assembly joints. `rw::physics::Simulation::Solve` visits contacts, joints,
-- and drives in that order on each configured outer iteration. The joint loop
-- starts near `0x82AE2BC8`; the loop near `0x82AE2E78` is the drive family.

local rt = require("../../rt")
local rigid_body = require("./rigid_body")

local from_bits = rt.from_bits
local to_bits = rt.to_bits

local joint_solver = {}

joint_solver.tu3 = {
	SIMULATION_SOLVE = 0x82AE_27D0,
	JOINT_SOLVE_LOOP = 0x82AE_2BC8,
	DRIVE_SOLVE_LOOP = 0x82AE_2E78,
	JOINT_BATCH_BUILD = 0x82AE_39D0,
	JOINT_JACOBIAN_BUILD = 0x82AE_3BC8,
	JACOBIAN_BYTES = 384,
	REACTION_BYTES = 64,
}

local JACOBIAN_WORDS = joint_solver.tu3.JACOBIAN_BYTES // 4
local REACTION_WORDS = joint_solver.tu3.REACTION_BYTES // 4

-- Raw guest word order of TU3's 384-byte `JointJacobian` (96 слов).
export type RetailJointJacobian = { words: { number } }

-- Four raw vectors indexed by a rigid body's solver id (16 слов).
export type RetailJointReactionBlock = { words: { number } }

local RetailJointJacobian = {}
joint_solver.RetailJointJacobian = RetailJointJacobian

function RetailJointJacobian.zeroed(): RetailJointJacobian
	return { words = rt.zeros(JACOBIAN_WORDS) }
end

local RetailJointReactionBlock = {}
joint_solver.RetailJointReactionBlock = RetailJointReactionBlock

-- #[derive(Default)]
function RetailJointReactionBlock.default(): RetailJointReactionBlock
	return { words = rt.zeros(REACTION_WORDS) }
end

-- Packs the two reaction vectors consumed by the joint-family branch.
-- TU3 leaves reaction vectors one and three to the contact family's
-- position/orientation correction.
function RetailJointReactionBlock.from_reactions(reactions: rigid_body.RetailReactionCorrections): RetailJointReactionBlock
	local words = rt.zeros(REACTION_WORDS)
	words[1] = to_bits(reactions.linear_displacement.x)
	words[2] = to_bits(reactions.linear_displacement.y)
	words[3] = to_bits(reactions.linear_displacement.z)
	words[9] = to_bits(reactions.angular_displacement.x)
	words[10] = to_bits(reactions.angular_displacement.y)
	words[11] = to_bits(reactions.angular_displacement.z)
	return { words = words }
end

-- Writes back only the two joint-owned velocity correction vectors.
-- ROBLOX: `&mut RetailReactionCorrections` — поля таблицы меняются на месте.
function RetailJointReactionBlock.write_velocity_reactions(self: RetailJointReactionBlock, reactions: rigid_body.RetailReactionCorrections)
	local w = self.words
	reactions.linear_displacement = vector.create(from_bits(w[1]), from_bits(w[2]), from_bits(w[3]))
	reactions.angular_displacement = vector.create(from_bits(w[9]), from_bits(w[10]), from_bits(w[11]))
end

-- One joint pass using TU3's fused vector operations and projector.
function joint_solver.solve_joint_iteration(
	jacobian: RetailJointJacobian,
	reaction_a: RetailJointReactionBlock,
	reaction_b: RetailJointReactionBlock
)
	local solver = require("./solver") :: any
	solver.solve_joint_record(jacobian.words, reaction_a.words, reaction_b.words)
end

return joint_solver
