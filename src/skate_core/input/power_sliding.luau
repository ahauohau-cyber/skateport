--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/power_sliding.rs (коммит 2e16697)
--
-- Complete PowerSliding update 82BB28E8 at resolved graph/component boundaries.
-- Registration 82F89300; factory 82BC9060; vtable 82320328.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local native_arithmetic = require("../physics/native_arithmetic")
local angle_mod = require("./angle")
local controller = require("./controller")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local evaluate = point_graph.PointGraph.evaluate

local power_sliding = {}

export type State = { elapsed: number, previous_right: number, previous_left: number, flags: number }

export type Settings = {
	-- Global slot 332 layout 1684 and 1632.
	minimum_speed: number,
	minimum_slide_time: number,
	-- Graph4 layouts x1408/y1424, x1360/y1376, x1456/y1472.
	stop_time: point_graph.PointGraph,
	speed_response: point_graph.PointGraph,
	angle_response: point_graph.PointGraph,
}

export type Input = {
	-- PhysOut64->0 and PhysOut4->164.
	category: number,
	speed: number,
	right_slide: number?,
	left_slide: number?,
	-- Results of 82454FD8 for keys 830BE528 and 830C0818.
	right_query: boolean,
	left_query: boolean,
	-- MotionGraph interface virtual 224, 82595930.
	graph_scalar: number,
}

-- ROBLOX: fn bit(word: &mut u32, ..) -> возвращает новое слово.
local function bit(word: number, mask: number, value: boolean): number
	return bit32.bor(bit32.band(word, bit32.bnot(mask)), if value then mask else 0)
end

-- 82595930 arithmetic.
-- Inputs are PhysOut4->vector 80,
-- PhysOut32->basis row 32 and PhysOut4->byte 273. None means absent Physical.
-- ROBLOX: Option<([f32; 4], [f32; 4], u8)> -> { velocity, basis, flipped } или nil.
function power_sliding.alignment(input: { any }?): number
	if input == nil then
		return 1.0
	end
	local velocity: { number }, basis: { number }, flipped: number = input[1], input[2], input[3]
	local dot = native_arithmetic.dot3
	local squared = dot(velocity, velocity)
	if not (squared > from_bits(0x3a83126f)) then
		return 1.0
	end
	local length = controller.magnitude(squared)
	local reciprocal = angle_mod.reciprocal_estimate(length)
	for _ = 1, 2 do
		reciprocal = mul_add(reciprocal, mul_add(-reciprocal, length, 1.0), reciprocal)
	end
	local v = {}
	for i = 1, 4 do
		v[i] = f32(reciprocal * velocity[i])
	end
	local bs = basis
	if flipped ~= 0 then
		bs = {}
		for i = 1, 4 do
			bs[i] = -basis[i]
		end
	end
	return dot(v, bs)
end

-- Clock calls preserve the conditional first query and two subsequent timer
-- queries. The native context obtains each through its clock virtual 40.
-- ROBLOX: latch: &mut [u32; 5] -> таблица, слово k лежит в [k + 1].
function power_sliding.update(state: State, latch: { number }, input: Input, settings: Settings, clock: () -> number)
	local right = if input.right_slide ~= nil then input.right_slide else 0.0
	local left = if input.left_slide ~= nil then input.left_slide else 0.0
	local active = input.category == 1
	if active and bit32.band(state.flags, 0x20000000) == 0 then
		state.elapsed = 0.0
		state.previous_right = right
		state.previous_left = left
		state.flags = bit32.band(state.flags, 0x3fffffff)
	end
	state.flags = bit(state.flags, 0x20000000, active)
	if not active then
		return
	end
	local fast = input.speed > settings.minimum_speed
	local start_right = fast and input.right_query and bit32.band(state.flags, 0x80000000) == 0 and state.previous_right < right
	latch[4] = bit(latch[4], 0x80000000, start_right)
	state.previous_right = right
	state.flags = bit(state.flags, 0x80000000, input.right_query)
	local start_left = fast and input.left_query and bit32.band(state.flags, 0x40000000) == 0 and state.previous_left > left
	latch[2] = bit(latch[2], 0x80000000, start_left)
	state.previous_left = left
	state.flags = bit(state.flags, 0x40000000, input.left_query)
	local stop_time = evaluate(settings.stop_time, input.graph_scalar)
	local response = f32(evaluate(settings.speed_response, input.speed) * f32(1.0 - math.abs(input.graph_scalar)))
	local threshold = evaluate(settings.angle_response, input.graph_scalar)
	state.elapsed = if response < threshold then f32(state.elapsed + clock()) else 0.0
	local stop = state.elapsed > stop_time
	local right_time = f32(clock() + from_bits(latch[3]))
	latch[3] = to_bits(right_time)
	local left_time = f32(clock() + from_bits(latch[1]))
	latch[1] = to_bits(left_time)
	local exit_right = right_time > settings.minimum_slide_time and (input.right_slide == nil or not fast or stop)
	local exit_left = left_time > settings.minimum_slide_time and (input.left_slide == nil or not fast or stop)
	latch[4] = bit(latch[4], 0x40000000, exit_right)
	latch[2] = bit(latch[2], 0x40000000, exit_left)
end

return power_sliding
