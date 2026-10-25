-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local Runtime = import("skate_game/physics/grind/runtime").Runtime

local function grind() -- line: 14
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local v1 = BoardRuntime.transform_scratch()

return {
    condition = function(p1, p2) -- condition | line: 28
        -- upvalues: rt (copy), import (copy), BodyId (copy), BoardRuntime (copy), Runtime (copy), v1 (copy)
        local Family = import("skate_game/physics/grind").Family
        local grinds = p2.player_input.physical.grinds

        grinds.grinding_316 = (grinds.words_136_140[2] == 1 or grinds.words_136_140[2] == 2) and 1 or 0

        local v2 = grinds.words_136_140[1]
        local v3

        if v2 == 0 then
            v3 = Family.FiftyFifty
        elseif v2 == 1 then
            v3 = Family.Boardslide
        elseif v2 == 2 then
            v3 = Family.Tipslide
        elseif v2 == 3 then
            v3 = Family.FiveO
        elseif v2 == 4 then
            v3 = Family.Backslash
        elseif v2 == 5 then
            v3 = Family.Darkslide
        end

        if grinds.grinding_316 ~= 0 and v3 == nil then
            error(string.format("Active grind has invalid native family %d", grinds.words_136_140[1]), 0)
        end

        local v4 = BoardRuntime.part_transform_into(p1.board, BodyId.index(BodyId.Deck), v1)

        local function axis(p3) -- line: 70
            return {
                p3[1],
                p3[2],
                p3[3],
                0
            }
        end

        local v5 = p1.riding.motion.effective_basis.columns[3]
        local t2 = {
            v5[1],
            v5[2],
            v5[3],
            0
        }
        local position = BoardRuntime.bodies(p1.board)[BodyId.index(BodyId.Deck) + 1].rates.position

        local function raw(p4) -- line: 76
            -- upvalues: rt (copy)
            return rt.map(p4, rt.from_bits)
        end

        local t3 = {
            category = p2.player_input.physical.state.category_12,
            grinding_316 = grinds.grinding_316 ~= 0
        }

        t3.air_event_439 = bit32.band(p2.player_input.processed.flags_2468, 2097152) ~= 0
        t3.family = v3

        local v6 = v4.basis.columns[1]

        t3.basic_right_0 = {
            v6[1],
            v6[2],
            v6[3],
            0
        }

        local v7 = v4.basis.columns[3]

        t3.basic_forward_32 = {
            v7[1],
            v7[2],
            v7[3],
            0
        }
        t3.basic_position_48 = {
            v4.translation.x,
            v4.translation.y,
            v4.translation.z,
            0
        }
        t3.basic_location_axis_96 = rt.copy(t2)
        t3.basic_twist_axis_128 = rt.copy(t2)
        t3.basic_location_position_144 = {
            position.x,
            position.y,
            position.z,
            0
        }
        t3.feet_256_272 = {
            rt.copy(p2.skeleton.record.pose[20][1]),
            rt.copy(p2.skeleton.record.pose[16][1])
        }
        t3.fakie_155 = p2.animation.packet.riding_fakie

        local point_16 = grinds.point_16

        t3.point = rt.map(point_16, rt.from_bits)

        local direction_0 = grinds.direction_0

        t3.direction = rt.map(direction_0, rt.from_bits)

        local normal_32 = grinds.normal_32

        t3.normal = rt.map(normal_32, rt.from_bits)

        local across_48 = grinds.across_48

        t3.across = rt.map(across_48, rt.from_bits)

        return Runtime.condition_outputs(p2.grind, t3, grinds)
    end
}
