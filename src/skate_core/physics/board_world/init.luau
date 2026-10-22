--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_world.rs (коммит 2e16697)
--
-- Contacts for every board primitive against the host triangle world.
-- Rust owns geometry storage and traversal. Recovered query8277B720,
-- triangle fixup82AD3130, material combine82763078 and contact retention
-- determine the physical result, in world-triangle then moving-volume order.
--
-- ROBLOX: подмодули broadphase, query_index, query_metadata — в @self/;
-- методы broadphase (candidate_ranges и др.) подключены к BoardWorld ниже.

local rt = require("../../rt")
local contact = require("./contact")
local sphere_triangle = require("./collision/sphere_triangle")
local primitive_geometry = require("./world_contact/primitive_geometry")
local primitive_query = require("./world_contact/primitive_query")
local buffer_mod = require("./world_contact/buffer")
local triangle_query = require("./triangle_query")
local board = require("./board")
local query_metadata = require("@self/query_metadata")
local query_index = require("@self/query_index")
local broadphase = require("@self/broadphase")

local f32 = rt.f32
local fmin, fmax = rt.fmin, rt.fmax
local from_bits, to_bits = rt.from_bits, rt.to_bits
local Bounds = query_metadata.Bounds
local ContactBuffer = buffer_mod.ContactBuffer

type Vector3 = vector
type Triangle = sphere_triangle.Triangle
type RetailContactMaterial = contact.RetailContactMaterial

local board_world = {}

-- Retail surface type 12 (`(tag >> 7) & 31`): water.
-- pub const fn is_water_tag(tag: u32) -> bool
function board_world.is_water_tag(tag: number): boolean
	return bit32.band(tag, 0xF80) == 0x600
end

-- Water with geometry within this depth under the surface (at a given point)
-- is shallow: solid there, like retail's University fountain channel, where
-- the bailed skater lies on the water. Deeper water is not solid: bodies sink
-- in and float (Aletown canal). Project-chosen depth.
board_world.FLOAT_DEPTH = 0.5

-- pub struct WorldTriangle
export type WorldTriangle = {
	triangle: Triangle,
	material: RetailContactMaterial,
	tag: number,
}

-- pub struct WorldLineHit
export type WorldLineHit = {
	geometry: triangle_query.TriangleLineHit,
	tag: number,
}

local WorldTriangle = {}
board_world.WorldTriangle = WorldTriangle

local function finite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

-- Host geometry preparation, with explicit adjacency and sidedness.
-- Uses the native Volume constructor and its authored winding. Invalid
-- host geometry is rejected without substituting a repaired triangle.
-- pub fn from_vertices(vertices, material, tag, flags, edge_cosines, fatness) -> Option<Self>
function WorldTriangle.from_vertices(
	vertices: { Vector3 },
	material: RetailContactMaterial,
	tag: number,
	flags: number,
	edge_cosines: { number },
	fatness: number
): WorldTriangle?
	for _, v in vertices do
		if not finite(v.x) or not finite(v.y) or not finite(v.z) then
			return nil
		end
	end
	local triangle = primitive_geometry.triangle_from_volume(vertices, fatness, edge_cosines, flags)
	local normal = triangle.feature.normal
	for _, length in triangle.edge_lengths do
		if not finite(length) or length <= 0.0 then
			return nil
		end
	end
	if not finite(normal.x) or not finite(normal.y) or not finite(normal.z) or normal == vector.zero then
		return nil
	end
	return {
		triangle = triangle,
		material = material,
		tag = tag,
	}
end

-- Caller-resolved TempContactBuffer settings. Retention changes solver rows,
-- so its thresholds/capacity remain explicit instead of using tuned defaults.
export type ContactRetentionSettings = {
	capacity: number,
	duplicate_distance_squared: number,
	deferred_reduction: boolean,
}

export type WheelWorldSettings = {
	-- Sphere shared by wheel definitions in82C0AA78.
	radius: number,
	material: RetailContactMaterial,
	query: any, -- collision.WorldContactSettings
	retention: ContactRetentionSettings,
}

-- One enabled moving primitive, with its owning solver body and material.
export type BoardWorldVolume = {
	-- Native serialized VolumeData+212 (Part+92), not Volume+84.
	collision_group: number,
	body: any, -- board_step.CollisionBody
	primitive: any, -- world_contact.ContactPrimitive
	-- Owning body's rates; 82777E70 sweeps the query box over them.
	motion: broadphase.VolumeMotion,
	material: RetailContactMaterial,
}

