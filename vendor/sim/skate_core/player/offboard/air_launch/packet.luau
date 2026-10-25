-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    Packet = {}
}

function t1.Packet.eq(p1, p2) -- line: 30
    for _, v1 in { "velocity_0", "secondary_velocity_16", "position_32", "up_48", "forward_64", "board_position_80" } do
        local v2 = p1[v1]
        local v3 = p2[v1]

        if v2[1] ~= v3[1] or v2[2] ~= v3[2] or v2[3] ~= v3[3] or v2[4] ~= v3[4] then
            return false
        end
    end

    if p1.scalar_96 == p2.scalar_96 and p1.scalar_100 == p2.scalar_100 and p1.scalar_104 == p2.scalar_104 and p1.kind_108 == p2.kind_108 and p1.kind_112 == p2.kind_112 and p1.has_board_position_116 == p2.has_board_position_116 then
        return p1.flag_117 == p2.flag_117
    end

    return false
end

function t1.Packet.initialized(p3) -- line: 50
    return {
        scalar_96 = 0,
        scalar_100 = 0,
        kind_108 = 1,
        kind_112 = 0,
        has_board_position_116 = false,
        flag_117 = false,
        velocity_0 = { 0, 0, 0, 0 },
        secondary_velocity_16 = { 0, 0, 0, 0 },
        position_32 = { 0, 0, 0, 0 },
        up_48 = { 0, 1, 0, 0 },
        forward_64 = { 0, 0, 0, 0 },
        board_position_80 = { 0, 0, 0, 0 },
        scalar_104 = p3
    }
end

return t1
