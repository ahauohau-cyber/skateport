--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact.rs (коммит 2e16697)
--
-- Native grind contact leaf82C1E2C8. This is distinct from the tolerant wheel
-- triangle query: exact parallel rejection and closed segment/barycentric bounds.
-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел (индексы с 1, Rust v[1] -> v[2]);
-- Option<T> -> T или nil, внутри массивов -> T или false; usize-индексы
-- примитивов с нуля, как в Rust. Подмодули с `use super::*` получают этот
-- модуль через поле parent (иначе круговой require).

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local trigonometry = require("../trigonometry")
local arithmetic = require("@self/arithmetic")
local admission = require("@self/admission")
local families = require("@self/families")
local entry = require("@self/entry")
local control = require("@self/control")
local investigator = require("@self/investigator")
local manager = require("@self/manager")
local balance = require("@self/balance")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3

local grind_contact = {}

grind_contact.families = families
grind_contact.entry = entry
grind_contact.control = control
grind_contact.admission = admission
grind_contact.arithmetic = arithmetic -- ROBLOX: приватный модуль, открыт для подмодулей и сверки.
grind_contact.investigator = investigator
grind_contact.manager = manager
grind_contact.balance = balance

export type V = { number }

-- Native query entry: endpoints plus a spline owner, not three vectors.
-- ROBLOX: owner: u64 -> число.
export type Primitive = { start: V, ["end"]: V, owner: number }

export type TruckContact = { position: V, primitive: number }

export type FiftyFiftyCandidate = {
	direction: V,
	centre: V,
	front: V,
	rear: V,
	primitive: number,
}

-- ROBLOX: приватные fn sub/add/scale/cross открыты для подмодулей (super::*).
local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		0.0,
	}
end
grind_contact.sub = sub
grind_contact.add = add
grind_contact.scale = scale
grind_contact.cross = cross
grind_contact.dot3 = dot3

-- Intersect a grind primitive segment with a board/truck probe triangle.
-- Returns the native hit position; acquisition/scoring belongs to the caller.
-- Both windings are accepted. Failed branches do not synthesize a contact.
function grind_contact.segment_triangle(start: V, end_: V, triangle: { V }): V?
	local a, b, c = triangle[1], triangle[2], triangle[3]
	local ac = sub(c, a)
	local ab = sub(b, a)
	local direction = sub(end_, start)
	local normal = cross(ab, ac)
	local denominator = -dot3(direction, normal)
	if denominator == 0.0 then
		return nil
	end
	local from = sub(start, a)
	local inverse = f32(1.0 / denominator)
	local t = f32(inverse * dot3(from, normal))
	if t < 0.0 or t > 1.0 then
		return nil
	end
	local side = cross(from, direction)
	local u = f32(inverse * dot3(ac, side))
	local v = f32(f32(1.0 / -denominator) * dot3(ab, side))
	if f32(u + v) > 1.0 or u < 0.0 or v < 0.0 then
		return nil
	end
	return {
		mul_add(direction[1], t, start[1]),
		mul_add(direction[2], t, start[2]),
		mul_add(direction[3], t, start[3]),
		mul_add(direction[4], t, start[4]),
	}
end
local segment_triangle = grind_contact.segment_triangle

-- 82C1FB98: the longitudinal deck rectangle. Unlike the two truck rectangles,
-- this catches a rail crossing between the trucks (boardslides/lipslides).
function grind_contact.deck_contact(
	board: { V },
	flags_2484: number,
	above: number,
	below: number,
	deck_center_to_truck: number,
	primitives: { Primitive }
): TruckContact?
	if bit32.btest(flags_2484, 0x0020_0000) then
		return nil
	end
	local centre = add(board[4], scale(board[2], above))
	local along = scale(board[3], deck_center_to_truck)
	local down = scale(board[2], -f32(above + below))
	local a = add(centre, along)
	local b = sub(centre, along)
	local c = add(a, down)
	local d = add(b, down)
	local best: TruckContact? = nil
	local distance = 1000000.0
	for index, edge in primitives do
		local position = segment_triangle(edge.start, edge["end"], { a, b, c })
			or segment_triangle(edge.start, edge["end"], { d, b, c })
		if position then
			local delta = sub(position, board[4])
			local square = dot3(delta, delta)
			if square < distance then
				distance = square
				best = { position = position, primitive = index - 1 }
			end
		end
	end
	return best