-- Host-supplied moving geometry (в Rust — трейт ExternalQueries).
export type ExternalLineHit = { hit: WorldLineHit, surface: number, geometry_id: number, frame: { { number } } }
export type ExternalQueries = {
	line: (self: any, start: Vector3, end_: Vector3, radius: number) -> ExternalLineHit?,
	nearby: (self: any, center: Vector3, radius: number) -> { { Vector3 } },
}

-- World geometry remains in supplied order. Each query reuses output storage;
-- the returned contacts are valid until the next mutable call.
export type BoardWorld = {
	triangles: { WorldTriangle },
	external: ExternalQueries?,
	triangle_bounds: { query_metadata.Bounds },
	query_metadata: query_metadata.QueryMetadata?,
	query_index: query_index.QueryIndex,
	maximum_fatness: number,
	maximum_triangle_margin: number,
	-- Indices of water triangles (с нуля), for `water_surface_at`.
	water: { number },
	contacts: { any },
	buffer: buffer_mod.ContactBuffer,
}

local BoardWorld = {}
board_world.BoardWorld = BoardWorld

-- ROBLOX: методы из broadphase.rs (impl BoardWorld в другом файле).
BoardWorld.candidate_ranges = broadphase.candidate_ranges
BoardWorld.line_candidates = broadphase.line_candidates
BoardWorld.line_candidate_bounds = broadphase.line_candidate_bounds
BoardWorld.candidate_mesh_indices = broadphase.candidate_mesh_indices
board_world.VOLUME_QUERY_STEP = broadphase.VOLUME_QUERY_STEP
board_world.VOLUME_QUERY_SCALE = broadphase.VOLUME_QUERY_SCALE
board_world.VolumeMotion = broadphase.VolumeMotion
board_world.volume_query_bounds = broadphase.volume_query_bounds

function BoardWorld.new(triangles: { WorldTriangle }): BoardWorld
	local inf = math.huge
	local triangle_bounds = {}
	for i, t in triangles do
		triangle_bounds[i] = Bounds.from_points(t.triangle.vertices)
			or { min = vector.create(-inf, -inf, -inf), max = vector.create(inf, inf, inf) }
	end
	local maximum_fatness = 0.0
	for _, t in triangles do
		local fat = t.triangle.fatness
		maximum_fatness = fmax(maximum_fatness, if rt.is_finite(fat) and fat >= 0.0 then fat else inf)
	end
	-- The current thin-triangle leaf accepts barycentric weights down to
	-- -epsilon. Two negative weights can extend an axis by 2*epsilon*span.
	local maximum_triangle_margin = 0.0
	for _, b in triangle_bounds do
		local span = fmax(fmax(f32(b.max.x - b.min.x), f32(b.max.y - b.min.y)), f32(b.max.z - b.min.z))
		maximum_triangle_margin = fmax(maximum_triangle_margin, f32(span * f32(2.0 * broadphase.THIN_MARGIN)))
	end
	local water = {}
	for i, t in triangles do
		if board_world.is_water_tag(t.tag) then
			table.insert(water, i - 1)
		end
	end
	local records = {}
	for i = 1, 50 do
		records[i] = rt.zeros(64)
	end
	return {
		water = water,
		triangles = triangles,
		external = nil,
		triangle_bounds = triangle_bounds,
		query_metadata = nil,
		query_index = query_index.QueryIndex.default(),
		maximum_fatness = maximum_fatness,
		maximum_triangle_margin = maximum_triangle_margin,
		contacts = {},
		buffer = {
			count = 0,
			flushed = 0,
			capacity = 0,
			dropped = 0,
			distance_squared_threshold = 0.0,
			allow_flush = 1,
			deferred_reduction = 0,
			full = 0,
			records = records,
		},
	}
end

function BoardWorld.with_query_metadata(triangles: { WorldTriangle }, metadata: query_metadata.QueryMetadata): (BoardWorld?, string?)
	local ok, err = query_metadata.QueryMetadata.validate(metadata, triangles)
	if not ok then
		return nil, err
	end
	local world = BoardWorld.new(triangles)
	world.query_index = query_index.QueryIndex.new(metadata.meshes)
	world.query_metadata = metadata
	return world, nil
