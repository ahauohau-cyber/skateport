--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/collision_mode.rs (коммит 2e16697)
--
-- Original normal body setup82BE7280 and driven selector82D913C0 modes1/5/6.
-- Collision volume groups and part metadata are distinct from body state bits.

local rt = require("../../../rt")
local rigid_body = require("../rigid_body")
local collision_feedback = require("./collision_feedback")

local f32 = rt.f32
local world_inverse_inertia = rigid_body.world_inverse_inertia

-- ROBLOX: константы из mod.rs продублированы, чтобы не было циклического require.
local ANIMATION_PART_COUNT = 24
local PART_COUNT = 26

local collision_mode = {}

-- ROBLOX: RetailContactMaterial — таблица { static_friction, dynamic_friction, restitution }.
type RetailContactMaterial = { static_friction: number, dynamic_friction: number, restitution: number }

export type SkeletonCollisionSettings = {
	enabled: boolean,
	normal_material: RetailContactMaterial,
	-- Original collision classification settings copied by82BE745C/7468.
	-- ROBLOX: массивы по части; индекс части с нуля -> [part + 1].
	compliant: { boolean },
	priority: { number },
	effect_time: number,
}

export type SkeletonPartCollision = {
	-- Volume+92 bit0. Other volume flags are owned by geometry construction.
	enabled: boolean,
	-- Volume+84; group4 is written by DisableCollisionWithWorld.
	volume_group: number,
	-- Original Part+92, distinct from its volume group.
	part_group: number,
	material: RetailContactMaterial,
}

export type SkeletonCollisionMode = {
	parts: { SkeletonPartCollision },
	disable_count: { number },
	-- Original Body8224 gates postphysics countdown/reenabling.
	pending_reenable: boolean,
	assembly_group: number,
	partial_ragdoll: boolean,
	is_ragdoll: boolean,
	settings: SkeletonCollisionSettings,
	--82BE82C0 table: true suppresses this pair before geometric collision.
	-- ROBLOX: self_culling[a + 1][b + 1].
	self_culling: { { boolean } },
	normal_self_culling: { { boolean } },
}

local SkeletonCollisionMode = {}
collision_mode.SkeletonCollisionMode = SkeletonCollisionMode

local function material_copy(m: RetailContactMaterial): RetailContactMaterial
	return { static_friction = m.static_friction, dynamic_friction = m.dynamic_friction, restitution = m.restitution }
end

local function all_true(): { { boolean } }
	local t: { { boolean } } = table.create(PART_COUNT) :: any
	for a = 1, PART_COUNT do
		t[a] = table.create(PART_COUNT, true)
	end
	return t
end

