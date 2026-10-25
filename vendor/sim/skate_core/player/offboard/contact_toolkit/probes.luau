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
local v9

local function toolkit() -- line: 30
    -- upvalues: import (copy), v9 (ref)
    if v9 == nil then
        v9 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v9
end

local function cross(p3, p4) -- line: 36
    -- upvalues: import (copy), v9 (ref)
    if v9 == nil then
        v9 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v9.cross(p3, p4)
end

local t1 = {
    Input = {}
}

function t1.Input.from_vectors(p5) -- line: 56
    -- upvalues: rt (copy)
    return {
        position = rt.copy(p5[1]),
        forward = rt.copy(p5[2]),
        up = rt.copy(p5[3]),
        right = rt.copy(p5[4]),
        velocity = rt.copy(p5[5]),
        animation_up = rt.copy(p5[6]),
        animation_right = rt.copy(p5[7])
    }
end

t1.LineProbe = {}

function t1.LineProbe.eq(p6, p7) -- line: 72
    for i = 1, 4 do
        if p6.start[i] ~= p7.start[i] or p6["end"][i] ~= p7["end"][i] then
            return false
        end
    end

    return p6.radius == p7.radius
end

t1.Descriptor = {}

function t1.Descriptor.eq(p8, p9) -- line: 85
    -- upvalues: t1 (copy)
    return t1.LineProbe.eq(p8.line, p9.line) and p8.forward_index == p9.forward_index and p8.reverse_index == p9.reverse_index
end

t1.ProbeLayout = {}
t1.Batch = {}

function t1.probe(p10, p11, p12, p13, p14, p15, p16) -- line: 103
    return {
        start = { p10, p11, p12, 0 },
        ["end"] = { p13, p14, p15, 0 },
        radius = p16
    }
end

local probe2 = t1.probe
local transform

function t1.ProbeLayout.stock() -- line: 114
    -- upvalues: v1 (copy), probe2 (copy)
    local t2 = {
        probe2(0, 1.2, 0, 0, -0.8, 0, 0.01),
        probe2(-0.12, 0.8, 0, -0.17, -0.2, 0, 0.03),
        probe2(0.12, 0.8, 0, 0.17, -0.2, 0, 0.03)
    }
    local t3 = {}

    buffer.writef32(v1, 0, 0.037500001)

    local v10 = 0
    local v11 = buffer.readf32(v1, 0)

    repeat
        table.insert(t3, {
            reverse_index = nil,
            line = probe2(0, 0.8, v11, 0, -0.8, v11, 0),
            forward_index = v10
        })
        v10 += 1
        buffer.writef32(v1, 0, 0.075000003)

        local v12 = v11 + buffer.readf32(v1, 0)

        if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
            local v13 = math.abs(v12) * 7.1362384635298E+44
            local v14 = math.floor(v13)
            local v15 = v13 - v14

            v11 = (if v15 > 0.5 or v15 == 0.5 and v14 % 2 == 1 then v14 + 1 else v14) * 1.401298464324817E-45

            if v12 < 0 then
                v11 = -v11
            end
        else
            buffer.writef32(v1, 0, v12)
            v11 = buffer.readf32(v1, 0)
        end

        buffer.writef32(v1, 0, 1.7624999)
    until not (v11 < buffer.readf32(v1, 0))

    local t5 = {}

    for i = 0, 11 do
        local v16 = i * 0.090909094
        local v17 = v16 * 0.8 - (1 - v16) * 0.8
        local v18 = if v17 < 0 then v10 + 1 else nil

        table.insert(t5, {
            line = probe2(0, v17, 0, 0, v17, 1.8, 0),
            forward_index = v10,
            reverse_index = v18
        })
        v10 += if v18 == nil then 1 else 2
    end

    for i = 0, 2 do
        local v19 = (i * 2 + 1) * 0.099999994 + 0.8

        table.insert(t5, {
            reverse_index = nil,
            line = probe2(0, v19, 0.099999994, 0, v19, 1.6999999, 0.099999994),
            forward_index = v10
        })
        v10 += 1
    end

    return {
        trajectories = t2,
        secondary = t3,
        primary = t5
    }
