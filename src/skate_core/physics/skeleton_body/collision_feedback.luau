--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/collision_feedback.rs (коммит 2e16697)
--
-- SkeletonCollision observations from original TU3 82BD4A30/82BD5DA0.
-- Reports must come from the completed solver, in native report order.

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел.
export type V = { number }

local collision_feedback = {}

-- ROBLOX: SkeletonCollisionSettings описан в collision_mode.luau; здесь тип
-- ослаблен до any, чтобы collision_mode мог подключать этот модуль без цикла.
export type SkeletonFeedbackSettings = {
	body: any,
	-- Fixed physics_collision layout120/124/128/164 consumed by82BD60C8.
	response: CollisionResponseSettings,
	small_object_mass: number,
	ground_plane_max_distance: number,
	ground_plane_max_angle: number,
	skater_scalar: number,
	ai_scalar: number,
	groin_offset: V,
	face_offset: V,
	groin_radius: number,
	face_radius: number,
}

export type SkeletonContactBody = {
	state_flags: number,
	inverse_mass: number,
	linear_velocity: V,
}

-- /// The useful fields of original 96-byte ContactInfo and its solved spy.
-- /// `normal` already has the report-side sign; `solved_vector` is spy+80.
-- ROBLOX: part — индекс части с нуля; other_entity: Option<i32> -> число или nil.
export type SkeletonContactReport = {
	part: number,
	normal: V,
	point: V,
	tag: number,
	other_group: number,
	other_entity: number?,
	body_a: SkeletonContactBody,
	body_b: SkeletonContactBody,
	side_a: boolean,
	solved_vector: V,
}

-- /// Original UpdatePostPhysics82BD80D8 builds these values before Update.
export type SkeletonCollisionInput = {
	dt: number,
	plane_point: V,
	plane_normal: V,
	reference_velocity: V,
	com_velocity: V,
	ragdoll: boolean,
	-- Processed2472 bit0x8000, which suppresses normal ground filtering.
	disable_ground_filter: boolean,
	-- Processed2472 bit0x10000000 selects AISkeletonScalar.
	ai_collision_scalar: boolean,
	-- Category500, excluding states501 and503.
	offboard: boolean,
	entering_offboard: boolean,
	category_600: boolean,
	request_partial_ragdoll: boolean,
	-- ROBLOX: SkeletonPhysicalRecord (record.luau).
	physical: any,
	part_weights: { number },
	-- Actual GetPartTransform frames used by CheckConflictingContacts.
	body_frames: { { V } },
}

export type BoneContact = {
	normal: V,
	specific_normal: V,
	tangent: V,
	specific_tangent: V,
	point: V,
	force: number,
	specific_force: number,
	tag: number,
	specific_tag: number,
	groups: { boolean },
}

local BoneContact = {}
collision_feedback.BoneContact = BoneContact

-- ROBLOX: #[derive(Default)].
function BoneContact.default(): BoneContact
	return {
		normal = { 0.0, 0.0, 0.0, 0.0 },
		specific_normal = { 0.0, 0.0, 0.0, 0.0 },
		tangent = { 0.0, 0.0, 0.0, 0.0 },
		specific_tangent = { 0.0, 0.0, 0.0, 0.0 },
		point = { 0.0, 0.0, 0.0, 0.0 },
		force = 0.0,
		specific_force = 0.0,
		tag = 0,
		specific_tag = 0,
		groups = { false, false, false, false },
	}
end

-- ROBLOX: part: Option<usize> -> индекс с нуля или nil.
export type ContactRegion = {
	force: number,
	weighted_force: number,
	tangent_speed: number,
	material_flags: number,
	normal: V,
	part: number?,
}

local ContactRegion = {}
collision_feedback.ContactRegion = ContactRegion

function ContactRegion.default(): ContactRegion
	return {
		force = 0.0,
		weighted_force = 0.0,
		tangent_speed = 0.0,
		material_flags = 0,
		normal = { 0.0, 0.0, 0.0, 0.0 },
		part = nil,
	}
