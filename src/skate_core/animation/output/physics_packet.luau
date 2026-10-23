--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/physics_packet.rs (коммит 2e16697)
--
-- Concrete SkaterAnim::GetPhysUpdateData, TU3 82B985E8.
-- This owns only fields written by that function, not the full AnimOutPhysIn
-- reset, motion-graph merge, attribute dispatch, or physical force consumers.

local rt = require("../../../rt")
local buffers = require("../commands/buffers")
local sqt = require("./sqt")

local physics_packet = {}

type NativeMatrix = sqt.NativeMatrix

-- Optional object at SkaterAnim+15104. The original class name is unresolved.
export type AnimationSignal = { name_hash: number, active: number }

-- Fields read or consumed from the concrete native SkaterAnim. Other object
-- fields remain with their owners. The two unknown requests are NOT push flags.
export type SkaterPublicationState = {
	-- Native packed flags+15180 bits 31,30,29,28 respectively.
	orientation_bit31: boolean,
	mirrored: boolean,
	riding_fakie: boolean,
	weight_on_nose: boolean,
	-- +15196 and +15188 are distinct enums. Only equality is tested here.
	relative_stance: number,
	natural_stance: number,
	-- Native flags bits 16 and 15, consumed at publication.
	request_bit16: boolean,
	request_bit15: boolean,
	-- Native flags bit 20 and persistent count+15184.
	air_dismount_revert_requested: boolean,
	air_dismount_revert_frames: number,
	signal: AnimationSignal?,
}

export type ActorPoseBuffers = {
	-- Actor-owned hierarchy-global matrices, full SkaterAnim+13460.
	hierarchy: buffers.BoneSlice,
	-- Actor-owned local matrices, full SkaterAnim+13468.
	["local"]: buffers.BoneSlice,
}

-- Physics-packet-owned arrays are separate from the animation allocations.
-- Count is packet+10380, which native publication reads without rewriting.
-- Unlisted packet fields must be preserved by the surrounding packet owner.
export type PhysicsPosePacket = {
	bone_count: number,
	hierarchy: { NativeMatrix },
	["local"]: { NativeMatrix },
	timestep: number,
	foot_surface_ids: { number },
	flags: number,
	board_flipped: boolean,
	mirrored: boolean,
	riding_switch: boolean,
	riding_fakie: boolean,
	weight_forwards: boolean,
	regular_stance: boolean,
	air_dismount_revert_frames: number,
}

local function replace_flag(flags: number, bit: number, value: boolean): number
	return bit32.bor(bit32.band(flags, bit32.bnot(bit32.lshift(1, bit))), bit32.lshift(if value then 1 else 0, bit))
end

-- 8296EA10: NUL-terminated, signed-byte name hashing. This deliberately does
-- not substitute a library hash or unsigned-byte variant.
function physics_packet.signal_hash(name: string): number
	local hash = 0
	for i = 1, #name do
		local byte = string.byte(name, i)
		if byte == 0 then
			break
		end
		local signed = if byte >= 128 then byte - 256 else byte
		hash = rt.wrapping_add_u32(bit32.lshift(hash, 4), signed % 0x100000000)
		local high = bit32.band(hash, 0xf0000000)
		if high ~= 0 then
			hash = bit32.bxor(hash, bit32.bxor(bit32.rshift(high, 23), high))
		end
	end
	return hash
end

local function copy_matrix(m: NativeMatrix): NativeMatrix
	return { table.clone(m[1]), table.clone(m[2]), table.clone(m[3]), table.clone(m[4]) }
end

-- Same publication with host-owned evaluated matrices. Completing animation
-- evaluation before this call preserves the source dependency without
-- requiring the original job/cache allocation system in the game.
-- ROBLOX: Result<i32, BufferError> -> число или rt.raise(BufferError).
function physics_packet.publish_evaluated(state: SkaterPublicationState, hierarchy: { NativeMatrix }, localm: { NativeMatrix }, packet: PhysicsPosePacket, timestep: number, signal_name: string): number
	local count = packet.bone_count
	if #hierarchy < count or #localm < count or #packet.hierarchy < count or #packet["local"] < count then
		rt.raise({ kind = "RangeOutsideAllocation" })
	end
	-- ROBLOX: timestep as f32 (f64 -> f32).
	packet.timestep = rt.f32(timestep)
	packet.foot_surface_ids = { 0, 0 }
	packet.flags = replace_flag(packet.flags, 27, state.request_bit16)
	state.request_bit16 = false
	packet.flags = replace_flag(packet.flags, 23, state.request_bit15)
	state.request_bit15 = false
	packet.flags = bit32.band(packet.flags, bit32.bnot(bit32.bor(bit32.lshift(1, 25), bit32.lshift(1, 26))))
	local signal = state.signal
	if signal ~= nil then
		signal.name_hash = physics_packet.signal_hash(signal_name)
		signal.active = 0
	end
	for i = 1, count do
		packet.hierarchy[i] = copy_matrix(hierarchy[i])
		packet["local"][i] = copy_matrix(localm[i])
	end
	packet.board_flipped = state.orientation_bit31 ~= state.mirrored
	packet.mirrored = state.mirrored
	packet.riding_switch = state.relative_stance == 1
	packet.riding_fakie = state.riding_fakie
	packet.weight_forwards = if state.riding_fakie then not state.weight_on_nose else state.weight_on_nose
	packet.regular_stance = state.natural_stance == 0
	packet.flags = replace_flag(packet.flags, 28, state.air_dismount_revert_requested)
	state.air_dismount_revert_requested = false
	packet.air_dismount_revert_frames = state.air_dismount_revert_frames
	return state.air_dismount_revert_frames
end

-- Publish after the source worker completes. Before modifying state, this safe
-- adapter rejects invalid/uninitialized ranges; native assumes valid storage.
-- `signal_name` is the current string selected by native global 830301E4 (the
-- inspected TU3 image selects "signup"). Supply it from verified startup data.
-- Concrete getters 82B970D8/82B97100/82B97128 are pure field reads here;
-- polymorphic replacement getters are outside this concrete SkaterAnim port.
function physics_packet.publish(state: SkaterPublicationState, completed: any, poses: ActorPoseBuffers, packet: PhysicsPosePacket, timestep: number, signal_name: string): number
	local count = packet.bone_count
	if #packet.hierarchy < count or #packet["local"] < count then
		rt.raise({ kind = "RangeOutsideAllocation" })
	end
	local hierarchy = buffers.BoneBuffers.read(completed.buffers.matrices, poses.hierarchy, count)
	local localm = buffers.BoneBuffers.read(completed.buffers.matrices, poses["local"], count)
	return physics_packet.publish_evaluated(state, hierarchy, localm, packet, timestep, signal_name)
end

return physics_packet
