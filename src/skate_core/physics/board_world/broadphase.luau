--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_world/broadphase.rs (коммит 2e16697)
--
-- ZIP world broadphase helpers; recovered narrow-phase stays in its existing modules.
-- ROBLOX: методы BoardWorld из этого файла (candidate_ranges, line_candidates и др.)
-- принимают world первым аргументом; board_world/init.luau подключает их к BoardWorld.

local rt = require("../../../rt")
local query_metadata = require("./query_metadata")
local query_index = require("./query_index")
local board_motion_output = require("../board_motion_output")

local f32 = rt.f32
local mul_add = rt.mul_add
local fmin, fmax = rt.fmin, rt.fmax
local Bounds = query_metadata.Bounds

type Vector3 = vector
type Bounds = query_metadata.Bounds

local broadphase = {}

-- Positive magnitude of thin_triangle's existing 0xb727_c5ac tolerance.
broadphase.THIN_MARGIN = rt.from_bits(0x3727_c5ac)
local F32_EPSILON = 2 ^ -23

-- Data 0x820849C8: the fixed 1/60 step the world query predicts over.
broadphase.VOLUME_QUERY_STEP = rt.from_bits(0x3C88_8889)
-- Data 0x821659FC: scale applied to the swept box about its centre.
broadphase.VOLUME_QUERY_SCALE = f32(1.05)

local function scale_of(bounds: Bounds): number
	local s = 1.0
	for _, v in { bounds.min.x, bounds.min.y, bounds.min.z, bounds.max.x, bounds.max.y, bounds.max.z } do
		s = fmax(s, math.abs(v))
	end
	return s
end

function broadphase.conservative_bounds(bounds: Bounds, padding: number): Bounds
	return Bounds.expanded(bounds, f32(padding + f32(scale_of(bounds) * f32(8.0 * F32_EPSILON))))
end

