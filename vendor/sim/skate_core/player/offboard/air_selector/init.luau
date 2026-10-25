-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local v1 = import("skate_core/player/offboard/air_selector/adjustment")
local v2 = import("skate_core/player/offboard/air_selector/candidates")
local v3 = import("skate_core/player/offboard/air_selector/completion")
local v4 = import("skate_core/player/offboard/air_selector/math")
local Packet = import("skate_core/player/offboard/air_launch").Packet
local v5 = import("skate_core/player/offboard/biped_air/recovered")
local v6 = import("skate_core/player/offboard/biped_air/sampling")
local v7 = import("skate_core/player/offboard/biped_air/selection")
local QueryResult = import("skate_core/air/trajectory").QueryResult
local t1 = {
    Candidate = v7.Candidate,
    TrajectoryResult = v5.TrajectoryResult,
    SelectorState = v6.SelectorState
}
local Candidate, SelectorState = t1.Candidate, t1.SelectorState

t1.DT = 0.01666666753590107
t1.MAX_CANDIDATES = 16
t1.MESH_REJECT_MASK = 24576
t1.Settings = {}
t1.Context = {}
t1.Selector = {}

for _, v8 in {
        v1.Selector,
        v3.Selector
    } do
    for v9, v10 in v8 do
        t1.Selector[v9] = v10
    end
end

function t1.Selector.default() -- line: 84
    -- upvalues: Packet (copy), t1 (copy)
    return t1.Selector.new(Packet.initialized(0))
end

function t1.Selector.new(p2) -- line: 88
    -- upvalues: rt (copy), v4 (copy), Candidate (copy), SelectorState (copy)
    local v11 = SelectorState.reset_sampling(p2.scalar_100)

    v11.restart_allowed_8493 = false
    v11.selection.landing_frame_8480 = 0

    return {
        selected_index = nil,
        ledge_selected_8496 = false,
        just_changed_8497 = false,
        requery_pending_8499 = false,
        requery_count_8488 = 0,
        sampling = v11,
        launch = rt.copy(p2),
        candidates = {},
        predictions = {},
        scores = {},
        selected_candidate = Candidate.reset(),
        offset_8272 = { 0, 0, 0, 0 },
        correction_8304 = { 0, 0, 0, 0 },
        ledge_normal_8320 = rt.copy(v4.UP),
        requery_position_8352 = { 0, 0, 0, 0 },
        requery_normal_8368 = { 0, 0, 0, 0 }
    }
end

function t1.Selector.reset(p3) -- line: 114
    -- upvalues: rt (copy), t1 (copy), SelectorState (copy)
    rt.assign(p3, t1.Selector.new(p3.launch))
    p3.sampling = SelectorState.reset_sampling(p3.launch.scalar_100)
end

function t1.Selector.exit(p4) -- line: 120
    p4.sampling.pending_8492 = false
    p4.sampling.preinitialized_8494 = false
end

function t1.Selector.begin_launch(p5, p6, p7, p8) -- line: 128
    -- upvalues: rt (copy), v2 (copy), QueryResult (copy), t1 (copy), SelectorState (copy)
    local v12, v13, v14 = v2.prepare(p6, p7, p8)

    t1.Selector.reset(p5)
    p5.launch = rt.copy(p6)
    p5.sampling.selection.candidate_scalar_100 = p6.scalar_100
    SelectorState.seed_fallback(p5.sampling, p6.position_32, p6.velocity_0, p7)
    p5.offset_8272 = v13
    p5.correction_8304 = v14
    p5.candidates = v12

    local v15 = table.create(#p5.candidates)

    for v16, v17 in p5.candidates do
        v15[v16] = t1.request(v17.trajectory, p8.sphere_radius)
    end

    local v18 = table.create(#v15)

    for v19, v20 in v15 do
        v18[v19] = {
            request = rt.copy(v20),
            result = QueryResult.miss()
        }
    end

    p5.predictions = v18
    p5.scores = rt.filled(#v15, 0)

    return v15
end

function t1.Selector.sample(p9, p10, p11, p12, p13) -- line: 153
    -- upvalues: SelectorState (copy)
    SelectorState.sample(p9.sampling, p10, p11, p12, p13)
end

function t1.Selector.begin_requery(p14, p15, p16, p17) -- line: 159
    -- upvalues: rt (copy), QueryResult (copy), t1 (copy)
    if bit32.band(p15, 268435456) ~= 0 or bit32.band(p16, 4194304) ~= 0 or not p14.sampling.restart_allowed_8493 then
        return nil
    end

    local v21 = t1.request(p14.selected_candidate.trajectory, p17)

    t1.validate_request(v21)
    p14.sampling.restart_allowed_8493 = false
    p14.requery_pending_8499 = true

    if #p14.predictions > 0 then
        rt.assign(p14.predictions[1], {
            request = v21,
            result = QueryResult.miss()
        })
    end

    return v21
end

function t1.request(p18, p19) -- line: 182
    -- upvalues: rt (copy)
    local v22 = rt.copy(p18)

    v22.duration = 2

    return {
        start_error = 0.25,
        end_error = 1.2,
        trajectory = v22,
        radius = p19
    }
end

function t1.validate_request(p20) -- line: 195
    local trajectory = p20.trajectory
    local v23 = false

    for _, v24 in {
            trajectory.duration,
            p20.radius,
            p20.start_error,
            p20.end_error
        } do
        if v24 ~= v24 or v24 == 1e999 or v24 == (-1e999) or v24 <= 0 then
            v23 = true
            break
        end
    end

    if not v23 then
        local v25 = v23

        for _, v26 in {
                trajectory.position,
                trajectory.velocity,
                trajectory.acceleration
            } do
            local v27 = v26[1]

            if v27 == v27 and v27 ~= 1e999 and v27 ~= (-1e999) then
                local v28 = v26[2]

                if v28 == v28 and v28 ~= 1e999 and v28 ~= (-1e999) then
                    local v29 = v26[3]

                    if v29 ~= v29 or v29 == 1e999 or v29 == (-1e999) then
                        v25 = true
                    end
                else
                    v25 = true
                end
            else
                v25 = true
            end

            if v25 then
                v23 = v25
                break
            end

            v23 = v25
        end
    end

    if v23 then
        error("Invalid native BipedAir trajectory request", 0)
    end
end

return t1
