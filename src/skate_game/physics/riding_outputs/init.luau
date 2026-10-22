--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/physics/riding_outputs.rs (коммит 2e16697)
--
-- Live board/query/solver outputs used by the riding gameplay owner.
-- Physical calculations stay in core; this owns stock settings and scheduling
-- state. Solved contacts and line probes remain distinct native inputs.
-- ROBLOX: init.luau — пути `./` указывают на соседей папки, дети — через `@self/`.

local rt = require("../../rt")
local collections_mod = require("../../skate_data/collections")
local body_spin = require("../../skate_core/air/body_spin")
local board = require("../../skate_core/physics/board")
local board_ground = require("../../skate_core/physics/board_ground")
local bmo = require("../../skate_core/physics/board_motion_output")
local board_world = require("../../skate_core/physics/board_world")
local point_graph = require("../../skate_core/point_graph")
local ground_orientation = require("../../skate_core/riding/ground_orientation")
local reckoning_frames = require("../../skate_core/riding/reckoning_frames")
local speed_and_slope = require("../../skate_core/riding/speed_and_slope")
local ground_input = require("@self/ground_input")
local probes_mod = require("@self/probes")

local from_bits = rt.from_bits
local Collections = collections_mod.Collections
local BodySpinState = body_spin.BodySpinState
local BoardGroundState = board_ground.BoardGroundState
local WheelLineState = board_ground.WheelLineState
local BoardMotionOutput = bmo.BoardMotionOutput
local BoardWorld = board_world.BoardWorld
local GroundOrientation = ground_orientation.GroundOrientation
local ReckoningFrames = reckoning_frames.ReckoningFrames
local SpeedAndSlopeSettings = speed_and_slope.SpeedAndSlopeSettings
local BoardProbes = probes_mod.BoardProbes
local GroundPacketInputs = ground_input.GroundPacketInputs

type Vector3 = vector
type F4 = { number }

local riding_outputs = {}
riding_outputs.BoardProbes = BoardProbes

-- Pose-side results which the native Skeleton/complete Reckoning transform own.
-- They cannot be inferred from the board body's center of mass or its up axis.
export type RidingPoseInputs = {
	-- Skeleton11008 -> Processed752 in82BD8918.
	com_to_deck: Vector3,
	-- Processed2812, supplied by the actual PhysBodySpin animation attribute.
	body_spin: number,
}

export type RidingOutputs = {
	ground: board_ground.BoardGroundState,
	wheel_lines: board_ground.WheelLineState,
	probes: probes_mod.BoardProbes,
	reckoning: ground_orientation.GroundOrientation,
	reckoning_frames: reckoning_frames.ReckoningFrames,
	body_spin: body_spin.BodySpinState,
	motion: bmo.BoardMotionOutput,
	orientation_settings: ground_orientation.GroundOrientationSettings,
	tilt_vs_rotation: point_graph.PointGraph,
	tilt_vs_slope: point_graph.PointGraph,
	speed_settings: speed_and_slope.SpeedAndSlopeSettings,
	maximum_ground_angle: number,
	heading_adjust_factor: number,
	-- ROBLOX: Option<[Option<WheelLineHit>; 4]> -> таблица из 4 (промах — false) или nil.
	pending_wheel_queries: { board_ground.WheelLineHit | false }?,
}

local RidingOutputs = {}
riding_outputs.RidingOutputs = RidingOutputs

local function vec3(v: { number }): Vector3
	return vector.create(v[1], v[2], v[3])
end
local function lanes(v: Vector3): F4
	return { v.x, v.y, v.z, 0.0 }
end

-- fn graph(data, class, field) -> Result<PointGraph<8>, String>
local function graph(data: any, class: string, field: string): point_graph.PointGraph
	local words = collections_mod.expect(Collections.words(data, class, "default", field, 16))
	local x, y = {}, {}
	for i = 1, 8 do
		x[i] = from_bits(words[i])
		y[i] = from_bits(words[8 + i])
	end
	return { x = x, y = y }
end

-- Board82C0D680 resets CollisionInfo and both probes, preserving7692.
function RidingOutputs.reset_for_teleport(self: RidingOutputs)
	local elapsed = self.ground.time_without_wheel_contact
	local drag = self.ground.wheel_angular_drag
	self.ground = BoardGroundState.default()
	self.ground.time_without_wheel_contact = elapsed
	self.ground.wheel_angular_drag = drag
	self.wheel_lines = WheelLineState.default()
	BoardProbes.reset_results(self.probes)
	-- Original82C0D680 preserves query handles203C..2050. EndBoard
	-- still consumes the batch submitted before this input-phase reset.
