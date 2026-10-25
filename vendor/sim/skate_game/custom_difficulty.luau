-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_fround(p3) -- line: 24
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v9 = math.abs(p3) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p3 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p4) -- line: 32
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

local import = require(sim.import)
local HttpService = game:GetService("HttpService")
local Collections = import("skate_data/collections").Collections
local Difficulty = import("skate_game/difficulty").Difficulty
local t1 = {
    OptionSpec = {}
}

local function number(p5, p6, p7, p8, p9) -- line: 55
    return {
        boolean = false,
        key = p5,
        label = p6,
        description = p7,
        max = p8,
        step = p9
    }
end

local function toggle(p10, p11, p12) -- line: 59
    return {
        max = 1,
        step = 1,
        boolean = true,
        key = p10,
        label = p11,
        description = p12
    }
end

t1.OPTIONS = {
    {
        key = "MotorEnabled",
        label = "Motor assistance",
        description = "Hold RB on suitable ground to drive toward the motor target speed.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "MotorTopSpeed",
        label = "Motor target speed (km/h)",
        description = "Target speed while motor assistance is enabled and RB is held.",
        max = 2000,
        step = 1,
        boolean = false
    },
    {
        key = "AutoPushEnabled",
        label = "Automatic pushing",
        description = "Enable the native automatic-push behavior.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "HostPushStrength",
        label = "Push strength (x)",
        description = "Multiplies the speed gain requested by each push animation. 1x is stock. Push limits and the normal pushing speed ceiling still apply.",
        max = 100,
        step = 0.25,
        boolean = false
    },
    {
        key = "MaxPushDVStart",
        label = "Push increase limit at low speed (m/s)",
        description = "Caps the requested speed gain at low speed. Raising this alone does not make a push stronger; use Push strength.",
        max = 100,
        step = 0.05,
        boolean = false
    },
    {
        key = "MaxPushDVEnd",
        label = "Push increase limit at high speed (m/s)",
        description = "Caps the requested speed gain at high speed. Raising this alone does not make a push stronger; use Push strength.",
        max = 100,
        step = 0.05,
        boolean = false
    },
    {
        key = "PumpEffectFactor",
        label = "Pumping acceleration strength",
        description = "Scales speed gained by pumping transitions.",
        max = 600,
        step = 0.5,
        boolean = false
    },
    {
        key = "PumpEffectFactorAbsorption",
        label = "Pumping speed absorption",
        description = "Scales speed absorbed when compressing through transitions.",
        max = 300,
        step = 0.25,
        boolean = false
    },
    {
        key = "Hash_D77AFD320B6241C5",
        label = "Pumping acceleration limit",
        description = "Maximum acceleration per second allowed by the pumping controller.",
        max = 400,
        step = 0.25,
        boolean = false
    },
    {
        key = "Hash_09D1AEE3D7D8A4A7",
        label = "Pumping absorption limit",
        description = "Maximum speed absorption per second allowed by the pumping controller.",
        max = 400,
        step = 0.25,
        boolean = false
    },
    {
        key = "UnintentionalPumpScalar",
        label = "Unintentional pumping strength",
        description = "Scales pumping generated without the intentional-pump input.",
        max = 30,
        step = 0.05,
        boolean = false
    },
    {
        key = "JumpHeightOverrideEnabled",
        label = "Difficulty jump-height override",
        description = "Allow difficulty jump-height settings to override animation-provided heights.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "JumpMinHeight",
        label = "Minimum regular jump height (m)",
        description = "Lower height endpoint for regular jumps; speed curves also affect the result.",
        max = 60,
        step = 0.05,
        boolean = false
    },
    {
        key = "Hash_BE3F74F978D777E5",
        label = "Minimum jump from manual (m)",
        description = "Lower jump-height endpoint when the animation marks the trick as starting from a manual.",
        max = 60,
        step = 0.05,
        boolean = false
    },
    {
        key = "JumpMaxHeight",
        label = "Maximum jump height (m)",
        description = "Upper jump-height endpoint; speed curves also affect the result.",
        max = 80,
        step = 0.05,
        boolean = false
    },
    {
        key = "GrindLockDist",
        label = "Grind targeting distance (m)",
        description = "Distance used by airborne grind targeting. Larger values allow more assistance.",
        max = 50,
        step = 0.05,
        boolean = false
    },
    {
        key = "Hash_3097A69281990652",
        label = "Standard grind pop - low strength",
        description = "Lower vertical pop endpoint for 50-50, 5-0, backslash and darkslide exits.",
        max = 100,
        step = 0.05,
        boolean = false
    },
    {
        key = "Hash_FA4CDBAE0DFD1FAD",
        label = "Standard grind pop - high strength",
        description = "Upper vertical pop endpoint for 50-50, 5-0, backslash and darkslide exits.",
        max = 100,
        step = 0.05,
        boolean = false
    },
    {
        key = "Hash_B2B1170AFFC8AC69",
        label = "Boardslide pop - low strength",
        description = "Lower vertical pop endpoint when exiting a boardslide.",
        max = 100,
        step = 0.05,
        boolean = false
    },
    {
        key = "Hash_1B3E9F9C836D287D",
        label = "Boardslide pop - high strength",
        description = "Upper vertical pop endpoint when exiting a boardslide.",
        max = 100,
        step = 0.05,
        boolean = false
    },
    {
        key = "Hash_703829BD711E54DE",
        label = "Tipslide pop - low strength",
        description = "Lower vertical pop endpoint when exiting a nose/tail tipslide.",
        max = 100,
        step = 0.05,
        boolean = false
    },
    {
        key = "Hash_0F2473E9125079F0",
        label = "Tipslide pop - high strength",
        description = "Upper vertical pop endpoint when exiting a nose/tail tipslide.",
        max = 100,
        step = 0.05,
        boolean = false
    },
    {
        key = "EasyBodySpins",
        label = "Assisted body spins",
        description = "Enable the easier native airborne body-spin behavior.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "PerfectBodyFlips",
        label = "Assisted body flips",
        description = "Enable native perfect-flip assistance.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "MaxAutoBodySpinSpeed",
        label = "Automatic body-spin speed limit",
        description = "Maximum speed used by the automatic airborne body-spin calculation.",
        max = 300,
        step = 0.25,
        boolean = false
    },
    {
        key = "Hash_77AFCE78FE1206CA",
        label = "Speed wobble onset",
        description = "Speed threshold used to activate the board wobble system.",
        max = 600,
        step = 0.5,
        boolean = false
    },
    {
        key = "Hash_5B57F2CCCCEEF430",
        label = "Speed wobble strength",
        description = "Amplitude of board wobble above its activation threshold. Zero disables its amplitude.",
        max = 30,
        step = 0.05,
        boolean = false
    },
    {
        key = "Hash_84CB2F459F3FC811",
        label = "Manual correction angular-speed threshold",
        description = "Angular-speed threshold used by the manual balance correction calculation.",
        max = 200,
        step = 0.1,
        boolean = false
    },
    {
        key = "Hash_F8CBC0F5FEF2240E",
        label = "Manual corrective force",
        description = "Enable the native corrective-force branch during manuals.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "Hash_5548109D7B0CB70C",
        label = "Forgiving surface response",
        description = "Remap native surface categories using Easy's surface-assistance rule.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "WipeoutCheckForBadLanding",
        label = "Bail on bad landings",
        description = "Enable the bad-landing wipeout check.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "Hash_D978550D6DB4E6F7",
        label = "Bad-landing check scale",
        description = "Scales the native bad-landing check; this is not a general damage multiplier.",
        max = 50,
        step = 0.05,
        boolean = false
    },
    {
        key = "Wipeout_GroundXZAcceleration",
        label = "Ground-impact bail threshold",
        description = "Horizontal acceleration threshold used by ground wipeout checks.",
        max = 400,
        step = 0.1,
        boolean = false
    },
    {
        key = "Hash_CC890A3BDCF6290A",
        label = "Bail when compressed",
        description = "Enable the native squash/compression wipeout check.",
        max = 1,
        step = 1,
        boolean = true
    },
    {
        key = "Hash_2B913C786BEFF4CD",
        label = "Bail when falling upside down",
        description = "Enable the airborne upside-down falling wipeout check.",
        max = 1,
        step = 1,
        boolean = true
    }
}

