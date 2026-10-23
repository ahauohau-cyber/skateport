--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/state_graph.rs (коммит 2e16697)
--
-- Stock TU3 `.stategraph` decoding, independent of graph execution.
--
-- ReadElement 82C15DE0 reads a NUL-terminated tag, BinaryAttributeMap
-- 82C14F38, a big-endian child count, then children in file order.
-- Each attribute stores two strings, a float word and a boolean byte.
-- Keep all three representations: parsing the string again loses stock data.
-- ROBLOX: &[u8] -> buffer; fs::read -> files.read; AssetError -> rt.raise(строка).

local rt = require("../rt")
local files = require("./files")

local state_graph = {}

export type GraphAttribute = {
	name: string,
	text: string,
	float_bits: number,
	boolean_byte: number,
}

-- ROBLOX: source_offset — смещение в байтах с нуля; children — индексы
-- элементов с нуля (в Rust usize).
export type GraphElement = {
	-- Byte offset of the tag in the original file, for binding diagnostics.
	source_offset: number,
	tag: string,
	-- File order, including duplicate names. Native hash-map binding is a
	-- separate operation; the decoder must not silently discard attributes.
	attributes: { GraphAttribute },
	-- Indices into StateGraph::elements, in original child order.
	children: { number },
}

export type StateGraph = {
	-- Preorder arena. Element zero is the single file root.
	elements: { GraphElement },
}

local StateGraph = {}
state_graph.StateGraph = StateGraph

type Reader = { bytes: buffer, offset: number }

local function reader_error(self: Reader, message: string): string
	return string.format("stategraph byte 0x%X: %s", self.offset, message)
end

local function take(self: Reader, count: number): number
	if count > buffer.len(self.bytes) - self.offset then
		rt.raise(reader_error(self, "truncated record"))
	end
	local begin = self.offset
	self.offset += count
	return begin
end

local function word(self: Reader): number
	local at = take(self, 4)
	return bit32.byteswap(buffer.readu32(self.bytes, at))
end

local function read_string(self: Reader): string
	local len = buffer.len(self.bytes)
	local length = -1
	for i = self.offset, len - 1 do
		if buffer.readu8(self.bytes, i) == 0 then
			length = i - self.offset
			break
		end
	end
	if length < 0 then
		rt.raise(reader_error(self, "unterminated string"))
	end
	local offset = self.offset
	take(self, length + 1)
	local s = buffer.readstring(self.bytes, offset, length)
	-- Native storage is bytes. Unsupported encodings fail explicitly;
	-- lossy conversion could change node names or binding keys.
	if utf8.len(s) == nil then
		rt.raise(string.format("stategraph byte 0x%X: non-UTF-8 string", offset))
	end
	return s
end

local function element(self: Reader): (GraphElement, number)
	local source_offset = self.offset
	local tag = read_string(self)
	local attribute_count = word(self)
	-- Each attribute requires at least two terminators, four bytes and
	-- one byte. Bound allocations by actual input, not a guessed graph cap.
	if attribute_count > (buffer.len(self.bytes) - self.offset) // 7 then
		rt.raise(reader_error(self, "attribute count exceeds remaining data"))
	end
	local attributes: { GraphAttribute } = table.create(attribute_count) :: any
	for _ = 1, attribute_count do
		local name = read_string(self)
		local text = read_string(self)
		local float_bits = word(self)
		local boolean_byte = buffer.readu8(self.bytes, take(self, 1))
		table.insert(attributes, { name = name, text = text, float_bits = float_bits, boolean_byte = boolean_byte })
	end
	local children = word(self)
	-- A minimal child is one terminator and two four-byte counts.
	if children > (buffer.len(self.bytes) - self.offset) // 9 then
		rt.raise(reader_error(self, "child count exceeds remaining data"))
	end
	return { source_offset = source_offset, tag = tag, attributes = attributes, children = {} }, children
end

-- ROBLOX: Result<Self, AssetError> -> StateGraph или rt.raise(строка).
function StateGraph.decode(bytes: buffer): StateGraph
	local reader: Reader = { bytes = bytes, offset = 0 }
	local root, children = element(reader)
	local elements = { root }
	-- ROBLOX: стек пар (индекс родителя с нуля, оставшиеся дети).
	local parents = { { 0, children } }
	-- The native reader recurses. An explicit stack preserves preorder and
	-- permits deeply nested input without depending on the host stack size.
	while #parents > 0 do
		local top = parents[#parents]
		if top[2] == 0 then
			table.remove(parents)
			continue
		end
		top[2] -= 1
		local e, c = element(reader)
		local index = #elements
		table.insert(elements[top[1] + 1].children, index)
		table.insert(elements, e)
		table.insert(parents, { index, c })
	end
	if reader.offset ~= buffer.len(bytes) then
		rt.raise(reader_error(reader, "trailing bytes after the root element"))
	end
	return { elements = elements }
end

-- ROBLOX: path — путь в упакованных файлах (files.luau), без "private/".
function StateGraph.load(path: string): StateGraph
	local bytes, err = rt.catch(files.read, path)
	if err ~= nil then
		rt.raise(string.format("Cannot read graph %s: %s", path, tostring(err)))
	end
	local graph, err2 = rt.catch(StateGraph.decode, bytes)
	if err2 ~= nil then
		rt.raise(string.format("Invalid graph %s: %s", path, tostring(err2)))
	end
	return graph
end

state_graph.attributes = require("@self/attributes")
state_graph.binding = require("@self/binding")

return state_graph
