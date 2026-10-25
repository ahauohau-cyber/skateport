-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local Collections = import("skate_data/collections").Collections
local t1 = {
    Validation = {}
}

function t1.Validation.load(p2) -- line: 27
    -- upvalues: Collections (copy)
    local v1 = Collections.load(p2)

    local function f(p3) -- line: 29
        -- upvalues: v1 (copy), Collections (copy)
        return Collections.float(v1, "Hash_12B64C0E804B0853", "default", p3)
    end

    return {
        slope = Collections.float(v1, "Hash_12B64C0E804B0853", "default", "Hash_ADD032CACF6A1C15"),
        max_drop = Collections.float(v1, "Hash_12B64C0E804B0853", "default", "Hash_8ABE098D3806D273"),
        clearance_length = Collections.float(v1, "Hash_12B64C0E804B0853", "default", "Hash_C0526C883AF0ECCA"),
        clearance_radius = Collections.float(v1, "Hash_12B64C0E804B0853", "default", "Hash_CEB092E418A5B001")
    }
end

function t1.Validation.check(p4, p5, p6) -- line: 45
    -- upvalues: Vector3 (copy), BoardWorld (copy)
    for _, v2 in p6 do
        if v2 ~= v2 or v2 == 1e999 or v2 == (-1e999) then
            return false
        end
    end

    local v3 = Vector3.new(p6[1], p6[2] + 0.1, p6[3])
    local v4 = Vector3.new(v3.x, v3.y - 10, v3.z)
    local query_thin_line = BoardWorld.query_thin_line
    local ok, result = pcall(query_thin_line, p5, v3, v4)

    if ok and result ~= nil then
        local v6 = bit32.band(bit32.rshift(result.tag, 7), 31)

        if not (result.geometry.normal.y < p4.slope
            or v3.y - result.geometry.position.y > p4.max_drop
            or v6 == 5
            or v6 == 6
            or v6 == 9
            or v6 == 12
            or v6 == 13) then
            local v7 = Vector3.new(v3.x, v3.y + p4.clearance_radius, v3.z)
            local v8 = Vector3.new(v7.x, v7.y + p4.clearance_length, v7.z)
            local query_swept_line = BoardWorld.query_swept_line
            local clearance_radius = p4.clearance_radius
            local ok, result = pcall(query_swept_line, p5, v7, v8, clearance_radius)

            return ok and result == nil
        end
    end

    return false
end

return t1
