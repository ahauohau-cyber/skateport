--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/drive_preparation/mod.rs (коммит 2e16697)
--
-- Drive-frame preparation in TU3 Island::Step_Solver2 82763B08.
-- The active-drive list is visited before thaw/partition and island-table
-- construction. Every island mode runs this loop, regardless of body flags.

local rt = require("../../rt")
local reciprocal_sqrt = require("./reciprocal_sqrt")
local native_arithmetic = require("./native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local drive_preparation = {}

local function quaternion_squared_length(q: { number }): number
	return native_arithmetic.dot4(q, q)
end

-- The two quaternion operations in the same stage. No zero-length or finite
-- fallback is supplied here.
-- ROBLOX: `&mut [u32; 16]` — таблица меняется на месте.
function drive_preparation.normalize_drive_frames(frames: { number })
	for _, offset in { 0, 8 } do
		local q = {}
		for i = 1, 4 do
			q[i] = from_bits(frames[offset + i])
		end
		local d = quaternion_squared_length(q)
		local e = reciprocal_sqrt.estimate(d)
		for _ = 1, 2 do
			local squared = f32(e * e)
			local half = f32(e * 0.5)
			e = mul_add(half, mul_add(-d, squared, 1.0), e)
		end
		for i = 1, 4 do
			frames[offset + i] = to_bits(f32(q[i] * e))
		end
	end
end

-- Normalize each nonnull frame record in native active-list order. Entries
-- are frame-record indices, not drive/body indices; duplicate references are
-- processed repeatedly just as live pointers are in 82763BB4..82763C50.
-- ROBLOX: Option<usize> -> число (индекс с нуля) или false вместо None.
function drive_preparation.normalize_active_drive_frames(frames: { { number } }, active_frame_indices: { number | false })
	for _, index in active_frame_indices do
		if index ~= false then
			drive_preparation.normalize_drive_frames(frames[(index :: number) + 1])
		end
	end
end

return drive_preparation
