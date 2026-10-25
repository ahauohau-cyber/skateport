-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

local Collections = require(sim.import)("skate_data/collections").Collections

return {
    load = function(p3) -- load | line: 29
        -- upvalues: v1 (copy), Collections (copy)
        local function float(p4) -- line: 30
            -- upvalues: p3 (copy), Collections (copy)
            return Collections.float(p3, "physics_state_offboard", "default", p4)
        end

        local function vector(p5) -- line: 33
            -- upvalues: p3 (copy), v1 (copy), Collections (copy)
            if Collections.field(p3, "physics_state_offboard", "default", p5).type_name ~= "Math::Vector3" then
                error(string.format("%s: expected stock Vector3", p5), 0)
            end

            local v2 = Collections.words(p3, "physics_state_offboard", "default", p5, 4)

            buffer.writeu32(v1, 0, v2[1])

            local v4 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[2])

            local v6 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[3])

            local v8 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[4])

            local t2 = {
                v4,
                v6,
                v8,
                (buffer.readf32(v1, 0))
            }

            for _, v10 in ipairs(t2) do
                if v10 ~= v10 or v10 == 1e999 or v10 == (-1e999) then
                    error(string.format("%s: non-finite vector", p5), 0)
                end
            end

            return t2
        end

        return {
            extent_0 = vector("GrabBoxSizeGrabbing"),
            extent_16 = vector("GrabBoxSize"),
            offset_32 = vector("GrabBoxOffset"),
            angle_436 = Collections.float(p3, "physics_state_offboard", "default", "GrabSplineMaxAngleToHorizontalGrabbing"),
            angle_440 = Collections.float(p3, "physics_state_offboard", "default", "GrabSplineMaxAngleToHorizontal"),
            margin_444 = Collections.float(p3, "physics_state_offboard", "default", "GrabSplineEndExclusion"),
            angle_452 = Collections.float(p3, "physics_state_offboard", "default", "GrabSplineAngleLimitGrabbing"),
            angle_456 = Collections.float(p3, "physics_state_offboard", "default", "GrabSplineAngleLimit")
        }
    end
}
