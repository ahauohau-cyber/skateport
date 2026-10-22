--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/math.rs (коммит 2e16697)
--
-- Shared scalar types. Rendering conversions stay outside the core.

local math_mod = {}

-- ROBLOX: Vector3 { x, y, z: f32 } -> встроенный тип `vector`.
-- Он хранит компоненты в f32 (как Rust), сравнивается по значению
-- и копируется при присваивании, как Copy-структура в Rust.
-- Поля читаются так же: v.x, v.y, v.z. Менять поле на месте нельзя:
-- вместо `v.y = 1.0` пишем `v = vector.create(v.x, 1.0, v.z)`.
export type Vector3 = vector

local Vector3 = {}
math_mod.Vector3 = Vector3

-- pub const ZERO: Self
Vector3.ZERO = vector.create(0.0, 0.0, 0.0)

-- pub const fn new(x: f32, y: f32, z: f32) -> Self
function Vector3.new(x: number, y: number, z: number): Vector3
	return vector.create(x, y, z)
end

-- impl Default for Vector3
function Vector3.default(): Vector3
	return Vector3.ZERO
end

-- ROBLOX: Basis3 { columns: [[f32; 3]; 3] } -> таблица.
-- Индексы с 1: columns[1][1] в Luau = columns[0][0] в Rust.
-- Таблица передаётся по ссылке, поэтому там, где Rust копирует
-- структуру (Copy), вызываем Basis3.copy.
export type Basis3 = {
	columns: { { number } },
}

local Basis3 = {}
math_mod.Basis3 = Basis3

function Basis3.new(columns: { { number } }): Basis3
	return { columns = columns }
end

-- ROBLOX: замена неявного копирования Copy-структуры.
function Basis3.copy(basis: Basis3): Basis3
	local c = basis.columns
	return {
		columns = {
			{ c[1][1], c[1][2], c[1][3] },
			{ c[2][1], c[2][2], c[2][3] },
			{ c[3][1], c[3][2], c[3][3] },
		},
	}
end

-- ROBLOX: #[derive(PartialEq)] для Basis3.
function Basis3.eq(left: Basis3, right: Basis3): boolean
	for column = 1, 3 do
		for row = 1, 3 do
			if left.columns[column][row] ~= right.columns[column][row] then
				return false
			end
		end
	end
	return true
end

return math_mod
