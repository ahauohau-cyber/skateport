-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_game/graph_host/motion_animation")
local v3 = import("skate_game/graph_host/motion_stock_gameplay")
local v4 = import("skate_core/animation/output/attributes")
local encode = import("skate_core/animation/skeleton_input/name").encode
local IntentMap = import("skate_core/graph/intents").IntentMap
local Attributes = import("skate_data/state_graph/attributes").Attributes
local AnimationMetadata = import("skate_data/animation_metadata").AnimationMetadata
local MotionAnimation = v2.MotionAnimation
local AttributeName = v4.AttributeName
local t1 = {}

t1.Operation = {}

function t1.Operation.parse(p2) -- line: 37
    -- upvalues: v1 (copy), encode (copy), Attributes (copy)
    local name = Attributes.text(p2, "name")

    if name ~= nil then
        local function text_or_empty(p3) -- line: 42
            -- upvalues: p2 (copy), Attributes (copy)
            local v5 = Attributes.text(p2, p3)

            if v5 == nil then
                v5 = ""
            end

            return v5
        end

        if name == "FootPlantAbsorb" then
            return {
                tag = "FootPlantAbsorb"
            }
        end

        if name == "SetHandPlantAnticLength" then
            return {
                tag = "HandplantAntic"
            }
        end

        if name == "ScoringHandPlants" then
            local handplantname = Attributes.text(p2, "handplantname")

            if handplantname == nil then
                handplantname = ""
            end

            local t2 = {
                Attributes.text(p2, "up"),
                Attributes.text(p2, "left"),
                Attributes.text(p2, "down"),
                (Attributes.text(p2, "right"))
            }
            local intentX = Attributes.text(p2, "intentX")

            if intentX == nil then
                intentX = ""
            end

            local intentY = Attributes.text(p2, "intentY")

            if intentY == nil then
                intentY = ""
            end

            return {
                tag = "HandplantScore",
                base = handplantname,
                directions = t2,
                intents = {
                    intentX,
                    intentY
                }
            }
        end

        if name == "SetTrickHeight" then
            local from = Attributes.text(p2, "from")

            if from == nil then
                from = ""
            end

            local v6 = encode(from)
            local rename = Attributes.text(p2, "rename")

            if rename == nil then
                rename = ""
            end

            local v7 = encode(rename)
            local setToValue = Attributes.get(p2, "setToValue")
            local v8

            if setToValue ~= nil then
                buffer.writeu32(v1, 0, setToValue.float_bits)
                v8 = buffer.readf32(v1, 0)
            end

            return {
                tag = "Height",
                from = v6,
                rename = v7,
                value = v8,
                manual = Attributes.get(p2, "trickFromManual") ~= nil,
                grind = Attributes.get(p2, "trickFromGrind") ~= nil
            }
        end

        if name == "SetTrickAttr" then
            local trick = Attributes.text(p2, "trick")

            if trick == nil then
                trick = ""
            end

            return {
                tag = "Attribute",
                (encode(trick))
            }
        end

        if name == "ScoringTrick" then
            local trick = Attributes.text(p2, "trick")

            if trick == nil then
                trick = ""
            end

            return {
                tag = "Scoring",
                (encode(trick))
            }
        end

        if name == "MonitorUnderflip" then
            return {
                tag = "MonitorUnderflip"
            }
        end

        if name == "SetDark" then
            return {
                tag = "Dark"
            }
        end

        if name == "UpdateIsWeightOnNose" then
            return {
                tag = "WeightOnNose"
            }
        end
    end

    return nil
end

t1.Requests = {}

function t1.Requests.default() -- line: 95
    return {
        underflip = false,
        dark_catch = false
    }
end

