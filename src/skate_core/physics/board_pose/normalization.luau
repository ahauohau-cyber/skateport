--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_pose/normalization.rs (коммит 2e16697)

local a = require("./arithmetic")

local f32 = require("../../../rt").f32

local normalization = {}

-- 825C5710: z/y/x projection against ORIGINAL input axes, then normalization.
-- Translation is copied verbatim. Degenerate inputs receive no invented repair.
function normalization.orthonormalize_rotation(input: { number }): { number }
	local original = a.matrix(input)
	local out = { table.clone(original[1]), table.clone(original[2]), table.clone(original[3]), table.clone(original[4]) }
	for axis = 2, 0, -1 do
		local residual = original[axis + 1]
		for other = 2, axis + 1, -1 do
			residual = a.sub(residual, a.mul(out[other + 1], a.splat(a.dot(out[other + 1], original[axis + 1], false))))
		end
		out[axis + 1] = a.normalize(residual, false)
	end
	return a.words(out)
end

-- 82AE0A40: native magnitude gates and least-parallel pair selection followed
-- by two normalized cross products. This differs from 825C5710 above.
function normalization.orthonormalize_part_basis(input: { number }): { number }
	local m = a.matrix(input)
	local squares = { a.dot(m[1], m[1], false), a.dot(m[2], m[2], false), a.dot(m[3], m[3], false) }
	local magnitudes = {}
	for i = 1, 3 do
		local v = squares[i]
		local root = f32(v * a.rsqrt(v))
		magnitudes[i] = if v == 0.0 then 0.0 else root
	end
	for axis = 1, 3 do
		m[axis] = a.mul(m[axis], a.splat(a.rsqrt(squares[axis])))
	end
	local u, v, w
	if not (magnitudes[1] > 0.0) then
		u, v, w = 1, 2, 0
	elseif not (magnitudes[2] > 0.0) then
		u, v, w = 2, 0, 1
	elseif not (magnitudes[3] > 0.0) then
		u, v, w = 0, 1, 2
	else
		local ca = math.abs(a.dot(m[3], m[1], false))
		local bc = math.abs(a.dot(m[2], m[3], false))
		local ab = math.abs(a.dot(m[1], m[2], false))
		if ca > bc then
			if ab > bc then
				u, v, w = 1, 2, 0
			else
				u, v, w = 0, 1, 2
			end
		elseif ab > ca then
			u, v, w = 2, 0, 1
		else
			u, v, w = 0, 1, 2
		end
	end
	m[w + 1] = a.normalize(a.cross(m[u + 1], m[v + 1]), false)
	m[v + 1] = a.normalize(a.cross(m[w + 1], m[u + 1]), false)
	return a.words(m)
end

return normalization
