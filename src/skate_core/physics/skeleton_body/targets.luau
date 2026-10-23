--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/targets.rs (коммит 2e16697)
--
-- Original TU3 SkeletonDrives::InitHooks82BEAB70 creates four static targets.
-- These physical constraint endpoints contain no runtime interception code.

local rt = require("../../../rt")
local assembly = require("../assembly")
local part_mod = require("../board_pose/part")
local normalization = require("../board_pose/normalization")
local board_runtime = require("../board_runtime")
local df = require("../drive_frames")
local drive_parameters = require("../drive_parameters")
local rigid_body = require("../rigid_body")
local sar = require("../skeleton_animation_record")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local IDENTITY = sar.IDENTITY
local RetailDriveType = drive_parameters.RetailDriveType

type AnimationPartTransform = sar.AnimationPartTransform
type BodySnapshot = assembly.BodySnapshot
type RetailDriveFrames = df.RetailDriveFrames
type RetailDriveDynamics = drive_parameters.RetailDriveDynamics
type RetailDriveParams = drive_parameters.RetailDriveParams

local targets = {}

targets.TARGET_COUNT = 4
-- ROBLOX: индексы частей с нуля.
targets.TARGET_PARTS = table.freeze({ 23, 0, 24, 25 })
targets.HARD_VELOCITY = from_bits(0x4415_FFFF)
targets.HARD_STRENGTH = from_bits(0x470C_9FFF)
local HARD_VELOCITY = targets.HARD_VELOCITY
local HARD_STRENGTH = targets.HARD_STRENGTH

export type SkeletonTargets = {
	bodies: { BodySnapshot },
	frames: { RetailDriveFrames },
	dynamics: { RetailDriveDynamics },
}

local SkeletonTargets = {}
targets.SkeletonTargets = SkeletonTargets

local function static_inertia(): rigid_body.RetailInertiaDynamics
	return {
		inverse_tensor = vector.zero,
		inverse_mass = 0.0,
		spherical = 0.0,
		maximum_linear_velocity = 0.0,
		maximum_angular_velocity = 0.0,
		linear_drag = 0.0,
		angular_drag = 0.0,
	}
end

function targets.hard(velocity: number, strength: number): RetailDriveParams
	return { spring_or_max_velocity = velocity, damping = 0.0, max_strength = strength, drive_type = RetailDriveType.HardDrive }
end
local hard = targets.hard

local function words(frame: AnimationPartTransform): { number }
	local w: { number } = table.create(16) :: any
	for i = 0, 15 do
		w[i + 1] = to_bits(frame[i // 4 + 1][i % 4 + 1])
	end
	return w
end

local function floats(frame: { number }): AnimationPartTransform
	local m = {}
	for i = 0, 3 do
		m[i + 1] = { from_bits(frame[i * 4 + 1]), from_bits(frame[i * 4 + 2]), from_bits(frame[i * 4 + 3]), from_bits(frame[i * 4 + 4]) }
	end
	return m
end

function SkeletonTargets.new(simulation: rigid_body.RetailSimulationStep): SkeletonTargets
	local bodies: { BodySnapshot } = table.create(4) :: any
	for i = 1, 4 do
		local part: part_mod.PartPose = {
			transform = words(IDENTITY()),
			local_mass_frame = words(IDENTITY()),
			body = table.create(44, 0),
			inertia = nil,
		}
		part_mod.set_part_transform(part, words(IDENTITY()))
		-- Original82BEAED4 inserts STATIC_BODY(1), giving zero inverse
		-- mass/tensor/rates. The centered.1m box's authored100kg and its
		-- disabled collision volume never participate in that response.
		bodies[i] = board_runtime.initialized_body(part, static_inertia(), simulation, board_runtime.BoardMotion.Static)
	end
	local function identity(): df.RetailDriveFrame
		return { orientation = rigid_body.RetailQuaternion.IDENTITY(), translation = vector.zero }
	end
	--82BEAD34..ADC8: X=(0,1,0),Y=(0,0,1),Z=(1,0,0).
	local function extra(): df.RetailDriveFrame
		return {
			orientation = df.retail_quaternion_from_basis({ columns = { { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 }, { 1.0, 0.0, 0.0 } } }),
			translation = vector.zero,
		}
	end
	local frames: { RetailDriveFrames } = table.create(4) :: any
	for i = 0, 3 do
		frames[i + 1] = { body_a = if i >= 2 then extra() else identity(), body_b = identity() }
	end
	local function strong()
		return hard(HARD_VELOCITY, HARD_STRENGTH)
	end
	local function root()
		return hard(from_bits(0x426F_FFFF), HARD_STRENGTH)
	end
	return {
		bodies = bodies,
		frames = frames,
		dynamics = {
			{ linear = strong(), angular = strong() },
			{ linear = root(), angular = root() },
			{ linear = hard(0.0, 0.0), angular = strong() },
			{ linear = hard(0.0, 0.0), angular = strong() },
		},
	}
end

-- /// Native PartSetTransform preserves velocity and force state while
-- /// changing the body transform. Its local mass frame is identity here.
-- ROBLOX: index — индекс цели с нуля.
function SkeletonTargets.set_transform(self: SkeletonTargets, index: number, frame: AnimationPartTransform)
	local body = self.bodies[index + 1]
	local part: part_mod.PartPose = {
		transform = words(frame),
		local_mass_frame = words(IDENTITY()),
		body = table.create(44, 0),
		inertia = nil,
	}
	part_mod.set_part_transform(part, words(frame))
	local w = part.body :: { number }
	local function f(i: number): number
		return from_bits(w[i + 1])
	end
	body.rates.orientation = { x = f(0), y = f(1), z = f(2), w = f(3) }
	body.rates.position = vector.create(f(4), f(5), f(6))
	body.rates.basis = { columns = { { f(16), f(17), f(18) }, { f(20), f(21), f(22) }, { f(24), f(25), f(26) } } }
end

-- /// Reset82BD9DB8/9DE0 normalizes these two desired matrices before
-- /// PartSetTransform. The other two target parts retain their pose.
function SkeletonTargets.reset(self: SkeletonTargets, hips: AnimationPartTransform, spawn: AnimationPartTransform)
	for index, frame in { hips, spawn } do
		SkeletonTargets.set_transform(self, index - 1, floats(normalization.orthonormalize_rotation(words(frame))))
	end
end

function SkeletonTargets.transform(self: SkeletonTargets, index: number): AnimationPartTransform
	local body = self.bodies[index + 1]
	local m = IDENTITY()
	for i = 1, 3 do
		local c = body.rates.basis.columns[i]
		m[i][1], m[i][2], m[i][3] = c[1], c[2], c[3]
	end
	local p = body.rates.position
	m[4] = { p.x, p.y, p.z, 0.0 }
	return m
end

-- /// Ground::PredictFutureDeck82D38630 moves target0, not physical hips.
function SkeletonTargets.apply_future_deck_displacement(self: SkeletonTargets, displacement: vector)
	local frame = SkeletonTargets.transform(self, 0)
	frame[4][1] = f32(frame[4][1] + displacement.x)
	frame[4][2] = f32(frame[4][2] + displacement.y)
	frame[4][3] = f32(frame[4][3] + displacement.z)
	SkeletonTargets.set_transform(self, 0, frame)
end

return targets
