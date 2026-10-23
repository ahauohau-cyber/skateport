--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/manual/state.rs (коммит 2e16697)
--
-- The five board-owned persistent fields used by CalcManualEffect.

local rt = require("../../../rt")

local f32 = rt.f32

local state = {}

export type ManualState = {
	-- Board+264: 0.95/0.05 filtered clamped angle error.
	filtered_angle_error: number,
	-- Board+268: normalized requested angle for this tick.
	target_angle: number,
	-- Board+272: normalized measured deck angle, retained for the next derivative.
	measured_angle: number,
	-- Board+276: accumulated controller output, scaled to angular displacement.
	angular_correction: number,
	-- Board+280: zero also identifies the first active controller tick.
	elapsed: number,
}

-- Explicit dependency returned by the entry-state slice, never a no-op
-- replacement for Ground's call to RemoveVelIntoGroundForManual 82D37960.
-- ROBLOX: enum ManualEntryContinuation -> строки.
state.ManualEntryContinuation = { Continue = "Continue", RemoveVelocityIntoGround = "RemoveVelocityIntoGround" }

local ManualState = {}
state.ManualState = ManualState

function ManualState.new(): ManualState
	return { filtered_angle_error = 0.0, target_angle = 0.0, measured_angle = 0.0, angular_correction = 0.0, elapsed = 0.0 }
end

-- 82C04EEC..4EFC when ProcessedPhysIn+2720 equals either signed zero.
-- This resets only these five controller fields, not heading state+284.
function ManualState.reset(self: ManualState)
	self.filtered_angle_error = 0.0
	self.target_angle = 0.0
	self.measured_angle = 0.0
	self.elapsed = 0.0
	self.angular_correction = 0.0
end

-- Manual-state slice of Ground Enter 82D376F4..7750. The caller still
-- owns all other entry work, including the returned velocity operation.
-- `previous_category` is ProcessedPhysIn+2516; 100 is the ground category.
function ManualState.enter_ground(self: ManualState, previous_category: number, powerslide_exit_scale: number): string
	if previous_category == 100 then
		-- +268 target, +272 measurement and +280 timer are preserved.
		self.angular_correction = f32(self.angular_correction * powerslide_exit_scale)
		self.filtered_angle_error = f32(self.filtered_angle_error * powerslide_exit_scale)
		return state.ManualEntryContinuation.Continue
	end
	-- Ground's inline reset82D3770C..771C writes +276 before +280.
	self.filtered_angle_error = 0.0
	self.target_angle = 0.0
	self.measured_angle = 0.0
	self.angular_correction = 0.0
	self.elapsed = 0.0
	return state.ManualEntryContinuation.RemoveVelocityIntoGround
end

return state
