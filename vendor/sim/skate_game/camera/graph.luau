-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/camera")
local Controller = import("skate_core/graph/controller").Controller
local StateGraph = import("skate_data/state_graph").StateGraph
local Attributes = import("skate_data/state_graph/attributes").Attributes
local Binding = import("skate_data/state_graph/binding").Binding
local v9 = import("skate_game/graph_runtime")
local v10 = import("skate_game/camera/graph_conditions")
local StockShots = import("skate_game/camera/shot_data").StockShots
local CameraMan, ShotManager, SlowMotionController = v8.CameraMan, v8.ShotManager, v8.SlowMotionController
local CompiledGraph = v9.CompiledGraph
local Condition, shot_names = v10.Condition, v10.shot_names
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {
    CameraGraph = {},
    Behavior = {},
    CameraHost = {}
}
local CameraHost = t1.CameraHost

local function stringify_error(p4, ...) -- line: 91
    -- upvalues: v9 (copy)
    local ok, result = pcall(p4, ...)

    if not ok then
        if type(result) == "table" and result.tag ~= nil and v9.GraphCompileError ~= nil then
            error(v9.GraphCompileError.fmt(result), 0)
        end

        error(tostring(result), 0)
    end

    return result
end

function t1.CameraGraph.load(p5, p6) -- line: 106
    -- upvalues: v1 (copy), Controller (copy), StateGraph (copy), Attributes (copy), Binding (copy), CompiledGraph (copy), Condition (copy), shot_names (copy), stringify_error (copy)
    local v11 = stringify_error(StateGraph.load, p5)
    local v12 = stringify_error(Binding.from_graph, v11)
    local v13 = stringify_error(CompiledGraph.from_binding, v12)
    local v14 = table.create(#v13.operations.conditions)

    for _, v15 in v13.operations.conditions do
        local v16 = v11.elements[v12.operations[v15 + 1].element + 1]

        table.insert(v14, Condition.parse(Attributes.new(v16.attributes)))
    end

    local v17 = table.create(#v13.operations.behaviors)

    for _, v18 in v13.operations.behaviors do
        local v19 = v12.operations[v18 + 1]
        local v20 = v11.elements[v19.element + 1]
        local v21 = Attributes.new(v20.attributes)
        local name = v19.name
        local t2

        if name == "CameraChooseShot" then
            local v22 = shot_names(v21)

            if #v22 == 0 then
                error("CameraChooseShot has no named shot", 0)
            end

            t2 = {
                tag = "Choose",
                names = v22
            }

            local float_bits = Attributes.float_bits

            buffer.writef32(v1, 0, -1)
            buffer.writeu32(v1, 0, (float_bits(v21, "transitionIn", (buffer.readu32(v1, 0)))))
            t2.incoming = buffer.readf32(v1, 0)

            local float_bits2 = Attributes.float_bits

            buffer.writef32(v1, 0, -1)
            buffer.writeu32(v1, 0, (float_bits2(v21, "transitionOut", (buffer.readu32(v1, 0)))))
            t2.outgoing = buffer.readf32(v1, 0)
        elseif name == "PrintText2D" then
            local text = Attributes.text(v21, "text")

            if text == nil then
                text = ""
            end

            t2 = {
                tag = "Print",
                text
            }
        elseif name == "SlowMotionController" then
            t2 = {
                tag = "SlowMotion"
            }
        else
            error(("Unimplemented camera behavior %*"):format(name), 0)
        end

        table.insert(v17, t2)
    end

    if #v13.operations.hooks ~= 0 then
        error("Camera graph has unimplemented transition hooks", 0)
    end

    return {
        program = v13,
        controller = Controller.new(#v12.states),
        conditions = v14,
        behaviors = v17,
        slow_motion = table.create(#v17),
        slow_motion_settings = p6
    }
end

function t1.CameraGraph.update_reference(p7, p8, p9, p10, p11, p12, p13) -- line: 165
    -- upvalues: rt (copy), Controller (copy), CameraHost (copy)
    local t3 = {
        error = nil,
        manager = p9,
        subject = p10,
        physical = p11,
        world = p12,
        database = p13,
        conditions = p7.conditions,
        behaviors = p7.behaviors,
        slow_motion = p7.slow_motion,
        slow_motion_settings = rt.copy(p7.slow_motion_settings),
        rates = {}
    }
    local t4 = {
        condition_activation = function(_, p15, p16) -- condition_activation | line: 181
            -- upvalues: t3 (copy), CameraHost (copy)
            return CameraHost.condition_activation(t3, p15, p16)
        end,
        context = function(_) -- context | line: 184
            -- upvalues: t3 (copy), CameraHost (copy)
            return CameraHost.context(t3)
        end,
        allocate = function(_, p19, p20) -- allocate | line: 187
            -- upvalues: t3 (copy), CameraHost (copy)
            return CameraHost.allocate(t3, p19, p20)
        end,
        begin = function(_, p22, p23, p24) -- begin | line: 190
            -- upvalues: t3 (copy), CameraHost (copy)
            CameraHost.begin(t3, p22, p23, p24)
        end,
        update = function(_, p26, p27, p28) -- update | line: 193
            -- upvalues: t3 (copy), CameraHost (copy)
            CameraHost.update(t3, p26, p27, p28)
        end,
        ["end"] = function(_, p30, p31, p32) -- line: 196
            -- upvalues: t3 (copy), CameraHost (copy)
            CameraHost["end"](t3, p30, p31, p32)
        end,
        hook = function(_, p34, p35) -- hook | line: 199
            -- upvalues: t3 (copy), CameraHost (copy)
            CameraHost.hook(t3, p34, p35)
        end,
        release = function(_, p37) -- release | line: 202
            -- upvalues: t3 (copy), CameraHost (copy)
            CameraHost.release(t3, p37)
        end
    }

    Controller.update(p7.controller, p7.program.program, p8, t4)

    if t3.error ~= nil then
        error(t3.error, 0)
    end

    return t3.rates
end

function t1.CameraHost.condition_activation(p38, p39, _) -- line: 215
    -- upvalues: Condition (copy)
    if Condition.evaluate(p38.conditions[p39 + 1], p38.manager, p38.subject, p38.physical, p38.world) then
        return 1
    end

    return 0
end

function t1.CameraHost.context(_) -- line: 224
    return { 0, 0, 0, 0, 0, 0 }
end

function t1.CameraHost.allocate(_, _, _) -- line: 229
    return 0
end

function t1.CameraHost.begin(p45, p46, _, _) -- line: 234
    -- upvalues: StockShots (copy), CameraMan (copy), ShotManager (copy), SlowMotionController (copy)
    local v25 = p45.behaviors[p46 + 1]

    if v25.tag == "Choose" then
        local v26 = v25.names[1]

        if v26 ~= nil then
            local database = p45.database
            local set_shot = CameraMan.set_shot
            local manager, subject = p45.manager, p45.subject
            local t5 = {
                load = function(_, p50) -- load | line: 245
                    -- upvalues: database (copy), StockShots (copy)
                    return StockShots.load(database, p50)
                end
            }
            local ok, result = pcall(set_shot, manager, v26, false, subject, t5)

            if ok then
                ShotManager.apply_graph_transition(p45.manager.shots, v25.incoming, v25.outgoing)
            else
                p45.error = result
            end
        else
            p45.error = "CameraChooseShot has no named shot"
        end
    elseif v25.tag ~= "Print" then
        local v27, v28 = SlowMotionController.begin(p45.slow_motion_settings)

        p45.slow_motion[p46 + 1] = v27
        table.insert(p45.rates, v28)
    end
end

function t1.CameraHost.update(p51, p52, _, p54) -- line: 265
    -- upvalues: SlowMotionController (copy)
    local v29 = p51.slow_motion[p52 + 1]

    if v29 == nil then
        return
    end

    table.insert(p51.rates, SlowMotionController.update(v29, p54.dt, p51.physical.slow_motion_air_duration, p51.slow_motion_settings))
end

t1.CameraHost["end"] = function(p55, p56, _, _) -- line: 281
    -- upvalues: SlowMotionController (copy)
    local v30 = p55.slow_motion[p56 + 1]

    p55.slow_motion[p56 + 1] = nil

    if v30 == nil then
        return
    end

    table.insert(p55.rates, SlowMotionController["end"]())
end

function t1.CameraHost.hook(_, _, _) -- line: 291
    error("camera hooks rejected during load", 0)
end

function t1.CameraHost.release(_, _) -- line: 296
end

local t6 = {
    manager = nil,
    subject = nil,
    physical = nil,
    world = nil,
    database = nil,
    conditions = nil,
    behaviors = nil,
    error = nil,
    slow_motion = nil,
    slow_motion_settings = nil,
    rates = {}
}
local t7 = {
    0, 0, 0, 0, 0, 0
}
local v32 = table.freeze({
    condition_activation = function(_, p65, p66) -- condition_activation | line: 324
        -- upvalues: CameraHost (copy), t6 (copy)
        return CameraHost.condition_activation(t6, p65, p66)
    end,
    context = function(_) -- context | line: 330
        -- upvalues: t7 (copy)
        t7[1] = 0
        t7[2] = 0
        t7[3] = 0
        t7[4] = 0
        t7[5] = 0
        t7[6] = 0

        return t7
    end,
    allocate = function(_, p69, p70) -- allocate | line: 335
        -- upvalues: CameraHost (copy), t6 (copy)
        return CameraHost.allocate(t6, p69, p70)
    end,
    begin = function(_, p72, p73, p74) -- begin | line: 338
        -- upvalues: CameraHost (copy), t6 (copy)
        CameraHost.begin(t6, p72, p73, p74)
    end,
    update = function(_, p76, p77, p78) -- update | line: 341
        -- upvalues: CameraHost (copy), t6 (copy)
        CameraHost.update(t6, p76, p77, p78)
    end,
    ["end"] = function(_, p80, p81, p82) -- line: 344
        -- upvalues: CameraHost (copy), t6 (copy)
        CameraHost["end"](t6, p80, p81, p82)
    end,
    hook = function(_, p84, p85) -- hook | line: 347
        -- upvalues: CameraHost (copy), t6 (copy)
        CameraHost.hook(t6, p84, p85)
    end,
    release = function(_, p87) -- release | line: 350
        -- upvalues: CameraHost (copy), t6 (copy)
        CameraHost.release(t6, p87)
    end
})

local function unbind_host() -- line: 355
    -- upvalues: t6 (copy)
    t6.manager = nil
    t6.subject = nil
    t6.physical = nil
    t6.world = nil
    t6.database = nil
    t6.conditions = nil
    t6.behaviors = nil
    t6.slow_motion = nil
    t6.slow_motion_settings = nil
end

function t1.CameraGraph.update_transient(p88, p89, p90, p91, p92, p93, p94) -- line: 361
    -- upvalues: Controller (copy), t6 (copy), v32 (copy)
    t6.manager = p90
    t6.subject = p91
    t6.physical = p92
    t6.world = p93
    t6.database = p94
    t6.conditions = p88.conditions
    t6.behaviors = p88.behaviors
    t6.error = nil
    t6.slow_motion = p88.slow_motion
    t6.slow_motion_settings = p88.slow_motion_settings

    local rates = t6.rates

    if #rates > 0 then
        table.clear(rates)
    end

    Controller.update(p88.controller, p88.program.program, p89, v32)

    local _error = t6.error

    t6.error = nil
    t6.manager = nil
    t6.subject = nil
    t6.physical = nil
    t6.world = nil
    t6.database = nil
    t6.conditions = nil
    t6.behaviors = nil
    t6.slow_motion = nil
    t6.slow_motion_settings = nil

    if _error ~= nil then
        error(_error, 0)
    end

    return rates
end

function t1.CameraGraph.update(p95, p96, p97, p98, p99, p100, p101) -- line: 387
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.CameraGraph.update_reference(p95, p96, p97, p98, p99, p100, p101)
    end

    return table.clone(t1.CameraGraph.update_transient(p95, p96, p97, p98, p99, p100, p101))
end

return t1
