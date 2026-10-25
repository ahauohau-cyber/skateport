-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local multiply = require(sim.import)("skate_core/animation/pose_trajectory").multiply
local reflect
local t1 = {
    mirror = function(p1, p2, p3, p4) -- mirror | line: 15
        -- upvalues: multiply (copy), reflect (ref)
        if #p1 ~= #p2 or #p1 ~= #p3 then
            error("Mirror pose and hierarchy dimensions differ", 0)
        end

        for v1, v2 in p3 do
            local v3 = v1 - 1

            if v2 < -1 or #p1 <= v2 then
                error(("Invalid mirror partner for bone%*"):format(v3), 0)
            end

            if not (v2 < v3) then
                if p4 == 1 and (v3 == 0 or p2[v3 + 1] == 0) then
                    if v3 ~= 0 then
                        p1[v3 + 1].rotation = multiply(p1[v3 + 1].rotation, {
                            0, 1, 0, 0
                        })
                    end

                    p1[v3 + 1].rotation[2] *= -1
                    p1[v3 + 1].rotation[3] *= -1
                    p1[v3 + 1].translation[1] *= -1
                else
                    local reflect2 = reflect

                    reflect2(p1[v3 + 1])
                end

                if v3 < v2 then
                    local v4 = p1[v3 + 1]

                    p1[v3 + 1] = p1[v2 + 1]
                    p1[v2 + 1] = v4
                    reflect(p1[v3 + 1])
                end
            end
        end
    end,
    reflect = function(p5) -- reflect | line: 49
        p5.rotation[1] *= -1
        p5.rotation[2] *= -1
        p5.translation[3] *= -1
    end
}

reflect = t1.reflect

return t1
