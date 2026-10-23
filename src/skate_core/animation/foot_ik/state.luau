--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/state.rs (коммит 2e16697)
--
-- Persistent SkeletonIK state and the GeneralUpdate82BDCA38 stage order.

local blend = require("./blend")
local contact = require("./contact")
local drive = require("./drive")
local external = require("./external")
local settings_mod = require("./settings")
local status = require("./status")
local transforms = require("./transforms")
local sar = require("../../physics/skeleton_animation_record")

local copy_transform = sar.copy_transform
local ContactState = contact.ContactState
local ExternalTarget = external.ExternalTarget
local LimbStatus = status.LimbStatus
local LimbFrames = transforms.LimbFrames

type Transform = sar.AnimationPartTransform
type F4 = { number }

local state = {}

-- ///82BED688 binds the toe targets to foot/toe volumes and the hand targets to
-- ///their hand volumes. The optional second volume is distinct from chain parents.
state.LIMBS = table.freeze({
	table.freeze({ part = 15, parent_part = 16 }),
	table.freeze({ part = 19, parent_part = 20 }),
	table.freeze({ part = 3, parent_part = nil }),
	table.freeze({ part = 7, parent_part = nil }),
}) :: { transforms.LimbBinding }
local LIMBS = state.LIMBS

-- ROBLOX: feet_enabled в Rust приватное поле; доступ через enable_feet/feet_enabled.
export type FootIkState = {
	limbs: { status.LimbStatus },
	frames: { transforms.LimbFrames },
	external_targets: { external.ExternalTarget },
	contacts: contact.ContactState,
	feet_enabled: boolean,
}

local FootIkState = {}
state.FootIkState = FootIkState

-- ROBLOX: impl Default.
function FootIkState.default(): FootIkState
	--82BED780 resets the retained histories and enables feet; it is not
	--the wipeout-entry solve82BF1B90, which disables feet after its update.
	local limbs, frames, targets = {}, {}, {}
	for i = 1, 4 do
		limbs[i] = LimbStatus.default()
		frames[i] = LimbFrames.default()
		targets[i] = ExternalTarget.default()
	end
	return {
		limbs = limbs,
		frames = frames,
		external_targets = targets,
		contacts = ContactState.default(),
		feet_enabled = true,
	}
end

-- ROBLOX: current_contacts: [Option<[f32; 4]>; 2] -> массив, где отсутствие — false.
export type UpdateInput = {
	flags_2468: number,
	flags_2472: number,
	flags_2480: number,
	-- DataIn32/96; both are actual Skeleton root transforms.
	animation_to_world: Transform,
	world_to_animation: Transform,
	-- DataIn160, from Skeleton12496. This is independently produced from
	--DataIn352 (Skeleton12304) used by foot contact correction.
	physical_board: Transform,
	contact_board: Transform,
	inverse_contact_board: Transform,
	-- SkeletonData animation record: physical volume frames after board offset.
	animation: { Transform },
	-- ProcessData14160: original selected globals, before volume composition.
	original_animation: { Transform },
	-- Actual board-parented targets after their type5 volume composition.
	targets: { Transform },
	hips_world_position: F4,
	contact_bone: number,
	foot_bones: { number },
	current_contacts: { F4 | false },
}

-- ROBLOX: `*self = Self::default()` -> перезапись полей той же таблицы.
function FootIkState.reset(self: FootIkState)
	local fresh = FootIkState.default() :: any
	for k, v in fresh do
		(self :: any)[k] = v
	end
end

-- /// Ground::Enter writes (*(Skeleton+16432))+464 directly.
function FootIkState.enable_feet(self: FootIkState, enabled: boolean)
	self.feet_enabled = enabled
end

function FootIkState.feet_enabled(self: FootIkState): boolean
	return self.feet_enabled
end

-- /// Ground collision handling can also set the per-update3185 flag.
function FootIkState.mark_support_failed_this_update(self: FootIkState)
	self.contacts.support_failed_this_update = true
end

-- /// The mutable output is Skeleton12624 consumed by SkeletonDrives. The
-- ///original animation and collision-volume record must remain separate.
-- ROBLOX: drives — `&mut [Transform; 24]`, меняется на месте.
function FootIkState.update(self: FootIkState, input: UpdateInput, geometry: drive.Geometry, settings: settings_mod.Settings, drives: { Transform }): { boolean }
	for limb = 1, 4 do
		self.frames[limb].target = copy_transform(input.targets[limb])
	end
	status.update_modes(self.limbs, self.feet_enabled, input.flags_2472)
	status.update_blends(self.limbs, settings.deck_half_width, settings.deck_total_half_length, input.flags_2480, settings.blend)
	local inverse_animation_board = transforms.inverse_rigid(input.animation[1])
	for limb = 1, 4 do
		self.frames[limb].within_contact_bounds = false
		local mode = self.limbs[limb].mode
		if mode == "External" or mode == "Local" then
			external.update(self.external_targets[limb], self.limbs[limb], self.frames[limb], LIMBS[limb], input.animation, input.animation_to_world, input.world_to_animation)
		end
		transforms.prepare_animation_target(self.limbs[limb], self.frames[limb], LIMBS[limb], input.animation, input.animation_to_world, inverse_animation_board, settings.contact_bounds)
	end
	blend.update(self.limbs, self.frames, LIMBS, input.physical_board, input.animation_to_world, input.animation[1])
	ContactState.update(self.contacts, self.limbs, self.frames, {
		flags_2468 = input.flags_2468,
		contact_bone = input.contact_bone,
		foot_bones = input.foot_bones,
		hips_world_position = input.hips_world_position,
		inverse_board = input.inverse_contact_board,
		board = input.contact_board,
		current_contacts = input.current_contacts,
	})
	return drive.update(self.limbs, self.frames, LIMBS, geometry, input.original_animation, drives, input.world_to_animation, settings.angle_limits)
end

return state
