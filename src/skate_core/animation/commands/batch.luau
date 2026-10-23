--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/commands/batch.rs (коммит 2e16697)
--
-- Owned host execution for the recovered SetData worker.
--
-- 828D7E08/828D7FD8 define batch boundaries and dependency collection; preparing
-- a job is not submitting or completing it (828C88D8). This synchronous host
-- adapter accepts only SetData jobs and already-materialized input buffers.
-- It is not a replacement for the full ACS scheduler or its other engines.

local rt = require("../../../rt")
local buffers = require("./buffers")
local set_data = require("./set_data")

local batch = {}

export type JobId = { owner: number, index: number }

-- ROBLOX: enum QueueError -> строки "CommandCapacityExceeded" |
-- "DependencyCapacityExceeded" | "UnavailableDependency" (через rt.raise).

type Job = { bone_count: number, commands: { set_data.SetDataCommand }, dependencies: { JobId } }

local function job_new(): Job
	return { bone_count = 0, commands = {}, dependencies = {} }
end

local function same(a: JobId, b: JobId): boolean
	return a.owner == b.owner and a.index == b.index
end

export type SetDataQueue = {
	owner: number,
	buffers: buffers.PoseBuffers,
	max_work_units: number,
	prepared: { Job },
	current: Job,
	command_count: number,
}

local SetDataQueue = {}
batch.SetDataQueue = SetDataQueue

-- ROBLOX: NonZeroU16 -> число > 0 (проверяется assert).
function SetDataQueue.new(b: buffers.PoseBuffers, max_work_units: number): SetDataQueue
	assert(max_work_units > 0 and max_work_units <= 0xffff)
	return { owner = buffers.new_owner(), buffers = b, max_work_units = max_work_units, prepared = {}, current = job_new(), command_count = 0 }
end

-- Finalize pending metadata; never executes a worker or exposes its output.
function SetDataQueue.flush(self: SetDataQueue): boolean
	if #self.current.commands == 0 then
		return false
	end
	table.insert(self.prepared, self.current)
	self.current = job_new()
	return true
end

-- A returned job identity establishes neither execution nor output readiness.
-- None (false в таблице) corresponds to a null dependency; current-job references are removed.
function SetDataQueue.enqueue(self: SetDataQueue, bone_count: number, command: set_data.SetDataCommand, dependencies: { JobId | false }): JobId
	if self.command_count == 0xffff then
		rt.raise("CommandCapacityExceeded")
	end
	local full = #self.current.commands == self.max_work_units
	local id = { owner = self.owner, index = #self.prepared + (if full then 1 else 0) }
	local collected = if full then {} else table.clone(self.current.dependencies)
	for _, d in dependencies do
		if d ~= false then
			local dependency = d :: JobId
			if not same(dependency, id) then
				if dependency.owner ~= self.owner or dependency.index >= id.index then
					rt.raise("UnavailableDependency")
				end
				local found = false
				for _, c in collected do
					if same(c, dependency) then
						found = true
					end
				end
				if not found then
					if #collected == 255 then
						rt.raise("DependencyCapacityExceeded")
					end
					table.insert(collected, dependency)
				end
			end
		end
	end
	if full then
		SetDataQueue.flush(self)
	end
	-- The native job header is rewritten on EVERY enqueue. Its last count
	-- applies to external copies for all records in that job.
	self.current.bone_count = bone_count
	table.insert(self.current.commands, command)
	self.current.dependencies = collected
	self.command_count += 1
	return id
end

export type PendingSetData = { owner: number, buffers: buffers.PoseBuffers, jobs: { Job } }
export type CompletedSetData = { buffers: buffers.PoseBuffers }
export type ExecutionFailure = {
	-- Diagnostic/recovery storage only; this is not a completed pose certificate.
	buffers: buffers.PoseBuffers,
	job: JobId,
	cause: buffers.BufferError,
}

function SetDataQueue.submit(self: SetDataQueue): PendingSetData
	SetDataQueue.flush(self)
	return { owner = self.owner, buffers = self.buffers, jobs = self.prepared }
end

-- Safe because no workers have been started by this host adapter.
function SetDataQueue.cancel(self: SetDataQueue): buffers.PoseBuffers
	return self.buffers
end

local PendingSetData = {}
batch.PendingSetData = PendingSetData

-- Execute complete workers in preparation order. All accepted dependencies
-- point to earlier jobs, so their writes precede dependent reads. No native
-- concurrency ordering beyond those dependencies is asserted.
-- ROBLOX: Result<CompletedSetData, ExecutionFailure> -> (completed) или (nil, failure).
function PendingSetData.complete(self: PendingSetData): (CompletedSetData?, ExecutionFailure?)
	for index, job in self.jobs do
		local _, cause = rt.catch(set_data.execute, self.buffers, job.bone_count, job.commands)
		if cause ~= nil then
			return nil, { buffers = self.buffers, job = { owner = self.owner, index = index - 1 }, cause = cause }
		end
	end
	return { buffers = self.buffers }, nil
end

local CompletedSetData = {}
batch.CompletedSetData = CompletedSetData

function CompletedSetData.buffers(self: CompletedSetData): buffers.PoseBuffers
	return self.buffers
end
-- Reuse can begin only after completion releases ownership.
function CompletedSetData.into_buffers(self: CompletedSetData): buffers.PoseBuffers
	return self.buffers
end

return batch