end

-- ROBLOX: Result<Self, String> -> (значение) или (nil, ошибка); ошибки
-- чтения данных поднимаются внутри pcall, как в settings.luau.
function RidingOutputs.load(data: any, runtime: any, processed_flags_2468: number): (RidingOutputs?, string?)
	local ok, result = pcall(function(): RidingOutputs
		local expect = collections_mod.expect
		local function f(field: string): number
			return expect(Collections.float(data, "physics_reckoning", "default", field))
		end
		local function control(field: string): F4
			local w = expect(Collections.words(data, "physics_reckoning", "default", field, 4))
			return { from_bits(w[1]), from_bits(w[2]), from_bits(w[3]), from_bits(w[4]) }
		end
		local function curve(field: string): point_graph.PointGraph
			return graph(data, "physics_reckoning", field)
		end
		local deck_words = expect(Collections.words(data, "physics_reckoning", "default", "DeckAngleUsageVsSpeed", 20))
		local deck_x, deck_y = {}, {}
		for i = 1, 8 do
			deck_x[i] = from_bits(deck_words[4 + i])
			deck_y[i] = from_bits(deck_words[12 + i])
		end
		local orientation_settings: ground_orientation.GroundOrientationSettings = {
			ground_normal_smoothing = control("GroundNormalSmoothing"),
			up_vector_smoothing_slow = control("UpVectorSmoothingSlow"),
			up_vector_smoothing_fast = control("UpVectorSmoothingFast"),
			dynamic_up_vs_ground_y = curve("DynamicUpVsGroundY"),
			ground_vector_blend = curve("GroundVectorBlendGraph"),
			deck_angle_usage_vs_speed = { x = deck_x, y = deck_y },
			up_vector_smoothing_vs_speed = curve("UpVectorSmoothingVsSpeed"),
			up_vector_max_delta_vs_speed = curve("UpVectorMaxDeltaVsSpeed"),
			ground_blend_max_delta = f("GroundVMaxBlendDelta"),
			up_vector_max_acceleration = f("UpVectorMaxAcceleration"),
			anti_wobble_damping = f("UpVectAntiWobbleDamping"),
			extra_side_damping = f("ExtraSideDamping"),
			-- ROBLOX: `as i32` — u32 со знаком.
			minimum_wheels_for_ground_blend = rt.to_i32(expect(Collections.integer(data, "physics_reckoning", "default", "MinWheelsToUseGroundVector"))),
		}
		local speed_settings: speed_and_slope.SpeedAndSlopeSettings = {
			turn_torque_vs_speed = graph(data, "physics_heading", "TurnTorqueVsSpeed"),
			turn_torque_vs_slope = graph(data, "physics_heading", "TurnTorqueVsSlope"),
			heading_adjust_max_speed = expect(Collections.float(data, "physics_heading", "default", "HeadingAdjustMaxSpeed")),
		}
		local reckoning = GroundOrientation.new(orientation_settings)
		local motion = BoardMotionOutput.from_board(runtime, reckoning.ground_normal, processed_flags_2468)
		local ground = BoardGroundState.default()
		local heading_adjust_factor = SpeedAndSlopeSettings.calculate(speed_settings, ground.wheel_normal.y, motion.forward_speed)
		return {
			ground = ground,
			wheel_lines = WheelLineState.default(),
			probes = BoardProbes.default(),
			reckoning = reckoning,
			reckoning_frames = ReckoningFrames.new(),
			body_spin = BodySpinState.new(),
			motion = motion,
			orientation_settings = orientation_settings,
			tilt_vs_rotation = curve("TiltVsRotGround"),
			tilt_vs_slope = curve("TiltVsSlopeGround"),
			speed_settings = speed_settings,
			maximum_ground_angle = f("MaxAllowedGroundNormalFromUp"),
			heading_adjust_factor = heading_adjust_factor,
			pending_wheel_queries = nil,
		}
	end)
	if not ok then
		return nil, tostring(result)
	end
	return result, nil
end

-- Original82DB5E10 reads current Processed464.y and2612 after Skeleton.
function RidingOutputs.update_input_heading(self: RidingOutputs, normal_y: number, speed: number): number
	self.heading_adjust_factor = SpeedAndSlopeSettings.calculate(self.speed_settings, normal_y, speed)
	return self.heading_adjust_factor
end

function RidingOutputs.heading_adjust_factor(self: RidingOutputs): number
	return self.heading_adjust_factor
end

