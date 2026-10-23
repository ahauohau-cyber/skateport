--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_output/wobble.rs (коммит 2e16697)
--
-- SkateboardWobble constructor82BF2E48, trigger82BF2F18, update82BF2FB8.

local rt = require("../../../rt")
local point_graph = require("../../point_graph")
local sar = require("../skeleton_animation_record")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph

local wobble = {}

export type Settings = {
	takeoff_tilt: point_graph.PointGraph,
	landing_tilt: point_graph.PointGraph,
	takeoff_squish: point_graph.PointGraph,
	landing_squish: point_graph.PointGraph,
	maximum_time: number,
}

-- ROBLOX: selected_landing_curves в Rust приватное поле.
export type Wobble = {
	active: boolean,
	landing: boolean,
	time: number,
	amplitude: number,
	direction: number,
	selected_landing_curves: boolean,
}

local Wobble = {}
wobble.Wobble = Wobble

-- ROBLOX: impl Default.
function Wobble.default(): Wobble
	--Constructor copies landing curves while initializing type17=false.
	return {
		active = false,
		landing = false,
		time = 0.0,
		amplitude = 0.0,
		direction = 1.0,
		selected_landing_curves = true,
	}
end

export type Output = {
	--Native out0 reports whether this update evaluated the effect, including
	--the final sample whose clock expires it. Return value is active AFTER.
	sampled: boolean,
	tilt: number,
	squish: number,
	remains_active: boolean,
}

local function default_output(): Output
	return { sampled = false, tilt = 0.0, squish = 0.0, remains_active = false }
end
wobble.Output = { default = default_output }

function Wobble.trigger(self: Wobble, landing: boolean, reverse: boolean)
	self.selected_landing_curves = landing
	self.landing = landing
	self.active = true
	self.time = 0.0
	self.amplitude = 1.0
	self.direction = if reverse then -1.0 else 1.0
end

function Wobble.update(self: Wobble, settings: Settings): Output
	if not self.active then
		return default_output()
	end
	local tilt_graph, squish_graph
	if self.selected_landing_curves then
		tilt_graph, squish_graph = settings.landing_tilt, settings.landing_squish
	else
		tilt_graph, squish_graph = settings.takeoff_tilt, settings.takeoff_squish
	end
	local squish = f32(PointGraph.evaluate(squish_graph, self.time) * self.amplitude)
	local tilt = f32(f32(PointGraph.evaluate(tilt_graph, self.time) * self.direction) * self.amplitude)
	self.time = f32(self.time + from_bits(0x3C88_8889))
	if self.time > settings.maximum_time then
		self.active = false
		self.time = 0.0
	end
	return { sampled = true, tilt = tilt, squish = squish, remains_active = self.active }
end

-- /// PostWipeoutCheck82BD857C..86D4 modifies the observed board record only.
-- ///This wobble is not a force or a SetPartTransform on the simulated deck.
-- ROBLOX: board: &mut -> ячейка { value }.
function wobble.apply(output: Output, board: { value: sar.AnimationPartTransform })
	if not output.sampled then
		return
	end
	local sine, cosine = trigonometry.sin_cos(output.tilt)
	--822FB890 permute and vrlimi mask2 retain the native packed W lanes.
	local rotation = {
		{ cosine, sine, 0.0, cosine },
		{ -sine, cosine, 0.0, -sine },
		{ 0.0, 0.0, 1.0, 0.0 },
		{ 0.0, 0.0, 0.0, 0.0 },
	}
	local b = sar.compose_affine(board.value, rotation)
	for lane = 1, 4 do
		b[4][lane] = mul_add(b[2][lane], output.squish, b[4][lane])
	end
	board.value = b
end

return wobble
