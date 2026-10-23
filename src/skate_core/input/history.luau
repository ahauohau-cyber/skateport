--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/history.rs (коммит 2e16697)
--
-- Native controller history owner (`8296D0D0`, `8296D1F0`, `82699230`).
--
-- The cache is thirty frame batches. Each batch contains four 100-byte
-- records, one per registered device. A record contains a value count and
-- up to 24 native float values. Startup is read=0 and write=1.

local pad = require("./pad")

local history = {}

history.HISTORY_CAPACITY = 30
history.DEVICE_SLOTS = 4
history.MAX_VALUES = 24
local CAP = 30

export type HistoryRecord = { values: { number }, count: number }

local HistoryRecord = {}
history.HistoryRecord = HistoryRecord

function HistoryRecord.new(values: { number }): HistoryRecord
	assert(#values <= history.MAX_VALUES)
	local v = table.create(history.MAX_VALUES, 0.0)
	for i, x in values do
		v[i] = x
	end
	return { values = v, count = #values }
end
function HistoryRecord.count(self: HistoryRecord): number
	return self.count
end
function HistoryRecord.values(self: HistoryRecord): { number }
	return table.move(self.values, 1, self.count, 1, {})
end
-- Failed device polls clear publication count while retaining value words.
function HistoryRecord.clear_count(self: HistoryRecord)
	self.count = 0
end
local function copy_record(r: HistoryRecord): HistoryRecord
	return { values = table.clone(r.values), count = r.count }
end

-- ROBLOX: read/write — индексы с нуля, как в Rust; batches[i + 1].
export type PadHistory = { batches: { { HistoryRecord } }, read: number, write: number }

local PadHistory = {}
history.PadHistory = PadHistory

-- Matches `826986A8`: zeroed storage, read index 0, write index 1.
function PadHistory.new(): PadHistory
	local batches = {}
	for b = 1, CAP do
		local batch = {}
		for d = 1, history.DEVICE_SLOTS do
			batch[d] = HistoryRecord.new({})
		end
		batches[b] = batch
	end
	return { batches = batches, read = 0, write = 1 }
end
function PadHistory.read_index(self: PadHistory): number
	return self.read
end
function PadHistory.write_index(self: PadHistory): number
	return self.write
end

-- `8296D0D0` copies the registered-device prefix into one frame batch,
-- then advances the producer once. Uncopied slots retain their contents;
-- an empty poll still advances the producer.
function PadHistory.publish(self: PadHistory, records: { HistoryRecord })
	assert(#records <= history.DEVICE_SLOTS)
	for i, r in records do
		self.batches[self.write + 1][i] = copy_record(r)
	end
	self.write = (self.write + 1) % CAP
end

local function is_empty(self: PadHistory): boolean
	return (self.read + 1) % CAP == self.write
end

-- `82699230` drains to the newest available batch and updates all Pads
-- exactly once with that batch.
function PadHistory.drain_to_latest(self: PadHistory, pads: { any }): boolean
	if is_empty(self) then
		return false
	end
	local latest = self.read
	while (self.read + 1) % CAP ~= self.write do
		self.read = (self.read + 1) % CAP
		latest = self.read
	end
	for i, p in pads do
		pad.Pad.update(p, HistoryRecord.values(self.batches[latest + 1][i]))
	end
	return true
end

return history
