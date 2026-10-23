--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/trajectory/math.rs (коммит 2e16697)
--
-- Independent PC arithmetic retaining the recovered refinement sequences.
-- ROBLOX: Vector = [f32; 4] -> таблица из 4 чисел, индексы с 1 (Rust v[1] -> v[2]).
-- Transform = [Vector; 4] -> таблица из 4 таких таблиц.

local rt = require("../../../rt")
local native_arithmetic = require("../../physics/native_arithmetic")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local math_ = {}

export type Vector = { number }
export type Transform = { Vector }

-- ROBLOX: const ZERO/UP/IDENTITY -> функции, возвращающие новую таблицу,
-- чтобы случайная запись в одну копию не портила «константу».
function math_.zero(): Vector
	return { 0.0, 0.0, 0.0, 0.0 }
end
function math_.up(): Vector
	return { 0.0, 1.0, 0.0, 0.0 }
end
math_.STEP = from_bits(0x3c88_8889)
function math_.identity(): Transform
	return { { 1.0, 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0, 0.0 }, { 0.0, 0.0, 1.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } }
end

function math_.dot(a: Vector, b: Vector): number
	return native_arithmetic.dot3(a, b)
end
function math_.add(a: Vector, b: Vector): Vector
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
function math_.sub(a: Vector, b: Vector): Vector
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
function math_.scale(a: Vector, s: number): Vector
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end
function math_.madd(a: Vector, s: number, b: Vector): Vector
	return { mul_add(a[1], s, b[1]), mul_add(a[2], s, b[2]), mul_add(a[3], s, b[3]), mul_add(a[4], s, b[4]) }
end
function math_.cross(a: Vector, b: Vector): Vector
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		0.0,
	}
end
function math_.inverse_length(square: number): number
	local v = native_arithmetic.reciprocal_square_root_estimate(square)
	for _ = 1, 2 do
		v = mul_add(f32(v * 0.5), mul_add(-square, f32(v * v), 1.0), v)
	end
	return v
end
function math_.reciprocal(value: number): number
	local inverse = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		inverse = mul_add(inverse, mul_add(-inverse, value, 1.0), inverse)
	end
	return inverse
end

-- 8296EBB0: squared-length gate, ONE refinement, clamped dot, native acos.
function math_.angle_between(a: Vector, b: Vector): number
	local aa = math_.dot(a, a)
	local bb = math_.dot(b, b)
	if not (aa > from_bits(0x38d1_b717) and bb > from_bits(0x38d1_b717)) then
		return 0.0
	end
	local function unit(v: Vector, square: number): Vector
		local r = native_arithmetic.reciprocal_square_root_estimate(square)
		return math_.scale(v, mul_add(f32(r * 0.5), mul_add(-square, f32(r * r), 1.0), r))
	end
	return trigonometry.acos(rt.fmin(rt.fmax(math_.dot(unit(a, aa), unit(b, bb)), -1.0), 1.0))
end
function math_.length(a: Vector): number
	local square = math_.dot(a, a)
	if square == 0.0 then
		return 0.0
	end
	return f32(square * math_.inverse_length(square))
end
function math_.normalize(a: Vector): Vector
	local square = math_.dot(a, a)
	local inverse = math_.inverse_length(square)
	local length = if square == 0.0 then 0.0 else f32(square * inverse)
	-- 830BD350's initializer82F826F8 broadcasts82181A88 (1e-6).
	if length > from_bits(0x3586_37bd) then
		return math_.scale(a, inverse)
	end
	return math_.zero()
end
function math_.transform(m: Transform, a: Vector): Vector
	return math_.madd(m[3], a[3], math_.madd(m[2], a[2], math_.madd(m[1], a[1], m[4])))
end

-- ROBLOX: копия значения (Rust Copy-типы копируются при присваивании).
function math_.copy(a: Vector): Vector
	return { a[1], a[2], a[3], a[4] }
end

return math_
