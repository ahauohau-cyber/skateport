-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/grind_chromosome/pose")
local encode = import("skate_core/animation/skeleton_input/name").encode

local function grind() -- line: 14
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {
    names = import("skate_game/physics/grind_names")
}
local names = t1.names

t1.ApproachPose = v1.ApproachPose
t1.Input = v1.Input

local add, dot, signed, sub = v1.add, v1.dot, v1.signed, v1.sub

t1.Components = {}

local Components = t1.Components

function t1.Components.eq(p1, p2) -- line: 35
    for i = 1, 6 do
        if p1[1][i] ~= p2[1][i] then
            return false
        end
    end

    return true
end

function t1.Components.name(p3) -- line: 45
    -- upvalues: rt (copy), names (copy)
    local v2 = names.lookup(rt.copy(p3[1]))

    if v2 == nil then
        error("validated grind chromosome dimensions", 0)
    end

    return v2
end

function t1.publish(p4, p5) -- line: 57
    -- upvalues: rt (copy), encode (copy), Components (copy)
    p5.volatile_chromosome_244 = rt.copy(p4.volatile[1])

    local animation = p4.animation

    if animation ~= nil then
        local v3 = Components.name(animation)

        p5.animation_chromosome_268 = rt.copy(animation[1])
        p5.animation_id_144 = rt.to_u32(v3.skating_id)
        p5.animation_name_156 = encode(v3.attribute)
    end

    local scoring = p4.scoring

    if scoring == nil then
        return
    end

    local v4 = Components.name(scoring)

    p5.scoring_chromosome_292 = rt.copy(scoring[1])
    p5.scoring_id_148 = rt.to_u32(v4.skating_id)
    p5.scorable_id_152 = rt.to_u32(v4.scorable_id)
    p5.scoring_name_176 = encode(v4.attribute)
end

t1.Publication = {}

local function option_components_eq(p6, p7) -- line: 79
    -- upvalues: Components (copy)
    if p6 ~= nil and p7 ~= nil then
        return Components.eq(p6, p7)
    end

    if p6 == nil then
        return p7 == nil
    end

    return false
end

function t1.Publication.eq(p8, p9) -- line: 87
    -- upvalues: Components (copy)
    local v5 = Components.eq(p8.volatile, p9.volatile)

    if not v5 then
        return v5
    end

    local animation = p8.animation
    local animation2 = p9.animation
    local v6 = if animation == nil then animation2 == nil elseif animation2 == nil then animation == nil and animation2 == nil else Components.eq(animation, animation2)

    if not v6 then
        return v6
    end

    local scoring = p8.scoring
    local scoring2 = p9.scoring

    if scoring ~= nil and scoring2 ~= nil then
        return (Components.eq(scoring, scoring2))
    end

    if scoring == nil then
        return scoring2 == nil
    end

    return false
end

t1.Chromosome = {}

local Chromosome = t1.Chromosome

function t1.Chromosome.uninitialized() -- line: 113
    -- upvalues: Chromosome (copy)
    local v7 = Chromosome.new(false)

    v7.saved_fakie_initialized = false

    return v7
end

function t1.Chromosome.initialize_host_fakie(p10, p11) -- line: 122
    if not p10.saved_fakie_initialized then
        p10.saved.fakie = p11
        p10.saved_fakie_initialized = true
    end
end

function t1.Chromosome.new(p12) -- line: 133
    return {
        saved_fakie_initialized = true,
        approach = 0,
        previous_category = 0,
        previous_kind = nil,
        away_frames = 31,
        reversed = false,
        orientation = nil,
        pending = nil,
        pending_frames = 0,
        animation = nil,
        scoring = nil,
        history = table.create(30),
        saved = {
            right = { 1, 0, 0, 0 },
            position = { 0, 0, 0, 0 },
            feet = {
                { 1, 0, 0, 0 },
                { 1, 0, 0, 0 }
            },
            fakie = p12
        }
    }
end

function t1.Chromosome.reference(p13) -- line: 157
    -- upvalues: rt (copy)
    if #p13.history == 30 then
        return rt.copy(p13.history[1])
    end

    return rt.copy(p13.saved)
end

