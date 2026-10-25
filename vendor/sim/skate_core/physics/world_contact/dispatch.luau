-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/world_contact/point_feature")
local v2 = import("skate_core/physics/world_contact/segment_prism")
local v3 = import("skate_core/physics/world_contact/segment_face")
local v4 = import("skate_core/physics/world_contact/face_face")
local v5 = import("skate_core/physics/world_contact/face_specialized")
local closest_feature_segment, intersect_point_face = v1.closest_feature_segment, v1.intersect_point_face
local intersect_feature_segments = v2.intersect_feature_segments
local intersect_segment_face = v3.intersect_segment_face
local segment_point
local t1 = {}

function t1.find_feature_intersection_prism(p1, p2, p3, p4) -- line: 36
    -- upvalues: v4 (copy), v5 (copy), intersect_point_face (copy), intersect_feature_segments (copy), intersect_segment_face (copy), segment_point (ref)
    local v6 = p2[141]
    local v7 = p3[141]

    if not (v6 <= 8 and v7 <= 8) then
        error("maximum-feature storage exceeded", 0)
    end

    if v6 ~= 0 or v7 ~= 0 then
        if v6 == 1 and v7 == 0 then
            return segment_point(p1, p2, p3, true)
        end

        if v6 == 0 and v7 == 1 then
            return segment_point(p1, p3, p2, false)
        end

        if v6 == 0 then
            return intersect_point_face(p1, p3, p2, p4, false)
        end

        if v7 == 0 then
            return intersect_point_face(p1, p2, p3, p4, true)
        end

        if v6 == 1 and v7 == 1 then
            return intersect_feature_segments(p1, p2, p3, p4, true)
        end

        if v6 == 1 then
            return intersect_segment_face(p1, p3, p2, p4, false)
        end

        if v7 == 1 then
            return intersect_segment_face(p1, p2, p3, p4, true)
        end

        if v6 ~= 4 or v7 ~= 3 then
            if v6 ~= 3 or v7 ~= 4 then
                if v6 == 4 and v7 == 4 and v5.quad_quad(p1, p2, p3, p4) ~= 0 then
                    return 1
                end
            elseif v5.quad_triangle(p1, p3, p2, p4, false) ~= 0 then
                return 1
            end
        elseif v5.quad_triangle(p1, p2, p3, p4, true) ~= 0 then
            return 1
        end

        return v4.intersect(p1, p2, p3)
    end

    p1[133] = 1
    p1[1] = p2[137]
    p1[2] = p2[138]
    p1[3] = p2[139]
    p1[4] = p2[140]
    p1[65] = p3[137]
    p1[66] = p3[138]
    p1[67] = p3[139]
    p1[68] = p3[140]

    return 1
end

function t1.segment_point_reference(p5, p6, p7, p8) -- line: 81
    -- upvalues: rt (copy), closest_feature_segment (copy)
    p5[133] = 1
    p5[1] = p7[137]
    p5[2] = p7[138]
    p5[3] = p7[139]
    p5[4] = p7[140]
    p5[65] = p7[137]
    p5[66] = p7[138]
    p5[67] = p7[139]
    p5[68] = p7[140]

    local v8 = if p8 then 0 else 64
    local v9 = rt.slice(p5, v8, v8 + 4)
    local v10 = closest_feature_segment(rt.slice(p6, 4, 20), v9)

    p5[v8 + 1] = v9[1]
    p5[v8 + 2] = v9[2]
    p5[v8 + 3] = v9[3]
    p5[v8 + 4] = v9[4]
    p6[1] = rt.wrapping_add_u32(rt.wrapping_sub_u32(p6[1], v10), 2)

    return 1
end

local closest_feature_segment_at = v1.closest_feature_segment_at
local t2 = { 0, 0, 0, 0 }

function segment_point(p9, p10, p11, p12) -- line: 108
    -- upvalues: rt (copy), closest_feature_segment_at (copy), t2 (copy)
    p9[133] = 1

    local v11 = p11[137]
    local v12 = p11[138]
    local v13 = p11[139]
    local v14 = p11[140]

    p9[1] = v11
    p9[2] = v12
    p9[3] = v13
    p9[4] = v14
    p9[65] = v11
    p9[66] = v12
    p9[67] = v13
    p9[68] = v14

    local v15 = if p12 then 0 else 64
    local v16 = p9[v15 + 1]
    local v17 = p9[v15 + 2]
    local v18 = p9[v15 + 3]
    local v19 = p9[v15 + 4]

    t2[1] = v16
    t2[2] = v17
    t2[3] = v18
    t2[4] = v19

    local v20 = closest_feature_segment_at(p10, 4, t2)
    local v21 = v15 + 1
    local v22 = v15 + 2
    local v23 = v15 + 3
    local v24 = v15 + 4
    local v25 = t2[1]
    local v26 = t2[2]
    local v27 = t2[3]
    local v28 = t2[4]

    p9[v21] = v25
    p9[v22] = v26
    p9[v23] = v27
    p9[v24] = v28
    p10[1] = rt.wrapping_add_u32(rt.wrapping_sub_u32(p10[1], v20), 2)

    return 1
end

t1.segment_point = segment_point

return t1
