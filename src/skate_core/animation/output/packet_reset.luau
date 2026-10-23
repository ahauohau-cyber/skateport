--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/packet_reset.rs (коммит 2e16697)
--
-- AnimOutPhysIn::Reset, TU3 82590028.
-- Reset is selective: it preserves storage, count, intents, attributes and all
-- fields not listed below. Actor::SetUpPhysics owns the later list replacement.

local rt = require("../../../rt")
local physics_packet = require("./physics_packet")

local packet_reset = {}

-- Additional fields written by Reset, kept separate from the existing pose
-- publication view. Unknown flags retain their verified producer/offset names.
export type AdditionalResetFields = {
	-- 10388; 10912/10916.
	compression: number,
	foot_ik_influence: { number },
	-- 10369. Position itself is preserved by Reset.
	next_step_position_valid: boolean,
	-- 10375/10376; overwritten from these Actor bits during SetUpPhysics.
	actor_flag_1904_bit23: boolean,
	actor_flag_1908_bit2: boolean,
	-- 10496, 10688, 10689: active markers only; payloads are not cleared here.
	external_impulse_active: boolean,
	external_physics_input_active: boolean,
	externally_controlled: boolean,
	-- 10786/10787/10796.
	prevent_manual_respawn: boolean,
	ignore_respawn_reset_button: number,
	force_braking: boolean,
	-- 10788/10792. Named source fields, same target scalar reset/caller roles.
	truck_tightness: number,
	wheel_hardness: number,
	-- Six complete native vectors at 10816..10896.
	-- Individual target semantics remain unassigned; all fourth lanes reset.
	auxiliary_vectors: { { number } },
	-- 10928, later overwritten by the Actor's selected physics settings.
	requested_physics_mode: number,
}

-- Native packed basis, NOT a conventional homogeneous 4x4 identity.
-- Three static vectors at 82139A10/20/30 plus an all-zero vector produced
-- inside Reset. All four fourth lanes, including translation W, are zero.
local function reset_pose(): { { number } }
	return { { 1.0, 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0, 0.0 }, { 0.0, 0.0, 1.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } }
end
packet_reset.RESET_POSE = table.freeze(reset_pose())

-- Complete field coverage for 82590028 on valid packet allocations. Host-side
-- extent checks precede mutation; native assumes allocations match the count.
-- Existing vector lengths/capacities and bones past packet.bone_count remain.
-- ROBLOX: Result<(), BufferError> -> rt.raise(BufferError).
function packet_reset.reset(packet: physics_packet.PhysicsPosePacket, fields: AdditionalResetFields)
	-- Both native loop comparisons are signed. A high-bit count skips the
	-- matrix loop while scalar/flag resets still run.
	local count = math.max(rt.to_i32(packet.bone_count), 0)
	if #packet.hierarchy < count or #packet["local"] < count then
		rt.raise({ kind = "RangeOutsideAllocation" })
	end
	packet.timestep = rt.from_bits(0x3c888889)
	fields.external_impulse_active = false
	fields.compression = 0.5
	fields.foot_ik_influence[1] = 0.0
	fields.external_physics_input_active = false
	fields.foot_ik_influence[2] = 0.0
	fields.externally_controlled = false
	fields.truck_tightness = 0.0
	packet.mirrored = false
	packet.riding_switch = false
	packet.riding_fakie = false
	packet.weight_forwards = false
	packet.regular_stance = false
	fields.prevent_manual_respawn = false
	fields.ignore_respawn_reset_button = 0
	fields.force_braking = false
	packet.air_dismount_revert_frames = 0
	packet.board_flipped = false
	fields.next_step_position_valid = false
	fields.actor_flag_1904_bit23 = false
	packet.flags = bit32.band(packet.flags, 0x013fffff)
	fields.actor_flag_1908_bit2 = false
	packet.foot_surface_ids[1] = 0
	fields.wheel_hardness = 0.0
	packet.foot_surface_ids[2] = 0
	fields.auxiliary_vectors[1] = { 0.0, 0.0, 0.0, 0.0 }
	fields.requested_physics_mode = 1
	for i = 2, 6 do
		fields.auxiliary_vectors[i] = { 0.0, 0.0, 0.0, 0.0 }
	end
	for bone = 1, count do
		-- Native completes local first, then hierarchy, for each bone.
		packet["local"][bone] = reset_pose()
		packet.hierarchy[bone] = reset_pose()
	end
end

return packet_reset
