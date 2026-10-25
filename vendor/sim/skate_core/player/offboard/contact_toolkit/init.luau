-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/physics/reciprocal_sqrt")

import("skate_core/player/offboard/contact_toolkit/analyzer_math")

local v3 = import("skate_core/player/offboard/contact_toolkit/candidate")
local v4 = import("skate_core/player/offboard/contact_toolkit/classification")
local v5 = import("skate_core/player/offboard/contact_toolkit/collection")
local v6 = import("skate_core/player/offboard/contact_toolkit/generation")
local v7 = import("skate_core/player/offboard/contact_toolkit/infill")
local v8 = import("skate_core/player/offboard/contact_toolkit/prefix")
local v9 = import("skate_core/player/offboard/contact_toolkit/probes")
local v10 = import("skate_core/player/offboard/contact_toolkit/profile")
local v11 = import("skate_core/player/offboard/contact_toolkit/publication")
local v12 = import("skate_core/player/offboard/contact_toolkit/samples")
local v13 = import("skate_core/player/offboard/contact_toolkit/sweep")
local t1 = {
    ContactPrefix = v8.ContactPrefix,
    Batch = v9.Batch,
    Input = v9.Input,
    LineProbe = v9.LineProbe,
    ProbeLayout = v9.ProbeLayout,
    ContactSample = v12.ContactSample,
    Samples = v12.Samples,
    query_sweep = v13.query_sweep
}
local ContactPrefix, ProbeLayout = t1.ContactPrefix, t1.ProbeLayout
local Candidate = v3.Candidate
local History = v4.History

t1.UP = { 0, 1, 0, 0 }
t1.ZERO = { 0, 0, 0, 0 }
t1.IDENTITY = {
    { 1, 0, 0, 0 },
    { 0, 1, 0, 0 },
    { 0, 0, 1, 0 },
    { 0, 0, 0, 0 }
}

local dot, sub, scale, cross
local v14 = false

function t1.set_reference(p1) -- line: 62
    -- upvalues: v14 (ref)
    v14 = p1
end

function t1.triangle_normal(p2) -- line: 65
    -- upvalues: v2 (copy), t1 (copy), v14 (ref)
    if v14 then
        return t1.triangle_normal_reference(p2)
    end

    local v15 = p2[1]
    local v16 = p2[2]
    local v17 = p2[3]
    local v18 = v15[1]
    local v19 = v15[2]
    local v20 = v15[3]
    local v21 = v16[1] - v18
    local v22 = v16[2] - v19
    local v23 = v16[3] - v20
    local v24 = v17[1] - v18
    local v25 = v17[2] - v19
    local v26 = v17[3] - v20
    local v27 = -v23 * v25 + v22 * v26
    local v28 = -v21 * v26 + v23 * v24
    local v29 = -v22 * v24 + v21 * v25
    local v30 = v27 * v27 + v28 * v28 + v29 * v29
    local v31 = v2.estimate(v30)
    local v32 = v31 * 0.5 * (-v30 * (v31 * v31) + 1) + v31
    local v33 = v32 * 0.5 * (-v30 * (v32 * v32) + 1) + v32

    return {
        v27 * v33,
        v28 * v33,
        v29 * v33,
        0 * v33
    }
end

function t1.triangle_normal_reference(p3) -- line: 83
    -- upvalues: v2 (copy), dot (ref), sub (ref), scale (ref), cross (ref)
    local v34 = p3[1]
    local v35 = p3[2]
    local v36 = p3[3]
    local v37 = cross(sub(v35, v34), sub(v36, v34))
    local v38 = dot(v37, v37)
    local v39 = v2.estimate(v38)
    local v40 = v39 * 0.5 * (-v38 * (v39 * v39) + 1) + v39
    local v41 = v40 * 0.5 * (-v38 * (v40 * v40) + 1) + v40

    return scale(v37, v41)
end

t1.LineHit = {}
t1.QueryResults = {}
t1.Scene = {}
t1.Collected = {}
t1.Owner = {}

function t1.Owner.default() -- line: 127
    -- upvalues: ContactPrefix (copy), ProbeLayout (copy), Candidate (copy), History (copy)
    return {
        pending = nil,
        readiness = 0,
        layout = ProbeLayout.stock(),
        prefix = ContactPrefix.reset(),
        candidate = Candidate.default(),
        history = History.default()
    }
end

function t1.Owner.begin_input(p4) -- line: 140
    -- upvalues: t1 (copy)
    p4.readiness = math.max(p4.readiness - 1, 0)
    t1.Owner.refresh(p4)
end

function t1.Owner.reset_history(p5) -- line: 149
    -- upvalues: t1 (copy), History (copy)
    t1.Owner.refresh(p5)
    p5.readiness = 0
    p5.history = History.default()
end

function t1.Owner.prefix(p6) -- line: 155
    -- upvalues: rt (copy)
    return rt.copy(p6.prefix)
end

function t1.Owner.submit(p7, p8, p9, p10) -- line: 162
    -- upvalues: ProbeLayout (copy)
    local v43 = ProbeLayout.prepare(p7.layout, p8, p9)
    local v44 = p10.execute(p10, v43)

    p7.readiness = 0
    p7.pending = { v43, v44 }
end

local v45

