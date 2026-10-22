--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact_feedback/spy.rs (коммит 2e16697)

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local spy = {}

local function vec(words: { number }, offset: number): { number }
	return { from_bits(words[offset + 1]), from_bits(words[offset + 2]), from_bits(words[offset + 3]), from_bits(words[offset + 4]) }
end

-- Complete TU3 82AE1608. Compacts eligible256-byte compiled contact rows into
-- 112-byte spies at the same buffer start. `spy_count` increments from its input
-- value; it does not choose the write offset and is not reset by this routine.
-- `body_center` resolves the exact body pointer to its packed COM/ID vector.
-- ROBLOX: `spy_count: &mut u32` -> новое значение возвращается.
function spy.spy_contact_jacobians(
	storage: { number },
	contact_count: number,
	spy_count: number,
	frequency: number,
	body_center: (number) -> { number }
): number
	assert(#storage >= contact_count * 64)
	local squared_frequency = f32(frequency * frequency)
	local write = 0
	for index = 0, contact_count - 1 do
		local start = index * 64
		if bit32.band(storage[start + 12], 8) ~= 0 then
			local impulse = vec(storage, start + 20)
			if impulse[1] > 0.0 then
				local a = storage[start + 32]
				local b = storage[start + 44]
				local bc = body_center(b)
				local ac = body_center(a)
				local b_center = { from_bits(bc[1]), from_bits(bc[2]), from_bits(bc[3]), from_bits(bc[4]) }
				local a_center = { from_bits(ac[1]), from_bits(ac[2]), from_bits(ac[3]), from_bits(ac[4]) }
				local a_position = vec(storage, start)
				local b_position = vec(storage, start + 4)
				local a_weight = from_bits(storage[start + 36])
				local b_weight = from_bits(storage[start + 40])
				local normal = vec(storage, start + 28)
				local tangent0 = vec(storage, start + 40)
				local tangent1 = vec(storage, start + 52)
				local tangent, position = {}, {}
				local inverse = f32(1.0 / f32(b_weight + a_weight))
				for i = 1, 4 do
					tangent[i] = mul_add(tangent0[i], impulse[2], f32(tangent1[i] * impulse[3]))
					position[i] = f32(
						mul_add(f32(a_center[i] + a_position[i]), a_weight, f32(f32(b_center[i] + b_position[i]) * b_weight))
							* inverse
					)
				end
				local tag = storage[start + 56]
				-- All source vectors/scalars are loaded before the in-place stores.
				storage[write + 25] = a
				storage[write + 26] = b
				storage[write + 27] = tag
				for i = 0, 3 do
					storage[write + 17 + i] = to_bits(f32(f32(normal[i + 1] * impulse[1]) * squared_frequency))
					storage[write + 21 + i] = to_bits(f32(tangent[i + 1] * squared_frequency))
					storage[write + 1 + i] = to_bits(normal[i + 1])
					storage[write + 5 + i] = to_bits(tangent0[i + 1])
					storage[write + 9 + i] = to_bits(tangent1[i + 1])
					storage[write + 13 + i] = to_bits(position[i + 1])
				end
				spy_count = rt.wrapping_add_u32(spy_count, 1)
				write += 28
			end
		end
	end
	return spy_count
end

return spy
