--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/collision_update.rs (коммит 2e16697)
--
-- Complete contact traversal and classification of TU3 82BD4A30.
-- ROBLOX: `impl SkeletonCollisionFeedback` в другом файле -> функция update
-- добавляется в таблицу SkeletonCollisionFeedback при загрузке модуля.

local rt = require("../../../rt")
local collision_feedback = require("./collision_feedback")
local cv = require("./collision_vector")

local f32 = rt.f32
local from_bits = rt.from_bits
local add, clamp_length, cross, dot, length, normalize, scale, sub, transform = cv.add, cv.clamp_length, cv.cross, cv.dot, cv.length, cv.normalize, cv.scale, cv.sub, cv.transform

type V = collision_feedback.V
type SkeletonCollisionFeedback = collision_feedback.SkeletonCollisionFeedback
type SkeletonCollisionInput = collision_feedback.SkeletonCollisionInput
type SkeletonContactReport = collision_feedback.SkeletonContactReport
type SkeletonContactBody = collision_feedback.SkeletonContactBody

local SkeletonCollisionFeedback = collision_feedback.SkeletonCollisionFeedback
local BoneContact = collision_feedback.BoneContact
local SkeletonContactFlags = collision_feedback.SkeletonContactFlags

local collision_update = {}

-- Original read-only table820CFCB0. Part0 is not a region participant.
-- ROBLOX: usize::MAX -> -1; значения — индексы регионов с нуля.
local REGIONS = {
	-1, 0, 1, 2, 2, 2, 1, 3, 3, 3, 1, 1, 1, 1, 1, 6, 6, 4, 4, 7, 7, 5, 5, 1,
}

local function mass(body: SkeletonContactBody): number
	return f32(1.0 / (if body.state_flags == 1 then f32(0.001) else body.inverse_mass))
end

local function maximum(a: number, b: number): number
	return if f32(a - b) >= 0.0 then a else b
end

local function begin_frame(self: SkeletonCollisionFeedback, input: SkeletonCollisionInput)
	self.timer = f32(self.timer - input.dt)
	self.wipeout_times[3] = f32(self.wipeout_times[3] + input.dt)
	local flags = SkeletonContactFlags.default()
	flags.ragdoll = input.ragdoll
	self.flags = flags
	table.clear(self.planes)
	self.maximum_priority = 0.0
	self.maximum_skater_force = 0.0
	self.other_skater = -1
	self.maximum_group_8_force = 0.0
	self.maximum_group_11_force = 0.0
	self.material_12_height = 0.0
	self.highest_normal = { 0.0, -1.0, 0.0, 0.0 }
	self.foot_normal = { 0.0, 0.0, 0.0, 0.0 }
	self.material_normals = { { 0.0, -1.0, 0.0, 0.0 }, { 0.0, -1.0, 0.0, 0.0 } }
	for part = 1, 24 do
		self.contact_age[part] = f32(self.contact_age[part] - input.dt)
		self.current[part] = false
		self.bones[part] = BoneContact.default()
	end
	for i, region in self.regions do
		-- Unlike Reset, Update leaves the material flag untouched.
		local fresh = collision_feedback.ContactRegion.default()
		fresh.material_flags = region.material_flags
		self.regions[i] = fresh
	end
	if not input.ragdoll then
		self.wipeout_times = { 0.0, 0.0, 0.0 }
	end
	for _, point in self.specific do
		point.recent = point.recent and input.ragdoll
		point.current = false
		point.world_point = transform(input.physical.pose[point.part + 1], point.local_point)
	end
	if input.request_partial_ragdoll then
		self.timer = self.settings.body.effect_time
	end
end

local function ignore_ground(self: SkeletonCollisionFeedback, input: SkeletonCollisionInput, report: SkeletonContactReport): boolean
	if input.ragdoll or (input.disable_ground_filter and not input.category_600) then
		return false
	end
	local distance = dot(input.plane_normal, sub(report.point, input.plane_point))
	local threshold = if input.offboard then f32(0.3) else self.settings.ground_plane_max_distance
	return distance < threshold and (input.offboard or math.abs(dot(report.normal, input.plane_normal)) > self.settings.ground_plane_max_angle)
