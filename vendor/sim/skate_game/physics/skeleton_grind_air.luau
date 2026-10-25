-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_air")
local GrindAir, Adjustment = v1.GrindAir, v1.Adjustment
local map_animation_parts = import("skate_core/physics/skeleton_animation_record").map_animation_parts
local SkateboardOffset = import("skate_core/physics/skeleton_board_offset").SkateboardOffset

return {
    SkeletonInputRuntime = {},
    update = function(p1, p2, p3, p4, p5, p6) -- update | line: 23
        -- upvalues: rt (copy), GrindAir (copy), Adjustment (copy), map_animation_parts (copy), SkateboardOffset (copy)
        local v2 = GrindAir.update(p1, {
            active = true,
            board = p3,
            velocity = rt.map(p4.vectors_400_416[1], rt.from_bits),
            angular_velocity = rt.map(p4.vectors_720_784_800_816_832_864[1], rt.from_bits),
            up = rt.map(p4.vectors_544_560_592_608[1], rt.from_bits),
            timestep = p4.timestep_2604,
            flags_2468 = p4.flags_2468,
            flags_2472 = p4.flags_2472,
            flags_2480 = p4.flags_2480,
            flags_2484 = p4.flags_2484
        }, p2)

        if v2 == nil then
            return false
        end

        local v3 = map_animation_parts(p6, p5.bone_indices, p5.physics_frames)
        local v4 = Adjustment.local_transform(v2, {
            animation_to_world = rt.copy(p5.roots.animation_to_world),
            world_to_animation = rt.copy(p5.roots.world_to_animation),
            physical_forward = rt.copy(p5.board_frames.physical_board[3]),
            animation_board_position = rt.copy(v3[1][4])
        })

        SkateboardOffset.refresh_transform(p5.board_offset, v4)

        return true
    end
}
