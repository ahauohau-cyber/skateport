--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/point_graph.rs (коммит 2e16697)
--
-- TU3 `PointGraph` scalar evaluator, `0x82481E10`.

local rt = require("../rt")

-- ROBLOX: каждая операция f32 в Rust -> f32(...) (округление до f32).
local f32 = rt.f32
local mul_add = rt.mul_add

local point_graph = {}

-- ROBLOX: PointGraph<const N: usize> { x: [f32; N], y: [f32; N] }.
-- N в Luau — длина массива x (#x). Индексы с 1.
export type PointGraph = {
	x: { number },
	y: { number },
}

local PointGraph = {}
point_graph.PointGraph = PointGraph

function PointGraph.new(x: { number }, y: { number }): PointGraph
	return { x = x, y = y }
end

-- Native endpoint handling and slope-first binary32 interpolation.
function PointGraph.evaluate(self: PointGraph, input: number): number
	local n = #self.x
	assert(n > 0, "assertion failed: N > 0")
	if input < self.x[1] then
		return self.y[1]
	end
	-- The native branch enters the scan only on an ordered less-than.
	-- Unordered input or a NaN final key therefore selects the last value.
	if not (input < self.x[n]) then
		return self.y[n]
	end
	-- ROBLOX: for upper in 1..N (с нуля) -> upper от 2 до n (с единицы).
	for upper = 2, n do
		if not (input < self.x[upper]) then
			continue
		end
		local lower = upper - 1
		local width = f32(self.x[upper] - self.x[lower])
		if width <= 0.0 then
			return self.y[upper]
		end
		local slope = f32(f32(self.y[upper] - self.y[lower]) / width)
		-- ROBLOX: slope.mul_add(a, b) -> mul_add(slope, a, b), одно округление.
		return mul_add(slope, f32(input - self.x[lower]), self.y[lower])
	end
	return self.y[1]
end

-- ROBLOX: #[derive(PartialEq)] для PointGraph.
function PointGraph.eq(left: PointGraph, right: PointGraph): boolean
	if #left.x ~= #right.x or #left.y ~= #right.y then
		return false
	end
	for i = 1, #left.x do
		if left.x[i] ~= right.x[i] then
			return false
		end
	end
	for i = 1, #left.y do
		if left.y[i] ~= right.y[i] then
			return false
		end
	end
	return true
end

return point_graph
