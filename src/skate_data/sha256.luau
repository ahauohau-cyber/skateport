--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/sha256.rs (коммит 2e16697)
--
-- SHA-256 source identity for private bank bytes (FIPS 180-4).
-- This is file integrity bookkeeping, separate from game arithmetic.
-- ROBLOX: &[u8] -> buffer; u32-арифметика через bit32 (обёртка по модулю 2^32).

local sha256 = {}

local K = {
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
	0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
	0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
	0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
	0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
	0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
	0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
	0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
	0xc67178f2,
}

local rrotate = bit32.rrotate
local bxor = bit32.bxor
local band = bit32.band
local bnot = bit32.bnot
local rshift = bit32.rshift

local w = table.create(64, 0)

-- ROBLOX: block — смещение блока в buffer.
local function compress(state: { number }, bytes: buffer, offset: number)
	for i = 0, 15 do
		local o = offset + i * 4
		w[i + 1] = bit32.bor(
			bit32.lshift(buffer.readu8(bytes, o), 24),
			bit32.lshift(buffer.readu8(bytes, o + 1), 16),
			bit32.lshift(buffer.readu8(bytes, o + 2), 8),
			buffer.readu8(bytes, o + 3)
		)
	end
	for i = 17, 64 do
		local x = w[i - 15]
		local y = w[i - 2]
		local s0 = bxor(rrotate(x, 7), rrotate(x, 18), rshift(x, 3))
		local s1 = bxor(rrotate(y, 17), rrotate(y, 19), rshift(y, 10))
		w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % 0x1_0000_0000
	end
	local a, b, c, d, e, f, g, h = state[1], state[2], state[3], state[4], state[5], state[6], state[7], state[8]
	for i = 1, 64 do
		local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
		local choice = bxor(band(e, f), band(bnot(e), g))
		local t1 = (h + s1 + choice + K[i] + w[i]) % 0x1_0000_0000
		local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
		local t2 = (s0 + bxor(band(a, b), band(a, c), band(b, c))) % 0x1_0000_0000
		h = g
		g = f
		f = e
		e = (d + t1) % 0x1_0000_0000
		d = c
		c = b
		b = a
		a = (t1 + t2) % 0x1_0000_0000
	end
	state[1] = (state[1] + a) % 0x1_0000_0000
	state[2] = (state[2] + b) % 0x1_0000_0000
	state[3] = (state[3] + c) % 0x1_0000_0000
	state[4] = (state[4] + d) % 0x1_0000_0000
	state[5] = (state[5] + e) % 0x1_0000_0000
	state[6] = (state[6] + f) % 0x1_0000_0000
	state[7] = (state[7] + g) % 0x1_0000_0000
	state[8] = (state[8] + h) % 0x1_0000_0000
end

function sha256.digest(bytes: buffer): string
	local state = { 0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19 }
	local len = buffer.len(bytes)
	local full = len // 64
	for block = 0, full - 1 do
		compress(state, bytes, block * 64)
	end
	local remainder = len - full * 64
	local tail = buffer.create(128)
	buffer.copy(tail, 0, bytes, full * 64, remainder)
	buffer.writeu8(tail, remainder, 0x80)
	local end_ = if remainder < 56 then 64 else 128
	-- (len * 8) как u64 big-endian.
	local bits = len * 8
	local hi = bits // 0x1_0000_0000
	local lo = bits % 0x1_0000_0000
	for i = 0, 3 do
		buffer.writeu8(tail, end_ - 8 + i, band(rshift(hi, 24 - 8 * i), 255))
		buffer.writeu8(tail, end_ - 4 + i, band(rshift(lo, 24 - 8 * i), 255))
	end
	compress(state, tail, 0)
	if end_ == 128 then
		compress(state, tail, 64)
	end
	local parts = {}
	for i, v in state do
		parts[i] = string.format("%08x", v)
	end
	return table.concat(parts)
end

return sha256
