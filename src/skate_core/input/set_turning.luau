--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/set_turning.rs (коммит 2e16697)
--
-- SetTurning enter 82BB3810 and update 82BB3830 at resolved component boundaries.
-- This is a reusable node operation; the loaded graph owns its activation.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local turn_remap = require("./turn_remap")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local evaluate = point_graph.PointGraph.evaluate
local apply = turn_remap.TurnRemap.apply

local set_turning = {}

local function b(v: boolean): number
	return if v then 1 else 0
end

-- One retained native slide record (SpecificMotionGraph 3204..3220).
-- Both SetTurning and authored slide handlers read and mutate this owner.
-- Reserved bits stay intact; reset 82595450..78 only clears the defined bits.
-- ROBLOX: words: [u32; 5] -> таблица, слово k лежит в [k + 1].
export type SlideLatch = { words: { number } }

local SlideLatch = {}
set_turning.SlideLatch = SlideLatch

function SlideLatch.default(): SlideLatch
	return { words = { 0, 0, 0, 0, 0 } }
end
-- ROBLOX: в Rust поле words приватное; конструктор для тестов и эталонов.
function SlideLatch.from_words(words: { number }): SlideLatch
	return { words = table.clone(words) }
end
function SlideLatch.captured_fakie(self: SlideLatch): boolean
	return bit32.band(self.words[5], 0x80000000) ~= 0
end
function SlideLatch.candidate_enabled(self: SlideLatch): boolean
	return bit32.band(self.words[5], 0x40000000) ~= 0
end
function SlideLatch.set_candidate_enabled(self: SlideLatch, enabled: boolean)
	self.words[5] = bit32.bor(bit32.band(self.words[5], bit32.bnot(0x40000000)), bit32.lshift(b(enabled), 30))
end
function SlideLatch.elapsed(self: SlideLatch, right: boolean): number
	return from_bits(self.words[if right then 3 else 1])
end
function SlideLatch.start(self: SlideLatch, right: boolean): boolean
	return bit32.band(self.words[if right then 4 else 2], 0x80000000) ~= 0
end
-- ROBLOX: "end" — ключевое слово Luau, метод объявлен через ["end"].
SlideLatch["end"] = function(self: SlideLatch, right: boolean): boolean
	return bit32.band(self.words[if right then 4 else 2], 0x40000000) ~= 0
end
function SlideLatch.set_start(self: SlideLatch, right: boolean, value: boolean)
	local i = if right then 4 else 2
	self.words[i] = bit32.bor(bit32.band(self.words[i], bit32.bnot(0x80000000)), bit32.lshift(b(value), 31))
end
function SlideLatch.set_end(self: SlideLatch, right: boolean, value: boolean)
	local i = if right then 4 else 2
	self.words[i] = bit32.bor(bit32.band(self.words[i], bit32.bnot(0x40000000)), bit32.lshift(b(value), 30))
end
function SlideLatch.advance_elapsed(self: SlideLatch, right: boolean, dt: number)
	local i = if right then 3 else 1
	self.words[i] = to_bits(f32(dt + from_bits(self.words[i])))
end
-- CreateSlide Begin 82BB2E88; do not clear start/end/grab/candidate flags.
function SlideLatch.begin_slide(self: SlideLatch, fakie: boolean)
	self.words[1] = 0
	self.words[3] = 0
	self.words[5] = bit32.bor(bit32.band(self.words[5], bit32.bnot(0x80000000)), bit32.lshift(b(fakie), 31))
end
-- GrabSlide 82BBB848 maps authored side through the captured stance.
function SlideLatch.grab(self: SlideLatch, authored_right: boolean)
	local right = authored_right ~= SlideLatch.captured_fakie(self)
	local i = if right then 4 else 2
	self.words[i] = bit32.bor(self.words[i], 0x20000000)
end
-- ShouldLeaveSlide 82BA7130 uses captured, not current, stance.
function SlideLatch.should_leave(self: SlideLatch, authored_right: boolean): boolean
	return SlideLatch["end"](self, authored_right ~= SlideLatch.captured_fakie(self))
end
function SlideLatch.reset(self: SlideLatch)
	self.words[1] = 0
	self.words[3] = 0
	self.words[2] = bit32.band(self.words[2], 0x1fffffff)
	self.words[4] = bit32.band(self.words[4], 0x1fffffff)
	self.words[5] = bit32.band(self.words[5], 0x3fffffff)
end

export type State = { elapsed: number, smoothed: number, mode: number }

local State = {}
set_turning.State = State

-- Native enter and allocator 82BB4138 use the same three initial values.
function State.enter(self: State)
	self.elapsed = 0.0
	self.smoothed = 0.0
	self.mode = 2
end

export type Settings = {
	-- Native helper mode 0 and mode 1, in that order.
	remaps: { turn_remap.TurnRemap },
	speed_tuck: point_graph.PointGraph,
	blend: point_graph.PointGraph,
	speed_threshold: number,
	maximum_delta: number,
	-- Global collection slot 332, layout 1680.
	override_turn: number,
}

