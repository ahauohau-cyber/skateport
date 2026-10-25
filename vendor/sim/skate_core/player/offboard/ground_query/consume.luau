-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/player/offboard/ground_query/math")

local function ground_query() -- line: 11
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/ground_query")
end

local sub, scale, dot, cross = v1.sub, v1.scale, v1.dot, v1.cross
local horizontal, inverse_root, length, reciprocal = v1.horizontal, v1.inverse_root, v1.length, v1.reciprocal
local safe_unit = v1.safe_unit

return {
    interpret_hits = function(p1, p2) -- interpret_hits | line: 30
        -- upvalues: rt (copy), Vector3 (copy), sub (copy), scale (copy), dot (copy), cross (copy), horizontal (copy), inverse_root (copy), safe_unit (copy)
        local function h(p3) -- line: 31
            -- upvalues: p2 (copy)
            return p2[p3 + 1] ~= nil
        end

        local v2 = scale(cross(Vector3.new(0, 1, 0), p1.tangent), inverse_root(dot(cross(Vector3.new(0, 1, 0), p1.tangent), cross(Vector3.new(0, 1, 0), p1.tangent))))
        local n1 = 3

        if (p2[1] == nil or p2[2] == nil) and p2[5] == nil then
            if p2[1] ~= nil then
                n1 = if p2[3] == nil or p2[3].fraction >= 0.65 then 1 else 2
            elseif p2[2] ~= nil then
                v2 = scale(v2, -1)
                n1 = if p2[4] == nil or p2[4].fraction >= 0.65 then 1 else 2
            else
                n1 = 0
            end
        end

        local v3 = p2[1] == nil
        local v4 = if not v3 then bit32.band(p2[1].packed_surface, 3968) == 1024 else nil
        local v5 = not not (not v3 and v4) or p2[2] ~= nil and bit32.band(p2[2].packed_surface, 3968) == 1024
        local v6 = p2[7]
        local v7, v8

        if v6 ~= nil then
            local v9 = sub(v6.position, p1.center)
            local v10 = dot(v6.face_normal, safe_unit(p1.tangent, Vector3.ZERO))
            local v12 = safe_unit(if v10 > 0 then sub(v6.face_normal, scale(p1.tangent, v10)) else rt.copy(v6.face_normal), Vector3.ZERO)

            v7 = not (v9.y > -1)
            v8 = v12.y < 0.9 and dot(horizontal(v9), v12) > 0
        else
            v7 = true
            v8 = false
        end

        return {
            frame = {
                right = v2,
                up = rt.copy(p1.up),
                forward = rt.copy(p1.tangent),
                position = rt.copy(p1.center)
            },
            kind = n1,
            flag26 = v7,
            flag27 = v8,
            flag28 = v5
        }
    end,
    consume_geometry = function(p4, p5) -- consume_geometry | line: 98
        -- upvalues: rt (copy), import (copy), sub (copy), scale (copy), dot (copy), cross (copy), horizontal (copy), length (copy), reciprocal (copy)
        local t2 = {
            state_752 = false,
            state_753 = false,
            state_754 = false,
            frame_768 = rt.copy(import("skate_core/player/offboard/ground_query").Frame.IDENTITY),
            input_up_416 = rt.copy(p4.previous_input_up_416)
        }
        local v13

        if p5 ~= nil then
            local v14 = sub(p5.frame.position, p4.frame_80.position)
            local v15 = horizontal(v14)

            v13 = math.abs(v14.y) < 0.3 and dot(v15, v15) < 0.04000000283122063 and math.abs((dot(p5.frame.forward, p4.frame_80.forward))) > 0.9

            if not p5.flag28 and p4.reach_364 > length(v15) + 0.7 then
                local v18 = p5.kind == 2 and p5.frame.up.y > 0.98

                t2.state_752 = v18
                t2.state_754 = p5.flag26 or p5.flag27
            end

            if p5.kind == 0 or p5.kind == 1 then
                t2.state_753 = not (math.abs((dot(v14, p5.frame.right))) > 0.06) and not (bit32.band(p4.contact_flags_368, 16) ~= 0 and bit32.band(p4.contact_flags_368, 32) ~= 0)
            end

            if t2.state_752 or t2.state_753 then
                t2.frame_768 = rt.copy(p5.frame)
            end
        else
            v13 = false
        end

        if not t2.state_753 and bit32.band(p4.contact_flags_368, 1) ~= 0 and bit32.band(p4.contact_flags_368, 56) == 0 then
            local v22 = dot(sub(p4.frame_80.position, p4.contact_position_192), p4.frame_80.up)

            if not (v22 >= 0.06) and not (v22 <= -0.02) then
                t2.state_753 = true
                t2.frame_768 = rt.copy(p4.frame_80)
                t2.frame_768.position = rt.copy(p4.contact_position_192)
            end
        end

        if v13 or t2.state_753 then
            local v23 = horizontal(t2.frame_768.right)
            local v24 = length(v23)

            if not (v24 <= 0.001) then
                local v25 = scale(v23, reciprocal(v24))
                local v26 = sub(t2.frame_768.forward, scale(v25, dot(t2.frame_768.forward, v25)))
                local v27 = length(v26)

                if not (v27 <= 0.001) then
                    local v28 = scale(v26, reciprocal(v27))

                    t2.frame_768.right = v25
                    t2.frame_768.forward = v28
                    t2.frame_768.up = cross(v28, v25)
                end
            end

            if t2.frame_768.up.y < 0 then
                t2.frame_768.up = scale(t2.frame_768.up, -1)
                t2.frame_768.right = scale(t2.frame_768.right, -1)
            end

            t2.input_up_416 = rt.copy(t2.frame_768.up)
        end

        return t2
    end
}
