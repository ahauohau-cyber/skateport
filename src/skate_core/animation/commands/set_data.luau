--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/commands/set_data.rs (коммит 2e16697)
--
-- ACSsetData_job (TU3 0x828D80B8), expressed in bones and typed allocations.

local buffers = require("./buffers")

local set_data = {}

-- ROBLOX: enum InternalUpdate<T> -> { kind = "Set", source, bone_count } | { kind = "Preserve" }.
-- Native opcode 12: byte-sized partial SET count. Every other opcode skips
-- the SET copy, but still permits extraction.
export type InternalUpdate = { kind: string, source: buffers.BoneSlice?, bone_count: number? }

export type CopyCommand = { update: InternalUpdate, internal: buffers.BoneSlice, external: buffers.BoneSlice? }

-- ROBLOX: enum SetDataCommand -> { kind = "Sqt" | "Matrix", command = CopyCommand }.
export type SetDataCommand = { kind: string, command: CopyCommand }

-- 828D7E08 uses the low byte of numExtBones when the encoded byte is zero.
function set_data.resolve_set_count(encoded_count: number, external_bone_count: number): number
	if encoded_count == 0 then
		return bit32.band(external_bone_count, 255)
	end
	return encoded_count
end

local function copy(b: buffers.BoneBuffers, skeleton_bones: number, command: CopyCommand)
	local update = command.update
	if update.kind == "Set" then
		buffers.BoneBuffers.copy(b, update.source :: buffers.BoneSlice, command.internal, update.bone_count :: number)
	end
	if command.external ~= nil then
		-- Read internal after SET, including writes through earlier aliases.
		buffers.BoneBuffers.copy(b, command.internal, command.external, skeleton_bones)
	end
end

-- ROBLOX: Result<(), BufferError> -> rt.raise(BufferError).
function set_data.execute(pose: buffers.PoseBuffers, bone_count: number, commands: { SetDataCommand })
	for _, c in commands do
		if c.kind == "Sqt" then
			copy(pose.sqt, bone_count, c.command)
		else
			copy(pose.matrices, bone_count, c.command)
		end
	end
end

return set_data
