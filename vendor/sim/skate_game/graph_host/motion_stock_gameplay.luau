-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Attributes = import("skate_data/state_graph/attributes").Attributes
local encode = import("skate_core/animation/skeleton_input/name").encode
local t1 = {}

local function debug_str(p1) -- line: 19
    return "\"" .. string.gsub(p1, "[\\\"\n\r\t]", function(p2) -- line: 20
        if p2 == "\\" then
            return "\\\\"
        end

        if p2 == "\"" then
            return "\\\""
        end

        if p2 == "\n" then
            return "\\n"
        end

        if p2 == "\r" then
            return "\\r"
        end

        return "\\t"
    end) .. "\""
end

t1.GrabType = {}

function t1.GrabType.parse(p3) -- line: 39
    if p3 == "FS" then
        return "Fs"
    end

    if p3 == "BS" then
        return "Bs"
    end

    if p3 == "Nose" then
        return "Nose"
    end

    if p3 == "Tail" then
        return "Tail"
    end

    error("SetGrabType has unknown grab type " .. "\"" .. string.gsub(p3, "[\\\"\n\r\t]", function(p4) -- line: 20
        if p4 == "\\" then
            return "\\\\"
        end

        if p4 == "\"" then
            return "\\\""
        end

        if p4 == "\n" then
            return "\\n"
        end

        if p4 == "\r" then
            return "\\r"
        end

        return "\\t"
    end) .. "\"", 0)
end

function t1.GrabType.as_value(p5) -- line: 52
    if p5 == "Fs" then
        return 1
    end

    if p5 == "Bs" then
        return 2
    end

    if p5 == "Nose" then
        return 3
    end

    return 4
end

t1.MovingObjectRegistry = {}

function t1.MovingObjectRegistry.default() -- line: 69
    return {
        active = nil,
        objects = {}
    }
end

function t1.MovingObjectRegistry.register(p6, p7) -- line: 75
    -- upvalues: t1 (copy)
    local v1 = t1.normalize_path(p7)
    local v2 = t1.djb2(v1)

    p6.objects[v2] = v1

    return v2
end

function t1.MovingObjectRegistry.begin(p8, p9) -- line: 83
    -- upvalues: t1 (copy)
    local v3 = t1.djb2(t1.normalize_path(p9))

    if p8.objects[v3] == nil then
        error("MovingObject resource is not registered: " .. p9, 0)
    end

    p8.active = v3
end

function t1.MovingObjectRegistry.update(p10, p11) -- line: 92
    -- upvalues: t1 (copy)
    local v4 = t1.djb2(t1.normalize_path(p11))

    if p10.objects[v4] == nil then
        error("MovingObject update references unknown resource: " .. p11, 0)
    end

    return p10.active == v4
end

t1.MovingObjectRegistry["end"] = function(p12) -- line: 100
    p12.active = nil
end

function t1.MovingObjectRegistry.active(p13) -- line: 104
    return p13.active ~= nil
end

function t1.normalize_path(p14) -- line: 109
    return (string.gsub(p14, "/", "\\"))
end

function t1.select_grab_score(p15, p16, p17, p18) -- line: 116
    -- upvalues: rt (copy)
    local v5 = p16[1]
    local v6 = p16[2]
    local v7 = p16[3]
    local v8 = p16[4]

    if not (math.sqrt(p17 * p17 + p18 * p18) <= 0.5) then
        local v10 = rt.rem_euclid(math.atan2(p18, p17), 6.283185307179586)
        local t2 = {
            v5,
            v6,
            v7,
            v8
        }
        local t3 = {
            if v8 == nil then 359 else 44,
            if v5 == nil then 89 else 44,
            if v6 == nil then 179 else 224,
            if v7 == nil then 269 else 314
        }
        local t4 = {
            if v6 == nil then 181 else 134,
            if v7 == nil then 271 else 226,
            if v8 == nil then 1 else 316,
            if v5 == nil then 91 else 46
        }

        for i = 1, 4 do
            local v19 = t2[i]
            local v20 = t3[i] * 0.017453292519943295
            local v21 = t4[i] * 0.017453292519943295

            if (if v21 < v20 then v20 <= v10 or v10 <= v21 else v20 <= v10 and v10 <= v21) and v19 ~= nil then
                return v19
            end
        end
    end

    return p15
end

function t1.djb2(p19) -- line: 154
    -- upvalues: rt (copy)
    local n1 = 5381

    for i = 1, #p19 do
        n1 = rt.wrapping_add_u32(rt.wrapping_mul_u32(n1, 33), string.byte(p19, i))
    end

    return n1
end

t1.Operation = {}

function t1.Operation.recognizes(p20) -- line: 173
    if p20 == "MatchAirTime"
        or p20 == "UpdateStandingOnCar"
        or p20 == "InitMovingObjects"
        or p20 == "MovingObject"
        or p20 == "CreateGrindAttributes"
        or p20 == "ControlGrindCrouch"
        or p20 == "GrindControlFade"
        or p20 == "SetGrabType"
        or p20 == "JumpInto"
        or p20 == "ScoringHandPlants"
        or p20 == "SetHandPlantAnticLength"
        or p20 == "ScoringGrabs"
        or p20 == "AirDismounting"
        or p20 == "TweakProject"
        or p20 == "FootPlantAbsorb"
        or p20 == "FingerFlipOut"
        or p20 == "EnterSkitchingBehaviour"
        or p20 == "SkitchingBehaviour"
        or p20 == "SkitchShimmyingBehaviour"
        or p20 == "SetManualAngle"
        or p20 == "HippyJumpAntic" then
        return true
    end

    return p20 == "LandOnBoard"
