--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/posture.rs (коммит 2e16697)
--
-- TU3 posture profile selection and the pending GetAnimTree construction latch.
-- 82590B50 maps profile values; 82678990 sets the latch; 82B984C8 consumes it.
-- Channel construction bypasses this service entirely (82D1CC20/82D1D0F0).

local posture = {}

-- Registration order at 82858810, independent of asset directory ordering.
-- ROBLOX: enum PosturePose -> строки "Stiff" | "Slouch" | "Buff".
export type PosturePose = "Stiff" | "Slouch" | "Buff"

local PosturePose = {}
posture.PosturePose = PosturePose

function PosturePose.from_profile(value: number): PosturePose?
	if value == 1 then
		return "Stiff"
	elseif value == 2 then
		return "Slouch"
	elseif value == 3 then
		return "Buff"
	end
	return nil
end

function PosturePose.name(self: PosturePose): string
	if self == "Stiff" then
		return "POSTURE_STIFF_POSE"
	elseif self == "Slouch" then
		return "POSTURE_SLOUCH_POSE"
	end
	return "POSTURE_BUFF_POSE"
end

-- Actual profile selection and a request for the next eligible main tree.
-- Native reset 824FA9A0 supplies profile 0; constructor 82B973C8 clears pending.
export type PendingPosture = { profile: number, pending: boolean }

local PendingPosture = {}
posture.PendingPosture = PendingPosture

function PendingPosture.default(): PendingPosture
	return { profile = 0, pending = false }
end

-- Profile refresh changes selection without inventing a playback request.
function PendingPosture.set_profile(self: PendingPosture, profile: number)
	self.profile = profile
end
function PendingPosture.profile(self: PendingPosture): number
	return self.profile
end
-- Every Play Begin overwrites this latch, including an authored false.
function PendingPosture.set_requested(self: PendingPosture, requested: boolean)
	self.pending = requested
end
function PendingPosture.is_pending(self: PendingPosture): boolean
	return self.pending
end
function PendingPosture.selected_pose(self: PendingPosture): PosturePose?
	return if self.pending then PosturePose.from_profile(self.profile) else nil
end

-- Wrap a successfully built main motion tree before its bind-pose wrapper.
-- The caller must first establish a valid registered static-pose bank.
-- Missing motion/bank must skip this call and leave the latch untouched.
-- Clear only after posture construction succeeds, before outer bind work.
-- ROBLOX: Result<T, E> из wrap -> ошибка wrap пробрасывается как есть.
function PendingPosture.apply<T>(self: PendingPosture, motion: T, wrap: (T, PosturePose) -> T): T
	local pose = PendingPosture.selected_pose(self)
	if pose == nil then
		return motion
	end
	local wrapped = wrap(motion, pose)
	self.pending = false
	return wrapped
end

return posture
