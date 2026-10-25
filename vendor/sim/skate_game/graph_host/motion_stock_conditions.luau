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
local NumericCondition = import("skate_core/graph/conditions").NumericCondition
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v9 = import("skate_game/graph_host/condition_nodes")
local MotionAnimation = import("skate_game/graph_host/motion_animation").MotionAnimation
local t1 = {}

t1.Condition = {}

function t1.Condition.eq(p3, p4) -- line: 45
    if p3.tag ~= p4.tag then
        return false
    end

    if p3.tag == "DistToEdge" then
        local v11 = p3[1]
        local v12 = p4[1]

        if v11.comparison == v12.comparison and v11.threshold == v12.threshold then
            return v11.absolute == v12.absolute
        end

        return false
    end

    if p3.tag ~= "EnoughDistToObstacle" then
        return true
    end

    if p3.database == p4.database then
        return p3.animation == p4.animation
    end

    return false
end

function t1.Condition.recognizes(p5) -- line: 58
    if p5 == "CanLandOnBoard"
        or p5 == "DistToEdge"
        or p5 == "IsDeckFree"
        or p5 == "IsBipedCommittedToMotion"
        or p5 == "EnoughDistToObstacle"
        or p5 == "CanBipedLand"
        or p5 == "IsCrouchedEnoughForBlendToGrabCycle"
        or p5 == "TrucksOrDeckInContact"
        or p5 == "PhysicsWantsManualExit" then
        return true
    end

    return p5 == "ApexReached"
end

function t1.Condition.parse(p6) -- line: 72
    -- upvalues: Attributes (copy), v9 (copy)
    local name = Attributes.text(p6, "name")

    if name == nil then
        name = ""
    end

    if name == "CanLandOnBoard" then
        return {
            tag = "CanLandOnBoard"
        }
    end

    if name == "DistToEdge" then
        return {
            tag = "DistToEdge",
            (v9.numeric(p6))
        }
    end

    if name == "IsDeckFree" then
        return {
            tag = "IsDeckFree"
        }
    end

    if name == "IsBipedCommittedToMotion" then
        return {
            tag = "IsBipedCommittedToMotion"
        }
    end

    if name == "EnoughDistToObstacle" then
        local db = Attributes.text(p6, "db")

        if db == nil then
            db = ""
        end

        local anim = Attributes.text(p6, "anim")

        if anim == nil then
            anim = ""
        end

        return {
            tag = "EnoughDistToObstacle",
            database = db,
            animation = anim
        }
    end

    if name == "CanBipedLand" then
        return {
            tag = "CanBipedLand"
        }
    end

    if name == "IsCrouchedEnoughForBlendToGrabCycle" then
        return {
            tag = "IsCrouchedEnoughForBlendToGrabCycle"
        }
    end

    if name == "TrucksOrDeckInContact" then
        return {
            tag = "TrucksOrDeckInContact"
        }
    end

    if name == "PhysicsWantsManualExit" then
        return {
            tag = "PhysicsWantsManualExit"
        }
    end

    if name == "ApexReached" then
        return {
            tag = "ApexReached"
        }
    end

    error("internal error: entered unreachable code", 0)
end

function t1.Condition.evaluate(p7, p8) -- line: 110
    -- upvalues: v1 (copy), NumericCondition (copy), t1 (copy), MotionAnimation (copy)
    local gameplay_conditions = p8.gameplay_conditions

    if gameplay_conditions == nil then
        error("stock gameplay condition requires physical publication", 0)
    end

    local tag = p7.tag

    if tag == "CanLandOnBoard" then
        return gameplay_conditions.can_land_on_board
    end

    if tag == "CanBipedLand" then
        local v13 = gameplay_conditions.offboard_landing_normal[2]
        local v14

        if v13 ~= 0 and v13 > -1.1754943508222875E-38 and v13 < 1.1754943508222875E-38 then
            local v15 = math.abs(v13) * 7.1362384635298E+44
            local v16 = math.floor(v15)
            local v17 = v15 - v16

            v14 = (if v17 > 0.5 or v17 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16) * 1.401298464324817E-45

            if v13 < 0 then
                v14 = -v14
            end
        else
            buffer.writef32(v1, 0, v13)
            v14 = buffer.readf32(v1, 0)
        end

        buffer.writef32(v1, 0, 0.85)

        return buffer.readf32(v1, 0) < v14
    end

    if tag == "IsDeckFree" then
        local toggle_board_physical = p8.toggle_board_physical

        if toggle_board_physical == nil then
            error("IsDeckFree requires completed OffBoard312", 0)
        end

        return toggle_board_physical.free_board
    end

    if tag == "IsBipedCommittedToMotion" then
        return gameplay_conditions.offboard_committed_to_motion
    end

    if tag == "TrucksOrDeckInContact" then
        return gameplay_conditions.trucks_or_deck_contact
    end

    if tag == "ApexReached" then
        return gameplay_conditions.reached_apex
    end

    if tag == "DistToEdge" then
        return NumericCondition.matches(p7[1], gameplay_conditions.offboard_edge_distance)
    end

    if tag == "EnoughDistToObstacle" then
        return t1.enough_distance(gameplay_conditions.offboard_obstacle_distance, MotionAnimation.stock_clip_translation_z(p8.animation, p7.database, p7.animation))
    end

    if tag == "IsCrouchedEnoughForBlendToGrabCycle" then
        local crouching_physical = p8.crouching_physical

        if crouching_physical == nil then
            error("Crouch condition requires physical animation height", 0)
        end

        return crouching_physical.animation_height_72 < 0.6000000238418579
    end

    if tag == "PhysicsWantsManualExit" then
        local manual_exit = p8.manual_exit

        if manual_exit == nil then
            error("PhysicsWantsManualExit requires completed physical animation output", 0)
        end

        return manual_exit
    end

    error("internal error: entered unreachable code", 0)
end

function t1.enough_distance(p9, p10) -- line: 164
    -- upvalues: v1 (copy)
    local v18

    if p9 ~= 0 and p9 > -1.1754943508222875E-38 and p9 < 1.1754943508222875E-38 then
        local v19 = math.abs(p9) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = (if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20) * 1.401298464324817E-45

        if p9 < 0 then
            v18 = -v18
        end
    else
        buffer.writef32(v1, 0, p9)
        v18 = buffer.readf32(v1, 0)
    end

    local v22

    if p10 ~= 0 and p10 > -1.1754943508222875E-38 and p10 < 1.1754943508222875E-38 then
        local v23 = math.abs(p10) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = (if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24) * 1.401298464324817E-45

        if p10 < 0 then
            v22 = -v22
        end
    else
        buffer.writef32(v1, 0, p10)
        v22 = buffer.readf32(v1, 0)
    end

    local v26 = v22 + 0.30000001192092896
    local v27

    if v26 == 0 or not (v26 > -1.1754943508222875E-38) or not (v26 < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, v26)
        v27 = buffer.readf32(v1, 0)

        return not (v18 < v27)
    end

    local v28 = math.abs(v26) * 7.1362384635298E+44
    local v29 = math.floor(v28)
    local v30 = v28 - v29

    v27 = (if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29) * 1.401298464324817E-45

    if v26 < 0 then
        v27 = -v27
    end

    return not (v18 < v27)
end

return t1