end

local function observe_normal(self: SkeletonCollisionFeedback, ragdoll: boolean, report: SkeletonContactReport, material: number)
	local normal = report.normal
	if normal[2] > self.highest_normal[2] then
		self.highest_normal = normal
	end
	if ragdoll then
		if material == 10 and normal[2] > self.material_normals[1][2] then
			self.material_normals[1] = normal
			self.flags.material_10 = true
		elseif material == 11 and normal[2] > self.material_normals[2][2] then
			self.material_normals[2] = normal
			self.flags.material_11 = true
		end
	elseif (report.part == 15 or report.part == 19) and normal[2] > self.foot_normal[2] then
		self.foot_normal = normal
	end
end

local function record_force(self: SkeletonCollisionFeedback, report: SkeletonContactReport, specific: boolean, relative: V, force: number, weighted_force: number)
	local bone = self.bones[report.part + 1]
	local region_index = REGIONS[report.part + 1] + 1
	local region = self.regions[region_index]
	local previous = if specific then bone.specific_force else bone.force
	local tangent = if force > previous or force > region.force then cross(relative, report.normal) else { 0.0, 0.0, 0.0, 0.0 }
	if force > previous then
		if specific then
			bone.specific_force = force
			bone.specific_normal = report.normal
			bone.specific_tangent = tangent
			bone.specific_tag = report.tag
		else
			bone.force = force
			bone.normal = report.normal
			bone.tangent = tangent
			bone.point = report.point
			bone.tag = report.tag
		end
		local g = report.other_group
		bone.groups[1] = bone.groups[1] or g == 8
		bone.groups[2] = bone.groups[2] or g == 11
		bone.groups[3] = bone.groups[3] or g == 5
		bone.groups[4] = bone.groups[4] or not (g == 8 or g == 11 or g == 5)
	end
	if force > region.force then
		self.regions[region_index] = {
			force = force,
			weighted_force = weighted_force,
			tangent_speed = length(tangent),
			material_flags = bit32.band(report.tag, 0x7f),
			normal = report.normal,
			part = report.part,
		}
	end
end

-- /// Original82BD5770 calls GetPartTransform, not animation-pose lookup.
local function check_conflicting(self: SkeletonCollisionFeedback, input: SkeletonCollisionInput): boolean
	for i, a in self.regions do
		local part_a = a.part
		if part_a == nil then
			continue
		end
		if not (a.force > 0.0) or not self.compliant[part_a + 1] then
			continue
		end
		for j, b in self.regions do
			local part_b = b.part
			if part_b == nil then
				continue
			end
			if i == j or not (b.force > 0.0) or not self.compliant[part_b + 1] then
				continue
			end
			if dot(a.normal, b.normal) < f32(-0.7) and dot(sub(input.body_frames[part_b + 1][4], input.body_frames[part_a + 1][4]), a.normal) < 0.0 then
				return true
			end
		end
	end
	return false
end

local function check_impaled(self: SkeletonCollisionFeedback): boolean
	for i = 1, 22 do
		local a = self.bones[i + 1]
		if not (a.force > 0.0) then
			continue
		end
		for k = i + 2, 24 do
			local b = self.bones[k]
			if b.force > 0.0 and dot(a.normal, b.normal) < f32(-0.99) and math.abs(dot(a.normal, sub(a.point, b.point))) < f32(0.03) then
				return true
			end
		end
	end
	return false
end