end

-- 82D370F8: upward-facing normal perpendicular to the spline direction.
function grind_contact.upright_normal(direction: V): V
	local cross_up = cross({ 0.0, 1.0, 0.0, 0.0 }, direction)
	local normal = cross(cross_up, direction)
	local length = arithmetic.square_root(dot3(normal, normal))
	if length <= 0.0 then
		return { 1.0, 0.0, 0.0, 0.0 }
	end
	if normal[2] < 0.0 then
		length = -length
	end
	return scale(normal, arithmetic.reciprocal(length))
end
local upright_normal = grind_contact.upright_normal

-- 82D88518, common active-grind angular admission. Plane projection occurs
-- before the direction comparison; vertical speed is not an approach angle.
function grind_contact.within_approach_angle(direction: V, velocity: V, degrees: number): boolean
	local normal = upright_normal(direction)
	local projected = sub(velocity, scale(normal, dot3(velocity, normal)))
	local length = arithmetic.square_root(dot3(projected, projected))
	if length <= f32(0.001) then
		return true
	end
	local alignment = math.abs(dot3(scale(projected, arithmetic.reciprocal(length)), direction))
	return alignment > trigonometry.cos(f32(degrees * from_bits(0x3c8e_fa35)))
end

-- 82D889A8 geometry admission. The state manager owns approach-angle and
-- candidate arbitration separately. No nearest-rail substitute is used.
function grind_contact.boardslide_candidate(
	board: { V },
	contact: TruckContact,
	edge: Primitive,
	velocity: V,
	category: number,
	manager_frames: number,
	flags_2476: number,
	deck_center_to_truck: number,
	truck_to_wheel: number,
	adm: admission.Admission
): FiftyFiftyCandidate?
	if bit32.btest(flags_2476, 0x4000_0000) then
		return nil
	end
	local delta = sub(edge["end"], edge.start)
	local direction = scale(delta, arithmetic.reciprocal(arithmetic.square_root(dot3(delta, delta))))
	if dot3(upright_normal(direction), board[2]) <= f32(0.65) then
		return nil
	end
	if not admission.Admission.test(adm, 400, direction, false).allowed then
		return nil
	end
	local depth = dot3(sub(board[4], contact.position), board[2])
	local projected = scale(board[2], depth)
	if dot3(projected, projected) >= from_bits(0x3b6b_edfa) then
		return nil
	end
	if category == 100 and math.abs(dot3(velocity, direction)) <= 0.75 and manager_frames <= 10 then
		return nil
	end
	local horizontal = sub(delta, scale(board[2], dot3(delta, board[2])))
	local length = arithmetic.square_root(dot3(horizontal, horizontal))
	if not (length > 0.0) then
		return nil
	end
	horizontal = scale(horizontal, arithmetic.reciprocal(length))
	local alignment = math.abs(dot3(horizontal, board[3]))
	local from = sub(contact.position, board[4])
	local across = sub(from, scale(board[2], dot3(from, board[2])))
	local remaining = f32(deck_center_to_truck - arithmetic.square_root(dot3(across, across)))
	local clearance
	if alignment > 0.0 then
		clearance = f32(f32(remaining / alignment) * arithmetic.square_root(f32(1.0 - f32(alignment * alignment))))
	else
		clearance = 999.0
	end
	if not (clearance > truck_to_wheel) then
		return nil
	end
	return {
		direction = direction,
		centre = contact.position,
		front = edge["end"],
		rear = edge.start,
		primitive = contact.primitive,
	}
end

