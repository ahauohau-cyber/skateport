--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_world/query_index.rs (коммит 2e16697)
--
-- Static bounds hierarchy over authored query meshes. Results are sorted back
-- into source order before narrow-phase, preserving equal-hit/contact order.

local rt = require("../../../rt")
local query_metadata = require("./query_metadata")

local f32 = rt.f32
local Bounds = query_metadata.Bounds

local query_index = {}

-- ROBLOX: range — { start, end_ } в позициях order (с нуля); children — пара
-- индексов узлов (с нуля) или nil.
type Node = { bounds: query_metadata.Bounds, children: { number }?, range: query_metadata.Range }
export type QueryIndex = { nodes: { Node }, order: { number } }

-- ROBLOX: f32::total_cmp — порядок по битам (отрицательные в обратном порядке).
local function total_key(x: number): number
	local bits = rt.to_bits(x)
	if bits >= 0x8000_0000 then
		return -(bits - 0x8000_0000) - 1
	end
	return bits
end

local function build(index: QueryIndex, meshes: { query_metadata.QueryMesh }, start: number, end_: number): number
	local points = {}
	for k = start + 1, end_ do
		local m = meshes[index.order[k] + 1]
		table.insert(points, m.local_bounds.min)
		table.insert(points, m.local_bounds.max)
	end
	local bounds = Bounds.from_points(points) :: query_metadata.Bounds
	assert(bounds)
	local id = #index.nodes
	table.insert(index.nodes, { bounds = bounds, children = nil, range = { start = start, end_ = end_ } })
	local len = end_ - start
	if len > 8 then
		local extents = {
			f32(bounds.max.x - bounds.min.x),
			f32(bounds.max.y - bounds.min.y),
			f32(bounds.max.z - bounds.min.z),
		}
		-- max_by: при равенстве берётся последний максимум.
		local axis = 1
		for a = 2, 3 do
			if total_key(extents[a]) >= total_key(extents[axis]) then
				axis = a
			end
		end
		local function center(i: number): number
			local b = meshes[i + 1].local_bounds
			local low = ({ b.min.x, b.min.y, b.min.z })[axis]
			local high = ({ b.max.x, b.max.y, b.max.z })[axis]
			return f32(f32(low * 0.5) + f32(high * 0.5))
		end
		local mid = start + len // 2
		-- ROBLOX: select_nth_unstable_by делит диапазон на «первые len/2 по
		-- (center, индекс)» и остальные. Этот набор однозначен при строгом
		-- порядке, поэтому полная сортировка даёт те же узлы и тот же ответ query.
		local slice = table.move(index.order, start + 1, end_, 1, {})
		local keys = {}
		for _, i in slice do
			keys[i] = total_key(center(i))
		end
		table.sort(slice, function(x: number, y: number): boolean
			if keys[x] ~= keys[y] then
				return keys[x] < keys[y]
			end
			return x < y
		end)
		table.move(slice, 1, #slice, start + 1, index.order)
		local left = build(index, meshes, start, mid)
		local right = build(index, meshes, mid, end_)
		index.nodes[id + 1].children = { left, right }
	end
	return id
end

local QueryIndex = {}
query_index.QueryIndex = QueryIndex

-- #[derive(Default)]
function QueryIndex.default(): QueryIndex
	return { nodes = {}, order = {} }
end

function QueryIndex.new(meshes: { query_metadata.QueryMesh }): QueryIndex
	local order = {}
	for i = 0, #meshes - 1 do
		order[i + 1] = i
	end
	local index = { nodes = {}, order = order }
	if #meshes > 0 then
		build(index, meshes, 0, #meshes)
	end
	return index
end

function QueryIndex.query(self: QueryIndex, bounds: query_metadata.Bounds, meshes: { query_metadata.QueryMesh }): { number }
	local result = {}
	if #self.nodes == 0 then
		return result
	end
	local stack = { 0 }
	while #stack > 0 do
		local id = table.remove(stack) :: number
		local node = self.nodes[id + 1]
		if Bounds.overlaps(node.bounds, bounds) then
			local children = node.children
			if children then
				table.insert(stack, children[2])
				table.insert(stack, children[1])
			else
				for k = node.range.start + 1, node.range.end_ do
					local i = self.order[k]
					if Bounds.overlaps(meshes[i + 1].local_bounds, bounds) then
						table.insert(result, i)
					end
				end
			end
		end
	end
	table.sort(result)
	return result
end

return query_index
