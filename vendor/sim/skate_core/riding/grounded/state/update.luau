-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/riding/pumping/controller")
local v2 = import("skate_core/riding/grounded/state/contact_state")
local PhysicsGroundState = import("skate_core/riding/grounded/state/data").PhysicsGroundState
local call
local t1 = {
    GroundUpdateStage = {},
    GroundUpdateError = {},
    update = function(p1, p2, p3, p4, p5) -- update | line: 47
        -- upvalues: v1 (copy), v2 (copy), PhysicsGroundState (copy), call (ref)
        if PhysicsGroundState.begin_update(p1, p4).set_skeleton_flag_16505 then
            call("SetElapsedSkeletonFlag", p5.set_elapsed_skeleton_flag, p5)
        end

        call("UpdateContactState", v2.update, p3, p4.contact_state, p5)

        local v3, v4, v5 = call("LoadPumpingFrame", p5.pumping_frame, p5)

        call("UpdatePumping", v1.update_ground, p2, v3, v4, v5, p5)
        call("UpdateSkateboard", p5.update_skateboard, p5, p1)
        call("PredictFutureDeck", p5.predict_future_deck, p5)

        if p1.flag_2722 then
            call("SetCollisionSkeletonFlag", p5.set_collision_skeleton_flag, p5)
        end

        call("SetGroundSkeletonFlag", p5.set_ground_skeleton_flag, p5)
        PhysicsGroundState.finish_update(p1, p4.timestep_2604)

        if bit32.band(p4.contact_state.flags_2476, 4194304) == 0 then
            return call("UpdateTrajectory", p5.update_trajectory, p5)
        end

        return call("UpdateSpecialState", p5.update_special_state, p5)
    end
}

local function finish_call(p6, p7, ...) -- line: 69
    if p7 then
        return ...
    end

    error({
        stage = p6,
        source = ...
    }, 0)

    return ...
end

function call(p8, p9, ...) -- line: 79
    -- upvalues: finish_call (copy)
    return finish_call(p8, pcall(p9, ...))
end

t1.call = call

return t1