-- Resolved physical output bundle+56 and bundle+4 inputs. Offset names avoid
-- assigning unverified meanings to upstream physical producer fields.
export type Physical = {
	field_32: number,
	field_36: number,
	field_52: number,
	field_56: number,
	field_60: number,
	body_168: number,
}

export type Intents = {
	fakie_turn: number?,
	-- Native keys 830C067C and 830C05F4, respectively.
	mode_0_slide: number?,
	mode_1_slide: number?,
}

-- Skeleton selectors bind to the decoded node parameter keys. Packet Turn and
-- Slide are native fixed attribute keys. Emissions occur in native call order.
-- ROBLOX: enum Attribute -> строки.
export type Attribute = "Angle" | "Direction" | "Quickness" | "Speed" | "Holding" | "Turn" | "Slide"

-- `latch` preserves all five words returned by motion graph virtual+64.
-- `stance` is the component's virtual+12 and virtual+28 result pair.
-- `dt` is the graph context clock virtual+40 result, not a guessed fixed tick.
-- ROBLOX: stance (bool, bool) -> { fakie, mirror }.
function set_turning.update(state: State, latch_: SlideLatch, physical: Physical, stance: { boolean }, dt: number, settings: Settings, intents: Intents, emit: (Attribute, number) -> ())
	local latch = latch_.words
	local a = apply(settings.remaps[1], { physical.field_32, physical.field_56 })
	local _ = apply(settings.remaps[1], { physical.field_36, physical.field_56 })
	local bb = apply(settings.remaps[2], { physical.field_32, physical.field_56 })
	local _ = apply(settings.remaps[2], { physical.field_36, physical.field_56 })
	local complement = f32(1.0 - physical.field_52)
	local target = -mul_add(a[1], physical.field_52, f32(bb[1] * complement))
	local direction = -mul_add(a[2], physical.field_52, f32(bb[2] * complement))
	local old_0 = latch[2]
	local old_1 = latch[4]
	latch[2] = bit32.band(latch[2], bit32.bnot(0x20000000))
	latch[4] = bit32.band(latch[4], bit32.bnot(0x20000000))
	local prior_0 = bit32.band(old_0, 0x20000000) ~= 0
	local prior_1 = bit32.band(old_1, 0x20000000) ~= 0
	local enabled = bit32.band(latch[5], 0x40000000) ~= 0
	local mode = state.mode
	if mode == 2 then
		local first = enabled and (bit32.band(latch[4], 0x80000000) ~= 0 or prior_1)
		local second = enabled and (bit32.band(latch[2], 0x80000000) ~= 0 or prior_0)
		if first or second then
			if not prior_0 and not prior_1 then
				latch[1] = 0
				latch[3] = 0
				latch[5] = bit32.bor(bit32.band(latch[5], 0x7fffffff), bit32.lshift(b(stance[1]), 31))
			end
			mode = if first then 1 else 0
		end
	elseif (mode == 1 and (not enabled or bit32.band(latch[4], 0x40000000) ~= 0)) or (mode == 0 and (not enabled or bit32.band(latch[2], 0x40000000) ~= 0)) then
		mode = 2
	end
	if mode <= 1 then
		target = if (mode == 1) ~= stance[2] then 1.0 else -1.0
		if bit32.band(latch[5], 0x80000000) ~= 0 then
			target = -target
		end
	end
	if mode ~= state.mode then
		state.elapsed = 0.0
	end
	state.mode = mode
	local blend = evaluate(settings.blend, state.elapsed)
	local lower = f32(state.smoothed - settings.maximum_delta)
	local upper = f32(state.smoothed + settings.maximum_delta)
	local value = mul_add(f32(1.0 - blend), state.smoothed, f32(blend * target))
	value = if f32(lower - value) >= 0.0 then lower else value
	state.elapsed = f32(state.elapsed + dt)
	state.smoothed = if f32(upper - value) >= 0.0 then value else upper
	local speed = math.abs(physical.body_168)
	local tuck = if speed > settings.speed_threshold then evaluate(settings.speed_tuck, f32(speed - settings.speed_threshold)) else 0.0
	emit("Angle", state.smoothed)
	emit("Direction", direction)
	emit("Quickness", physical.field_52)
	emit("Speed", tuck)
	emit("Holding", physical.field_60)
	if mode <= 1 then
		local flip = bit32.band(latch[5], 0x80000000) ~= 0
		local turn = if (mode == 1) ~= flip then settings.override_turn else -settings.override_turn
		emit("Turn", turn)
		local slide_opt = if mode == 0 then intents.mode_0_slide else intents.mode_1_slide
		local slide = if slide_opt ~= nil then slide_opt else 0.0
		if flip then
			local negative = -slide
			local absolute = math.abs(negative)
			local v = if absolute > 0.5 then f32(1.0 - absolute) else absolute
			slide = if negative >= 0.0 then v else -v
		end
		emit("Slide", slide)
	elseif intents.fakie_turn ~= nil then
		emit("Turn", intents.fakie_turn)
	end
end

return set_turning
