--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_forces/orientation.rs (коммит 2e16697)
--
-- ZIP orientation formulas checked against original S3 family bodies.
-- S2 equivalents82D9B818/918/BAC0/BCF8/BD88 retain tunable angles/blends;
-- S3 uses the literals below and adds darkslide's inverted normal.
-- ROBLOX: Frame = [V; 4] -> таблица из 4 векторов; Result<_, &str> -> rt.raise(строка).

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local board_motion_output = require("../board_motion_output")
local trigonometry = require("../../trigonometry")
local foot_ik = require("../../animation/foot_ik")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3

type V = { number }
export type Frame = { V }

local orientation = {}
orientation.parent = (nil :: any)

export type Input = {
	-- Exact Processed64..127, not an effective/fakie-adjusted board frame.
	board: Frame,
	direction: V,
	normal: V,
	point: V,
	yaw_1504: number,
	pitch_1508: number,
	switched: boolean,
}

export type Target = { frame: Frame, noise_amount: number }

local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end
local function signed(v: V, positive: boolean): V
	if positive then
		return v
	end
	return scale(v, -1.0)
end
local function rotate(axis: V, value: V, angle: number): V
	local sine, cosine = trigonometry.sin_cos(f32(angle * 0.5))
	local q = scale(axis, sine)
	local first = cross(q, value)
	local inner = {}
	for i = 1, 4 do
		inner[i] = mul_add(cosine, value[i], first[i])
	end
	local second = cross(q, inner)
	local out = {}
	for i = 1, 4 do
		out[i] = mul_add(2.0, second[i], value[i])
	end
	return out
end

-- 82D40290: zero angles skip rotation; near-parallel support returns the entire
-- input frame. Neither branch introduces a replacement normal or heading.
local function truck(i: Input): Frame
	local P = orientation.parent
	local yaw = f32(i.yaw_1504 * -f32(0.68))
	local forward = i.board[3]
	if math.abs(yaw) > 0.0 then
		forward = rotate(i.normal, forward, yaw)
	end
	local right = cross(i.normal, forward)
	local magnitude = P.length(right)
	if magnitude <= f32(0.001) then
		return i.board
	end
	right = scale(right, P.reciprocal(magnitude))
	local up = cross(forward, right)
	local pitch = f32((if i.switched then -i.pitch_1508 else i.pitch_1508) * f32(0.68))
	if math.abs(pitch) > 0.0 then
		forward = rotate(right, forward, pitch)
		up = cross(forward, right)
	end
	return { right, up, forward, i.board[4] }
end

-- ROBLOX: Result<Target, &str> -> Target или rt.raise("Unknown physical grind family").
function orientation.target(family: number, i: Input): Target
	local frame: Frame
	if family == 0 and math.abs(i.pitch_1508) <= f32(0.12) then
		local forward = signed(i.direction, dot3(i.direction, i.board[3]) > 0.0)
		frame = { cross(i.normal, forward), i.normal, forward, i.board[4] }
	elseif family == 0 or family == 3 then
		frame = truck(i)
	elseif family == 1 or family == 5 then
		local right = signed(i.direction, dot3(i.direction, i.board[1]) > 0.0)
		local up = if family == 5 then scale(i.normal, -1.0) else i.normal
		frame = { right, up, cross(right, up), i.board[4] }
	elseif family == 2 or family == 4 then
		local across = cross(i.direction, i.normal)
		local axis = signed(i.direction, not (dot3(across, sub(i.board[4], i.point)) > 0.0))
		-- Original822F8618/822F8614,20/42degrees expressed in radians.
		local angle = from_bits(if family == 4 then 0x3f3b_a866 else 0x3eb2_b8c3)
		local up = rotate(axis, i.normal, angle)
		local right = signed(i.direction, dot3(i.direction, i.board[1]) > 0.0)
		frame = { right, up, cross(right, up), i.board[4] }
	else
		rt.raise("Unknown physical grind family")
	end
	return { frame = frame, noise_amount = if family == 0 then 0.0 else f32(0.09) }
end

local function orthonormal(input: Frame): Frame
	local output = { { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } }
	for axis = 3, 1, -1 do
		local value = input[axis]
		for previous = 3, axis + 1, -1 do
			value = sub(value, scale(output[previous], dot3(output[previous], input[axis])))
		end
		output[axis] = scale(value, board_motion_output.inverse_length_squared(dot3(value, value), 2))
	end
	return output
end

-- 82D40890: reverse-order classical Gram-Schmidt on BOTH frames, then
-- CURRENT's original82BD3150 helper. The temporary orthonormal frames' fourth
-- vectors are explicitly zeroed (82D40930/82D409C8), not a position teleport.
function orientation.blend(current: Frame, target: Frame): Frame
	local out = foot_ik.interpolate_native(orthonormal(current) :: any, orthonormal(target) :: any, f32(0.1))
	return out :: any
end

return orientation
