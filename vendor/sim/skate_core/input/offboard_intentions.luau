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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p4) -- line: 28
    -- upvalues: v1 (copy)
    if p4 ~= 0 and p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
        local v9 = math.abs(p4) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p4 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p4)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v12 = import("skate_core/input/controller")
local v13 = import("skate_core/physics/reciprocal_sqrt")
local DerivedControllerInput = v12.DerivedControllerInput
local t1 = {}

t1.OffboardIntent = {}

function t1.OffboardIntent.eq(p5, p6) -- line: 52
    if p5.name == p6.name then
        return p5.value == p6.value
    end

    return false
end

function t1.produce_discrete(p7, p8, p9) -- line: 60
    -- upvalues: v1 (copy), DerivedControllerInput (copy)
    local v14 = DerivedControllerInput.words(p7)
    local v15 = v14[7]
    local v16 = v14[14]

    local function axis(p10) -- line: 64
        -- upvalues: v14 (copy), v1 (copy)
        buffer.writeu32(v1, 0, v14[p10 + 1])

        return (buffer.readf32(v1, 0))
    end

    local function held(p11) -- line: 67
        -- upvalues: v16 (copy)
        return bit32.band(v16, (bit32.lshift(1, p11))) ~= 0
    end

    local function rising(p12) -- line: 70
        -- upvalues: v15 (copy), v16 (copy)
        local v20 = bit32.band(v16, (bit32.lshift(1, p12))) ~= 0

        v20 = v20 and bit32.band(v15, (bit32.lshift(1, p12))) == 0

        return v20
    end

    local t2 = {}

    local function emit(p13, p14) -- line: 74
        -- upvalues: t2 (copy)
        table.insert(t2, {
            name = p13,
            value = p14
        })
    end

    if bit32.band(v16, 8388608) ~= 0 and bit32.band(v15, 8388608) == 0 then
        table.insert(t2, {
            name = "OB_Jump",
            value = 1
        })
    end

    buffer.writeu32(v1, 0, v14[10])

    local v23 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v14[11])

    local v25 = buffer.readf32(v1, 0)

    if v23 ~= 0 then
        table.insert(t2, {
            name = "OB_LookAtX",
            value = v23
        })
    end

    if v25 ~= 0 then
        table.insert(t2, {
            name = "OB_LookAtY",
            value = v25
        })
    end

    buffer.writeu32(v1, 0, v14[5])

    local v27

    if buffer.readf32(v1, 0) == 1 then
        v27 = false
    else
        buffer.writeu32(v1, 0, v14[12])
        v27 = buffer.readf32(v1, 0) == 1
    end

    buffer.writeu32(v1, 0, v14[6])

    local v30

    if buffer.readf32(v1, 0) == 1 then
        v30 = false
    else
        buffer.writeu32(v1, 0, v14[13])
        v30 = buffer.readf32(v1, 0) == 1
    end

    if v27 then
        table.insert(t2, {
            name = "OB_DropBoard",
            value = 1
        })
    end

    if v30 then
        table.insert(t2, {
            name = "OB_ThrowBoard",
            value = 1
        })
    end

    if v27 or v30 then
        table.insert(t2, {
            name = "OB_RetrieveBoard",
            value = 1
        })
    end

    if bit32.band(v16, 268435456) ~= 0 or bit32.band(v16, 1073741824) ~= 0 then
        table.insert(t2, {
            name = "OB_DoAirBodyTweak",
            value = 1
        })
    end

    table.insert(t2, {
        name = "OB_AirBodyTweakX",
        value = v23
    })
    table.insert(t2, {
        name = "OB_AirBodyTweakY",
        value = v25
    })

    if not p9 and bit32.band(v16, 536870912) == 0 and bit32.band(v16, 4194304) ~= 0 then
        local v32 = bit32.band(v16, 4194304) ~= 0 and bit32.band(v15, 4194304) == 0
        local v33

        if not v32 then
            buffer.writeu32(v1, 0, v14[24])
            v33 = buffer.readf32(v1, 0) >= 0.029999999329447746
        end

        if (v32 or not v33) and bit32.band(p8, 1024) == 0 then
            table.insert(t2, {
                name = "NewToggleOffBoardState",
                value = 1
            })
        end

        table.insert(t2, {
            name = "ToggleOffBoardState",
            value = 1
        })
    end

    buffer.writeu32(v1, 0, v14[22])

    if not (buffer.readf32(v1, 0) > 0) then
        buffer.writeu32(v1, 0, v14[21])

        if buffer.readf32(v1, 0) > 0 then
            table.insert(t2, {
                name = "OB_Sprint",
                value = 1
            })
        end
    end

    return t2
end

t1.AnalogObservation = {}

