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

local function rtl_is_finite(p3) -- line: 24
    if p3 ~= p3 or p3 == 1e999 then
        return false
    end

    return p3 ~= (-1e999)
end

local import = require(sim.import)
local v8 = import("skate_core/player/offboard/grab_scene/math")
local v9 = import("skate_core/player/offboard/grab_scene/registry")

local function grab_scene() -- line: 34
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/grab_scene")
end

local length, sub, dot, sphere_segment = v8.length, v8.sub, v8.dot, v8.sphere_segment
local point = v8.point

return {
    query = function(p4, p5) -- query | line: 49
        -- upvalues: rt (copy), v1 (copy), import (copy), v9 (copy), length (copy), sub (copy), dot (copy), sphere_segment (copy), point (copy)
        if p5.mode ~= 4 then
            error("This offboard provider implements native bounded mode4 only", 0)
        end

        if p5.capacity > 32 then
            error("Native grab query buffer capacity is32", 0)
        end

        local v10 = false

        for i = 1, 4 do
            local v11 = p5.position[i]

            if v11 ~= v11 or v11 == 1e999 or v11 == (-1e999) then
                v10 = true
                break
            end
        end

        if not v10 then
            for i = 1, 4 do
                local v12 = p5.sort_position[i]

                if v12 ~= v12 or v12 == 1e999 or v12 == (-1e999) then
                    v10 = true
                    break
                end
            end
        end

        if not v10 then
            for i = 1, 4 do
                local v13 = p5.bounds.extents[i]

                if v13 ~= v13 or v13 == 1e999 or v13 == (-1e999) then
                    v10 = true
                    break
                end
            end
        end

        if not v10 then
            for i = 1, 4 do
                for j = 1, 4 do
                    local v14 = p5.bounds.frame[i][j]

                    if v14 ~= v14 or v14 == 1e999 or v14 == (-1e999) then
                        v10 = true
                        break
                    end
                end

                if v10 then
                    break
                end
            end
        end

        if v10 then
            error("Nonfinite grab query", 0)
        end

        local v15 = import("skate_core/player/offboard/grab_scene")
        local Record, qualify, closest_point = v15.Record, v15.qualify, v15.closest_point
        local Object = v9.Object
        local v16 = length(p5.bounds.extents)
        local v17 = rt.copy(p5.bounds.frame[4])
        local v18 = table.create(32)

        for _, v19 in p4.objects do
            if not v19.disabled and v19.assembly_ready and v19.assembly ~= nil then
                local provider = v19.provider

                if provider.tag == "Dmo" then
                    if provider.record_enabled and provider.selection_variant == bit32.band(bit32.rshift(p5.context.selection_flags_2948, 1), 1) and (p5.context.matching_id_2952 == -1 or provider.matching_group == -1 or provider.matching_group == p5.context.matching_id_2952) then
                        for _, v21 in v19.splines do
                            local points = v21.geometry.points

                            if v21.descriptor.kind == 2 and not (#points < 2) and #v21.geometry.approach_vectors ~= 0 then
                                local v22 = #points - 2
                                local v23 = false

                                for k = 0, v22 do
                                    local v24 = points[k + 1]
                                    local v25 = points[k + 2]
                                    local v26 = sub(v25, v24)

                                    if dot(v26, v26) > 9.999999747378752E-06 and sphere_segment(v17, v16, point(v19.frame, v24), point(v19.frame, v25)) then
                                        v23 = true
                                        break
                                    end
                                end

                                if v23 and #v18 ~= 32 then
                                    local v28 = Object.record(v19, v21)

                                    if qualify(v28, p5.position, p5.bounds, p5.limits) then
                                        table.insert(v18, v28)
                                    end
                                end
                            end
                        end
                    end
                else
                    if provider.tag == "LivingWorld" then
                        local v29 = sub(v19.frame[4], v17)
                        local v30 = v16 + 15

                        if dot(v29, v29) >= v30 * v30 then
                            continue
                        end
                    end

                    for _, v31 in v19.splines do
                        local points = v31.geometry.points

                        if v31.descriptor.kind == 2 and not (#points < 2) and #v31.geometry.approach_vectors ~= 0 then
                            local v32 = #points - 2
                            local v33 = false

                            for n = 0, v32 do
                                local v34 = points[n + 1]
                                local v35 = points[n + 2]
                                local v36 = sub(v35, v34)

                                if dot(v36, v36) > 9.999999747378752E-06 and sphere_segment(v17, v16, point(v19.frame, v34), point(v19.frame, v35)) then
                                    v33 = true
                                    break
                                end
                            end

                            if v33 and #v18 ~= 32 then
                                local v38 = Object.record(v19, v31)

                                if qualify(v38, p5.position, p5.bounds, p5.limits) then
                                    table.insert(v18, v38)
                                end
                            end
                        end
                    end
                end
            end
        end

        for _, v39 in v18 do
            local v40 = sub(p5.sort_position, closest_point(p5.sort_position, Record.endpoints(v39)))
            local v41 = v39[1]
            local v42 = dot(v40, v40)
            local v43

            if v42 == 0 then
                buffer.writef32(v1, 0, v42)
                v43 = buffer.readu32(v1, 0)
            elseif v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
                local v44 = math.abs(v42) * 7.1362384635298E+44

                v43 = math.floor(v44)

                local v45 = v44 - v43

                if v45 > 0.5 or v45 == 0.5 and v43 % 2 == 1 then
                    v43 += 1
                end

                if v42 < 0 then
                    v43 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v42)
                v43 = buffer.readu32(v1, 0)
            end

            v41[47] = v43
        end

        for i = 1, #v18 - 1 do
            local v46 = i

            while v46 > 0 and Record.scalar(v18[v46 + 1], 184) < Record.scalar(v18[v46], 184) do
                local v47 = v18[v46 + 1]

                v18[v46 + 1] = v18[v46]
                v18[v46] = v47
                v46 -= 1
            end
        end

        for i = #v18, p5.capacity + 1, -1 do
            v18[i] = nil
        end

        return v18
    end
}
