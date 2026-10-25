-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local IntentMap = import("skate_core/graph/intents").IntentMap
local v1 = import("skate_core/input/gesture")
local Collections = import("skate_data/collections").Collections
local v2 = import("skate_data/gesture_patterns")
local Recognizer = v1.Recognizer
local t1 = {}

local function u8_from_str_radix_16(p1) -- line: 20
    if #p1 == 0 then
        error("cannot parse integer from empty string", 0)
    end

    local v3 = if string.sub(p1, 1, 1) == "+" then string.sub(p1, 2) else p1

    if #v3 == 0 or string.find(v3, "^%x+$") == nil then
        error("invalid digit found in string", 0)
    end

    local n1 = 0

    for i = 1, #v3 do
        n1 = n1 * 16 + tonumber(string.sub(v3, i, i), 16)

        if n1 > 255 then
            error("number too large to fit in target type", 0)
        end
    end

    return n1
end

local function path_join(p2, p3) -- line: 42
    if p2 == nil or p2 == "" then
        return p3
    end

    return tostring(p2) .. "/" .. p3
end

local function eq_ignore_ascii_case(p4, p5) -- line: 50
    return string.lower(p4) == string.lower(p5)
end

t1.GestureInput = {}

function t1.GestureInput.load(p6) -- line: 62
    -- upvalues: Collections (copy), v2 (copy), Recognizer (copy), u8_from_str_radix_16 (copy)
    local v7 = Collections.load(p6)

    local function misses(p7) -- line: 64
        -- upvalues: v7 (copy), Collections (copy), u8_from_str_radix_16 (copy)
        local NumTicksPatternNotInRangeBeforeCulling = Collections.field(v7, "recognizer", p7, "NumTicksPatternNotInRangeBeforeCulling")

        if NumTicksPatternNotInRangeBeforeCulling.type_name ~= "EA::Reflection::UInt8" then
            error("Recognizer culling field must be UInt8", 0)
        end

        return (u8_from_str_radix_16(NumTicksPatternNotInRangeBeforeCulling.data))
    end

    local t2 = {}

    for _, v8 in {
            { 1, "skater.pat" },
            { 1, "skater90.pat" },
            { 1, "skaterN90.pat" },
            { 1, "skater_air.pat" },
            { 1, "skater_fingerflip.pat" },
            { 0, "skaterls.pat" },
            { 0, "skaterstep.pat" }
        } do
        local v9 = v8[1]
        local v10 = v8[2]
        local new = Recognizer.new
        local load = v2.load
        local v11 = if p6 == nil or p6 == "" then "private/stock/data/joystick" else tostring(p6) .. "/" .. "private/stock/data/joystick"

        if v11 ~= nil and v11 ~= "" then
            v10 = tostring(v11) .. "/" .. v10
        end

        table.insert(t2, {
            v9,
            new(load(v10))
        })
    end

    local t4 = {
        held_pattern = nil,
        recognizers = t2
    }
    local NumTicksPatternNotInRangeBeforeCulling = Collections.field(v7, "recognizer", "left_stick", "NumTicksPatternNotInRangeBeforeCulling")

    if NumTicksPatternNotInRangeBeforeCulling.type_name ~= "EA::Reflection::UInt8" then
        error("Recognizer culling field must be UInt8", 0)
    end

    local v12 = u8_from_str_radix_16(NumTicksPatternNotInRangeBeforeCulling.data)
    local NumTicksPatternNotInRangeBeforeCulling2 = Collections.field(v7, "recognizer", "right_stick", "NumTicksPatternNotInRangeBeforeCulling")

    if NumTicksPatternNotInRangeBeforeCulling2.type_name ~= "EA::Reflection::UInt8" then
        error("Recognizer culling field must be UInt8", 0)
    end

    t4.maximum_misses = {
        v12,
        (u8_from_str_radix_16(NumTicksPatternNotInRangeBeforeCulling2.data))
    }

    return t4
end

local v14 = false

function t1.set_reference(p8) -- line: 100
    -- upvalues: v14 (ref)
    v14 = p8
end

local t6 = {
    0, 0
}
local t7 = {
    0, 0
}
local t8 = {
    t6,
    t7
}
local t9 = {
    maximum_misses = 0,
    difficulty = 0
}
local v15 = table.freeze({ 1, 0 })

