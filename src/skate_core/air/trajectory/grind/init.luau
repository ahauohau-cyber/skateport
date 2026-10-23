--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/grind.rs (коммит 2e16697)
--
-- Original S3 trajectory grind acquisition and typed retained selection.
-- ROBLOX: Option -> значение или nil; usize-индексы примитивов с нуля, как в Rust.

local rt = require("../../../rt")
local m = require("./math")
local grind_surface = require("./grind_surface")
local admission = require("@self/admission")
local candidate = require("@self/candidate")

local f32 = rt.f32
local from_bits = rt.from_bits

type Vector = m.Vector

local grind = {}

grind.admitted_displacement = admission.admitted_displacement
grind.apply_admitted_target = admission.apply_admitted_target
grind.descending_plane_time = candidate.descending_plane_time
grind.consider_grind_primitive = candidate.consider_grind_primitive
grind.take_best_grind = candidate.take_best_grind
grind.trajectory_box_filter = candidate.trajectory_box_filter
-- ROBLOX: pub fn в приватном модуле admission; открыт для сверки.
grind.landing_normal = admission.landing_normal

-- ROBLOX: crate::physics::grind_contact::Primitive { start, end, owner: u64 }.
export type Primitive = { start: Vector, ["end"]: Vector, owner: any }

export type GrindTrajectoryCandidate = candidate.GrindTrajectoryCandidate

export type GrindSurfaceEvidence = {
	kind: number,
	side: Vector,
}

export type GrindAssistLimits = {
	lock_distance: number,
	max_speed_squared_ledge: number,
	max_speed_squared_rail: number,
	max_downward_speed: number,
	ledge_scalars: { number }, -- [f32; 4]
	tip_scalar: number,
	maximum_adjust_angle: number,
	deck_dimensions: { number }, -- [f32; 2]
}

export type GrindTarget = {
	edge: Primitive,
	provider_index: number,
	primitive_flags: number,
	orientation: grind_surface.LandingOrientation,
	point: Vector,
	-- Selector2896, distinct from landing contact normal.
	vertical_normal: Vector,
}

local GrindTarget = {}
grind.GrindTarget = GrindTarget

-- ROBLOX: crate::physics::grind_air::Target — таблица с теми же полями
-- (grind_air не подключаем здесь, чтобы не было кругового require).
function GrindTarget.air_target(self: GrindTarget): { edge: Primitive, primitive_flags: number, orientation: grind_surface.LandingOrientation }
	return {
		edge = self.edge,
		primitive_flags = self.primitive_flags,
		orientation = self.orientation,
	}
end

export type GrindEvaluation = {
	target: GrindTarget?,
	score: number,
	distance: number,
	-- 9663/9664 can be written even when candidate admission fails.
	effective_lock_distance: number?,
	penalty_domain: number,
}

local GrindEvaluation = {}
grind.GrindEvaluation = GrindEvaluation

function GrindEvaluation.penalty_input(self: GrindEvaluation): number
	local distance = self.effective_lock_distance
	if distance ~= nil then
		local denominator = f32(distance + from_bits(0x3e19_999a))
		if denominator < self.penalty_domain then
			return f32(f32(self.penalty_domain / denominator) * self.distance)
		end
	end
	return self.distance
end

return grind