-- Animated takeoff retains the rider's heading while the deck begins its
-- authored spin. Feeding the driven deck axis back into this frame would
-- apply that spin to the whole skater again on each ground-animation tick.
function RidingOutputs.update_ground_reckoning_with_heading(
	self: RidingOutputs,
	runtime: any,
	pose: RidingPoseInputs,
	processed_flags_2468: number,
	animation_balance: number,
	coffin: boolean,
	processed: any,
	heading: F4
)
	local BoardRuntime = (require("../../skate_core/physics/board_runtime") :: any).BoardRuntime
	local observations = GroundPacketInputs.from_processed(processed)
	local deck = BoardRuntime.part_transforms(runtime)[board.BodyId.Deck + 1]
	-- The source takes the previous final frame X for the damping step.
	local previous_right = self.reckoning_frames.system[1]
	-- ROBLOX: dev_trace (только debug-сборка Rust) не переносится.
	self.reckoning_frames.heading = table.clone(heading)
	body_spin.update_ground(self.body_spin, pose.body_spin)
	local effective = BoardMotionOutput.from_board(runtime, self.reckoning.ground_normal, processed_flags_2468)
	GroundOrientation.update(self.reckoning, self.orientation_settings, {
		com_to_deck = pose.com_to_deck,
		ground_normal = observations.wheel_normal,
		dynamic_up = observations.dynamic_up,
		speed = observations.speed,
		wheel_contact_count = observations.wheel_count,
		animation_balance = animation_balance,
		deck_angle_curve_input = observations.absolute_speed,
		board_up = vec3(deck.basis.columns[2]),
		board_forward = vec3(deck.basis.columns[3]),
		effective_board_forward = vec3(effective.effective_basis.columns[3]),
		previous_reckoning_right = vector.create(previous_right[1], previous_right[2], previous_right[3]),
		prevent_up_behind_board = coffin,
	})
	local up = lanes(self.reckoning.up)
	ReckoningFrames.calculate_transform(self.reckoning_frames, up, lanes(self.reckoning.ground_normal))
	ReckoningFrames.calculate_dynamic_lean(self.reckoning_frames, up, lanes(self.reckoning.dynamic_up))
	ReckoningFrames.calculate_tilt(
		self.reckoning_frames,
		bit32.band(processed_flags_2468, 0x100000) ~= 0,
		self.tilt_vs_rotation,
		self.tilt_vs_slope
	)
end

-- Ground preupdate82D37C50 ->82D38018 submits82D4E250. The host computes
-- that job directly: its heading seed, BodySpin, up filters, full transform,
-- dynamic lean and tilt. This must complete before ground forces consume it.
function RidingOutputs.update_ground_reckoning(
	self: RidingOutputs,
	runtime: any,
	pose: RidingPoseInputs,
	processed_flags_2468: number,
	animation_balance: number,
	coffin: boolean,
	processed: any
)
	local BoardRuntime = (require("../../skate_core/physics/board_runtime") :: any).BoardRuntime
	local deck = BoardRuntime.part_transforms(runtime)[board.BodyId.Deck + 1]
	local z = deck.basis.columns[3]
	-- Ordinary ground riding follows the physical deck (82D4E250).
	RidingOutputs.update_ground_reckoning_with_heading(
		self, runtime, pose, processed_flags_2468, animation_balance, coffin, processed,
		{ z[1], z[2], z[3], 0.0 }
	)
end

-- Slide82D3A890 seeds1136/1200 from Processed528/96 and calls82D8C8F0
-- directly. Its data block is exactly the Processed snapshot82D8E5C0.
function RidingOutputs.update_slide_reckoning(self: RidingOutputs, p: any, toolkit: any, physical_body_spin: number, balance: number)
	local function raw(v: { number }): Vector3
		return vector.create(from_bits(v[1]), from_bits(v[2]), from_bits(v[3]))
	end
	local previous_right = self.reckoning_frames.system[1]
	self.reckoning_frames.heading = table.clone(toolkit.deck[3])
	self.reckoning.dynamic_up = raw(p.vectors_464_480_496_512_528[5])
	body_spin.update_ground(self.body_spin, physical_body_spin)
	GroundOrientation.update(self.reckoning, self.orientation_settings, {
		com_to_deck = raw(p.animation_com_to_deck_752),
		ground_normal = raw(p.vectors_464_480_496_512_528[1]),
		dynamic_up = raw(p.vectors_464_480_496_512_528[5]),
		speed = p.scalar_2652,
		wheel_contact_count = rt.to_i32(p.wheel_count_2556),
		animation_balance = balance,
		deck_angle_curve_input = toolkit.absolute_speed,
		board_up = vec3(toolkit.deck[2]),
		board_forward = vec3(toolkit.deck[3]),
		effective_board_forward = vec3(toolkit.effective[3]),
		previous_reckoning_right = vec3(previous_right),
		prevent_up_behind_board = bit32.band(p.flags_2476, 0x4000_0000) ~= 0,
	})
	local up = lanes(self.reckoning.up)
	ReckoningFrames.calculate_transform(self.reckoning_frames, up, lanes(self.reckoning.ground_normal))
	ReckoningFrames.calculate_dynamic_lean(self.reckoning_frames, up, lanes(self.reckoning.dynamic_up))
	ReckoningFrames.calculate_tilt(self.reckoning_frames, bit32.band(p.flags_2468, 0x100000) ~= 0, self.tilt_vs_rotation, self.tilt_vs_slope)
