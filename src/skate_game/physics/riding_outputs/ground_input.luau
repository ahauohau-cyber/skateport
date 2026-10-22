--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/physics/riding_outputs/ground_input.rs (коммит 2e16697)
--
-- Snapshot inputs copied by original TU382D8E5C0 for the Ground job.

local rt = require("../../../rt")

local from_bits = rt.from_bits

type Vector3 = vector

local ground_input = {}

export type GroundPacketInputs = {
	wheel_normal: Vector3,
	dynamic_up: Vector3,
	speed: number,
	absolute_speed: number,
	wheel_count: number,
}

local GroundPacketInputs = {}
ground_input.GroundPacketInputs = GroundPacketInputs

-- ROBLOX: ProcessedPhysicsInput пока передаётся таблицей с теми же именами
-- полей, что в Rust (RawVector = таблица из 4 слов-битов).
-- TODO: тип ProcessedPhysicsInput переносится вместе с player/input_phase.
function GroundPacketInputs.from_processed(input: any): GroundPacketInputs
	local function vec(bits: { number }): Vector3
		return vector.create(from_bits(bits[1]), from_bits(bits[2]), from_bits(bits[3]))
	end
	return {
		-- 82D8E790: Processed464 -> input720.
		wheel_normal = vec(input.vectors_464_480_496_512_528[1]),
		-- 82D8E79C: Processed528 -> input736. Board112 is a retained
		-- acceleration-derived normal, NOT CollisionInfo's overall normal.
		dynamic_up = vec(input.vectors_464_480_496_512_528[5]),
		speed = input.scalar_2652, -- 82D8E7C0 -> input772.
		absolute_speed = input.scalar_2616, -- 82D8E7D8 -> input780.
		wheel_count = rt.to_i32(input.wheel_count_2556), -- 82D8E924 -> input804.
	}
end

return ground_input
