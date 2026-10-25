-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_game/physics/offboard/landing_deck/input")
local v3 = import("skate_game/physics/offboard/contact_toolkit")
local v4 = import("skate_core/player/offboard/hippy_jump")
local v5 = import("skate_core/player/offboard/landing_deck")
local StaticScene = v3.StaticScene
local Manager, QueryResult = v5.Manager, v5.QueryResult
local t1 = {
    execute = function(p2, p3, p4) -- execute | line: 29
        -- upvalues: rt (copy), StaticScene (copy)
        return StaticScene.trajectory(p2, p3, rt.to_i32(p4.actor_query_2952), 0)
    end,
    Owner = {}
}

function t1.Owner.submit(p5, p6, p7, p8) -- line: 44
    -- upvalues: Manager (copy), t1 (copy)
    p5.completion = t1.execute(p6, p7, p8)
    Manager.query_submitted(p5.manager)
end

function t1.Owner.post_physics(p9, p10) -- line: 54
    -- upvalues: rt (copy), v1 (copy), v2 (copy), v4 (copy), Manager (copy), QueryResult (copy)
    if p9.manager.pending_262 then
        local completion = p9.completion

        if completion == nil then
            error("Landing pending262 has no submitted world-query completion", 0)
        end

        local v6 = rt.copy(completion)
        local processed = p10.processed

        if not QueryResult.valid(v6) then
            v6 = nil
        end

        Manager.sync(p9.manager, v6, {
            position_592 = v2.position(p10),
            flags_2488 = processed.flags_2488
        }, function(_) -- line: 78
            -- upvalues: p10 (copy), processed (copy), rt (copy), v1 (copy), v2 (copy), v4 (copy)
            local v7 = v2.processed(p10)
            local calculate = v4.calculate
            local t2 = {}

            buffer.writeu32(v1, 0, processed.vectors_880_896_912_928_944[4][2])
            t2.desired_height = buffer.readf32(v1, 0) + 0.20000000298023224
            t2.board_position = rt.copy(v7.board_position_112)
            t2.centre_of_mass_position = v2.position(p10)
            t2.reference_up = rt.copy(v7.up_544)
            t2.current_velocity = rt.copy(v7.board_velocity_400)

            return calculate(t2)
        end)
        p9.completion = nil
    elseif p9.completion ~= nil then
        error("Landing query completion exists without native pending262", 0)
    end
end

return t1
