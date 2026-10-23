--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/actor_packet.rs (коммит 2e16697)
--
-- Actor field publication 825937EC..825939C8 and external payload copy 82592810.
-- Runtime services remain explicit source interfaces; their implementation is
-- not supplied here and these fields do not manufacture a gameplay impulse.

local rt = require("../../../rt")
local packet_reset = require("./packet_reset")
local physics_packet = require("./physics_packet")

local actor_packet = {}

export type ExternalPhysicsInput = {
	-- Ten complete vectors; word representation preserves non-arithmetic bits.
	vectors: { { number } },
	flags: number,
}

local ExternalPhysicsInput = {}
actor_packet.ExternalPhysicsInput = ExternalPhysicsInput

-- 82592810 copies 160 bytes and only the high seven flag bits. Remaining
-- destination flag bits and native padding are not overwritten.
function ExternalPhysicsInput.copy_from(self: ExternalPhysicsInput, source: ExternalPhysicsInput)
	local v = {}
	for i, vec in source.vectors do
		v[i] = table.clone(vec)
	end
	self.vectors = v
	self.flags = bit32.bor(bit32.band(self.flags, 0x01ffffff), bit32.band(source.flags, 0xfe000000))
end

export type ExternalReset = {
	transform: { { number } },
	-- Source payload+64 -> packet 10768; retains the complete byte.
	byte64: number,
}

export type ActorPacketFields = {
	external_impulse: { number },
	external_physics: ExternalPhysicsInput,
	external_reset: ExternalReset,
	-- Actor 1904 bit29 -> packet 10784; not reset by 82590028.
	actor_flag_1904_bit29: boolean,
}

export type ActorPublicationState = {
	flags1904: number,
	flags1908: number,
	external_controller_present: boolean,
	external_impulse: { number },
	external_physics: ExternalPhysicsInput,
	external_reset: ExternalReset,
	-- Actor 1768 selects the native 168-byte per-player settings record.
	player_index: number,
}

-- A source-owned binding to the settings object captured before Actor+56's
-- virtual call. Each read uses the same captured object and 168-byte stride.
-- ROBLOX: трейты -> таблицы методов, каждый возвращает (значение) или (nil, ошибка).
export type PlayerPhysicsSettingsSource = {
	-- Record+160. This read is skipped by the fixed-settings branch.
	truck_tightness: (self: any, player_index: number) -> (number?, any),
	-- Record+164. This read is skipped by the fixed-settings branch.
	wheel_hardness: (self: any, player_index: number) -> (number?, any),
	-- Record+172. Read after either branch has written both output scalars.
	requested_physics_mode: (self: any, player_index: number) -> (number?, any),
}

-- Exact unresolved external service boundaries for this field publisher.
-- A game adapter must implement these from their source-owned systems.
export type ActorPublicationEnvironment = {
	-- 8259FC28: scene mode enum or nil (no current object).
	current_scene_mode: (self: any) -> (number?, any),
	-- Read global byte 830B7C30 verbatim, without bool normalization.
	ignore_respawn_reset_button: (self: any) -> (number?, any),
	-- Actor subobject+56 virtual16, low return byte.
	actor_subobject56_slot16: (self: any, actor: ActorPublicationState) -> (number?, any),
	-- Capture global 83067068 at 82593954 before slot16 at 8259395C.
	capture_physics_settings: (self: any) -> (PlayerPhysicsSettingsSource?, any),
}

local function replace_flag(flags: number, bit: number, value: boolean): number
	return bit32.bor(bit32.band(flags, bit32.bnot(bit32.lshift(1, bit))), bit32.lshift(if value then 1 else 0, bit))
end

-- ROBLOX: оператор ? для сервисов: (значение, ошибка) -> значение или rt.raise(ошибка).
local function try<T>(value: T?, err: any): T
	if err ~= nil then
		rt.raise(err)
	end
	return value :: T
end

local function has(flags: number, bit: number): boolean
	return bit32.band(flags, bit32.lshift(1, bit)) ~= 0
end

-- Full actor-owned suffix on distinct actor/packet payload storage. Scene
-- lookup is skipped for an external controller or force-braking bit26.
-- This stops before the physical object's borrowed-packet setter 82DB3C48.
-- ROBLOX: Result<(), E::Error> -> rt.raise(ошибка сервиса).
function actor_packet.publish(actor: ActorPublicationState, pose: physics_packet.PhysicsPosePacket, reset: packet_reset.AdditionalResetFields, fields: ActorPacketFields, environment: ActorPublicationEnvironment)
	reset.actor_flag_1904_bit23 = has(actor.flags1904, 23)
	reset.actor_flag_1908_bit2 = has(actor.flags1908, 2)
	reset.external_impulse_active = has(actor.flags1904, 30)
	fields.external_impulse = table.clone(actor.external_impulse)
	ExternalPhysicsInput.copy_from(fields.external_physics, actor.external_physics)
	reset.external_physics_input_active = has(actor.flags1904, 27)
	local scene_mode_flag = false
	if not actor.external_controller_present and not has(actor.flags1904, 26) then
		local mode = try(environment:current_scene_mode())
		scene_mode_flag = mode == 19 or mode == 20
	end
	pose.flags = replace_flag(pose.flags, 22, scene_mode_flag)
	reset.externally_controlled = actor.external_controller_present
	fields.external_reset = {
		transform = { table.clone(actor.external_reset.transform[1]), table.clone(actor.external_reset.transform[2]), table.clone(actor.external_reset.transform[3]), table.clone(actor.external_reset.transform[4]) },
		byte64 = actor.external_reset.byte64,
	}
	fields.actor_flag_1904_bit29 = has(actor.flags1904, 29)
	reset.prevent_manual_respawn = has(actor.flags1904, 28)
	reset.force_braking = has(actor.flags1904, 26)
	pose.flags = replace_flag(pose.flags, 24, has(actor.flags1904, 25))
	actor.flags1904 = bit32.band(actor.flags1904, bit32.bnot(bit32.lshift(1, 25)))
	reset.ignore_respawn_reset_button = try(environment:ignore_respawn_reset_button())
	actor.flags1904 = bit32.band(actor.flags1904, bit32.bnot(bit32.lshift(1, 28)))
	local settings = try(environment:capture_physics_settings())
	local use_fixed_settings = try(environment:actor_subobject56_slot16(actor)) ~= 0
	if use_fixed_settings then
		reset.truck_tightness = rt.from_bits(0x3f333333)
		reset.wheel_hardness = rt.from_bits(0x3f333333)
	else
		reset.truck_tightness = try(settings:truck_tightness(actor.player_index))
		reset.wheel_hardness = try(settings:wheel_hardness(actor.player_index))
	end
	reset.requested_physics_mode = try(settings:requested_physics_mode(actor.player_index))
end

return actor_packet
