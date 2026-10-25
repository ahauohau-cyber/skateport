-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local v1 = import("skate_core/player/offboard/board_possession/angular")
local t1 = {
    VolumeFlags = {},
    Materials = {}
}

function t1.Materials.set(p1, p2) -- line: 35
    -- upvalues: rt (copy)
    rt.assign(p1.wheels, p2[1])
    rt.assign(p1.trucks, p2[2])
    rt.assign(p1.deck, p2[3])
end

function t1.VolumeFlags.set_enabled(p3, p4) -- line: 41
    p3.deck = p4
    p3.trucks = p4
    p3.wheels = p4

    for i = 1, #p3.deck_children do
        p3.deck_children[i] = p4
    end
end

t1.Effects = {}

local function write_scalar(p5, p6, p7) -- line: 72
    p5[p6] = p7

    local refs = p5.refs

    if refs ~= nil then
        local v2 = refs[p6]

        if v2 ~= nil then
            v2[1][v2[2]] = p7
        end
    end
end

function t1.Effects.enable_animation_soft(p8) -- line: 84
    -- upvalues: BoardRuntime (copy), HookDriveState (copy)
    local v3 = HookDriveState.enable_animation_soft(BoardRuntime.hook_mut(p8.board).drive, p8.animated_290)

    p8.animated_290 = v3

    local refs = p8.refs

    if refs ~= nil then
        local animated_290 = refs.animated_290

        if animated_290 ~= nil then
            animated_290[1][animated_290[2]] = v3
        end
    end
end

function t1.Effects.enable_animation_angular_only(p9) -- line: 92
    -- upvalues: BoardRuntime (copy), HookDriveState (copy)
    local v4 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p9.board).drive, p9.animated_290)

    p9.animated_290 = v4

    local refs = p9.refs

    if refs ~= nil then
        local animated_290 = refs.animated_290

        if animated_290 ~= nil then
            animated_290[1][animated_290[2]] = v4
        end
    end
end

function t1.Effects.disable_animation(p10) -- line: 100
    -- upvalues: BoardRuntime (copy), HookDriveState (copy)
    local v5 = HookDriveState.disable_animation(BoardRuntime.hook_mut(p10.board).drive, p10.animated_290)

    p10.animated_290 = v5

    local refs = p10.refs

    if refs ~= nil then
        local animated_290 = refs.animated_290

        if animated_290 ~= nil then
            animated_290[1][animated_290[2]] = v5
        end
    end
end

function t1.Effects.disable_linear_drive(p11) -- line: 108
    -- upvalues: BoardRuntime (copy), HookDriveState (copy)
    HookDriveState.disable_linear(BoardRuntime.hook_mut(p11.board).drive)
end

function t1.Effects.standard_board(p12) -- line: 112
    -- upvalues: rt (copy), BoardRuntime (copy), t1 (copy)
    p12.wiping_out = false

    local refs = p12.refs

    if refs ~= nil then
        local wiping_out = refs.wiping_out

        if wiping_out ~= nil then
            wiping_out[1][wiping_out[2]] = false
        end
    end

    BoardRuntime.bodies_mut(p12.board)[7].inertia.angular_drag = p12.standard_angular_drag
    BoardRuntime.set_collision_group(p12.board, 4)
    t1.Materials.set(p12.materials, rt.copy(p12.standard_materials))
    t1.Effects.collision_volumes(p12, true)
end

function t1.Effects.released_board(p13) -- line: 120
    -- upvalues: rt (copy), BoardRuntime (copy), t1 (copy)
    p13.wiping_out = true

    local refs = p13.refs

    if refs ~= nil then
        local wiping_out = refs.wiping_out

        if wiping_out ~= nil then
            wiping_out[1][wiping_out[2]] = true
        end
    end

    BoardRuntime.bodies_mut(p13.board)[7].inertia.angular_drag = 14.999999046325684
    BoardRuntime.set_collision_group(p13.board, 7)
    t1.Materials.set(p13.materials, rt.filled(3, p13.released_material))
    t1.Effects.collision_volumes(p13, true)
