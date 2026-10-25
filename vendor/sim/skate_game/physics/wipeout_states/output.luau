-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory")
local v2 = import("skate_core/player/wipeout_state")
local v3 = import("skate_core/player/wipeout_state/response")
local QueryResult = v1.QueryResult
local State = v2.State

return {
    fill = function(p1) -- fill | line: 18
        -- upvalues: rt (copy), v3 (copy), QueryResult (copy), State (copy)
        local wipeout_state, collision_feedback = p1.wipeout_state, p1.collision_feedback
        local v4 = v3.response_normal(if collision_feedback.flags.compliant then rt.copy(collision_feedback.highest_normal) else nil, if QueryResult.valid(wipeout_state.prediction.result) then rt.copy(wipeout_state.prediction.result.landing_normal) else nil)

        return State.output(wipeout_state.state, p1.skeleton.record.pose[24], v4)
    end
}
