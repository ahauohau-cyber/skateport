--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/data.rs (коммит 2e16697)
--
-- Original WipeoutGround Reset82D3B3A8. Native offsets document ownership.
-- ROBLOX: [f32; 4] -> таблица из 4 чисел; profile (usize) — индекс с нуля.

local rt = require("../../../rt")

local data = {}

export type State = {
	time: number, -- 304
	settled_time: number, -- 308
	time_until_teleport: number, -- 312
	impaled_time: number, -- 316
	no_support_time: number, -- 320
	response_time: number, -- 324
	extra_weight_zero_time: number, -- 328
	slow_time: number, -- 332
	surface_height: number, -- 336
	board_offset: { number }, -- 352
	forward: { number }, -- 368
	right: { number }, -- 384
	angular_velocity: { number }, -- 400
	retained_tilt: { number }, -- 416
	velocity: { number }, -- 432
	retained_velocity: { number }, -- 448
	predicted_position: { number }, -- 464
	over: boolean, -- 480
	slow: boolean, -- 481
	material_eleven_response: boolean, -- 482
	air_collision_mode: boolean, -- 483
	request_teleport: boolean, -- 484
	move_board: boolean, -- 485
	special_surface: boolean, -- 486
	below_surface: boolean, -- 487
	retained_velocity_active: boolean, -- 488
	sideways_input: number, -- 492
	forward_input: number, -- 496
	orientation: number, -- 500
	collision_weight: number, -- 504
	controlled_weight: number, -- 508
	control_time: number, -- 512
	retained_sideways_input: number, -- 516
	retained_forward_input: number, -- 520
	response_scalar: number, -- 524
	extra_weight: number, -- 528
	maximum_speed: number, -- 532
	response_start_speed: number, -- 536
	response_change: number, -- 540
	board_move_frames: number, -- 544, initialized by Enter
	response_count: number, -- 548
	response_frames: number, -- 552
	airborne_frames: number, -- 556
	teleport_countdown: number, -- 560
	prevent_manual: boolean, -- 564
	ignore_reset: boolean, -- 565
	reset_ever: boolean, -- 566
	ever_settled: boolean, -- 567
	recovery_eligible: boolean, -- 568
	teleport_pending: boolean, -- 569
	ever_impaled: boolean, -- 570
	direction_initialized: boolean, -- 571
	material_ten_response: boolean, -- 572
	imminent_surface_twelve: boolean, -- 573
	allow_retained_velocity: boolean, -- 574
	response_finished: boolean, -- 575
	surface_query: boolean, -- 576
	profile: number, -- 580
	predicted_time: number, -- 832
}

local State = {}
data.State = State

-- ROBLOX: impl Default for State.
function State.default(): State
	local z = function()
		return { 0.0, 0.0, 0.0, 0.0 }
	end
	return {
		time = 0.0, settled_time = 0.0, time_until_teleport = 0.0,
		impaled_time = 0.0, no_support_time = 0.0, response_time = 0.0,
		extra_weight_zero_time = 0.0, slow_time = 0.0, surface_height = 0.0,
		board_offset = z(), forward = z(), right = z(),
		angular_velocity = z(), retained_tilt = z(), velocity = z(),
		retained_velocity = z(), predicted_position = z(),
		over = false, slow = false, material_eleven_response = false,
		air_collision_mode = false, request_teleport = false, move_board = false,
		special_surface = false, below_surface = false, retained_velocity_active = false,
		sideways_input = 0.0, forward_input = 0.0, orientation = 0.0,
		collision_weight = 0.0, controlled_weight = 0.0, control_time = 0.0,
		retained_sideways_input = 0.0, retained_forward_input = 0.0,
		response_scalar = 0.0, extra_weight = 1.0, maximum_speed = 10.0,
		response_start_speed = 0.0, response_change = 0.0, board_move_frames = 0,
		response_count = 0, response_frames = -1, airborne_frames = -1,
		teleport_countdown = -1, prevent_manual = false, ignore_reset = false,
		reset_ever = false, ever_settled = false, recovery_eligible = false,
		teleport_pending = false, ever_impaled = false, direction_initialized = false,
		material_ten_response = false, imminent_surface_twelve = false,
		allow_retained_velocity = true, response_finished = false,
		surface_query = false, profile = 0, predicted_time = rt.F32_MAX,
	}
end

-- ROBLOX: #[derive(Clone)].
function State.clone(self: State): State
	return table.clone(self)
end

return data