local OPTIONS = t1.OPTIONS

local function find_option(p13) -- line: 103
    -- upvalues: OPTIONS (copy)
    for _, v12 in ipairs(OPTIONS) do
        if v12.key == p13 then
            return v12
        end
    end

    return nil
end

local function sorted_keys(p14) -- line: 113
    local t2 = {}

    for v13 in p14 do
        table.insert(t2, v13)
    end

    table.sort(t2)

    return t2
end

local function with_file_name(p15, p16) -- line: 123
    local v14 = #p15
    local n1 = 0

    for i = v14, 1, -1 do
        local v15 = string.sub(p15, i, i)

        if v15 == "/" or v15 == "\\" then
            n1 = i
            break
        end
    end

    return string.sub(p15, 1, n1) .. p16
end

local function f32_json(p17) -- line: 137
    -- upvalues: v1 (copy)
    local v16

    if p17 ~= 0 and p17 > -1.1754943508222875E-38 and p17 < 1.1754943508222875E-38 then
        local v17 = math.abs(p17) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = (if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18) * 1.401298464324817E-45

        if p17 < 0 then
            v16 = -v16
        end
    else
        buffer.writef32(v1, 0, p17)
        v16 = buffer.readf32(v1, 0)
    end

    if v16 ~= v16 or v16 == 1e999 or v16 == (-1e999) then
        return "null"
    end

    local v20 = string.format("%.9g", v16)

    for i = 0, 12 do
        local v21 = string.format("%." .. i .. "f", v16)
        local v22 = tonumber(v21)
        local v23

        if v22 ~= 0 and v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
            local v24 = math.abs(v22) * 7.1362384635298E+44
            local v25 = math.floor(v24)
            local v26 = v24 - v25

            v23 = (if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25) * 1.401298464324817E-45

            if v22 < 0 then
                v23 = -v23
            end
        else
            buffer.writef32(v1, 0, v22)
            v23 = buffer.readf32(v1, 0)
        end

        if v23 == v16 then
            v20 = v21
            break
        end
    end

    if not string.find(v20, "[%.eE]") then
        v20 ..= ".0"
    end

    return v20
