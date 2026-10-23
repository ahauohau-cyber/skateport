--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/drive.rs (коммит 2e16697)
--
-- SkeletonIK::UpdateDriveFrames82BF0198 and its solve/mapping chain.

local rt = require("../../../rt")
local m = require("./math")
local status = require("./status")
local transforms = require("./transforms")
local two_bone = require("./two_bone")
local native_arithmetic = require("../../physics/native_arithmetic")
local sar = require("../../physics/skeleton_animation_record")
local skeleton_root = require("../../physics/skeleton_root")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local cross, length, normalize = m.cross, m.length, m.normalize
local inverse_rigid = transforms.inverse_rigid
local dot3 = native_arithmetic.dot3
local compose_affine = sar.compose_affine
local transform_point = sar.transform_point
local copy_transform = sar.copy_transform
local orthonormalize = skeleton_root.orthonormalize

type Vector = m.Vector
type Transform = sar.AnimationPartTransform

local drive = {}

-- ROBLOX: parents: [Option<usize>; 24] -> массив, где отсутствие — false;
-- индексы частей с нуля.
export type Geometry = {
	-- SkeletonData4704: nearest ancestor represented by a physical part.
	parents: { number | false },
	-- SkeletonData1536: native cofactor inverse of the authored part frames.
	inverse_part_frames: { Transform },
}

local Geometry = {}
drive.Geometry = Geometry

-- /// SkeletonData Init82BD6C40 builds these inverses once from the real
-- /// PhysicsParamBoneData frames. It does not assume an orthogonal basis.
-- ROBLOX: Result<Self, String> -> Geometry или rt.raise(строка).
function Geometry.new(parents: { number | false }, part_frames: { Transform }): Geometry
	for part = 0, 23 do
		local parent = parents[part + 1]
		local visited = table.create(24, false)
		visited[part + 1] = true
		while parent ~= false do
			local index = parent :: number
			if index >= 24 or visited[index + 1] then
				rt.raise(string.format("Invalid physical ancestor chain for IK part %d", part))
			end
			visited[index + 1] = true
			parent = parents[index + 1]
		end
	end
	local inverses = {}
	for i, frame in part_frames do
		inverses[i] = m.inverse_affine(frame)
	end
	return { parents = table.clone(parents), inverse_part_frames = inverses }
end

-- ROBLOX: Result<(), String> -> rt.raise(строка).
function Geometry.validate_limbs(self: Geometry, bindings: { transforms.LimbBinding })
	for _, binding in bindings do
		local end_ = if binding.parent_part ~= nil then binding.parent_part else binding.part
		local ok = binding.part < 24 and end_ < 24
		if ok then
			local p = self.parents[end_ + 1]
			ok = p ~= false and self.parents[(p :: number) + 1] ~= false
		end
		if not ok then
			rt.raise(string.format("IK part %d has no two-bone physical ancestor chain", end_))
		end
	end
end

local function subtract(a: Vector, b: Vector): Vector
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

local function add_translation(frame: Transform, offset: Vector)
	for lane = 1, 4 do
		frame[4][lane] = f32(frame[4][lane] + offset[lane])
	end
end

function drive.normalize_safe(value: Vector): Vector
	local magnitude = length(value)
	local normalized = normalize(value)
	--830BD350 <-82181A88; no arbitrary fallback axis for a degenerate line.
	if magnitude > from_bits(0x3586_37BD) then
		return normalized
	end
	return { 0.0, 0.0, 0.0, 0.0 }
end
local normalize_safe = drive.normalize_safe

local function line_frame(start: Vector, end_: Vector, normal: Vector): Transform?
	local line = subtract(end_, start)
	local across = cross(line, normal)
	local third = cross(across, line)
	local x = normalize_safe(across)
	local z = normalize_safe(third)
	local y = normalize_safe(line)
	local product = f32(f32(dot3(z, z) * dot3(x, x)) * dot3(y, y))
	--830BD300 <-821647E0, initializer82F82690.
	if product > from_bits(0x3780_0000) then
		return { x, y, z, table.clone(start) }
	end
	return nil
end

-- ///82BF1F20, two82BF1D28 frames and target * rigidInverse(original).
-- ROBLOX: Option<Transform> -> Transform или nil.
function drive.line_mapping(start: Vector, end_: Vector, normal: Vector, new_start: Vector, new_end: Vector, new_normal: Vector): Transform?
	local original = line_frame(start, end_, normal)
	if original == nil then
		return nil
	end
	local target = line_frame(new_start, new_end, new_normal)
	if target == nil then
		return nil
	end
	return compose_affine(target, inverse_rigid(original))