function t1.AnalogObservation.eq(p15, p16) -- line: 135
    if p15.effective_skeleton_z[1] ~= p16.effective_skeleton_z[1] or p15.effective_skeleton_z[2] ~= p16.effective_skeleton_z[2] or p15.effective_skeleton_z[3] ~= p16.effective_skeleton_z[3] or p15.effective_skeleton_z[4] ~= p16.effective_skeleton_z[4] or p15.biped_correction == nil ~= (p16.biped_correction == nil) then
        return false
    end

    if p15.biped_correction ~= nil and (p15.biped_correction[1] ~= p16.biped_correction[1] or p15.biped_correction[2] ~= p16.biped_correction[2] or p15.biped_correction[3] ~= p16.biped_correction[3] or p15.biped_correction[4] ~= p16.biped_correction[4]) then
        return false
    end

    return true
end

function t1.produce_analog(p17, p18) -- line: 156
    -- upvalues: rt (copy), v1 (copy), v12 (copy), t1 (copy), DerivedControllerInput (copy)
    local v37 = DerivedControllerInput.words(p17)

    buffer.writeu32(v1, 0, v37[8])

    local v39 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v37[9])

    local t16 = {
        v39,
        0,
        buffer.readf32(v1, 0),
        0
    }
    local v41 = rt.copy(p18.effective_skeleton_z)

    v41[2] = 0

    local v42 = t1.safe_unit(v41)
    local v43

    if p18.biped_correction ~= nil then
        local v44 = rt.copy(p18.biped_correction)
        local v45 = rt.map(v44, function(p19) -- line: 165
            -- upvalues: v1 (copy)
            local v46

            if p19 ~= 0 and p19 > -1.1754943508222875E-38 and p19 < 1.1754943508222875E-38 then
                local v47 = math.abs(p19) * 7.1362384635298E+44
                local v48 = math.floor(v47)
                local v49 = v47 - v48

                v46 = if v49 > 0.5 or v49 == 0.5 and v48 % 2 == 1 then v48 + 1 else v48

                if p19 < 0 then
                    v46 += 2147483648
                end
            else
                buffer.writef32(v1, 0, p19)
                v46 = buffer.readu32(v1, 0)
            end

            buffer.writeu32(v1, 0, (bit32.bxor(v46, 2147483648)))

            return (buffer.readf32(v1, 0))
        end)
        local v51 = t1.dot(t16, v45)

        if -v51 >= 0 then
            v51 = 0
        end

        if not (1 - v51 >= 0) then
            v51 = 1
        end

        if t1.dot(t1.safe_unit(t16), v45) <= 0.8999999761581421 then
            local t17 = {
                v44[1] * v51 + t16[1],
                v44[2] * v51 + t16[2],
                v44[3] * v51 + t16[3],
                v44[4] * v51 + t16[4]
            }

            v43 = t1.dot(v42, t17)
        else
            v43 = 0
        end
    else
        v43 = t1.dot(v42, t16)
    end

    return {
        {
            name = "OB_Mag",
            value = v43
        },
        {
            name = "OB_BipedWorldZ",
            value = t16[3]
        },
        {
            name = "OB_BipedWorldX",
            value = t16[1]
        },
        {
            name = "OB_BipedStickMag",
            value = v12.magnitude(t1.dot(t16, t16))
        }
    }
end

function t1.dot(p20, p21) -- line: 194
    return p20[1] * p21[1] + p20[2] * p21[2] + p20[3] * p21[3]
end

function t1.safe_unit(p22) -- line: 198
    -- upvalues: rt (copy), v1 (copy), v13 (copy), t1 (copy)
    local v52 = t1.dot(p22, p22)
    local v53

    if v52 ~= 0 and v52 > -1.1754943508222875E-38 and v52 < 1.1754943508222875E-38 then
        local v54 = math.abs(v52) * 7.1362384635298E+44
        local v55 = math.floor(v54)
        local v56 = v54 - v55

        v53 = (if v56 > 0.5 or v56 == 0.5 and v55 % 2 == 1 then v55 + 1 else v55) * 1.401298464324817E-45

        if v52 < 0 then
            v53 = -v53
        end
    else
        buffer.writef32(v1, 0, v52)
        v53 = buffer.readf32(v1, 0)
    end

    local v57 = v13.estimate(v53)
    local v58 = -v53 * (v57 * v57) + 1
    local v59 = v57 * 0.5 * v58 + v57
    local v60 = -v53 * (v59 * v59) + 1
    local v61 = v59 * 0.5 * v60 + v59

    if (if v53 == 0 then 0 else v53 * v61) > 9.999999974752427E-07 then
        return rt.map(p22, function(p23) -- line: 208
            -- upvalues: v61 (copy)
            return p23 * v61
        end)
    end

    return table.create(4, 0)
end

return t1