end

t1.Tuning = {}

local Tuning = t1.Tuning

function t1.Tuning.default() -- line: 162
    return {
        values = {}
    }
end

function t1.Tuning.from_json(p18) -- line: 167
    -- upvalues: v1 (copy), HttpService (copy)
    local function v27() -- line: 168
        -- upvalues: p18 (copy), HttpService (copy)
        return HttpService:JSONDecode(p18)
    end

    local ok, result = pcall(v27)

    if not ok then
        error(tostring(result), 0)
    end

    if type(result) ~= "table" then
        error("invalid type: expected struct Tuning", 0)
    end

    for v28 in result do
        if v28 ~= "values" then
            error("unknown field `" .. tostring(v28) .. "`, expected `values`", 0)
        end
    end

    if type(result.values) ~= "table" then
        error("missing field `values`", 0)
    end

    local t3 = {}

    for v29, v30 in result.values do
        if type(v29) ~= "string" or type(v30) ~= "number" then
            error("invalid type: expected a map of f32", 0)
        end

        local v31

        if v30 == 0 then
            buffer.writef32(v1, 0, v30)
            v31 = buffer.readf32(v1, 0)
        elseif v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
            local v32 = math.abs(v30) * 7.1362384635298E+44
            local v33 = math.floor(v32)
            local v34 = v32 - v33

            if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then
                v33 += 1
            end

            v31 = v33 * 1.401298464324817E-45

            if v30 < 0 then
                v31 = -v31
            end
        else
            buffer.writef32(v1, 0, v30)
            v31 = buffer.readf32(v1, 0)
        end

        t3[v29] = v31
    end

    return {
        values = t3
    }
