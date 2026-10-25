-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/player/offboard/surface_frame/math")
local clamp, dot, scale, add = v1.clamp, v1.dot, v1.scale, v1.add
local sub, madd, cross, square_root = v1.sub, v1.madd, v1.cross, v1.square_root
local length, normalize_or, unsigned_angle, wrap_angle = v1.length, v1.normalize_or, v1.unsigned_angle, v1.wrap_angle
local clamp_axis, clamp_angle = v1.clamp_axis, v1.clamp_angle
local t1 = {
    UP = { 0, 1, 0, 0 },
    State = {}
}

function t1.State.default() -- line: 31
    -- upvalues: rt (copy), t1 (copy)
    return {
        surface_normal = rt.copy(t1.UP),
        source_normal = rt.copy(t1.UP),
        spring_normal = rt.copy(t1.UP),
        spring_delta = { 0, 0, 0, 0 },
        final_up = rt.copy(t1.UP),
        lean = { 0, 0, 0, 0 }
    }
end

function t1.State.eq(p1, p2) -- line: 43
    for _, v2 in { "surface_normal", "source_normal", "spring_normal", "spring_delta", "final_up", "lean" } do
        if p1[v2][1] ~= p2[v2][1] or p1[v2][2] ~= p2[v2][2] or p1[v2][3] ~= p2[v2][3] or p1[v2][4] ~= p2[v2][4] then
            return false
        end
    end

    return true
end

t1.SurfaceInput = {}
t1.SpringInput = {}

function t1.State.update_surface(p3, p4) -- line: 76
    -- upvalues: rt (copy), clamp (copy), dot (copy), scale (copy), sub (copy), madd (copy), cross (copy), square_root (copy), normalize_or (copy), unsigned_angle (copy), wrap_angle (copy), clamp_angle (copy), t1 (copy)
    if bit32.band(p4.flags, 1) == 0 then
        return
    end

    p3.source_normal = rt.copy(p4.normal)

    local v3 = rt.copy(p4.normal)

    if bit32.band(p4.flags, 4) ~= 0 then
        local v4 = sub(p4.edge_point, p4.origin)
        local v5 = normalize_or(cross(t1.UP, v4), { 0, 0, 0, 0 })
        local v7 = clamp_angle(normalize_or(cross(v4, v5), p4.normal), p4.normal, 0.7853981573134661)
        local v8 = clamp_angle(p4.edge_normal, p4.normal, 0.7853981573134661)
        local v9 = scale(v5, dot(v5, p4.normal))
        local v10 = normalize_or(sub(p4.normal, v9), t1.UP)

        if not (v7[2] > v10[2]) then
            v7 = v10
        end

        if not (v8[2] > v7[2]) then
            v8 = v7
        end

        v3 = madd(v8, square_root((clamp(1 - dot(v9, v9), 0, 1))), v9)
    end

    if math.abs((wrap_angle(unsigned_angle(p3.surface_normal, v3)))) < 0.7853981852531433 or v3[2] > 0.7099999785423279 then
        p3.surface_normal = normalize_or(madd(p3.surface_normal, 0.5, scale(v3, 0.5)), p3.surface_normal)
    end
end

function t1.State.update_spring(p5, p6) -- line: 107
    -- upvalues: clamp (copy), scale (copy), add (copy), sub (copy), madd (copy), length (copy), normalize_or (copy), clamp_axis (copy), clamp_angle (copy), t1 (copy)
    local v13 = clamp(length(p6.velocity) * 0.125, 0, 1)
    local v21 = clamp_axis(clamp_axis(sub(clamp_axis(scale(sub(normalize_or(clamp_angle(madd(p5.surface_normal, v13, scale(t1.UP, 1 - v13)), p5.surface_normal, 0.6283185258507729), p6.up), p5.spring_normal), 0.20000000298023224), p6.spring_right, -0.02500000037252903, 0.02500000037252903), p5.spring_delta), p6.spring_right, -0.006000000052154064, 0.006000000052154064), p6.spring_forward, -0.05000000074505806, 0.05000000074505806)

    p5.spring_delta = add(p5.spring_delta, v21)
    p5.spring_normal = normalize_or(add(p5.spring_normal, p5.spring_delta), p5.spring_normal)
    p5.lean = madd(if p6.suppress_lean then { 0, 0, 0, 0 } else madd(p6.forward, p6.forward_delta * 0.03999999910593033, scale(p6.right, p6.right_delta * 0.699999988079071)), 0.05000000074505806, scale(p5.lean, 0.949999988079071))
    p5.final_up = normalize_or(add(p5.lean, p5.spring_normal), p5.spring_normal)
end

return t1
