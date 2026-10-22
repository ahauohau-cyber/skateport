--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/reckoning_frames.rs (коммит 2e16697)
--
-- Reckoning transform, dynamic lean and lateral tilt, TU3
-- 82D8D688/82D8D930/82D8C4F8. State scheduling and frame producers are separate.
-- Numerical primitives retain their documented hardware-validation boundary.

local rt = require("../../rt")
local bmo = require("../physics/board_motion_output")
local native_arithmetic = require("../physics/native_arithmetic")
local sar = require("../physics/skeleton_animation_record")
local point_graph = require("../point_graph")
local collision_response = require("./collision_response")
local trigonometry = require("../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local inverse_length_squared = bmo.inverse_length_squared
local dot3 = native_arithmetic.dot3
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine
local copy_transform = sar.copy_transform
local PointGraph = point_graph.PointGraph
local signed_angle = collision_response.signed_angle

type Vector3 = vector
type F4 = { number }
type AnimationPartTransform = sar.AnimationPartTransform

local reckoning_frames = {}

export type ReckoningFrames = {
	-- 752: ground frame, whose translation is retained by CalculateTransform.
	ground: AnimationPartTransform,
	-- 816: system frame after application of the body-flip transform.
	system: AnimationPartTransform,
	-- 880: same frame before body flip, used by CalculateTilt.
	unflipped: AnimationPartTransform,
	-- 944: rigid inverse of the final system frame.
	inverse_system: AnimationPartTransform,
	-- 1008: body-flip transform, produced by UpdateBodyFlip.
	body_flip: AnimationPartTransform,
	-- 1200: heading, reprojected onto the current up plane on each calculation.
	heading: F4,
	-- 1576, published to PhysOutSystemReckoning160 with the stance sign.
	target_lean_angle: number,
	-- 1248: first lane consumed by the body-tilt animation handler.
	lateral_tilt: F4,
}

local ReckoningFrames = {}
reckoning_frames.ReckoningFrames = ReckoningFrames

local function normalize(value: F4): F4
	local reciprocal = inverse_length_squared(dot3(value, value), 2)
	return { f32(value[1] * reciprocal), f32(value[2] * reciprocal), f32(value[3] * reciprocal), f32(value[4] * reciprocal) }
end

local function cross(a: F4, b: F4): F4
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

local function inverse(frame: AnimationPartTransform): AnimationPartTransform
	local axes = {}
	for i = 1, 3 do
		axes[i] = { frame[1][i], frame[2][i], frame[3][i], 0.0 }
	end
	local p = {}
	for i = 1, 4 do
		p[i] = f32(0.0 - frame[4][i])
	end
	local position = {}
	for i = 1, 4 do
		local z = f32(axes[3][i] * p[3])
		local y = mul_add(axes[2][i], p[2], z)
		position[i] = mul_add(axes[1][i], p[1], y)
	end
	return { axes[1], axes[2], axes[3], position }
end

local function wrap_fraction(angle: number): number
	local turns = f32(angle * from_bits(0x3e22_f983))
	local fraction = f32(turns - math.floor(turns))
	fraction = f32(fraction - (if fraction > 0.5 then 1.0 else 0.0))
	return f32(fraction * from_bits(0x40c9_0fdb))
end

local function xyz(v: F4): Vector3
	return vector.create(v[1], v[2], v[3])
end

-- 82D33178 initializes each matrix independently to identity and seeds
-- heading to world X. Reset82D8C3A8 later preserves the matrices.
function ReckoningFrames.new(): ReckoningFrames
	return {
		ground = IDENTITY(),
		system = IDENTITY(),
		unflipped = IDENTITY(),
		inverse_system = IDENTITY(),
		body_flip = IDENTITY(),
		heading = { 1.0, 0.0, 0.0, 0.0 },
		target_lean_angle = 0.0,
		lateral_tilt = { 0.0, 0.0, 0.0, 0.0 },
	}
end

-- ROBLOX: #[derive(Clone)].
function ReckoningFrames.clone(self: ReckoningFrames): ReckoningFrames
	return {
		ground = copy_transform(self.ground),
		system = copy_transform(self.system),
		unflipped = copy_transform(self.unflipped),
		inverse_system = copy_transform(self.inverse_system),
		body_flip = copy_transform(self.body_flip),
		heading = table.clone(self.heading),
		target_lean_angle = self.target_lean_angle,
		lateral_tilt = table.clone(self.lateral_tilt),
	}
end

-- 82D8D688. Cross products use the unnormalized intermediate axis;
-- normalization has two refinements and no epsilon fallback in this leaf.
function ReckoningFrames.calculate_transform(self: ReckoningFrames, up: F4, ground_normal: F4)
	local right = cross(up, self.heading)
	local forward = cross(right, up)
	self.heading = normalize(forward)
	self.system[1] = normalize(right)
	self.system[2] = table.clone(up)
	self.system[3] = table.clone(self.heading)
	self.unflipped = copy_transform(self.system)
	self.system = compose_affine(self.body_flip, self.system)
	self.inverse_system = inverse(self.system)

	local ground_right = cross(ground_normal, self.heading)
	local ground_forward = cross(ground_right, ground_normal)
	self.ground[1] = normalize(ground_right)
	self.ground[2] = table.clone(ground_normal)
	self.ground[3] = normalize(ground_forward)
end

-- 82D8D930. Signed angle is wrapped by fraction/floor, not scalar atan2.
function ReckoningFrames.calculate_dynamic_lean(self: ReckoningFrames, up: F4, dynamic_up: F4)
	local axis = self.system[3]
	local function project(value: F4): F4
		local amount = dot3(value, axis)
		local out = {}
		for i = 1, 4 do
			out[i] = f32(value[i] - f32(axis[i] * amount))
		end
		return out
	end
	local from = project(up)
	local to = project(dynamic_up)
	local threshold = from_bits(0x3727_c5ac) -- 8219B100
	self.target_lean_angle = if dot3(from, from) > threshold and dot3(to, to) > threshold
		then wrap_fraction(signed_angle(xyz(from), xyz(to), xyz(axis)))
		else 0.0
end

local HALF_PI = from_bits(0x3fc9_0fdb)
local TILT_SCALE = from_bits(0x3f22_f983)

-- 82D8C4F8. Degenerate projection preserves the preceding lateral tilt.
-- The stock source uses the unflipped up/forward axes and two authored
-- curves, including its absolute wrapped angle and stance sign change.
function ReckoningFrames.calculate_tilt(
	self: ReckoningFrames,
	reverse_stance: boolean,
	tilt_vs_angle: point_graph.PointGraph,
	tilt_vs_up: point_graph.PointGraph
)
	local axis = self.unflipped[2]
	local world_up = { 0.0, 1.0, 0.0, 0.0 }
	local d = dot3(axis, world_up)
	local parallel, projected = {}, {}
	for i = 1, 4 do
		parallel[i] = f32(axis[i] * d)
		projected[i] = f32(world_up[i] - parallel[i])
	end
	local squared = dot3(projected, projected)
	if squared <= from_bits(0x3a03_126f) then
		return
	end
	local equal = world_up[1] == parallel[1] and world_up[2] == parallel[2] and world_up[3] == parallel[3] and world_up[4] == parallel[4]
	local angle = if equal then 0.0 else signed_angle(xyz(self.unflipped[3]), xyz(normalize(projected)), xyz(axis))
	local normalized_angle = f32(f32(f32(math.abs(wrap_fraction(f32(angle - HALF_PI))) - HALF_PI) * -1.0) * TILT_SCALE)
	if reverse_stance then
		normalized_angle = -normalized_angle
	end
	-- Inline native asin polynomial82D8C704..7E0 is the same operation
	-- tree retained by trigonometry::asin, including one rsqrt refinement.
	local normalized_up_angle = f32(f32(HALF_PI - trigonometry.asin(axis[2])) * TILT_SCALE)
	local angle_tilt = PointGraph.evaluate(tilt_vs_angle, math.abs(normalized_angle))
	local up_tilt = PointGraph.evaluate(tilt_vs_up, math.abs(normalized_up_angle))
	local signed = if normalized_angle >= -0.0 then angle_tilt else -angle_tilt
	self.lateral_tilt = { f32(up_tilt * signed), 0.0, 0.0, 0.0 }
end

return reckoning_frames