end

-- StartSkateboardLineTests82DB6310 ->82C07788: four current wheel positions,
-- each queried0.2m along negative Reckoning up, radius0 and static-world
-- backend. World8275EA20 submits these before actor SetUpPhysics.
function RidingOutputs.start_wheel_queries(self: RidingOutputs, runtime: any, world: any): (boolean?, string?)
	if self.pending_wheel_queries ~= nil then
		return nil, "Wheel queries were started twice without result publication"
	end
	local lines = board_ground.wheel_lines(runtime, self.reckoning.up)
	local results: { board_ground.WheelLineHit | false } = { false, false, false, false }
	for i, line in lines do
		local hit, err = BoardWorld.query_thin_line(world, line.start, line.end_)
		if err ~= nil then
			return nil, string.format("Wheel%d stock line query: %s", i - 1, err)
		end
		if hit then
			results[i] = { fraction = hit.geometry.fraction, normal = hit.geometry.normal, surface_tag = hit.tag }
		end
	end
	local ok, err = BoardProbes.start(self.probes, runtime, world)
	if not ok then
		return nil, err
	end
	self.pending_wheel_queries = results
	return true, nil
end

-- World8275EB10 calls EndBoard8275E6E8 after PlayerInput and before
-- PostInput/state work. These results are available to this frame's state
-- selector, independently of the subsequent solve's contact reports.
function RidingOutputs.finish_wheel_queries(self: RidingOutputs): (boolean?, string?)
	local hits = self.pending_wheel_queries
	if hits == nil then
		return nil, "EndBoard requires its submitted wheel query batch"
	end
	self.pending_wheel_queries = nil
	WheelLineState.publish(self.wheel_lines, hits)
	return BoardProbes.publish(self.probes)
end

-- UpdatePostPhysics82C07D20 consumes current solved reports.
-- Contact-dependent inertia drag affects the next step. ProcessOutput
-- 82C02A80 publishes actual body rates with filtered normal1216.
function RidingOutputs.finish_post_physics(
	self: RidingOutputs,
	runtime: any,
	board_wiping_out: boolean,
	processed_flags_2468: number,
	time_step: number
): (boolean?, string?)
	local BoardRuntime = (require("../../skate_core/physics/board_runtime") :: any).BoardRuntime
	BoardGroundState.update(
		self.ground,
		BoardRuntime.contact_reports(runtime),
		self.wheel_lines,
		self.reckoning.up,
		self.maximum_ground_angle,
		board_wiping_out
	)
	local velocities = {}
	for i, body in BoardRuntime.bodies(runtime) do
		velocities[i] = body.rates.linear_velocity
	end
	BoardGroundState.sample_accelerations(self.ground, velocities, time_step)
	BoardGroundState.advance_contact_time(self.ground, time_step)
	local bodies = BoardRuntime.bodies_mut(runtime)
	for i = 1, 4 do
		-- S3 82C08634 writes inertia+36; S2 82B372E0 names this
		-- mAngularDrag. Linear drag belongs to separate state controls.
		bodies[i].inertia.angular_drag = self.ground.wheel_angular_drag[i]
	end
	self.motion = BoardMotionOutput.from_board(runtime, self.reckoning.ground_normal, processed_flags_2468)
	return true, nil
end

-- ROBLOX: возвращает таблицу с полями SpeedInputs (graph::conditions).
-- TODO: тип SpeedInputs переносится вместе с graph.
function RidingOutputs.graph_speeds(self: RidingOutputs): { speed: number, forward_speed: number, speed_and_slope: number }
	return {
		speed = self.motion.ground_speed,
		forward_speed = self.motion.forward_speed,
		speed_and_slope = self.heading_adjust_factor,
	}
end

return riding_outputs
