--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/force_queue.rs (коммит 2e16697)
--
-- Board force delivery: TU3 append 0x82C03EF0 and consumer 0x82C03718.

local rt = require("../../rt")
local math_mod = require("../math")
local point_force = require("./point_force")

local f32 = rt.f32

type Vector3 = vector

local force_queue = {}

force_queue.FORCE_CAPACITY = 21

export type QueuedPointForce = {
	-- Native tag is retained for attribution; it does not select a body.
	tag: number,
	force_world: Vector3,
	point_body: Vector3,
}

export type BoardForceQueue = {
	entries: { QueuedPointForce },
	count: number,
}

local BoardForceQueue = {}
force_queue.BoardForceQueue = BoardForceQueue

-- impl Default for BoardForceQueue
function BoardForceQueue.default(): BoardForceQueue
	local entries = {}
	for i = 1, force_queue.FORCE_CAPACITY do
		entries[i] = { tag = 0, force_world = vector.zero, point_body = vector.zero }
	end
	return { entries = entries, count = 0 }
end

-- TU3 drops the new force when 21 entries are already present. Repeated
-- tags remain separate entries, in append order; they are not summed here.
function BoardForceQueue.append(self: BoardForceQueue, entry: QueuedPointForce): boolean
	if self.count == force_queue.FORCE_CAPACITY then
		return false
	end
	self.entries[self.count + 1] = { tag = entry.tag, force_world = entry.force_world, point_body = entry.point_body }
	self.count += 1
	return true
end

function BoardForceQueue.entries(self: BoardForceQueue): { QueuedPointForce }
	return table.move(self.entries, 1, self.count, 1, {})
end

-- Every record acts on the deck. The caller resolves the native collection
-- force-point Y offset; the native null-collection fallback is zero.
-- Consumption does not clear the records in Skate 3.
function BoardForceQueue.apply_to_deck(
	self: BoardForceQueue,
	accumulator: point_force.RetailForceAccumulator,
	deck_basis: math_mod.Basis3,
	inverse_mass: number,
	world_inverse_inertia: math_mod.Basis3,
	force_point_y_offset: number
): point_force.RetailForceAccumulator
	for i = 1, self.count do
		local entry = self.entries[i]
		local point = vector.create(
			f32(entry.point_body.x + 0.0),
			f32(entry.point_body.y + force_point_y_offset),
			f32(entry.point_body.z + 0.0)
		)
		accumulator = point_force.accumulate_point_force(
			accumulator,
			entry.force_world,
			point,
			deck_basis,
			inverse_mass,
			world_inverse_inertia
		)
	end
	return accumulator
end

-- Separate lifecycle operation, corresponding to the queue reset at
-- 0x82C02360..0x82C02368 (also reset when the board is repositioned).
function BoardForceQueue.clear(self: BoardForceQueue)
	self.count = 0
end

-- ROBLOX: #[derive(Clone)].
function BoardForceQueue.clone(self: BoardForceQueue): BoardForceQueue
	local entries = {}
	for i, e in self.entries do
		entries[i] = { tag = e.tag, force_world = e.force_world, point_body = e.point_body }
	end
	return { entries = entries, count = self.count }
end

-- TU3 0x82C06F58: accumulate alternating body masses, then combine. The
-- grouped binary32 additions differ from an ordinary left-to-right sum.
-- Native input is live-body inverse mass at +124, in definition order.
function force_queue.total_body_mass(inverse_masses: { number }): number
	local even, odd = 0.0, 0.0
	local pairs_count = #inverse_masses // 2
	for p = 0, pairs_count - 1 do
		even = f32(f32(1.0 / inverse_masses[2 * p + 1]) + even)
		odd = f32(f32(1.0 / inverse_masses[2 * p + 2]) + odd)
	end
	local paired = f32(odd + even)
	local remainder = if #inverse_masses % 2 == 1 then f32(1.0 / inverse_masses[#inverse_masses]) else 0.0
	return f32(paired + remainder)
end

return force_queue
