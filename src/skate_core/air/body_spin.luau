--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/body_spin.rs (коммит 2e16697)
--
-- Complete TU3 BodySpin::Update (82D8BF58) and history scan (82D8C2D8).
-- Cached curves are explicit inputs, not reconstructed from Skate 2 settings.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local PointGraph = point_graph.PointGraph

local body_spin = {}

-- Native bytes +0..176. Preserves the unused +136 word and mode-byte padding.
-- Construction/air-entry lifecycle belongs to the recovered caller, not Default.
-- ROBLOX: words: [u32; 44] -> таблица, слово k лежит в [k + 1].
export type BodySpinState = { words: { number } }

local BodySpinState = {}
body_spin.BodySpinState = BodySpinState

-- 82D8DA98..DAE0 initializes every BodySpin scalar and history entry.
function BodySpinState.new(): BodySpinState
	return { words = rt.zeros(44) }
end

function BodySpinState.from_words(words: { number }): BodySpinState
	assert(words[43] < 30, "native derivative history index must be 0..30")
	return { words = table.clone(words) }
end

function BodySpinState.words(self: BodySpinState): { number }
	return self.words
end

local function get(self: BodySpinState, offset: number): number
	return from_bits(self.words[offset // 4 + 1])
end

local function set(self: BodySpinState, offset: number, value: number)
	self.words[offset // 4 + 1] = to_bits(value)
end

-- +140, consumed by Reckoning::UpdateAirStates after BodySpin::Update.
function BodySpinState.speed(self: BodySpinState): number
	return get(self, 140)
end

-- ROBLOX: #[derive(Clone, PartialEq)].
function BodySpinState.clone(self: BodySpinState): BodySpinState
	return { words = table.clone(self.words) }
end
function BodySpinState.eq(a: BodySpinState, b: BodySpinState): boolean
	for i = 1, 44 do
		if a.words[i] ~= b.words[i] then
			return false
		end
	end
	return true
end

-- Native cached inputs at +176/+180, seven 80-byte curves, and 830BD300.
-- The vector threshold's producer must be supplied: no guessed retail default.
export type BodySpinSettings = {
	derivative_floor: number,
	acceleration_limit: number,
	-- Native +184, +264, +344, +424, +504, +584, +664; x/y at +16/+48.
	-- ROBLOX: [PointGraph<8>; 7], индексы с 1.
	curves: { point_graph.PointGraph },
	input_fade_threshold: { number },
}

local STEP = from_bits(0x3C88_8889) -- 820849C8, fixed in these functions.

local F32_0_1 = f32(0.1)
local F32_0_8 = f32(0.8)
local F32_0_2 = f32(0.2)
local F32_0_96 = f32(0.96)
local F32_0_02 = f32(0.02)

local function select(test: number, nonnegative: number, negative: number): number
	if test >= 0.0 then
		return nonnegative
	end
	return negative
end

local function native_clamp(value: number, lower: number, upper: number): number
	value = select(f32(lower - value), lower, value)
	return select(f32(upper - value), value, upper)
end

local function update_input(state: BodySpinState, input: number, auto_spin: number, mode: number)
	local delta = f32(input - get(state, 120))
	local derivative = mul_add(delta, 1.5, f32(get(state, 124) * 0.0))
	set(state, 164, auto_spin)
	set(state, 120, input)
	state.words[44] = bit32.bor(bit32.band(state.words[44], 0x00FF_FFFF), bit32.lshift(mode, 24))
	set(state, 124, derivative)
	local filtered = if f32(derivative * input) > F32_0_1 then derivative else 0.0
	filtered = native_clamp(filtered, -1.0, 1.0)
	set(state, 128, filtered)
	local index = state.words[43]
	set(state, index * 4, filtered)
	state.words[43] = (index + 1) % 30
end

local function finish_ground(state: BodySpinState, input: number)
	set(state, 152, 0.0)
	set(state, 144, 0.0)
	set(state, 140, 0.0)
	set(state, 132, mul_add(get(state, 132), F32_0_8, f32(input * F32_0_2)))
end

-- 82D8C2D8 scans the 29 entries before the current write position.
-- The newest entry starts at negative one native step, with strict peak ties.
local function calculate_history_derivative(state: BodySpinState, graph: point_graph.PointGraph)
	local end_ = state.words[43]
	local index = (end_ + 29) % 30
	local time = 0.0
	local peak = 0.0
	set(state, 148, 0.0)
	set(state, 156, 0.0)
	while index ~= end_ do
		time = f32(time - STEP)
		local candidate = f32(PointGraph.evaluate(graph, time) * get(state, index * 4))
		if math.abs(candidate) > math.abs(peak) then
			peak = candidate
			set(state, 156, time)
		end
		index = (index + 29) % 30
	end
	set(state, 148, peak)
end

local function update_air(state: BodySpinState, settings: BodySpinSettings, input: number, auto_spin: number, mode: number)
	-- ROBLOX: индексы кривых с 1: curves[k] в Rust -> curves[k + 1].
	local alternate = if mode == 0 then 1 else 0
	local curves = settings.curves
	if get(state, 152) == 0.0 then
		calculate_history_derivative(state, curves[3 + alternate + 1])
	end
	local time = get(state, 152)
	local normal_acceleration = PointGraph.evaluate(curves[alternate + 1], time)
	local auto_acceleration = PointGraph.evaluate(curves[3], time)
	local derivative_gain = PointGraph.evaluate(curves[3 + alternate + 1], time)
	local candidate = f32(derivative_gain * get(state, 128))
	if math.abs(candidate) > math.abs(get(state, 148)) then
		set(state, 148, candidate)
		set(state, 156, time)
	end
	local next_time = f32(time + STEP)
	set(state, 152, next_time)
	-- vcmpgtfp128. followed by CR6 all-lanes test, not a scalar dead zone.
	local all = true
	local current = math.abs(get(state, 120))
	for _, v in settings.input_fade_threshold do
		if not (v > current) then
			all = false
			break
		end
	end
	if all then
		local faded = f32(get(state, 132) * F32_0_96)
		set(state, 132, faded)
		set(state, 120, faded)
	else
		set(state, 132, mul_add(get(state, 132), F32_0_8, f32(input * F32_0_2)))
	end
	local proportional = f32(PointGraph.evaluate(curves[5 + alternate + 1], next_time) * get(state, 120))
	set(state, 144, proportional)
	if f32(proportional * get(state, 148)) < 0.0 then
		set(state, 148, 0.0)
	end
	local weight = mul_add(math.abs(get(state, 148)), f32(1.0 - settings.derivative_floor), settings.derivative_floor)
	local target = -f32(weight * proportional)
	local acceleration = normal_acceleration
	local old_speed = get(state, 140)
	if math.abs(auto_spin) > from_bits(0x3780_0000) and (f32(old_speed * auto_spin) > 0.0 or math.abs(old_speed) < F32_0_02) then
		acceleration = auto_acceleration
		target = native_clamp(auto_spin, -2.0, 2.0)
	end
	local limited = select(f32(settings.acceleration_limit - acceleration), acceleration, settings.acceleration_limit)
	local lower, upper
	if old_speed > 0.0 then
		lower, upper = -limited, acceleration
	else
		lower, upper = -acceleration, limited
	end
	local change = native_clamp(f32(target - old_speed), lower, upper)
	local speed = f32(old_speed + change)
	set(state, 140, speed)
	-- Both subtractions are present at 82D8C27C..284.
	set(state, 160, f32(f32(target - speed) - change))
end

-- Registers f1/f2/r6/r7, including the native mode-byte publication.
-- pub fn update(state, settings, input, auto_spin, in_air, mode: u8)
function body_spin.update(
	state: BodySpinState,
	settings: BodySpinSettings,
	input: number,
	auto_spin: number,
	in_air: boolean,
	mode: number
)
	update_input(state, input, auto_spin, mode)
	if not in_air then
		finish_ground(state, input)
		return
	end
	update_air(state, settings, input, auto_spin, mode)
end

-- Ground caller82D8C8F0 supplies auto_spin=0, in_air=false and mode=0.
-- This branch does not read any of the airborne BodySpin tuning curves.
function body_spin.update_ground(state: BodySpinState, input: number)
	update_input(state, input, 0.0, 0)
	finish_ground(state, input)
end

return body_spin