local function copy_table2(t: { { boolean } }): { { boolean } }
	local c: { { boolean } } = table.create(#t) :: any
	for i, row in t do
		c[i] = table.clone(row)
	end
	return c
end

-- ROBLOX: fn set_group/disable_root/enable_eligible_bones/select_biped — приватные.
local function set_group(self: SkeletonCollisionMode, group: number)
	self.assembly_group = group
	for _, part in self.parts do
		part.part_group = group
	end
end

local function disable_root(self: SkeletonCollisionMode)
	self.parts[1].volume_group = 4
	self.parts[1].enabled = false
	self.disable_count[1] = 0
end

local function enable_eligible_bones(self: SkeletonCollisionMode)
	for part = 1, 23 do
		if self.disable_count[part + 1] == 0 then
			self.parts[part + 1].enabled = true
			self.parts[part + 1].volume_group = 0
		end
	end
end

-- ///82D91298: Body volume pointers start at3092, counters at8128.
-- /// The stores at3120/3104/3124/3108/3096 therefore select parts7/3/8/4/1:
-- /// both hands, both forearms and the head, not the next bone in each chain.
function SkeletonCollisionMode.disable_handplant_contacts(self: SkeletonCollisionMode, frames: number)
	self.pending_reenable = true
	for _, part in { 7, 3, 8, 4, 1 } do
		self.disable_count[part + 1] = frames
		self.parts[part + 1].enabled = false
	end
end

-- ///82BE7078, used by the real teleport path82BE3508. Collision volume
-- ///enabled flags and materials survive this reset.
function SkeletonCollisionMode.reset_body_state(self: SkeletonCollisionMode, feedback: collision_feedback.SkeletonCollisionFeedback)
	self.is_ragdoll = false
	collision_feedback.SkeletonCollisionFeedback.reset(feedback)
	self.disable_count = table.create(ANIMATION_PART_COUNT, 0)
	self.pending_reenable = false
end

-- /// Full normal constructor state after82BE4290 and SetUpNormal. The final
-- /// argument is the actual constructor byte8227, not a guessed AI identity.
function SkeletonCollisionMode.new_normal(settings: SkeletonCollisionSettings, cull_all_self_pairs: boolean): SkeletonCollisionMode
	--82BE5130..5164 assigns this zero material to parts0,24,25.
	local zero = { static_friction = 0.0, dynamic_friction = 0.0, restitution = 0.0 }
	local parts: { SkeletonPartCollision } = table.create(PART_COUNT) :: any
	for part = 0, PART_COUNT - 1 do
		parts[part + 1] = {
			enabled = false,
			volume_group = if part == 0 then 4 else 0,
			part_group = 5,
			material = if part >= 1 and part < 24 then material_copy(settings.normal_material) else material_copy(zero),
		}
	end
	local result: SkeletonCollisionMode = {
		parts = parts,
		disable_count = table.create(ANIMATION_PART_COUNT, 0),
		pending_reenable = false, --82BE4660, following the24 counter clears.
		assembly_group = 5,
		partial_ragdoll = false,
		is_ragdoll = false,
		settings = settings,
		self_culling = all_true(),
		normal_self_culling = all_true(),
	}
	if not cull_all_self_pairs then
		for _, pair in { { 14, 4 }, { 14, 8 }, { 23, 4 }, { 23, 8 }, { 4, 18 }, { 8, 22 } } do
			local a, b = pair[1], pair[2]
			result.self_culling[a + 1][b + 1] = false
			result.self_culling[b + 1][a + 1] = false
		end
	end
	if settings.enabled then
		SkeletonCollisionMode.normal_collision(result)
	else
		SkeletonCollisionMode.disable_all(result, true)
	end
	result.normal_self_culling = copy_table2(result.self_culling)
	return result
end

local function enable_bone(self: SkeletonCollisionMode, part: number)
	SkeletonCollisionMode.enable_bone(self, part)
end

-- ///Request4 branch82D914B0 and Body82BE5248. Existing physical masses,
-- ///joint limits, material and self-pair table survive this policy change.
local function select_biped(self: SkeletonCollisionMode)
	set_group(self, 6)
	SkeletonCollisionMode.disable_all(self, false)
	for _, part in { 17, 21, 15, 19, 16, 20 } do
		enable_bone(self, part)
		self.parts[part + 1].part_group = 17
	end
	for _, part in { 5, 4, 3, 9, 8, 7, 2, 1 } do
		enable_bone(self, part)
	end
	for _, part in { 6, 10, 11, 12, 13, 14, 23 } do
		enable_bone(self, part)
		self.parts[part + 1].part_group = 18
	end
	self.partial_ragdoll = true
	for _, part in { 24, 25 } do
		self.parts[part + 1].part_group = 20
		self.parts[part + 1].enabled = true
	end
end

-- ///Normal riding and ascending-Air collision. Mode6 calls82BE3700, whose
-- ///root/extra disabling, group5 and eligible-bone writes match mode5's result.
-- ROBLOX: Result<(), &str> -> rt.raise(строка).
function SkeletonCollisionMode.select_driven(self: SkeletonCollisionMode, mode: number)
	if mode == 3 then
		select_biped(self)
		return
	elseif mode == 5 or mode == 6 then
		SkeletonCollisionMode.normal_collision(self)
	elseif mode == 1 then
		--82BE3808 enables eligible bones before switching the group.
		enable_eligible_bones(self)
		set_group(self, 3)
	else
		rt.raise("Skeleton collision selector requires its non-driven physical setup")
	end
	self.partial_ragdoll = false
	disable_root(self)
	self.parts[25].enabled = false
	self.parts[26].enabled = false
end

-- ///82BE70D8. Does not consult BoneHasCollision, clear positive disable
-- ///counts, alter materials or disable the two extra volumes.
function SkeletonCollisionMode.normal_collision(self: SkeletonCollisionMode)
	set_group(self, 5)
	disable_root(self)
	enable_eligible_bones(self)
end

-- ///82BE6FF8. Bone volume group values survive this operation.
function SkeletonCollisionMode.disable_all(self: SkeletonCollisionMode, clear_counts: boolean)
	disable_root(self)
	self.parts[25].enabled = false
	self.parts[26].enabled = false
	for part = 1, 23 do
		self.parts[part + 1].enabled = false
		if clear_counts then
			self.disable_count[part + 1] = 0
		end
	end
end

-- ///82BE7190. This operation tests the counter but does not decrement it.
function SkeletonCollisionMode.enable_bone(self: SkeletonCollisionMode, part: number)
	if self.disable_count[part + 1] == 0 then
		self.parts[part + 1].enabled = true
		self.parts[part + 1].volume_group = 0
	end
	self.parts[part + 1].part_group = 5
end

-- ///82BD8364..83BC runs after collision observations and before82BD9FB0.
-- /// It only changes the enabled bit, preserving each volume's group.
function SkeletonCollisionMode.finish_contact_frame(self: SkeletonCollisionMode)
	if not self.pending_reenable then
		return
	end
	local remaining = false
	for part = 1, ANIMATION_PART_COUNT do
		-- ROBLOX: `as i32` -> rt.to_i32.
		if rt.to_i32(self.disable_count[part]) > 0 then
			self.disable_count[part] -= 1
			local enabled = self.disable_count[part] == 0
			self.parts[part].enabled = enabled
			remaining = remaining or not enabled
		end
	end
	self.pending_reenable = remaining
end

-- ///82BE71F0, unlike the whole-body normal path, uses BoneHasCollision.
function SkeletonCollisionMode.normal_bone(self: SkeletonCollisionMode, part: number, has_collision: boolean)
	if has_collision then
		if self.disable_count[part + 1] == 0 then
			self.parts[part + 1].enabled = true
			self.parts[part + 1].volume_group = 0
		end
	else
		self.parts[part + 1].enabled = false
		self.parts[part + 1].volume_group = 4
		self.disable_count[part + 1] = 0
	end
end

local function spherical(tensor: vector): number
	local minimum = tensor.x
	if minimum >= tensor.y then
		minimum = tensor.y
	end
	if minimum >= tensor.z then
		minimum = tensor.z
	end
	return f32(1.0 / minimum)
end

-- /// Physical-property portion of82BE7280. The coordinator separately resets
-- /// the real SkeletonCollision observations and reinstalls normal joint
-- /// limits in that method's original order. This method does not fake either.
-- ROBLOX: skeleton — SkeletonBody (runtime.luau); поля definition и bodies.
function SkeletonCollisionMode.restore_normal_properties(self: SkeletonCollisionMode, skeleton: any)
	self.self_culling = copy_table2(self.normal_self_culling)
	set_group(self, 5)
	for part = 0, PART_COUNT - 1 do
		local animated = skeleton.definition.parts[part + 1]
		local body = skeleton.bodies[part + 1]
		body.inertia.linear_drag = 0.0
		body.inertia.angular_drag = 0.0
		if part >= 1 and part < 24 then
			body.inertia.inverse_mass = animated.inverse_mass_animated
			body.inertia.inverse_tensor = animated.animated.dynamics.inverse_tensor
			local tensor = body.inertia.inverse_tensor
			body.inertia.spherical = spherical(tensor)
			body.rates.world_inverse_inertia = world_inverse_inertia(body.rates.basis, tensor)
			self.parts[part + 1].material = material_copy(self.settings.normal_material)
		end
	end
	if self.settings.enabled then
		SkeletonCollisionMode.normal_collision(self)
	else
		SkeletonCollisionMode.disable_all(self, true)
	end
	self.is_ragdoll = false
end

--Exact raw82BE8900..A664 stores, not the asymmetric decompiler output.
local CULLED = {
	0x03FFFFFF, 0x03FFF447, 0x03FFFC47, 0x039B8479, 0x03BB8479, 0x039F8479, 0x03FFFFFF,
	0x03B987C1, 0x03BB87C1, 0x03F987C1, 0x03FFFFFF, 0x03FFFC45, 0x03FFFC47, 0x03FFFC47,
	0x03FFFC47, 0x03FFFFFF, 0x038FFFFF, 0x038FFD7F, 0x03CFFC67, 0x03FFFFFF, 0x03F8FFFF,
	0x03F8FFD7, 0x03FCFE47, 0x03FFFFFF, 0x03FFFFFF, 0x03FFFFFF,
}

-- ///Physical properties of82BE6D60; joint limits are set first by its caller.
function SkeletonCollisionMode.apply_ragdoll_properties(self: SkeletonCollisionMode, skeleton: any, inverse_mass: boolean, inverse_inertia: boolean, drag: { number }, materials: { RetailContactMaterial })
	--Constructor byte8227 selects the all-culled table for both modes.
	local all = true
	for _, row in self.normal_self_culling do
		for _, culled in row do
			if not culled then
				all = false
			end
		end
	end
	if all then
		self.self_culling = all_true()
	else
		local t: { { boolean } } = table.create(PART_COUNT) :: any
		for a = 1, PART_COUNT do
			local row = table.create(PART_COUNT) :: any
			for b = 0, PART_COUNT - 1 do
				row[b + 1] = bit32.band(CULLED[a], bit32.lshift(1, b)) ~= 0
			end
			t[a] = row
		end
		self.self_culling = t
	end
	set_group(self, 6)
	for _, body in skeleton.bodies do
		body.inertia.linear_drag = drag[1]
		body.inertia.angular_drag = drag[2]
	end
	for part = 1, 23 do
		local authored = skeleton.definition.parts[part + 1]
		local body = skeleton.bodies[part + 1]
		self.disable_count[part + 1] = 0
		self.parts[part + 1].enabled = true
		self.pending_reenable = false
		self.parts[part + 1].material = material_copy(materials[if part == 1 or part == 3 or part == 7 then 2 else 1])
		if inverse_mass then
			body.inertia.inverse_mass = authored.inverse_mass_ragdoll
		end
		if inverse_inertia then
			local tensor = authored.ragdoll.dynamics.inverse_tensor
			body.inertia.inverse_tensor = tensor
			body.inertia.spherical = spherical(tensor)
		end
		body.rates.world_inverse_inertia = world_inverse_inertia(body.rates.basis, body.inertia.inverse_tensor)
	end
	self.is_ragdoll = true
end

-- ///The post-body portions of original selector modes7..10.
function SkeletonCollisionMode.finish_ragdoll_request(self: SkeletonCollisionMode, mode: number)
	if mode == 7 or mode == 10 then
		--Skeleton82BE3350 clears partial mode, root and extra volumes.
		self.partial_ragdoll = false
		disable_root(self)
		self.parts[25].enabled = false
		self.parts[26].enabled = false
	elseif mode == 8 then
		--82D915A0..C4 uses constructor material3076 for all bones.
		for part = 1, 23 do
			self.parts[part + 1].material = { static_friction = 0.5, dynamic_friction = f32(0.3), restitution = f32(0.4) }
		end
	elseif mode == 9 then
		set_group(self, 7)
	else
		error("Only original Wipeout requests8..11 enter this adapter")
	end
end

return collision_mode
