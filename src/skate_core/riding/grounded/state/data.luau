--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/data.rs (коммит 2e16697)
--
-- Persistent fields owned by TU3 `PhysState_PhysicsGround`.
--
-- Offsets remain in names when the original semantic name has not been
-- recovered. This prevents an adapter from silently assigning an invented
-- meaning to a stock field.

local rt = require("../../../../rt")

local f32 = rt.f32
local from_bits = rt.from_bits

type F4 = { number }

local data = {}

export type PhysicsGroundState = {
	-- Collision-force record retained by the successful `82D944E8` branch.
	collision_force_2528: F4,
	collision_point_2544: F4,
	word_2560: number,
	word_2564: number,
	-- Collision response retained and decayed by `82D38800`.
	vector_2592: F4,
	-- Direct hang-up force assembled by `82D39510`.
	vector_2608: F4,
	-- Output of `Toolkit_AntiFlipTorque` (`82D94190`).
	anti_flip_torque_2624: F4,
	-- Optional steering history arguments passed to `82D92440`.
	steering_push_scalar_2640: number,
	steering_damped_turn_2644: number,
	-- Accumulated by ProcessedPhysIn+2604 once per Ground Update.
	elapsed_2648: number,
	-- Collision-response countdown set from the selected global settings.
	collision_countdown_2652: number,
	-- First contacted position captured once for spawn pinning.
	captured_position_x_2656: number,
	captured_position_z_2660: number,
	-- Time remaining before the skater may enter the skitch path.
	scalar_2664: number,
	-- Height of the selected skitch spline.
	scalar_2668: number,
	-- Multiplies the straighten-out torque before heading calculation.
	straighten_scale_2672: number,
	-- Animated-board velocity/displacement state used by Enter/Exit and Update.
	vector_2688: F4,
	-- Explicitly zeroed by `82D93DF0` through its Ground+2688 output record.
	scalar_2704: number,
	-- Selects the animated-board branch of `82D38800`.
	flag_2708: boolean,
	flag_2720: boolean,
	flag_2721: boolean,
	flag_2722: boolean,
	anti_flip_nudge_applied_2723: boolean,
	-- Pinning is restricted to the human-player path.
	human_player_2724: boolean,
	controls_latched_2725: boolean,
	captured_position_valid_2726: boolean,
	pinning_2727: boolean,
	was_pinning_2728: boolean,
	flag_2729: boolean,
	push_suppressed_2730: boolean,
	flag_2731: boolean,
	manual_correction_2732: boolean,
	manual_opposition_2733: boolean,
	hang_detection_frames_2740: number,
	hang_force_frames_2744: number,
	hung_wipeout_frames_2748: number,
	anti_flip_nudge_frames_2752: number,
}

local function zero4(): F4
	return { 0.0, 0.0, 0.0, 0.0 }
end

local PhysicsGroundState = {}
data.PhysicsGroundState = PhysicsGroundState

-- Ground constructor82D37358..37534. Fields whose first native write is
-- Enter are safe host zero storage until Enter replaces them; this method
-- does not imply that entering Ground has already occurred.
function PhysicsGroundState.before_first_enter(human_player: boolean): PhysicsGroundState
	return {
		collision_force_2528 = zero4(),
		collision_point_2544 = zero4(),
		word_2560 = 0,
		word_2564 = 0,
		vector_2592 = zero4(),
		vector_2608 = zero4(),
		anti_flip_torque_2624 = zero4(),
		steering_push_scalar_2640 = 0.0,
		steering_damped_turn_2644 = 0.0,
		elapsed_2648 = 0.0,
		collision_countdown_2652 = 0.0,
		captured_position_x_2656 = 0.0,
		captured_position_z_2660 = 0.0,
		scalar_2664 = 0.0,
		scalar_2668 = 0.0,
		straighten_scale_2672 = 0.0,
		vector_2688 = zero4(),
		scalar_2704 = 0.0,
		flag_2708 = false,
		flag_2720 = false,
		flag_2721 = false,
		flag_2722 = false,
		anti_flip_nudge_applied_2723 = false,
		human_player_2724 = human_player,
		controls_latched_2725 = false,
		captured_position_valid_2726 = false,
		pinning_2727 = false,
		was_pinning_2728 = false,
		flag_2729 = false,
		push_suppressed_2730 = false,
		flag_2731 = false,
		manual_correction_2732 = false,
		manual_opposition_2733 = false,
		hang_detection_frames_2740 = 0,
		hang_force_frames_2744 = 0,
		hung_wipeout_frames_2748 = 0,
		anti_flip_nudge_frames_2752 = 0,
	}
