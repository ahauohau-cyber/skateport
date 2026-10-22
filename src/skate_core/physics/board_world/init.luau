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
-- TODO: перенесена только первая часть файла (WorldTriangle и вода).
-- BoardWorld, broadphase, query_index и query_metadata зависят от board.rs,
-- board_runtime.rs, board_step.rs и drive_frames.rs — их порт идёт в этапе
-- доски, после чего этот файл дописывается до конца в том же порядке.

local contact = require("./contact")
local sphere_triangle = require("./collision/sphere_triangle")
local primitive_geometry = require("./world_contact/primitive_geometry")

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
-- TODO: поле geometry — triangle_query.TriangleLineHit; тип уточнится вместе с BoardWorld.
export type WorldLineHit = {
	geometry: any,
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

return board_world
