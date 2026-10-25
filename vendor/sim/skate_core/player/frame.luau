-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    FrameStage = {},
    SchedulerState = {},
    ScheduleError = {},
    AnimationPhases = {},
    WorldPhases = {},
    PhysicalPhases = {},
    SolverPhases = {},
    FrameScheduler = {}
}
local FrameScheduler = t1.FrameScheduler

function t1.FrameScheduler.default() -- line: 59
    return {
        state = "Ready"
    }
end

function t1.FrameScheduler.state(p1) -- line: 65
    return p1.state
end

function t1.FrameScheduler.run_before_solver(p2, p3, p4, p5, p6, p7) -- line: 72
    -- upvalues: FrameScheduler (copy)
    FrameScheduler.require(p2, "Ready")
    p2.state = "Running"

    local call = FrameScheduler.call
    local start_frame = p5.start_frame

    call(p2, "StartFrame", pcall(start_frame, p5, p3))

    local call2 = FrameScheduler.call
    local pre_frame = p5.pre_frame

    call2(p2, "WorldPreFrame", pcall(pre_frame, p5))

    local call3 = FrameScheduler.call
    local phase_one = p4.phase_one

    call3(p2, "AnimationPhaseOne", pcall(phase_one, p4))

    local call4 = FrameScheduler.call
    local phase_two = p4.phase_two

    call4(p2, "AnimationPhaseTwo", pcall(phase_two, p4))

    local call5 = FrameScheduler.call
    local prepare = p5.prepare

    call5(p2, "WorldPrepare", pcall(prepare, p5))

    local call6 = FrameScheduler.call
    local phase_three = p4.phase_three

    call6(p2, "AnimationPhaseThree", pcall(phase_three, p4))

    local call7 = FrameScheduler.call
    local precursor = p5.precursor

    call7(p2, "WorldPrecursor", pcall(precursor, p5))

    local call8 = FrameScheduler.call
    local publish_physics_input = p4.publish_physics_input

    call8(p2, "ActorPhysicsPublication", pcall(publish_physics_input, p4))

    local call9 = FrameScheduler.call
    local post_zero_jobs = p6.post_zero_jobs

    call9(p2, "PostZeroJobs", pcall(post_zero_jobs, p6))

    local call10 = FrameScheduler.call
    local input = p6.input

    call10(p2, "Input", pcall(input, p6))

    local call11 = FrameScheduler.call
    local after_input = p5.after_input

    call11(p2, "WorldAfterInput", pcall(after_input, p5))

    local call12 = FrameScheduler.call
    local post_input = p6.post_input

    call12(p2, "PostInput", pcall(post_input, p6))

    local call13 = FrameScheduler.call
    local logic = p6.logic

    call13(p2, "Logic", pcall(logic, p6))

    local call14 = FrameScheduler.call
    local pre_state = p6.pre_state

    call14(p2, "PreState", pcall(pre_state, p6))

    local call15 = FrameScheduler.call
    local state = p6.state

    call15(p2, "State", pcall(state, p6))

    local call16 = FrameScheduler.call
    local post_state = p6.post_state

    call16(p2, "PostState", pcall(post_state, p6))

    local call17 = FrameScheduler.call
    local collect_solver_inputs = p5.collect_solver_inputs

    call17(p2, "CollectSolverInputs", pcall(collect_solver_inputs, p5))

    local call18 = FrameScheduler.call
    local prepare_jobs = p7.prepare_jobs

    call18(p2, "PrepareSolverJobs", pcall(prepare_jobs, p7))

    local call19 = FrameScheduler.call
    local submit = p7.submit

    call19(p2, "SubmitSolver", pcall(submit, p7))
    p2.state = "SolverPending"
end

function t1.FrameScheduler.run_after_solver(p8, p9, p10, p11) -- line: 103
    -- upvalues: FrameScheduler (copy)
    FrameScheduler.require(p8, "SolverPending")
    p8.state = "Running"

    local call = FrameScheduler.call
    local wait = p11.wait

    call(p8, "WaitSolver", pcall(wait, p11))

    local call2 = FrameScheduler.call
    local adjust = p10.adjust

    call2(p8, "Adjust", pcall(adjust, p10))

    local call3 = FrameScheduler.call
    local post_adjust = p10.post_adjust

    call3(p8, "PostAdjust", pcall(post_adjust, p10))

    local call4 = FrameScheduler.call
    local output = p10.output

    call4(p8, "Output", pcall(output, p10))

    local call5 = FrameScheduler.call
    local post_output = p10.post_output

    call5(p8, "PostOutput", pcall(post_output, p10))

    local call6 = FrameScheduler.call
    local finish_outputs = p9.finish_outputs

    call6(p8, "FinishOutputs", pcall(finish_outputs, p9))
    p8.state = "Ready"
end

function t1.FrameScheduler.require(p12, p13) -- line: 117
    if p12.state ~= p13 then
        error({
            tag = "WrongState",
            expected = p13,
            actual = p12.state
        }, 0)
    end
end

function t1.FrameScheduler.call(p14, p15, p16, p17) -- line: 132
    if not p16 then
        p14.state = "Faulted"
        error({
            tag = "Runtime",
            stage = p15,
            source = p17
        }, 0)
    end
end

return t1
