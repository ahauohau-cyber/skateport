--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/physics/colliders.rs (коммит 2e16697)
--
-- Bind stock child geometry to the live solver part transforms.

local rt = require("../../rt")
local board = require("../../skate_core/physics/board")
local board_runtime = require("../../skate_core/physics/board_runtime")
local board_step = require("../../skate_core/physics/board_step")
local board_world = require("../../skate_core/physics/board_world")
local primitive_geometry = require("../../skate_core/physics/world_contact/primitive_geometry")

local mul_add = rt.mul_add
local f32 = rt.f32
local BodyId = board.BodyId
local BoardRuntime = board_runtime.BoardRuntime
local CollisionBody = board_step.CollisionBody
local VolumeMotion = board_world.VolumeMotion

local colliders = {}

-- fn capsule(pose, radius, half_length) -> ContactPrimitive
local function capsule(pose: any, radius: number, half_length: number): any
	local z = pose.basis.columns[3]
	return {
		kind = "Capsule",
		center = pose.translation,
		axis = vector.create(z[1], z[2], z[3]),
		half_length = half_length,
		radius = radius,
	}
end

-- Same multiply/add order as the Volume-to-world vertex path82ADE468.
-- fn transform(basis, point, origin) -> Vector3
local function transform(basis: any, point: vector, origin: vector): vector
	local translation = { origin.x, origin.y, origin.z }
	local c = basis.columns
	local function component(row: number): number
		return mul_add(point.z, c[3][row], mul_add(point.y, c[2][row], mul_add(point.x, c[1][row], translation[row])))
	end
	return vector.create(component(1), component(2), component(3))
end

-- fn compose(parent, child) -> RetailAffineTransform
local function compose(parent: any, child: any): any
	local p = parent.basis.columns
	local columns = {}
	for k = 1, 3 do
		local c = child.basis.columns[k]
		local column = {}
		for row = 1, 3 do
			-- CreateGP82AD8758 starts basis composition with a product;
			-- only position composition includes an initial translation.
			column[row] = mul_add(c[3], p[3][row], mul_add(c[2], p[2][row], f32(c[1] * p[1][row])))
		end
		columns[k] = column
	end
	return {
		basis = { columns = columns },
		translation = transform(parent.basis, child.translation, parent.translation),
	}
end

-- pub(crate) fn world_volumes(board: &BoardRuntime, settings: &PhysicsSettings) -> Vec<BoardWorldVolume>
function colliders.world_volumes(runtime: any, settings: any): { board_world.BoardWorldVolume }
	local poses = BoardRuntime.part_transforms(runtime)
	local bodies = BoardRuntime.bodies(runtime)
	local volumes: { board_world.BoardWorldVolume } = {}
	-- SerializeVolumes preserves part order, then compound child order.
	for _, id in BodyId.ORDER do
		local body = bodies[id + 1]
		if body.state_flags ~= 1 then
			local pose = poses[id + 1]
			local function add(primitive: any, material: any)
				table.insert(volumes, {
					collision_group = BoardRuntime.collision_group(runtime),
					body = CollisionBody.Board(id),
					primitive = primitive,
					material = material,
					motion = VolumeMotion.of(body.rates),
				})
			end
			if id == BodyId.Deck then
				for _, child in settings.deck_geometry.children do
					if child.collision_enabled then
						local world = compose(pose, child.transform)
						local shape = child.shape
						local primitive
						if shape.kind == "Sphere" then
							primitive = { kind = "Sphere", sphere = { center = world.translation, radius = shape.radius } }
						elseif shape.kind == "Capsule" then
							primitive = capsule(world, shape.radius, shape.half_length)
						elseif shape.kind == "RoundedBox" then
							primitive = {
								kind = "RoundedBox",
								center = world.translation,
								basis = world.basis,
								half_extents = shape.half_extents,
								radius = shape.radius,
							}
						else
							primitive = {
								kind = "Triangle",
								triangle = primitive_geometry.transform_triangle_volume(
									shape.vertices,
									shape.fatness,
									shape.edge_cosines,
									shape.volume_flags,
									world.basis,
									world.translation
								),
							}
						end
						add(primitive, settings.deck_material)
					end
				end
			elseif id == BodyId.FrontTruck or id == BodyId.BackTruck then
				if settings.truck_collisions then
					local shape = settings.truck_shape
					-- TU382C0A6F8 constructs a capsule for each truck.
					assert(shape.kind == "Capsule", "TU382C0A6F8 constructs a capsule for each truck")
					add(capsule(pose, shape.radius, shape.half_length), settings.truck_material)
				end
			else
				add({ kind = "Sphere", sphere = { center = pose.translation, radius = settings.wheel_radius } }, settings.wheel_material)
			end
		end
	end
	return volumes
end

return colliders
