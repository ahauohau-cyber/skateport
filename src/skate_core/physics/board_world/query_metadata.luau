--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_world/query_metadata.rs (коммит 2e16697)
--
-- Canonical authored scene metadata; independent of rendering tags and actors.

local rt = require("../../../rt")
local drive_frames = require("../drive_frames")

local f32 = rt.f32
local fmin, fmax = rt.fmin, rt.fmax

type Vector3 = vector

local query_metadata = {}

-- pub enum QueryPool { Ground, Island, Conditional }
query_metadata.QueryPool = { Ground = 0, Island = 1, Conditional = 2 }

export type Bounds = { min: Vector3, max: Vector3 }

local function finite(p: Vector3): boolean
	return rt.is_finite(p.x) and rt.is_finite(p.y) and rt.is_finite(p.z)
end

local Bounds = {}
query_metadata.Bounds = Bounds

function Bounds.expanded(self: Bounds, padding: number): Bounds
	return {
		min = vector.create(f32(self.min.x - padding), f32(self.min.y - padding), f32(self.min.z - padding)),
		max = vector.create(f32(self.max.x + padding), f32(self.max.y + padding), f32(self.max.z + padding)),
	}
end

function Bounds.overlaps(self: Bounds, other: Bounds): boolean
	return not (
		self.max.x < other.min.x
		or self.min.x > other.max.x
		or self.max.y < other.min.y
		or self.min.y > other.max.y
		or self.max.z < other.min.z
		or self.min.z > other.max.z
	)
end

-- pub fn from_points(points: impl IntoIterator<Item = Vector3>) -> Option<Self>
function Bounds.from_points(points: { Vector3 }): Bounds?
	local first = points[1]
	if first == nil or not finite(first) then
		return nil
	end
	local min, max = first, first
	for i = 2, #points do
		local p = points[i]
		if not finite(p) then
			return nil
		end
		min = vector.create(fmin(min.x, p.x), fmin(min.y, p.y), fmin(min.z, p.z))
		max = vector.create(fmax(max.x, p.x), fmax(max.y, p.y), fmax(max.z, p.z))
	end
	return { min = min, max = max }
end

function Bounds.contains(self: Bounds, p: Vector3): boolean
	return finite(p)
		and p.x >= self.min.x
		and p.x <= self.max.x
		and p.y >= self.min.y
		and p.y <= self.max.y
		and p.z >= self.min.z
		and p.z <= self.max.z
end

function Bounds.valid(self: Bounds): boolean
	return finite(self.min)
		and finite(self.max)
		and self.min.x <= self.max.x
		and self.min.y <= self.max.y
		and self.min.z <= self.max.z
end

export type EdgeSegment = { start: Vector3, end_: Vector3, local_bounds: Bounds }

-- ROBLOX: Range<usize> -> { start, end_ } (с нуля, конец не включается);
-- `end` — ключевое слово Luau, поэтому end_.
export type Range = { start: number, end_: number }

export type QueryMesh = {
	triangle_range: Range,
	local_to_world: drive_frames.RetailAffineTransform,
	world_to_local: drive_frames.RetailAffineTransform,
	local_bounds: Bounds,
	matching_group: number,
	-- S3 mesh184: trajectory rejection mask, separate from surface/material.
	rejection_flags: number,
	-- S3 mesh176 support/body identity; static registration uses 0.
	geometry: number,
	pool: number,
}

export type QueryMetadata = {
	-- Exact authored uint16 codes, in canonical triangle order. Low7 material,
	-- next5 category, upper4 flags; never synthesized from WorldTriangle::tag.
	packed_surfaces: { number },
	meshes: { QueryMesh },
	-- Explicit level query edges; triangulation diagonals are not query edges.
	static_edges: { EdgeSegment },
	island_flags: number,
}

local QueryMetadata = {}
query_metadata.QueryMetadata = QueryMetadata

-- pub(super) fn validate(&self, triangles: &[WorldTriangle]) -> Result<(), &'static str>
function QueryMetadata.validate(self: QueryMetadata, triangles: { any }): (boolean?, string?)
	if #self.packed_surfaces ~= #triangles then
		return nil, "Query surface count must equal canonical triangle count"
	end
	local next_index = 0
	local identity = drive_frames.RetailAffineTransform.IDENTITY()
	for _, mesh in self.meshes do
		local r = mesh.triangle_range
		if r.start ~= next_index or r.end_ <= next_index or r.end_ > #triangles then
			return nil, "Query meshes must partition canonical triangles in supplied order"
		end
		-- BoardWorld collision currently owns world-space static triangles.
		-- Reject an unsupported scene transform rather than move query-only geometry.
		if
			not drive_frames.RetailAffineTransform.eq(mesh.local_to_world, identity)
			or not drive_frames.RetailAffineTransform.eq(mesh.world_to_local, identity)
		then
			return nil, "BoardWorld static query meshes require identity transforms"
		end
		if not Bounds.valid(mesh.local_bounds) then
			return nil, "Invalid query mesh bounds"
		end
		for i = r.start + 1, r.end_ do
			for _, p in triangles[i].triangle.vertices do
				if not Bounds.contains(mesh.local_bounds, p) then
					return nil, "Query mesh bounds exclude canonical triangle geometry"
				end
			end
		end
		next_index = r.end_
	end
	if next_index ~= #triangles then
		return nil, "Query metadata leaves canonical triangles unassigned"
	end
	for _, edge in self.static_edges do
		if
			not Bounds.valid(edge.local_bounds)
			or not Bounds.contains(edge.local_bounds, edge.start)
			or not Bounds.contains(edge.local_bounds, edge.end_)
		then
			return nil, "Invalid authored query edge"
		end
	end
	return true, nil
end

return query_metadata
