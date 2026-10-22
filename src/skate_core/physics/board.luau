--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board.rs (коммит 2e16697)
--
-- Physical body indices and stock geometry used by the TU3 board assembly.

local rt = require("../../rt")

local from_bits = rt.from_bits

local board = {}

board.BODY_COUNT = 7

-- pub enum BodyId (#[repr(u8)])
-- ROBLOX: enum без данных -> числа, как в Rust (с нуля).
-- Элемент массива тел для BodyId лежит в [id + 1].
board.BodyId = {
	RightFrontWheel = 0,
	LeftFrontWheel = 1,
	RightBackWheel = 2,
	LeftBackWheel = 3,
	FrontTruck = 4,
	BackTruck = 5,
	Deck = 6,
}

-- pub const ORDER: [Self; BODY_COUNT]
board.BodyId.ORDER = { 0, 1, 2, 3, 4, 5, 6 }

board.RETAIL_WHEEL_RADIUS = from_bits(0x3CFD_F3B6)
board.RETAIL_TRUCK_Y_POSITION = from_bits(0xBD67_6C8B)
board.RETAIL_TRUCK_Z_POSITION_BACK = from_bits(0xBD54_FDF4)
board.RETAIL_TRUCK_Z_POSITION_FRONT = from_bits(0xBD54_FDF4)
board.RETAIL_TRUCK_ROTATION_AXIS_ANGLE_DEGREES = from_bits(0x41F8_0000)
board.RETAIL_DECK_MID_LENGTH = from_bits(0x3F17_0A3D)

return board
