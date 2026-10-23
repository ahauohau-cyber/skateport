--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_output/correction.rs (коммит 2e16697)
--
-- PostWipeoutCheck82BD83E0's error correction before wobble and physical IK.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local sar = require("../skeleton_animation_record")
local skeleton_body = require("../skeleton_body")

local f32 = rt.f32
local mul_add = rt.mul_add
local dot3, vector_min = native_arithmetic.dot3, native_arithmetic.vector_min
local copy_transform = sar.copy_transform
local SkeletonBody = skeleton_body.SkeletonBody

type F4 = { number }

local correction = {}

export type CorrectionState = {
	--Skeleton16224, initialized zero at82BD7918.
	board_prediction_error: F4,
	--Skeleton16388, initialized false at82BD7998 and set by Ground::Update.
	pending: boolean,
}

local CorrectionState = {}
correction.CorrectionState = CorrectionState

-- ROBLOX: #[derive(Default)].
function CorrectionState.default(): CorrectionState
	return { board_prediction_error = { 0.0, 0.0, 0.0, 0.0 }, pending = false }
end

-- ///UpdatePostPhysics82BD8194..81B0, before collision and error feedback:
-- ///actual board GetPartTransform translation minus predicted16112.
function CorrectionState.observe_board(self: CorrectionState, actual: F4, predicted: F4)
	self.board_prediction_error = { f32(actual[1] - predicted[1]), f32(actual[2] - predicted[2]), f32(actual[3] - predicted[3]), f32(actual[4] - predicted[4]) }
end

-- ///Skeleton16224 is the already-produced board prediction error, and16388 says the
-- ///record adjustment remains pending. This function does not synthesize errors.
-- ROBLOX: pending: &mut bool -> ячейка { value }.
function correction.apply(body: skeleton_body.SkeletonBody, pending: { value: boolean }, error_: F4, ground_normal: F4, wipeout: boolean, flags_2468: number, flags_2476: number)
	if wipeout and bit32.band(flags_2476, bit32.lshift(1, 30)) ~= 0 then
		--82BE2AB0 moves live parts0..23 only when correction length²<1.
		if 1.0 > dot3(error_, error_) then
			for part = 0, 23 do
				local frame = copy_transform(body.record.pose[part + 1])
				for lane = 1, 4 do
					frame[4][lane] = f32(frame[4][lane] + error_[lane])
				end
				SkeletonBody.set_part_transform(body, part, frame)
			end
		end
		pending.value = false
	elseif not wipeout and bit32.band(flags_2468, bit32.lshift(1, 18)) == 0 and pending.value then
		local distance = dot3(error_, ground_normal)
		local allowed = vector_min(0.0, distance)
		local offset = {}
		for i = 1, 4 do
			local tangent = f32(error_[i] - f32(ground_normal[i] * distance))
			offset[i] = mul_add(ground_normal[i], allowed, tangent)
		end
		--82BEC2C0 starts at record part1 and translates through23. It leaves
		--the observed board, solver states, COM and velocity history alone.
		for part = 1, 23 do
			local t = body.record.pose[part + 1][4]
			for lane = 1, 4 do
				t[lane] = f32(t[lane] + offset[lane])
			end
		end
		pending.value = false
	end
end

function CorrectionState.apply(self: CorrectionState, body: skeleton_body.SkeletonBody, ground_normal: F4, wipeout: boolean, flags_2468: number, flags_2476: number)
	local pending = { value = self.pending }
	correction.apply(body, pending, self.board_prediction_error, ground_normal, wipeout, flags_2468, flags_2476)
	self.pending = pending.value
end

return correction