function t1.Chromosome.update(p14, p15) -- line: 169
    -- upvalues: rt (copy), import (copy), v1 (copy), add (copy), dot (copy), signed (copy), sub (copy), Components (copy), Chromosome (copy)
    local Family = import("skate_game/physics/grind").Family
    local t2 = {
        right = rt.copy(p15.basic_right_0),
        position = rt.copy(p15.basic_position_48),
        feet = rt.copy(p15.feet_256_272),
        fakie = p15.fakie_155
    }

    if p15.air_event_439 then
        p14.saved = rt.copy(t2)
        p14.saved_fakie_initialized = true
        table.clear(p14.history)
    end

    if p15.category == 100 then
        if #p14.history == 30 then
            table.remove(p14.history, 1)
        end

        table.insert(p14.history, rt.copy(t2))
    end

    local v8 = p15.category == 400 and p14.previous_category ~= 400 and p14.away_frames > 30

    if v8 or p15.category == 400 and p14.previous_kind ~= p15.family then
        p14.saved = Chromosome.reference(p14)
        p14.saved_fakie_initialized = p14.saved_fakie_initialized or #p14.history == 30
    end

    if v8 then
        local v10 = signed(p15.across, dot(p15.across, sub(p14.saved.position, p15.point)) > 0)

        p14.approach = dot(signed(p14.saved.right, dot(add(p14.saved.feet[1], p14.saved.feet[2]), p14.saved.right) > 0), v10) > 0 and 1 or 0
    end

    p14.previous_kind = p15.family

    if p15.category == 400 then
        p14.away_frames = 0
    else
        p14.away_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p14.away_frames), 1))
    end

    local family = if p15.grinding_316 then p15.family else nil
    local t3

    if family ~= nil then
        local v12 = Chromosome.travel(p14, p15, family)
        local v13 = v1.low(p15)
        local v14 = v1.straight(p15)
        local v15 = (family == Family.Tipslide or family == Family.FiveO or family == Family.Backslash) and dot(sub(p15.point, p15.basic_location_position_144), p15.basic_location_axis_96) <= 0
        local t4 = {
            {
                p14.approach,
                if v15 then 1 else 0,
                if v14 then 1 else 0,
                if v13 then 1 else 0,
                v12,
                family
            }
        }

        if p14.previous_category == 400 then
            if p14.pending == nil or not Components.eq(p14.pending, t4) then
                p14.pending = rt.copy(t4)
                p14.pending_frames = 0
            else
                p14.pending_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p14.pending_frames), 1))
            end
        else
            p14.pending = rt.copy(t4)
            p14.pending_frames = 13
        end

        if p14.pending_frames > 0 then
            p14.animation = rt.copy(p14.pending)
        end

        if p14.pending_frames > 12 then
            p14.scoring = rt.copy(p14.pending)
        end

        t3 = {
            volatile = t4,
            animation = rt.copy(p14.animation),
            scoring = rt.copy(p14.scoring)
        }
    else
        p14.orientation = nil
        p14.reversed = false
    end

    p14.previous_category = p15.category

    return t3
end

function t1.Chromosome.travel(p16, p17, p18) -- line: 258
    -- upvalues: import (copy), add (copy), dot (copy), signed (copy), Chromosome (copy)
    local Family = import("skate_game/physics/grind").Family
    local v19 = add(p17.feet_256_272[1], p17.feet_256_272[2])
    local v21 = dot(signed(p17.basic_right_0, dot(v19, p17.basic_right_0) > 0), p17.direction) > 0
    local v22 = false
    local v23 = false
    local v24 = false
    local v25 = false

    if p18 == Family.FiftyFifty then
        v23 = true
    else
        v22 = true
    end

    if v22 then
        if p18 == Family.FiveO then
            v23 = true
        else
            v25 = true
        end
    end

    v22 = false

    if v23 then
        if p16.orientation ~= nil then
            v25 = false
        else
            v22 = true
        end
    end

    v23 = false

    if v22 then
        if #p16.history == 30 then
            v24 = true
        else
            v23 = true
        end
    end

    v22 = false

    if v23 then
        if p16.saved_fakie_initialized then
            v24 = true
        else
            v22 = true
        end
    end

    v23 = false

    if v22 then
        v24 = true
        error("saved fakie144 consumed before an actual history write", 0)
    end

    v22 = false

    local v26

    if v24 then
        v26 = Chromosome.reference(p16)

        if dot(v19, add(v26.feet[1], v26.feet[2])) < 0 then
            v23 = true
        else
            v22 = true
        end
    end

    v24 = false

    local v27

    if v22 then
        v27 = false
        v24 = true
    end

    if v23 then
        v27 = true
        v24 = true
    end

    v23 = false

    if v24 then
        p16.reversed = v27

        if v26.fakie then
            v23 = true
        else
            v25 = false
        end
    end

    if v23 then
        v25 = false
        p16.reversed = not p16.reversed
    end

    local v28 = 0

    if v25 then
        v28 = if v21 then 0 else 1
    else
        local reversed = if v21 then p16.reversed else nil

        if not v21 or reversed then
            local reversed = if not v21 then p16.reversed else nil

            if v21 or reversed then
                local reversed = if v21 then p16.reversed else nil

                v28 = if not v21 or not reversed then 3 else 2
            else
                v28 = 1
            end
        end
    end

    p16.orientation = v28

    return v28
end

return t1
