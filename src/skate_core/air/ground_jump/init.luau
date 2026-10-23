--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/ground_jump/mod.rs (коммит 2e16697)
--
-- GroundAnimation's Toolkit_CalcGroundJump, original TU3 82D93618.
-- Stock graph values and live animation/physical inputs determine launch.

local rt = require("../../rt")
local trigonometry = require("../trigonometry")
local point_graph = require("../point_graph")
local air_math = require("./state/math")
local m = require("@self/math")
local types = require("@self/types")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local acos = trigonometry.acos
local evaluate = point_graph.PointGraph.evaluate
local AirMath = air_math.AirMath
local dot, add, sub, scale, madd, planar = m.dot, m.add, m.sub, m.scale, m.madd, m.planar
local maximum, clamp, vector_clamp, reciprocal = m.maximum, m.clamp, m.vector_clamp, m.reciprocal
local square_root, length, normalize, cross = m.square_root, m.length, m.normalize, m.cross

local ground_jump = {}
ground_jump.GroundJump = types.GroundJump
export type GroundJump = types.GroundJump
export type GroundJumpInput = types.GroundJumpInput
export type GroundJumpMode = types.GroundJumpMode
export type GroundJumpSettings = types.GroundJumpSettings

function ground_jump.calculate(input: GroundJumpInput, mode: GroundJumpMode, s: GroundJumpSettings): GroundJump
	local hippy = bit32.btest(input.flags_2480, 0x0000_1000)
	if not bit32.btest(input.flags_2468, 0x0040_0000) and not hippy then
		return types.GroundJump.default()
	end
	local normal = input.filtered_ground_normal
	local y_scalar = evaluate(s.y_scalar_vs_normal_y, normal[2])
	local current = planar(input.current_velocity, normal)
	local prepared = planar(input.prepared_velocity, normal)
	if dot(sub(current, prepared), sub(current, prepared)) > 7.0 then
		local agreement = vector_clamp(dot(normalize(current), normalize(prepared)), 0.0, 1.0)
		local fraction = f32(acos(agreement) * reciprocal(from_bits(0x4049_0fdb)))
		local bound = f32(length(prepared) * evaluate(s.speed_scalar_vs_angle, fraction))
		prepared = AirMath.clamp_vector_within_max_length(AirMath, current, bound)
	end
	local velocity
	if bit32.btest(input.flags_2488, 0x1000_0000) then
		velocity = madd(input.effective_forward, f32(2.3), prepared)
		velocity[2] = f32(velocity[2] + 1.0)
	else
		local minimum
		if hippy then
			minimum = s.hippy_minimum_height
		elseif bit32.btest(input.flags_2484, 0x800) then
			minimum = mode.minimum_height_64
		else
			minimum = mode.minimum_height_68
		end
		local speed_fraction = clamp(f32(input.surface_speed / s.speed_response_max_speed), 0.0, 1.0)
		local low = mul_add(evaluate(s.minimum_height_vs_speed, speed_fraction), f32(minimum - s.absolute_minimum_height), s.absolute_minimum_height)
		local high = mul_add(
			evaluate(s.maximum_height_vs_speed, speed_fraction),
			f32((if hippy then s.hippy_maximum_height else mode.maximum_height) - s.absolute_minimum_height),
			s.absolute_minimum_height
		)
		local height = mul_add(low, f32(1.0 - input.jump_strength), f32(high * input.jump_strength))
		local current_height = dot(sub(input.animation_com_position, input.ground_reference_position), input.reference_up)
		local remaining = maximum(f32(height - current_height), 0.0)
		local square = f32(f32(remaining * input.gravity_y) * -2.0)
		local speed = square_root(square)
		local angle = acos(vector_clamp(normal[2], -1.0, 1.0))
		local fraction = clamp(f32(angle * from_bits(0x3f22_f983)), 0.0, 1.0)
		local response = maximum(evaluate(s.vertical_response, fraction), s.minimum_scalar)
		velocity = madd(normal, f32(speed * response), prepared)
	end
	local bonus = clamp(f32(f32(y_scalar - 1.0) * velocity[2]), 0.0, s.maximum_y_bonus)
	velocity[2] = f32(velocity[2] + bonus)
	local projected = dot(velocity, normal)
	local side = normalize(cross(m.up(), input.forward))
	local x = -f32(f32(input.jump_controls[1] * s.adjust_x_factor) * projected)
	local z = f32(f32(input.jump_controls[2] * s.adjust_z_factor) * projected)
	local correction = madd(side, x, scale(cross(side, m.up()), z))
	return { velocity = add(velocity, correction), scalar_16 = 0.0, active = true }
end

return ground_jump
