--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/control_ground.rs (коммит 2e16697)
--
-- Original Wipeout contact control82D3D660, using the world-space animation hands.
-- ROBLOX: processed: &ProcessedPhysicsInput — читается только поле
-- vectors_464_480_496_512_528 (слова u32).

local rt = require("../../../rt")
local m = require("./math")
local data = require("./data")
local torque = require("./torque")
local sar = require("../../physics/skeleton_animation_record")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type V = m.V

local control_ground = {}

local ZERO = { 0.0, 0.0, 0.0, 0.0 }

function control_ground.update(
	state: data.State,
	body: any,
	physical_com: V,
	effective: sar.AnimationPartTransform,
	processed: any,
	profile: any,
	animation_to_world: sar.AnimationPartTransform,
	animation_pose: { sar.AnimationPartTransform }
)
	-- 82D3D734 reads ProcessedPhysIn+464 (v6), NOT WipeoutState+464.
	-- The latter is a world position and reverses rolling at different locations.
	local words = processed.vectors_464_480_496_512_528[1]
	local ground_axis_464 = { from_bits(words[1]), from_bits(words[2]), from_bits(words[3]), from_bits(words[4]) }
	state.angular_velocity = torque.angular_velocity(body.record, body.definition.animation_masses.fractional)
	local speed = m.length(state.velocity)
	local raw = {}
	for i = 1, 4 do
		local x = f32(effective[1][i] * profile.roll_axis[1])
		local y = mul_add(effective[2][i], profile.roll_axis[2], x)
		raw[i] = mul_add(effective[3][i], profile.roll_axis[3], y)
	end
	local rolling_axis = m.normalize_or(raw, ZERO)
	local hand_a = sar.compose_affine(animation_to_world, animation_pose[4])
	local hand_b = sar.compose_affine(animation_to_world, animation_pose[8])
	local hands_close = m.length(m.sub(hand_a[4], hand_b[4])) <= f32(0.6)
	local alignment = ZERO
	if profile.align_ground_with_velocity then
		local axis = m.normalize_or(m.cross(ground_axis_464, state.velocity), ZERO)
		if m.dot(rolling_axis, axis) < 0.0 then
			rolling_axis = m.scale(rolling_axis, -1.0)
		end
		local perpendicular = m.cross(rolling_axis, axis)
		local sine = m.clamp(m.length(perpendicular), -f32(0.9999), f32(0.9999))
		local angle = m.wrap_angle(trigonometry.asin(sine))
		local magnitude = m.clamp(f32(angle * f32(1.2)), 0.0, 1.0)
		if speed > 2.0 then
			local a2 = m.normalize_or(perpendicular, ZERO)
			local current = m.normalize_or(state.angular_velocity, ZERO)
			alignment = m.scale(m.sub(m.scale(a2, magnitude), m.scale(a2, m.dot(current, a2))), profile.ground_align_torque)
		end
	end
	local rolling = ZERO
	if hands_close and profile.roll_on_ground and speed > 2.0 then
		local current = m.normalize_or(state.angular_velocity, ZERO)
		rolling = m.scale(
			m.sub(m.scale(m.scale(rolling_axis, 1.5), state.forward_input), m.scale(rolling_axis, m.dot(current, rolling_axis))),
			profile.ground_roll_torque
		)
	end
	torque.apply(body, physical_com, m.add(alignment, rolling))
end

return control_ground
