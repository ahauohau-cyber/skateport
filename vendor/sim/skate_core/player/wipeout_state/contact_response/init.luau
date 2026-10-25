-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/contact_response/material10")
local v2 = import("skate_core/player/wipeout_state/contact_response/material11")
local v3 = import("skate_core/player/wipeout_state/math")
local dot, normalize_or, scale, sub = v3.dot, v3.normalize_or, v3.scale, v3.sub
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody
local t1 = {
    ContactResponseInput = {},
    ContactResponseOutput = {},
    ContactResponse = {}
}

function t1.ContactResponse.new() -- line: 38
    -- upvalues: v1 (copy), v2 (copy)
    return {
        material10 = v1.Response.new(),
        material11 = v2.Response.new()
    }
end

function t1.ContactResponse.reset(p1) -- line: 46
    -- upvalues: v1 (copy), v2 (copy)
    v1.Response.reset(p1.material10)
    v2.Response.reset(p1.material11)
end

function t1.ContactResponse.update(p2, p3, p4) -- line: 51
    -- upvalues: v1 (copy), v2 (copy)
    v1.Response.update(p2.material10, p3, p4.com_velocity_608, p4.material10_normal)
    v2.Response.update(p2.material11, p3, p4)

    return {
        material10_phase = p2.material10.phase,
        material10_finished_77 = p2.material10.finished,
        material11_active_73 = p2.material11.active
    }
end

function t1.reject(p5, p6) -- line: 63
    -- upvalues: dot (copy), normalize_or (copy), scale (copy), sub (copy)
    local v4 = normalize_or(p6, { 0, 0, 0, 0 })

    return sub(p5, scale(v4, dot(p5, v4)))
end

function t1.reject_positive(p7, p8) -- line: 70
    -- upvalues: rt (copy), dot (copy), normalize_or (copy), scale (copy), sub (copy)
    local v5 = dot(p7, normalize_or(p8, { 0, 0, 0, 0 }))

    if v5 > 0 then
        return sub(p7, scale(p8, v5))
    end

    return rt.copy(p7)
end

function t1.apply_velocity_delta(p9, p10) -- line: 79
    -- upvalues: SkeletonBody (copy)
    local v6 = SkeletonBody.bodies_mut(p9)

    for i = 1, 23 do
        local v7 = v6[i + 1]

        v7.rates.linear_velocity.x += p10[1]
        v7.rates.linear_velocity.y += p10[2]
        v7.rates.linear_velocity.z += p10[3]
    end
end

return t1