end

function t1.Tuning.to_json(p19, p20) -- line: 196
    -- upvalues: HttpService (copy), f32_json (copy)
    local t4 = {}
    local _ipairs = ipairs
    local t5 = {}

    for v35 in p19.values do
        table.insert(t5, v35)
    end

    table.sort(t5)

    for _, v36 in _ipairs(t5) do
        local v37 = HttpService:JSONEncode(v36)

        if p20 then
            table.insert(t4, "    " .. v37 .. ": " .. f32_json(p19.values[v36]))
        else
            table.insert(t4, v37 .. ":" .. f32_json(p19.values[v36]))
        end
    end

    if not p20 then
        return "{\"values\":{" .. table.concat(t4, ",") .. "}}"
    end

    if #t4 == 0 then
        return "{\n  \"values\": {}\n}"
    end

    return "{\n  \"values\": {\n" .. table.concat(t4, ",\n") .. "\n  }\n}"
end

function t1.Tuning.defaults(p21) -- line: 216
    -- upvalues: Collections (copy), OPTIONS (copy)
    local t6 = {}

    for _, v40 in ipairs(OPTIONS) do
        local v41 = if v40.key == "HostPushStrength" then 1
            elseif not v40.boolean then Collections.float(p21, "physics_mode", "easy", v40.key)
            elseif Collections.boolean(p21, "physics_mode", "easy", v40.key) then 1
            else 0

        t6[v40.key] = v41
    end

    return {
        values = t6
    }
end

function t1.Tuning.load(p22, p23, p24) -- line: 235
    -- upvalues: Difficulty (copy), with_file_name (copy), Tuning (copy)
    local v42 = Tuning.defaults(p23)

    with_file_name(Difficulty.path(p22), "custom-difficulty.json")

    if p24 ~= nil then
        local from_json = Tuning.from_json
        local ok, result = pcall(from_json, p24)

        if not ok then
            error("Custom difficulty: " .. tostring(result), 0)
        end

        Tuning.validate(result)

        for v43, v44 in result.values do
            v42.values[v43] = v44
        end
    end

    return v42
end

function t1.Tuning.validate(p25) -- line: 252
    -- upvalues: OPTIONS (copy)
    local _ipairs = ipairs
    local t7 = {}

    for v45 in p25.values do
        table.insert(t7, v45)
    end

    table.sort(t7)

    for _, v46 in _ipairs(t7) do
        local v47 = p25.values[v46]
        local v48 = false
        local v49

        for _, v50 in ipairs(OPTIONS) do
            if v50.key == v46 then
                v49 = v50
                v48 = true
                break
            end
        end

        if not v48 then
            v49 = nil
        end

        if v49 == nil then
            error("Unknown custom difficulty field: " .. v46, 0)
        end

        if v47 ~= v47
            or v47 == 1e999
            or v47 == (-1e999)
            or v47 < 0
            or v49.max < v47
            or v49.boolean and v47 ~= 0 and v47 ~= 1 then
            error("Invalid value for " .. v49.label, 0)
        end
    end
end

function t1.Tuning.save(p26, p27) -- line: 273
    -- upvalues: Difficulty (copy), with_file_name (copy), Tuning (copy)
    Tuning.validate(p26)

    return with_file_name(Difficulty.path(p27), "custom-difficulty.json"), Tuning.to_json(p26, true)
end

