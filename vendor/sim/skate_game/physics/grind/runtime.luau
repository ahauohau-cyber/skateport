-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/grind_chromosome")
local v2 = import("skate_game/physics/grind/output")
local Settings = import("skate_game/physics/grind/settings").Settings
local State = import("skate_game/physics/grind/state").State
local OrientationRandom = import("skate_game/physics/grind/rng").OrientationRandom

local function grind() -- line: 15
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {
    Runtime = {}
}

function t1.Runtime.adopt_mode_settings(p1, p2) -- line: 40
    p1.settings = p2.settings
end

function t1.Runtime.load(p3) -- line: 45
    -- upvalues: rt (copy), v1 (copy), Settings (copy), State (copy), OrientationRandom (copy)
    return {
        active = nil,
        nonspecific_active = false,
        nonspecific_jumped = false,
        manager = nil,
        pending_wipeout_impulse = nil,
        states = rt.filled(6, State.new()),
        nonspecific_jump_velocity = { 0, 0, 0, 0 },
        orientation_random = OrientationRandom.new(),
        settings = Settings.load(p3),
        chromosome = v1.Chromosome.uninitialized()
    }
end

function t1.Runtime.active_name(p4) -- line: 61
    -- upvalues: import (copy)
    local Family = import("skate_game/physics/grind").Family
    local active = p4.active

    if active == nil then
        return nil
    end

    if active == Family.FiftyFifty then
        return "50-50"
    end

    if active == Family.Boardslide then
        return "boardslide"
    end

    if active == Family.Tipslide then
        return "tipslide"
    end

    if active == Family.FiveO then
        return "5-0"
    end

    if active == Family.Backslash then
        return "backslash"
    end

    return "darkslide"
end

function t1.Runtime.take_orientation_noise(p5) -- line: 82
    -- upvalues: OrientationRandom (copy)
    return OrientationRandom.take_three(p5.orientation_random)
end

function t1.Runtime.observe(p6, p7) -- line: 88
    p6.manager = p7
end

function t1.Runtime.fill_physical(p8, p9, p10) -- line: 95
    -- upvalues: rt (copy), v2 (copy)
    local active = p8.active

    if active == nil then
        return nil
    end

    return v2.fill_fields(active, rt.copy(p8.states[active + 1].output), p9, p10)
end

function t1.Runtime.condition_outputs(p11, p12, p13) -- line: 106
    -- upvalues: v1 (copy)
    local chromosome = p11.chromosome

    v1.Chromosome.initialize_host_fakie(chromosome, p12.fakie_155)

    local v3 = v1.Chromosome.update(chromosome, p12)

    if v3 ~= nil then
        v1.publish(v3, p13)
    end
end

function t1.Runtime.last_grind_distance(_) -- line: 120
    return 0
end

function t1.Runtime.filtered_output(p15) -- line: 125
    -- upvalues: rt (copy)
    local v4 = rt.to_i32(p15.words_136_140[1])
    local v5 = rt.to_i32(p15.scorable_id_152)

    if p15.animation_name_156 == nil then
        error("Missing native grind name reset/publication", 0)
    end

    local v6 = rt.copy(p15.animation_name_156)

    if p15.scoring_name_176 == nil then
        error("Missing native scoring grind name reset/publication", 0)
    end

    return {
        kind = v4,
        scorable_id = v5,
        name = v6,
        scoring_name = rt.copy(p15.scoring_name_176),
        on_front = p15.flag_318 ~= 0,
        crouch = p15.crouch_132,
        pathed_guid = p15.spline_guids_224_232[1],
        local_guid = p15.spline_guids_224_232[2]
    }
end

return t1
