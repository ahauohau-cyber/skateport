-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_data/state_graph/attributes")
local v10 = import("skate_game/graph_host/motion_channels")
local v11 = import("skate_core/input/set_turning")
local t1 = {}
local Attributes = v9.Attributes
local MotionChannels = v10.MotionChannels
local SlideLatch = v11.SlideLatch

local function debug_str(p3) -- line: 40
    local v12 = string.gsub(p3, "[\\\"]", "\\%0")
    local v13 = string.gsub(v12, "\n", "\\n")
    local v14 = string.gsub(v13, "\r", "\\r")
    local v15 = string.gsub(v14, "\t", "\\t")

    return "\"" .. string.gsub(v15, "%z", "\\0") .. "\""
end

local function debug_opt_str(p4) -- line: 50
    -- upvalues: debug_str (copy)
    if p4 == nil then
        return "None"
    end

    return "Some(" .. debug_str(p4) .. ")"
end

t1.GameplayConditions = {}
t1.GameplayCondition = {}

function t1.GameplayCondition.eq(p5, p6) -- line: 97
    if p5.tag ~= p6.tag then
        return false
    end

    if p5.tag == "CanEnterSlide" then
        return p5.right == p6.right
    end

    if p5.tag == "HandPlanting" then
        if p5.state == p6.state then
            return p5.direction == p6.direction
        end

        return false
    end

    if p5.tag == "PlayHandplant" then
        return p5.phase == p6.phase
    end

    return true
end

function t1.GameplayCondition.recognizes(p7) -- line: 111
    return p7 == "IsRetrievingSkateboard"
        or p7 == "IsDroppingSkateboard"
        or p7 == "IsInBipedAir"
        or p7 == "IsHippyHurdling"
        or p7 == "PhysicsWantsRunout"
        or p7 == "IsPhysicsWiping"
        or p7 == "IsBodyFlipping"
        or p7 == "PhysicsWantsWipeOut"
        or p7 == "IsBumped"
        or p7 == "CanEnterSlide"
        or p7 == "IsGrabbingObject"
        or p7 == "IsDark"
        or p7 == "IsUnderflipRequested"
        or p7 == "IsDarkCatchRequested"
        or p7 == "OkToDoTrickOnStairs"
        or p7 == "IsHandPlanting"
        or p7 == "IsFootPlanting"
        or p7 == "ShouldPrepareOneFootAirForFootplant"
        or p7 == "HasNewHandPlantPos"
        or p7 == "ShouldPlayHandPlantAnim"
        or p7 == "IsEnteringSkitch"
        or p7 == "IsSkitching"
        or p7 == "IsMovingObject"
end

function t1.GameplayCondition.parse(p8) -- line: 138
    -- upvalues: Attributes (copy), debug_str (copy)
    local name = Attributes.text(p8, "name")

    if name == nil then
        name = ""
    end

    if name == "IsRetrievingSkateboard" then
        return {
            tag = "RetrievingBoard"
        }
    end

    if name == "IsDroppingSkateboard" then
        return {
            tag = "DroppingBoard"
        }
    end

    if name == "IsInBipedAir" then
        return {
            tag = "InBipedAir"
        }
    end

    if name == "IsHippyHurdling" then
        return {
            tag = "HippyHurdling"
        }
    end

    if name == "PhysicsWantsRunout" then
        return {
            tag = "WantsRunout"
        }
    end

    if name == "IsPhysicsWiping" then
        return {
            tag = "PhysicsWiping"
        }
    end

    if name == "IsBodyFlipping" then
        return {
            tag = "BodyFlipping"
        }
    end

    if name == "PhysicsWantsWipeOut" then
        return {
            tag = "WantsWipeout"
        }
    end

    if name == "IsBumped" then
        return {
            tag = "Bumped"
        }
    end

    if name == "CanEnterSlide" then
        return {
            tag = "CanEnterSlide",
            right = Attributes.boolean_byte(p8, "right", 1) ~= 0
        }
    end

    if name == "IsGrabbingObject" then
        return {
            tag = "GrabbingObject"
        }
    end

    if name == "IsDark" then
        return {
            tag = "Dark"
        }
    end

    if name == "IsUnderflipRequested" then
        return {
            tag = "UnderflipRequested"
        }
    end

    if name == "IsDarkCatchRequested" then
        return {
            tag = "DarkCatchRequested"
        }
    end

    if name == "OkToDoTrickOnStairs" then
        return {
            tag = "OkToDoTrickOnStairs"
        }
    end

    if name == "IsEnteringSkitch" then
        return {
            tag = "EnteringSkitch"
        }
    end

    if name == "IsSkitching" then
        return {
            tag = "Skitching"
        }
    end

    if name == "IsFootPlanting" then
        return {
            tag = "FootPlanting"
        }
    end

    if name == "ShouldPrepareOneFootAirForFootplant" then
        return {
            tag = "PrepareFootplant"
        }
    end

    if name == "HasNewHandPlantPos" then
        return {
            tag = "NewHandplantPosition"
        }
    end

    if name == "ShouldPlayHandPlantAnim" then
        local anim = Attributes.text(p8, "anim")
        local v16

        if anim == "antic" then
            v16 = 2
        elseif anim == "into" then
            v16 = 1
        elseif anim == "out" then
            v16 = 0
        else
            error(("Unauthored handplant animation phase %*"):format(if anim == nil then "None" else "Some(" .. debug_str(anim) .. ")"), 0)
        end

        return {
            tag = "PlayHandplant",
            phase = v16
        }
    end

    if name == "IsMovingObject" then
        return {
            tag = "IsMovingObject"
        }
    end

    if name == "IsHandPlanting" then
        local state = Attributes.text(p8, "state")

        if state == nil then
            state = ""
        end

        local v17

        if state == "air" then
            v17 = 0
        elseif state == "ground" then
            v17 = 1
        else
            error(("IsHandPlanting has unauthored state %*"):format((debug_str(state))), 0)
        end

        local dir = Attributes.text(p8, "dir")

        if dir == nil then
            dir = ""
        end

        return {
            tag = "HandPlanting",
            state = v17,
            direction = if dir == "FS" then 1 elseif dir == "BS" then 0 else 2
        }
    end

    error(("Unknown gameplay condition %*"):format(name), 0)
