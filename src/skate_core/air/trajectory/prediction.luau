--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/prediction.rs (коммит 2e16697)
--
-- tTrajectory and complete PredictionResults8276C9D8/8276DBE0.
-- ROBLOX: Copy-структуры -> таблицы; *.clone даёт независимую копию.

local rt = require("../../../rt")
local m = require("./math")

local f32 = rt.f32
local mul_add = rt.mul_add

type Vector = m.Vector
type Transform = m.Transform

local prediction = {}

export type Trajectory = {
	position: Vector, -- 0 metres
	velocity: Vector, -- 16 metres/second
	acceleration: Vector, -- 32 metres/second squared
	duration: number, -- 48 seconds; -1 means unbounded
}

local Trajectory = {}
prediction.Trajectory = Trajectory

function Trajectory.clone(self: Trajectory): Trajectory
	return table.clone(self)
end

function Trajectory.position_at(self: Trajectory, time: number): Vector
	local square = f32(time * time)
	local out = table.create(4) :: any
	for i = 1, 4 do
		out[i] = mul_add(f32(self.acceleration[i] * 0.5), square, mul_add(self.velocity[i], time, self.position[i]))
	end
	return out
end
function Trajectory.velocity_at(self: Trajectory, time: number): Vector
	local out = table.create(4) :: any
	for i = 1, 4 do
		out[i] = mul_add(self.acceleration[i], time, self.velocity[i])
	end
	return out
end
-- ROBLOX: кортеж (Vector, f32) -> два возвращаемых значения.
function Trajectory.highest_position(self: Trajectory): (Vector, number)
	-- 82D2CCA0: downward velocity or nonnegative gravity has no apex.
	if self.velocity[2] < 0.0 or self.acceleration[2] >= 0.0 then
		return self.position, 0.0
	end
	local t = f32(self.velocity[2] * m.reciprocal(-self.acceleration[2]))
	return Trajectory.position_at(self, t), t
end

export type QueryRequest = {
	trajectory: Trajectory, -- request144..207
	radius: number, -- 208 metres
	start_error: number, -- 212 multiplier of radius
	end_error: number, -- 216 multiplier of radius
}

local QueryRequest = {}
prediction.QueryRequest = QueryRequest

function QueryRequest.clone(self: QueryRequest): QueryRequest
	local c = table.clone(self)
	c.trajectory = Trajectory.clone(self.trajectory)
	return c
end

export type QueryResult = {
	contact_position: Vector, -- 0
	contact_normal: Vector, -- 16 first hit face normal
	landing_normal: Vector, -- 32 velocity-qualified nearby-face average
	contact_time: number, -- 48 seconds; -1 is no contact
	contact_transform: Transform, -- 64 static world identity
	contact_frame: number, -- 128
	surface: number, -- 132 original surface data
	geometry: number, -- 136 host geometry identity
}

local QueryResult = {}
prediction.QueryResult = QueryResult

function QueryResult.clone(self: QueryResult): QueryResult
	return table.clone(self)
end

function QueryResult.miss(): QueryResult
	return {
		contact_position = m.zero(),
		contact_normal = m.up(),
		landing_normal = m.up(),
		contact_time = -1.0,
		contact_transform = m.identity(),
		contact_frame = -1,
		surface = 0,
		geometry = 0,
	}
end
function QueryResult.valid(self: QueryResult): boolean
	return self.contact_time >= 0.0
end
-- PredictionResults::GetLandingNormal82D2D9E8.
function QueryResult.suggested_normal(self: QueryResult): Vector
	if QueryResult.valid(self) then
		return self.landing_normal
	end
	return m.up()
end

export type Prediction = {
	result: QueryResult,
	request: QueryRequest,
}

local Prediction = {}
prediction.Prediction = Prediction

function Prediction.clone(self: Prediction): Prediction
	return { result = QueryResult.clone(self.result), request = QueryRequest.clone(self.request) }
end

function Prediction.collision_position(self: Prediction): Vector
	return Trajectory.position_at(self.request.trajectory, self.result.contact_time)
end
function Prediction.collision_velocity(self: Prediction): Vector
	return Trajectory.velocity_at(self.request.trajectory, f32(self.result.contact_frame * m.STEP))
end

return prediction
