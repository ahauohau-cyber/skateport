--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/packed.rs (коммит 2e16697)
--
-- Native solver records with host indices replacing guest reaction pointers.

local rt = require("../../../rt")
local contact = require("./contact")
local drive = require("./drive")
local joint = require("./joint")

local from_bits = rt.from_bits
local to_bits = rt.to_bits

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

-- ROBLOX: слова записи -> числа один раз до итераций (from_bits), обратно — один
-- раз после (to_bits), и только те слова, которые ядра пишут. Это та же
-- арифметика без тысяч переводов на каждом проходе.
local function floats(words: { number }): { number }
	local out = table.create(#words) :: { number }
	for i, w in words do
		out[i] = from_bits(w)
	end
	return out
end

local function store(words: { number }, values: { number }, from: number, to: number)
	for i = from, to do
		words[i] = to_bits(values[i])
	end
end

local function pass_floats(constraints: { Constraint }, views: { { number } }, reactions: { { number } }, kernel: ({ number }, { number }, { number }) -> ())
	for i, c in constraints do
		kernel(views[i], reactions[c.reaction_a + 1], reactions[c.reaction_b + 1])
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
	if iterations == 0 then
		return
	end
	local fc, fj, fd, fr = {}, {}, {}, {}
	for i, c in contacts do
		fc[i] = floats(c.words)
	end
	for i, j in joints do
		fj[i] = floats(j.words)
	end
	for i, d in drives do
		fd[i] = floats(d.words)
	end
	for i, r in reactions do
		fr[i] = floats(r)
	end
	for _ = 1, iterations do
		pass_floats(contacts, fc, fr, contact.solve_floats)
		pass_floats(joints, fj, fr, joint.solve_floats)
		pass_floats(drives, fd, fr, drive.solve_floats)
	end
	-- Ядра пишут: контакт — слова 20..23 (накопленный импульс), шарнир и привод —
	-- слова 8..15 (накопленные импульсы), реакции — все 16 слов.
	for i, c in contacts do
		store(c.words, fc[i], 21, 24)
	end
	for i, j in joints do
		store(j.words, fj[i], 9, 16)
	end
	for i, d in drives do
		store(d.words, fd[i], 9, 16)
	end
	for i, r in reactions do
		store(r, fr[i], 1, 16)
	end
end

-- ROBLOX: исходный вариант прохода по словам (как в Rust), для сверки.
function packed.solve_words(contacts: { Contact }, joints: { Joint }, drives: { Drive }, reactions: { Reaction }, iterations: number)
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
