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
local v1 = import("skate_game/physics/offboard/air_selector/settings")
local StaticScene = import("skate_game/physics/offboard/contact_toolkit").StaticScene
local with_world_scene = import("skate_game/physics/offboard/ground_query").with_world_scene
local WorldScene = import("skate_game/physics/offboard/ground_query/world").WorldScene
local VehicleEdgeCache = import("skate_game/physics/offboard/mod_solid_ground").VehicleEdgeCache
local v2 = import("skate_core/player/offboard/air_selector")
local v3 = import("skate_core/player/offboard/air_selector/ledge")
local t1 = {
    Settings = v1.Settings,
    AirSelector = {}
}

function t1.AirSelector.reset(p2) -- line: 41
    -- upvalues: v2 (copy)
    p2.core = v2.Selector.default()
    p2.completed_launch = nil
    p2.completed_requery = nil
end

function t1.AirSelector.new(p3) -- line: 47
    -- upvalues: v2 (copy)
    return {
        completed_launch = nil,
        completed_requery = nil,
        core = v2.Selector.default(),
        settings = p3
    }
end

function t1.AirSelector.launch(p4, p5, p6, p7, p8) -- line: 58
    -- upvalues: rt (copy), StaticScene (copy), v2 (copy)
    local v4 = rt.copy(p4.core)
    local v5 = v2.Selector.begin_launch(v4, p6, p7, rt.copy(p4.settings.query))
    local v6 = StaticScene.new(p5)
    local t2 = {}

    for _, v7 in v5 do
        table.insert(t2, StaticScene.trajectory(v6, v7, p8.matching_group_2952, v2.MESH_REJECT_MASK))
    end

    p4.core = v4
    p4.completed_launch = t2
    p4.completed_requery = nil
end

function t1.AirSelector.consume_launch(p9, p10, p11, p12, p13) -- line: 80
    -- upvalues: rt (copy), StaticScene (copy), with_world_scene (copy), WorldScene (copy), VehicleEdgeCache (copy), v2 (copy), v3 (copy)
    local completed_launch = p9.completed_launch

    if completed_launch == nil or not p9.core.sampling.pending_8492 then
        return nil
    end

    local v8 = rt.copy(p9.core)

    v2.Selector.observe_launch(v8, completed_launch)

    if v8.candidates[1] == nil or v8.predictions[1] == nil then
        error("index out of bounds: the len is 0 but the index is 0", 0)
    end

    local v9 = rt.copy(v8.candidates[1])
    local v10 = rt.copy(v8.predictions[1])
    local v11 = v3.search(v9, v10, p12)
    local v12

    if v11 ~= nil then
        local v13 = VehicleEdgeCache.build(p11)
        local v14 = VehicleEdgeCache.with_primary_edges(v13, function(p14) -- line: 99
            -- upvalues: p10 (copy), v11 (copy), with_world_scene (copy), WorldScene (copy)
            return with_world_scene(p10, p14, {}, function(p15) -- line: 100
                -- upvalues: v11 (copy), WorldScene (copy)
                return WorldScene.edge_candidates(p15, v11)
            end)
        end)
        local v15 = v3.filter_edges(v14, v9.trajectory.position)

        v12 = v3.choose(v9, v10, p12, p9.settings.query.sphere_radius, v15)

        if v12 ~= nil then
            if not (p13 == p13 and p13 ~= 1e999 and p13 ~= (-1e999)) or p13 <= 0 then
                error("BipedAir ledge requires actual positive board half-wheelbase", 0)
            end

            local v16 = v3.lines(v12, p13)

            if v16 ~= nil then
                local v17 = StaticScene.lines(StaticScene.new(p10), v16, p12.matching_group_2952)

                v3.consume_lines(v17)
            else
                v12 = nil
            end
        end
    end

    local v18 = v2.Selector.select_launch(v8, p12, v9, v12)

    p9.core = v8
    p9.completed_launch = nil

    return v18
end

function t1.AirSelector.adjust_animation(p16, p17, p18, p19) -- line: 130
    -- upvalues: v2 (copy)
    v2.Selector.adjust_animation(p16.core, p17, p18, p19, p16.settings.query.sphere_radius)
end

function t1.AirSelector.sample(p20, p21, p22, p23) -- line: 135
    -- upvalues: v2 (copy)
    v2.Selector.sample(p20.core, p21, p22, p20.settings.blend, p23)
end

function t1.AirSelector.requery(p24, p25, p26, p27, p28) -- line: 142
    -- upvalues: rt (copy), StaticScene (copy), v2 (copy)
    local v19 = rt.copy(p24.core)
    local v20 = v2.Selector.begin_requery(v19, p27, p28, p24.settings.query.sphere_radius)

    if v20 == nil then
        return false
    end

    local v21 = StaticScene.trajectory(StaticScene.new(p25), v20, p26.matching_group_2952, v2.MESH_REJECT_MASK)

    p24.core = v19
    p24.completed_requery = {
        request = rt.copy(v20),
        result = rt.copy(v21)
    }

    local completed_launch = p24.completed_launch

    if completed_launch ~= nil then
        local v22 = completed_launch[1]

        if v22 ~= nil then
            rt.assign(v22, v21)
        end
    end

    local v23 = p24.core.predictions[1]

    if v23 ~= nil then
        rt.assign(v23, {
            request = v20,
            result = v21
        })
    end

    return true
end

function t1.AirSelector.consume_requery(p29) -- line: 167
    -- upvalues: rt (copy), v2 (copy)
    local completed_requery = p29.completed_requery

    if completed_requery == nil then
        return false
    end

    local v24 = p29.core.predictions[1]
    local v25 = if v24 == nil then rt.copy(completed_requery) else rt.copy(v24)

    v2.Selector.complete_requery(p29.core, v25)
    p29.completed_requery = nil

    return true
end

function t1.AirSelector.consume(p30, p31, p32, p33, p34) -- line: 188
    -- upvalues: t1 (copy)
    p30.core.sampling.preinitialized_8494 = false

    local v26 = if p30.core.sampling.pending_8492 then t1.AirSelector.consume_launch(p30, p31, p32, p33, p34) else nil

    if p30.core.requery_pending_8499 then
        t1.AirSelector.consume_requery(p30)
    end

    p30.core.sampling.restart_allowed_8493 = true

    return v26
end

function t1.AirSelector.exit(p35) -- line: 203
    -- upvalues: v2 (copy)
    v2.Selector.exit(p35.core)
end

return t1
