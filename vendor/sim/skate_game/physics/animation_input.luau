-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local JumpAttributeState = import("skate_core/animation/skeleton_input/attribute_finalization").JumpAttributeState
local ExtendedAttributes = import("skate_core/animation/skeleton_input/extended_attributes").ExtendedAttributes
local encode = import("skate_core/animation/skeleton_input/name").encode
local v1 = import("skate_core/animation/skeleton_input/process_attributes")
local ScalarAttributeInputs = import("skate_core/animation/skeleton_input/scalar_attributes").ScalarAttributeInputs
local Collections = import("skate_data/collections").Collections

local function difficulty() -- line: 18
    -- upvalues: import (copy)
    return import("skate_game/difficulty")
end

local t1 = {
    AnimationInput = {}
}

function t1.AnimationInput.adopt_mode_settings(p1, p2) -- line: 30
    p1.height_overrides = p2.height_overrides
end

function t1.AnimationInput.load(p3, p4, p5) -- line: 35
    -- upvalues: import (copy), JumpAttributeState (copy), ExtendedAttributes (copy), encode (copy), ScalarAttributeInputs (copy), Collections (copy)
    local v2

    for v3, v4 in p4.bone_names do
        if string.lower(v4) == "righttoebase" then
            v2 = v3 - 1
            break
        end
    end

    if v2 == nil then
        error("Stock skeleton is missing RightToeBase", 0)
    end

    local t2 = {}
    local t3 = {}

    for _, v5 in import("skate_game/difficulty").NATIVE_MODES do
        local boolean = Collections.boolean
        local JumpHeightOverrideEnabled, JumpHeightOverrideEnabled2 = pcall(boolean, p3, "physics_mode", v5, "JumpHeightOverrideEnabled")

        table.insert(t3, {
            JumpHeightOverrideEnabled,
            JumpHeightOverrideEnabled2
        })
    end

    local t5 = {}

    for _, v6 in t3 do
        if not v6[1] then
            error(v6[2], 0)
        end

        table.insert(t5, v6[2])
    end

    t2.height_overrides = t5
    t2.fields = ScalarAttributeInputs.reset(0, 0)
    t2.extra = ExtendedAttributes.reset(0)
    t2.contacts = {
        bone = 0,
        push_speed = 0
    }
    t2.cached_jump = JumpAttributeState.new()
    t2.output = {
        flags = 0,
        grind_name = encode("")
    }

    local t6 = {}

    for _, v8 in p4.bone_names do
        table.insert(t6, encode(v8))
    end

    t2.bone_names = t6
    t2.right_toe = v2
    t2.settings = {
        select_jump_extremes = Collections.boolean(p3, "anim_motion", "jumping", "clamp_jump"),
        low_jump_threshold = Collections.float(p3, "anim_motion", "jumping", "clamp_low_inclusive"),
        high_jump_threshold = Collections.float(p3, "anim_motion", "jumping", "clamp_high_inclusive"),
        allow_height_override = Collections.boolean(p3, "physics_mode", p5, "JumpHeightOverrideEnabled"),
        use_prepared_controls = Collections.boolean(p3, "physics_jump", "default", "AdjustOnPrepare"),
        external_impulse_active = false,
        animation_flags = 0
    }

    return t2
end

function t1.AnimationInput.select_physics_mode(p6, p7) -- line: 101
    local v9 = p6.height_overrides[p7 + 1]

    if v9 == nil then
        error(string.format("Invalid animation physics mode %d", p7), 0)
    end

    p6.settings.allow_height_override = v9
end

function t1.AnimationInput.reset_processed(p8) -- line: 111
    -- upvalues: ExtendedAttributes (copy), ScalarAttributeInputs (copy)
    p8.fields = ScalarAttributeInputs.reset(p8.fields.flags2468, p8.fields.flags2488)
    p8.extra = ExtendedAttributes.reset(p8.extra.footstep_strength)
    p8.contacts = {
        bone = 0,
        push_speed = 0
    }
end

function t1.AnimationInput.finish_output_publication(p9) -- line: 122
    -- upvalues: encode (copy)
    p9.output.grind_name = encode("")
    p9.output.flags = bit32.band(p9.output.flags, 4194303)
    p9.extra.footstep_strength = 0
end

function t1.AnimationInput.process(p10, p11, p12, p13, p14, p15, p16) -- line: 130
    -- upvalues: rt (copy), v1 (copy)
    local t7 = {
        trajectory_bone = 0,
        bone_names = p10.bone_names,
        hierarchy = p12,
        right_toe_bone = p10.right_toe,
        timestep = p13
    }
    local v10 = rt.copy(p10.settings)

    v10.animation_flags = p14
    v10.external_impulse_active = p15
    v1.process(p11, t7, p10.fields, p10.extra, p10.contacts, p10.cached_jump, p10.output, v10, p16)
end

return t1
