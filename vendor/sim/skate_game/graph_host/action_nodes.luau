-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Attributes = import("skate_data/state_graph/attributes").Attributes
local Group = import("skate_game/input/gesture_catalog").Group
local v2 = import("skate_game/graph_host/action_conditions")
local v3 = import("skate_game/graph_host/condition_nodes")
local t1 = {
    Parameter = {}
}

function t1.Parameter.from_attributes(p2) -- line: 30
    -- upvalues: v1 (copy), Attributes (copy), t1 (copy)
    local value = Attributes.get(p2, "value")
    local defaultValue = Attributes.get(p2, "defaultValue")
    local scale = Attributes.get(p2, "scale")
    local filter1 = Attributes.text(p2, "filter1")

    if filter1 == nil then
        filter1 = Attributes.text(p2, "filter")
    end

    local t2 = {
        name = Attributes.text(p2, "name"),
        mg_intent = Attributes.text(p2, "MGIntent"),
        mg_intent_mag = Attributes.text(p2, "MGIntentMag"),
        mg_intent_angle = Attributes.text(p2, "MGIntentAngle"),
        ag_intent = Attributes.text(p2, "AGIntent"),
        text = Attributes.text(p2, "value")
    }

    t2.float_bits = if value == nil then nil else value.float_bits
    t2.boolean_byte = if value == nil then nil else value.boolean_byte

    if defaultValue ~= nil then
        buffer.writeu32(v1, 0, defaultValue.float_bits)
        t2.default_value = buffer.readf32(v1, 0)
    else
        t2.default_value = nil
    end

    if scale ~= nil then
        buffer.writeu32(v1, 0, scale.float_bits)
        t2.scale = buffer.readf32(v1, 0)
    else
        t2.scale = nil
    end

    t2.on_update = Attributes.boolean_byte(p2, "onUpdate", 1) ~= 0
    t2.filters = {
        t1.filter(filter1),
        t1.filter(Attributes.text(p2, "filter2")),
        t1.filter(Attributes.text(p2, "fakieFilter")),
        t1.filter(Attributes.text(p2, "mirrorFilter"))
    }
    t2.angle_filter = t1.filter(Attributes.text(p2, "angleFilter"))
    t2.negate_on_mirror = Attributes.boolean_byte(p2, "negateOnMirror", 1) ~= 0

    return t2
end

function t1.filter(p3) -- line: 64
    if p3 == "negate" then
        return 1
    end

    if p3 == "abs" then
        return 2
    end

    if p3 == "oneMinus" then
        return 3
    end

    if p3 == "clamp" then
        return 4
    end

    if p3 == "angleFlip" then
        return 5
    end

    if p3 == "angleRot90" then
        return 6
    end

    if p3 == "angleRotN90" then
        return 7
    end

    return 0
end

t1.ActionOperation = {}
t1.ActionInstance = {}
t1.ActionFactoryError = {}

function t1.ActionFactoryError.fmt(p4) -- line: 104
    return p4[1]
end

t1.ActionFactory = {}

function t1.ActionFactory.default() -- line: 111
    return {}
end

function t1.ActionFactory.operation(p5, p6) -- line: 116
    if p5 == "Condition" and p6 == "PhysicsRequestsDismount" then
        return {
            tag = "PhysicsRequestsDismount"
        }
    end

    if p5 == "Condition" and p6 == "IsLandingOnBoard" then
        return {
            tag = "IsLandingOnBoard"
        }
    end

    if p5 == "Behavior" and p6 == "CreateMGIntentFromAGIntent" then
        return {
            tag = "CreateMgIntent"
        }
    end

    if p5 == "Behavior" and p6 == "CreateMGTimeIntentFromAGIntent" then
        return {
            tag = "CreateMgTimeIntent"
        }
    end

    if p5 == "Behavior" and p6 == "CreateConstMGIntent" then
        return {
            tag = "CreateConstMgIntent"
        }
    end

    if p5 == "Behavior" and p6 == "BoardAdjust" then
        return {
            tag = "BoardAdjust"
        }
    end

    if p5 == "Behavior" and p6 == "JuiceHook" then
        return {
            tag = "JuiceHook"
        }
    end

    if p5 ~= "Behavior" or p6 ~= "BodyFlippingSignal" then
        return {
            tag = "Unsupported",
            kind = p5,
            name = p6
        }
    end

    return {
        tag = "BodyFlippingSignal"
    }
end

function t1.ActionFactory.create(_, p8, _, p10) -- line: 140
    -- upvalues: Attributes (copy), Group (copy), v2 (copy), v3 (copy), t1 (copy)
    local name = Attributes.text(p10, "name")

    if name == nil then
        error("operation has no name attribute", 0)
    end

    local v4

    if p8 == "Condition" then
        local v5 = v2.ActionCondition.parse(p10)

        if v5 ~= nil then
            v4 = {
                tag = "ExtraCondition",
                v5
            }
        else
            local v6 = v3.parse(p10)

            if v6 ~= nil then
                v4 = {
                    tag = "Condition",
                    v6
                }
            else
                v4 = t1.ActionFactory.operation(p8, name)
            end
        end
    elseif p8 == "Behavior" and name == "CreateTrickIntentFromGesture" then
        local group = Attributes.text(p10, "group")

        if group == nil then
            group = "Square"
        end

        v4 = {
            tag = "CreateTrickIntentFromGesture",
            group = Group.parse(group),
            override_name = Attributes.text(p10, "override")
        }
    elseif p8 == "Behavior" and name == "PrintText2D" then
        local text = Attributes.text(p10, "text")

        if text == nil then
            text = ""
        end

        v4 = {
            tag = "PrintText",
            text
        }
    else
        v4 = t1.ActionFactory.operation(p8, name)
    end

    return {
        operation = v4,
        config = t1.Parameter.from_attributes(p10),
        parameters = {}
    }
end

function t1.ActionFactory.add_parameter(_, p12, p13) -- line: 187
    -- upvalues: t1 (copy)
    table.insert(p12.parameters, t1.Parameter.from_attributes(p13))
end

t1.UnsupportedOperation = {}

function t1.UnsupportedOperation.eq(p14, p15) -- line: 195
    if p14.kind == p15.kind then
        return p14.name == p15.name
    end

    return false
end

function t1.ActionInstance.unsupported(p16) -- line: 200
    local operation = p16.operation

    return if operation.tag == "Unsupported" then {
        kind = operation.kind,
        name = operation.name
    } else nil
end

t1.ActionInstances = {}

function t1.ActionInstances.new(p17) -- line: 212
    return {
        operations = p17
    }
end

function t1.ActionInstances.get(p18, p19) -- line: 217
    return p18.operations[p19 + 1]
end

return t1
