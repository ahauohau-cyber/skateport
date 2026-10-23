--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/jump_velocity.rs (коммит 2e16697)
--
-- TU3 PhysicsAir jump-velocity correction (`0x82D34BC0`).
-- ROBLOX: trait PhysicsAirMath -> тип таблицы с методами (вызов через двоеточие).

local rt = require("../../../rt")
local data = require("./data")

local f32 = rt.f32
local from_bits = rt.from_bits

type Vector4 = data.Vector4

local jump_velocity = {}

local VERTICAL_ERROR_FLOOR = from_bits(0xC040_0000) -- -3.0
local HORIZONTAL_ERROR_LIMIT_SQUARED = from_bits(0x4110_0000) -- 9.0

-- Numerical operations used by the recovered formula. The PC adapter uses
-- independently implemented arithmetic and the original refinement steps;
-- agreement with every Xenon floating-point edge case is not established.
export type PhysicsAirMath = {
	-- Native `vminfp128`, used by the OffBoard air-entry velocity cap.
	minimum_vminfp: (self: any, left: number, right: number) -> number,
	-- Native `vmsum3fp128(value, value)`; only lane zero is consumed.
	length_squared_vmsum3fp: (self: any, value: Vector4) -> number,
	-- The native vmsum/vrsqrte/two-refinement sequence at 82D34D10..68.
	length_vmsum3fp_vrsqrte: (self: any, value: Vector4) -> number,
	-- `PhysicsUtility::ClampVectorWithinMaxLength`, `0x82BD3D90`.
	clamp_vector_within_max_length: (self: any, value: Vector4, maximum_length: number) -> Vector4,
}

-- Reconstructs the full branch contract and arithmetic order of `0x82D34BC0`.
-- The frame count is signed in the caller and in the target's `extsw/fcfid`.
function jump_velocity.calculate_velocity_from_jump(frame: data.PhysicsAirFrame, frames: number, math_: any): Vector4
	local frame_seconds = f32(frame.delta_time_2604 * f32(frames))
	local gravity_delta = f32(frame_seconds * frame.gravity_y_2648)
	local j = frame.jump_velocity_848
	local predicted = { f32(j[1] + 0.0), f32(j[2] + gravity_delta), f32(j[3] + 0.0), f32(j[4] + 0.0) }

	local current = frame.current_velocity_400
	local err = {}
	for lane = 1, 4 do
		err[lane] = f32(current[lane] - predicted[lane])
	end
	local output = table.clone(predicted)

	-- `vcmpgtfp(error.y, -3.0)`: false, including equality/unordered, selects
	-- the current vertical velocity.
	if not (err[2] > VERTICAL_ERROR_FLOOR) then
		output[2] = current[2]
	end

	err[2] = 0.0
	local horizontal_error_squared = math_:length_squared_vmsum3fp(err)
	-- Native fcmpu+blt skips correction only for an ordered value below 9.0.
	if not (horizontal_error_squared < HORIZONTAL_ERROR_LIMIT_SQUARED) then
		local predicted_horizontal = table.clone(output)
		predicted_horizontal[2] = 0.0
		local maximum_length = math_:length_vmsum3fp_vrsqrte(predicted_horizontal)
		local current_horizontal = table.clone(current)
		current_horizontal[2] = 0.0
		local clamped = math_:clamp_vector_within_max_length(current_horizontal, maximum_length)
		output[1] = clamped[1]
		output[3] = clamped[3]
	end
	return output
end

return jump_velocity
