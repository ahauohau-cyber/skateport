--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact/families.rs (коммит 2e16697)
--
-- Additional TU3 deck/truck contact queries and family admission leaves.
-- ROBLOX: `use super::*` -> families.parent (ставит grind_contact/init.luau).

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local arithmetic = require("./arithmetic")
local admission = require("./admission")

local f32 = rt.f32
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3
local EntryKind = admission.EntryKind
local test = admission.Admission.test

type V = { number }
type TruckContact = { position: V, primitive: number }
type Hit = TruckContact | false

local families = {}
families.parent = (nil :: any)

export type Contact = {
	geometry: any, -- FiftyFiftyCandidate
	front: boolean,
	kind: number,
	entry_kind: number,
}

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end

local function rectangle(a: V, b: V, c: V, d: V, reference: V, edges: { any }): TruckContact?
	local segment_triangle = families.parent.segment_triangle
	local best: TruckContact? = nil
	local distance = 1000000.0
	for index, edge in edges do
		local position = segment_triangle(edge.start, edge["end"], { a, b, c })
		if position == nil then
			position = segment_triangle(edge.start, edge["end"], { d, a, c })
		end
		if position then
			local delta = sub(position, reference)
			local square = dot3(delta, delta)
			if square < distance then
				distance = square
				best = { position = position, primitive = index - 1 }
			end
		end
	end
	return best
end

-- 82C1F968: inverted deck only, .3 longitudinal half-length, inverted depth.
function families.inverted_contact(board: { V }, flags: number, epsilon: number, depth: number, edges: { any }): TruckContact?
	if not bit32.btest(flags, 0x0020_0000) then
		return nil
	end
	-- 82C1F968 uses the same diagonal as82C1FB98.
	local inverted = table.clone(board)
	inverted[2] = scale(board[2], -1.0)
	return families.parent.deck_contact(inverted, 0, epsilon, depth, f32(0.3), edges)
end

-- 82C20130: longitudinal trapezoids beyond each truck, with the native
-- current-tip suppression so the loaded end does not swap on each tick.
-- ROBLOX: [Option<TruckContact>; 2] -> { TruckContact | false }.
function families.tip_contacts(
	board: { V },
	flags_2484: number,
	state: number,
	flags_2468: number,
	truck_distance: number,
	edges: { any }
): { Hit }
	if bit32.btest(flags_2484, 0x0020_0000) then
		return { false, false }
	end
	local out: { Hit } = {}
	for i = 0, 1 do
		if (state == 402 or state == 404) and (bit32.btest(flags_2468, 0x200) ~= (i == 0)) then
			out[i + 1] = false
			continue
		end
		local sign = if i == 0 then 1.0 else -1.0
		local centre = add(board[4], scale(board[2], f32(0.02)))
		local a = add(centre, scale(board[3], f32(sign * truck_distance)))
		local b = add(add(centre, scale(board[3], f32(sign * f32(truck_distance + f32(0.215))))), scale(board[2], f32(0.03)))
		local c = add(b, scale(board[2], -f32(0.2)))
		local d = add(a, scale(board[2], -f32(0.2)))
		out[i + 1] = rectangle(a, b, c, d, scale(add(a, b), 0.5), edges) or false
	end
	return out
end

local function geometry(hit: TruckContact, edge: any): any
	local delta = sub(edge["end"], edge.start)
	return {
		direction = scale(delta, arithmetic.inverse_square_root(dot3(delta, delta))),
		centre = hit.position,
		front = edge["end"],
		rear = edge.start,
		primitive = hit.primitive,
	}
end

-- 82D883E0: a tip on a height-discontinuous edge becomes a backslash when
-- the deck lies over the higher side. Existing tipslides remain tipslides.
function families.is_backslash(
	board_position: V,
	point: V,
	far_points: { V },
	support: V,
	truck_distance: number,
	state: number
): boolean
	if state == 402 then
		return false
	end
	local offsets = { sub(far_points[1], point), sub(far_points[2], point) }
	local heights = { dot3(offsets[1], support), dot3(offsets[2], support) }
	if math.abs(f32(heights[1] - heights[2])) <= f32(truck_distance * f32(0.1)) then
		return false
	end
	local higher = if heights[1] > heights[2] then offsets[1] else offsets[2]
	return dot3(sub(board_position, point), higher) > 0.0
end

