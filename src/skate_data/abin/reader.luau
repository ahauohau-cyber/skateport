--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/abin/reader.rs (коммит 2e16697)
--
-- Checked big-endian reads with absolute offsets retained through subrecords.
-- ROBLOX: &[u8] -> buffer; ошибки abin — rt.raise({ offset, message }).

local rt = require("../../rt")

local reader = {}

export type Reader = { bytes: buffer, begin: number, ["end"]: number }

local Reader = {}
reader.Reader = Reader

local function fail(offset: number, message: string): never
	return rt.raise({ offset = offset, message = message })
end
reader.fail = fail

function Reader.new(bytes: buffer): Reader
	return { bytes = bytes, begin = 0, ["end"] = buffer.len(bytes) }
end

-- ROBLOX: возвращает смещение начала проверенного диапазона (байты читаются из buffer).
function Reader.take(self: Reader, offset: number, size: number): number
	local e = offset + size
	if offset < self.begin or e > self["end"] then
		fail(offset, string.format("read size%d exceeds record %#x..%#x", size, self.begin, self["end"]))
	end
	return offset
end

-- ROBLOX: range Range<usize> -> (start, end).
function Reader.bounded(self: Reader, start: number, end_: number): Reader
	if end_ < start then
		fail(start, "reversed record range")
	end
	Reader.take(self, start, end_ - start)
	return { bytes = self.bytes, begin = start, ["end"] = end_ }
end

function Reader.u8(self: Reader, offset: number): number
	Reader.take(self, offset, 1)
	return buffer.readu8(self.bytes, offset)
end
function Reader.u16(self: Reader, offset: number): number
	Reader.take(self, offset, 2)
	return bit32.bor(bit32.lshift(buffer.readu8(self.bytes, offset), 8), buffer.readu8(self.bytes, offset + 1))
end
local function be32(b: buffer, at: number): number
	return bit32.bor(bit32.lshift(buffer.readu8(b, at), 24), bit32.lshift(buffer.readu8(b, at + 1), 16), bit32.lshift(buffer.readu8(b, at + 2), 8), buffer.readu8(b, at + 3))
end
reader.be32 = be32
function Reader.u32(self: Reader, offset: number): number
	Reader.take(self, offset, 4)
	return be32(self.bytes, offset)
end
function Reader.i32(self: Reader, offset: number): number
	return rt.to_i32(Reader.u32(self, offset))
end
-- ROBLOX: words::<N> -> words(offset, n).
function Reader.words(self: Reader, offset: number, n: number): { number }
	Reader.take(self, offset, n * 4)
	local out: { number } = {}
	for i = 0, n - 1 do
		out[i + 1] = be32(self.bytes, offset + 4 * i)
	end
	return out
end

local ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_"

-- Five words encode FastString30, six encode FastString36. Names stay
-- uppercase as authored; padding remains word-local, matching stock names.
function Reader.name(self: Reader, offset: number, words: number): string
	Reader.take(self, offset, words * 4)
	local result = {}
	for w = 0, words - 1 do
		local value = be32(self.bytes, offset + 4 * w)
		local divisor = 79235168 -- 38^5
		for _ = 1, 6 do
			local digit = value // divisor
			value = value % divisor
			if digit == 0 then
				if value ~= 0 then
					fail(offset, "invalid FastString padding")
				end
				break
			end
			if digit > #ALPHABET then
				fail(offset, "invalid FastString digit")
			end
			table.insert(result, string.sub(ALPHABET, digit, digit))
			divisor //= 38
		end
	end
	return table.concat(result)
end

-- pub(crate) fn relative -> (start, end).
function Reader.relative(self: Reader, base: number, offset: number, size: number): (number, number)
	local start = base + offset
	Reader.take(self, start, size)
	return start, start + size
end

return reader