end

-- ROBLOX: #[derive(Clone, Copy)] — явная копия с копиями массивов.
function PhysicsGroundState.clone(self: PhysicsGroundState): PhysicsGroundState
	local c = table.clone(self)
	for k, v in c :: any do
		if type(v) == "table" then
			(c :: any)[k] = table.clone(v)
		end
	end
	return c
end

-- State-owned prefix82D3758C..5C0 after the physical collision mode change.
function PhysicsGroundState.begin_entry(self: PhysicsGroundState)
	self.word_2560 = 0
	self.word_2564 = 0
	self.flag_2708 = false
	self.controls_latched_2725 = false
	self.captured_position_valid_2726 = false
	self.was_pinning_2728 = false
	self.flag_2731 = false
	self.manual_correction_2732 = false
	self.manual_opposition_2733 = false
end

-- State-owned tail82D378AC..7914, after pumping and controller-mode reset.
function PhysicsGroundState.finish_entry(self: PhysicsGroundState, previous_state: number)
	self.straighten_scale_2672 = if previous_state == 101 then from_bits(0x3e23_d70a) else 1.0
	self.steering_push_scalar_2640 = 1.0
	self.steering_damped_turn_2644 = 0.0
	self.elapsed_2648 = 0.0
	self.collision_countdown_2652 = 0.0
	self.vector_2592 = zero4()
	self.vector_2608 = zero4()
	self.anti_flip_torque_2624 = zero4()
	self.hang_detection_frames_2740 = 0
	self.hang_force_frames_2744 = 0
	self.hung_wipeout_frames_2748 = 0
	self.anti_flip_nudge_frames_2752 = 0
	self.flag_2721 = false
	self.anti_flip_nudge_applied_2723 = false
	self.push_suppressed_2730 = false
end

export type GroundUpdateSignals = { set_skeleton_flag_16505: boolean }

function PhysicsGroundState.begin_update_at(self: PhysicsGroundState, wheel_contacts: number, position: F4): GroundUpdateSignals
	if not self.captured_position_valid_2726 and wheel_contacts > 0 then
		self.captured_position_x_2656 = position[1]
		self.captured_position_z_2660 = position[3]
		self.captured_position_valid_2726 = true
	end
	self.anti_flip_torque_2624 = zero4()
	self.flag_2722 = false
	self.anti_flip_nudge_applied_2723 = false
	self.pinning_2727 = false
	self.scalar_2664 = -1.0
	self.flag_2729 = false
	return { set_skeleton_flag_16505 = self.elapsed_2648 > from_bits(0x3d4c_cccd) }
end

-- Prefix of `Update` `82D37CB4..82D37D28`, before contact-state work.
function PhysicsGroundState.begin_update(self: PhysicsGroundState, input: GroundUpdateInput): GroundUpdateSignals
	return PhysicsGroundState.begin_update_at(self, input.wheel_contact_count_2556, input.position_112)
end

-- Tail of `Update` `82D37EBC..82D37EEC` after prediction succeeds.
function PhysicsGroundState.finish_update(self: PhysicsGroundState, timestep_2604: number)
	self.elapsed_2648 = f32(self.elapsed_2648 + timestep_2604)
end

export type GroundUpdateInput = {
	wheel_contact_count_2556: number,
	position_112: F4,
	timestep_2604: number,
	contact_state: any, -- contact_state.GroundContactStateInput
}

-- Contact identity history updated by `82D38430`. The concrete collision
-- object handle is supplied by the world adapter rather than stored as a host
-- pointer in the engine-independent core.
-- ROBLOX: Option<T> -> значение или nil.
export type GroundContactHistory = {
	differing_contact_frames_2756: number,
	tracked_contact_2760: any,
}

local GroundContactHistory = {}
data.GroundContactHistory = GroundContactHistory

function GroundContactHistory.empty(): GroundContactHistory
	return { differing_contact_frames_2756 = 0, tracked_contact_2760 = nil }
end

return data
