--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/mod.rs (коммит 2e16697)
--
-- Physical skater assembly and its postphysics observations.
-- The body has 26 parts; animation and COM weighting use its first 24.
-- ROBLOX: `pub use` -> поля таблицы модуля. collision_filter/collision_update
-- добавляют методы в SkeletonCollisionFeedback, target_update — в SkeletonTargets.

local record = require("@self/record")
local construction = require("@self/construction")
local runtime = require("@self/runtime")
local joints = require("@self/joints")
local drive_dynamics = require("@self/drive_dynamics")
local drive_frames = require("@self/drive_frames")
local targets = require("@self/targets")
local target_update = require("@self/target_update")
local drives = require("@self/drives")
local collision_mode = require("@self/collision_mode")
local collision_feedback = require("@self/collision_feedback")
require("@self/collision_update")
require("@self/collision_vector")
require("@self/collision_filter")
local errors = require("@self/errors")

export type SkeletonPhysicalRecord = record.SkeletonPhysicalRecord
export type BoneSettings = construction.BoneSettings
export type HatGeometry = construction.HatGeometry
export type SkeletonBodyDefinition = construction.SkeletonBodyDefinition
export type SkeletonBodySettings = construction.SkeletonBodySettings
export type SkeletonPart = construction.SkeletonPart
export type SkeletonBody = runtime.SkeletonBody
export type JointBone = joints.JointBone
export type JointSettings = joints.JointSettings
export type SkeletonJointSettings = joints.SkeletonJointSettings
export type SkeletonJoint = joints.SkeletonJoint
export type SkeletonJoints = joints.SkeletonJoints
export type AnimationDriveSettings = drive_dynamics.AnimationDriveSettings
export type DriveInterpolation = drive_dynamics.DriveInterpolation
export type BoneDriveSettings = drive_dynamics.BoneDriveSettings
export type BoneDriveDynamics = drive_dynamics.BoneDriveDynamics
export type SkeletonTargets = targets.SkeletonTargets
export type SkeletonTargetInput = target_update.SkeletonTargetInput
export type SkeletonTargetUpdate = target_update.SkeletonTargetUpdate
export type ExtraTargetPositions = target_update.ExtraTargetPositions
export type SkeletonDriveSettings = drives.SkeletonDriveSettings
export type BoneDrives = drives.BoneDrives
export type SkeletonDrives = drives.SkeletonDrives
export type SkeletonDriveIdentity = drives.SkeletonDriveIdentity
export type SkeletonDriveBatch = drives.SkeletonDriveBatch
export type SkeletonCollisionSettings = collision_mode.SkeletonCollisionSettings
export type SkeletonPartCollision = collision_mode.SkeletonPartCollision
export type SkeletonCollisionMode = collision_mode.SkeletonCollisionMode
export type CollisionResponseSettings = collision_feedback.CollisionResponseSettings
export type SkeletonFeedbackSettings = collision_feedback.SkeletonFeedbackSettings
export type SkeletonContactBody = collision_feedback.SkeletonContactBody
export type SkeletonContactReport = collision_feedback.SkeletonContactReport
export type SkeletonCollisionInput = collision_feedback.SkeletonCollisionInput
export type BoneContact = collision_feedback.BoneContact
export type ContactRegion = collision_feedback.ContactRegion
export type ContactPlane = collision_feedback.ContactPlane
export type SpecificContact = collision_feedback.SpecificContact
export type SkeletonContactFlags = collision_feedback.SkeletonContactFlags
export type SkeletonCollisionFeedback = collision_feedback.SkeletonCollisionFeedback
export type SkeletonPoseErrors = errors.SkeletonPoseErrors
export type SkeletonNormalError = errors.SkeletonNormalError

return {
	SkeletonPhysicalRecord = record.SkeletonPhysicalRecord,
	HatGeometry = construction.HatGeometry,
	SkeletonBodyDefinition = construction.SkeletonBodyDefinition,
	SkeletonBody = runtime.SkeletonBody,
	SkeletonJoints = joints.SkeletonJoints,
	BoneDriveDynamics = drive_dynamics.BoneDriveDynamics,
	bone_drive_frames = drive_frames.bone_drive_frames,
	prepare_bone_drive_frames = drive_frames.prepare_bone_drive_frames,
	SkeletonTargets = targets.SkeletonTargets,
	TARGET_COUNT = targets.TARGET_COUNT,
	SkeletonDrives = drives.SkeletonDrives,
	SkeletonCollisionMode = collision_mode.SkeletonCollisionMode,
	collision_response = collision_feedback.collision_response,
	BoneContact = collision_feedback.BoneContact,
	ContactRegion = collision_feedback.ContactRegion,
	SkeletonContactFlags = collision_feedback.SkeletonContactFlags,
	SkeletonCollisionFeedback = collision_feedback.SkeletonCollisionFeedback,
	SkeletonPoseErrors = errors.SkeletonPoseErrors,

	PART_COUNT = 26,
	ANIMATION_PART_COUNT = 24,
	JOINT_COUNT = 22,
}
