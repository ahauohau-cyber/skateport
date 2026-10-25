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
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local v2 = import("skate_core/physics/board_animation")
local BoardAnimation, target_velocity = v2.BoardAnimation, v2.target_velocity
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local v3 = import("skate_core/physics/skeleton_air_frames")
local Collections = import("skate_data/collections").Collections

local function skeleton_input_runtime() -- line: 35
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function animated_skeleton() -- line: 38
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

local t1 = {}
local v4 = BoardRuntime.transform_scratch()
local matrix, affine

local function map_from_bits(p2) -- line: 51
    -- upvalues: v1 (copy)
    local v5 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v5[i] = buffer.readf32(v1, 0)
    end

    return v5
end

t1.SkeletonAir = {}

function t1.SkeletonAir.load(p3) -- line: 65
    -- upvalues: rt (copy), v1 (copy), BoardAnimation (copy), Collections (copy)
    local function graph(p4) -- line: 66
        -- upvalues: p3 (copy), rt (copy), v1 (copy), Collections (copy)
        local v7 = Collections.words(p3, "physics_airstates", "default", p4, 20)
        local v8 = table.create(#v7)

        for i = 1, #v7 do
            buffer.writeu32(v1, 0, v7[i])
            v8[i] = buffer.readf32(v1, 0)
        end

        return {
            x = rt.slice(v8, 4, 12),
            y = rt.slice(v8, 12, 20)
        }
    end

    return {
        board_animation = BoardAnimation.default(),
        settings = {
            slow = graph("PhysToAnimSlow"),
            fast = graph("PhysToAnimFast")
        }
    }
end

function t1.SkeletonAir.capture_physics_error(p5, p6, p7) -- line: 89
    -- upvalues: BodyId (copy), BoardAnimation (copy), BoardRuntime (copy), v4 (copy), matrix (ref)
    local v10 = BoardRuntime.part_transform_into(p6, BodyId.index(BodyId.Deck), v4)

    BoardAnimation.capture_physics_error(p5.board_animation, p7, matrix(v10))
end

function t1.SkeletonAir.reset_board(p8) -- line: 105
    -- upvalues: BoardAnimation (copy)
    BoardAnimation.reset(p8.board_animation)
end

function t1.SkeletonAir.apply_board(p9, p10, p11, p12) -- line: 112
    -- upvalues: rt (copy), BoardAnimation (copy), BoardRuntime (copy), affine (ref)
    local v11 = BoardAnimation.apply(p9.board_animation, p11, p12, p9.settings)

    BoardRuntime.set_hook_transform(p10, affine(rt.copy(v11)))

    return v11
end

t1.SkeletonInputRuntime = {}

function t1.SkeletonInputRuntime.update_animated(p13, p14, p15, p16, p17, p18, p19, p20, p21, p22) -- line: 129
    -- upvalues: import (copy), v3 (copy), t1 (copy)
    local AnimatedSkeleton = import("skate_game/physics/animated_skeleton").AnimatedSkeleton
    local animated = p18.animated

    AnimatedSkeleton.update_roots(animated, p15, p16, p17.timestep_2604)

    local v12, v13 = v3.prepare_animated(animated.roots, animated.board_frames, p13.drive_frames[1], p17.flags_2468)

    p17.flags_2468 = v13
    animated.board_frames.physical_board = t1.SkeletonAir.apply_board(p14, p15, v12, p22)
    import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.general_update(p13, p17, p18, p19, p20, p21)
    AnimatedSkeleton.finish_ground(p18.animated)
    p18.animation_input.fields.flags2468 = p17.flags_2468

    return v12
end

function t1.SkeletonInputRuntime.update_known_air(p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33) -- line: 165
    -- upvalues: rt (copy), import (copy), Vector3 (copy), BodyId (copy), target_velocity (copy), BoardRuntime (copy), v3 (copy), t1 (copy)
    local animated = p30.animated

    v3.update_known_air_roots(animated.roots, p26, p27, rt.copy(animated.record.centre_of_mass), {
        requested = bit32.band(p28.flags, 268435456) ~= 0,
        frames = rt.to_u32(p28.air_dismount_revert_frames),
        goofy = bit32.band(p29.flags_2476, 4) ~= 0
    })

    local v15, v16 = v3.prepare_known_air(animated.roots, animated.board_frames, p23.drive_frames[1], p29.flags_2468)

    p29.flags_2468 = v16

    local v17 = t1.SkeletonAir.apply_board(p24, p25, v15, true)

    animated.board_frames.physical_board = rt.copy(v17)

    local position = BoardRuntime.bodies(p25)[BodyId.index(BodyId.Deck) + 1].rates.position
    local v18 = target_velocity(v17[4], {
        position.x,
        position.y,
        position.z,
        0
    }, p29.timestep_2604)

    for _, v19 in BoardRuntime.bodies_mut(p25) do
        v19.rates.linear_velocity = Vector3.new(v18[1], v18[2], v18[3])
    end

    v3.finish_known_air(animated.roots, animated.board_frames, rt.copy(v17))
    import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.general_update(p23, p29, p30, p31, p32, p33)
    p30.animation_input.fields.flags2468 = p29.flags_2468

    return v15
end

function matrix(p34) -- line: 205
    -- upvalues: rt (copy)
    local v20 = rt.filled(4, { 0, 0, 0, 0 })

    for i = 0, 2 do
        local v21 = p34.basis.columns[i + 1]

        v20[i + 1][1] = v21[1]
        v20[i + 1][2] = v21[2]
        v20[i + 1][3] = v21[3]
    end

    v20[4] = {
        p34.translation.x,
        p34.translation.y,
        p34.translation.z,
        0
    }

    return v20
end

t1.matrix = matrix

function affine(p35) -- line: 219
    -- upvalues: Vector3 (copy)
    return {
        basis = {
            columns = {
                {
                    p35[1][1],
                    p35[1][2],
                    p35[1][3]
                },
                {
                    p35[2][1],
                    p35[2][2],
                    p35[2][3]
                },
                {
                    p35[3][1],
                    p35[3][2],
                    p35[3][3]
                }
            }
        },
        translation = Vector3.new(p35[4][1], p35[4][2], p35[4][3])
    }
end

t1.affine = affine

return t1
