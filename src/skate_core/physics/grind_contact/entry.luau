--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact/entry.rs (коммит 2e16697)
--
-- TU3 82D86F00 airborne entry and 82D872B8 impact admission.
-- The caller retains this result until Grind::PreUpdate82D40AF8 consumes it.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local arithmetic = require("./arithmetic")
local admission = require("./admission")
local point_graph = require("../../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local dot3 = native_arithmetic.dot3
local evaluate = point_graph.PointGraph.evaluate
local engagement_slope_sine = admission.engagement_slope_sine

type V = { number }

local entry = {}

export type Input = {
	valid: boolean,
	kind: number,
	category: number,
	previous_state_2504: number,
	speed: number,
	balance_2720: number,
	direction: V,
	normal: V,
	up: V,
	board_velocity: V,
	air_velocity: V,
	surface_kind: number,
	high_side: V,
	-- physics_grinds/VertEngagementHelpVsVelY, X144/Y160.
	vertical_help: point_graph.PointGraph,
	-- Stock wipeout collection layout256, checked by82D872B8.
	max_delta: number,
	flags: number,
	previous_entry_velocity: V,
}

export type Output = {
	valid: boolean,
	flags: number,
	entry_velocity: V,
	impact_speed: number,
	-- Wipeout reason offsets minus20. Each request also sets input2468 bit18.
	wipeout_reasons: { number },
}

export type Engagement = { tipslide_frames: number }

local Engagement = {}
entry.Engagement = Engagement

-- ROBLOX: #[derive(Default)].
function Engagement.default(): Engagement
	return { tipslide_frames = 0 }
end

local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		0.0,
	}
end

function entry.grounded_velocity(kind: number, direction: V, velocity: V, balance: number, speed: number, vertical_help: point_graph.PointGraph): V
	local base
	if kind == 1 then
		base = f32(0.1)
	elseif (kind == 2 or kind == 4) and balance ~= 0.0 and speed < f32(1.45) then
		base = 1.0
	elseif kind == 2 then
		base = f32(0.4)
	elseif kind == 0 or kind == 3 or kind == 4 or kind == 5 then
		base = f32(0.2)
	else
		base = 0.0
	end
	local help = evaluate(vertical_help, engagement_slope_sine(direction, velocity))
	local amount = mul_add(help, f32(1.0 - base), base)
	-- Native fsel on (1-amount), including unordered selecting1.
	amount = if f32(1.0 - amount) >= 0.0 then amount else 1.0
	local along = dot3(velocity, direction)
	local out = table.create(4) :: any
	for i = 1, 4 do
		out[i] = mul_add(f32(direction[i] * along), amount, f32(velocity[i] * f32(1.0 - amount)))
	end
	return out
end

function entry.airborne_velocity(kind: number, direction: V, normal: V, velocity: V): V
	local across = cross(normal, direction)
	local d = dot3(velocity, across)
	local removed = { f32(across[1] * d), f32(across[2] * d), f32(across[3] * d), f32(across[4] * d) }
	local amount
	if kind == 0 or kind == 3 then
		amount = f32(0.4)
	elseif kind == 1 or kind == 5 then
		amount = f32(0.2)
	elseif kind == 2 or kind == 4 then
		amount = f32(0.8)
	else
		amount = 0.0
	end
	local out = table.create(4) :: any
	for i = 1, 4 do
		out[i] = mul_add(f32(velocity[i] - removed[i]), amount, f32(velocity[i] * f32(1.0 - amount)))
	end
	return out
end

-- 82D86DE8: retain flags/velocity when invalid; reset impact every update.
function Engagement.update(self: Engagement, input: Input): Output
	if
		input.valid
		and input.kind == 2
		and (input.previous_state_2504 == 701 or input.previous_state_2504 == 403)
		and input.speed > f32(1.8)
	then
		self.tipslide_frames = 8
	else
		-- ROBLOX: u32::wrapping_sub(1), затем (next as i32) < 0 -> 0.
		local next = rt.wrapping_sub_u32(self.tipslide_frames, 1)
		self.tipslide_frames = if rt.to_i32(next) < 0 then 0 else next
	end
	local out: Output = {
		valid = input.valid,
		flags = bit32.bor(bit32.band(input.flags, bit32.bnot(0x0200_0000)), if self.tipslide_frames > 0 then 0x0200_0000 else 0),
		entry_velocity = input.previous_entry_velocity,
		impact_speed = 0.0,
		wipeout_reasons = {},
	}
	if not out.valid then
		return out
	end
	out.flags = bit32.band(out.flags, bit32.bnot(0x4000_0000))
	if not (input.category == 100 or input.category == 200) then
		return out
	end
	if math.abs(dot3(input.up, input.direction)) > 0.5 then
		out.valid = false
		if input.category == 200 then
			table.insert(out.wipeout_reasons, 13)
		end
		return out
	end
	out.flags = bit32.bor(out.flags, 0x4000_0000)
	local initial = if input.category == 100 then input.board_velocity else input.air_velocity
	if input.category == 100 then
		out.entry_velocity = entry.grounded_velocity(input.kind, input.direction, input.board_velocity, input.balance_2720, input.speed, input.vertical_help)
	else
		out.entry_velocity = entry.airborne_velocity(input.kind, input.direction, input.normal, input.air_velocity)
	end
	local delta = {}
	for i = 1, 4 do
		delta[i] = f32(out.entry_velocity[i] - initial[i])
	end
	out.impact_speed = arithmetic.square_root(dot3(delta, delta))
	-- MeasureEngagement runs for BOTH ground and air accepted entries.
	if out.impact_speed > input.max_delta then
		table.insert(out.wipeout_reasons, 9)
	end
	local along = dot3(input.board_velocity, input.direction)
	local transverse = {}
	for i = 1, 4 do
		transverse[i] = f32(f32(input.direction[i] * along) - input.board_velocity[i])
	end
	transverse[2] = 0.0
	if dot3(transverse, transverse) > 49.0 and (input.surface_kind == 0 or dot3(input.board_velocity, input.high_side) > 0.0) then
		table.insert(out.wipeout_reasons, 14)
	end
	if #out.wipeout_reasons > 0 then
		out.valid = false
	end
	return out
end

-- Native reason indices: byte33 steep entry,29 excessive correction,34
-- excessive horizontal impact. Retain both impact requests when both fire.
function entry.airborne_rejections(
	direction: V,
	up: V,
	board_velocity: V,
	air_velocity: V,
	corrected: V,
	surface_kind: number,
	surface_side: V,
	max_delta: number
): { number }
	if math.abs(dot3(up, direction)) > 0.5 then
		return { 13 }
	end
	local delta = {}
	for i = 1, 4 do
		delta[i] = f32(corrected[i] - air_velocity[i])
	end
	local reasons = {}
	if arithmetic.square_root(dot3(delta, delta)) > max_delta then
		table.insert(reasons, 9)
	end
	local along = dot3(board_velocity, direction)
	local transverse = {}
	for i = 1, 4 do
		transverse[i] = f32(f32(direction[i] * along) - board_velocity[i])
	end
	transverse[2] = 0.0
	if dot3(transverse, transverse) > 49.0 and (surface_kind == 0 or dot3(board_velocity, surface_side) > 0.0) then
		table.insert(reasons, 14)
	end
	return reasons
end

return entry
