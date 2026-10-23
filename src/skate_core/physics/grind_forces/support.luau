--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces/support.rs (коммит 2e16697)
--
-- Common force leaves82D40080/82D3FFC0/82D40130/82D401F8.
-- These consume manager output; they do not duplicate its assistance update.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local point_graph = require("../../point_graph")

local f32 = rt.f32
local dot3 = native_arithmetic.dot3
local evaluate = point_graph.PointGraph.evaluate

type V = { number }

local support = {}

local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end

function support.pin(normal: V, gravity_relief: number): V?
	if not (gravity_relief > 0.0) then
		return nil
	end
	local force = scale(normal, -40.0)
	force[2] = 0.0
	return force
end

function support.coping(upmost: V, velocity: V, gravity_relief: number): V?
	if gravity_relief > 0.0 and dot3(upmost, velocity) < 0.0 then
		return { 0.0, 120.0, 0.0, 0.0 }
	end
	return nil
end

function support.exit_lean(high_side: V, angle_1500: number, graph: point_graph.PointGraph): V?
	if angle_1500 > 0.0 then
		return scale(high_side, f32(evaluate(graph, angle_1500) * -65.0))
	end
	return nil
end

-- Unlike conditional pin/coping, original always calls AddForce, even at0.
function support.truck_compensation(normal: V, pitch_1508: number): V
	return scale(normal, f32(math.abs(pitch_1508) * -600.0))
end

return support
