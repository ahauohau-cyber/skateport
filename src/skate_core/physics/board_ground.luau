--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_ground.rs (коммит 2e16697)
--
-- Board contact normals and wheel-line state used by riding output.
--
-- TU3 CollisionInfo constructor82C00D68/reset82C00CA0, wheel result
-- publication82C079E0, and world-contact normal selection82C07D20. The
-- postphysics stage consumes actual solver reports, never speculative query
-- contacts. Dynamic-object classification is outside the host's static world.

local rt = require("../../rt")
local trigonometry = require("../trigonometry")
local board = require("./board")
local bmo = require("./board_motion_output")
local native_arithmetic = require("./native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local BodyId = board.BodyId
local BODY_COUNT = board.BODY_COUNT
local add, dot, inverse_length_squared, length, scale, subtract =
	bmo.add, bmo.dot, bmo.inverse_length_squared, bmo.length, bmo.scale, bmo.subtract

type Vector3 = vector

local board_ground = {}

local UP = vector.create(0.0, 1.0, 0.0)
board_ground.WHEEL_LINE_LENGTH = from_bits(0x3E4C_CCCD)
local WHEEL_LINE_LENGTH = board_ground.WHEEL_LINE_LENGTH

export type WheelLine = { start: Vector3, end_: Vector3 }

-- The four zero-radius queries in82C07788. Up is Reckoning+1152, supplied
-- by PhysicalPlayerHiLOD::StartSkateboardLineTests82DB6310.
-- pub fn wheel_lines(board: &BoardRuntime, reckoning_up: Vector3) -> [WheelLine; 4]
function board_ground.wheel_lines(runtime: any, reckoning_up: Vector3): { WheelLine }
	-- ROBLOX: подключение внутри функции — board_runtime тянет большую цепочку.
	local BoardRuntime = (require("./board_runtime") :: any).BoardRuntime
	local poses = BoardRuntime.part_transforms(runtime)
	local delta = scale(reckoning_up, WHEEL_LINE_LENGTH)
	local out = {}
	for i = 1, 4 do
		out[i] = { start = poses[i].translation, end_ = subtract(poses[i].translation, delta) }
	end
	return out
end

export type WheelLineHit = {
	-- Query result+96, before82C079E0 multiplies by the authored line length.
	fraction: number,
	normal: Vector3,
	surface_tag: number,
}

export type WheelLineState = {
	normals: { Vector3 },
	distances: { number },
	physics_surfaces: { number },
	-- Audio material (surface tag bits 0..6, `& 0x7F`) per wheel, 0 on a miss. Not
	-- part of 82C079E0; kept for the engine's rolling sound.
	audio_surfaces: { number },
	-- Seam pattern (surface tag bits 12..15, `>> 12 & 0xF`) per wheel, 0 on a miss: the
	-- audio state's `+636..+648` (82C079E0 stores it next to the material). Engine-side input
	-- for the rolling bed's seam-pattern gain envelope and `Class_Seams`.
	seam_patterns: { number },
	minimum_distance: number,
}

local WheelLineState = {}
board_ground.WheelLineState = WheelLineState

-- 82C00D68 initializes all four normal/distance/surface records.
function WheelLineState.default(): WheelLineState
	return {
		normals = { UP, UP, UP, UP },
		distances = { 0.0, 0.0, 0.0, 0.0 },
		physics_surfaces = { 0, 0, 0, 0 },
		audio_surfaces = { 0, 0, 0, 0 },
		seam_patterns = { 0, 0, 0, 0 },
		minimum_distance = 0.0,
	}
end

-- ROBLOX: Copy-структура — явная копия.
function WheelLineState.clone(self: WheelLineState): WheelLineState
	return {
		normals = table.clone(self.normals),
		distances = table.clone(self.distances),
		physics_surfaces = table.clone(self.physics_surfaces),
		audio_surfaces = table.clone(self.audio_surfaces),
		seam_patterns = table.clone(self.seam_patterns),
		minimum_distance = self.minimum_distance,
	}
end

-- Complete four-wheel branch82C079F8..82C07A9C. A miss clears the
-- surface, while the previous distance and normal deliberately survive.
-- ROBLOX: [Option<WheelLineHit>; 4] -> таблица из 4, промах — false.
function WheelLineState.publish(self: WheelLineState, hits: { WheelLineHit | false })
	self.minimum_distance = WHEEL_LINE_LENGTH
	for i = 1, 4 do
		local hit = hits[i]
		self.physics_surfaces[i] = 0
		self.audio_surfaces[i] = 0
		self.seam_patterns[i] = 0
		if hit then
			local distance = f32(hit.fraction * WHEEL_LINE_LENGTH)
			self.minimum_distance = if f32(distance - self.minimum_distance) >= -0.0 then self.minimum_distance else distance
			self.normals[i] = hit.normal
			self.distances[i] = distance
			self.physics_surfaces[i] = bit32.band(bit32.rshift(hit.surface_tag, 7), 31)
			self.audio_surfaces[i] = bit32.band(hit.surface_tag, 0x7F)
			self.seam_patterns[i] = bit32.band(bit32.rshift(hit.surface_tag, 12), 0xF)
		end
	end
end

export type PartGroundContact = {
	in_contact: boolean,
	normal: Vector3,
	point: Vector3,
	relative_velocity: Vector3,
}

local function empty_part(): PartGroundContact
	return { in_contact = false, normal = UP, point = vector.zero, relative_velocity = vector.zero }
end

export type BoardGroundState = {
	parts: { PartGroundContact },
	-- BoardBody320..416, retained between postphysics updates.
	previous_velocities: { Vector3 },
	-- BoardBody432..528, observed accelerations in actual part order.
	accelerations: { Vector3 },
	-- Body656/852: strongest closing velocity against this frame's contacts,
	-- computed from retained part velocities before acceleration sampling.
	closing_velocity: Vector3,
	maximum_closing_speed: number,
	-- Body860: range of DECK contact normal projections onto Reckoning1152.
	opposing_contact: number,
	-- Body864/872: static-world contact classifications and surface12 height.
	-- Other-assembly group flags require actual dynamic-object reports.
	surface_twelve_height: number,
	collision_flags: number,
	-- CollisionInfo+0. Can use truck/deck normals when the wheel sum fails.
	overall_normal: Vector3,
	-- CollisionInfo+16. Retained until a valid contacting-wheel sum replaces it.
	-- FillPhysOut publishes this to Ground+80 and Ground+96.
	wheel_normal: Vector3,
	valid_wheel_normals: { boolean },
	part_contact_count: number,
	wheel_contact_count: number,
	-- Body7692, accumulated only while all four physical wheels lack contact.
	time_without_wheel_contact: number,
	-- Angular drag: S3 postphysics82C08634 writes wheel inertia+36;
	-- paired S2 postphysics82B372E0 names this mAngularDrag.
	wheel_angular_drag: { number },
	-- CollisionInfo+4/+8/+12: the trucks' and deck's last contact audio surface (tag & 0x7F,
	-- 0 without contact this frame), read by the audio state as materials +652..+660.
	part_audio_surfaces: { number },
}

local BoardGroundState = {}
board_ground.BoardGroundState = BoardGroundState

function BoardGroundState.default(): BoardGroundState
	local parts, previous, accelerations = {}, {}, {}
	for i = 1, BODY_COUNT do
		parts[i] = empty_part()
		-- CollisionInfo ctor82C00DC8/CC zeros both arrays. Board reset
		-- 82C0D758 calls that constructor again; per-frame reset retains velocities.
		previous[i] = vector.zero
		accelerations[i] = vector.zero
	end
	return {
		parts = parts,
		overall_normal = UP,
		wheel_normal = UP,
		previous_velocities = previous,
		accelerations = accelerations,
		closing_velocity = vector.zero,
		maximum_closing_speed = 0.0,
		opposing_contact = 0.0,
		surface_twelve_height = 0.0,
		collision_flags = 0,
		valid_wheel_normals = { false, false, false, false },
		part_contact_count = 0,
		wheel_contact_count = 0,
		time_without_wheel_contact = 0.0,
		wheel_angular_drag = { 0.0, 0.0, 0.0, 0.0 },
		part_audio_surfaces = { 0, 0, 0 },
	}
end

-- Original PostPhysics82C082B8..8444. The scalar reciprocal timestep is
-- shared by all seven parts, then each previous velocity is replaced.
function BoardGroundState.sample_accelerations(self: BoardGroundState, velocities: { Vector3 }, time_step: number)
	local inverse_dt = f32(1.0 / time_step)
	for i = 1, BODY_COUNT do
		local current = velocities[i]
		self.accelerations[i] = scale(subtract(current, self.previous_velocities[i]), inverse_dt)
		self.previous_velocities[i] = current
	end
end

-- 82C087D8..87F4 after contact publication. The incoming f1 is the
-- actual physics timestep; reset82C0D680 deliberately preserves this field.
function BoardGroundState.advance_contact_time(self: BoardGroundState, time_step: number)
	self.time_without_wheel_contact = if self.wheel_contact_count == 0
		then f32(self.time_without_wheel_contact + time_step)
		else 0.0
end

-- Complete8296EBB0, including its small-vector gate and ONE reciprocal-square-
-- root refinement per vector. Native82C07D20 compares this angle with pi/4.
function board_ground.angle_between(a: Vector3, b: Vector3): number
	local a_squared = dot(a, a)
	local b_squared = dot(b, b)
	local epsilon = from_bits(0x38D1_B717)
	if not (a_squared > epsilon and b_squared > epsilon) then
		return 0.0
	end
	a = scale(a, inverse_length_squared(a_squared, 1))
	b = scale(b, inverse_length_squared(b_squared, 1))
	local cosine = native_arithmetic.vector_min(native_arithmetic.vector_max(dot(a, b), -1.0), 1.0)
	return trigonometry.acos(cosine)
end
local angle_between = board_ground.angle_between

local DECK = BodyId.Deck + 1
local LINE_DISTANCE_LIMIT = from_bits(0x3D8F_5C29)
local DEGREES_TO_RADIANS = from_bits(0x3C8E_FA35)
local QUARTER_PI = from_bits(0x3F49_0FDB)
local WIPEOUT_DRAG = from_bits(0x3D23_D70A)
local FREE_DRAG = from_bits(0x3BC4_9BA6)
local DRAG_FREQUENCY = from_bits(0x426F_FFFF)

-- Complete contact-normal/count/drag subpipeline of82C07D20 for the
-- static world. Reports must already satisfy82AE1608/827682B0 eligibility.
-- `maximum_ground_angle_degrees` is physics_reckoning.
-- MaxAllowedGroundNormalFromUp (full64 0E508708CC7F5249).
function BoardGroundState.update(
	self: BoardGroundState,
	reports: { any },
	lines: WheelLineState,
	reckoning_up: Vector3,
	maximum_ground_angle_degrees: number,
	board_wiping_out: boolean
)
	for i = 1, BODY_COUNT do
		self.parts[i] = empty_part()
	end
	-- CollisionInfo Reset82C00CA0 clears per-frame impacts and high flags.
	self.closing_velocity = vector.zero
	self.maximum_closing_speed = 0.0
	self.surface_twelve_height = 0.0
	self.collision_flags = bit32.band(self.collision_flags, 0x01ff_ffff)
	self.overall_normal = UP
	for i = 1, 4 do
		self.valid_wheel_normals[i] = true
	end
	self.part_audio_surfaces = { 0, 0, 0 }
	local highest_y = -2.0
	local highest_part: number? = nil
	-- 82C07E24..30 seeds min/max; only deck reports enter82C07EAC..CC.
	local minimum_projection = 1.0
	local maximum_projection = -1.0
	local surfaces = table.create(BODY_COUNT, 0)
	for i = 1, 4 do
		surfaces[i] = lines.physics_surfaces[i]
	end
	for _, report in reports do
		local i = report.part + 1
		if i == DECK then
			local projection = dot(report.normal, reckoning_up)
			minimum_projection = if f32(minimum_projection - projection) >= 0.0 then projection else minimum_projection
			maximum_projection = if f32(maximum_projection - projection) >= 0.0 then maximum_projection else projection
		end
		-- 82C07ED0..7F2C: this is the OLD part velocity, not the report's
		-- post-solve relative velocity or the finite-difference acceleration.
		local closing = -dot(report.normal, self.previous_velocities[i])
		if not (closing <= self.maximum_closing_speed) then
			self.maximum_closing_speed = closing
			self.closing_velocity = scale(report.normal, -closing)
		end
		local surface = bit32.band(bit32.rshift(report.other_surface, 7), 31)
		if surface == 12 then
			self.collision_flags = bit32.bor(self.collision_flags, bit32.lshift(1, 25)) -- 82C080D4..80F0.
			self.surface_twelve_height = report.position.y
		end
		if i >= 5 then
			surfaces[i] = surface -- 82C081B4..81E0, last report wins.
			self.part_audio_surfaces[i - 4] = bit32.band(report.other_surface, 0x7F)
		end
		local contact = self.parts[i]
		if not contact.in_contact or report.normal.y > contact.normal.y then
			contact.normal = report.normal
			contact.point = report.position
			contact.relative_velocity = report.relative_linear_velocity
		end
		-- Selection occurs after the per-part maximum, in report order.
		if contact.normal.y > highest_y then
			highest_y = contact.normal.y
			highest_part = i
		end
		contact.in_contact = true
	end
	-- 82C082AC/E8/F4/F8; no deck reports produce max(-2,0)=0.
	local range = f32(maximum_projection - minimum_projection)
	self.opposing_contact = if -range >= 0.0 then 0.0 else range
	-- 82C0834C..836C combines physical contact with the wheel query's
	-- surface (wheels), or the last actual contact tag (trucks/deck).
	for i = 1, BODY_COUNT do
		if self.parts[i].in_contact and surfaces[i] == 8 then
			self.collision_flags = bit32.bor(self.collision_flags, bit32.lshift(1, 31))
		end
	end
	-- The source's -1 best-part index addresses the retained wheel normal.
	local reference_normal = if highest_part == nil then self.wheel_normal else self.parts[highest_part].normal
	for i = 1, 4 do
		if not self.parts[i].in_contact then
			if lines.distances[i] < LINE_DISTANCE_LIMIT then
				self.parts[i].normal = lines.normals[i]
			else
				self.valid_wheel_normals[i] = false
			end
		end
	end
	local part_count, wheel_count = 0, 0
	for i = 1, BODY_COUNT do
		if self.parts[i].in_contact then
			part_count += 1
			if i <= 4 then
				wheel_count += 1
			end
		end
	end
	self.part_contact_count = part_count
	self.wheel_contact_count = wheel_count
	local angle_radians = f32(maximum_ground_angle_degrees * DEGREES_TO_RADIANS)
	local minimum_up_dot = trigonometry.cos(angle_radians)
	local sum = vector.zero
	for i = 1, 4 do
		local contact = self.parts[i]
		if self.valid_wheel_normals[i]
			and dot(contact.normal, reckoning_up) > minimum_up_dot
			and angle_between(reference_normal, contact.normal) < QUARTER_PI
		then
			sum = add(sum, contact.normal)
		end
		local drag
		if contact.in_contact then
			drag = if board_wiping_out then WIPEOUT_DRAG else 0.0
		else
			drag = FREE_DRAG
		end
		self.wheel_angular_drag[i] = f32(drag * DRAG_FREQUENCY)
	end
	local squared = dot(sum, sum)
	if self.wheel_contact_count > 0 and squared > from_bits(0x3780_0000) then
		self.overall_normal = scale(sum, inverse_length_squared(squared, 2))
		self.wheel_normal = self.overall_normal
	else
		local support = vector.zero
		-- Native sum order: deck, front truck, back truck.
		for _, id in { BodyId.Deck, BodyId.FrontTruck, BodyId.BackTruck } do
			if self.parts[id + 1].in_contact then
				support = add(support, self.parts[id + 1].normal)
			end
		end
		local magnitude = length(support)
		if magnitude > from_bits(0x3C23_D70A) then
			local inverse = native_arithmetic.reciprocal_estimate(magnitude)
			for _ = 1, 2 do
				local error = mul_add(-inverse, magnitude, 1.0)
				inverse = mul_add(inverse, error, inverse)
			end
			self.overall_normal = scale(support, inverse)
		end
	end
end

return board_ground
