--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/intents.rs (коммит 2e16697)
--
-- Fixed intent-map specialization constructed by 8258F638, used at full
-- MotionGraph+12 (82C0E088) and physics packet+8 (8258FEE8).
-- Names are six encoded words; no guessed text hashing or guest addresses.

local rt = require("../../../rt")

local intents = {}

intents.BUCKET_COUNT = 61
intents.ENTRY_CAPACITY = 64

-- ROBLOX: IntentName(pub [u32; 6]) -> таблица из 6 слов.
export type IntentName = { number }
export type Intent = { name: IntentName, value: number }

local function name_eq(a: IntentName, b: IntentName): boolean
	for i = 1, 6 do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end

local function bucket_of(name: IntentName): number
	local hash = 0
	for i = 1, 6 do
		hash = rt.wrapping_add_u32(hash, name[i])
	end
	return hash % intents.BUCKET_COUNT + 1
end

-- Native construction takes greatest prime<=65 (61), installs 64 nodes, then
-- changes maximum load to 10000. Thus every valid state of this specialization
-- stays at 61 buckets; generic rehash policy is unreachable before exhaustion.
-- Owned bucket vectors represent chains in traversal order.
export type IntentMap = { buckets: { { Intent } }, len: number }

local IntentMap = {}
intents.IntentMap = IntentMap

function IntentMap.default(): IntentMap
	local buckets = {}
	for i = 1, intents.BUCKET_COUNT do
		buckets[i] = {}
	end
	return { buckets = buckets, len = 0 }
end

function IntentMap.len(self: IntentMap): number
	return self.len
end
function IntentMap.is_empty(self: IntentMap): boolean
	return self.len == 0
end

function IntentMap.get(self: IntentMap, name: IntentName): number?
	for _, entry in self.buckets[bucket_of(name)] do
		if name_eq(entry.name, name) then
			return entry.value
		end
	end
	return nil
end

-- 826C20B0/825A0350: ascending buckets, head-to-tail within each chain.
function IntentMap.entries(self: IntentMap): { Intent }
	local out = {}
	for _, bucket in self.buckets do
		for _, entry in bucket do
			table.insert(out, entry)
		end
	end
	return out
end

-- 82472CD0/82472E10/824714D0: wrapping sum of all six words, exact
-- six-word equality, prepend new entries. Existing values are preserved.
-- At exhausted capacity native faults; the host rejects the new entry.
-- ROBLOX: Result<bool, IntentCapacityExceeded> -> bool или rt.raise("IntentCapacityExceeded").
function IntentMap.insert(self: IntentMap, intent: Intent): boolean
	local bucket = self.buckets[bucket_of(intent.name)]
	for _, entry in bucket do
		if name_eq(entry.name, intent.name) then
			return false
		end
	end
	if self.len == intents.ENTRY_CAPACITY then
		rt.raise("IntentCapacityExceeded")
	end
	table.insert(bucket, 1, { name = intent.name, value = intent.value })
	self.len += 1
	return true
end

-- Set the value at an existing native key, or insert a new key. The
-- native 82471818 lookup returns a value slot before the caller writes
-- it, so Set must overwrite an existing entry rather than silently
-- preserving it as `insert` does.
function IntentMap.set(self: IntentMap, name: IntentName, value: number): boolean
	for _, entry in self.buckets[bucket_of(name)] do
		if name_eq(entry.name, name) then
			entry.value = value
			return false
		end
	end
	return IntentMap.insert(self, { name = name, value = value })
end

-- Remove one exact six-word key using the same bucket and chain order as
-- native 82BC1068. Removing an entry leaves the relative order of the
-- remaining chain untouched.
function IntentMap.remove(self: IntentMap, name: IntentName): boolean
	local bucket = self.buckets[bucket_of(name)]
	for i, entry in bucket do
		if name_eq(entry.name, name) then
			table.remove(bucket, i)
			self.len -= 1
			return true
		end
	end
	return false
end

-- Apply the graph host's existing mutation protocol at one decoded key.
-- `IntentName` is deliberately supplied by the graph decoder: this
-- module does not invent a string-to-six-word encoding.
function IntentMap.apply(self: IntentMap, name: IntentName, mutation: any): boolean
	if mutation.kind == "None" then
		return false
	elseif mutation.kind == "Remove" then
		return IntentMap.remove(self, name)
	end
	return IntentMap.set(self, name, mutation.value)
end

-- 82BC1B68 clears all chains but preserves bucket configuration.
function IntentMap.clear(self: IntentMap)
	for _, bucket in self.buckets do
		table.clear(bucket)
	end
	self.len = 0
end

-- 825936FC..82593740: clear then range-insert, not a structural clone.
-- Each colliding source chain therefore reverses in the destination.
-- Canonical graph and packet are distinct owned maps. A caller binding a
-- map to itself must retain it instead, matching the native identity guard.
function IntentMap.replace_from(self: IntentMap, source: IntentMap)
	local entries = IntentMap.entries(source)
	IntentMap.clear(self)
	for _, entry in entries do
		-- Both maps enforce the same 64-entry bound and exact key uniqueness.
		IntentMap.insert(self, entry)
	end
end

return intents