-- 82D89150 also accepts two segment indices when their hits pass its signed
-- cross-rail separation check. Splines with multiple segments need this path.
-- ROBLOX: contacts: [Option<TruckContact>; 2] -> { TruckContact | false }.
function grind_contact.fifty_fifty_candidate_on_splines(
	board: { V },
	balance_: { number },
	contacts: { TruckContact | false },
	primitives: { Primitive }
): FiftyFiftyCandidate?
	local front, rear = contacts[1], contacts[2]
	if not front or not rear then
		return nil
	end
	if rt.fmax(math.abs(balance_[1]), math.abs(balance_[2])) >= f32(0.9) then
		return nil
	end
	if front.primitive ~= rear.primitive then
		local edge = primitives[front.primitive + 1]
		if edge == nil then
			return nil
		end
		local delta = sub(edge["end"], edge.start)
		local direction = scale(delta, arithmetic.inverse_square_root(dot3(delta, delta)))
		local across = cross(upright_normal(direction), direction)
		-- 820641A8. This comparison is signed in the original routine.
		if dot3(sub(front.position, rear.position), across) > f32(0.1) then
			return nil
		end
	end
	local front_depth = dot3(sub(board[4], front.position), board[2])
	local rear_depth = dot3(sub(board[4], rear.position), board[2])
	if rt.fmax(front_depth, rear_depth) >= f32(0.13) then
		return nil
	end
	local difference = sub(front.position, rear.position)
	return {
		direction = scale(difference, arithmetic.inverse_square_root(dot3(difference, difference))),
		centre = scale(add(front.position, rear.position), 0.5),
		front = front.position,
		rear = rear.position,
		primitive = front.primitive,
	}
end

-- 82D89150's same-primitive contact branch, before shared admission82D886B8.
-- Linked/adjacent primitive arbitration belongs to the caller; this boundary
-- explicitly returns none for that case instead of guessing an owner.
function grind_contact.fifty_fifty_candidate(board: { V }, balance_: { number }, contacts: { TruckContact | false }): FiftyFiftyCandidate?
	return grind_contact.fifty_fifty_candidate_on_splines(board, balance_, contacts, {})
end

-- Truck rectangles from82C1FDC0. The geometry dimensions come from the
-- physics_grinds collection (TruckToWheel584, DeckCenterToTruck636).
-- Output order is positive board-forward truck, negative board-forward truck.
-- These are geometric contacts;82D89150 still decides whether to engage.
-- ROBLOX: [Option<TruckContact>; 2] -> { TruckContact | false }.
function grind_contact.truck_contacts(
	board: { V },
	flags_2484: number,
	truck_to_wheel: number,
	deck_center_to_truck: number,
	primitives: { Primitive }
): { TruckContact | false }
	if bit32.btest(flags_2484, 0x0020_0000) then
		return { false, false }
	end
	local right, up, forward, position = board[1], board[2], board[3], board[4]
	-- 821659F8 /8208EA7C: the probe starts .02 below the board and extends
	-- another .20 down its local up axis. Do not substitute world vertical.
	local centre = {}
	for i = 1, 4 do
		centre[i] = mul_add(up[i], -f32(0.02), position[i])
	end
	local side = scale(right, truck_to_wheel)
	local along = scale(forward, deck_center_to_truck)
	local down = scale(up, -f32(0.2))
	local centres = { add(centre, along), sub(centre, along) }
	local result: { TruckContact | false } = { false, false }
	local distance = { 1000000.0, 1000000.0 } -- 822F88D4, squared-distance ceiling.
	for index, edge in primitives do
		for truck = 1, 2 do
			local a = add(centres[truck], side)
			local b = sub(centres[truck], side)
			local c = add(b, down)
			local d = add(a, down)
			-- Native calls both triangles and retains the first triangle's
			-- intersection if both succeed, including a shared diagonal hit.
			local first = segment_triangle(edge.start, edge["end"], { a, b, c })
			local second = segment_triangle(edge.start, edge["end"], { a, d, c })
			local p = first or second
			if p then
				local delta = sub(p, centres[truck])
				local squared = dot3(delta, delta)
				if distance[truck] > squared then
					distance[truck] = squared
					result[truck] = { position = p, primitive = index - 1 }
				end
			end
		end
	end
	return result
end

-- ROBLOX: подмодули получают родителя после того, как он полностью собран.
families.parent = grind_contact
admission.parent = grind_contact
control.parent = grind_contact
investigator.parent = grind_contact

return grind_contact
