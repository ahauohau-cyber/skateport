-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody

return {
    audit_render_parts = function(p2) -- audit_render_parts | line: 30
        -- upvalues: rt (copy), compose_affine (copy), SkeletonBody (copy)
        local v1 = SkeletonBody.part_transforms(p2.skeleton)

        local function error_(p3, p4) -- line: 32
            -- upvalues: rt (copy)
            local n1 = 0

            for i = 0, 3 do
                for j = 0, 2 do
                    local v3 = math.abs(p3[i + 1][j + 1] - p4[i + 1][j + 1])

                    if v3 ~= v3 or v3 == 1e999 or v3 == (-1e999) then
                        return 1e999
                    end

                    n1 = rt.fmax(n1, v3)
                end
            end

            return n1
        end

        return rt.from_fn(24, function(p5) -- line: 45
            -- upvalues: p2 (copy), v1 (copy), error_ (copy), compose_affine (copy)
            local v4 = compose_affine(p2.skeleton.record.pose[p5 + 1], p2.skeleton_output.pose.geometry.inverse_part_frames[p5 + 1])

            return {
                p5,
                error_(compose_affine(p2.animated_skeleton.roots.animation_to_world, p2.render_pose[p2.animated_skeleton.bone_indices[p5 + 1] + 1]), v4),
                (error_(p2.skeleton.record.pose[p5 + 1], v1[p5 + 1]))
            }
        end)
    end
}
