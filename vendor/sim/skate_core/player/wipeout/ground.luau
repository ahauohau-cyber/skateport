-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout/common")
local Requests = import("skate_core/player/wipeout/requests").Requests
local v2 = import("skate_core/physics/native_arithmetic")
local dot3, vector_max, vector_min = v2.dot3, v2.vector_max, v2.vector_min
local v3 = import("skate_core/trigonometry")
local t1 = {}

function t1.check(p1, p2, p3, p4) -- line: 19
    -- upvalues: v1 (copy), Requests (copy), dot3 (copy), vector_max (copy), vector_min (copy), v3 (copy)
    Requests.enter_ground(p1)

    if p1.cooldown > 0 then
        p1.cooldown -= p4.timestep
    else
        local ground = p2.ground
        local v4 = if p4.group_8 then ground.vehicle_scalar else 1
        local v5 = if bit32.band(p4.flags_2472, 32768) == 0 then 1 else 0.30000001192092896
        local v6 = if bit32.band(p4.flags_2476, 8) == 0 then 1 else ground.skitch_scalar
        local v7 = if bit32.band(p4.flags_2476, 8) == 0 then 1 else ground.skitch_arms_scalar
        local v8 = if bit32.band(p4.flags_2472, 268435456) ~= 0 or not (p4.maximum_skater_force > 0) then 1 else ground.skater_scalar
        local v9 = v4 * v5 * v6 * v8
        local v10 = if bit32.band(p4.flags_2476, 1073741824) == 0 then ground.max_squash else ground.max_squash_coffin
        local v11 = ground.max_displacement * v9

        if (p3.check_squash or p4.time_on_ground > 0.05000000074505806) and p4.maximum_pose_error > v4 * v10 then
            Requests.request(p1, 18, 0)
        elseif dot3(p4.pose_error, p4.pose_error) > v11 * v11 then
            Requests.request(p1, 1, 0)
        elseif v1.force(p4, ground.max_contact * v9, ground.max_arm_contact * v7) then
            Requests.request(p1, 0, 0)
        end

        v1.vehicle(p1, p2, p4)

        if bit32.band(p4.flags_2484, 2097152) == 0 then
            local v12 = vector_min(vector_min(dot3(p4.deck[1], p4.input_board[1]), dot3(p4.deck[2], p4.input_board[2])), dot3(p4.deck[3], p4.input_board[3]))

            if v3.acos(vector_min(vector_max(v12, -1), 1)) > ground.max_deck_error then
                Requests.request(p1, 3, 0)
            end
        end

        local flags_2472_3 = p4.flags_2472
        local ground_xz, y_acceleration

        if bit32.band(flags_2472_3, 32768) == 0 then
            ground_xz = p3.ground_xz
            y_acceleration = ground.y_acceleration

            if bit32.band(p4.board_material_flags, 1073741824) ~= 0 then
                local v13 = if bit32.band(p4.flags_2472, 268435456) == 0 then ground.player_scalar else ground.ai_scalar

                ground_xz *= v13
                y_acceleration *= v13
            end

            if bit32.band(p4.board_material_flags, 536870912) ~= 0 then
                ground_xz *= ground.light_dmo_scalar
            end

            if bit32.band(p4.flags_2476, 8) ~= 0 then
                ground_xz *= ground.skitch_acc_scalar
                y_acceleration *= ground.skitch_acc_scalar
            end

            if bit32.band(p4.flags_2484, 2097152) ~= 0 then
                ground_xz = 0
                y_acceleration = 0
            end
        else
            ground_xz = p2.air.xz_trick
            y_acceleration = p2.air.y_trick
        end

        v1.closing(p1, p4, ground_xz, y_acceleration)

        local v14 = if bit32.band(p4.flags_2476, 8388608) == 0 then 1 else 0
        local v15 = if bit32.band(p4.flags_2468, 32) == 0 then 1 else 0
        local v16 = (ground.balance_min_speed - p4.speed) / ground.balance_min_speed * (1 - p4.animation_up[2]) * v15 * v14 + -ground.balance_base

        if v16 > 0 then
            p1.balance += v16
        else
            p1.balance = 0
        end

        if p1.balance > ground.balance_total then
            Requests.request(p1, 11, 0)
        end

        if p4.conflicting then
            Requests.request(p1, 16, 0)
        end

        v1.leaning(p1, p2, p4)
    end
end

function t1.check_animation(p5, p6, p7, p8, p9) -- line: 105
    -- upvalues: v1 (copy), Requests (copy), t1 (copy)
    t1.check(p5, p6, p7, p8)

    if v1.force(p8, p6.air.max_contact, p6.air.max_arm_contact) then
        Requests.request(p5, 0, 0)
    end

    if p8.opposing_contact > p6.ground.opposing_contact * p9 then
        Requests.request(p5, 20, 0)
    end
end

function t1.check_plant(p10, p11, p12) -- line: 116
    -- upvalues: v1 (copy), Requests (copy)
    p10.mode = 3

    if p12.maximum_pose_error > p11.ground.max_squash then
        Requests.request(p10, 18, 0)
    elseif v1.length(p12.pose_error) > p11.air.max_displacement then
        Requests.request(p10, 1, 0)
    elseif v1.force(p12, p11.air.max_contact, p11.air.max_arm_contact) then
        Requests.request(p10, 0, 0)
    end

    v1.closing(p10, p12, p11.air.xz_trick, p11.air.y_trick)
end

return t1
