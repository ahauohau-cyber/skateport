--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/hook_drive/mod.rs (коммит 2e16697)
--
-- TU3 hook-drive state. The hook is a separate target part, child of deck 6.
-- Registration, target publication and the caller's state transition remain
-- explicit; changing these live dynamics does not recreate the drive.
-- ROBLOX: set_child_angular_frame/set_parent_angular_frame — в @self/frames.

local rt = require("../../rt")
local drive_parameters = require("./drive_parameters")
local frames = require("@self/frames")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local RetailDriveType = drive_parameters.RetailDriveType

local hook_drive = {}

export type HookDriveState = {
	-- JointFrames at SkateboardBody+896: child quaternion/translation, parent
	-- quaternion/translation, four words each in guest lane order.
	frames: { number },
	-- Live linear then angular parameters at SkateboardBody+960.
	dynamics: { number },
}

local HookDriveState = {}
hook_drive.HookDriveState = HookDriveState

local function soft(spring: number, strength: number): { number }
	local damping = f32(f32(spring * frames.rsqrt(spring)) * 2.0)
	return { to_bits(spring), to_bits(damping), to_bits(strength), 1 }
end

function HookDriveState.disable_linear(self: HookDriveState)
	rt.copy_into(self.dynamics, 0, { 0, 0, 0, 2 })
end

function HookDriveState.disable_angular(self: HookDriveState)
	rt.copy_into(self.dynamics, 4, { 0, 0, 0, 2 })
end

-- Frame/dynamics initialization in 82C0D330. This does not manufacture the
-- separate hook assembly, allocate a drive, or choose a gameplay pose.
function HookDriveState.initial(): HookDriveState
	local state = { frames = rt.zeros(16), dynamics = rt.zeros(8) }
	local identity = {}
	for i, value in { 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0 } do
		identity[i] = to_bits(value)
	end
	frames.set_child_angular_frame(state.frames, identity)
	frames.set_parent_angular_frame(state.frames, identity)
	HookDriveState.disable_linear(state)
	HookDriveState.disable_angular(state)
	return state
end

-- Complete 82C0D5C0. Other fields and the caller's animated flag survive.
function HookDriveState.enable_angular_soft(self: HookDriveState)
	rt.copy_into(self.dynamics, 4, soft(20000.0, from_bits(0x470c_9fff)))
end

-- ROBLOX: `animated: &mut u8` — в Luau нет ссылок на число, поэтому функции
-- возвращают новое значение флага; вызывающий сохраняет его сам.

-- 82C04708, including its inline linear enable and 82C0D5C0 call.
-- TU3 reads no caller strength multiplier here.
function HookDriveState.enable_animation_soft(self: HookDriveState): number
	rt.copy_into(self.dynamics, 0, soft(5000.0, from_bits(0x44e0_fffe)))
	HookDriveState.enable_angular_soft(self)
	return 1
end

-- Complete 82C05658: animated flag, angular soft, then linear hard/zero.
function HookDriveState.enable_angular_only(self: HookDriveState): number
	HookDriveState.enable_angular_soft(self)
	HookDriveState.disable_linear(self)
	return 1
end

-- Inline Ground Enter82D375D0..5FC and LetGo82D75450..98 operation.
-- The blend flag and stored board quaternion are not inputs or outputs.
function HookDriveState.disable_animation(self: HookDriveState): number
	HookDriveState.disable_linear(self)
	HookDriveState.disable_angular(self)
	return 0
end

function HookDriveState.solver_dynamics(self: HookDriveState): drive_parameters.RetailDriveDynamics
	local function params(i: number): drive_parameters.RetailDriveParams
		local t = self.dynamics[i + 4]
		return {
			spring_or_max_velocity = from_bits(self.dynamics[i + 1]),
			damping = from_bits(self.dynamics[i + 2]),
			max_strength = from_bits(self.dynamics[i + 3]),
			drive_type = if t == 1 then RetailDriveType.SoftDrive elseif t == 2 then RetailDriveType.HardDrive else RetailDriveType.NoDrive,
		}
	end
	return { linear = params(0), angular = params(4) }
end

-- ROBLOX: #[derive(Clone)].
function HookDriveState.clone(self: HookDriveState): HookDriveState
	return { frames = table.clone(self.frames), dynamics = table.clone(self.dynamics) }
end

return hook_drive
