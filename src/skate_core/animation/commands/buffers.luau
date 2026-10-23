--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/commands/buffers.rs (коммит 2e16697)
--
-- Typed animation allocations. Slots identify whole allocations, never addresses.

local rt = require("../../../rt")

local buffers = {}

-- ROBLOX: AtomicUsize -> счётчик модуля (Luau однопоточный).
local next_owner = 0
function buffers.new_owner(): number
	local value = next_owner
	next_owner += 1
	return value
end

-- ROBLOX: Buffer<T> { slot, owner } без PhantomData; slot — с нуля.
export type Buffer = { slot: number, owner: number }
export type BoneSlice = { buffer: Buffer, first_bone: number }

function buffers.at(buffer: Buffer, first_bone: number): BoneSlice
	return { buffer = buffer, first_bone = first_bone }
end

-- ROBLOX: enum BufferError -> { kind = "UnknownBuffer" | "RangeOutsideAllocation"
-- | "UninitializedBone" | "UnsupportedPartialOverlap", bone = number? }.
export type BufferError = { kind: string, bone: number? }

-- ROBLOX: Vec<Vec<Option<T>>> -> таблицы, None -> false.
export type BoneBuffers = { owner: number, allocations: { { any } } }

local BoneBuffers = {}
buffers.BoneBuffers = BoneBuffers

function BoneBuffers.default(): BoneBuffers
	return { owner = buffers.new_owner(), allocations = {} }
end

-- ROBLOX: T: Copy — значения копируются целиком (вложенные таблицы клонируются).
local function deep(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local out = table.clone(v)
	for k, x in out do
		if type(x) == "table" then
			out[k] = deep(x)
		end
	end
	return out
end
buffers.deep = deep

local function insert(self: BoneBuffers, allocation: { any }): Buffer
	local slot = #self.allocations
	table.insert(self.allocations, allocation)
	return { slot = slot, owner = self.owner }
end

-- Allocate exactly the requested extent without inventing a bind pose.
function BoneBuffers.allocate(self: BoneBuffers, count: number): Buffer
	return insert(self, table.create(count, false))
end

function BoneBuffers.initialized(self: BoneBuffers, values: { any }): Buffer
	local a = {}
	for i, v in values do
		a[i] = deep(v)
	end
	return insert(self, a)
end

-- ROBLOX: возвращает (first, end) — полуинтервал костей с нуля.
local function range(self: BoneBuffers, source: BoneSlice, count: number): (number, number)
	if source.buffer.owner ~= self.owner then
		rt.raise({ kind = "UnknownBuffer" })
	end
	local allocation = self.allocations[source.buffer.slot + 1]
	if allocation == nil then
		rt.raise({ kind = "UnknownBuffer" })
	end
	local end_ = source.first_bone + count
	if end_ > #allocation then
		rt.raise({ kind = "RangeOutsideAllocation" })
	end
	return source.first_bone, end_
end

-- ROBLOX: Result<Vec<T>, BufferError> -> таблица или rt.raise(BufferError).
function BoneBuffers.read(self: BoneBuffers, source: BoneSlice, count: number): { any }
	if count == 0 then
		return {}
	end
	local first, end_ = range(self, source, count)
	local allocation = self.allocations[source.buffer.slot + 1]
	local out = {}
	for bone = first, end_ - 1 do
		local v = allocation[bone + 1]
		if v == false then
			rt.raise({ kind = "UninitializedBone", bone = bone })
		end
		table.insert(out, deep(v))
	end
	return out
end

function BoneBuffers.copy(self: BoneBuffers, source: BoneSlice, destination: BoneSlice, count: number)
	if count == 0 then
		return
	end
	local from_start, from_end = range(self, source, count)
	local to_start, to_end = range(self, destination, count)
	if source.buffer.slot == destination.buffer.slot then
		if from_start == to_start and from_end == to_end then
			return
		end
		if from_start < to_end and to_start < from_end then
			rt.raise({ kind = "UnsupportedPartialOverlap" })
		end
	end
	-- Copy validity alongside the value: native SET does not initialize
	-- unwritten bones. Such exports remain unreadable, rather than zero-filled.
	local src = self.allocations[source.buffer.slot + 1]
	local dst = self.allocations[destination.buffer.slot + 1]
	for i = 0, count - 1 do
		dst[to_start + i + 1] = deep(src[from_start + i + 1])
	end
end

export type PoseBuffers = { sqt: BoneBuffers, matrices: BoneBuffers }

function buffers.pose_buffers_default(): PoseBuffers
	return { sqt = BoneBuffers.default(), matrices = BoneBuffers.default() }
end

return buffers
