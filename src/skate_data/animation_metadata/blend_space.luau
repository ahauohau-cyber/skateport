--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/animation_metadata/blend_space.rs (коммит 2e16697)
--
-- Andale type6: construction82D1B8D0, layout82D22DA0, simplex82D23898.
-- ROBLOX: validate_name из animation_metadata (init.luau) подставляет init
-- в поле blend_space.validate_name (без циклического require).

local rt = require("../../rt")
local abin_reader = require("../abin/reader")

local Reader = abin_reader.Reader
local from_bits = rt.from_bits
local is_finite = rt.is_finite

local blend_space = {}
blend_space.validate_name = (nil :: any) :: (string, number) -> ()

-- ROBLOX: children — индексы детей с нуля.
export type BlendSimplexMetadata = {
	children: { number },
	-- Spatial coordinates only; the serialized matrix also has a final column.
	vertex_bits: { { number } },
	normal_bits: { { number } },
	scale_bits: { number },
}

export type BlendSpaceMetadata = {
	name: string,
	source_offset: number,
	parameters: { string },
	children: { string },
	simplexes: { BlendSimplexMetadata },
}

-- ROBLOX: Result<(), String> -> rt.raise(строка).
function blend_space.validate(self: BlendSpaceMetadata, bytes: number)
	local validate_name = blend_space.validate_name
	validate_name(self.name, 36)
	local d = #self.parameters
	if self.source_offset >= bytes or d == 0 or d > 4 or #self.children < d + 1 or #self.simplexes == 0 then
		rt.raise(string.format("%s: invalid BlendSpace dimensions/offset", self.name))
	end
	for _, name in self.parameters do
		validate_name(name, 30)
	end
	for _, name in self.children do
		validate_name(name, 36)
	end
	for _, s in self.simplexes do
		local bad = #s.children ~= d + 1 or #s.scale_bits ~= d + 1 or #s.vertex_bits ~= d + 1 or #s.normal_bits ~= d + 1
		if not bad then
			for _, i in s.children do
				if i >= #self.children then
					bad = true
				end
			end
			for _, list in { s.vertex_bits, s.normal_bits } do
				for _, v in list do
					if #v ~= d then
						bad = true
					end
					for _, w in v do
						if not is_finite(from_bits(w)) then
							bad = true
						end
					end
				end
			end
			for _, w in s.scale_bits do
				if not is_finite(from_bits(w)) then
					bad = true
				end
			end
		end
		if bad then
			rt.raise(string.format("%s: invalid BlendSpace simplex", self.name))
		end
	end
end

local function fail(offset: number, message: string): never
	return rt.raise({ offset = offset, message = message })
end

-- ROBLOX: Result<_> (abin::Error) -> rt.raise({ offset, message }).
function blend_space.read(r: abin_reader.Reader, h: any): BlendSpaceMetadata
	local p = h.payload_offset
	local count = Reader.u32(r, p)
	local names = Reader.relative(r, p, Reader.u32(r, p + 4), count * 24)
	local q = Reader.relative(r, p, Reader.u32(r, p + 12), 44)
	local ss, se = Reader.relative(r, q, 0, Reader.u32(r, q))
	local space = Reader.bounded(r, ss, se)
	local d = Reader.u32(space, q + 28)
	if d == 0 or d > 4 or d > Reader.u32(r, p + 16) then
		fail(q + 28, "invalid BlendSpace dimension")
	end
	local params = Reader.relative(space, q, Reader.u32(space, q + 32), d * 20)
	local simplex_count = Reader.u32(space, q + 36)
	-- Every record must at least contain its header; bound the count before allocating.
	Reader.relative(space, q, Reader.u32(space, q + 40), simplex_count * 20)
	local at = Reader.relative(space, q, Reader.u32(space, q + 40), 20)
	local simplexes = {}
	for _ = 1, simplex_count do
		local size = Reader.u32(space, at)
		local s0, s1 = Reader.relative(space, at, 0, size)
		local s = Reader.bounded(space, s0, s1)
		if Reader.u32(s, at + 16) ~= d + 1 then
			fail(at + 16, "BlendSpace matrix dimension mismatch")
		end
		Reader.take(s, at + 20, (d + 1) * (d + 1) * 4)
		local indices = Reader.relative(s, at, Reader.u32(s, at + 4), (d + 1) * 4)
		local scales = Reader.relative(s, at, Reader.u32(s, at + 8), (d + 1) * 4)
		local normals = Reader.relative(s, at, Reader.u32(s, at + 12), (d + 1) * (d + 1) * 4)
		local simplex: BlendSimplexMetadata = { children = {}, vertex_bits = {}, normal_bits = {}, scale_bits = {} }
		for i = 0, d do
			local normal = normals + i * (d + 1) * 4
			if Reader.u32(s, normal) ~= d then
				fail(normal, "BlendSpace normal dimension mismatch")
			end
			table.insert(simplex.children, Reader.u32(s, indices + i * 4))
			table.insert(simplex.scale_bits, Reader.u32(s, scales + i * 4))
			local vertex = {}
			for j = 0, d - 1 do
				table.insert(vertex, Reader.u32(s, at + 20 + (i * (d + 1) + j) * 4))
			end
			table.insert(simplex.vertex_bits, vertex)
			local nv = {}
			for j = 0, d - 1 do
				table.insert(nv, Reader.u32(s, normal + 4 + j * 4))
			end
			table.insert(simplex.normal_bits, nv)
		end
		table.insert(simplexes, simplex)
		at += size
	end
	local parameters = {}
	for i = 0, d - 1 do
		table.insert(parameters, Reader.name(space, params + i * 20, 5))
	end
	local children = {}
	for i = 0, count - 1 do
		table.insert(children, Reader.name(r, names + i * 24, 6))
	end
	return { name = h.name, source_offset = h.offset, parameters = parameters, children = children, simplexes = simplexes }
end

return blend_space
