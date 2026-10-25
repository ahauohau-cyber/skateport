-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_body/record")
local v2 = import("skate_core/physics/skeleton_body/construction")
local v3 = import("skate_core/physics/skeleton_body/runtime")
local v4 = import("skate_core/physics/skeleton_body/joints")
local v5 = import("skate_core/physics/skeleton_body/drive_dynamics")
local v6 = import("skate_core/physics/skeleton_body/drive_frames")
local v7 = import("skate_core/physics/skeleton_body/targets")
local v8 = import("skate_core/physics/skeleton_body/target_update")
local v9 = import("skate_core/physics/skeleton_body/drives")
local v10 = import("skate_core/physics/skeleton_body/collision_mode")
local v11 = import("skate_core/physics/skeleton_body/collision_feedback")
local v12 = import("skate_core/physics/skeleton_body/errors")

return {
    SkeletonPhysicalRecord = v1.SkeletonPhysicalRecord,
    BoneSettings = v2.BoneSettings,
    HatGeometry = v2.HatGeometry,
    SkeletonBodyDefinition = v2.SkeletonBodyDefinition,
    SkeletonBodySettings = v2.SkeletonBodySettings,
    SkeletonPart = v2.SkeletonPart,
    SkeletonBody = v3.SkeletonBody,
    JointBone = v4.JointBone,
    JointSettings = v4.JointSettings,
    SkeletonJointSettings = v4.SkeletonJointSettings,
    SkeletonJoint = v4.SkeletonJoint,
    SkeletonJoints = v4.SkeletonJoints,
    AnimationDriveSettings = v5.AnimationDriveSettings,
    DriveInterpolation = v5.DriveInterpolation,
    BoneDriveSettings = v5.BoneDriveSettings,
    BoneDriveDynamics = v5.BoneDriveDynamics,
    bone_drive_frames = v6.bone_drive_frames,
    prepare_bone_drive_frames = v6.prepare_bone_drive_frames,
    SkeletonTargets = v7.SkeletonTargets,
    TARGET_COUNT = v7.TARGET_COUNT,
    SkeletonTargetInput = v8.SkeletonTargetInput,
    SkeletonTargetUpdate = v8.SkeletonTargetUpdate,
    ExtraTargetPositions = v8.ExtraTargetPositions,
    SkeletonDriveSettings = v9.SkeletonDriveSettings,
    BoneDrives = v9.BoneDrives,
    SkeletonDrives = v9.SkeletonDrives,
    SkeletonDriveIdentity = v9.SkeletonDriveIdentity,
    SkeletonDriveBatch = v9.SkeletonDriveBatch,
    SkeletonCollisionSettings = v10.SkeletonCollisionSettings,
    SkeletonPartCollision = v10.SkeletonPartCollision,
    SkeletonCollisionMode = v10.SkeletonCollisionMode,
    SkeletonFeedbackSettings = v11.SkeletonFeedbackSettings,
    SkeletonContactBody = v11.SkeletonContactBody,
    SkeletonContactReport = v11.SkeletonContactReport,
    SkeletonCollisionInput = v11.SkeletonCollisionInput,
    BoneContact = v11.BoneContact,
    ContactRegion = v11.ContactRegion,
    ContactPlane = v11.ContactPlane,
    SpecificContact = v11.SpecificContact,
    SkeletonContactFlags = v11.SkeletonContactFlags,
    SkeletonCollisionFeedback = v11.SkeletonCollisionFeedback,
    SkeletonPoseErrors = v12.SkeletonPoseErrors,
    SkeletonNormalError = v12.SkeletonNormalError,
    PART_COUNT = 26,
    ANIMATION_PART_COUNT = 24,
    JOINT_COUNT = 22
}
