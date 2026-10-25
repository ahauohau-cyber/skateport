-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/player/offboard/biped_air/feet")
local update_history
local t1 = {
    update = function(p1, p2, p3) -- update | line: 22
        -- upvalues: rt (copy), v1 (copy), update_history (ref)
        local v2 = true

        for _, v3 in ipairs(p2.lines) do
            if not v3.valid then
                v2 = false
                break
            end
        end

        if v2 then
            local t2 = {
                p2.lines[1].position[2] - p2.world_foot_pairs[1][1][2],
                p2.lines[2].position[2] - p2.world_foot_pairs[2][1][2]
            }

            if math.abs(t2[1]) > 0.3 and math.abs(t2[1] - t2[2]) > 0.3 then
                p2.lines[1].valid = false
            end

            if math.abs(t2[2]) > 0.3 and math.abs(t2[2] - t2[1]) > 0.3 then
                p2.lines[2].valid = false
            end
        end

        local v6 = v1.update(p1, p2)

        if bit32.band(p2.flags_2484, 2147483648) == 0 then
            for i = 0, 1 do
                local v7 = v6[i + 1]
                local v8 = p3.limbs[i + 1]
                local v9 = p3.external_targets[i + 1]

                if v7.world then
                    v9.world_position = rt.copy(v7.position)
                    v8.external_target_set = true
                else
                    v9.animation_position = rt.copy(v7.position)
                    v8.local_target_set = true
                end

                v8.target_blend = v7.blend

                local normal = v7.normal

                if normal ~= nil then
                    v1.set_normal(v9, rt.copy(normal))
                end
            end
        end

        update_history(p1)
    end,
    update_history = function(p4) -- update_history | line: 67
        -- upvalues: rt (copy)
        local v10 = false

        for _, v11 in ipairs(p4.hands) do
            if v11.flag_84 then
                v10 = true
                break
            end
        end

        local v12

        if v10 then
            p4.words_308_to_316[3] = rt.wrapping_add_u32(p4.words_308_to_316[3], 1)
            v12 = true

            for _, v14 in ipairs(p4.hands) do
                local v15 = v14.vectors_0_to_64[2][2] - v14.vectors_0_to_64[4][2]

                if v14.flag_84 and not (v15 > 0.18) then
                    p4.words_308_to_316[3] = 0
                end

                local v16 = not v14.flag_84

                if not v16 then
                    v16 = v15 > 1 or v14.vectors_0_to_64[5][2] < 0.6
                end

                v12 = v12 and v16
            end
        else
            v12 = true
        end

        if v12 then
            p4.words_308_to_316[2] = rt.wrapping_add_u32(p4.words_308_to_316[2], 1)

            if rt.to_i32(p4.words_308_to_316[2]) > 20 or rt.to_i32(p4.words_308_to_316[3]) > 40 then
                p4.flags_304_to_307[2] = true
            end
        else
            p4.flags_304_to_307[2] = false
            p4.words_308_to_316[2] = 0
        end

        p4.words_308_to_316[1] = 0
        p4.flags_304_to_307[3] = false
        p4.vectors_224_to_272[1] = { 0, 0, 0, 0 }
        p4.vectors_224_to_272[2] = { 0, 0, 0, 0 }
    end
}

update_history = t1.update_history

return t1
