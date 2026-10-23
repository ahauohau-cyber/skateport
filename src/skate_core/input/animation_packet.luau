--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/animation_packet.rs (коммит 2e16697)
--
-- Complete TU3 82DB5BE0: AnimOutPhysIn -> ProcessedPhysIn publication.
-- Called by physical input stage 82DB4048 before board/attribute processing.
-- Inputs are already produced by animation; this is not a gamepad mapping.

local animation_packet = {}

-- Source packet fields. Byte flags use their low bit, including noncanonical
-- byte values. Matrix/vector words are copied without numerical conversion.
export type AnimationPacketFields = {
	-- Packet +10368 -> processed +2468 bit 20.
	stance_byte: number,
	-- Packet +10384 / +10388.
	timestep: number,
	scalar_10388: number,
	-- Packet +10375, +10496, +10784 -> processed +2468 bits 3, 2, 1.
	flags_10375_10496_10784: { number },
	vector_10480: { number },
	matrix_10704: { { number } },
	byte_10768: number,
	-- Packet +10788 / +10792.
	truck_tightness: number,
	scalar_10792: number,
	-- Packet +10371 -> processed +2476 bit 20.
	flag_10371: number,
}

-- All fields written by 82DB5BE0. Seed flag words from the preceding native
-- reset/publication stages: this helper preserves their unrelated bits.
export type ProcessedPacketFields = {
	flags_2468: number,
	flags_2476: number,
	timestep: number,
	scalar_2668: number,
	vector_1520: { number },
	matrix_1536: { { number } },
	byte_1600: number,
	truck_tightness: number,
	scalar_2764: number,
}

local function replace_bit(word: number, bit: number, byte: number): number
	return bit32.bor(bit32.band(word, bit32.bnot(bit32.lshift(1, bit))), bit32.lshift(bit32.band(byte, 1), bit))
end

-- Publish the complete function's writes into distinct source/destination
-- records. The source packet must remain valid through physical processing.
function animation_packet.publish(source: AnimationPacketFields, output: ProcessedPacketFields)
	output.flags_2468 = replace_bit(output.flags_2468, 20, source.stance_byte)
	output.timestep = source.timestep
	output.scalar_2668 = source.scalar_10388
	output.flags_2468 = replace_bit(output.flags_2468, 3, source.flags_10375_10496_10784[1])
	output.flags_2468 = replace_bit(output.flags_2468, 2, source.flags_10375_10496_10784[2])
	output.vector_1520 = table.clone(source.vector_10480)
	output.flags_2468 = replace_bit(output.flags_2468, 1, source.flags_10375_10496_10784[3])
	output.matrix_1536 = { table.clone(source.matrix_10704[1]), table.clone(source.matrix_10704[2]), table.clone(source.matrix_10704[3]), table.clone(source.matrix_10704[4]) }
	output.byte_1600 = source.byte_10768
	output.truck_tightness = source.truck_tightness
	output.scalar_2764 = source.scalar_10792
	output.flags_2476 = replace_bit(output.flags_2476, 20, source.flag_10371)
end

return animation_packet