-- Conservative cluster culling, retaining canonical traversal order and
-- every triangle in intersecting clusters. Narrow-phase remains unchanged.
-- ROBLOX: Vec<Range> -> список { start, end_ }.
function broadphase.candidate_ranges(world: any, bounds: Bounds?): { query_metadata.Range }
	local metadata = world.query_metadata
	if metadata == nil or bounds == nil or not Bounds.valid(bounds) then
		return { { start = 0, end_ = #world.triangles } }
	end
	local expanded = Bounds.expanded(
		bounds,
		f32(f32(world.maximum_fatness + world.maximum_triangle_margin) + f32(scale_of(bounds) * f32(8.0 * F32_EPSILON)))
	)
	local out = {}
	for _, i in query_index.QueryIndex.query(world.query_index, expanded, metadata.meshes) do
		table.insert(out, metadata.meshes[i + 1].triangle_range)
	end
	return out
end

-- Bounds shared with adapters that retain mesh pool/group/identity filtering.
-- Includes the current thin-leaf endpoint and barycentric margins.
function broadphase.line_candidate_bounds(world: any, start: Vector3, end_: Vector3, radius: number): Bounds?
	if not rt.is_finite(radius) or radius < 0.0 then
		return nil
	end
	local span = fmax(fmax(math.abs(f32(end_.x - start.x)), math.abs(f32(end_.y - start.y))), math.abs(f32(end_.z - start.z)))
	local b = Bounds.from_points({ start, end_ })
	if b == nil then
		return nil
	end
	return broadphase.conservative_bounds(
		b,
		f32(f32(f32(radius + world.maximum_fatness) + world.maximum_triangle_margin) + f32(span * broadphase.THIN_MARGIN))
	)
end

-- ROBLOX: итератор -> список пар { index (с нуля), треугольник }.
function broadphase.line_candidates(world: any, start: Vector3, end_: Vector3, radius: number): { { any } }
	local bounds = broadphase.line_candidate_bounds(world, start, end_, radius)
	local out = {}
	for _, r in broadphase.candidate_ranges(world, bounds) do
		for i = r.start, r.end_ - 1 do
			if world.query_metadata == nil or bounds == nil or Bounds.overlaps(world.triangle_bounds[i + 1], bounds) then
				table.insert(out, { i, world.triangles[i + 1] })
			end
		end
	end
	return out
end

-- ZIP hierarchy results in canonical mesh order, for current metadata consumers.
function broadphase.candidate_mesh_indices(world: any, bounds: Bounds?): ({ number }?, string?)
	local metadata = world.query_metadata
	if metadata == nil then
		return nil, "Canonical world has no authored query metadata"
	end
	if bounds == nil or not Bounds.valid(bounds) then
		local all = {}
		for i = 0, #metadata.meshes - 1 do
			all[i + 1] = i
		end
		return all, nil
	end
	return query_index.QueryIndex.query(
		world.query_index,
		broadphase.conservative_bounds(bounds, f32(world.maximum_fatness + world.maximum_triangle_margin)),
		metadata.meshes
	),
		nil
end

function broadphase.primitive_bounds(primitive: any): Bounds?
	local kind = primitive.kind
	if kind == "Capsule" then
		local radius, half_length, axis, center = primitive.radius, primitive.half_length, primitive.axis, primitive.center
		if not rt.is_finite(radius) then
			return nil
		end
		-- 82AD97A0: centre +- fma(|axis|, half length +68, radius +80).
		local function extent(a: number): number
			return mul_add(math.abs(a), half_length, math.abs(radius))
		end
		local e = vector.create(extent(axis.x), extent(axis.y), extent(axis.z))
		return Bounds.from_points({
			vector.create(f32(center.x - e.x), f32(center.y - e.y), f32(center.z - e.z)),
			vector.create(f32(center.x + e.x), f32(center.y + e.y), f32(center.z + e.z)),
		})
	elseif kind == "RoundedBox" then
		local radius, center, half = primitive.radius, primitive.center, primitive.half_extents
		if not rt.is_finite(radius) then
			return nil
		end
		-- 82AD9558: per world axis, |axis 1| * h1, then fma |axis 0| * h0,
		-- then fma |axis 2| * h2, then + radius (+80) as a separate add.
		local c = primitive.basis.columns
		local h0, h1, h2 = math.abs(half.x), math.abs(half.y), math.abs(half.z)
		local extent = {}
		for axis = 1, 3 do
			extent[axis] = f32(
				mul_add(math.abs(c[3][axis]), h2, mul_add(math.abs(c[1][axis]), h0, f32(math.abs(c[2][axis]) * h1)))
					+ math.abs(radius)
			)
		end
		return Bounds.from_points({
			vector.create(f32(center.x - extent[1]), f32(center.y - extent[2]), f32(center.z - extent[3])),
			vector.create(f32(center.x + extent[1]), f32(center.y + extent[2]), f32(center.z + extent[3])),
		})
	elseif kind == "Triangle" then
		local t = primitive.triangle
		if not rt.is_finite(t.fatness) then
			return nil
		end
		local b = Bounds.from_points(t.vertices)
		return if b then Bounds.expanded(b, math.abs(t.fatness)) else nil
	end
	-- Sphere
	local s = primitive.sphere
	if not rt.is_finite(s.radius) then
		return nil
	end
	local b = Bounds.from_points({ s.center })
	return if b then Bounds.expanded(b, math.abs(s.radius)) else nil
end

-- Body motion the per-volume query box sweeps over (body +32, +48, +144, +160).
export type VolumeMotion = {
	linear_velocity: Vector3,
	angular_velocity: Vector3,
	force_acceleration: Vector3,
	torque_acceleration: Vector3,
}

local VolumeMotion = {}
broadphase.VolumeMotion = VolumeMotion

function VolumeMotion.default(): VolumeMotion
	local z = vector.zero
	return { linear_velocity = z, angular_velocity = z, force_acceleration = z, torque_acceleration = z }
end

function VolumeMotion.of(rates: any): VolumeMotion
	return {
		linear_velocity = rates.linear_velocity,
		angular_velocity = rates.angular_velocity,
		force_acceleration = rates.force_acceleration,
		torque_acceleration = rates.torque_acceleration,
	}
end

-- Step = rate * dt + clamp(dot(rate * dt, accel * dt^2), 0, 1) * accel * dt^2.
local function motion_step(rate: Vector3, acceleration: Vector3, dt: number): Vector3
	local r = { rate.x, rate.y, rate.z }
	local a = { acceleration.x, acceleration.y, acceleration.z }
	local first, second = {}, {}
	for i = 1, 3 do
		first[i] = f32(r[i] * dt)
		second[i] = f32(f32(a[i] * dt) * dt)
	end
	-- ROBLOX: Sum для f32 в Rust начинается с -0.0.
	local sum = -0.0
	for i = 1, 3 do
		sum = f32(sum + f32(first[i] * second[i]))
	end
	local factor = fmin(fmax(sum, 0.0), 1.0)
	local out = {}
	for i = 1, 3 do
		out[i] = mul_add(r[i], dt, f32(f32(f32(a[i] * factor) * dt) * dt))
	end
	return vector.create(out[1], out[2], out[3])
end

-- 82777E70: the box every world triangle's vertex box is tested against in
-- 8277BC58 (BE94..BF38) before the pair query. Primitive bounds from the
-- shape's bounds slot, padded by the largest extent difference times
-- min(|angular step|, 1), unioned with itself moved by the linear step, then
-- scaled about its centre.
function broadphase.volume_query_bounds(primitive: any, motion: VolumeMotion, step: number, scale: number): Bounds?
	local b = broadphase.primitive_bounds(primitive)
	if b == nil then
		return nil
	end
	local ex, ey, ez = f32(b.max.x - b.min.x), f32(b.max.y - b.min.y), f32(b.max.z - b.min.z)
	local extent_pad = fmax(fmax(math.abs(f32(ex - ey)), math.abs(f32(ey - ez))), math.abs(f32(ez - ex)))
	local angular = motion_step(motion.angular_velocity, motion.torque_acceleration, step)
	-- vmsum3fp128, vrsqrtefp128 and two Newton refinements, length = x * y,
	-- zero for a zero step: the same sequence as board_motion_output::length.
	local length = board_motion_output.length(angular)
	local pad = f32(extent_pad * fmin(length, 1.0))
	local linear = motion_step(motion.linear_velocity, motion.force_acceleration, step)
	local lmin = { f32(b.min.x - pad), f32(b.min.y - pad), f32(b.min.z - pad) }
	local lmax = { f32(b.max.x + pad), f32(b.max.y + pad), f32(b.max.z + pad) }
	local l = { linear.x, linear.y, linear.z }
	local centre, half, omin, omax = {}, {}, {}, {}
	for i = 1, 3 do
		lmin[i] = fmin(lmin[i], f32(lmin[i] + l[i]))
		lmax[i] = fmax(lmax[i], f32(lmax[i] + l[i]))
		centre[i] = f32(f32(lmax[i] + lmin[i]) * 0.5)
		half[i] = f32(f32(lmax[i] - centre[i]) * scale)
		omin[i] = f32(centre[i] - half[i])
		omax[i] = f32(centre[i] + half[i])
	end
	local out = { min = vector.create(omin[1], omin[2], omin[3]), max = vector.create(omax[1], omax[2], omax[3]) }
	return if Bounds.valid(out) then out else nil
end

return broadphase
