--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_landing.rs (коммит 2e16697)
--
-- Complete TU3 Skeleton::UpdateLandingAdjust82BD9028. This owns the four
-- landing modes and history; it does not synthesize physical COM observations.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local skeleton_board_offset = require("./skeleton_board_offset")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph
local SkateboardOffset = skeleton_board_offset.SkateboardOffset

local STEP = from_bits(0x3C88_8889)
local F32_MAX = from_bits(0x7F7F_FFFF)

local skeleton_landing = {}

export type LandingSettings = {
	manual_blend: point_graph.PointGraph,
	grind_blend: point_graph.PointGraph,
	coffin_height: point_graph.PointGraph,
	minimum_height: number,
	maximum_velocity: number,
	manual_damping: number,
	manual_spring: number,
	ground_minimum_compression_time: number,
	ground_damping: number,
	ground_spring: number,
	grind_animation_target_time: number,
	grind_damping: number,
	grind_spring: number,
	grind_target_delta: number,
	desired_com_height: number,
	coffin_time: number,
	coffin_maximum_velocity: number,
	coffin_blend_frames: number,
	coffin_base_height: number,
}

export type LandingInput = {
	filtered_state: number,
	flags_2468: number,
	flags_2472: number,
	flags_2476: number,
	balance: number,
	-- dot(Processed608 physical COM velocity, Processed544 ground up).
	physical_com_velocity_along_up: number,
	-- dot(Skeleton10928 physical COM - Skeleton9680 physical board, up).
	physical_com_height: number,
	-- Previous animation COM Skeleton10960.y minus current board pose12672.y.
	animation_com_height: number,
}

export type LandingAdjustment = {
	active: boolean,
	kind: number,
	time: number,
	position: number,
	velocity: number,
	previous_com_velocity: number,
	previous_animation_height: number,
	previous_filtered_state: number,
	desired_grind_com: number,
}

local LandingAdjustment = {}
skeleton_landing.LandingAdjustment = LandingAdjustment

-- ROBLOX: impl Default.
function LandingAdjustment.default(): LandingAdjustment
	-- Skeleton ctor82BD7A9C..7ABC.
	return {
		active = false,
		kind = 0,
		time = 0.0,
		position = 0.0,
		velocity = 0.0,
		previous_com_velocity = 0.0,
		previous_animation_height = F32_MAX,
		previous_filtered_state = 0,
		desired_grind_com = 0.0,
	}
end

local function select(selector: number, positive: number, negative: number): number
	return if selector >= 0.0 then positive else negative
end

