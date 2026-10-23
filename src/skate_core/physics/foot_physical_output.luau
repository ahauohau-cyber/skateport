--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/foot_physical_output.rs (коммит 2e16697)
--
-- Full original SkeletonIK::FillPhysOut_FeetDeckInteraction82BF22A0.
-- Physical toe positions and derivatives are observed in the physical board's
-- frame. They are distinct from animation targets and contact-query validity.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local sar = require("./skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add

type Transform = sar.AnimationPartTransform
type F4 = { number }

local foot_physical_output = {}

export type FootPhysicalSettings = {
	deck_half_width: number,
	deck_total_half_length: number,
	-- Original physics_skeletonik layout64 FootOnDeckPadding.
	padding: F4,
}

export type FootPhysicalState = {
	-- IK3136/3152. Reset82BEDB5C/60 writes both vectors to zero.
	previous_local_toes: { F4 },
}

export type FootPhysicalOutput = {
	-- PhysOutSkeleton192/208: change in local physical toe positions / dt.
	local_velocity: { F4 },
	-- PhysOutSkeleton224/240: physical record velocities15/19, copied intact.
	world_velocity: { F4 },
	-- PhysOutSkeleton600/601. Strict XYZ containment, with authored padding.
	within_deck_box: { boolean },
}

local FootPhysicalState = {}
foot_physical_output.FootPhysicalState = FootPhysicalState

function FootPhysicalState.default(): FootPhysicalState
	return { previous_local_toes = { { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } } }
end

function FootPhysicalState.reset(self: FootPhysicalState)
	self.previous_local_toes = { { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } }
end

local function inverse_physical_board(board: Transform): Transform
	local inverse = { { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } }
	for axis = 1, 3 do
		for lane = 1, 3 do
			inverse[axis][lane] = board[lane][axis]
		end
	end
	--82BF2398..241C builds -P.z * inverseZ, then Y and X in source order.
	for lane = 1, 4 do
		local z = f32(-board[4][3] * inverse[3][lane])
		local yz = mul_add(-board[4][2], inverse[2][lane], z)
		inverse[4][lane] = mul_add(-board[4][1], inverse[1][lane], yz)
	end
	return inverse
end

local function transform_point(frame: Transform, p: F4): F4
	local out = {}
	for lane = 1, 4 do
		local x = mul_add(frame[1][lane], p[1], frame[4][lane])
		local xy = mul_add(frame[2][lane], p[2], x)
		out[lane] = mul_add(frame[3][lane], p[3], xy)
	end
	return out
end

-- ROBLOX: record — SkeletonPhysicalRecord (skeleton_body/record.luau).
function FootPhysicalState.update(self: FootPhysicalState, record: any, dt: number, settings: FootPhysicalSettings): FootPhysicalOutput
	local inverse = inverse_physical_board(record.pose[1])
	local positions = { transform_point(inverse, record.pose[16][4]), transform_point(inverse, record.pose[20][4]) }
	local inverse_dt = native_arithmetic.reciprocal_estimate(dt)
	for _ = 1, 2 do
		inverse_dt = mul_add(inverse_dt, mul_add(-inverse_dt, dt, 1.0), inverse_dt)
	end
	local local_velocity = {}
	for foot = 1, 2 do
		local v = {}
		for lane = 1, 4 do
			v[lane] = f32(f32(positions[foot][lane] - self.previous_local_toes[foot][lane]) * inverse_dt)
		end
		local_velocity[foot] = v
	end
	self.previous_local_toes = positions
	--82165A10 is zero: only authored padding supplies the box's Y extent.
	local dimensions = { settings.deck_half_width, 0.0, settings.deck_total_half_length, 0.0 }
	local bounds = {}
	for lane = 1, 4 do
		bounds[lane] = f32(dimensions[lane] + settings.padding[lane])
	end
	local within = {}
	for i, p in positions do
		within[i] = math.abs(p[1]) < bounds[1] and math.abs(p[2]) < bounds[2] and math.abs(p[3]) < bounds[3]
	end
	return {
		local_velocity = local_velocity,
		world_velocity = { table.clone(record.velocities[16]), table.clone(record.velocities[20]) },
		within_deck_box = within,
	}
end

return foot_physical_output