function t1.execute(p4, p5, p6, p7) -- line: 101
    -- upvalues: rt (copy), v1 (copy), v3 (copy), encode (copy), IntentMap (copy), AnimationMetadata (copy), t1 (copy), MotionAnimation (copy), AttributeName (copy)
    local tag = p5.tag

    if tag == "HandplantAntic" and p7 == 0 then
        local function duration(p8) -- line: 105
            -- upvalues: p4 (copy), v1 (copy), AnimationMetadata (copy), MotionAnimation (copy)
            local v9 = AnimationMetadata.clip(MotionAnimation.metadata(p4.animation), p8)

            buffer.writeu32(v1, 0, v9.frames_bits)

            local v10 = buffer.readf32(v1, 0) - 1

            buffer.writeu32(v1, 0, v9.base_speed_bits)

            local v11 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v9.fps_bits)

            return v10 / (v11 * buffer.readf32(v1, 0))
        end

        local INVERT_HANDPLANT_FS_0_ANTIC = AnimationMetadata.clip(MotionAnimation.metadata(p4.animation), "INVERT_HANDPLANT_FS_0_ANTIC")

        buffer.writeu32(v1, 0, INVERT_HANDPLANT_FS_0_ANTIC.frames_bits)

        local v12 = buffer.readf32(v1, 0) - 1

        buffer.writeu32(v1, 0, INVERT_HANDPLANT_FS_0_ANTIC.base_speed_bits)

        local v13 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, INVERT_HANDPLANT_FS_0_ANTIC.fps_bits)

        local v14 = v12 / (v13 * buffer.readf32(v1, 0))
        local INVERT_HANDPLANT_FS_0_ANTIC_LATE = AnimationMetadata.clip(MotionAnimation.metadata(p4.animation), "INVERT_HANDPLANT_FS_0_ANTIC_LATE")

        buffer.writeu32(v1, 0, INVERT_HANDPLANT_FS_0_ANTIC_LATE.frames_bits)

        local v15 = buffer.readf32(v1, 0) - 1

        buffer.writeu32(v1, 0, INVERT_HANDPLANT_FS_0_ANTIC_LATE.base_speed_bits)

        local v16 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, INVERT_HANDPLANT_FS_0_ANTIC_LATE.fps_bits)

        local v17 = v15 / (v16 * buffer.readf32(v1, 0))
        local gameplay_conditions = p4.gameplay_conditions

        if gameplay_conditions == nil then
            error("Handplant antic requires physical output", 0)
        end

        local v18 = rt.clamp((v14 - (gameplay_conditions.handplant_thresholds[3] - gameplay_conditions.handplant_time) - v17) / (v14 - v17), 0, 1)

        MotionAnimation.set_attribute(p4.animation, {
            normalized = false,
            sequence_id = -1,
            name = encode("antic_length"),
            value = v18
        })

        return p6
    end

    if tag == "HandplantScore" and p7 == 1 then
        local intents = p5.intents
        local v19 = MotionAnimation.filtered_intent(p4.animation, intents[1])

        if v19 == nil then
            v19 = 0
        end

        local t6 = {}

        t6[1] = v19

        local v20 = MotionAnimation.filtered_intent(p4.animation, intents[2])

        t6[2] = if v20 == nil then 0 else v20

        local directions = p5.directions
        local v21 = v3.select_grab_score(p5.base, {
            directions[1],
            directions[2],
            directions[3],
            directions[4]
        }, t6[1], t6[2])

        p4.score_packet.handplant = {
            encode(v21),
            t6
        }

        return p6
    end

    if tag == "FootPlantAbsorb" and p7 == 1 then
        local gameplay_conditions = p4.gameplay_conditions

        if gameplay_conditions == nil then
            error("FootPlantAbsorb requires physical output", 0)
        end

        local footplant_duration = gameplay_conditions.footplant_duration

        MotionAnimation.set_attribute(p4.animation, {
            normalized = false,
            sequence_id = -1,
            name = encode("absorblength"),
            value = footplant_duration
        })

        return p6
    end

    if tag == "Height" and p7 == 0 then
        local value, manual, grind = p5.value, p5.manual, p5.grind
        local GestureSpeed = IntentMap.get(p4.animation.motion_intents, "GestureSpeed")

        if GestureSpeed == nil then
            GestureSpeed = 0
        end

        if value == nil then
            value = IntentMap.get(p4.animation.motion_intents, "TrickHeight")

            if value == nil then
                local v22 = MotionAnimation.last_attribute(p4.animation, rt.copy(p5.from))
                local v23 = 0

                if v22 ~= nil then
                    local v24 = v22.payload[1][1]

                    if v24 ~= nil then
                        buffer.writeu32(v1, 0, v24)
                        v23 = buffer.readf32(v1, 0)
                    end
                end

                value = if not p4.trick_height_settings[1] then v23 elseif p4.trick_height_settings[2] then rt.fmin(v23, rt.fmax(GestureSpeed, 0)) else GestureSpeed
            end
        end

        local v25 = if manual then 0.27 elseif grind then 1 else 0.2

        MotionAnimation.emit_packet(p4.animation, encode("JumpHeightOverride"), GestureSpeed * v25)
        MotionAnimation.set_attribute(p4.animation, {
            normalized = true,
            sequence_id = -1,
            name = rt.copy(p5.rename),
            value = value
        })

        return p6
    end

    local v26

    if tag == "Attribute" then
        local v27 = p5[1]
        local Trick = encode("Trick")
        local construction_values = p4.animation.construction_values

        if p7 == 0 then
            local v28

            for _, v29 in construction_values do
                if AttributeName.eq(v29[1], Trick) then
                    v28 = v29
                    break
                end
            end

            if v28 ~= nil then
                v28[2] = rt.copy(v27)
            else
                table.insert(construction_values, {
                    Trick,
                    rt.copy(v27)
                })
            end

            return p6
        end

        v26 = p6

        if p7 == 2 and MotionAnimation.last_attribute(p4.animation, encode("defaultcyc")) ~= nil then
            local v30 = #construction_values
            local n1 = 0

            for i = 1, v30 do
                local v31 = construction_values[i]

                if not AttributeName.eq(v31[1], Trick) then
                    n1 += 1
                    construction_values[n1] = v31
                end
            end

            local v32 = n1 + 1

            v26 = p6

            for i = v30, v32, -1 do
                construction_values[i] = nil
                v26 = p6
            end
        end
    else
        if tag == "Scoring" and p7 == 1 then
            local v33 = p5[1]

            p4.score_packet.trick_names.first = rt.copy(v33)
            p4.score_packet.trick_names.second = rt.copy(v33)
            p4.score_packet.flags = bit32.bor(p4.score_packet.flags, 16777216)

            return p6
        end

        if tag == "MonitorUnderflip" then
            if p7 == 0 then
                return 0
            end

            if p7 == 2 then
                p4.trick_requests = t1.Requests.default()

                return p6
            end

            v26 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p6), rt.to_u32(1)))

            if v26 > 1 then
                local motion_intents = p4.animation.motion_intents
                local v34 = false

                for _, v35 in {
                        "U_L_F_Kickflip",
                        "U_L_F_Heelflip",
                        "U_L_B_Kickflip",
                        "U_L_B_Heelflip",
                        "U_Nollie",
                        "U_Fingerflip",
                        "U_Kickflip",
                        "U_Heelflip",
                        "U_N_Kickflip",
                        "U_N_Heelflip"
                    } do
                    if IntentMap.contains_key(motion_intents, v35) then
                        v34 = true
                        break
                    end
                end

                if v34 then
                    p4.trick_requests.underflip = true

                    return v26
                end

                if IntentMap.contains_key(motion_intents, "DarkCatch") then
                    p4.trick_requests.dark_catch = true

                    return v26
                end
            end
        elseif tag == "Dark" then
            p4.riding.dark = p7 ~= 2

            if p7 == 1 then
                MotionAnimation.emit_packet(p4.animation, encode("IsDark"), 1)

                return p6
            end

            v26 = p6
        else
            v26 = p6

            local skater_animation_flags

            if tag == "WeightOnNose" and p7 ~= 1 then
                skater_animation_flags = p4.animation.skater_animation_flags

                if skater_animation_flags == nil then
                    error("UpdateIsWeightOnNose requires live ISkaterAnim", 0)
                end

                p4.animation.skater_animation_flags = bit32.bor(bit32.band(skater_animation_flags, 4026531839), p7 == 0 and 268435456 or 0)
            end
        end
    end

    return v26
end

return t1
