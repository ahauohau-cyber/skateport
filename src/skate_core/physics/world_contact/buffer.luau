--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/buffer.rs (коммит 2e16697)

local rt = require("../../../rt")
local arithmetic = require("./arithmetic")
local reduction = require("./reduction")

local dot, sub, vector = arithmetic.dot, arithmetic.sub, arithmetic.vector
local wrapping_add_u32 = rt.wrapping_add_u32

local buffer_mod = {}

-- Native TempContactBuffer state (+0/+4/+8/+12/+16, +128 records,
-- +12940/+12941/+12942 flags). Caller supplies the actual constructor settings.
-- Guest allocator/publication pointers are represented by the flush callback.
export type ContactBuffer = {
	count: number, -- u32
	flushed: number, -- u32
	capacity: number, -- u32
	dropped: number, -- u32
	distance_squared_threshold: number, -- f32
	allow_flush: number, -- u8
	deferred_reduction: number, -- u8
	full: number, -- u8
	records: { { number } }, -- [ContactRecord; 50]
}

local ContactBuffer = {}
buffer_mod.ContactBuffer = ContactBuffer

-- ROBLOX: f64::from_bits(0x3fee_147a_e147_ae14)
local DUPLICATE_NORMAL_DOT = rt.f64_from_bits(0x3fee_147a, 0xe147_ae14)

-- ROBLOX: #[derive(Clone)] для ContactBuffer.
function ContactBuffer.clone(self: ContactBuffer): ContactBuffer
	local records = table.create(50) :: { { number } }
	for i, record in self.records do
		records[i] = table.clone(record)
	end
	return {
		count = self.count,
		flushed = self.flushed,
		capacity = self.capacity,
		dropped = self.dropped,
		distance_squared_threshold = self.distance_squared_threshold,
		allow_flush = self.allow_flush,
		deferred_reduction = self.deferred_reduction,
		full = self.full,
		records = records,
	}
end

-- ROBLOX: срез &self.records[..count] для sink — новая таблица со ссылками на записи.
local function first_records(self: ContactBuffer): { { number } }
	return table.move(self.records, 1, self.count, 1, {})
end

-- pub fn reduce(&mut self)
function ContactBuffer.reduce(self: ContactBuffer)
	self.count = reduction.reduce(self.records, self.count)
end

-- Complete 82779E40; sink is the caller's 8277B428 publication operation.
-- Flushed counts advance by the reduced count, irrespective of sink result.
-- pub fn flush(&mut self, sink: &mut impl FnMut(&[ContactRecord]))
function ContactBuffer.flush(self: ContactBuffer, sink: ({ { number } }) -> ())
	if self.count == 0 then
		return
	end
	if self.deferred_reduction ~= 0 then
		ContactBuffer.reduce(self)
	end
	sink(first_records(self))
	self.flushed = wrapping_add_u32(self.flushed, self.count)
	self.count = 0
end

-- Complete 82779D60. A full physical buffer with flushing disabled sets
-- the full flag but does not increment dropped until a subsequent call.
-- pub fn allocate(&mut self, sink) -> Option<usize>
-- ROBLOX: индекс записи — как в Rust (с нуля), сама запись в records[index + 1].
function ContactBuffer.allocate(self: ContactBuffer, sink: ({ { number } }) -> ()): number?
	assert(self.count <= 50)
	if wrapping_add_u32(self.count, self.flushed) >= self.capacity then
		if self.full == 0 then
			if self.deferred_reduction ~= 0 then
				ContactBuffer.reduce(self)
			end
			if wrapping_add_u32(self.count, self.flushed) >= self.capacity then
				self.full = 1
			end
		end
		if self.full ~= 0 then
			self.dropped = wrapping_add_u32(self.dropped, 1)
			return nil
		end
	end
	if self.count >= 50 then
		if self.allow_flush == 0 then
			self.full = 1
			return nil
		end
		ContactBuffer.flush(self, sink)
	end
	local index = self.count
	self.count += 1
	return index
end

-- Complete 82779C18. Tests the most recently allocated record against all
-- previous records. The native caller, not this function, decrements count.
-- pub fn last_is_duplicate(&mut self) -> bool
function ContactBuffer.last_is_duplicate(self: ContactBuffer): boolean
	if self.distance_squared_threshold < 0.0 or self.deferred_reduction ~= 0 then
		return false
	end
	assert(self.count > 0 and self.count <= 50)
	local current = self.records[self.count]
	for k = 1, self.count - 1 do
		local previous = self.records[k]
		if previous[4] ~= current[4] or previous[8] ~= current[8] then
			continue
		end
		local a = sub(vector(previous, 0), vector(current, 0))
		local b = sub(vector(previous, 4), vector(current, 4))
		if
			self.distance_squared_threshold > dot(a, a)
			and dot(b, b) < self.distance_squared_threshold
			and dot(vector(previous, 8), vector(current, 8)) > DUPLICATE_NORMAL_DOT
		then
			self.dropped = wrapping_add_u32(self.dropped, 1)
			return true
		end
	end
	return false
end

return buffer_mod
