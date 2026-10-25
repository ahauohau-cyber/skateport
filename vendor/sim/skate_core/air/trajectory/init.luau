-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/prediction")
local v2 = import("skate_core/air/trajectory/query")
local v3 = import("skate_core/air/trajectory/selector")
local v4 = import("skate_core/air/trajectory/types")

return {
    Prediction = v1.Prediction,
    QueryRequest = v1.QueryRequest,
    QueryResult = v1.QueryResult,
    Trajectory = v1.Trajectory,
    SurfaceHit = v2.SurfaceHit,
    query_trajectory = v2.query_trajectory,
    Selection = v3.Selection,
    TrajectorySelector = v3.TrajectorySelector,
    WorldWithoutGrindEdges = v3.WorldWithoutGrindEdges,
    LaunchInfo = v4.LaunchInfo,
    SelectorInput = v4.SelectorInput,
    SelectorSettings = v4.SelectorSettings
}
