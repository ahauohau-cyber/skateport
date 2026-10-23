--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/startup/reset.rs (коммит 2e16697)
--
-- Complete 82C0D680 and its 82C00D68 dependency, guest big-endian record bytes.
-- ROBLOX: [u8; N] -> buffer (байты big-endian, как у Xenon); срез &mut board[64..876]
-- -> тот же buffer плюс смещение base. [u32; 44] -> таблица слов (слово k в [k + 1]).

local reset = {}

local function word(bytes: buffer, offset: number): number
	return bit32.byteswap(buffer.readu32(bytes, offset))
end
local function put(bytes: buffer, offset: number, value: number)
	buffer.writeu32(bytes, offset, bit32.byteswap(value))
end
local function fill(bytes: buffer, from: number, to: number)
	buffer.fill(bytes, from, 0, to - from)
end
local function up(bytes: buffer, offset: number)
	fill(bytes, offset, offset + 16)
	put(bytes, offset + 4, 0x3f80_0000)
end

-- Complete CollisionInfo initialization/reset at 82C00D68. This is distinct
-- from the selective per-frame reset at 82C00CA0. Unwritten bytes survive.
-- ROBLOX: info: &mut [u8; 812] -> (buffer, base), запись идёт в [base, base + 812).
function reset.reset_collision_info(info: buffer, base: number?)
	local b = base or 0
	up(info, b + 0)
	up(info, b + 16)
	for i = 0, 6 do
		up(info, b + 32 + i * 16)
		for _, offset in { 144, 256, 368, 480 } do
			fill(info, b + offset + i * 16, b + offset + i * 16 + 16)
		end
		for _, offset in { 692, 720, 748 } do
			put(info, b + offset + i * 4, 0)
		end
		buffer.writeu8(info, b + 780 + i, 0)
	end
	fill(info, b + 592, b + 608)
	for i = 0, 3 do
		up(info, b + 608 + i * 16)
		put(info, b + 672 + i * 4, 0)
		buffer.writeu8(info, b + 688 + i, 0)
	end
	for _, offset in { 776, 788, 792, 796, 800 } do
		put(info, b + offset, 0)
	end
	buffer.writeu8(info, b + 804, 0)
	buffer.writeu8(info, b + 805, 0)
	local flags = bit32.band(word(info, b + 808), 0x01ff_ffff)
	put(info, b + 808, flags)
end

-- Complete SkateboardBody reset at 82C0D680. `bodies` are assembly parts in
-- their native order; each gravity vector is read from that body's Simulation
-- at +144. The hook assembly is separate and is not traversed here.
--
-- XYZ rates/torque clear; force XYZ receives the simulation vector. Fourth
-- lanes, pose, body flags/cooldown and all other body words survive. Ancillary
-- board bytes are preserved except for stores present in the native function.
-- Returns the original byte at board+8384, matching native r3.
function reset.reset_board_body(board: buffer, bodies: { { number } }, simulation_gravity: { { number } }): number
	assert(#bodies == #simulation_gravity, "assertion `left == right` failed")
	for i, body in bodies do
		local gravity = simulation_gravity[i]
		for k = 9, 11 do
			body[k] = 0
		end
		for k = 13, 15 do
			body[k] = 0
		end
		for k = 1, 3 do
			body[36 + k] = gravity[k]
		end
		for k = 41, 43 do
			body[k] = 0
		end
	end
	put(board, 7680, 0)
	put(board, 7684, 0)
	reset.reset_collision_info(board, 64)
	local old_flags = buffer.readu8(board, 8384)
	buffer.writeu8(board, 8384, bit32.band(old_flags, 0x3f))
	for _, offset in { 7968, 8032 } do
		fill(board, offset, offset + 52)
		buffer.writeu8(board, offset + 52, 0)
	end
	fill(board, 1008, 1044)
	buffer.writeu8(board, 1044, 0)
	return old_flags
end

return reset