function t1.GestureInput.publish(p9, p10, p11, p12, p13, p14) -- line: 118
    -- upvalues: IntentMap (copy), Recognizer (copy), t1 (copy), v14 (ref), t6 (copy), t7 (copy), t8 (copy), t9 (copy), v15 (copy)
    local t10, v16, v17, t11, v18

    if v14 then
        v18 = true
    elseif #p10 == 2 then
        t10 = t8
        v16 = p10[1][1]
        v17 = p10[1][2]
        t11 = t6

        if math.abs(v16) < 0.1 then
            v16 = 0
        end

        v18 = false
    else
        v18 = true
    end

    if v18 then
        return t1.GestureInput.publish_reference(p9, p10, p11, p12, p13, p14)
    end

    t11[1] = v16

    local v19 = -v17

    t6[2] = if math.abs(v19) < 0.1 then 0 else v19

    local v20 = p10[2][1]
    local v21 = p10[2][2]

    t7[1] = if math.abs(v20) < 0.1 then 0 else v20

    local v22 = -v21

    t7[2] = if math.abs(v22) < 0.1 then 0 else v22

    local t12 = {}
    local v23 = false

    for _, v24 in v15 do
        for _, v25 in p9.recognizers do
            if v25[1] == v24 then
                local v26 = v25[2]
                local v27 = Recognizer.held(v26, t10[v24 + 1])

                if v27 ~= nil and p9.held_pattern ~= nil then
                    local held_pattern = p9.held_pattern
                    local name = Recognizer.patterns(v26)[v27 + 1].name

                    if string.lower(held_pattern) == string.lower(name) then
                        v23 = true
                    end
                end
            end
        end

        for _, v28 in p9.recognizers do
            if v28[1] == v24 then
                local v29 = v28[2]

                t9.maximum_misses = p9.maximum_misses[v24 + 1]
                t9.difficulty = p11

                local v30 = Recognizer.sample(v29, t10[v24 + 1], t9)

                if v30 ~= nil then
                    local name = Recognizer.patterns(v29)[v30.pattern + 1].name

                    if name == "Kickflip" or name == "Heelflip" or name == "N_Kickflip" or name == "N_Heelflip" then
                        p9.held_pattern = name
                    end

                    table.insert(t12, {
                        name,
                        v30.strength
                    })
                end
            end
        end
    end

    local t14 = {}

    if v23 then
        IntentMap.insert(p14, "HoldPattern", 1)
        table.insert(t14, {
            "HoldPattern",
            1
        })
    end

    for _, v31 in t12 do
        local v32 = v31[1]
        local v33 = v31[2]

        if t1.permitted(v32, p12, p13, p14) then
            IntentMap.insert(p14, "Trick", 1)
            IntentMap.insert(p14, v32, 1)
            IntentMap.insert(p14, "GestureSpeed", v33)
            table.insert(t14, {
                "Trick",
                1
            })
            table.insert(t14, {
                v32,
                1
            })
            table.insert(t14, {
                "GestureSpeed",
                v33
            })
        end
    end

    return t14
end

