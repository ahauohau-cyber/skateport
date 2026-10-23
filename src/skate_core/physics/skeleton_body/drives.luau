--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/drives.rs (коммит 2e16697)
--
-- Original SkeletonDrives82BEA670/82BEB488: two channels per physical bone
-- and four independent static targets, all solved in the same island.

local rt = require("../../../rt")
local assembly = require("../assembly")
local normalization = require("../board_pose/normalization")
local df = require("../drive_frames")
local drive_solver = require("../drive_solver")
local rigid_body = require("../rigid_body")
local sar = require("../skeleton_animation_record")
local skeleton_root = require("../skeleton_root")
local drive_dynamics = require("./drive_dynamics")
local bone_frames = require("./drive_frames")
local targets_mod = require("./targets")

local mul_add = rt.mul_add
local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local compose_affine = sar.compose_affine
local inverse_rigid = skeleton_root.inverse_rigid
local bone_drive_frames = bone_frames.bone_drive_frames
local prepare_bone_drive_frames = bone_frames.prepare_bone_drive_frames
local BoneDriveDynamics = drive_dynamics.BoneDriveDynamics
local SkeletonTargets = targets_mod.SkeletonTargets
local hard = targets_mod.hard
local HARD_STRENGTH = targets_mod.HARD_STRENGTH
local HARD_VELOCITY = targets_mod.HARD_VELOCITY
local TARGET_PARTS = targets_mod.TARGET_PARTS
local TARGET_COUNT = targets_mod.TARGET_COUNT

type AnimationPartTransform = sar.AnimationPartTransform
type BodySnapshot = assembly.BodySnapshot

-- ROBLOX: константы из mod.rs продублированы, чтобы не было циклического require.
local ANIMATION_PART_COUNT = 24

local drives = {}

export type SkeletonDriveSettings = {
	bone: drive_dynamics.BoneDriveSettings,
	enabled: boolean,
	strength: { number },
	-- InitAttribData82BE7860 applies CollisionDriveScalar to each part's
	-- LOCAL and LOCAL_ROOT collision strengths before use in Update.
	collision_strength: { { number } },
}

-- ROBLOX: parent — индексы частей с нуля.
export type BoneDrives = {
	parent: { number },
	active: { boolean },
	frames: { df.RetailDriveFrames },
	dynamics: drive_dynamics.BoneDriveDynamics,
}

-- ROBLOX: bones: [Option<BoneDrives>; 24] -> массив, где отсутствие — false.
export type SkeletonDrives = {
	targets: targets_mod.SkeletonTargets,
	bones: { BoneDrives | false },
	settings: SkeletonDriveSettings,
}

-- /// Identity stays parallel to eligible rows. Native m_spy requests force
-- /// observation; it does not disable a drive or remove it from the solve.
-- ROBLOX: enum -> { kind = "Target", index } | { kind = "Bone", part, channel }.
export type SkeletonDriveIdentity = { kind: "Target", index: number } | { kind: "Bone", part: number, channel: number }

export type SkeletonDriveBatch = {
	rows: { any },
	identities: { SkeletonDriveIdentity },
	spy: { boolean },
}

local SkeletonDrives = {}
drives.SkeletonDrives = SkeletonDrives

local function drive_body(body: BodySnapshot, reaction_index: number): drive_solver.RetailDriveBodyState
	local rates = body.rates
	return {
		reaction_index = reaction_index,
		state = body.state_flags,
		orientation = rates.orientation,
		basis = rates.basis,
		center_of_mass = rates.position,
		linear_velocity = rates.linear_velocity,
		angular_velocity = rates.angular_velocity,
		force_acceleration = rates.force_acceleration,
		torque_acceleration = rates.torque_acceleration,
		inverse_mass = body.inertia.inverse_mass,
		world_inverse_inertia = rigid_body.pack_world_inverse_inertia(rates.world_inverse_inertia),
	}
end