function t1.Tuning.overlay(p28, p29) -- line: 280
    -- upvalues: rt (copy), v1 (copy), Collections (copy), OPTIONS (copy), Tuning (copy)
    Tuning.validate(p28)

    local t8 = {}
    local _ipairs = ipairs
    local t9 = {}

    for v51 in p28.values do
        table.insert(t9, v51)
    end

    table.sort(t9)

    for _, v52 in _ipairs(t9) do
        local v53 = p28.values[v52]
        local v54 = false
        local v55

        for _, v56 in ipairs(OPTIONS) do
            if v56.key == v52 then
                v55 = v56
                v54 = true
                break
            end
        end

        if not v54 then
            v55 = nil
        end

        if v55 == nil then
            error("called `Option::unwrap()` on a `None` value", 0)
        end

        local t10 = {}

        t10.type_name = v55.boolean and "EA::Reflection::Bool" or "EA::Reflection::Float"

        if v55.boolean then
            t10.data = string.format("%02X", rt.f_to_int(v53, 0, 255))
        else
            local format = string.format
            local v57

            if v53 == 0 then
                buffer.writef32(v1, 0, v53)
                v57 = buffer.readu32(v1, 0)
            elseif v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
                local v58 = math.abs(v53) * 7.1362384635298E+44

                v57 = math.floor(v58)

                local v59 = v58 - v57

                if v59 > 0.5 or v59 == 0.5 and v57 % 2 == 1 then
                    v57 += 1
                end

                if v53 < 0 then
                    v57 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v53)
                v57 = buffer.readu32(v1, 0)
            end

            t10.data = format("%08X", v57)
        end

        t8[v52] = t10
    end

    return Collections.override_profile(p29, "physics_mode", "test", "easy", t8)
end

function t1.Tuning.value(p30, p31) -- line: 300
    -- upvalues: OPTIONS (copy)
    local v60 = p30.values[OPTIONS[p31 + 1].key]

    if v60 == nil then
        return 0
    end

    return v60
end

function t1.Tuning.adjust(p32, p33, p34) -- line: 310
    -- upvalues: rt (copy), v1 (copy), OPTIONS (copy), Tuning (copy)
    local v61 = OPTIONS[p33 + 1]
    local v62 = Tuning.value(p32, p33)
    local v63

    if v61.boolean then
        v63 = 1 - v62
    else
        local clamp = rt.clamp
        local step = v61.step
        local v64

        if step == 0 then
            buffer.writef32(v1, 0, step)
            v64 = buffer.readf32(v1, 0)
        elseif step > -1.1754943508222875E-38 and step < 1.1754943508222875E-38 then
            local v65 = math.abs(step) * 7.1362384635298E+44
            local v66 = math.floor(v65)
            local v67 = v65 - v66

            if v67 > 0.5 or v67 == 0.5 and v66 % 2 == 1 then
                v66 += 1
            end

            v64 = v66 * 1.401298464324817E-45

            if step < 0 then
                v64 = -v64
            end
        else
            buffer.writef32(v1, 0, step)
            v64 = buffer.readf32(v1, 0)
        end

        local v68 = p34 * v64
        local v69

        if v68 ~= 0 and v68 > -1.1754943508222875E-38 and v68 < 1.1754943508222875E-38 then
            local v70 = math.abs(v68) * 7.1362384635298E+44
            local v71 = math.floor(v70)
            local v72 = v70 - v71

            v69 = (if v72 > 0.5 or v72 == 0.5 and v71 % 2 == 1 then v71 + 1 else v71) * 1.401298464324817E-45

            if v68 < 0 then
                v69 = -v69
            end
        else
            buffer.writef32(v1, 0, v68)
            v69 = buffer.readf32(v1, 0)
        end

        local v73 = v62 + v69
        local v74

        if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
            local v75 = math.abs(v73) * 7.1362384635298E+44
            local v76 = math.floor(v75)
            local v77 = v75 - v76

            v74 = (if v77 > 0.5 or v77 == 0.5 and v76 % 2 == 1 then v76 + 1 else v76) * 1.401298464324817E-45

            if v73 < 0 then
                v74 = -v74
            end
        else
            buffer.writef32(v1, 0, v73)
            v74 = buffer.readf32(v1, 0)
        end

        v63 = clamp(v74, 0, v61.max)
    end

    p32.values[v61.key] = v63
end

