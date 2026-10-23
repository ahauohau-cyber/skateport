--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/pose_sample.rs (коммит 2e16697)
--
-- TU3 timed frame selection 82D20788 and decoded VBR interpolation 82D1DE08.
-- The data adapter supplies complete decoded keys; no clip substitution occurs.

local rt = require("../../rt")
local sqt = require("./output/sqt")
local pose_blend = require("./pose_blend")

local f32 = rt.f32

local pose_sample = {}

-- ROBLOX: first/second — номера кадров с нуля.
export type FrameSelection = { first: number, second: number, coefficient: number }

local K_37800080 = rt.from_bits(0x37800080)

-- Clip evaluation supplies bounded nonnegative seconds. Frame blending uses
-- zero truncation offset; disabled blending uses the FetchSys setting at +8.
-- ROBLOX: Result<_, &'static str> -> rt.raise(строка).
function pose_sample.select_frames(time: number, fps: number, frames: number, blend_frames: boolean, truncation_offset: number): FrameSelection
	if frames == 0 or not rt.is_finite(time) or time < 0.0 or not rt.is_finite(fps) or fps <= 0.0 then
		rt.raise("Invalid stock animation sampling input")
	end
	local last = f32(frames - 1)
	local position = f32(time * fps)
	position = if f32(position - last) >= 0.0 then last else position
	local offset = if blend_frames then 0.0 else truncation_offset
	-- ROBLOX: f32 as usize — отбрасывание дробной части с насыщением в 0.
	local sum = f32(position + offset)
	local first = if sum ~= sum or sum <= 0 then 0 else math.floor(sum)
	if first >= frames then
		rt.raise("Stock frame selection exceeds decoded samples")
	end
	local second = if blend_frames then math.min(first + 1, frames - 1) else first
	-- 82D20C08 truncates to 16 bits, 82D1E090 expands using literal 822F88B8.
	local scaled = f32(f32(position - f32(first)) * 65535.0)
	local fraction = if scaled ~= scaled or scaled <= 0 then 0 elseif scaled >= 65535 then 65535 else math.floor(scaled)
	return { first = first, second = second, coefficient = f32(fraction * K_37800080) }
end

function pose_sample.sample_key(first: sqt.Sqt, second: sqt.Sqt, selection: FrameSelection): sqt.Sqt
	-- Same-frame extraction does not normalize its decoded quaternion.
	if selection.first == selection.second then
		return first
	end
	return pose_blend.blend_sample(first, second, selection.coefficient)
end

-- TU3 VBR's two-frame extraction selects the second compressed block at an
-- 8-frame boundary, and uses its second frame for both decoded keys.
-- Original raw 82D1E0C0..E0 selects the block; 82E89BD0..BF4 replaces the first
-- intra-block index. Keep the ORIGINAL selection for interpolation: two-frame
-- extraction still normalizes the quaternion, even when both samples coincide.
function pose_sample.sample_key_vbr(first: sqt.Sqt, second: sqt.Sqt, selection: FrameSelection): sqt.Sqt
	local crosses_block = selection.first // 8 ~= selection.second // 8
	local copies_second = crosses_block and (selection.first % 8 == 7 or selection.second % 8 == 0)
	return pose_sample.sample_key(if copies_second then second else first, second, selection)
end

return pose_sample
