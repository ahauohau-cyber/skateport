-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Owner = import("skate_game/physics/biped_ground/grab_runtime").Owner
local v1 = import("skate_core/player/offboard/grab_scene")
local v2 = import("skate_core/player/offboard/ground_sync")
local Record = v1.Record
local board_bounds = v2.board_bounds
local t1 = {
    Input = {}
}
local limits

function t1.sync(p1, p2, p3, p4) -- line: 29
    -- upvalues: rt (copy), Owner (copy), v1 (copy), Record (copy), board_bounds (copy), limits (ref)
    if bit32.band(p4.flags_2484, 536870912) == 0 and bit32.band(p4.flags_2480, 262144) == 0 and not (p4.timer_2852 > 0) then
        if bit32.band(p4.flags_2476, 4194304) == 0 then
            Owner.invalidate(p2)
        elseif p1.flags_144_to_150[5] then
            if not (p4.elapsed <= 0.5) then
                p1.flags_144_to_150[5] = false
            end
        else
            local v3 = board_bounds(rt.copy(p4.frame), rt.copy(p3.offset_32), rt.copy(p3.extent_16))

            if bit32.band(p2.flags_12836, 64) ~= 0 then
                local v4 = Owner.best(p2, rt.copy(p4.position))

                if v4 ~= nil then
                    local v5 = board_bounds(rt.copy(p4.frame), rt.copy(p3.offset_32), rt.map(p3.extent_0, function(p5) -- line: 50
                        return p5 * 0.949999988079071
                    end))

                    p1.flags_144_to_150[1] = v1.qualify(v4, rt.copy(p4.bone), v5, limits(p3.margin_444, p3.angle_452, p3.angle_436))

                    if p1.flags_144_to_150[1] then
                        local v6 = Record.descriptor(v4)

                        p1.counter_152 = v6.kind
                        p1.counter_156 = v6.id
                    end
                end
            end

            Owner.query(p2, {
                mode = 4,
                capacity = 5,
                position = rt.copy(p4.position),
                sort_position = rt.copy(p4.position),
                bounds = v3,
                limits = limits(p3.margin_444, p3.angle_456, p3.angle_440),
                context = rt.copy(p4.context)
            })

            if p1.flags_144_to_150[1] then
                Owner.request_primary(p2, {
                    kind = p1.counter_152,
                    id = p1.counter_156
                })
            else
                Owner.request_interactable(p2, rt.copy(p4.frame), rt.copy(p4.context))
            end
        end
    end
end

function t1.limits(p6, p7, p8) -- line: 89
    return {
        margin = p6,
        angle_a = p7 * 0.01745329238474369,
        angle_b = p8 * 0.01745329238474369
    }
end

limits = t1.limits

return t1
