-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

require(sim.import)

local t1 = {}

local function not_ported() -- line: 21
    error("skate_dynamics: Rapier query not ported", 0)
end

t1.MAX_MODEL_VERTICES = 65536
t1.MAX_MODEL_TRIANGLES = 131072
t1.MAX_COMPOUND_HULLS = 64
t1.MAX_HULL_POINTS = 2048
t1.MAX_BODY_POINTS = 8192
t1.ModelColliderOptions = {}

function t1.ModelColliderOptions.default() -- line: 37
    return {
        max_hulls = 32,
        resolution = 96,
        concavity = 0.0025,
        scale = { 1, 1, 1 }
    }
end

function t1.ModelColliderOptions.eq(p2, p3) -- line: 42
    if p2.max_hulls == p3.max_hulls and p2.resolution == p3.resolution and p2.concavity == p3.concavity and p2.scale[1] == p3.scale[1] and p2.scale[2] == p3.scale[2] then
        return p2.scale[3] == p3.scale[3]
    end

    return false
end

function t1.ModelColliderOptions.validate(p4) -- line: 52
    -- upvalues: t1 (copy)
    local v1 = not (p4.max_hulls >= 1 and p4.max_hulls <= t1.MAX_COMPOUND_HULLS)
    local v2

    if v1 then
        v2 = v1
    else
        local v3 = not (p4.resolution >= 32 and p4.resolution <= 128)

        if v3 then
            v2 = v3
        else
            local concavity = p4.concavity
            local v4 = not (concavity == concavity and concavity ~= 1e999 and concavity ~= (-1e999))

            v2 = v4 or not (p4.concavity >= 1E-04 and p4.concavity <= 0.1)
        end
    end

    if not v2 then
        for _, v5 in ipairs(p4.scale) do
            if v5 ~= v5 or v5 == 1e999 or v5 == (-1e999) or math.abs(v5) < 1E-04 or math.abs(v5) > 100 then
                v2 = true
                break
            end
        end
    end

    if v2 then
        error("model options: max_hulls 1..64, resolution 32..128, concavity 0.0001..0.1, finite nonzero scale required", 0)
    end
end

function t1.validate_hulls(p5) -- line: 74
    -- upvalues: t1 (copy)
    if #p5 == 0 or #p5 > t1.MAX_COMPOUND_HULLS then
        error("compound needs 1..64 convex parts", 0)
    end

    local n1 = 0

    for _, v6 in ipairs(p5) do
        local v7 = not (#v6 >= 4 and #v6 <= t1.MAX_HULL_POINTS)

        if not v7 then
            local v8 = v7

            for _, v9 in ipairs(v6) do
                for _, v10 in ipairs(v9) do
                    if v10 ~= v10 or v10 == 1e999 or v10 == (-1e999) or math.abs(v10) > 1000 then
                        v8 = true
                        break
                    end
                end

                if v8 then
                    v7 = v8
                    break
                end

                v7 = v8
            end
        end

        if v7 then
            error("compound contains invalid or oversized convex part", 0)
        end

        n1 += #v6

        if t1.MAX_BODY_POINTS < n1 then
            error("compound exceeds 8192 hull vertices; lower max_hulls/resolution", 0)
        end
    end
end

function t1.compound_shape(p6) -- line: 107
    -- upvalues: t1 (copy), not_ported (copy)
    t1.validate_hulls(p6)

    return not_ported()
end

function t1.decompose(p7, p8, p9) -- line: 117
    -- upvalues: rt (copy), t1 (copy), not_ported (copy)
    t1.ModelColliderOptions.validate(p9)

    local v11 = not (#p7 >= 4 and #p7 <= t1.MAX_MODEL_VERTICES)

    if not v11 then
        v11 = #p8 == 0 or #p8 > t1.MAX_MODEL_TRIANGLES
    end

    if not v11 then
        local v12 = v11

        for _, v13 in ipairs(p7) do
            for _, v14 in ipairs(v13) do
                if v14 ~= v14 or v14 == 1e999 or v14 == (-1e999) or math.abs(v14) > 1000 then
                    v12 = true
                    break
                end
            end

            if v12 then
                v11 = v12
                break
            end

            v11 = v12
        end
    end

    if not v11 then
        local v15 = v11

        for _, v16 in ipairs(p8) do
            for _, v17 in ipairs(v16) do
                if #p7 <= v17 then
                    v15 = true
                    break
                end
            end

            if v15 then
                v11 = v15
                break
            end

            v11 = v15
        end
    end

    if v11 then
        error("invalid or oversized render-mesh collision input", 0)
    end

    local t2 = {
        p7[1][1],
        p7[1][2],
        p7[1][3]
    }
    local t3 = {
        t2[1],
        t2[2],
        t2[3]
    }

    for _, v18 in ipairs(p7) do
        for i = 1, 3 do
            t2[i] = rt.fmin(t2[i], v18[i])
            t3[i] = rt.fmax(t3[i], v18[i])
        end
    end

    local t4 = {
        t3[1] - t2[1],
        t3[2] - t2[2],
        t3[3] - t2[3]
    }

    if rt.fmin(t4[1], rt.fmin(t4[2], t4[3])) < 1E-04 then
        error("model collision requires a nonzero 3D extent, not a flat/line mesh", 0)
    end

    return not_ported()
end

return t1
