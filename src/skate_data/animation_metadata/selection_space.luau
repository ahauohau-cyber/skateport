--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/animation_metadata/selection_space.rs (коммит 2e16697)
--
-- Type11 layout from original 82D1BEA0, 82D26CC0 and 82D26FF8.
-- ROBLOX: validate_name из animation_metadata (init.luau) подставляет init
-- в поле selection_space.validate_name (без циклического require).

local rt = require("../../rt")
local abin_reader = require("../abin/reader")

local Reader = abin_reader.Reader
local from_bits = rt.from_bits
local is_finite = rt.is_finite

local selection_space = {}
selection_space.validate_name = (nil :: any) :: (string, number) -> ()

export type SelectionParameterMetadata = {
	name: string,
	mode: number,
	weight_bits: number,
	minimum_bits: number,
	maximum_bits: number,
}

export type SelectionCandidateMetadata = {
	child: string,
	value_bits: { number },
}

export type SelectionSpaceMetadata = {
	name: string,
	source_offset: number,
	parameters: { SelectionParameterMetadata },
	candidates: { SelectionCandidateMetadata },
}

-- ROBLOX: Result<(), String> -> rt.raise(строка).
function selection_space.validate(self: SelectionSpaceMetadata, bytes: number)
	local validate_name = selection_space.validate_name
	validate_name(self.name, 36)
	if self.source_offset >= bytes or #self.parameters > 10 or #self.candidates == 0 then
		rt.raise(string.format("%s: invalid selection space dimensions", self.name))
	end
	for _, p in self.parameters do
		validate_name(p.name, 30)
		for _, v in { p.weight_bits, p.minimum_bits, p.maximum_bits } do
			if not is_finite(from_bits(v)) then
				rt.raise(string.format("%s: nonfinite selection metric", self.name))
			end
		end
	end
	for _, c in self.candidates do
		validate_name(c.child, 36)
		local bad = #c.value_bits ~= #self.parameters
		for _, v in c.value_bits do
			if not is_finite(from_bits(v)) then
				bad = true
			end
		end
		if bad then
			rt.raise(string.format("%s: invalid selection candidate", self.name))
		end
	end
end

local function fail(offset: number, message: string): never
	return rt.raise({ offset = offset, message = message })
end

function selection_space.read(r: abin_reader.Reader, h: any): SelectionSpaceMetadata
	local p = h.payload_offset
	local count = Reader.u32(r, p)
	if count > 10 then
		fail(p, "selection parameter array exceeds native capacity")
	end
	local parameters_at = Reader.relative(r, p, Reader.u32(r, p + 4), count * 40)
	local candidates_count = Reader.u32(r, p + 8)
	local candidates_at = Reader.relative(r, p, Reader.u32(r, p + 12), 4)
	local stride = Reader.u32(r, candidates_at)
	local size = stride * candidates_count
	Reader.take(r, candidates_at, size)
	if stride < 32 then
		fail(candidates_at, "selection candidate header too small")
	end
	local parameters = {}
	for i = 0, count - 1 do
		local at = parameters_at + i * 40
		table.insert(parameters, {
			name = Reader.name(r, at, 6),
			mode = Reader.u32(r, at + 24),
			weight_bits = Reader.u32(r, at + 28),
			minimum_bits = Reader.u32(r, at + 32),
			maximum_bits = Reader.u32(r, at + 36),
		})
	end
	local candidates = {}
	for i = 0, candidates_count - 1 do
		local at = candidates_at + i * stride
		local child_reader = Reader.bounded(r, at, at + stride)
		local values = Reader.relative(child_reader, at, Reader.u32(child_reader, at + 28), count * 4)
		local value_bits = {}
		for j = 0, count - 1 do
			table.insert(value_bits, Reader.u32(child_reader, values + j * 4))
		end
		table.insert(candidates, { child = Reader.name(child_reader, at + 4, 6), value_bits = value_bits })
	end
	return { name = h.name, source_offset = h.offset, parameters = parameters, candidates = candidates }
end

return selection_space
