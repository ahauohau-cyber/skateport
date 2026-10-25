-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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
local v9 = import("skate_core/player/wipeout")

local function ground_lifecycle() -- line: 30
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/ground_lifecycle")
end

local Requests = v9.Requests

return {
    PostInput = {},
    post_physics = function(p3, p4, p5, p6) -- post_physics | line: 50
        -- upvalues: v1 (copy), import (copy), Requests (copy)
        local v10 = import("skate_core/player/offboard/ground_lifecycle")
        local dot, length = v10.dot, v10.length

        v10.check_collision(p4, p5, p6.collision)

        if bit32.band(p6.processed_flags_2484, 1024) == 0 then
            local v12 = math.abs((dot(p6.skeleton_displacement_16304, p3.frame_80[2])))
            local v14 = math.abs((dot(p6.skeleton_displacement_16288, p3.frame_80[2])))
            local v15 = false
            local v16 = false
            local v17 = false
            local v18 = false
            local v19 = false

            if v12 > 0.3499999940395355 then
                v16 = true
            else
                v15 = true
            end

            if v15 then
                if v14 > 0.15000000596046448 then
                    v16 = true
                else
                    v19 = true
                end
            end

            v15 = false

            local v20

            if v16 then
                v20 = p3.elapsed_168 + 0.01666666753590107

                if v20 == 0 then
                    v17 = true
                else
                    v15 = true
                end
            end

            v16 = false

            if v15 then
                if v20 > -1.1754943508222875E-38 then
                    v16 = true
                else
                    v17 = true
                end
            end

            v15 = false

            if v16 then
                if v20 < 1.1754943508222875E-38 then
                    v15 = true
                else
                    v17 = true
                end
            end

            v16 = false

            local v21

            if v17 then
                buffer.writef32(v1, 0, v20)
                v21 = buffer.readf32(v1, 0)
                v19 = false
            end

            v17 = false

            local v22, v23

            if v15 then
                local v24 = math.abs(v20) * 7.1362384635298E+44

                v22 = math.floor(v24)
                v23 = v24 - v22

                if v23 > 0.5 then
                    v17 = true
                else
                    v16 = true
                end
            end

            v15 = false

            local v25

            if v16 then
                if v23 == 0.5 then
                    v15 = true
                else
                    v25 = v22
                    v18 = true
                end
            end

            if v15 then
                if v22 % 2 == 1 then
                    v17 = true
                else
                    v25 = v22
                    v18 = true
                end
            end

            v15 = false

            if v17 then
                v25 = v22 + 1
                v18 = true
            end

            v17 = false

            local v26

            if v18 then
                v26 = v25 * 1.401298464324817E-45

                if v20 < 0 then
                    v17 = true
                else
                    v15 = true
                end
            end

            if v15 then
                v21 = v26
                v19 = false
            end

            if v17 then
                v21 = -v26
                v19 = false
            end

            if v19 then
                p3.elapsed_168 = 0
            else
                p3.elapsed_168 = v21
            end

            if not (p3.elapsed_168 < 0.05000000447034836) then
                Requests.request(p4, 32, 0)
            end
        else
            if p3.flags_144_to_150[7] and p3.flags_144_to_150[3] then
                Requests.request(p4, 31, 0)
            end

            p3.elapsed_168 = 0

            if not p3.flags_144_to_150[3] and not (p3.angle_172 > 1.5707963705062866) and p6.ground_kind_356 ~= 2 and p6.ground_kind_356 ~= 4 and not (p3.frame_80[2][2] < 0.5) then
                local v27 = dot(p6.processed_velocity_608, p6.skeleton_displacement_16304)
                local v28

                if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
                    local v29 = math.abs(v27) * 7.1362384635298E+44
                    local v30 = math.floor(v29)
                    local v31 = v29 - v30

                    v28 = (if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30) * 1.401298464324817E-45

                    if v27 < 0 then
                        v28 = -v28
                    end
                else
                    buffer.writef32(v1, 0, v27)
                    v28 = buffer.readf32(v1, 0)
                end

                local v32 = length(p6.processed_velocity_608)
                local v33

                if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
                    local v34 = math.abs(v32) * 7.1362384635298E+44
                    local v35 = math.floor(v34)
                    local v36 = v34 - v35

                    v33 = (if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35) * 1.401298464324817E-45

                    if v32 < 0 then
                        v33 = -v33
                    end
                else
                    buffer.writef32(v1, 0, v32)
                    v33 = buffer.readf32(v1, 0)
                end

                local v37 = v33 * -0.019999999552965164
                local v38

                if v37 ~= 0 and v37 > -1.1754943508222875E-38 and v37 < 1.1754943508222875E-38 then
                    local v39 = math.abs(v37) * 7.1362384635298E+44
                    local v40 = math.floor(v39)
                    local v41 = v39 - v40

                    v38 = (if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40) * 1.401298464324817E-45

                    if v37 < 0 then
                        v38 = -v38
                    end
                else
                    buffer.writef32(v1, 0, v37)
                    v38 = buffer.readf32(v1, 0)
                end

                if not (v38 <= v28) then
                    Requests.request(p4, 32, 0)
                end
            else
                Requests.request(p4, 31, 0)
            end
        end

        if p3.flags_144_to_150[2] then
            Requests.request(p4, 28, 0)
        end
    end
}