end

function t1.GameplayCondition.evaluate_physical(p9, p10) -- line: 236
    -- upvalues: v1 (copy)
    local tag = p9.tag

    if tag == "OkToDoTrickOnStairs" then
        return not p10.tricks_blocked_on_stairs
    end

    if tag == "RetrievingBoard" then
        return p10.retrieving_board
    end

    if tag == "InBipedAir" then
        return p10.in_biped_air
    end

    if tag == "HippyHurdling" then
        return p10.hippy_hurdling
    end

    if tag == "WantsRunout" then
        return p10.wants_runout
    end

    if tag == "PhysicsWiping" then
        return p10.physics_wiping
    end

    if tag == "BodyFlipping" then
        return p10.body_flipping
    end

    if tag == "WantsWipeout" then
        return p10.wants_wipeout
    end

    if tag == "Bumped" then
        return p10.bumped
    end

    if tag == "GrabbingObject" then
        return p10.grabbing_object
    end

    if tag == "Skitching" then
        return p10.state == 104
    end

    if tag == "IsMovingObject" then
        return p10.moving_object
    end

    if tag == "EnteringSkitch" then
        return not (p10.time_to_skitch < 0) and p10.time_to_skitch <= p10.skitch_transition_time
    end

    if tag == "HandPlanting" then
        if not (if p9.state == 0 then p10.state == 600 else bit32.band(p10.handplant_flags, 2147483648) ~= 0) then
            return false
        end

        local direction = p9.direction

        if direction == 2 then
            return true
        end

        if direction == 1 then
            return bit32.band(p10.handplant_flags, 536870912) ~= 0
        end

        if direction ~= 0 then
            return false
        end

        return bit32.band(p10.handplant_flags, 536870912) == 0
    end

    if tag == "FootPlanting" then
        return p10.footplant_active and p10.footplant_duration >= 0
    end

    if tag == "PrepareFootplant" then
        if not (p10.footplant_contact_time >= 0.1) then
            return false
        end

        return p10.footplant_contact_time <= 0.5
    end

    if tag == "NewHandplantPosition" then
        return bit32.band(p10.handplant_flags, 1073741824) ~= 0
    end

    if tag ~= "PlayHandplant" then
        return nil
    end

    local v19 = p10.handplant_thresholds[p9.phase + 1]

    if v19 == nil then
        error("index out of bounds", 0)
    end

    local v20 = p10.handplant_time - 0.01666666753590107
    local v21

    if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
        local v22 = math.abs(v20) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = (if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23) * 1.401298464324817E-45

        if v20 < 0 then
            v21 = -v21
        end
    else
        buffer.writef32(v1, 0, v20)
        v21 = buffer.readf32(v1, 0)
    end

    if p9.phase == 0 then
        v19 = -v19
    end

    return v21 < v19
end

function t1.GameplayCondition.evaluate(p11, p12) -- line: 311
    -- upvalues: t1 (copy), MotionChannels (copy), SlideLatch (copy)
    local gameplay_conditions = p12.gameplay_conditions

    if gameplay_conditions == nil then
        error("MotionGraph requires the actual physical condition publication", 0)
    end

    local v25 = t1.GameplayCondition.evaluate_physical(p11, gameplay_conditions)

    if v25 ~= nil then
        return v25
    end

    local tag = p11.tag

    if tag == "DroppingBoard" then
        return gameplay_conditions.dropping_board or MotionChannels.has(p12.animation.channels, "RetrieveBoard")
    end

    if tag == "Dark" then
        return p12.riding.dark
    end

    if tag == "UnderflipRequested" then
        return p12.trick_requests.underflip
    end

    if tag == "DarkCatchRequested" then
        return p12.trick_requests.dark_catch
    end

    if tag == "CanEnterSlide" then
        if gameplay_conditions.state == 102 then
            return false
        end

        local skater_animation_flags = p12.animation.skater_animation_flags

        if skater_animation_flags == nil then
            error("CanEnterSlide requires actual SkaterAnim stance flags", 0)
        end

        local v26 = bit32.band(skater_animation_flags, 536870912) ~= 0

        if p11.right == v26 then
            return SlideLatch.start(p12.slide_latch, false)
        end

        return SlideLatch.start(p12.slide_latch, true)
    end

    error("internal error: entered unreachable code: Physical condition handled above", 0)
end

return t1
