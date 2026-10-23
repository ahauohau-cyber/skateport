--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_animation.rs (коммит 2e16697)
--
-- Original TU3 board error capture82C04368 and animation blend82C01878.
-- PC arithmetic and the recovered refinements are used; this is not a claim
-- of instruction-identical Xenon estimates or exceptional-lane execution.

local rt = require("../../rt")
local constraint_frames = require("./constraint_frames")
local drive_frames = require("./drive_frames")
local native_arithmetic = require("./native_arithmetic")
local sar = require("./skeleton_animation_record")
local skeleton_root = require("./skeleton_root")
local point_graph = require("../point_graph")
local trigonometry = require("../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot4 = native_arithmetic.dot4
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine
local copy_transform = sar.copy_transform
local PointGraph = point_graph.PointGraph

type Transform = sar.AnimationPartTransform

local board_animation = {}

export type BoardAnimationSettings = {
	slow: point_graph.PointGraph,
	fast: point_graph.PointGraph,
}

-- ///Board240 and288. This state must be shared between physical Ground error
-- ///capture and subsequent animated-board updates; it is not a per-state cache.
export type BoardAnimation = {
	rotation_error: { number },
	blending: boolean,
}

local BoardAnimation = {}
board_animation.BoardAnimation = BoardAnimation

-- ROBLOX: impl Default.
function BoardAnimation.default(): BoardAnimation
	--Original constructor82C01100/1104.
	return { rotation_error = { 0.0, 0.0, 0.0, 1.0 }, blending = false }
end

-- ///82C0606C resets the quaternion. The source does not clear byte288.
function BoardAnimation.reset(self: BoardAnimation)
	self.rotation_error = { 0.0, 0.0, 0.0, 1.0 }
end

-- ///82C04368: target inverse * actual DECK PART frame, reverse-axis
-- ///orthonormalization, quaternion conversion, and unconditional activation.
function BoardAnimation.capture_physics_error(self: BoardAnimation, target: Transform, deck_part: Transform)
	local relative = skeleton_root.orthonormalize(compose_affine(skeleton_root.inverse_rigid(target), deck_part))
	local q = drive_frames.retail_quaternion_from_basis({
		columns = {
			{ relative[1][1], relative[1][2], relative[1][3] },
			{ relative[2][1], relative[2][2], relative[2][3] },
			{ relative[3][1], relative[3][2], relative[3][3] },
		},
	})
	self.rotation_error = { q.x, q.y, q.z, q.w }
	self.blending = true
end

-- ///82C041C0 returns the target unchanged while inactive. Otherwise the
-- ///slow/fast graph is evaluated once per invocation, without a dt factor.
function BoardAnimation.apply(self: BoardAnimation, target: Transform, fast: boolean, settings: BoardAnimationSettings): Transform
	if not self.blending then
		return copy_transform(target)
	end
	local angle = f32(trigonometry.acos(self.rotation_error[4]) * 2.0)
	local turns = f32(angle * from_bits(0x3e22_f983))
	local fraction0 = f32(turns - math.floor(turns))
	local folded = f32(fraction0 - (if fraction0 > 0.5 then 1.0 else 0.0))
	local distance = math.abs(f32(folded * from_bits(0x40c9_0fdb)))
	local fraction = PointGraph.evaluate(if fast then settings.fast else settings.slow, distance)
	--Original fcmpu/blt: unordered graph output also completes the blend.
	if not (fraction < from_bits(0x3f73_3333)) then
		self.blending = false
		return copy_transform(target)
	end
	local identity = { 0.0, 0.0, 0.0, 1.0 }
	local dot = dot4(self.rotation_error, identity)
	local reverse = 0.0 > dot
	local magnitude = if reverse then -dot else dot
	local q = {}
	for i = 1, 4 do
		q[i] = if reverse then -self.rotation_error[i] else self.rotation_error[i]
	end
	if magnitude > from_bits(0x3f7f_069e) then
		local same_sign = dot4(q, identity) > 0.0
		local mixed = {}
		for lane = 1, 4 do
			if same_sign then
				mixed[lane] = mul_add(fraction, f32(identity[lane] - q[lane]), q[lane])
			else
				mixed[lane] = mul_add(-f32(identity[lane] + q[lane]), fraction, q[lane])
			end
		end
		local inverse = constraint_frames.reciprocal_sqrt(dot4(mixed, mixed))
		q = { f32(mixed[1] * inverse), f32(mixed[2] * inverse), f32(mixed[3] * inverse), f32(mixed[4] * inverse) }
	else
		local theta = trigonometry.acos(magnitude)
		local a = trigonometry.sin(f32(f32(1.0 - fraction) * theta))
		local b = trigonometry.sin(f32(fraction * theta))
		local inverse = constraint_frames.reciprocal(trigonometry.sin(theta))
		local weight_a = f32(a * inverse)
		local weight_b = f32(b * inverse)
		local r = {}
		for lane = 1, 4 do
			r[lane] = mul_add(identity[lane], weight_b, f32(q[lane] * weight_a))
		end
		q = r
	end
	self.rotation_error = q
	--82C01B04..BE0 uses the same sqrt(2) / paired residual basis kernel
	--independently present in82AE1CC4. No quaternion normalization here.
	local rotation = constraint_frames.basis({ x = q[1], y = q[2], z = q[3], w = q[4] })
	local correction = IDENTITY()
	for axis = 1, 3 do
		local c = rotation.columns[axis]
		correction[axis][1], correction[axis][2], correction[axis][3] = c[1], c[2], c[3]
	end
	return compose_affine(target, correction)
end

-- ///82C04270: target is compared with actual deck BODY COM, then all seven
-- ///board bodies receive this XYZ velocity, leaving their angular rates alone.
function board_animation.target_velocity(target: { number }, deck_body_position: { number }, dt: number): { number }
	local inverse = f32(1.0 / dt)
	local out = {}
	for lane = 1, 4 do
		out[lane] = f32(f32(target[lane] - deck_body_position[lane]) * inverse)
	end
	return out
end

return board_animation