end

local v20 = false

function t1.set_reference(p17) -- line: 171
    -- upvalues: v20 (ref)
    v20 = p17
end

function t1.ProbeLayout.prepare(p18, p19, p20) -- line: 183
    -- upvalues: rt (copy), import (copy), v9 (ref), t1 (copy), transform (ref), v20 (ref)
    if v20 then
        return t1.ProbeLayout.prepare_reference(p18, p19, p20)
    end

    local t8 = {
        p19.right,
        p19.up,
        p19.forward,
        p19.position
    }
    local animation_right, animation_up, animation_right2, animation_up2 = p19.animation_right, p19.animation_up, p19.animation_right, p19.animation_up

    if v9 == nil then
        v9 = import("skate_core/player/offboard/contact_toolkit")
    end

    local t9 = {
        animation_right,
        animation_up,
        v9.cross(animation_right2, animation_up2),
        p19.position
    }
    local v22 = rt.from_fn(3, function(p21) -- line: 195
        -- upvalues: p18 (copy), t8 (copy), t9 (copy), rt (copy), import (copy), v9 (ref), transform (ref)
        local v23 = transform(p18.trajectories[p21 + 1], if p21 == 0 then t8 else t9)
        local t10 = {
            start_error = 0,
            end_error = 0
        }
        local t11 = {
            duration = 1,
            position = rt.copy(v23.start)
        }

        if v9 == nil then
            v9 = import("skate_core/player/offboard/contact_toolkit")
        end

        t11.velocity = v9.sub(v23["end"], v23.start)
        t11.acceleration = { 0, 0, 0, 0 }
        t10.trajectory = t11
        t10.radius = v23.radius

        return t10
    end)
    local right, up, forward, position2 = p19.right, p19.up, p19.forward, p19.position
    local v24 = right[1]
    local v25 = right[2]
    local v26 = right[3]
    local v27 = right[4]
    local v28 = up[1]
    local v29 = up[2]
    local v30 = up[3]
    local v31 = up[4]
    local v32 = forward[1]
    local v33 = forward[2]
    local v34 = forward[3]
    local v35 = forward[4]
    local v36 = position2[1]
    local v37 = position2[2]
    local v38 = position2[3]
    local v39 = position2[4]
    local t12 = {}
    local n1 = 0
    local v40, v41

    for i = 1, 2 do
        local v42 = if i == 1 then p18.secondary else p18.primary
        local v43 = table.create(#v42)

        for v44, v45 in v42 do
            local line = v45.line
            local start = line.start
            local v46 = start[1]
            local v47 = start[2]
            local v48 = start[3]
            local v49 = v32 * v48 + (v28 * v47 + (v24 * v46 + v36))
            local v50 = v33 * v48 + (v29 * v47 + (v25 * v46 + v37))
            local v51 = v34 * v48 + (v30 * v47 + (v26 * v46 + v38))
            local v52 = v35 * v48 + (v31 * v47 + (v27 * v46 + v39))
            local v53 = line["end"]
            local v54 = v53[1]
            local v55 = v53[2]
            local v56 = v53[3]
            local v57 = v32 * v56 + (v28 * v55 + (v24 * v54 + v36))
            local v58 = v33 * v56 + (v29 * v55 + (v25 * v54 + v37))
            local v59 = v34 * v56 + (v30 * v55 + (v26 * v54 + v38))
            local v60 = v35 * v56 + (v31 * v55 + (v27 * v54 + v39))
            local radius = line.radius

            n1 += 1
            t12[n1] = {
                start = { v49, v50, v51, v52 },
                ["end"] = { v57, v58, v59, v60 },
                radius = radius
            }

            local reverse_index = v45.reverse_index

            if reverse_index ~= nil then
                n1 += 1
                t12[n1] = {
                    start = { v57, v58, v59, v60 },
                    ["end"] = { v49, v50, v51, v52 },
                    radius = radius
                }
            end

            v43[v44] = {
                line = {
                    start = { v49, v50, v51, v52 },
                    ["end"] = { v57, v58, v59, v60 },
                    radius = radius
                },
                forward_index = v45.forward_index,
                reverse_index = reverse_index
            }
        end

        if i == 1 then
            v40 = v43
        else
            v41 = v43
        end
    end

    return {
        mesh_reject_mask = 24576,
        input = rt.copy(p19),
        matching_group = p20,
        trajectories = v22,
        lines = t12,
        secondary = v40,
        primary = v41
    }
end

function t1.ProbeLayout.prepare_reference(p22, p23, p24) -- line: 265
    -- upvalues: rt (copy), import (copy), v9 (ref), transform (ref)
    local t13 = {
        p23.right,
        p23.up,
        p23.forward,
        p23.position
    }
    local animation_right, animation_up, animation_right2, animation_up2 = p23.animation_right, p23.animation_up, p23.animation_right, p23.animation_up

    if v9 == nil then
        v9 = import("skate_core/player/offboard/contact_toolkit")
    end

    local t14 = {
        animation_right,
        animation_up,
        v9.cross(animation_right2, animation_up2),
        p23.position
    }
    local v62 = rt.from_fn(3, function(p25) -- line: 274
        -- upvalues: p22 (copy), t13 (copy), t14 (copy), rt (copy), import (copy), v9 (ref), transform (ref)
        local v63 = transform(p22.trajectories[p25 + 1], if p25 == 0 then t13 else t14)
        local t15 = {
            start_error = 0,
            end_error = 0
        }
        local t16 = {
            duration = 1,
            position = rt.copy(v63.start)
        }

        if v9 == nil then
            v9 = import("skate_core/player/offboard/contact_toolkit")
        end

        t16.velocity = v9.sub(v63["end"], v63.start)
        t16.acceleration = { 0, 0, 0, 0 }
        t15.trajectory = t16
        t15.radius = v63.radius

        return t15
    end)
    local t17 = {}

    local function prepare(p26) -- line: 289
        -- upvalues: t13 (copy), t17 (copy), rt (copy), transform (ref)
        local v64 = table.create(#p26)

        for v65, v66 in p26 do
            local v67 = transform(v66.line, t13)

            table.insert(t17, rt.copy(v67))

            if v66.reverse_index ~= nil then
                table.insert(t17, {
                    start = rt.copy(v67["end"]),
                    ["end"] = rt.copy(v67.start),
                    radius = v67.radius
                })
            end

            v64[v65] = {
                line = v67,
                forward_index = v66.forward_index,
                reverse_index = v66.reverse_index
            }
        end

        return v64
    end

    local v68 = prepare(p22.secondary)
    local v69 = prepare(p22.primary)

    return {
        mesh_reject_mask = 24576,
        input = rt.copy(p23),
        matching_group = p24,
        trajectories = v62,
        lines = t17,
        secondary = v68,
        primary = v69
    }
end

function t1.transform(p27, p28) -- line: 319
    local function point(p29) -- line: 320
        -- upvalues: p28 (copy)
        return {
            p28[3][1] * p29[3] + (p28[2][1] * p29[2] + (p28[1][1] * p29[1] + p28[4][1])),
            p28[3][2] * p29[3] + (p28[2][2] * p29[2] + (p28[1][2] * p29[1] + p28[4][2])),
            p28[3][3] * p29[3] + (p28[2][3] * p29[2] + (p28[1][3] * p29[1] + p28[4][3])),
            p28[3][4] * p29[3] + (p28[2][4] * p29[2] + (p28[1][4] * p29[1] + p28[4][4]))
        }
    end

    return {
        start = point(p27.start),
        ["end"] = point(p27["end"]),
        radius = p27.radius
    }
end

transform = t1.transform

return t1