end

function t1.Effects.collision_volumes(p14, p15) -- line: 128
    -- upvalues: t1 (copy)
    t1.VolumeFlags.set_enabled(p14.volumes, p15)
end

function t1.Effects.clear_alignment(p16) -- line: 132
    p16.alignment_active = false

    local refs = p16.refs

    if refs ~= nil then
        local alignment_active = refs.alignment_active

        if alignment_active ~= nil then
            alignment_active[1][alignment_active[2]] = false
        end
    end
end

function t1.Effects.alignment(p17, p18) -- line: 136
    -- upvalues: rt (copy)
    rt.assign(p17.alignment, p18)
    p17.alignment_active = true

    local refs = p17.refs

    if refs ~= nil then
        local alignment_active = refs.alignment_active

        if alignment_active ~= nil then
            alignment_active[1][alignment_active[2]] = true
        end
    end
end

function t1.Effects.velocity(p19, p20) -- line: 141
    -- upvalues: BoardRuntime (copy), t1 (copy)
    for _, v6 in BoardRuntime.bodies_mut(p19.board) do
        v6.rates.linear_velocity = t1.xyz(p20)
    end
end

function t1.Effects.position(p21, p22) -- line: 147
    -- upvalues: BoardRuntime (copy), t1 (copy)
    local v7 = BoardRuntime.part_transforms(p21.board)[7]

    v7.translation = t1.xyz(p22)
    BoardRuntime.set_transform(p21.board, v7)
end

function t1.Effects.hook_frame(p23, p24) -- line: 153
    -- upvalues: BoardRuntime (copy), t1 (copy)
    BoardRuntime.set_hook_transform(p23.board, t1.affine(p24))
end

function t1.Effects.target_position_velocity(p25, p26) -- line: 157
    -- upvalues: rt (copy), BoardRuntime (copy), t1 (copy)
    local v8 = rt.copy(BoardRuntime.bodies(p25.board)[7].rates.position)
    local t2 = {}

    for v9, v10 in {
            p26[1] - v8.x,
            p26[2] - v8.y,
            p26[3] - v8.z,
            0
        } do
        t2[v9] = v10 * (1 / p25.processed_dt_2604)
    end

    t1.Effects.velocity(p25, t2)
end

function t1.Effects.torque(p27, p28) -- line: 172
    -- upvalues: rt (copy), Vector3 (copy), BoardRuntime (copy), v1 (copy), t1 (copy)
    local v11 = BoardRuntime.bodies_mut(p27.board)[7]
    local t3 = {}

    for v12, v13 in v11.rates.world_inverse_inertia.columns do
        t3[v12] = {
            v13[1],
            v13[2],
            v13[3],
            0
        }
    end

    local v14 = v1.acceleration_delta(p28, t1.vector(v11.rates.angular_velocity), t3)
    local v15 = rt.copy(v11.rates.torque_acceleration)

    v11.rates.torque_acceleration = Vector3.new(v15.x + v14[1], v15.y + v14[2], v15.z + v14[3])
    v11.rates.cool_down = 0
end

function t1.xyz(p29) -- line: 186
    -- upvalues: Vector3 (copy)
    return Vector3.new(p29[1], p29[2], p29[3])
end

function t1.vector(p30) -- line: 191
    return {
        p30.x,
        p30.y,
        p30.z,
        0
    }
end

function t1.affine(p31) -- line: 196
    -- upvalues: t1 (copy)
    return {
        basis = {
            columns = {
                {
                    p31[1][1],
                    p31[1][2],
                    p31[1][3]
                },
                {
                    p31[2][1],
                    p31[2][2],
                    p31[2][3]
                },
                {
                    p31[3][1],
                    p31[3][2],
                    p31[3][3]
                }
            }
        },
        translation = t1.xyz(p31[4])
    }
end

return t1
