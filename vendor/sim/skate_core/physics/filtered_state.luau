-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local encode = require(sim.import)("skate_core/animation/skeleton_input/name").encode
local t1 = {
    FilteredCategory = {
        Invalid = 0,
        Ground = 1,
        Air = 2,
        Grind = 3,
        Wipeout = 4,
        Teleport = 5,
        Offboard = 6,
        OffboardAir = 7
    }
}

function t1.FilteredCategory.default() -- line: 29
    -- upvalues: t1 (copy)
    return t1.FilteredCategory.Invalid
end

local Invalid, Ground, Air, Grind = t1.FilteredCategory.Invalid, t1.FilteredCategory.Ground, t1.FilteredCategory.Air, t1.FilteredCategory.Grind
local Wipeout, Teleport, Offboard, OffboardAir = t1.FilteredCategory.Wipeout, t1.FilteredCategory.Teleport, t1.FilteredCategory.Offboard, t1.FilteredCategory.OffboardAir

t1.GrindState = {}

function t1.GrindState.default() -- line: 51
    -- upvalues: encode (copy)
    return {
        kind = -1,
        scorable_id = -1,
        on_front = false,
        crouch = 0,
        pathed_guid = "0xFFFFFFFFFFFFFFFF",
        local_guid = "0xFFFFFFFFFFFFFFFF",
        name = encode({}),
        scoring_name = encode({})
    }
end

function t1.GrindState.eq(p1, p2) -- line: 67
    local function name_eq(p3, p4) -- line: 68
        for i = 1, 5 do
            if p3[1][i] ~= p4[1][i] then
                return false
            end
        end

        return true
    end

    local v1

    if p1.kind == p2.kind and p1.scorable_id == p2.scorable_id then
        v1 = name_eq(p1.name, p2.name)

        if v1 then
            v1 = name_eq(p1.scoring_name, p2.scoring_name)

            if v1 then
                v1 = p1.on_front == p2.on_front and p1.crouch == p2.crouch and p1.pathed_guid == p2.pathed_guid and p1.local_guid == p2.local_guid
            end
        end
    else
        v1 = false
    end

    return v1
end

t1.FilteredStateInput = {}
t1.FilteredStateOutput = {}
t1.FilteredState = {}

function t1.FilteredState.default() -- line: 110
    -- upvalues: t1 (copy), Invalid (copy)
    return {
        previous_physics_state = 0,
        air_count = 0,
        nonspecific_count = 0,
        nonspecific_collision_free_count = 0,
        nonspecific_collision_count = 0,
        frames_since_ground_stairs = 0,
        must_change = true,
        category = Invalid,
        previous_category = Invalid,
        cached_grind = t1.GrindState.default()
    }
end

function t1.FilteredState.reset(p5) -- line: 125
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p5, t1.FilteredState.default())
end

function t1.FilteredState.update(p6, p7) -- line: 129
    -- upvalues: rt (copy), t1 (copy), Invalid (copy), Ground (copy), Air (copy), Grind (copy), Wipeout (copy), Teleport (copy), Offboard (copy), OffboardAir (copy)
    local category = p6.category

    p6.previous_category = category

    if category == Wipeout or category == Invalid then
        p6.must_change = true
    elseif p6.previous_physics_state == 702 then
        p6.must_change = p7.physics_state ~= 702
    else
        p6.must_change = false
    end

    p6.air_count = t1.count(p6.air_count, p7.physics_category == 200)
    p6.nonspecific_count = t1.count(p6.nonspecific_count, p7.physics_state == 701)
    p6.nonspecific_collision_free_count = t1.count(p6.nonspecific_collision_free_count, p7.physics_state == 701 and not p7.anything_in_contact)
    p6.nonspecific_collision_count = t1.count(p6.nonspecific_collision_count, p7.physics_state == 701 and p7.anything_in_contact)
    p6.frames_since_ground_stairs = t1.count(p6.frames_since_ground_stairs, not (p7.physics_category == 100 and p7.physics_surface_type == 8))

    local physics_state = p7.physics_state

    if physics_state == 100 then
        category = if p7.wall_ride_exit then Air else Ground
    elseif not (physics_state >= 101 and physics_state <= 105) and physics_state ~= 602 then
        if physics_state == 200 then
            local v2 = p6.air_count > 3

            if category == Air then
                category = if not (v2 and p7.anything_in_contact) and not p6.must_change then Air else Ground
            elseif v2 and (category ~= Ground or p6.frames_since_ground_stairs > 9) or p6.must_change then
                category = Air
            end
        elseif physics_state == 201 then
            category = if p7.anything_in_contact and not p7.targeting_grind and p6.air_count > 5 then Ground else Air
        elseif physics_state ~= 202 and physics_state ~= 600 and physics_state ~= 601 then
            if physics_state == 300 then
                category = Wipeout
            elseif physics_state >= 400 and physics_state <= 405 then
                p6.cached_grind = rt.copy(p7.grind)
                category = Grind
            elseif physics_state == 500 or physics_state == 502 then
                category = Offboard
            elseif physics_state == 501 then
                category = if p7.offboard_has_landed then Offboard else OffboardAir
            elseif physics_state == 503 then
                category = if p7.offboard_on_deck then Ground else Offboard
            elseif physics_state == 702 then
                category = Teleport
            end
        else
            category = Air
        end
    else
        category = Ground
    end

    p6.category = category
    p6.previous_physics_state = p7.physics_state

    local v3 = p6.category == Grind

    return {
        category = p6.category,
        previous_category = p6.previous_category,
        grinding = v3,
        grind = if v3 then rt.copy(p6.cached_grind) else t1.GrindState.default(),
        last_grind_distance = p7.last_grind_distance
    }
end

function t1.count(p8, p9) -- line: 206
    -- upvalues: rt (copy)
    if p9 then
        return rt.to_i32(p8 + 1)
    end

    return 0
end

return t1