end

function t1.Operation.parse(p21) -- line: 199
    -- upvalues: Attributes (copy), encode (copy), t1 (copy)
    local name = Attributes.text(p21, "name")

    if name == nil then
        name = ""
    end

    if name == "MatchAirTime" then
        return {
            tag = "MatchAirTime"
        }
    end

    if name == "UpdateStandingOnCar" then
        return {
            tag = "UpdateStandingOnCar"
        }
    end

    if name == "InitMovingObjects" then
        return {
            tag = "InitMovingObjects",
            path = t1.authored_path(p21)
        }
    end

    if name == "MovingObject" then
        return {
            tag = "MovingObject",
            path = t1.authored_path(p21)
        }
    end

    if name == "CreateGrindAttributes" then
        return {
            tag = "CreateGrindAttributes"
        }
    end

    if name == "ControlGrindCrouch" then
        return {
            tag = "ControlGrindCrouch"
        }
    end

    if name == "GrindControlFade" then
        return {
            tag = "GrindControlFade"
        }
    end

    if name == "SetGrabType" then
        local grab = Attributes.text(p21, "grab")

        if grab == nil then
            grab = ""
        end

        return {
            tag = "SetGrabType",
            grab = grab
        }
    end

    if name == "JumpInto" then
        local attribute = Attributes.text(p21, "attribute")

        if attribute == nil then
            attribute = Attributes.text(p21, "attr")
        end

        if attribute == nil then
            attribute = "JumpInto"
        end

        return {
            tag = "JumpInto",
            attribute = encode(attribute)
        }
    end

    if name == "ScoringHandPlants" then
        return {
            tag = "ScoringHandPlants"
        }
    end

    if name == "SetHandPlantAnticLength" then
        return {
            tag = "SetHandPlantAnticLength"
        }
    end

    if name == "ScoringGrabs" then
        local grabName = t1.required_text(p21, "grabName")
        local up = Attributes.text(p21, "up")
        local left = Attributes.text(p21, "left")
        local down = Attributes.text(p21, "down")
        local right = Attributes.text(p21, "right")
        local intentX = Attributes.text(p21, "intentX")

        if intentX == nil then
            intentX = Attributes.text(p21, "angle")
        end

        if intentX == nil then
            intentX = ""
        end

        local intentY = Attributes.text(p21, "intentY")

        if intentY == nil then
            intentY = Attributes.text(p21, "magnitude")
        end

        if intentY == nil then
            intentY = ""
        end

        return {
            tag = "ScoringGrabs",
            grab_name = grabName,
            up = up,
            left = left,
            down = down,
            right = right,
            intent_x = intentX,
            intent_y = intentY,
            invert_y = Attributes.boolean_byte(p21, "invertY", 0) ~= 0,
            polar = Attributes.text(p21, "intentX") == nil
        }
    end

    if name == "AirDismounting" then
        return {
            tag = "AirDismounting"
        }
    end

    if name == "TweakProject" then
        return {
            tag = "TweakProject",
            intent_x = "TweakX",
            intent_y = "TweakY",
            attribute_x = encode("tweak_x"),
            attribute_y = encode("tweak_y")
        }
    end

    if name == "FootPlantAbsorb" then
        return {
            tag = "FootPlantAbsorb"
        }
    end

    if name == "FingerFlipOut" then
        return {
            tag = "FingerFlipOut",
            grab_intent = t1.required_text(p21, "grabintent")
        }
    end

    if name == "EnterSkitchingBehaviour" then
        return {
            tag = "EnterSkitchingBehaviour"
        }
    end

    if name == "SkitchingBehaviour" then
        return {
            tag = "SkitchingBehaviour"
        }
    end

    if name == "SkitchShimmyingBehaviour" then
        return {
            tag = "SkitchShimmyingBehaviour"
        }
    end

    if name == "SetManualAngle" then
        return {
            tag = "SetManualAngle",
            attribute = encode("manual_angle")
        }
    end

    if name == "HippyJumpAntic" then
        return {
            tag = "HippyJumpAntic"
        }
    end

    if name == "LandOnBoard" then
        return {
            tag = "LandOnBoard"
        }
    end

    error("internal error: entered unreachable code: unrecognized stock gameplay operation", 0)
end

function t1.authored_path(p22) -- line: 309
    -- upvalues: Attributes (copy)
    local path = Attributes.text(p22, "path")

    if path == nil then
        path = Attributes.text(p22, "object")
    end

    if path == nil then
        path = Attributes.text(p22, "nameToFind")
    end

    if path == nil then
        path = ""
    end

    return path
end

function t1.required_text(p23, p24) -- line: 324
    -- upvalues: Attributes (copy)
    local v23 = Attributes.text(p23, p24)

    if v23 == nil then
        v23 = ""
    end

    return v23
end

return t1
