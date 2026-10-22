--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_probes.rs (коммит 2e16697)
--
-- Deck and wall probes in TU3 82C07788/82C079E0, with the actual optional
-- wall-line producer82C01F10. Wheel probes remain in board_ground.

local rt = require("../../rt")
local bmo = require("./board_motion_output")
local board_ground = require("./board_ground")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot, inverse_length_squared = bmo.dot, bmo.inverse_length_squared

type Vector3 = vector

local board_probes = {}

export type BoardProbeHit = { point: Vector3, normal: Vector3, surface_tag: number }
export type BoardProbeState = {
	start: Vector3,
	point: Vector3,
	normal: Vector3,
	surface_tag: number,
	hit: boolean,
}

local BoardProbeState = {}
board_probes.BoardProbeState = BoardProbeState

-- SkateboardBody ctor82C06614..82C0675C clears both complete records.
function BoardProbeState.default(): BoardProbeState
	return { start = vector.zero, point = vector.zero, normal = vector.zero, surface_tag = 0, hit = false }
end

function BoardProbeState.clone(self: BoardProbeState): BoardProbeState
	return table.clone(self)
end

function BoardProbeState.eq(a: BoardProbeState, b: BoardProbeState): boolean
	return a.start == b.start and a.point == b.point and a.normal == b.normal and a.surface_tag == b.surface_tag and a.hit == b.hit
end

function BoardProbeState.start(self: BoardProbeState, position: Vector3)
	self.start = position
	self.hit = false
end

-- A miss only clears the hit byte. Previously published point, normal and
-- surface deliberately remain, unlike a disabled optional query.
-- ROBLOX: Option<BoardProbeHit> -> BoardProbeHit или nil.
function BoardProbeState.publish(self: BoardProbeState, hit: BoardProbeHit?)
	self.hit = hit ~= nil
	if hit then
		self.point = hit.point
		self.normal = hit.normal
		self.surface_tag = hit.surface_tag
	end
end

function BoardProbeState.disable(self: BoardProbeState)
	local d = BoardProbeState.default()
	self.start, self.point, self.normal, self.surface_tag, self.hit = d.start, d.point, d.normal, d.surface_tag, d.hit
end

board_probes.DECK_PROBE_RADIUS = from_bits(0x3e19_999a)

-- Fifth query always runs from the physical deck origin100m down, radius0.15.
-- Native start is copied to body7968, and result to7984/8000/8016/8020.
function board_probes.deck_probe(position: Vector3): board_ground.WheelLine
	return {
		start = position,
		end_ = vector.create(position.x, f32(position.y + from_bits(0xc2c8_0000)), position.z),
	}
end

export type WallLineInput = {
	-- Processed2508: current physical state (100 or101 admitted).
	state: number,
	-- Processed464,544,112,2752.
	contact_normal: Vector3,
	skater_up: Vector3,
	deck_position: Vector3,
	time: number,
}

local function cross(a: Vector3, b: Vector3): Vector3
	return vector.create(
		mul_add(-a.z, b.y, f32(a.y * b.z)),
		mul_add(-a.x, b.z, f32(a.z * b.x)),
		mul_add(-a.y, b.x, f32(a.x * b.y))
	)
end

local F32_0_05 = f32(0.05)

-- Source82C01F10 clears endpoints208/224 on every call, then enables byte291
-- only for the three physical gates below. No guessed grounded condition.
-- pub fn wall_probe(input: WallLineInput) -> Option<WheelLine>
function board_probes.wall_probe(input: WallLineInput): board_ground.WheelLine?
	if not (input.state == 100 or input.state == 101)
		or not (math.abs(input.contact_normal.y) < 0.5)
		or not (dot(input.skater_up, input.contact_normal) > from_bits(0x3f35_c28f))
		or not (input.time > from_bits(0x3c23_d70a))
	then
		return nil
	end
	local normal = input.contact_normal
	local start = vector.create(
		mul_add(normal.x, F32_0_05, input.deck_position.x),
		mul_add(normal.y, F32_0_05, input.deck_position.y),
		mul_add(normal.z, F32_0_05, input.deck_position.z)
	)
	local first = cross(vector.create(0.0, 1.0, 0.0), normal)
	local down = cross(first, normal)
	local squared = dot(down, down)
	local inverse = inverse_length_squared(squared, 2)
	local magnitude = if squared == 0.0 then 0.0 else f32(squared * inverse)
	if magnitude > from_bits(0x3586_37bd) then
		down = vector.create(f32(down.x * inverse), f32(down.y * inverse), f32(down.z * inverse))
	else
		down = vector.zero
	end
	return {
		start = start,
		end_ = vector.create(mul_add(down.x, 4.0, start.x), mul_add(down.y, 4.0, start.y), mul_add(down.z, 4.0, start.z)),
	}
end

return board_probes
