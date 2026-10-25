-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local Vector3 = require(sim.import)("skate_core/math").Vector3

return {
    BrakeSettings = {},
    BrakeInput = {},
    calculate_braking = function(p1, p2) -- calculate_braking | line: 35
        -- upvalues: rt (copy), Vector3 (copy)
        local v1 = if bit32.band(p1.flags_2468, 1073741824) == 0 then 0 else p1.input_2728 * p2.input_force

        if bit32.band(p1.flags_2468, 536870912) ~= 0 then
            v1 = p2.override_force
        end

        local v2 = p1.surface_factor * v1
        local v3 = (if p1.signed_speed < 0 then 1 else -1) * v2

        if p1.absolute_body_speed < p2.minimum_speed then
            v3 = 0
        end

        return {
            tag = 2,
            force_world = Vector3.new(p1.direction.x * v3, p1.direction.y * v3, p1.direction.z * v3),
            point_body = rt.copy(Vector3.ZERO)
        }
    end,
    LinearDragSettings = {},
    LinearDragInput = {},
    calculate_linear_drag = function(p3, p4) -- calculate_linear_drag | line: 87
        local v4, v5

        if not (p3.absolute_body_speed < p4.brake_speed * 2) or bit32.band(p3.flags_2468, 1610612736) == 0 then
            v5 = false
        else
            v4 = p3.scalar_2724 > 0
            v5 = not v4 and p3.balance_2720 == 0
        end

        local v6 = p3.balance_2720 ~= 0 and p3.absolute_body_speed < p4.balance_speed and p3.comparison_scalar > p4.comparison_threshold

        if v5 then
            return 1
        end

        if v6 then
            return p4.balance_drag
        end

        return 0
    end
}
