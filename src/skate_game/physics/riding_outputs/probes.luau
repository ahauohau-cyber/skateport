--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/physics/riding_outputs/probes.rs (коммит 2e16697)
--
-- The fifth/sixth board probes, kept in the same query/publication phase as
-- the wheel probes. Geometry is the world's recovered triangle dispatcher.

local rt = require("../../../rt")
local board = require("../../../skate_core/physics/board")
local board_ground = require("../../../skate_core/physics/board_ground")
local board_probes = require("../../../skate_core/physics/board_probes")
local board_world = require("../../../skate_core/physics/board_world")

local from_bits = rt.from_bits
local BoardProbeState = board_probes.BoardProbeState
local BoardWorld = board_world.BoardWorld

type Vector3 = vector

local probes = {}

type Pending = {
	deck: board_probes.BoardProbeHit?,
	-- ROBLOX: Option<Option<BoardProbeHit>>: nil — стена выключена,
	-- { hit = BoardProbeHit? } — запрос был.
	wall: { hit: board_probes.BoardProbeHit? }?,
}

export type BoardProbes = {
	deck: board_probes.BoardProbeState,
	wall: board_probes.BoardProbeState,
	wall_line: board_ground.WheelLine?,
	pending: Pending?,
}

local BoardProbes = {}
probes.BoardProbes = BoardProbes

-- Skateboard ctor82C0111C starts optional wall line byte291 clear.
function BoardProbes.default(): BoardProbes
	return {
		deck = BoardProbeState.default(),
		wall = BoardProbeState.default(),
		wall_line = nil,
		pending = nil,
	}
end

-- ResetBoardBody82C0D680 clears published probe records, preserving
-- query handles204C/2050 and the wall-query enable bit.
function BoardProbes.reset_results(self: BoardProbes)
	self.deck = BoardProbeState.default()
	self.wall = BoardProbeState.default()
end

-- ROBLOX: возвращает таблицу с полями GroundContactFrame
-- (riding::grounded::state::board_types). TODO: тип переносится с этапом катания.
function BoardProbes.wall_contact_frame(self: BoardProbes, time2752: number, time2756: number): any
	local function v(p: Vector3): { number }
		return { p.x, p.y, p.z, 0.0 }
	end
	return {
		vector_8032 = v(self.wall.start),
		vector_8048 = v(self.wall.point),
		vector_8064 = v(self.wall.normal),
		word_8080 = self.wall.surface_tag,
		flag_8084 = self.wall.hit,
		scalar_2752 = time2752,
		scalar_2756 = time2756,
	}
end

-- PostPhysics82C02138 calls82C01F10 before updating board contact output.
-- Its saved endpoints and enabled291 feed the NEXT StartBoard82DB6310.
-- Processed112 is the input phase's cached deck translation, published by
-- 82C01460, not the newly solved body's current transform.
function BoardProbes.prepare_wall(self: BoardProbes, input: any, toolkit: any)
	local function vec(value: { number }): Vector3
		return vector.create(value[1], value[2], value[3])
	end
	local function bits(value: { number }): Vector3
		return vector.create(from_bits(value[1]), from_bits(value[2]), from_bits(value[3]))
	end
	self.wall_line = board_probes.wall_probe({
		state = input.state_2508,
		contact_normal = bits(input.vectors_464_480_496_512_528[1]),
		skater_up = bits(input.vectors_544_560_592_608[1]),
		deck_position = vec(toolkit.deck[4]),
		time = input.time_on_ground_2752,
	})
end

local function hit(h: any): board_probes.BoardProbeHit
	return { point = h.geometry.position, normal = h.geometry.normal, surface_tag = h.tag }
end

-- ROBLOX: Result<(), String> -> (true) или (nil, ошибка).
function BoardProbes.start(self: BoardProbes, runtime: any, world: any): (boolean?, string?)
	if self.pending ~= nil then
		return nil, "Board probes submitted twice without publication"
	end
	local BoardRuntime = (require("../../../skate_core/physics/board_runtime") :: any).BoardRuntime
	local line = board_probes.deck_probe(BoardRuntime.part_transforms(runtime)[board.BodyId.Deck + 1].translation)
	BoardProbeState.start(self.deck, line.start)
	local deck_hit, err = BoardWorld.query_swept_line(world, line.start, line.end_, board_probes.DECK_PROBE_RADIUS)
	if err ~= nil then
		return nil, "Stock deck ground probe: " .. err
	end
	local deck = if deck_hit then hit(deck_hit) else nil
	local wall: { hit: board_probes.BoardProbeHit? }? = nil
	local wall_line = self.wall_line
	if wall_line then
		BoardProbeState.start(self.wall, wall_line.start)
		local wall_hit, wall_err = BoardWorld.query_thin_line(world, wall_line.start, wall_line.end_)
		if wall_err ~= nil then
			return nil, "Stock wall floor probe: " .. wall_err
		end
		wall = { hit = if wall_hit then hit(wall_hit) else nil }
	else
		BoardProbeState.disable(self.wall)
	end
	self.pending = { deck = deck, wall = wall }
	return true, nil
end

function BoardProbes.publish(self: BoardProbes): (boolean?, string?)
	local pending = self.pending
	if pending == nil then
		return nil, "Board probe publication requires a submitted batch"
	end
	self.pending = nil
	BoardProbeState.publish(self.deck, pending.deck)
	if pending.wall then
		BoardProbeState.publish(self.wall, pending.wall.hit)
	else
		BoardProbeState.disable(self.wall)
	end
	return true, nil
end

return probes