end
local line_mapping = drive.line_mapping

-- ///82BD41B0 clamps a point relative to the original chain root using scalar
-- ///division after the two-refinement length; it is not limit_length's reciprocal.
local function clamp_point(point: Vector, origin: Vector, maximum: number): Vector
	local delta = subtract(point, origin)
	local distance = length(delta)
	if maximum >= distance then
		return point
	end
	local scale = f32(maximum / distance)
	return {
		mul_add(delta[1], scale, origin[1]),
		mul_add(delta[2], scale, origin[2]),
		mul_add(delta[3], scale, origin[3]),
		mul_add(delta[4], scale, origin[4]),
	}
end

-- ///82BF0FA8, using original animation joint centers and mutable volume frames.
local function solve_drives(end_part: number, offset: Vector, maximum_distance: number, geometry: Geometry, original: { Transform }, drives: { Transform }, limits: two_bone.AngleLimits): Vector?
	local middle_part = geometry.parents[end_part + 1]
	if middle_part == false then
		return nil
	end
	local root_part = geometry.parents[(middle_part :: number) + 1]
	if root_part == false then
		return nil
	end
	local mp, rp = middle_part :: number, root_part :: number
	local root, middle, end_ = original[rp + 1][4], original[mp + 1][4], original[end_part + 1][4]
	local requested = {}
	for i = 1, 4 do
		requested[i] = f32(end_[i] + offset[i])
	end
	local target = { value = clamp_point(requested, root, maximum_distance) }
	local solved_middle = { value = { 0.0, 0.0, 0.0, 0.0 } }
	if two_bone.solve(root, middle, end_, solved_middle, target, limits, true, 2) == "Invalid" then
		return nil
	end
	local residual = subtract(target.value, requested)
	local original_normal = cross(subtract(root, middle), subtract(end_, middle))
	local solved_normal = cross(subtract(root, solved_middle.value), subtract(target.value, solved_middle.value))
	local sum = {}
	for i = 1, 4 do
		sum[i] = f32(original_normal[i] + solved_normal[i])
	end
	local normal = normalize_safe(sum)
	local middle_mapping = line_mapping(middle, end_, normal, solved_middle.value, target.value, normal)
	if middle_mapping == nil then
		return nil
	end
	local root_mapping = line_mapping(root, middle, normal, root, solved_middle.value, normal)
	if root_mapping == nil then
		return nil
	end
	drives[rp + 1] = orthonormalize(compose_affine(root_mapping, drives[rp + 1]))
	drives[mp + 1] = orthonormalize(compose_affine(middle_mapping, drives[mp + 1]))
	return residual
end

-- ROBLOX: drives — `&mut [Transform; 24]`, меняется на месте.
function drive.update(statuses: { status.LimbStatus }, frames: { transforms.LimbFrames }, bindings: { transforms.LimbBinding }, geometry: Geometry, original_animation: { Transform }, drives: { Transform }, world_to_animation: Transform, limits: two_bone.AngleLimits): { boolean }
	local updated = { false, false, false, false }
	for limb = 0, 3 do
		local l = limb + 1
		if statuses[l].mode == "Disabled" then
			continue
		end
		local binding = bindings[l]
		local target = compose_affine(world_to_animation, frames[l].world)
		local parent_target = if binding.parent_part ~= nil then compose_affine(world_to_animation, frames[l].parent_world) else nil
		local driven = if binding.parent_part ~= nil then binding.parent_part else binding.part
		local driven_target = if parent_target ~= nil then parent_target else target
		local endpoint = transform_point(driven_target, geometry.inverse_part_frames[driven + 1][4])
		local offset = subtract(endpoint, original_animation[driven + 1][4])
		--82BF01DC..1F4: these are maximum root-to-target distances passed
		--through f1 into82BD41B0, not animation blend weights.
		local maximum_distance = if limb < 2 then from_bits(0x3F4C_CCCD) else 1.0
		local residual = solve_drives(driven, offset, maximum_distance, geometry, original_animation, drives, limits)
		if residual ~= nil then
			drives[binding.part + 1] = copy_transform(target)
			add_translation(drives[binding.part + 1], residual)
			-- The source also adds the same returned delta to retained world
			--targets. Do not insert an extra rotation absent from82BF0458.
			add_translation(frames[l].world, residual)
			local parent = binding.parent_part
			if parent ~= nil then
				drives[parent + 1] = copy_transform(parent_target :: Transform)
				add_translation(drives[parent + 1], residual)
				add_translation(frames[l].parent_world, residual)
			end
			updated[l] = true
		end
	end
	return updated
end

return drive
