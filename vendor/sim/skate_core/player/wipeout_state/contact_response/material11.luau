-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/player/wipeout_state/math")
local add, cross, dot, length = v2.add, v2.cross, v2.dot, v2.length
local normalize_or, reciprocal, scale, sub = v2.normalize_or, v2.reciprocal, v2.scale, v2.sub

local function parent() -- line: 17
    -- upvalues: import (copy)
    return import("skate_core/player/wipeout_state/contact_response")
end

local t1 = {
    Response = {}
}
local Response = t1.Response

local function wrapping_inc_i32(p1) -- line: 36
    -- upvalues: rt (copy)
    return rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1), rt.to_u32(1)))
end

function t1.Response.new() -- line: 40
    return {
        frames_since_contact = 100,
        active_frames = 0,
        contact_latched = false,
        active = false,
        normal = { 0, 1, 0, 0 },
        previous_velocity = { 0, 0, 0, 0 },
        velocity = { 0, 0, 0, 0 }
    }
end

function t1.Response.reset(p2) -- line: 54
    -- upvalues: rt (copy), Response (copy)
    local active = p2.active

    rt.assign(p2, Response.new())
    p2.active = active
end

function t1.Response.update(p3, p4, p5) -- line: 61
    -- upvalues: rt (copy), import (copy), dot (copy), Response (copy)
    p3.velocity = rt.copy(p5.com_velocity_608)

    if dot(p3.velocity, p3.velocity) > 0.25 then
        local material11_normal = p5.material11_normal

        if material11_normal ~= nil then
            p3.frames_since_contact = 0
            p3.contact_latched = true
            p3.normal = rt.copy(material11_normal)

            if not p3.active then
                p3.previous_velocity = import("skate_core/player/wipeout_state/contact_response").reject(p3.previous_velocity, p3.normal)
            end
        end
    end

    p3.active = p3.contact_latched or p3.frames_since_contact < 3

    if p3.active then
        Response.apply_response(p3, p4)
        Response.apply_control(p3, p4, p5.effective_axis_224, p5.wipeout_control_2824_2828)

        local active_frames = p3.active_frames

        p3.active_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(active_frames), rt.to_u32(1)))
    else
        p3.previous_velocity = rt.copy(p3.velocity)
        p3.active_frames = 0
    end

    if p3.frames_since_contact <= 100 then
        local frames_since_contact = p3.frames_since_contact

        p3.frames_since_contact = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(frames_since_contact), rt.to_u32(1)))
    else
        p3.frames_since_contact = 100
    end
end

function t1.Response.apply_response(p6, p7) -- line: 91
    -- upvalues: rt (copy), import (copy), add (copy), cross (copy), dot (copy), length (copy), normalize_or (copy), scale (copy), sub (copy)
    local v3 = import("skate_core/player/wipeout_state/contact_response")
    local reject = v3.reject
    local v4 = {
        0, 0, 0, 0
    }

    if p6.active_frames < 3 then
        local v5 = reject(sub(p6.previous_velocity, p6.velocity), p6.normal)

        if dot(v5, p6.velocity) > 0 then
            v4 = scale(v5, 0.8999999761581421)
        end
    end

    local v6 = reject(scale(p6.velocity, -0.0020000000949949026), p6.normal)
    local t2 = {
        0, 0, 0, 0
    }
    local v7 = t2

    if p6.normal[2] < 0.9700000286102295 then
        local v9 = normalize_or(cross(cross({ 0, 1, 0, 0 }, p6.normal), p6.normal), { 0, 0, 0, 0 })

        if v9[2] > 0 then
            v9 = scale(v9, -1)
        end

        local v10 = rt.copy(p6.normal)

        v10[2] = 0
        v7 = scale(v9, length(v10) * 0.10000000149011612)

        if not (dot(v7, p6.velocity) > 0) then
            v7 = t2
        end
    end

    v3.apply_velocity_delta(p7, add(add(v6, v4), v7))
end

function t1.Response.apply_control(p8, p9, p10, p11) -- line: 122
    -- upvalues: import (copy), v1 (copy), dot (copy), length (copy), normalize_or (copy), reciprocal (copy), scale (copy)
    local v11 = import("skate_core/player/wipeout_state/contact_response")
    local reject = v11.reject
    local v12 = reject(p8.velocity, p8.normal)
    local v13 = normalize_or(v12, { 0, 0, 0, 0 })

    if not (dot({ 0, 1, 0, 0 }, p10) < 0.9990000128746033) then
        return
    end

    local v14 = reciprocal(10) * v1.vector_min(10, length(v12))
    local v15 = reject(reject({
        p11[1],
        0,
        p11[2],
        0
    }, p8.normal), v13)

    v11.apply_velocity_delta(p9, scale(v15, v14 * 0.05000000074505806))
end

return t1