local function reset_prefix_into(p11) -- line: 182
    -- upvalues: t1 (copy), ContactPrefix (copy), v45 (ref)
    local v46 = v45

    if v46 == nil then
        v46 = {}

        for v47 in ContactPrefix.reset() do
            v46[v47] = true
        end

        v45 = v46
    end

    local position, normal, support_frame, target_position = p11.position, p11.normal, p11.support_frame, p11.target_position
    local target_normal, edge_position, edge_normal = p11.target_normal, p11.edge_position, p11.edge_normal

    if type(position) ~= "table"
        or #position ~= 4
        or type(normal) ~= "table"
        or #normal ~= 4
        or type(target_position) ~= "table"
        or #target_position ~= 4
        or type(target_normal) ~= "table"
        or #target_normal ~= 4
        or type(edge_position) ~= "table"
        or #edge_position ~= 4
        or type(edge_normal) ~= "table"
        or #edge_normal ~= 4
        or type(support_frame) ~= "table"
        or #support_frame ~= 4 then
        return false
    end

    local ZERO, UP, IDENTITY = t1.ZERO, t1.UP, t1.IDENTITY

    if #ZERO ~= 4 or #UP ~= 4 or #IDENTITY ~= 4 then
        return false
    end

    for i = 1, 4 do
        local v48 = support_frame[i]
        local v49 = IDENTITY[i]

        if type(v48) ~= "table" or #v48 ~= 4 or type(v49) ~= "table" or #v49 ~= 4 then
            return false
        end
    end

    for v50 in p11 do
        if v46[v50] == nil then
            p11[v50] = nil
        end
    end

    local v51 = ZERO[1]
    local v52 = ZERO[2]
    local v53 = ZERO[3]
    local v54 = ZERO[4]
    local v55 = UP[1]
    local v56 = UP[2]
    local v57 = UP[3]
    local v58 = UP[4]

    position[1] = v51
    position[2] = v52
    position[3] = v53
    position[4] = v54
    normal[1] = v55
    normal[2] = v56
    normal[3] = v57
    normal[4] = v58

    for i = 1, 4 do
        local v59 = support_frame[i]
        local v60 = IDENTITY[i]
        local v61 = v60[1]
        local v62 = v60[2]
        local v63 = v60[3]
        local v64 = v60[4]

        v59[1] = v61
        v59[2] = v62
        v59[3] = v63
        v59[4] = v64
    end

    target_position[1] = v51
    target_position[2] = v52
    target_position[3] = v53
    target_position[4] = v54
    target_normal[1] = v55
    target_normal[2] = v56
    target_normal[3] = v57
    target_normal[4] = v58
    edge_position[1] = v51
    edge_position[2] = v52
    edge_position[3] = v53
    edge_position[4] = v54
    edge_normal[1] = v51
    edge_normal[2] = v52
    edge_normal[3] = v53
    edge_normal[4] = v54
    p11.scalar_160 = 0
    p11.kind_164 = 0
    p11.distance_168 = 1E+10
    p11.distance_172 = 1E+10
    p11.flags_176 = 0
    p11.support_180 = 0

    return true
end

t1.reset_prefix_into = reset_prefix_into

function t1.Owner.refresh(p12) -- line: 242
    -- upvalues: rt (copy), v5 (copy), v6 (copy), v7 (copy), v10 (copy), v11 (copy), ContactPrefix (copy), v14 (ref), reset_prefix_into (copy)
    local prefix = p12.prefix

    if v14 or type(prefix) ~= "table" or not reset_prefix_into(prefix) then
        p12.prefix = ContactPrefix.reset()
    end

    p12.readiness = 30

    local pending = p12.pending

    p12.pending = nil

    if pending == nil then
        return nil
    end

    local v65 = pending[1]
    local v66 = pending[2]
    local v67 = ContactPrefix.reset()

    ContactPrefix.consume_support(v67, v65.input, v66.trajectories, p12.candidate.flags)

    local v68 = v5.collect(v65, p12.layout, v66)

    v7.insert_obstacles(v65.input, v68)
    v7.correct_normals(v65.input, v68)

    local v69, v70 = v10.simplify(v65.input, v68.ground)

    v67.distance_172 = v69

    local v71 = v10.build(v65.input, rt.slice(v68.ground, 0, v70))
    local v72 = v6.generate(v65.input, v71, v67, v69, p12.candidate.flags)

    v11.publish(v65.input, v71, v68, v72, v69, p12.candidate, p12.history, v67)
    p12.prefix = rt.copy(v67)

    return {
        batch = v65,
        results = v66,
        prefix = v67,
        samples = v68
    }
end

function t1.Owner.has_pending(p13) -- line: 283
    return p13.pending ~= nil
end

function t1.Owner.readiness(p14) -- line: 287
    return p14.readiness
end

function t1.dot(p15, p16) -- line: 291
    -- upvalues: v1 (copy)
    return v1.dot3(p15, p16)
end

dot = t1.dot

function t1.sub(p17, p18) -- line: 296
    return {
        p17[1] - p18[1],
        p17[2] - p18[2],
        p17[3] - p18[3],
        p17[4] - p18[4]
    }
end

sub = t1.sub

function t1.scale(p19, p20) -- line: 301
    return {
        p19[1] * p20,
        p19[2] * p20,
        p19[3] * p20,
        p19[4] * p20
    }
end

scale = t1.scale

function t1.cross(p21, p22) -- line: 306
    return {
        -p21[3] * p22[2] + p21[2] * p22[3],
        -p21[1] * p22[3] + p21[3] * p22[1],
        -p21[2] * p22[1] + p21[1] * p22[2],
        0
    }
end

cross = t1.cross

function t1.length(p23) -- line: 316
    -- upvalues: v2 (copy), dot (ref)
    local v73 = dot(p23, p23)

    if v73 == 0 then
        return 0
    end

    local v74 = v2.estimate(v73)
    local v75 = v74 * 0.5 * (-v73 * (v74 * v74) + 1) + v74

    return v73 * (v75 * 0.5 * (-v73 * (v75 * v75) + 1) + v75)
end

return t1
