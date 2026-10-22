--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact_feedback/mod.rs (коммит 2e16697)
--
-- TU3 post-solver contact observations and their native record lifetimes.
-- ROBLOX: функции подмодулей (board_reports, collision_info, compression,
-- reports, spy) берутся из этих файлов, переэкспорта нет.

local contact_feedback = {}

-- SkateboardBody+64..+876, retained as guest big-endian bytes.
-- ROBLOX: [u8; 812] -> buffer длиной 812 байт.
export type CollisionInfo = buffer
contact_feedback.COLLISION_INFO_BYTES = 812

-- ROBLOX: запись/чтение u32 в порядке big-endian (как в памяти Xbox 360).
function contact_feedback.word(bytes: buffer, offset: number): number
	return bit32.byteswap(buffer.readu32(bytes, offset))
end

function contact_feedback.put(bytes: buffer, offset: number, value: number)
	buffer.writeu32(bytes, offset, bit32.byteswap(value))
end

return contact_feedback