end

export type ContactPlane = {
	normal: V,
	part: number,
}

export type SpecificContact = {
	part: number,
	local_point: V,
	world_point: V,
	radius_squared: number,
	current: boolean,
	recent: boolean,
}

export type SkeletonContactFlags = {
	material_6: boolean,
	noncompliant: boolean,
	-- Native4070.
	compliant: boolean,
	recovering: boolean,
	group_8: boolean,
	nonboard: boolean,
	ragdoll: boolean,
	conflicting: boolean,
	impaled: boolean,
	-- Native4077. This does not itself contain the pose-error vector16272.
	has_impulse: boolean,
	foot_board: boolean,
	material_10: boolean,
	material_11: boolean,
	material_12: boolean,
	any: boolean,
}

local SkeletonContactFlags = {}
collision_feedback.SkeletonContactFlags = SkeletonContactFlags

function SkeletonContactFlags.default(): SkeletonContactFlags
	return {
		material_6 = false,
		noncompliant = false,
		compliant = false,
		recovering = false,
		group_8 = false,
		nonboard = false,
		ragdoll = false,
		conflicting = false,
		impaled = false,
		has_impulse = false,
		foot_board = false,
		material_10 = false,
		material_11 = false,
		material_12 = false,
		any = false,
	}
end

export type SkeletonCollisionFeedback = {
	settings: SkeletonFeedbackSettings,
	contact_age: { number },
	priority: { number },
	compliant: { boolean },
	current: { boolean },
	bones: { BoneContact },
	regions: { ContactRegion },
	planes: { ContactPlane },
	specific: { SpecificContact },
	highest_normal: V,
	foot_normal: V,
	material_normals: { V },
	timer: number,
	-- Native4028. Reset is zero; Update recovers toward one.
	drive_weight: number,
	maximum_priority: number,
	wipeout_times: { number },
	maximum_skater_force: number,
	other_skater: number,
	maximum_group_8_force: number,
	maximum_group_11_force: number,
	material_12_height: number,
	flags: SkeletonContactFlags,
}

local SkeletonCollisionFeedback = {}
collision_feedback.SkeletonCollisionFeedback = SkeletonCollisionFeedback

local function many<T>(n: number, make: () -> T): { T }
	local t = table.create(n)
	for i = 1, n do
		t[i] = make()
	end
	return t
end

-- /// Constructor82BD5F48/6038 plus the final Body constructor Reset. Static
-- /// compliant settings survive Reset, while the priority array is cleared.
function SkeletonCollisionFeedback.new(settings: SkeletonFeedbackSettings): SkeletonCollisionFeedback
	local specific = {}
	for _, s in { { 23, settings.groin_offset, settings.groin_radius }, { 1, settings.face_offset, settings.face_radius } } do
		local radius = s[3] :: number
		table.insert(specific, {
			part = s[1] :: number,
			local_point = table.clone(s[2] :: V),
			world_point = { 0.0, 0.0, 0.0, 0.0 },
			radius_squared = f32(radius * radius),
			current = false,
			recent = false,
		})
	end
	return {
		settings = settings,
		contact_age = table.create(24, 0.0),
		priority = table.create(24, 0.0),
		compliant = table.clone(settings.body.compliant),
		current = table.create(24, false),
		bones = many(24, BoneContact.default),
		regions = many(8, ContactRegion.default),
		planes = {},
		specific = specific,
		highest_normal = { 0.0, 1.0, 0.0, 0.0 },
		foot_normal = { 0.0, 1.0, 0.0, 0.0 },
		material_normals = { { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } },
		timer = 0.0,
		drive_weight = 0.0,
		maximum_priority = 0.0,
		wipeout_times = { 0.0, 0.0, 0.0 },
		maximum_skater_force = 0.0,
		other_skater = -1,
		maximum_group_8_force = 0.0,
		maximum_group_11_force = 0.0,
		material_12_height = 0.0,
		flags = SkeletonContactFlags.default(),
	}
