--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/pumping/controller.rs (коммит 2e16697)
--
-- Recovered scalar/control flow of TU3 82D8F228 and 82D8F470.
--
-- Production uses geometry::NativePumpingGeometry for the original vector
-- operations, refinement order and inverse-cosine kernel. The Ground adapter
-- supplies the current physical sample and the selected stock mode each tick.

local rt = require("../../../rt")
local point_graph = require("../../point_graph")
local settings_mod = require("./settings")
local state_mod = require("./state")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph

type F4 = { number }

local controller = {}

-- Literal loaded by Ground Update 82D37EA0, independent of Processed+2604.
controller.GROUND_PUMPING_TIMESTEP = from_bits(0x3c88_8889)

export type PumpingSample = {
	-- Ground caller: ProcessedPhysIn+112, ground context+1216, skeleton+11008.
	position: F4,
	normal: F4,
	com_to_deck_world: F4,
	-- Ground's signed-angle difference calculation supplies the absolute angle.
	deck_angle: number,
	-- Ground caller extracts ProcessedPhysIn+2476 bit 1.
	intentional_pumping: number,
}

-- Recovered numeric operations, implemented by geometry::NativePumpingGeometry.
-- ROBLOX: трейт -> таблица методов height/speed/angular_speed/inclination_radians,
-- каждый возвращает (значение) или (nil, ошибка).
export type PumpingGeometry = {
	height: (self: any, normal: F4, com_to_deck: F4) -> (number?, string?),
	speed: (self: any, previous: F4, current: F4, dt: number) -> (number?, string?),
	angular_speed: (self: any, previous_position: F4, previous_normal: F4, sample: PumpingSample, dt: number) -> (number?, string?),
	inclination_radians: (self: any, clamped_normal_y: number) -> (number?, string?),
}

local function unit(value: number): number
	local lower = if -value >= 0.0 then 0.0 else value
	return if f32(1.0 - lower) >= 0.0 then lower else 1.0
end

-- Scalar portion of Calculate, including output write/curve evaluation order.
-- Does not update the Update-owned cached pose, pump time or pump acceleration.
function controller.calculate(
	state: state_mod.PumpingState,
	settings: settings_mod.PumpingSettings,
	sample: PumpingSample,
	timestep: number,
	geometry: PumpingGeometry
): (number?, string?)
	local speed, e1 = geometry:speed(state.previous_position, sample.position, timestep)
	if speed == nil then
		return nil, e1
	end
	local speed_effect = PointGraph.evaluate(settings.pump_vs_speed, speed)
	local angular_speed, e2 = geometry:angular_speed(state.previous_position, state.previous_normal, sample, timestep)
	if angular_speed == nil then
		return nil, e2
	end
	local measured = f32(angular_speed * settings.angular_speed_damping)
	state.angular_speed = mul_add(f32(1.0 - settings.angular_speed_damping), state.angular_speed, measured)
	state.absorption = -f32(speed * state.angular_speed)
	local inclination, e3 = geometry:inclination_radians(unit(state.previous_normal[2]))
	if inclination == nil then
		return nil, e3
	end
	-- Stock 822F8B7C: 2/pi rounded to binary32. This is not host acos().
	local radians_to_quarter_turns = from_bits(0x3f22_f983)
	local ground_angle = unit(f32(radians_to_quarter_turns * inclination))
	state.ground_normal_absorption = f32(PointGraph.evaluate(settings.compression_vs_ground_angle, ground_angle) * settings.ground_compression_scale)
	state.minimum_crouch = PointGraph.evaluate(settings.min_crouch_vs_ground_angle, ground_angle)
	state.deck_angle_absorption = PointGraph.evaluate(settings.compression_vs_deck_angle, f32(sample.deck_angle * radians_to_quarter_turns))
	local deck_compression = f32(settings.deck_compression_scale * state.deck_angle_absorption)
	local pumping = f32(state.angular_speed * speed_effect)
	if f32(deck_compression * deck_compression) > f32(state.ground_normal_absorption * state.ground_normal_absorption) then
		state.ground_normal_absorption = deck_compression
	end
	return pumping, nil
end

-- Executes the recovered lifecycle only when the required geometry succeeds.
-- An error leaves the already executed prefix visible, and must abort the
-- caller's simulation tick; it is never permission to publish partial forces.
-- ROBLOX: Result<(), E> -> (true) или (nil, ошибка).
function controller.update(
	state: state_mod.PumpingState,
	settings: settings_mod.PumpingSettings,
	mode: settings_mod.PumpingMode,
	sample: PumpingSample,
	timestep: number,
	geometry: PumpingGeometry
): (boolean?, string?)
	state.pump_acceleration = 0.0
	local height, err = geometry:height(sample.normal, sample.com_to_deck_world)
	if height == nil then
		return nil, err
	end
	if state.record_valid then
		state.intentional_pumping = sample.intentional_pumping
		local change = f32(height - state.previous_height)
		local rising_change = if change >= 0.0 then change else 0.0
		local retained = f32(f32(1.0 - settings.height_change_damping) * state.smoothed_height_change)
		local smoothed = mul_add(rising_change, settings.height_change_damping, retained)
		state.smoothed_height_change = smoothed
		-- bge after fcmpu takes the unordered path too: do not replace with >=.
		local effect = if smoothed < settings.minimum_height_change then 0.0 else smoothed
		state.pumping_time = if effect > 0.0 then f32(state.pumping_time + timestep) else 0.0
		if math.abs(effect) > settings.maximum_height_change then
			local sign
			if effect >= 0.0 then
				sign = if effect > 0.0 then 1.0 else 0.0
			else
				sign = -1.0
			end
			effect = f32(sign * settings.maximum_height_change)
		end
		effect = f32(PointGraph.evaluate(settings.pump_vs_time, state.pumping_time) * effect)
		local pumping, perr = controller.calculate(state, settings, sample, timestep, geometry)
		if pumping == nil then
			return nil, perr
		end
		state.pumping = pumping
		local factor = if f32(pumping * effect) > 0.0 then mode.acceleration_factor else mode.absorption_factor
		local raw = f32(f32(pumping * factor) * effect)
		local lower = -f32(mode.maximum_absorption_per_second * timestep)
		local upper = f32(mode.maximum_acceleration_per_second * timestep)
		local lower_clamped = if f32(lower - raw) >= 0.0 then lower else raw
		state.pump_acceleration = if f32(upper - lower_clamped) >= 0.0 then lower_clamped else upper
	end
	state.previous_position = table.clone(sample.position)
	state.previous_normal = table.clone(sample.normal)
	state.record_valid = true
	state.previous_height = height
	return true, nil
end

-- Pumping slice of Ground Update 82D37EA8. Force assembly must follow only
-- after this succeeds; it has its own ProcessedPhysIn timestep for force scaling.
function controller.update_ground(
	state: state_mod.PumpingState,
	settings: settings_mod.PumpingSettings,
	mode: settings_mod.PumpingMode,
	sample: PumpingSample,
	geometry: PumpingGeometry
): (boolean?, string?)
	return controller.update(state, settings, mode, sample, controller.GROUND_PUMPING_TIMESTEP, geometry)
end

return controller
