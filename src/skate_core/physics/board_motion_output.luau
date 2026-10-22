--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_motion_output.rs (коммит 2e16697)
--
-- Observed deck motion from TU3 Skateboard::FillPhysOut82C02A80.
-- These calculations consume the live solver body and the actual Reckoning
-- normal. They do not infer contact state from height or vertical velocity.

local rt = require("../../rt")
local math_mod = require("../math")
local board = require("./board")
local native_arithmetic = require("./native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add

type Vector3 = vector

local board_motion_output = {}

export type BoardMotionOutput = {
	angular_velocity: Vector3,
	linear_velocity: Vector3,
	ground_velocity: Vector3,
	-- SkateboardMotion+160: magnitude of the unprojected deck velocity.
	speed: number,
	-- SkateboardMotion+164: magnitude after rejecting the Reckoning normal.
	ground_speed: number,
	-- SkateboardMotion+168: raw deck velocity projected onto effective Z.
	forward_speed: number,
	effective_basis: math_mod.Basis3,
}

function board_motion_output.dot(a: Vector3, b: Vector3): number
	return native_arithmetic.dot3({ a.x, a.y, a.z, 0.0 }, { b.x, b.y, b.z, 0.0 })
end
local dot = board_motion_output.dot

function board_motion_output.scale(v: Vector3, s: number): Vector3
	return vector.create(f32(v.x * s), f32(v.y * s), f32(v.z * s))
end
function board_motion_output.add(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x + b.x), f32(a.y + b.y), f32(a.z + b.z))
end
function board_motion_output.subtract(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x - b.x), f32(a.y - b.y), f32(a.z - b.z))
end

-- ROBLOX: f32::is_subnormal.
local function is_subnormal(x: number): boolean
	return x ~= 0 and math.abs(x) < rt.F32_MIN_POSITIVE
end

function board_motion_output.inverse_length_squared(squared_in: number, refinements: number): number
	-- The PC rsqrt seed preserves subnormals. Squaring its finite inverse
	-- can overflow during refinement (landing residuals around 1e-22).
	-- Rescale the exponent before refinement, then undo that scale:
	-- rsqrt(x * 2^24) * 2^12 = rsqrt(x). Normal inputs keep the same path.
	local squared, rescale = squared_in, 1.0
	if squared_in > 0.0 and is_subnormal(squared_in) then
		squared, rescale = f32(squared_in * 16777216.0), 4096.0
	end
	local inverse = native_arithmetic.reciprocal_square_root_estimate(squared)
	for _ = 1, refinements do
		local correction = mul_add(-squared, f32(inverse * inverse), 1.0)
		inverse = mul_add(f32(inverse * 0.5), correction, inverse)
	end
	return f32(inverse * rescale)
end

function board_motion_output.length(v: Vector3): number
	local squared = dot(v, v)
	local value = f32(squared * board_motion_output.inverse_length_squared(squared, 2))
	return if squared == 0.0 then 0.0 else value
end

local BoardMotionOutput = {}
board_motion_output.BoardMotionOutput = BoardMotionOutput

-- pub fn from_board(board, reckoning_ground_normal, processed_flags_2468) -> Self
-- ROBLOX: board — board_runtime.BoardRuntime (подключается внутри: board_runtime
-- зависит от модулей, которые подключают этот файл).
function BoardMotionOutput.from_board(runtime: any, reckoning_ground_normal: Vector3, processed_flags_2468: number): BoardMotionOutput
	local BoardRuntime = (require("./board_runtime") :: any).BoardRuntime
	local deck_index = board.BodyId.Deck + 1
	local deck = BoardRuntime.bodies(runtime)[deck_index].rates
	local effective_basis = math_mod.Basis3.copy(BoardRuntime.part_transforms(runtime)[deck_index].basis)
	-- Complete GetEffectiveTransform82C01BF8 axis adjustment; translation
	-- and Y remain the physical part's values.
	if bit32.band(processed_flags_2468, 0x0010_0000) ~= 0 then
		for _, axis in { 1, 3 } do
			local c = effective_basis.columns[axis]
			effective_basis.columns[axis] = { -c[1], -c[2], -c[3] }
		end
	end
	local normal_speed = dot(deck.linear_velocity, reckoning_ground_normal)
	local ground_velocity = board_motion_output.subtract(
		deck.linear_velocity,
		board_motion_output.scale(reckoning_ground_normal, normal_speed)
	)
	local z = effective_basis.columns[3]
	return {
		angular_velocity = deck.angular_velocity,
		linear_velocity = deck.linear_velocity,
		ground_velocity = ground_velocity,
		speed = board_motion_output.length(deck.linear_velocity),
		ground_speed = board_motion_output.length(ground_velocity),
		forward_speed = dot(deck.linear_velocity, vector.create(z[1], z[2], z[3])),
		effective_basis = effective_basis,
	}
end

return board_motion_output
