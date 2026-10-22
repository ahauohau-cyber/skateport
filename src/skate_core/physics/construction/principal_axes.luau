--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/construction/principal_axes.rs (коммит 2e16697)
--
-- TU3 inertia diagonalization: 82AE8388 and its three rotation helpers.
-- Rows here are mathematical rows. The caller transposes the resulting axes
-- into RenderWare's Ri/Up/At storage. No eigenvalue sorting is performed.

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add

local principal_axes = {}

-- pub(super) type Matrix3 = [[f32; 3]; 3]
-- ROBLOX: matrix[row][column] в Rust -> m[row + 1][column + 1].
export type Matrix3 = { { number } }

-- ROBLOX: refined_reciprocal определён в mass.luau, а mass подключает этот файл.
-- Цикл require разорван подключением внутри функции.
local function refined_reciprocal(value: number): number
	return (require("../mass") :: any).refined_reciprocal(value)
end

-- 82AE7AD8. The zero off-diagonal path is exactly the identity rotation.
local function rotation(matrix: Matrix3, row: number, column: number): (number, number)
	local off_diagonal = matrix[row + 1][column + 1]
	if off_diagonal == 0.0 then
		return 0.0, 1.0
	end
	local difference = f32(matrix[column + 1][column + 1] - matrix[row + 1][row + 1])
	local theta = f32(refined_reciprocal(off_diagonal) * f32(difference * 0.5))
	local length = f32(math.sqrt(mul_add(theta, theta, 1.0)))
	local tangent = if theta > 0.0 then f32(1.0 / f32(length + theta)) else f32(-1.0 / f32(length - theta))
	local cosine = f32(1.0 / f32(math.sqrt(mul_add(tangent, tangent, 1.0))))
	return f32(cosine * tangent), cosine
end

-- 82AE7C30: independently rounded products for the subtraction and one FMA
-- for the addition. Combining the subtraction into an FMA changes the port.
local function rotate_columns(matrix: Matrix3, a: number, b: number, sine: number, cosine: number)
	for _, row in matrix do
		local left = row[a + 1]
		local right = row[b + 1]
		row[a + 1] = f32(f32(left * cosine) - f32(right * sine))
		row[b + 1] = mul_add(left, sine, f32(right * cosine))
	end
end

-- 82AE7FD0 applies the matching rotation across the two matrix rows.
local function rotate_rows(matrix: Matrix3, a: number, b: number, sine: number, cosine: number)
	local left = table.clone(matrix[a + 1])
	local right = table.clone(matrix[b + 1])
	for column = 1, 3 do
		matrix[a + 1][column] = f32(f32(left[column] * cosine) - f32(right[column] * sine))
		matrix[b + 1][column] = mul_add(left[column], sine, f32(right[column] * cosine))
	end
end

local F32_1E_24 = f32(1.0e-24)

-- ROBLOX: `&mut Matrix3` — таблица меняется на месте, как в Rust.
-- pub(super) fn diagonalize(inertia: &mut Matrix3) -> Matrix3
function principal_axes.diagonalize(inertia: Matrix3): Matrix3
	local axes = { { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 } }
	local remaining = 10
	while true do
		-- 82AE84A4..8680: squared lower-triangle residual, relative to the
		-- smallest squared diagonal. Preserve comparison and FMA ordering.
		local diagonal = {
			f32(inertia[1][1] * inertia[1][1]),
			f32(inertia[2][2] * inertia[2][2]),
			f32(inertia[3][3] * inertia[3][3]),
		}
		local smallest
		if diagonal[2] > diagonal[1] then
			smallest = if diagonal[3] > diagonal[1] then diagonal[1] else diagonal[3]
		elseif diagonal[3] > diagonal[2] then
			smallest = diagonal[2]
		else
			smallest = diagonal[3]
		end
		local residual = mul_add(
			inertia[3][2],
			inertia[3][2],
			mul_add(inertia[2][1], inertia[2][1], f32(inertia[3][1] * inertia[3][1]))
		)
		if not (residual > f32(smallest * F32_1E_24)) or remaining == 0 then
			break
		end
		for row = 1, 2 do
			for column = 0, row - 1 do
				local sine, cosine = rotation(inertia, row, column)
				rotate_columns(axes, row, column, sine, cosine)
				rotate_columns(inertia, row, column, sine, cosine)
				rotate_rows(inertia, row, column, sine, cosine)
			end
		end
		remaining -= 1
	end
	return axes
end

return principal_axes