function LandingAdjustment.update(self: LandingAdjustment, input: LandingInput, settings: LandingSettings, offset: skeleton_board_offset.SkateboardOffset)
	local from_offboard = self.previous_filtered_state == 6 and input.filtered_state == 1
	local from_air = self.previous_filtered_state == 2 and input.filtered_state == 1
	local ground = (from_offboard or from_air) and bit32.band(input.flags_2476, 0x1000_0000) ~= 0
	local manual = from_air and input.balance ~= 0.0
	local grind = self.previous_filtered_state == 2 and input.filtered_state == 3 and bit32.band(input.flags_2468, 0x20) == 0
	local coffin_flag = bit32.band(input.flags_2472, 1) ~= 0
	local coffin = coffin_flag and (grind or from_air)
	local cancel = bit32.band(input.flags_2476, 0x4000_0000) ~= 0 and not coffin_flag
	if cancel then
		self.active = false
	end
	local first_ground_update = false
	if not cancel and not self.active and (ground or coffin or manual or grind) then
		self.time = 0.0
		self.active = true
		self.kind = if coffin then 3 elseif manual then 2 elseif ground then 0 else 1
		first_ground_update = self.kind == 0
		local velocity = if grind or coffin then self.previous_com_velocity else input.physical_com_velocity_along_up
		local lower = select(f32(-settings.maximum_velocity - velocity), -settings.maximum_velocity, velocity)
		self.velocity = select(-lower, lower, 0.0)
		self.previous_animation_height = F32_MAX
		self.position = input.physical_com_height
	end
	if self.active then
		local spring = 0.0
		local damping = 0.0
		local blend = 0.0
		local release = false
		local allow_upwards = true
		local kind = self.kind
		if kind == 0 then
			spring = settings.ground_spring
			damping = settings.ground_damping
			allow_upwards = false
			blend = 1.0
			release = input.filtered_state ~= 1 or bit32.band(input.flags_2476, 0x1000_0000) == 0
		elseif kind == 1 then
			spring = settings.grind_spring
			damping = settings.grind_damping
			blend = PointGraph.evaluate(settings.grind_blend, self.time)
			release = input.filtered_state ~= 3
		elseif kind == 2 then
			spring = settings.manual_spring
			damping = settings.manual_damping
			blend = PointGraph.evaluate(settings.manual_blend, self.time)
			release = input.filtered_state ~= 1
		elseif kind == 3 then
			blend = 1.0
			release = input.filtered_state ~= 1 or self.time > settings.coffin_time or not coffin_flag
		end
		local animation_height = input.animation_com_height
		if self.kind == 3 then
			local ratio = f32(math.abs(self.velocity) / settings.coffin_maximum_velocity)
			local positive_ratio = select(-ratio, 0.0, ratio)
			local scale = select(f32(1.0 - positive_ratio), positive_ratio, 1.0)
			local height = PointGraph.evaluate(settings.coffin_height, f32(self.time / settings.coffin_time))
			self.position = mul_add(height, scale, settings.coffin_base_height)
		else
			local target = settings.desired_com_height
			if self.kind == 1 then
				if self.time > settings.grind_animation_target_time then
					local minimum = f32(self.desired_grind_com - settings.grind_target_delta)
					local maximum = f32(self.desired_grind_com + settings.grind_target_delta)
					local lower = select(f32(minimum - animation_height), minimum, animation_height)
					target = select(f32(maximum - lower), lower, maximum)
				end
				self.desired_grind_com = target
			end
			local displacement = f32(self.position - target)
			local previous_velocity = self.velocity
			-- fnmsubs of damping*velocity and negative spring displacement.
			local spring_force = -f32(displacement * spring)
			local acceleration = -mul_add(previous_velocity, damping, -spring_force)
			local candidate = mul_add(acceleration, STEP, previous_velocity)
			local lower = select(f32(-settings.maximum_velocity - candidate), -settings.maximum_velocity, candidate)
			local maximum = if allow_upwards then settings.maximum_velocity else 0.0
			self.velocity = select(f32(maximum - lower), lower, maximum)
			local integrated = mul_add(f32(f32(self.velocity + previous_velocity) * 0.5), STEP, displacement)
			local height = f32(integrated + target)
			self.position = select(f32(height - settings.minimum_height), height, settings.minimum_height)
		end
		local displacement = f32(animation_height - self.position)
		if first_ground_update then
			local correction = f32(self.velocity * from_bits(0x3C75_C28F))
			local lower = select(f32(f32(-0.1) - correction), f32(-0.1), correction)
			local down = select(-lower, lower, 0.0)
			local combined = f32(down + displacement)
			displacement = select(combined, combined, 0.0)
		end
		if self.kind == 0 and self.time > settings.ground_minimum_compression_time and self.previous_animation_height < animation_height and displacement > 0.0 then
			release = true
		end
		if self.kind == 1 and bit32.band(input.flags_2468, 0x20) ~= 0 then
			release = true
		end
		if self.time > 1.5 then
			release = true
		end
		local force_blend = bit32.band(input.flags_2468, bit32.lshift(1, 21)) ~= 0
		if (not release and blend >= f32(0.05)) or force_blend then
			local frames = if self.kind == 3 then settings.coffin_blend_frames else 15.0
			if force_blend then
				self.active = false
				frames = 6.0
			end
			SkateboardOffset.refresh_height(offset, f32(displacement * blend), frames)
		else
			self.active = false
		end
		self.time = f32(self.time + STEP)
		self.previous_animation_height = animation_height
	end
	self.previous_com_velocity = input.physical_com_velocity_along_up
	self.previous_filtered_state = input.filtered_state
end

return skeleton_landing
