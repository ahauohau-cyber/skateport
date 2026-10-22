--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/packed.rs (коммит 2e16697)
--
-- Native solver records with host indices replacing guest reaction pointers.

local contact = require("./contact")
local drive = require("./drive")
local joint = require("./joint")

local packed = {}

-- pub struct Constraint<const WORDS: usize>
-- ROBLOX: Contact = 64 слова, Joint и Drive = 96 слов. Индексы реакций —
-- как в Rust, с нуля (реакция i лежит в reactions[i + 1]).
export type Constraint = {
	words: { number },
	reaction_a: number,
	reaction_b: number,
}
export type Contact = Constraint
export type Joint = Constraint
export type Drive = Constraint
-- pub type Reaction = [u32; 16]
export type Reaction = { number }

local function validate(constraints: { Constraint }, count: number)
	for _, c in constraints do
		assert(c.reaction_a ~= c.reaction_b)
		assert(c.reaction_a < count and c.reaction_b < count)
	end
end

local function pass(constraints: { Constraint }, reactions: { Reaction }, kernel: ({ number }, { number }, { number }) -> ())
	for _, c in constraints do
		-- ROBLOX: split_at_mut не нужен — таблицы реакций передаются по ссылке.
		kernel(c.words, reactions[c.reaction_a + 1], reactions[c.reaction_b + 1])
	end
end

-- Complete contact → joint → drive loops of HorusPipeline (82AE27D0).
-- Contact position corrections remain distinct from velocity-producing
-- reactions; all families see preceding writes during the same iteration.
-- pub fn solve(contacts, joints, drives, reactions, iterations)
function packed.solve(contacts: { Contact }, joints: { Joint }, drives: { Drive }, reactions: { Reaction }, iterations: number)
	validate(contacts, #reactions)
	validate(joints, #reactions)
	validate(drives, #reactions)
	for _ = 1, iterations do
		pass(contacts, reactions, contact.solve)
		pass(joints, reactions, joint.solve)
		pass(drives, reactions, drive.solve)
	end
end

return packed