function collision_update.update(self: SkeletonCollisionFeedback, input: SkeletonCollisionInput, reports: { SkeletonContactReport })
	begin_frame(self, input)
	local reference_speed = length(input.reference_velocity)
	local direction = normalize(input.reference_velocity)
	for _, report in reports do
		-- Original constructor enables reports for the24 animated parts.
		-- A different owner must not silently index this state as part24/25.
		assert(report.part < 24, "SkeletonCollision report part exceeds native24-part array")
		local part = report.part
		local p = part + 1
		local material = bit32.band(bit32.rshift(report.tag, 7), 31)
		self.flags.any = true
		if report.other_group == 4 and (part == 15 or part == 16 or part == 19 or part == 20) then
			self.flags.foot_board = true
		end
		if material == 6 then
			self.flags.material_6 = true
		end
		if material == 12 then
			self.flags.material_12 = true
			self.material_12_height = report.point[2]
		end
		if ignore_ground(self, input, report) then
			continue
		end
		observe_normal(self, input.ragdoll, report, material)
		local specific = false
		for _, point in self.specific do
			local delta = sub(report.point, point.world_point)
			if part == point.part and dot(delta, delta) < point.radius_squared then
				point.current = true
				point.recent = true
				specific = true
			end
		end
		-- This gate precedes priority replacement and all force recording.
		if #self.planes >= 20 then
			continue
		end
		self.contact_age[p] = 0.0
		self.current[p] = true
		if self.priority[p] > self.maximum_priority then
			self.maximum_priority = self.priority[p]
			table.clear(self.planes)
		end
		if self.priority[p] == self.maximum_priority then
			table.insert(self.planes, { normal = report.normal, part = part })
		end

		local mass_a = mass(report.body_a)
		local mass_b = mass(report.body_b)
		local other_mass = if report.side_a then mass_b else mass_a
		local small = other_mass > f32(0.0001) and other_mass < self.settings.small_object_mass
		local factor = f32(f32(f32(mass_b + mass_a) / f32(mass_b * mass_a)) * from_bits(0x3991_A2B5))
		local weighted_force = f32(length(scale(report.solved_vector, factor)) * input.part_weights[p])
		local part_velocity = input.physical.velocities[p]
		local own_velocity
		if input.ragdoll then
			own_velocity = scale(add(input.com_velocity, part_velocity), 0.5)
		elseif input.offboard or input.entering_offboard then
			own_velocity = table.clone(input.com_velocity)
			own_velocity[2] = 0.0
		else
			local projected = scale(direction, dot(part_velocity, direction))
			own_velocity = clamp_length(projected, reference_speed)
		end
		local other = if report.side_a then report.body_b else report.body_a
		local relative = sub(other.linear_velocity, own_velocity)
		local force = math.abs(dot(relative, report.normal))
		if small then
			force = f32(force * 0.5)
		end
		local group = report.other_group
		if group == 5 then
			force = f32(force * (if input.ai_collision_scalar then self.settings.ai_scalar else self.settings.skater_scalar))
			self.maximum_skater_force = maximum(self.maximum_skater_force, force)
			if report.other_entity ~= nil then
				self.other_skater = report.other_entity
			end
			self.flags.nonboard = true
		elseif group == 8 then
			self.flags.group_8 = true
			self.maximum_group_8_force = maximum(self.maximum_group_8_force, force)
			self.flags.nonboard = true
		elseif group == 11 then
			self.maximum_group_11_force = maximum(self.maximum_group_11_force, force)
			self.flags.nonboard = true
		elseif group == 4 then
			-- ()
		else
			self.flags.nonboard = true
		end
		if part > 0 then
			record_force(self, report, specific, relative, force, weighted_force)
			self.timer = self.settings.body.effect_time
		end
		if not self.compliant[p] or small then
			self.flags.noncompliant = true
		else
			self.flags.compliant = true
		end
		self.flags.has_impulse = self.flags.compliant or input.offboard
	end
	if input.ragdoll then
		self.flags.impaled = check_impaled(self)
	else
		self.flags.conflicting = check_conflicting(self, input)
	end
	local duration = self.settings.body.effect_time
	if duration == 0.0 then
		self.drive_weight = 1.0
	else
		local ratio = f32(self.timer / duration)
		local low = if -ratio >= 0.0 then 0.0 else ratio
		self.drive_weight = f32(1.0 - (if f32(1.0 - low) >= 0.0 then low else 1.0))
	end
	self.flags.recovering = self.drive_weight < 1.0
end

-- ROBLOX: метод impl-блока.
;(SkeletonCollisionFeedback :: any).update = collision_update.update

return collision_update