-- ROBLOX: Result<Self, &str> -> SkeletonDrives или rt.raise(строка).
-- parents: [Option<usize>; 24] -> массив, где отсутствие — false.
function SkeletonDrives.new(initial_bones: { AnimationPartTransform }, initial_mapped: { AnimationPartTransform }, parents: { number | false }, animation_to_world: AnimationPartTransform, spawn: AnimationPartTransform, simulation: rigid_body.RetailSimulationStep, settings: SkeletonDriveSettings): SkeletonDrives
	local bad = parents[1] ~= false or parents[24] ~= false
	for i = 1, 24 do
		local p = parents[i]
		if p ~= false and (p :: number) >= ANIMATION_PART_COUNT then
			bad = true
		end
		if i >= 2 and i <= 23 and p == false then
			bad = true
		end
	end
	if bad then
		rt.raise("Skeleton drives require22 bone pairs and two roots")
	end
	local inverses = {}
	for i, m in initial_bones do
		inverses[i] = inverse_rigid(m)
	end
	local bones: { BoneDrives | false } = table.create(ANIMATION_PART_COUNT, false)
	for part = 0, ANIMATION_PART_COUNT - 1 do
		local parent = parents[part + 1]
		if parent == false then
			continue
		end
		local p = parent :: number
		local frames = {}
		for i, q in { p, 23 } do
			frames[i] = bone_drive_frames(initial_bones[part + 1], inverses[part + 1], inverses[q + 1])
		end
		local dynamics = BoneDriveDynamics.default()
		-- Init82BED180: LOCAL mode2 followed by LOCAL_ROOT mode0.
		dynamics.mode = 2
		BoneDriveDynamics.enable(dynamics, 0, 1.0, settings.bone)
		dynamics.mode = 0
		BoneDriveDynamics.enable(dynamics, 1, 1.0, settings.bone)
		bones[part + 1] = {
			parent = { p, 23 },
			active = { true, true },
			frames = frames,
			dynamics = dynamics,
		}
	end
	local targets = SkeletonTargets.new(simulation)
	local frame = initial_mapped[24]
	local w: { number } = table.create(16) :: any
	for i = 0, 15 do
		w[i + 1] = to_bits(frame[i // 4 + 1][i % 4 + 1])
	end
	local normalized = normalization.orthonormalize_part_basis(w)
	local hips = {}
	for i = 0, 3 do
		hips[i + 1] = { from_bits(normalized[i * 4 + 1]), from_bits(normalized[i * 4 + 2]), from_bits(normalized[i * 4 + 3]), from_bits(normalized[i * 4 + 4]) }
	end
	SkeletonTargets.reset(targets, compose_affine(animation_to_world, hips), spawn)
	return {
		targets = targets,
		bones = bones,
		settings = settings,
	}
end

-- ///82BEB488 consumes the24 IK-adjusted frames in animation coordinates.
-- /// Collision weight comes from the actual SkeletonCollision state owner.
function SkeletonDrives.update(self: SkeletonDrives, pose: { AnimationPartTransform }, partial: boolean, collision_weight: number)
	local inverses = {}
	for i, frame in pose do
		inverses[i] = inverse_rigid(frame)
	end
	local settings = self.settings
	local base = if settings.enabled then settings.strength else { 0.0, 0.0 }
	self.targets.dynamics[1].linear = hard(HARD_VELOCITY, HARD_STRENGTH)
	for part = 1, 22 do
		local entry = self.bones[part + 1]
		if entry == false then
			continue
		end
		local bone = entry :: BoneDrives
		local selected = not partial or (part >= 1 and part <= 5) or (part >= 7 and part <= 9)
		local strengths
		if not (collision_weight >= 1.0) and selected then
			bone.dynamics.mode = 3
			strengths = {}
			for channel = 1, 2 do
				local c = settings.collision_strength[part + 1][channel]
				--82BEB6F0/F4 are fmadds, followed by scalar fmuls.
				strengths[channel] = f32(mul_add(f32(1.0 - c), collision_weight, c) * settings.strength[channel])
			end
		else
			bone.dynamics.mode = 0
			strengths = table.clone(base)
		end
		bone.dynamics.strengths = strengths
		for channel = 0, 1 do
			if not bone.active[channel + 1] then
				continue
			end
			bone.frames[channel + 1] = bone_drive_frames(pose[part + 1], inverses[part + 1], inverses[bone.parent[channel + 1] + 1])
			BoneDriveDynamics.enable(bone.dynamics, channel, strengths[channel + 1], settings.bone)
		end
	end
end

-- /// Native order: four targets, then LOCAL and LOCAL_ROOT for parts1..22.
-- /// The caller appends rows to the board/contact/joint solve before any
-- /// integration and borrows targets.bodies directly into that same step.
function SkeletonDrives.build(self: SkeletonDrives, bodies: { BodySnapshot }, reaction_base: number, target_reaction_base: number, time_step: number): SkeletonDriveBatch
	local batch: SkeletonDriveBatch = { rows = {}, identities = {}, spy = {} }
	for target = 0, TARGET_COUNT - 1 do
		self.targets.frames[target + 1] = prepare_bone_drive_frames(self.targets.frames[target + 1])
		local part = TARGET_PARTS[target + 1]
		local a = bodies[part + 1]
		local b = self.targets.bodies[target + 1]
		if bit32.band(bit32.bor(a.state_flags, b.state_flags), 4) ~= 0 then
			table.insert(batch.rows, drive_solver.build_drive_rows(
				drive_body(a, reaction_base + part),
				drive_body(b, target_reaction_base + target),
				self.targets.frames[target + 1],
				self.targets.dynamics[target + 1],
				time_step
			))
			table.insert(batch.identities, { kind = "Target", index = target } :: any)
			table.insert(batch.spy, target >= 2)
		end
	end
	for part = 1, 22 do
		local entry = self.bones[part + 1]
		if entry == false then
			continue
		end
		local bone = entry :: BoneDrives
		for channel = 0, 1 do
			if not bone.active[channel + 1] then
				continue
			end
			bone.frames[channel + 1] = prepare_bone_drive_frames(bone.frames[channel + 1])
			local parent = bone.parent[channel + 1]
			local a = bodies[part + 1]
			local b = bodies[parent + 1]
			if bit32.band(bit32.bor(a.state_flags, b.state_flags), 4) ~= 0 then
				table.insert(batch.rows, drive_solver.build_drive_rows(
					drive_body(a, reaction_base + part),
					drive_body(b, reaction_base + parent),
					bone.frames[channel + 1],
					bone.dynamics.channels[channel + 1],
					time_step
				))
				table.insert(batch.identities, { kind = "Bone", part = part, channel = channel } :: any)
				table.insert(batch.spy, true)
			end
		end
	end
	return batch
end

return drives
