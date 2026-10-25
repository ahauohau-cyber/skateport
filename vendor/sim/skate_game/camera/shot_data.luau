-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Shot = import("skate_core/camera").Shot
local Collections = import("skate_data/collections").Collections
local v1 = import("skate_game/camera/stock_names")
local t1 = {
    CLASS = "camera_shots",
    CLASS_HASH = "0xF27DD93E059EF6CB",
    RADIANS = 0.01745329238474369
}
local CLASS, CLASS_HASH, RADIANS = t1.CLASS, t1.CLASS_HASH, t1.RADIANS
local has_field

t1.StockShots = {}

function t1.StockShots.from_collections(p1) -- line: 36
    -- upvalues: Shot (copy), Collections (copy), v1 (copy), CLASS (copy), CLASS_HASH (copy), RADIANS (copy), has_field (ref)
    local t2 = {}

    for _, v2 in Collections.entries(p1) do
        if v2.class_name == CLASS then
            local CollectionName = Collections.field(p1, CLASS, v2.key, "CollectionName")

            if CollectionName.type_name ~= "EA::Reflection::Text" then
                error(("Invalid camera collection name %*"):format(v2.key), 0)
            end

            local v3 = v1.lookup8(v2.key)
            local v4 = t2[v3]

            t2[v3] = CollectionName.data

            if v4 ~= nil then
                error("Duplicate camera collection hash", 0)
            end
        end
    end

    local t3 = {}

    for _, v5 in Collections.entries(p1) do
        if v5.class_name == CLASS then
            local key = v5.key

            local function float(p2) -- line: 59
                -- upvalues: p1 (copy), key (copy), Collections (copy), CLASS (copy)
                return Collections.float(p1, CLASS, key, p2)
            end

            local function enumeration(p3) -- line: 62
                -- upvalues: p1 (copy), key (copy), Collections (copy), CLASS (copy)
                return Collections.words(p1, CLASS, key, p3, 1)[1]
            end

            local function boolean(p4) -- line: 65
                -- upvalues: p1 (copy), key (copy), Collections (copy), CLASS (copy)
                if Collections.boolean(p1, CLASS, key, p4) then
                    return 1
                end

                return 0
            end

            local function floats(p5) -- line: 68
                -- upvalues: p1 (copy), key (copy), Collections (copy), CLASS (copy)
                local v6 = table.create(#p5)

                for v7, v8 in p5 do
                    v6[v7] = Collections.float(p1, CLASS, key, v8)
                end

                return v6
            end

            local function child(p6) -- line: 76
                -- upvalues: p1 (copy), t2 (copy), key (copy), Collections (copy), CLASS (copy), CLASS_HASH (copy)
                local v9 = Collections.words(p1, CLASS, key, p6, 6)
                local v10 = string.format("0x%08X%08X", v9[1], v9[2])
                local v11 = string.format("0x%08X%08X", v9[3], v9[4])

                if v9[3] == 0 and v9[4] == 0 then
                    return nil
                end

                if v10 ~= CLASS_HASH then
                    error(("Non-shot reference %*/%*"):format(key, p6), 0)
                end

                local v12 = t2[v11]

                if v12 == nil then
                    error(string.format("Missing camera child %s/%s: %08X%08X", key, p6, v9[3], v9[4]), 0)
                end

                if #v12 == 0 then
                    return nil
                end

                return string.lower(v12)
            end

            local PositionDistance = Collections.float(p1, CLASS, key, "PositionDistance")
            local FramingLensLength = Collections.float(p1, CLASS, key, "FramingLensLength")
            local t4 = {
                "SmoothingDirection",
                "SmoothingElevation",
                "SmoothingYaw",
                "SmoothingPitch"
            }
            local v13 = table.create(#t4)

            for v14, v15 in t4 do
                v13[v14] = Collections.float(p1, CLASS, key, v15)
            end

            local t5 = {
                "ReferenceWeightHead",
                "ReferenceWeightHips",
                "ReferenceWeightGrind",
                "ReferenceWeightCOM",
                "ReferenceWeightBoard",
                "ReferenceWeightTrajectory",
                "ReferenceWeightAnchor",
                "ReferenceWeightFeet",
                "ReferenceWeightDampedCOM",
                "Hash_D70C95EDC16A7DFC"
            }
            local v16 = table.create(#t5)

            for v17, v18 in t5 do
                v16[v17] = Collections.float(p1, CLASS, key, v18)
            end

            local ReferenceBoardOffset = Collections.float(p1, CLASS, key, "ReferenceBoardOffset")
            local v19 = Collections.float(p1, CLASS, key, "PositionHeading") * RADIANS
            local v20 = Collections.float(p1, CLASS, key, "PositionElevation") * RADIANS
            local t6 = {
                Collections.float(p1, CLASS, key, "FramingRoll") * RADIANS,
                Collections.float(p1, CLASS, key, "FramingYaw") * RADIANS,
                Collections.float(p1, CLASS, key, "FramingPitch") * RADIANS
            }
            local v21 = if Collections.boolean(p1, CLASS, key, "OptionFollowSubjectInAir") then 1 else 0
            local v22 = if Collections.boolean(p1, CLASS, key, "OptionMirrorForStance") then 1 else 0
            local v23 = if Collections.boolean(p1, CLASS, key, "OptionSnapToReferencePoint") then 1 else 0
            local v24 = if Collections.boolean(p1, CLASS, key, "OptionUsePreviousShot") then 1 else 0
            local v25 = if Collections.boolean(p1, CLASS, key, "OptionUseDropPredictor") then 1 else 0
            local v26 = if Collections.boolean(p1, CLASS, key, "OptionUseFreeCamStick") then 1 else 0
            local v27 = if has_field(p1, key, "OptionAvoidanceOverride") and Collections.boolean(p1, CLASS, key, "OptionAvoidanceOverride") then 1 else 0
            local FXBlurShot = Collections.float(p1, CLASS, key, "FXBlurShot")
            local FXBlurTransition = Collections.float(p1, CLASS, key, "FXBlurTransition")
            local FXSubjectOpacity = Collections.float(p1, CLASS, key, "FXSubjectOpacity")
            local v28 = Collections.words(p1, CLASS, key, "OptionCollisionType", 1)[1]
            local v29 = Collections.words(p1, CLASS, key, "OptionAnchor", 1)[1]
            local v30 = Collections.words(p1, CLASS, key, "OptionCompassNorth", 1)[1]
            local v31 = Collections.float(p1, CLASS, key, "WorldHeading") * RADIANS
            local v32 = Shot.new()

            v32.distance = PositionDistance
            v32.lens_length = FramingLensLength
            v32.smoothing = v13
            v32.reference_weights = v16
            v32.board_offset = ReferenceBoardOffset
            v32.position_heading = v19
            v32.position_elevation = v20
            v32.framing = t6
            v32.follow_subject_in_air = v21
            v32.mirror_for_stance = v22
            v32.snap_to_reference_point = v23
            v32.use_previous_shot = v24
            v32.use_drop_predictor = v25
            v32.use_free_camera_stick = v26
            v32.avoidance_override = v27
            v32.blur = FXBlurShot
            v32.transition_blur = FXBlurTransition
            v32.subject_opacity = FXSubjectOpacity
            v32.collision_hint = v28
            v32.anchor = v29
            v32.compass_north = v30
            v32.world_heading = v31

            local t7 = {
                name = string.lower(key),
                shot_type = Collections.words(p1, CLASS, key, "ShotType", 1)[1],
                shot = v32,
                transition_time = Collections.float(p1, CLASS, key, "TransitionTime"),
                transition_units = Collections.words(p1, CLASS, key, "TransitionTimeUnits", 1)[1],
                children = {
                    child("BlendShot1"),
                    child("BlendShot2"),
                    (child("BlendShot3"))
                },
                blend_points = {
                    Collections.float(p1, CLASS, key, "BlendPoint1"),
                    Collections.float(p1, CLASS, key, "BlendPoint2"),
                    float("BlendPoint3")
                },
                blend_value = Collections.float(p1, CLASS, key, "BlendValue"),
                blend_type = Collections.words(p1, CLASS, key, "BlendType", 1)[1],
                blend_smoothing = Collections.float(p1, CLASS, key, "SmoothingBlendValue")
            }
            local v33 = t3[t7.name]

            t3[t7.name] = t7

            if v33 ~= nil then
                error(("Duplicate lowercase camera shot %*"):format(key), 0)
            end
        end
    end

    local t8 = {}

    for v34 in t3 do
        table.insert(t8, v34)
    end

    table.sort(t8)

    for _, v35 in t8 do
        local v36 = t3[v35]

        for i = 0, 2 do
            local v37 = v36.children[i + 1]

            if v37 ~= nil and t3[v37] == nil then
                error(("Camera shot %* references missing named shot %*"):format(v36.name, v37), 0)
            end
        end
    end

    return { t3 }
end

function t1.StockShots.load(p7, p8) -- line: 221
    -- upvalues: rt (copy)
    local v38 = p7[1][string.lower(p8)]

    if v38 == nil then
        error(("Missing stock camera shot %*"):format(p8), 0)
    end

    return rt.copy(v38)
end

function t1.has_field(p9, p10, p11) -- line: 230
    -- upvalues: Collections (copy), CLASS (copy)
    local v39 = Collections.entries(p9)
    local v40 = #v39
    local v41 = p10

    for _ = 0, v40 do
        local v42

        for _, v43 in v39 do
            if v43.class_name == CLASS and v43.key == v41 then
                v42 = v43
                break
            end
        end

        if v42 == nil then
            error(("Missing camera collection %*"):format(v41), 0)
        end

        if v42.fields[p11] ~= nil then
            return true
        end

        if #v42.parent == 0 then
            return false
        end

        v41 = v42.parent
    end

    error(("Cyclic camera collection inheritance %*"):format(p10), 0)
end

has_field = t1.has_field

return t1
