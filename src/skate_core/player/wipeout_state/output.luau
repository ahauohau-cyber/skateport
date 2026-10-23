--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/output.rs (коммит 2e16697)
--
-- Physical output stores82D3EEE8. Optional fields are conditional writes,
-- not instructions to clear the corresponding shared output on false paths.
-- ROBLOX: impl State { fn output } -> output.output(state, ...); Option -> значение или nil.

local rt = require("../../../rt")
local m = require("./math")
local data = require("./data")
local orientation = require("./orientation")

local f32 = rt.f32
local from_bits = rt.from_bits

local output = {}

export type Output = {
	over_599: boolean,
	scalar_544: number,
	no_support_time_548: number,
	can_leave_72: boolean,
	special_surface_81: boolean,
	below_surface_82: boolean,
	surface_height_32: number,
	surface_height_valid_83: boolean,
	collision_time_144: number,
	profile_148: number,
	response_strength_580: number,
	extra_weight_584: number,
	time_until_teleport_576: number,
	teleport_pending_604: boolean,
	material_ten_3479: boolean,
	material_eleven_3480: boolean,
	imminent_surface_twelve_3483: boolean,
	predicted_position_64: { number },
	retained_air_velocity_160: { number }?,
	response_change_588: number?,
	teleport_countdown_68: boolean,
	request_teleport_69: boolean,
	hips_right_angle_496: number,
	hips_up_angle_500: number,
}

function output.output(self: data.State, hips: { { number } }, normal: { number }): Output
	local right = hips[1]
	local projected = m.sub(normal, m.scale(right, m.dot(normal, right)))
	local right_angle = orientation.signed_angle(right, normal, { 0.0, 0.0, 0.0, 0.0 })
	local up_angle = m.wrap_angle(f32(orientation.signed_angle(projected, hips[2], right) + from_bits(0x4049_0FDB)))
	return {
		over_599 = self.over,
		scalar_544 = self.orientation,
		no_support_time_548 = self.no_support_time,
		can_leave_72 = self.recovery_eligible and not self.prevent_manual and not self.ignore_reset,
		special_surface_81 = self.special_surface,
		below_surface_82 = self.below_surface,
		surface_height_32 = self.surface_height,
		surface_height_valid_83 = true,
		collision_time_144 = self.predicted_time,
		profile_148 = self.profile,
		response_strength_580 = self.response_scalar,
		extra_weight_584 = self.extra_weight,
		time_until_teleport_576 = self.time_until_teleport,
		teleport_pending_604 = self.teleport_pending,
		material_ten_3479 = self.material_ten_response,
		material_eleven_3480 = self.material_eleven_response,
		imminent_surface_twelve_3483 = self.imminent_surface_twelve,
		predicted_position_64 = self.predicted_position,
		retained_air_velocity_160 = if self.retained_velocity_active then self.retained_velocity else nil,
		response_change_588 = if self.response_finished then self.response_change else nil,
		teleport_countdown_68 = self.teleport_countdown >= 0,
		request_teleport_69 = self.request_teleport,
		hips_right_angle_496 = right_angle,
		hips_up_angle_500 = up_angle,
	}
end

return output
