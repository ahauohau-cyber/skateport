--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/frame.rs (коммит 2e16697)
--
-- Stock frame order recovered from TU3 `0x82859E70`, `0x8275EB10` and
-- `0x8275ED68`. The solver boundary intentionally splits the frame because
-- the native game submits jobs before returning for the post-solver pass.
-- ROBLOX: enum FrameStage/SchedulerState -> строки с теми же именами.
-- ROBLOX: traits *Phases -> таблицы с методами; ошибка фазы — rt.raise(e)
-- внутри метода. ScheduleError<E> -> таблица { kind = "WrongState" | "Runtime", ... },
-- выбрасывается через rt.raise.

local rt = require("../../rt")

local frame = {}

export type FrameStage =
	"StartFrame"
	| "WorldPreFrame"
	| "AnimationPhaseOne"
	| "AnimationPhaseTwo"
	| "WorldPrepare"
	| "AnimationPhaseThree"
	| "WorldPrecursor"
	| "ActorPhysicsPublication"
	| "PostZeroJobs"
	| "Input"
	| "WorldAfterInput"
	| "PostInput"
	| "Logic"
	| "PreState"
	| "State"
	| "PostState"
	| "CollectSolverInputs"
	| "PrepareSolverJobs"
	| "SubmitSolver"
	| "WaitSolver"
	| "Adjust"
	| "PostAdjust"
	| "Output"
	| "PostOutput"
	| "FinishOutputs"

export type SchedulerState = "Ready" | "Running" | "SolverPending" | "Faulted"

export type ScheduleError = {
	kind: "WrongState",
	expected: SchedulerState,
	actual: SchedulerState,
} | {
	kind: "Runtime",
	stage: FrameStage,
	source: any,
}

export type AnimationPhases = {
	phase_one: (self: any) -> (),
	phase_two: (self: any) -> (),
	phase_three: (self: any) -> (),
	publish_physics_input: (self: any) -> (),
}

export type WorldPhases = {
	-- `82DC2FB8`; writes the shared timestep and its reciprocal and clears the
	-- current job/island counters.
	start_frame: (self: any, timestep: number) -> (),
	pre_frame: (self: any) -> (),
	prepare: (self: any) -> (),
	precursor: (self: any) -> (),
	-- World-owned work at `8275E6E8`, between all Input and Post-Input calls.
	after_input: (self: any) -> (),
	-- `8275E928`; filtered physicals publish solver-facing work.
	collect_solver_inputs: (self: any) -> (),
	-- Conditioners, contact reports and final world output after Post 5-Jobs.
	finish_outputs: (self: any) -> (),
}

export type PhysicalPhases = {
	post_zero_jobs: (self: any) -> (),
	input: (self: any) -> (),
	post_input: (self: any) -> (),
	logic: (self: any) -> (),
	pre_state: (self: any) -> (),
	state: (self: any) -> (),
	post_state: (self: any) -> (),
	adjust: (self: any) -> (),
	post_adjust: (self: any) -> (),
	output: (self: any) -> (),
	post_output: (self: any) -> (),
}

export type SolverPhases = {
	-- `82764480` / `82DC35E0`; builds the dependency tree after every state
	-- has submitted contacts, joints, drives and external forces.
	prepare_jobs: (self: any) -> (),
	-- `82763B08`; finalizes collision data and submits the dependency tree.
	submit: (self: any) -> (),
	-- `82763D18`; the Adjust phase cannot run until this fence completes.
	wait: (self: any) -> (),
}

export type FrameScheduler = {
	scheduler_state: SchedulerState,
}

local FrameScheduler = {}
frame.FrameScheduler = FrameScheduler

-- ROBLOX: impl Default; приватное поле state -> scheduler_state (имя state
-- занято методом).
function FrameScheduler.default(): FrameScheduler
	return { scheduler_state = "Ready" }
end

function FrameScheduler.state(self: FrameScheduler): SchedulerState
	return self.scheduler_state
end

local function require_state(self: FrameScheduler, expected: SchedulerState)
	if self.scheduler_state ~= expected then
		rt.raise({ kind = "WrongState", expected = expected, actual = self.scheduler_state })
	end
end

-- ROBLOX: self.call(stage, object.method(args)) -> вызов метода внутри
-- rt.catch; при ошибке состояние становится Faulted и выбрасывается Runtime.
local function call(self: FrameScheduler, stage: FrameStage, object: any, method: string, ...: any)
	local _, err = rt.catch(object[method], object, ...)
	if err ~= nil then
		self.scheduler_state = "Faulted"
		rt.raise({ kind = "Runtime", stage = stage, source = err })
	end
end

-- Runs the complete pre-solver half of the stock player frame. Successful
-- return means jobs were submitted and their inputs must remain alive.
function FrameScheduler.run_before_solver(
	self: FrameScheduler,
	timestep: number,
	animation: any,
	world: any,
	physical: any,
	solver: any
)
	require_state(self, "Ready")
	self.scheduler_state = "Running"

	call(self, "StartFrame", world, "start_frame", timestep)
	call(self, "WorldPreFrame", world, "pre_frame")
	call(self, "AnimationPhaseOne", animation, "phase_one")
	call(self, "AnimationPhaseTwo", animation, "phase_two")
	call(self, "WorldPrepare", world, "prepare")
	call(self, "AnimationPhaseThree", animation, "phase_three")
	call(self, "WorldPrecursor", world, "precursor")
	call(self, "ActorPhysicsPublication", animation, "publish_physics_input")
	call(self, "PostZeroJobs", physical, "post_zero_jobs")
	call(self, "Input", physical, "input")
	call(self, "WorldAfterInput", world, "after_input")
	call(self, "PostInput", physical, "post_input")
	call(self, "Logic", physical, "logic")
	call(self, "PreState", physical, "pre_state")
	call(self, "State", physical, "state")
	call(self, "PostState", physical, "post_state")
	call(self, "CollectSolverInputs", world, "collect_solver_inputs")
	call(self, "PrepareSolverJobs", solver, "prepare_jobs")
	call(self, "SubmitSolver", solver, "submit")
	self.scheduler_state = "SolverPending"
end

-- Completes the stock post-solver half. The scheduler becomes reusable
-- only after every output/conditioner phase succeeds.
function FrameScheduler.run_after_solver(self: FrameScheduler, world: any, physical: any, solver: any)
	require_state(self, "SolverPending")
	self.scheduler_state = "Running"

	call(self, "WaitSolver", solver, "wait")
	call(self, "Adjust", physical, "adjust")
	call(self, "PostAdjust", physical, "post_adjust")
	call(self, "Output", physical, "output")
	call(self, "PostOutput", physical, "post_output")
	call(self, "FinishOutputs", world, "finish_outputs")
	self.scheduler_state = "Ready"
end

return frame