end

function BoardWorld.query_metadata(self: BoardWorld): (query_metadata.QueryMetadata?, string?)
	if self.query_metadata == nil then
		return nil, "Canonical world has no authored query metadata"
	end
	return self.query_metadata, nil
end

function BoardWorld.set_external_queries(self: BoardWorld, queries: ExternalQueries?)
	self.external = queries
end
function BoardWorld.external_line(self: BoardWorld, start: Vector3, end_: Vector3, radius: number): ExternalLineHit?
	local q = self.external
	return if q then q:line(start, end_, radius) else nil
end
function BoardWorld.external_nearby(self: BoardWorld, center: Vector3, radius: number): { { Vector3 } }
	local q = self.external
	return if q then q:nearby(center, radius) else {}
end

function BoardWorld.triangles(self: BoardWorld): { WorldTriangle }
	return self.triangles
end

-- Ordered nearest-hit traversal for wheel and camera queries. The host
-- owns traversal; each candidate uses the complete TU3 triangle dispatcher.
function BoardWorld.query_swept_line(self: BoardWorld, start: Vector3, end_: Vector3, radius: number): (WorldLineHit?, string?)
	if not rt.is_finite(radius) or radius < 0.0 then
		return nil, "line query radius must be finite and nonnegative"
	end
	local direction = vector.create(f32(end_.x - start.x), f32(end_.y - start.y), f32(end_.z - start.z))
	local external = BoardWorld.external_line(self, start, end_, radius)
	local nearest: WorldLineHit? = if external then external.hit else nil
	for _, candidate in broadphase.line_candidates(self, start, end_, radius) do
		local entry = candidate[2]
		local geometry: triangle_query.TriangleLineHit = {
			position = vector.zero,
			normal = vector.zero,
			fraction = 0.0,
			volume_parameter = { 0.0, 0.0, 0.0 },
		}
		if triangle_query.triangle_segment(geometry, start, direction, entry.triangle.vertices, radius, entry.triangle.fatness) then
			if nearest == nil or geometry.fraction < (nearest :: WorldLineHit).geometry.fraction then
				nearest = { geometry = geometry, tag = entry.tag }
			end
		end
	end
	-- ROBLOX: Ok(None) -> (nil, nil); ошибка -> (nil, текст).
	return nearest, nil
end

-- Board wheel segments use zero query radius; rounded world triangles
-- still select the native swept branch through their own fatness.
function BoardWorld.query_thin_line(self: BoardWorld, start: Vector3, end_: Vector3): (WorldLineHit?, string?)
	return BoardWorld.query_swept_line(self, start, end_, 0.0)
end

-- Whether the water at `point` on its surface is shallow: some geometry
-- lies within `FLOAT_DEPTH` under it (a channel, a ledge, a bank).
function BoardWorld.water_shallow_at(self: BoardWorld, point: Vector3): boolean
	local start = vector.create(point.x, f32(point.y - f32(0.001)), point.z)
	local end_ = vector.create(point.x, f32(point.y - board_world.FLOAT_DEPTH), point.z)
	local hit, err = BoardWorld.query_thin_line(self, start, end_)
	return not (hit == nil and err == nil)
end

-- Retention reads only contact header geometry, body IDs and material/tag.
-- BoardStep builds the actual body workspaces after this frame's force queue
-- has been applied, preventing stale acceleration copies in solver contacts.
local function retention_record(id: any, c: contact.RetailContactInput): { number }
	local CollisionBody = (require("./board_step") :: any).CollisionBody
	local record = rt.zeros(64)
	for _, item in { { 0, c.position_on_a }, { 4, c.position_on_b }, { 8, c.normal } } do
		local offset: number, v: Vector3 = item[1] :: any, item[2] :: any
		record[offset + 1], record[offset + 2], record[offset + 3] = to_bits(v.x), to_bits(v.y), to_bits(v.z)
	end
	record[4] = CollisionBody.contact_id(id)
	record[8] = 0xFFFF_FFFF
	record[12] = to_bits(c.restitution)
	record[16] = to_bits(c.static_friction)
	record[20] = to_bits(c.dynamic_friction)
	record[24] = c.tag
	return record
end

