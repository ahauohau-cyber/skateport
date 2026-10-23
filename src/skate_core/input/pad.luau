--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/pad.rs (коммит 2e16697)
--
-- Native pad publication 82966F30; retained records use their big-endian words.

local rt = require("../../rt")

local to_bits = rt.to_bits

local pad = {}

-- ROBLOX: records: Vec<[u32; 4]> -> таблица записей по 4 слова (индексы с 1).
export type Pad = { records: { { number } }, count: number }

local Pad = {}
pad.Pad = Pad

-- An empty native cInputPad. 8296D288/826986A8 initialize the published
-- count to zero; records become initialized only when a larger count is
-- published by 82966F30.
function Pad.new(): Pad
	return { records = {}, count = 0 }
end

-- Existing initialized native records. The native count is their length.
function Pad.from_records(records: { { number } }): Pad
	return { records = records, count = #records }
end

function Pad.from_storage(records: { { number } }, count: number): Pad
	assert(count <= #records)
	return { records = records, count = count }
end

function Pad.count(self: Pad): number
	return self.count
end

function Pad.records(self: Pad): { { number } }
	return self.records
end

-- Complete update, including growth reset, updated count on shorter
-- polls, three-call edge suppression and 24/12-call repeat intervals.
function Pad.update(self: Pad, values: { number })
	local n = #values
	if n > self.count then
		for i = #self.records + 1, n do
			self.records[i] = { 0, 0, 0, 0 }
		end
		for i = self.count + 1, n do
			self.records[i] = { 0, 0, 0, 0 }
		end
	end
	self.count = n
	for i = 1, n do
		local record = self.records[i]
		local value = values[i]
		record[1] = to_bits(value)
		local down = if value > 0.5 then 1 else 0
		local held = bit32.band(bit32.rshift(record[2], 8), 255)
		if rt.to_i32(record[4]) < 3 then
			record[4] = rt.wrapping_add_u32(record[4], 1)
			record[2] = bit32.band(record[2], 0xffff)
		elseif down == held then
			record[2] = bit32.band(record[2], 0xffff)
		else
			record[2] = bit32.bor(bit32.band(record[2], 255), bit32.lshift(down, 8), if down ~= 0 then bit32.lshift(1, 24) else bit32.lshift(1, 16))
			record[4] = 0
		end
		if bit32.band(record[2], 0xff00) ~= 0 then
			if record[3] == 0 then
				record[2] = bit32.bor(bit32.band(record[2], bit32.bnot(255)), 1)
				record[3] = 24
			else
				record[3] = rt.wrapping_sub_u32(record[3], 1)
				if record[3] == 0 then
					record[2] = bit32.bor(bit32.band(record[2], bit32.bnot(255)), 1)
					record[3] = 12
				else
					record[2] = bit32.band(record[2], bit32.bnot(255))
				end
			end
		else
			record[3] = 0
			record[2] = bit32.band(record[2], bit32.bnot(255))
		end
	end
end

return pad
