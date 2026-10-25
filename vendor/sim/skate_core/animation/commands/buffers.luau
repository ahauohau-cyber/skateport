-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local n1 = 0
local t1 = {}

function t1.new_owner() -- line: 18
    -- upvalues: n1 (ref)
    local v1 = n1

    if v1 >= 18446744073709552000 then
        error("animation storage identity exhausted", 0)
    end

    n1 = v1 + 1

    return v1
end

t1.Buffer = {}

function t1.Buffer.eq(p1, p2) -- line: 32
    if p1.slot == p2.slot then
        return p1.owner == p2.owner
    end

    return false
end

function t1.Buffer.at(p3, p4) -- line: 36
    -- upvalues: rt (copy)
    return {
        buffer = rt.copy(p3),
        first_bone = p4
    }
end

t1.BoneSlice = {}

function t1.BoneSlice.eq(p5, p6) -- line: 47
    -- upvalues: t1 (copy)
    return t1.Buffer.eq(p5.buffer, p6.buffer) and p5.first_bone == p6.first_bone
end

t1.BufferError = {}

function t1.BufferError.eq(p7, p8) -- line: 59
    if p7.tag ~= p8.tag then
        return false
    end

    if p7.tag == "UninitializedBone" then
        return p7.bone == p8.bone
    end

    return true
end

t1.BoneBuffers = {}

function t1.BoneBuffers.default() -- line: 74
    -- upvalues: t1 (copy)
    return {
        owner = t1.new_owner(),
        allocations = {}
    }
end

function t1.BoneBuffers.allocate(p9, p10) -- line: 82
    -- upvalues: t1 (copy)
    return t1.BoneBuffers.insert(p9, {
        n = p10
    })
end

function t1.BoneBuffers.initialized(p11, p12) -- line: 87
    -- upvalues: t1 (copy)
    local t2 = {
        n = #p12
    }

    for v2, v3 in ipairs(p12) do
        t2[v2] = v3
    end

    return t1.BoneBuffers.insert(p11, t2)
end

function t1.BoneBuffers.insert(p13, p14) -- line: 95
    local v4 = #p13.allocations

    table.insert(p13.allocations, p14)

    return {
        slot = v4,
        owner = p13.owner,
        marker = {}
    }
end

function t1.BoneBuffers.range(p15, p16, p17) -- line: 106
    if p16.buffer.owner ~= p15.owner then
        error({
            tag = "UnknownBuffer"
        }, 0)
    end

    local v5 = p15.allocations[p16.buffer.slot + 1]

    if v5 == nil then
        error({
            tag = "UnknownBuffer"
        }, 0)
    end

    local v6 = p16.first_bone + p17

    if v6 > 18446744073709552000 then
        error({
            tag = "RangeOutsideAllocation"
        }, 0)
    end

    if v5.n < v6 then
        error({
            tag = "RangeOutsideAllocation"
        }, 0)
    end

    return p16.first_bone, v6
end

function t1.BoneBuffers.read(p18, p19, p20) -- line: 125
    -- upvalues: rt (copy), t1 (copy)
    if p20 == 0 then
        return {}
    end

    local v7, v8 = t1.BoneBuffers.range(p18, p19, p20)
    local v9 = table.create(p20)
    local v10 = p18.allocations[p19.buffer.slot + 1]

    for i = v7, v8 - 1 do
        local v11 = v10[i + 1]

        if v11 == nil then
            error({
                tag = "UninitializedBone",
                bone = i
            }, 0)
        end

        table.insert(v9, rt.copy(v11))
    end

    return v9
end

function t1.BoneBuffers.copy(p21, p22, p23, p24) -- line: 143
    -- upvalues: rt (copy), t1 (copy)
    if p24 == 0 then
        return
    end

    local v12, v13 = t1.BoneBuffers.range(p21, p22, p24)
    local v14, v15 = t1.BoneBuffers.range(p21, p23, p24)

    if p22.buffer.slot == p23.buffer.slot then
        if v12 == v14 and v13 == v15 then
            return
        end

        if v12 < v15 and v14 < v13 then
            error({
                tag = "UnsupportedPartialOverlap"
            }, 0)
        end
    end

    local v16 = p21.allocations[p23.buffer.slot + 1]
    local v17 = p21.allocations[p22.buffer.slot + 1]

    for i = 0, p24 - 1 do
        local v18 = v12 + i

        v16[v14 + i + 1] = rt.copy(v17[v18 + 1])
    end
end

t1.PoseBuffers = {}

function t1.PoseBuffers.default() -- line: 171
    -- upvalues: t1 (copy)
    return {
        sqt = t1.BoneBuffers.default(),
        matrices = t1.BoneBuffers.default()
    }
end

return t1