-- 82D88E88. Unlike boardslides, inverted decks have no truck-clearance test.
function families.darkslide(
	board: { V },
	hit: TruckContact,
	edge: any,
	velocity: V,
	category: number,
	low_wheel_frames: number,
	adm: admission.Admission
): Contact?
	local g = geometry(hit, edge)
	local delta = sub(edge["end"], edge.start)
	g.direction = scale(delta, arithmetic.reciprocal(arithmetic.square_root(dot3(delta, delta))))
	if dot3(families.parent.upright_normal(g.direction), scale(board[2], -1.0)) <= f32(0.45) then
		return nil
	end
	-- 82D8907C deliberately tests state400, even for darkslide kind5.
	local decision = test(adm, 400, g.direction, false)
	if not decision.allowed then
		return nil
	end
	local depth = dot3(sub(board[4], hit.position), board[2])
	if dot3(scale(board[2], depth), scale(board[2], depth)) >= f32(0.005625) then
		return nil
	end
	if category == 100 and math.abs(dot3(velocity, g.direction)) <= 0.75 and low_wheel_frames <= 10 then
		return nil
	end
	return { geometry = g, front = false, kind = 5, entry_kind = decision.kind }
end

-- 82D89898/82D89820: valid single-truck contacts. Selection between two valid
-- ends is performed below using the native travel-relative branches.
function families.five_o(
	board: { V },
	hits: { Hit },
	edges: { any },
	velocity: V,
	flags_2476: number,
	flags_2472: number,
	ground_frames: number,
	translation: number,
	adm: admission.Admission
): Contact?
	if bit32.btest(flags_2476, 0x4000_0000) then
		return nil
	end
	local valid: { any } = {}
	for i = 1, 2 do
		local hit = hits[i]
		local v: any = false
		if hit then
			local g = geometry(hit, edges[hit.primitive + 1])
			local depth = dot3(sub(board[4], hit.position), board[2])
			local projected = scale(board[2], depth)
			if not (dot3(projected, projected) >= from_bits(0x3c8a71de)) then
				local decision = test(adm, 403, g.direction, true)
				if
					decision.allowed
					and not (math.abs(dot3(board[1], g.direction)) >= f32(0.906))
					and not (math.abs(dot3(board[2], g.direction)) >= f32(0.46))
				then
					v = { g, decision.kind }
				end
			end
		end
		valid[i] = v
	end
	local forwards = dot3(board[3], velocity) > 0.0
	local leading = if forwards then 0 else 1
	local trailing = 1 - leading
	local take_leading, take_trailing
	local lv, tv = valid[leading + 1] ~= false, valid[trailing + 1] ~= false
	if lv and tv then
		local lead
		if ground_frames > 30 then
			lead = bit32.btest(flags_2472, 0x1000)
		else
			lead = translation > f32(0.68)
		end
		take_leading, take_trailing = lead, not lead
	elseif not lv and tv then
		take_leading, take_trailing = false, true
	elseif lv and not tv then
		take_leading, take_trailing = ground_frames <= 30 or bit32.btest(flags_2472, 0x1000), false
	else
		take_leading, take_trailing = false, false
	end
	local index
	if take_trailing then
		index = trailing
	elseif take_leading then
		index = leading
	else
		return nil
	end
	local chosen = valid[index + 1]
	if not chosen then
		return nil
	end
	return { geometry = chosen[1], front = index == 0, kind = 3, entry_kind = chosen[2] }
end

-- 82D89428 selects the positive tip first, then checks penetration, descent,
-- cross-rail velocity and the animation's lateral balance intent.
function families.tipslide(
	board: { V },
	hits: { Hit },
	edges: { any },
	velocity: V,
	category: number,
	flags_2476: number,
	flags_2472: number,
	ground_frames: number,
	balance: number,
	reference_right: V,
	adm: admission.Admission
): Contact?
	if bit32.btest(flags_2476, 0x4000_0000) then
		return nil
	end
	local front = hits[1] ~= false
	local hit = if front then hits[1] else hits[2]
	if not hit then
		return nil
	end
	local g = geometry(hit, edges[hit.primitive + 1])
	local decision = test(adm, 402, g.direction, true)
	if not decision.allowed then
		return nil
	end
	if (decision.kind == EntryKind.DropIn or (velocity[2] < 0.0 and category ~= 400)) and board[4][2] <= hit.position[2] then
		return nil
	end
	local delta = sub(board[4], hit.position)
	local depth = dot3(delta, board[2])
	local projected = scale(board[2], depth)
	if dot3(projected, projected) >= from_bits(0x3b6bedfa) then
		return nil
	end
	local perpendicular = sub(velocity, scale(g.direction, dot3(g.direction, velocity)))
	if dot3(perpendicular, perpendicular) < 9.0 then
		if math.abs(balance) > 0.0 then
			if dot3(sub(hit.position, board[4]), reference_right) >= 0.0 then
				return nil
			end
		elseif ground_frames > 30 then
			local toward = dot3(sub(hit.position, board[4]), velocity) > 0.0
			if bit32.btest(flags_2472, 0x1000) ~= toward then
				return nil
			end
		end
	end
	return { geometry = g, front = front, kind = 2, entry_kind = decision.kind }
end

return families