function t1.GestureInput.publish_reference(p15, p16, p17, p18, p19, p20) -- line: 191
    -- upvalues: IntentMap (copy), Recognizer (copy), t1 (copy)
    local function deadzone(p21) -- line: 194
        if math.abs(p21) < 0.1 then
            return 0
        end

        return p21
    end

    local t19 = {}

    for i = 1, #p16 do
        local v34 = p16[i][1]
        local v35 = p16[i][2]

        if math.abs(v34) < 0.1 then
            v34 = 0
        end

        local v36 = -v35

        if math.abs(v36) < 0.1 then
            v36 = 0
        end

        t19[i] = {
            v34,
            v36
        }
    end

    local t21 = {}
    local v37 = false

    for _, v38 in { 1, 0 } do
        for _, v39 in p15.recognizers do
            if v39[1] == v38 then
                local v40 = v39[2]
                local v41 = Recognizer.held(v40, t19[v38 + 1])

                if v41 ~= nil and p15.held_pattern ~= nil then
                    local held_pattern = p15.held_pattern
                    local name = Recognizer.patterns(v40)[v41 + 1].name

                    if string.lower(held_pattern) == string.lower(name) then
                        v37 = true
                    end
                end
            end
        end

        for _, v42 in p15.recognizers do
            if v42[1] == v38 then
                local v43 = v42[2]
                local v44 = Recognizer.sample(v43, t19[v38 + 1], {
                    maximum_misses = p15.maximum_misses[v38 + 1],
                    difficulty = p17
                })

                if v44 ~= nil then
                    local name = Recognizer.patterns(v43)[v44.pattern + 1].name

                    if name == "Kickflip" or name == "Heelflip" or name == "N_Kickflip" or name == "N_Heelflip" then
                        p15.held_pattern = name
                    end

                    table.insert(t21, {
                        name,
                        v44.strength
                    })
                end
            end
        end
    end

    local t23 = {}

    if v37 then
        IntentMap.insert(p20, "HoldPattern", 1)
        table.insert(t23, {
            "HoldPattern",
            1
        })
    end

    for _, v45 in t21 do
        local v46 = v45[1]
        local v47 = v45[2]

        if t1.permitted(v46, p18, p19, p20) then
            IntentMap.insert(p20, "Trick", 1)
            IntentMap.insert(p20, v46, 1)
            IntentMap.insert(p20, "GestureSpeed", v47)
            table.insert(t23, {
                "Trick",
                1
            })
            table.insert(t23, {
                v46,
                1
            })
            table.insert(t23, {
                "GestureSpeed",
                v47
            })
        end
    end

    return t23
end

function t1.GestureInput.reset_recognizers(p22) -- line: 262
    -- upvalues: v1 (copy)
    for _, v48 in p22.recognizers do
        local v49 = v48[2]

        for i = 1, #v49.nodes do
            v49.nodes[i] = v1.Node.default()
        end

        v49.refractory = false
        v49.refractory_units = nil
        v49.held = nil
        v1.forget(v49)
    end

    p22.held_pattern = nil
end

local t28 = {}

function t1.GestureInput.publish_hz(p23, p24, p25, p26, p27, p28, p29) -- line: 285
    -- upvalues: IntentMap (copy), Recognizer (copy), t1 (copy), t6 (copy), t7 (copy), t9 (copy), v15 (copy), t28 (copy)
    local t29 = {}

    local function deadzoned(p30, p31, p32) -- line: 290
        if math.abs(p30) < 0.1 then
            p32[1] = 0
        else
            p32[1] = p30
        end

        local v50 = -p31

        p32[2] = if math.abs(v50) < 0.1 then 0 else v50

        return p32
    end

    local v51 = false

    for _, v52 in v15 do
        table.clear(t28)

        local v53 = p24[v52 + 1]

        if v52 == 1 and p25 ~= nil then
            for _, v54 in p25 do
                local v55 = v54[1]
                local v56 = v54[2]
                local t30 = {
                    0, 0
                }

                t30[1] = if math.abs(v55) < 0.1 then 0 else v55

                local v57 = -v56

                t30[2] = if math.abs(v57) < 0.1 then 0 else v57
                table.insert(t28, t30)
            end
        end

        local v58 = v53[1]
        local v59 = v53[2]
        local v60 = if v52 == 1 then t7 else t6

        v60[1] = if math.abs(v58) < 0.1 then 0 else v58

        local v61 = -v59

        v60[2] = if math.abs(v61) < 0.1 then 0 else v61
        table.insert(t28, v60)

        local v62 = #t28
        local v63 = 6 // v62
        local v64 = v51

        for v65, v66 in t28 do
            local v67 = v65 == v62

            for _, v68 in p23.recognizers do
                if v68[1] == v52 then
                    local v69 = v68[2]
                    local v70 = Recognizer.held(v69, v66)

                    if v67 and v70 ~= nil and p23.held_pattern ~= nil then
                        local held_pattern = p23.held_pattern
                        local name = Recognizer.patterns(v69)[v70 + 1].name

                        if string.lower(held_pattern) == string.lower(name) then
                            v64 = true
                        end
                    end
                end
            end

            v51 = v64

            for _, v71 in p23.recognizers do
                if v71[1] == v52 then
                    local v72 = v71[2]

                    t9.maximum_misses = p23.maximum_misses[v52 + 1]
                    t9.difficulty = p26

                    local v73 = Recognizer.sample_hz(v72, v66, t9, v63)

                    if v73 ~= nil then
                        local name = Recognizer.patterns(v72)[v73.pattern + 1].name

                        if name == "Kickflip" or name == "Heelflip" or name == "N_Kickflip" or name == "N_Heelflip" then
                            p23.held_pattern = name
                        end

                        table.insert(t29, {
                            name,
                            v73.strength
                        })
                    end
                end
            end
        end
    end

    table.clear(t28)

    local t32 = {}

    if v51 then
        IntentMap.insert(p29, "HoldPattern", 1)
        table.insert(t32, {
            "HoldPattern",
            1
        })
    end

    for _, v74 in t29 do
        local v75 = v74[1]
        local v76 = v74[2]

        if t1.permitted(v75, p27, p28, p29) then
            IntentMap.insert(p29, "Trick", 1)
            IntentMap.insert(p29, v75, 1)
            IntentMap.insert(p29, "GestureSpeed", v76)
            table.insert(t32, {
                "Trick",
                1
            })
            table.insert(t32, {
                v75,
                1
            })
            table.insert(t32, {
                "GestureSpeed",
                v76
            })
        end
    end

    return t32
