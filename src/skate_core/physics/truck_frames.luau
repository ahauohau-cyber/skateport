--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/truck_frames.rs (коммит 2e16697)
--
-- Dynamic truck frames, TU3 `SkateboardBody::SetTruckDriveFrames` (0x82C0B9C0).

local rt = require("../../rt")
local trigonometry = require("../trigonometry")
local drive_frames = require("./drive_frames")

local f32 = rt.f32
local mul_add = rt.mul_add

type RetailAffineTransform = drive_frames.RetailAffineTransform

local truck_frames = {}

local function rotate_truck(base: RetailAffineTransform, angle: number): RetailAffineTransform
	local sin, cos = trigonometry.sin_cos(angle)
	local rotation = { { 1.0, 0.0, 0.0 }, { 0.0, cos, sin }, { 0.0, -sin, cos } }
	local b = base.basis.columns
	local columns = {}
	for i, column in rotation do
		local out = {}
		for lane = 1, 3 do
			local first = f32(column[1] * b[1][lane])
			local second = mul_add(column[2], b[2][lane], first)
			out[lane] = mul_add(column[3], b[3][lane], second)
		end
		columns[i] = out
	end
	return { basis = { columns = columns }, translation = base.translation }
end

-- 82C0B9C0 caches front7840/back7904 for both physical drives and the
-- physical pose worker82DB6698. Preserve this separately from the base frames.
function truck_frames.steering_truck_transforms(base: { RetailAffineTransform }, targets: { number }): { RetailAffineTransform }
	return { rotate_truck(base[1], -targets[1]), rotate_truck(base[2], targets[2]) }
end

-- `base` is CalculateTruckTransforms output in native +7712/+7776 order.
-- Targets are +7680/+7684. Frame output follows +6768/+6832 drive order.
function truck_frames.steering_drive_frames(base: { RetailAffineTransform }, targets: { number }): { drive_frames.RetailDriveFrames }
	local t = truck_frames.steering_truck_transforms(base, targets)
	local front, back = t[1], t[2]
	return {
		drive_frames.set_drive_frames_2(drive_frames.RetailAffineTransform.IDENTITY(), back),
		drive_frames.set_drive_frames_2(drive_frames.RetailAffineTransform.IDENTITY(), front),
	}
end

return truck_frames