local function collision_from_record(record: { number }): any
	local CollisionBody = (require("./board_step") :: any).CollisionBody
	local function f(i: number): number
		return from_bits(record[i + 1])
	end
	local function v(i: number): Vector3
		return vector.create(f(i), f(i + 1), f(i + 2))
	end
	return {
		body_a = CollisionBody.from_contact_id(record[4]),
		body_b = CollisionBody.StaticWorld,
		contact = {
			position_on_a = v(0),
			position_on_b = v(4),
			normal = v(8),
			restitution = f(11),
			static_friction = f(15),
			dynamic_friction = f(19),
			tag = record[24],
		},
	}
end

-- World-space shapes come from the live part poses and authored children.
-- Cluster bounds include shape radii and the maximum predictive padding.
-- Candidate pairs retain world-triangle then moving-volume order.
function BoardWorld.query_primitives(
	self: BoardWorld,
	volumes: { BoardWorldVolume },
	query: any,
	retention: ContactRetentionSettings
): { any }
	table.clear(self.contacts)
	local buf = self.buffer
	buf.count = 0
	buf.flushed = 0
	buf.dropped = 0
	buf.full = 0
	buf.capacity = retention.capacity
	buf.distance_squared_threshold = retention.duplicate_distance_squared
	buf.deferred_reduction = if retention.deferred_reduction then 1 else 0
	local padding = if rt.is_finite(query.volume_padding) and rt.is_finite(query.maximum_separating_distance)
		then f32(fmax(query.volume_padding, 0.0) + fmax(query.maximum_separating_distance, 0.0))
		else math.huge
	-- Cluster preselection only: a conservative superset of every pair the
	-- per-volume test below can keep.
	local volume_bounds = {}
	local all_bounds = true
	local points = {}
	for i, v in volumes do
		local p = broadphase.primitive_bounds(v.primitive)
		local pre = if p then broadphase.conservative_bounds(p, f32(padding + self.maximum_fatness)) else nil
		-- 82777E70: the swept, scaled box 8277BC58 tests every triangle against.
		local vb = broadphase.volume_query_bounds(v.primitive, v.motion, broadphase.VOLUME_QUERY_STEP, broadphase.VOLUME_QUERY_SCALE)
		volume_bounds[i] = vb or false
		if pre and vb then
			table.insert(points, vector.create(fmin(pre.min.x, vb.min.x), fmin(pre.min.y, vb.min.y), fmin(pre.min.z, vb.min.z)))
			table.insert(points, vector.create(fmax(pre.max.x, vb.max.x), fmax(pre.max.y, vb.max.y), fmax(pre.max.z, vb.max.z)))
		else
			all_bounds = false
		end
	end
	local bounds: query_metadata.Bounds? = nil
	if all_bounds then
		local b = Bounds.from_points(points)
		if b then
			bounds = Bounds.expanded(b, padding)
		end
	end
	local ranges = broadphase.candidate_ranges(self, bounds)
	local output = self.contacts
	local function publish(records: { { number } })
		for _, r in records do
			table.insert(output, collision_from_record(r))
		end
	end
	local stop = false
	for _, r in ranges do
		for index = r.start + 1, r.end_ do
			local entry = self.triangles[index]
			for vi, volume in volumes do
				-- GroundPipeline8277BC58 checks the group/surface exclusion
				-- table before running the geometric dispatcher. Its stock
				-- initializer82767D60 sets only (7,12) and (16,12).
				if (volume.collision_group == 7 or volume.collision_group == 16) and board_world.is_water_tag(entry.tag) then
					continue
				end
				-- 8277BC58 BE94..BF38: unpadded triangle vertex box against the
				-- volume box, for every triangle. A non-finite box keeps the pair.
				local vb = volume_bounds[vi]
				if vb and not Bounds.overlaps(self.triangle_bounds[index], vb :: query_metadata.Bounds) then
					continue
				end
				local manifold = primitive_query.primitive_triangle_world_contacts(
					volume.primitive,
					entry.triangle,
					volume.motion.linear_velocity,
					query
				)
				if manifold == nil then
					continue
				end
				local material = contact.combine_contact_materials(volume.material, entry.material)
				for k = 1, manifold.count do
					local pair = manifold.points[k]
					local c: contact.RetailContactInput = {
						position_on_a = pair.a,
						position_on_b = pair.b,
						normal = manifold.normal,
						restitution = material.restitution,
						static_friction = material.static_friction,
						dynamic_friction = material.dynamic_friction,
						tag = entry.tag,
					}
					local slot = ContactBuffer.allocate(buf, publish)
					if slot == nil then
						ContactBuffer.flush(buf, publish)
						stop = true
						break
					end
					buf.records[slot + 1] = retention_record(volume.body, c)
					-- 8277C23C removes the most recent record on rejection.
					if ContactBuffer.last_is_duplicate(buf) then
						buf.count -= 1
					end
				end
				if stop then
					break
				end
			end
			if stop then
				break
			end
		end
		if stop then
			break
		end
	end
	if buf.full == 0 then
		ContactBuffer.flush(buf, publish)
	end
	return self.contacts
