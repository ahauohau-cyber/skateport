--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/air_leg_extension.rs (коммит 2e16697)
--
-- ControlAirLegExtension 82BAF538 and its ascending/descending/preland helpers.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local native_arithmetic = require("../physics/native_arithmetic")
local attributes = require("./output/attributes")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3

local air_leg_extension = {}

-- ROBLOX: enum Bone -> строки.
export type Bone = "Board" | "LeftToe" | "RightToe"

export type Settings = {
	going_up_speed: number,
	going_down_speed: number,
	minimum_height: number,
	preland_velocity: number,
	preland_final_height: number,
	offboard_multiplier: number,
	arm_extension: point_graph.PointGraph,
}

-- All vectors are preceding completed physical output in stock coordinates.
export type Physical = {
	com_velocity: { number },
	com_position: { number },
	system_up: { number },
	right_toe: { number },
	left_toe: { number },
	animation_height: number,
	offboard_316: boolean,
	remaining_air_time: number,
}

-- CreateInstance 82BAF980 zeros mode 8, distance 12 and descending_time 16.
export type State = { mode: number, height: number, descending_time: number }

local State = {}
air_leg_extension.State = State

function State.default(): State
	return { mode = 0, height = 0.0, descending_time = 0.0 }
end

local function maximum(a: number, b: number): number
	return if f32(a - b) >= 0.0 then a else b
end
local function minimum(a: number, b: number): number
	return if f32(b - a) >= 0.0 then a else b
end

function State.needs_initial_attribute(self: State): boolean
	return self.mode == 0
end

function State.needs_prelanding_query(self: State, p: Physical): boolean
	return self.mode == 2 or (self.mode == 1 and p.com_velocity[2] < 0.0)
end

local function preland(self: State, bone: Bone, settings: Settings, dt: number)
	self.height = mul_add(dt, settings.preland_velocity, self.height)
	if bone ~= "Board" then
		self.height = f32(self.height * settings.offboard_multiplier)
	end
end

local function scalar(attribute: attributes.AnimationAttribute): number
	local word = attribute.payload[1]
	return from_bits(if word == false then 0 else word :: number)
end

-- The first update seeds the height but does not also advance its new mode.
-- ROBLOX: возвращает [f32; 2] -> { высота, разгиб рук }.
function State.update(self: State, bone: Bone, p: Physical, settings: Settings, dt: number, initial_attribute: attributes.AnimationAttribute?, prepare_to_land: boolean): { number }
	local ascending = p.com_velocity[2] > 0.0
	local mode = self.mode
	if mode == 0 then
		self.mode = if ascending then 1 else 2
		if initial_attribute ~= nil then
			if initial_attribute.kind == 0 then
				-- The queried union is initialized to zero before GetLastAttr.
				self.height = scalar(initial_attribute)
			end
		else
			local toe = nil
			if p.offboard_316 or bone == "RightToe" then
				toe = p.right_toe
			elseif bone == "LeftToe" then
				toe = p.left_toe
			end
			if toe ~= nil then
				local d = {}
				for i = 1, 4 do
					d[i] = f32(p.com_position[i] - toe[i])
				end
				self.height = dot3(d, p.system_up)
			else
				self.height = p.animation_height
			end
		end
	elseif mode == 1 and p.com_velocity[2] >= 0.0 then
		-- 82BAFB60 is FNMSUBS, followed by FSEL against minimum 1756.
		self.height = maximum(mul_add(-dt, settings.going_up_speed, self.height), settings.minimum_height)
	elseif mode == 1 or mode == 2 then
		self.mode = 2
		if prepare_to_land then
			self.mode = 3
			preland(self, bone, settings, dt)
		else
			-- 82BAFC88..FD0C: both dot products precede the fused blend.
			local closing = -dot3(p.com_velocity, p.system_up)
			local vertical = math.abs(dot3(p.system_up, { 0.0, 1.0, 0.0, 0.0 }))
			local speed = mul_add(maximum(closing, 0.0), vertical, f32(f32(1.0 - vertical) * settings.going_down_speed))
			speed = minimum(speed, settings.going_down_speed)
			self.height = maximum(mul_add(-speed, dt, self.height), settings.minimum_height)
		end
	elseif mode == 3 then
		preland(self, bone, settings, dt)
	end
	self.descending_time = if ascending then 0.0 else f32(self.descending_time + dt)
	return { self.height, point_graph.PointGraph.evaluate(settings.arm_extension, self.descending_time) }
end

local K_3dcccccd = from_bits(0x3dcccccd)
local K_3d75c28f = from_bits(0x3d75c28f)

-- 82BAFDB8 checks the named FullExtension attribute after the physical query.
function air_leg_extension.prepare_to_land(physical_query: boolean, full_extension: attributes.AnimationAttribute?, p: Physical, s: Settings): boolean
	if not physical_query then
		return false
	end
	if full_extension == nil then
		return true
	end
	-- GetLastAttr's scalar output remains initialized zero for nonfloat records.
	local extension = if full_extension.kind == 0 then scalar(full_extension) else 0.0
	if extension < f32(s.preland_final_height - K_3dcccccd) then
		return true
	end
	local required_time = f32(f32(extension - p.animation_height) / s.preland_velocity)
	return f32(p.remaining_air_time - K_3d75c28f) < required_time
end

return air_leg_extension