end

function t1.permitted(p33, p34, p35, p36) -- line: 363
    -- upvalues: IntentMap (copy)
    local function bit(p37) -- line: 364
        -- upvalues: p34 (copy)
        return bit32.band(p34, (bit32.lshift(1, p37))) ~= 0
    end

    local function member(p38) -- line: 367
        -- upvalues: p33 (copy)
        for _, v78 in p38 do
            if string.lower(v78) == string.lower(p33) then
                return true
            end
        end

        return false
    end

    if bit32.band(p34, 32) ~= 0 then
        local v79 = false
        local v80

        for _, v81 in { "FingerFlip", "FS_Varial", "BS_Varial" } do
            if string.lower(v81) == string.lower(p33) then
                v80 = true
                v79 = true
                break
            end
        end

        if not v79 then
            v80 = false
        end

        if v80 then
            return false
        end
    end

    if bit32.band(p34, 16) ~= 0 then
        if p35 == 200 or p35 == 201 then
            return false
        end

        local v82 = false
        local v83

        for _, v84 in { "L_F_Kickflip", "L_B_Kickflip", "L_F_Heelflip", "L_B_Heelflip", "L_FS_Shuvit", "L_BS_Shuvit" } do
            if string.lower(v84) == string.lower(p33) then
                v83 = true
                v82 = true
                break
            end
        end

        if not v82 then
            v83 = false
        end

        if v83 then
            return false
        end
    end

    local v85 = false
    local v86

    for _, v87 in { "FrontFlip", "BackFlip" } do
        if string.lower(v87) == string.lower(p33) then
            v86 = true
            v85 = true
            break
        end
    end

    if not v85 then
        v86 = false
    end

    if v86 and (not IntentMap.contains_key(p36, "RightAirGrab") and not IntentMap.contains_key(p36, "LeftAirGrab") or IntentMap.contains_key(p36, "LeftPush") or IntentMap.contains_key(p36, "RightPush") or bit32.band(p34, 8) ~= 0) then
        return false
    end

    if bit32.band(p34, 256) ~= 0 then
        local v88 = false
        local v89

        for _, v90 in { "SlideFs180", "SlideBs180" } do
            if string.lower(v90) == string.lower(p33) then
                v89 = true
                v88 = true
                break
            end
        end

        if not v88 then
            v89 = false
        end

        if v89 then
            return false
        end
    end

    if bit32.band(p34, 4096) ~= 0 then
        local v91 = false
        local v92

        for _, v93 in {
                "Ollie",
                "Kickflip",
                "Heelflip",
                "Hardflip",
                "InwardHeelflip",
                "VarialKickflip",
                "VarialHeelflip",
                "PopShuvit",
                "FSPopShuvit",
                "360PopShuvit",
                "FS360PopShuvit"
            } do
            if string.lower(v93) == string.lower(p33) then
                v92 = true
                v91 = true
                break
            end
        end

        if not v91 then
            v92 = false
        end

        if not v92 then
            return false
        end
    end

    return true
end

return t1