end

-- Sphere-only convenience for callers querying wheels. The game uses
-- query_primitives with all enabled deck/truck/wheel children.
function BoardWorld.query(self: BoardWorld, runtime: any, settings: WheelWorldSettings): { any }
	local BoardRuntime = (require("./board_runtime") :: any).BoardRuntime
	local CollisionBody = (require("./board_step") :: any).CollisionBody
	local poses = BoardRuntime.part_transforms(runtime)
	local volumes: { BoardWorldVolume } = {}
	for k = 1, 4 do
		local id = board.BodyId.ORDER[k]
		local body = BoardRuntime.bodies(runtime)[id + 1]
		if body.state_flags ~= 1 then
			table.insert(volumes, {
				collision_group = BoardRuntime.collision_group(runtime),
				body = CollisionBody.Board(id),
				primitive = { kind = "Sphere", sphere = { center = poses[id + 1].translation, radius = settings.radius } },
				motion = broadphase.VolumeMotion.of(body.rates),
				material = settings.material,
			})
		end
	end
	return BoardWorld.query_primitives(self, volumes, settings.query, settings.retention)
end

function BoardWorld.contacts(self: BoardWorld): { any }
	return self.contacts
end

-- Height of the water surface over `point`, when the point lies at most
-- `max_depth` below it (or less than `above` over it). Water surfaces are
-- the type-12 triangles, interpolated at the point's XZ; the nearest
-- surface at or above the point wins.
function BoardWorld.water_surface_at(self: BoardWorld, point: Vector3, above: number, max_depth: number): number?
	local best: number? = nil
	for _, index in self.water do
		local v = self.triangles[index + 1].triangle.vertices
		local a, b, c = v[1], v[2], v[3]
		local det = f32(f32(f32(b.x - a.x) * f32(c.z - a.z)) - f32(f32(c.x - a.x) * f32(b.z - a.z)))
		if math.abs(det) < f32(1e-8) then
			continue
		end
		local u = f32(
			f32(f32(f32(point.x - a.x) * f32(c.z - a.z)) - f32(f32(c.x - a.x) * f32(point.z - a.z))) / det
		)
		local w = f32(
			f32(f32(f32(b.x - a.x) * f32(point.z - a.z)) - f32(f32(point.x - a.x) * f32(b.z - a.z))) / det
		)
		if u < 0.0 or w < 0.0 or f32(u + w) > 1.0 then
			continue
		end
		local height = f32(f32(a.y + f32(u * f32(b.y - a.y))) + f32(w * f32(c.y - a.y)))
		local depth = f32(height - point.y)
		if depth > -above and depth <= max_depth and (best == nil or height < (best :: number)) then
			best = height
		end
	end
	return best
end

-- `water_surface_at`, but only where the water is at least `min_depth`
-- deep: no solid (or other) geometry within `min_depth` under the surface.
function BoardWorld.deep_water_surface_at(self: BoardWorld, point: Vector3, above: number, max_depth: number, min_depth: number): number?
	local surface = BoardWorld.water_surface_at(self, point, above, max_depth)
	if surface == nil then
		return nil
	end
	local start = vector.create(point.x, f32(surface - f32(0.001)), point.z)
	local end_ = vector.create(point.x, f32(surface - min_depth), point.z)
	local hit, err = BoardWorld.query_thin_line(self, start, end_)
	return if hit == nil and err == nil then surface else nil
end

function BoardWorld.dropped_contacts(self: BoardWorld): number
	return self.buffer.dropped
end

return board_world
