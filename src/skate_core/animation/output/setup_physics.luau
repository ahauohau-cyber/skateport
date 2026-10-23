--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/setup_physics.rs (коммит 2e16697)
--
-- Source-bound packet composition for concrete Actor::SetUpPhysics 82593640.
-- The caller supplies the runtime services and completed materialized poses.
-- This is not the complete Actor update or Skeleton attribute interpreter.

local rt = require("../../../rt")
local actor_packet = require("./actor_packet")
local attributes = require("./attributes")
local intents = require("./intents")
local motion_graph_packet = require("./motion_graph_packet")
local packet_reset = require("./packet_reset")
local physics_packet = require("./physics_packet")

local setup_physics = {}

-- Views cover fields touched by this concrete publication chain. Packet fields
-- only used by later Skeleton consumers are not fabricated here.
export type PhysicsInputPacket = {
	pose: physics_packet.PhysicsPosePacket,
	reset: packet_reset.AdditionalResetFields,
	motion_graph: motion_graph_packet.MotionGraphPacket,
	intents: intents.IntentMap,
	attributes: attributes.PacketAttributes,
	actor: actor_packet.ActorPacketFields,
}

export type AnimationPublication = {
	state: physics_packet.SkaterPublicationState,
	completed: any,
	poses: physics_packet.ActorPoseBuffers,
	signal_name: string,
	tree_attributes: { attributes.AnimationAttribute },
}

-- ROBLOX: enum IntentPublication -> { kind = "MotionGraph", map = IntentMap } |
-- { kind = "RetainPacket" } (exact same-container branch 825936FC; no clear/reinsert occurs).
export type IntentPublication = { kind: string, map: intents.IntentMap? }

export type MotionGraphPublication = {
	state: motion_graph_packet.MotionGraphPacket,
	intents: IntentPublication,
	attributes: { attributes.MotionGraphAttribute },
}

-- ROBLOX: enum PublicationError<E> -> { kind = "Pose", error = BufferError } |
-- { kind = "RuntimeService", error = E }.
export type PublicationError = { kind: string, error: any }

-- 82DB3C48 only stores a borrowed packet pointer at physical+1808. This safe
-- binding keeps the entire owned packet alive and prevents its next mutation
-- while a consumer reads it. It does not execute the downstream physics step.
export type PhysicsPacketBinding = { packet: PhysicsInputPacket }

local function wrap(kind: string, f: (...any) -> ...any, ...: any): any
	local value, err = rt.catch(f, ...)
	if err ~= nil then
		rt.raise({ kind = kind, error = err })
	end
	return value
end

-- Concrete canonical virtual144 is a no-op. Remaining phases execute in the
-- native order: reset, SkaterAnim, MG, intents, MG/tree attrs, actor suffix,
-- then packet binding. Failure preserves writes already made and returns no
-- binding; the caller must not consume the partially published packet.
-- ROBLOX: Result<PhysicsPacketBinding, PublicationError> -> binding или rt.raise(PublicationError).
function setup_physics.compose(packet: PhysicsInputPacket, animation: AnimationPublication, graph: MotionGraphPublication, actor: actor_packet.ActorPublicationState, environment: actor_packet.ActorPublicationEnvironment): PhysicsPacketBinding
	wrap("Pose", packet_reset.reset, packet.pose, packet.reset)
	-- ROBLOX: f64::from(f32::from_bits(..)) — значение f32 уже точное в double.
	wrap("Pose", physics_packet.publish, animation.state, animation.completed, animation.poses, packet.pose, rt.from_bits(0x3c888889), animation.signal_name)
	motion_graph_packet.publish(graph.state, packet.motion_graph)
	if graph.intents.kind == "MotionGraph" then
		intents.IntentMap.replace_from(packet.intents, graph.intents.map :: intents.IntentMap)
	end
	attributes.PacketAttributes.replace_from(packet.attributes, graph.attributes, animation.tree_attributes)
	wrap("RuntimeService", actor_packet.publish, actor, packet.pose, packet.reset, packet.actor, environment)
	return { packet = packet }
end

return setup_physics
