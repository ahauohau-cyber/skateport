--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/drive_solver.rs (коммит 2e16697)
--
-- Scalar port of Skate 3 TU3's RenderWare drive Jacobian and solve path.
-- A retail drive is not a generic six-degree-of-freedom joint. TU3 builds three
-- linear and three quaternion-component constraint rows into a 384-byte
-- workspace, then solves each drive sequentially. This module keeps those rows
-- in named scalar fields and preserves the observed soft/hard coefficient and
-- impulse-limit equations.
-- ROBLOX: build_drive_rows лежит в @self/builder (в Rust — pub use builder::*).

local rt = require("../../rt")
local math_mod = require("../math")
local native_arithmetic = require("./native_arithmetic")
local constraint_frames = require("./constraint_frames")
local rigid_body = require("./rigid_body")

local f32 = rt.f32

type Vector3 = vector

local drive_solver = {}

drive_solver.tu3 = {
	DRIVE_JACOBIAN_BUILD = 0x82AE_1AE8,
	ITERATIVE_CONSTRAINT_SOLVER = 0x82AE_27D0,
}

drive_solver.ACTIVE_BODY = 4

export type RetailDriveBodyState = {
	-- ROBLOX: индекс реакции с нуля, как в Rust.
	reaction_index: number,
	state: number,
	orientation: rigid_body.RetailQuaternion,
	-- Native Body+64/+80/+96, independently read for the anchor transform.
	basis: math_mod.Basis3,
	center_of_mass: Vector3,
	linear_velocity: Vector3,
	angular_velocity: Vector3,
	force_acceleration: Vector3,
	torque_acceleration: Vector3,
	inverse_mass: number,
	world_inverse_inertia: rigid_body.RetailPackedWorldInverseInertia,
}

export type RetailDriveRows = {
	-- Body paired with `DriveFrames::body_a`.
	frame_a_body: RetailDriveBodyState,
	-- Body paired with `DriveFrames::body_b`.
	frame_b_body: RetailDriveBodyState,
	arm_a: Vector3,
	arm_b: Vector3,
	-- World-space columns of the frame-B basis.
	linear_axes: { Vector3 },
	-- Normalized world-space quaternion-component Jacobian axes (generally
	-- not orthogonal).
	angular_axes: { Vector3 },
	linear_inverse_effective_mass: { number },
	angular_inverse_effective_mass: { number },
	linear_softness: number,
	angular_softness: number,
	-- Preconditioned target impulses in constraint-row order.
	linear_target_impulse: { number },
	angular_target_impulse: { number },
	linear_maximum_impulse: { number },
	angular_maximum_impulse: { number },
	accumulated_linear_impulse: { number },
	accumulated_angular_impulse: { number },
}

-- Runs TU3's drive portion of the sequential iterative constraint solver.
function drive_solver.solve_drive_rows(drives: { RetailDriveRows }, reactions: { rigid_body.RetailReactionCorrections }, maximum_iterations: number)
	local solver = require("./solver") :: any
	solver.solve_constraints({}, {}, drives, reactions, maximum_iterations)
end

-- One drive pass through the same native kernel used by the shared solver.
function drive_solver.solve_drive_iteration(drives: { RetailDriveRows }, reactions: { rigid_body.RetailReactionCorrections })
	drive_solver.solve_drive_rows(drives, reactions, 1)
end

function drive_solver.is_active(body: RetailDriveBodyState): boolean
	return bit32.band(body.state, drive_solver.ACTIVE_BODY) == drive_solver.ACTIVE_BODY
end

function drive_solver.basis_columns(basis: math_mod.Basis3): { Vector3 }
	local c = basis.columns
	return {
		vector.create(c[1][1], c[1][2], c[1][3]),
		vector.create(c[2][1], c[2][2], c[2][3]),
		vector.create(c[3][1], c[3][2], c[3][3]),
	}
end

function drive_solver.dot(a: Vector3, b: Vector3): number
	return native_arithmetic.dot3({ a.x, a.y, a.z, 0.0 }, { b.x, b.y, b.z, 0.0 })
end

function drive_solver.project(v: Vector3, axes: { Vector3 }): { number }
	return { drive_solver.dot(v, axes[1]), drive_solver.dot(v, axes[2]), drive_solver.dot(v, axes[3]) }
end

function drive_solver.point_rate(linear: Vector3, angular: Vector3, arm: Vector3): Vector3
	return constraint_frames.point_rate(linear, angular, arm)
end

function drive_solver.add(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x + b.x), f32(a.y + b.y), f32(a.z + b.z))
end

function drive_solver.sub(a: Vector3, b: Vector3): Vector3
	return vector.create(f32(a.x - b.x), f32(a.y - b.y), f32(a.z - b.z))
end

function drive_solver.scale(v: Vector3, factor: number): Vector3
	return vector.create(f32(v.x * factor), f32(v.y * factor), f32(v.z * factor))
end

function drive_solver.cross(a: Vector3, b: Vector3): Vector3
	return constraint_frames.cross(a, b)
end

-- pub use builder::build_drive_rows
function drive_solver.build_drive_rows(...): RetailDriveRows
	return (require("@self/builder") :: any).build_drive_rows(...)
end

return drive_solver
