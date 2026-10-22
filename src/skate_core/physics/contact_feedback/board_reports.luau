--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact_feedback/board_reports.rs (коммит 2e16697)
--
-- Solver observations consumed by the board's post-physics update.
--
-- TU3 82AE1608 observes completed contact rows after integration; 827682B0
-- then constructs at most sixteen reports per board, in contact order.
-- Rust owns the report storage and part identifiers. No guest pointers or
-- copied native map/locking infrastructure are needed for this single board.

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector3 = vector

local board_reports = {}

-- ROBLOX: CollisionBody из board_step: { kind = "Board", id } |
-- { kind = "Attached", index } | { kind = "StaticWorld" }; part — BodyId (число).
export type BoardContactReport = {
	part: number,
	other: any,
	is_body_a: boolean,
	-- Oriented toward this board, as ContactInfo+16.
	normal: Vector3,
	position: Vector3,
	-- Linear velocities after integration. Native does not add omega cross r.
	relative_linear_velocity: Vector3,
	other_surface: number,
	-- The underlying spy retains A's orientation even in a B-side report.
	normal_force_on_a: Vector3,
	friction_force_on_a: Vector3,
	tangents: { Vector3 },
}

local function vec(words: { number }, offset: number): Vector3
	return vector.create(from_bits(words[offset + 1]), from_bits(words[offset + 2]), from_bits(words[offset + 3]))
end
local function scale(v: Vector3, s: number): Vector3
	return vector.create(f32(v.x * s), f32(v.y * s), f32(v.z * s))
end
local function add(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x + b.x), f32(a.y + b.y), f32(a.z + b.z))
end
local function subtract(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x - b.x), f32(a.y - b.y), f32(a.z - b.z))
end
local function combine(a: Vector3, weight: number, b: Vector3): Vector3
	return vector.create(mul_add(a.x, weight, b.x), mul_add(a.y, weight, b.y), mul_add(a.z, weight, b.z))
end

local function body_of(body: any, bodies: { any }, attached: { any }): any?
	if body.kind == "Board" then
		return bodies[body.id + 1]
	elseif body.kind == "Attached" then
		return attached[body.index + 1]
	end
	return nil
end

local function center(body: any, bodies: { any }, attached: { any }): Vector3
	local b = body_of(body, bodies, attached)
	return if b then b.rates.position else vector.zero
end

local function velocity(body: any, bodies: { any }, attached: { any }): Vector3
	local b = body_of(body, bodies, attached)
	return if b then b.rates.linear_velocity else vector.zero
end

-- Replace this frame's reports from the actual solved rows. All seven board
-- parts share one report budget and one owner; their self contacts are excluded
-- from reporting, independently of whether they participated in the solver.
-- ROBLOX: `output: &mut Vec` — таблица очищается и заполняется на месте.
function board_reports.collect(output: { BoardContactReport }, contacts: { any }, bodies: { any }, attached: { any }, frequency: number)
	local board_step = require("../board_step") :: any
	local CollisionBody = board_step.CollisionBody
	table.clear(output)
	local frequency_squared = f32(frequency * frequency)
	for _, c in contacts do
		local words = c.words
		local impulse = {
			from_bits(words[21]),
			from_bits(words[22]),
			from_bits(words[23]),
			from_bits(words[24]),
		}
		-- 82AE1668..168C: enabled spy and strictly positive normal response.
		if bit32.band(words[12], 8) == 0 or not (impulse[1] > 0.0) then
			continue
		end
		local a = CollisionBody.from_contact_id(words[32])
		local b = CollisionBody.from_contact_id(words[44])
		local part, other, is_body_a
		if a.kind == "Board" and b.kind == "StaticWorld" then
			part, other, is_body_a = a.id, b, true
		elseif a.kind == "StaticWorld" and b.kind == "Board" then
			part, other, is_body_a = b.id, a, false
		-- Dynamic props/vehicles share the solve; board ground consumes them
		-- through the recovered attached-body owner (827682B0 routing).
		elseif a.kind == "Board" and b.kind == "Attached" then
			part, other, is_body_a = a.id, b, true
		elseif a.kind == "Attached" and b.kind == "Board" then
			part, other, is_body_a = b.id, a, false
		else
			continue
		end
		if #output == 16 then
			break
		end
		local normal = vec(words, 28)
		local tangents = { vec(words, 40), vec(words, 52) }
		local a_position = add(center(a, bodies, attached), vec(words, 0))
		local b_position = add(center(b, bodies, attached), vec(words, 4))
		local a_weight = from_bits(words[36])
		local b_weight = from_bits(words[40])
		local inverse_weight = f32(1.0 / f32(b_weight + a_weight))
		local position = combine(a_position, a_weight, scale(b_position, b_weight))
		local friction = combine(tangents[1], impulse[2], scale(tangents[2], impulse[3]))
		local sign = if is_body_a then 1.0 else -1.0
		local this = CollisionBody.Board(part)
		table.insert(output, {
			part = part,
			other = other,
			is_body_a = is_body_a,
			normal = scale(normal, sign),
			position = scale(position, inverse_weight),
			relative_linear_velocity = subtract(velocity(this, bodies, attached), velocity(other, bodies, attached)),
			other_surface = if is_body_a then bit32.band(words[56], 0xFFFF) else bit32.rshift(words[56], 16),
			normal_force_on_a = scale(scale(normal, impulse[1]), frequency_squared),
			friction_force_on_a = scale(friction, frequency_squared),
			tangents = tangents,
		})
	end
end

return board_reports
