--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/solver/contact_data.rs (коммит 2e16697)
--
-- Named view of the compiled contact and shared reaction records.
-- Fourth components retain the native packed layout, including inverse mass
-- alongside each body's first angular response.
-- ROBLOX: в Rust это подмодуль contact (`#[path]`), здесь — отдельный файл.
-- Components = [f32; 4] -> таблица из 4 чисел, лейн i в [i + 1].

local rt = require("../../../rt")

local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type Components = { number }

local contact_data = {}

local function read(words: { number }, row: number): Components
	return {
		from_bits(words[4 * row + 1]),
		from_bits(words[4 * row + 2]),
		from_bits(words[4 * row + 3]),
		from_bits(words[4 * row + 4]),
	}
end

local function write(words: { number }, row: number, value: Components)
	for lane = 1, 4 do
		words[4 * row + lane] = to_bits(value[lane])
	end
end

export type ContactRows = {
	arm_a: Components,
	arm_b: Components,
	correction_columns: { Components },
	static_friction: number,
	dynamic_friction: number,
	accumulated: Components,
	target: Components,
	axes: { Components },
	angular_a: { Components },
	angular_b: { Components },
}

local ContactRows = {}
contact_data.ContactRows = ContactRows

function ContactRows.read(words: { number }): ContactRows
	assert(#words == 64)
	return {
		arm_a = read(words, 0),
		arm_b = read(words, 1),
		correction_columns = { read(words, 2), read(words, 3), read(words, 4) },
		static_friction = from_bits(words[16]),
		dynamic_friction = from_bits(words[20]),
		accumulated = read(words, 5),
		target = read(words, 6),
		axes = { read(words, 7), read(words, 10), read(words, 13) },
		angular_a = { read(words, 8), read(words, 11), read(words, 14) },
		angular_b = { read(words, 9), read(words, 12), read(words, 15) },
	}
end

function ContactRows.publish_impulses(_self: ContactRows, words: { number }, impulse: Components)
	write(words, 5, impulse)
end

export type Reaction = {
	linear: Components,
	position: Components,
	angular: Components,
	orientation: Components,
}

local Reaction = {}
contact_data.Reaction = Reaction

function Reaction.read(words: { number }): Reaction
	assert(#words == 16)
	return { linear = read(words, 0), position = read(words, 1), angular = read(words, 2), orientation = read(words, 3) }
end

-- 82AE297C..2A18: linear + angular cross arm. Fuse the first product into
-- linear before subtracting the second; a separate cross product rounds early.
local function point_correction(arm: Components, linear: Components, angular: Components): Components
	local out = {}
	for lane = 0, 3 do
		local next_lane = if lane == 3 then 3 else (lane + 1) % 3
		local previous = if lane == 3 then 3 else (lane + 2) % 3
		local first = mul_add(angular[next_lane + 1], arm[previous + 1], linear[lane + 1])
		out[lane + 1] = mul_add(-angular[previous + 1], arm[next_lane + 1], first)
	end
	return out
end

function Reaction.point_position(self: Reaction, arm: Components): Components
	return point_correction(arm, self.position, self.orientation)
end

function Reaction.point_velocity(self: Reaction, arm: Components): Components
	return point_correction(arm, self.linear, self.angular)
end

function Reaction.apply_contact(self: Reaction, rows: ContactRows, change: Components, body_a: boolean)
	local response = if body_a then rows.angular_a else rows.angular_b
	local inverse_mass = response[1][4]
	for lane = 1, 4 do
		local linear_impulse = mul_add(rows.axes[1][lane], change[1], 0.0)
		linear_impulse = mul_add(rows.axes[2][lane], change[2], linear_impulse)
		linear_impulse = mul_add(rows.axes[3][lane], change[3], linear_impulse)
		local position_impulse = mul_add(rows.axes[1][lane], change[4], 0.0)
		if body_a then
			for axis = 1, 3 do
				self.angular[lane] = mul_add(response[axis][lane], change[axis], self.angular[lane])
			end
			self.orientation[lane] = mul_add(response[1][lane], change[4], self.orientation[lane])
			self.linear[lane] = mul_add(linear_impulse, inverse_mass, self.linear[lane])
			self.position[lane] = mul_add(position_impulse, inverse_mass, self.position[lane])
		else
			for axis = 1, 3 do
				self.angular[lane] = mul_add(-response[axis][lane], change[axis], self.angular[lane])
			end
			self.orientation[lane] = mul_add(-response[1][lane], change[4], self.orientation[lane])
			self.linear[lane] = mul_add(-linear_impulse, inverse_mass, self.linear[lane])
			self.position[lane] = mul_add(-position_impulse, inverse_mass, self.position[lane])
		end
	end
end

function Reaction.write(self: Reaction, words: { number })
	write(words, 0, self.linear)
	write(words, 1, self.position)
	write(words, 2, self.angular)
	write(words, 3, self.orientation)
end

return contact_data
