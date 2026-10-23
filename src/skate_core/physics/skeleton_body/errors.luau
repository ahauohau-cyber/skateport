--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/errors.rs (коммит 2e16697)
--
-- Original physical pose errors82BEBEA8 and normal collision response82BE2438.

local collision_feedback = require("./collision_feedback")
require("./collision_filter") -- ROBLOX: подключает метод filter_error.
local cv = require("./collision_vector")
local sar = require("../skeleton_animation_record")

local dot, sub, transform, length = cv.dot, cv.sub, cv.transform, cv.length

type V = collision_feedback.V
type AnimationPartTransform = sar.AnimationPartTransform

local errors = {}

export type SkeletonPoseErrors = {
	-- SkeletonState4752, one vector per animated part.
	parts: { V },
	-- SkeletonState5136/5152: the two additional physical target errors.
	extra: { V },
	-- SkeletonState5168/5184/5200, written by UpdateExtraTargets.
	targets: { V },
}

export type SkeletonNormalError = {
	-- Skeleton16272: physical error constrained by actual contact planes.
	impulse: V,
	-- Normal82BE2438 clears Skeleton16288 and16304.
	extra: { V },
	-- Skeleton16384, length before contact-plane filtering.
	maximum_error: number,
}

local SkeletonPoseErrors = {}
errors.SkeletonPoseErrors = SkeletonPoseErrors

local function zeros(n: number): { V }
	local t = table.create(n) :: any
	for i = 1, n do
		t[i] = { 0.0, 0.0, 0.0, 0.0 }
	end
	return t
end

-- ROBLOX: #[derive(Default)].
function SkeletonPoseErrors.default(): SkeletonPoseErrors
	return { parts = zeros(24), extra = zeros(2), targets = zeros(3) }
end

-- ///82BEBBB0 clears only target histories. The next82BEBEA8 replaces errors.
function SkeletonPoseErrors.reset_history(self: SkeletonPoseErrors)
	self.targets = zeros(3)
end

-- ROBLOX: positions — ExtraTargetPositions (target_update.luau).
function SkeletonPoseErrors.set_targets(self: SkeletonPoseErrors, positions: any)
	self.targets = { table.clone(positions.com), table.clone(positions.lifted_com), table.clone(positions.following_com) }
end

-- ///82BEBEA8. These are actual part-frame errors, not COM or force proxies.
function SkeletonPoseErrors.update(self: SkeletonPoseErrors, physical: any, animation_to_world: AnimationPartTransform, drive_frames: { AnimationPartTransform })
	self.parts[1] = { 0.0, 0.0, 0.0, 0.0 }
	for part = 1, 23 do
		self.parts[part + 1] = sub(physical.pose[part + 1][4], transform(animation_to_world, drive_frames[part + 1][4]))
	end
	for i = 1, 2 do
		self.extra[i] = sub(physical.pose[24 + i][4], self.targets[1 + i])
	end
end

local CANDIDATES = { 23, 17, 18, 16, 21, 22, 20, 1 }

local function maximum_error(self: SkeletonPoseErrors): number
	local candidates = {}
	for i, part in CANDIDATES do
		candidates[i] = self.parts[part + 1]
	end
	local maximum = if dot(candidates[1], candidates[1]) > dot(candidates[2], candidates[2]) then candidates[1] else candidates[2]
	for i = 3, #candidates do
		local candidate = candidates[i]
		if dot(candidate, candidate) > dot(maximum, maximum) then
			maximum = candidate
		end
	end
	return length(maximum)
end

-- ///82BE2438. Strict comparison and the first raw-pair tie behavior differ
-- /// from the filtered-pair tie; preserve both selection sequences.
function SkeletonPoseErrors.normal_response(self: SkeletonPoseErrors, collision: collision_feedback.SkeletonCollisionFeedback, support_normal: V): SkeletonNormalError
	local filtered = {}
	for i, part in CANDIDATES do
		filtered[i] = (collision_feedback.SkeletonCollisionFeedback :: any).filter_error(collision, self.parts[part + 1], support_normal)
	end
	local impulse = filtered[1]
	for i = 2, #filtered do
		local candidate = filtered[i]
		if dot(candidate, candidate) > dot(impulse, impulse) then
			impulse = candidate
		end
	end
	return {
		impulse = impulse,
		extra = zeros(2),
		maximum_error = maximum_error(self),
	}
end

-- ///82BD9FB0 partial-ragdoll branch copies the two extra errors directly,
-- /// then82BE2310 computes the same raw eight-part maximum length.
function SkeletonPoseErrors.partial_response(self: SkeletonPoseErrors): SkeletonNormalError
	return {
		impulse = table.clone(self.extra[1]),
		extra = { table.clone(self.extra[1]), table.clone(self.extra[2]) },
		maximum_error = maximum_error(self),
	}
end

return errors