end

-- ///82BD5DA0 preserves compliant settings, specific-point histories and4082.
-- ROBLOX: `*self = Self::new(..)` -> перезапись полей той же таблицы.
function SkeletonCollisionFeedback.reset(self: SkeletonCollisionFeedback)
	local specific = self.specific
	local compliant = self.compliant
	local any = self.flags.any
	local fresh = SkeletonCollisionFeedback.new(self.settings) :: any
	for k, v in fresh do
		(self :: any)[k] = v
	end
	self.specific = specific
	self.compliant = compliant
	self.flags.any = any
end

-- /// SetUpNormal82BE7280 calls Reset before reinstalling authored priority
-- /// and compliant settings. A subsequent constructor Reset clears priority.
function SkeletonCollisionFeedback.set_up_normal(self: SkeletonCollisionFeedback)
	SkeletonCollisionFeedback.reset(self)
	self.priority = table.clone(self.settings.body.priority)
	self.compliant = table.clone(self.settings.body.compliant)
end

-- /// Fixed-layout physics_collision tuning for SkeletonCollision::Fill82BD60C8.
export type CollisionResponseSettings = {
	force_scale: number,
	velocity_scale: number,
	divisor: number,
	region_scale: number,
}

-- /// Fill82BD60C8 accumulates these responses after contact traversal, then
-- /// publishes them to Collision196/200 and the eight normalized region words.
function SkeletonCollisionFeedback.fill_response(self: SkeletonCollisionFeedback, physical: any, weights: { number }): { number }
	local velocities = table.move(physical.velocities, 1, 24, 1, {})
	return collision_feedback.collision_response(self.settings.response, self.wipeout_times, self.regions, velocities, weights)
end

-- /// The arithmetic block of82BD60C8. The fourth vector lane is not part of either dot.
-- ROBLOX: accumulated — `&mut [f32; 3]`, таблица меняется на месте.
function collision_feedback.collision_response(t: CollisionResponseSettings, accumulated: { number }, regions: { ContactRegion }, velocities: { V }, weights: { number }): { number }
	-- vmsum3fp128 pairs guest x/y, then adds guest z/zero. Each multiplication
	-- rounds before addition; fmadds below is independently fused.
	local function dot(a: V, b: V): number
		return f32(f32(f32(a[1] * b[1]) + f32(a[2] * b[2])) + f32(a[3] * b[3]))
	end
	local function positive(v: number): number
		return if -v >= 0.0 then 0.0 else v
	end
	local function clamp(v_in: number): number
		local v = positive(v_in)
		return if f32(1.0 - v) >= 0.0 then v else 1.0
	end
	local output = table.create(8, 0.0)
	for i = 1, 8 do
		local r = regions[i]
		local part = r.part
		if part == nil then
			output[i] = 0.0
			continue
		end
		local v = velocities[part + 1]
		local speed = if dot(v, v) <= from_bits(0x3dcc_cccd) then 0.0 else 1.0
		local force = if r.force <= 0.5 then 0.0 else 1.0
		local inverse = f32(1.0 / t.divisor)
		local normal_speed = math.abs(dot(v, r.normal))
		accumulated[2] = mul_add(f32(f32(inverse * t.force_scale) * force), r.force, accumulated[2])
		accumulated[1] = mul_add(f32(f32(inverse * t.velocity_scale) * normal_speed), speed, accumulated[1])
		local value = f32(f32(normal_speed * weights[part + 1]) * t.region_scale)
		local floor = from_bits(0x3a83_126f)
		output[i] = clamp(if f32(floor - value) >= 0.0 then floor else value)
	end
	accumulated[1] = clamp(accumulated[1])
	accumulated[2] = clamp(accumulated[2])
	return output
end

return collision_feedback
