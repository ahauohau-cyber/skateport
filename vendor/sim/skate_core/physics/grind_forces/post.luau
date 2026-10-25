-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
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
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local v9 = import("skate_core/player/wipeout")
local v10 = import("skate_core/trigonometry")
local Requests, regional_force = v9.Requests, v9.regional_force

return {
    Settings = {},
    check = function(p3, p4, p5) -- check | line: 46
        -- upvalues: rt (copy), v1 (copy), inverse_length_squared (copy), dot3 (copy), v10 (copy), Requests (copy), regional_force (copy)
        p3.mode = 5

        if dot3(p5.pose_error, p5.pose_error) > p4.max_displacement_208 * p4.max_displacement_208 then
            Requests.request(p3, 1, 0)
        elseif regional_force(p5, p4.max_body_contact_168, p4.max_arm_contact_164) then
            Requests.request(p3, 0, 0)
        end

        if p5.board_contact then
            local closing_velocity, world_to_animation = p5.closing_velocity, p5.world_to_animation
            local v11 = table.create(4)

            for i = 0, 3 do
                v11[i + 1] = world_to_animation[3][i + 1] * closing_velocity[3] + (world_to_animation[2][i + 1] * closing_velocity[2] + world_to_animation[1][i + 1] * closing_velocity[1])
            end

            local v12 = dot3({
                v11[1],
                0,
                v11[3],
                v11[4]
            }, {
                v11[1],
                0,
                v11[3],
                v11[4]
            })
            local v13 = true

            if v12 == 0 then
                v13 = false
            elseif v12 < 1E-44 then
                local v14

                if v12 == 0 then
                    buffer.writef32(v1, 0, v12)
                    v14 = buffer.readf32(v1, 0)
                elseif v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
                    local v15 = math.abs(v12) * 7.1362384635298E+44
                    local v16 = math.floor(v15)
                    local v17 = v15 - v16

                    if v17 > 0.5 or v17 == 0.5 and v16 % 2 == 1 then
                        v16 += 1
                    end

                    v14 = v16 * 1.401298464324817E-45

                    if v12 < 0 then
                        v14 = -v14
                    end
                else
                    buffer.writef32(v1, 0, v12)
                    v14 = buffer.readf32(v1, 0)
                end

                v13 = v14 ~= 0
            end

            local v18 = (if v13 then v12 * inverse_length_squared(v12, 2) else 0) > p4.xz_acceleration_204
            local v19 = if not v18 then math.abs(v11[2]) > 100 else nil

            if v18 or v19 then
                Requests.request(p3, 2, 0)

                if regional_force(p5, 1, 20) then
                    Requests.request(p3, 0, 0)
                end
            end
        end

        local v21 = rt.fmin(rt.fmin(dot3(p5.deck[1], p5.input_board[1]), dot3(p5.deck[2], p5.input_board[2])), dot3(p5.deck[3], p5.input_board[3]))

        if v10.acos(rt.fmin(rt.fmax(v21, -1), 1)) > p4.max_angular_deck_error_212 then
            Requests.request(p3, 3, 0)
        end
    end
}