function t1.Tuning.set_fraction(p35, p36, p37) -- line: 323
    -- upvalues: rt (copy), v1 (copy), OPTIONS (copy)
    local v78 = OPTIONS[p36 + 1]
    local step = v78.step
    local v79

    if step ~= 0 and step > -1.1754943508222875E-38 and step < 1.1754943508222875E-38 then
        local v80 = math.abs(step) * 7.1362384635298E+44
        local v81 = math.floor(v80)
        local v82 = v80 - v81

        v79 = (if v82 > 0.5 or v82 == 0.5 and v81 % 2 == 1 then v81 + 1 else v81) * 1.401298464324817E-45

        if step < 0 then
            v79 = -v79
        end
    else
        buffer.writef32(v1, 0, step)
        v79 = buffer.readf32(v1, 0)
    end

    local round = rt.round
    local v83 = rt.clamp(p37, 0, 1) * v78.max
    local v84

    if v83 ~= 0 and v83 > -1.1754943508222875E-38 and v83 < 1.1754943508222875E-38 then
        local v85 = math.abs(v83) * 7.1362384635298E+44
        local v86 = math.floor(v85)
        local v87 = v85 - v86

        v84 = (if v87 > 0.5 or v87 == 0.5 and v86 % 2 == 1 then v86 + 1 else v86) * 1.401298464324817E-45

        if v83 < 0 then
            v84 = -v84
        end
    else
        buffer.writef32(v1, 0, v83)
        v84 = buffer.readf32(v1, 0)
    end

    local v88 = v84 / v79
    local v89

    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
        local v90 = math.abs(v88) * 7.1362384635298E+44
        local v91 = math.floor(v90)
        local v92 = v90 - v91

        v89 = (if v92 > 0.5 or v92 == 0.5 and v91 % 2 == 1 then v91 + 1 else v91) * 1.401298464324817E-45

        if v88 < 0 then
            v89 = -v89
        end
    else
        buffer.writef32(v1, 0, v88)
        v89 = buffer.readf32(v1, 0)
    end

    local v93 = round(v89)
    local clamp = rt.clamp
    local v94 = v93 * v79
    local v95

    if v94 ~= 0 and v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
        local v96 = math.abs(v94) * 7.1362384635298E+44
        local v97 = math.floor(v96)
        local v98 = v96 - v97

        v95 = (if v98 > 0.5 or v98 == 0.5 and v97 % 2 == 1 then v97 + 1 else v97) * 1.401298464324817E-45

        if v94 < 0 then
            v95 = -v95
        end
    else
        buffer.writef32(v1, 0, v94)
        v95 = buffer.readf32(v1, 0)
    end

    local v99 = clamp(v95, 0, v78.max)

    p35.values[v78.key] = v99
end

function t1.Tuning.label(p38, p39) -- line: 332
    -- upvalues: v1 (copy), OPTIONS (copy), Tuning (copy)
    local v100 = OPTIONS[p39 + 1]
    local v101 = Tuning.value(p38, p39)

    if v100.boolean then
        return v100.label .. "     " .. (if v101 == 0 then "Off" else "On")
    end

    local label = v100.label
    local format = string.format
    local v102

    if v101 == 0 or not (v101 > -1.1754943508222875E-38) or not (v101 < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, v101)
        v102 = buffer.readf32(v1, 0)

        return label .. "     " .. format("%.2f", v102)
    end

    local v103 = math.abs(v101) * 7.1362384635298E+44
    local v104 = math.floor(v103)
    local v105 = v103 - v104

    v102 = (if v105 > 0.5 or v105 == 0.5 and v104 % 2 == 1 then v104 + 1 else v104) * 1.401298464324817E-45

    if v101 < 0 then
        v102 = -v102
    end

    return label .. "     " .. format("%.2f", v102)
end

function t1.load_collections(p40, p41) -- line: 345
    -- upvalues: Collections (copy), Tuning (copy)
    local v106 = Collections.load(p40)

    Tuning.overlay(Tuning.load(p40, v106, p41), v106)

    return v106
end

return t1
