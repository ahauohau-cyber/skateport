--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/motion_graph_packet.rs (коммит 2e16697)
--
-- Concrete SkaterMotionGraph::GetPhysUpdateData 82595FA8 and copy 82596008.
-- Actor construction 82590DC0 -> 8258F488 installs base vtable 823006D0;
-- slot 36 resolves 82595FA8. Unlike the reviewed Skate2 counterpart, this
-- Skate3 body does not reset trick, gesture or wipeout source state afterward.

local motion_graph_packet = {}

-- ROBLOX: TrickIdentifier(pub [u32; 6]) -> таблица из 6 слов.
export type TrickIdentifier = { number }

export type TrickData = {
	identifiers: { TrickIdentifier },
	-- Native trick record+48. Its producer/enum meaning is not recovered here.
	word48: number,
	-- Native record+52/+56; copied by lfs/stfs.
	scalars52_56: { number },
}

export type GestureData = {
	gesture: number,
	-- The native body copies the complete second word, including unused bytes.
	flag_bytes: { number },
}

export type MotionGraphPacket = {
	-- Source MG+5924 -> physics packet+10392, 60 bytes.
	trick: TrickData,
	-- MG+5984/+5988 -> packet+10452/+10456.
	gesture: GestureData,
	-- MG+5992/+5996 -> packet+10460/+10464; complete words are copied.
	wipeout_gesture: { number },
}

-- Complete concrete publication. Timestep is unused by 82595FA8; no source
-- request is consumed, and repeated publication copies the same state.
function motion_graph_packet.publish(source: MotionGraphPacket, destination: MotionGraphPacket)
	destination.trick = {
		identifiers = { table.clone(source.trick.identifiers[1]), table.clone(source.trick.identifiers[2]) },
		word48 = source.trick.word48,
		scalars52_56 = table.clone(source.trick.scalars52_56),
	}
	destination.gesture.gesture = source.gesture.gesture
	destination.gesture.flag_bytes = table.clone(source.gesture.flag_bytes)
	destination.wipeout_gesture[1] = source.wipeout_gesture[1]
	destination.wipeout_gesture[2] = source.wipeout_gesture[2]
end

return motion_graph_packet
