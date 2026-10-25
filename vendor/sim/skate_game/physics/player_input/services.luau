-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/player_input/pre_input")
local v2 = import("skate_game/physics/player_input/reset")
local v3 = import("skate_game/physics/player_input/ground_position")
local GroundRuntime = import("skate_game/physics/ground_runtime").GroundRuntime
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local ProbeFields = import("skate_core/player/input_phase").ProbeFields
local PreInputManager = v1.PreInputManager
local v4 = import("skate_core/player/input_phase")
local assign_into = v4.assign_into
local v5 = false
local t1 = {}

function t1.set_reference(p1) -- line: 28
    -- upvalues: v5 (ref)
    v5 = p1
end

local v6 = v4.freeze_deep(ProbeFields.default())
local t2 = {
    0, 0, 0, 0
}

t1.InputHostFrame = {}
t1.PlayerInputCallbacks = {}
t1.Services = {}

function t1.Services.update_pre_input_manager_82d81610(p2, p3, _) -- line: 71
    -- upvalues: PreInputManager (copy)
    local prepare = PreInputManager.prepare
    local pre_input = p2.pre_input
    local manager_1856_counter_320 = p3.manager_1856_counter_320
    local ok, result = pcall(prepare, pre_input, manager_1856_counter_320)

    if not ok then
        p3.manager_1856_counter_320 = 30
        error(result, 0)
    end

    p3.manager_1856_counter_320 = result
end

function t1.Services.reset_processed_input_82bf9ef0(_, p6) -- line: 81
    -- upvalues: v2 (copy)
    v2.reset_processed(p6)
end

function t1.Services.actor_query_slot_56(p7) -- line: 85
    return p7.host.actor_query_56
end

function t1.Services.actor_query_slot_44(p8) -- line: 89
    return p8.host.actor_query_44
end

function t1.Services.reset_player_probe_82d7a330(p9, p10, p11) -- line: 97
    -- upvalues: assign_into (copy), t1 (copy), v5 (ref), v6 (copy)
    local probe = p10.probe

    if v5 or type(probe) ~= "table" then
        return t1.Services.reset_player_probe_82d7a330_reference(p9, p10, p11)
    end

    assign_into(probe, v6)
end

function t1.Services.reset_player_probe_82d7a330_reference(_, p13, _) -- line: 106
    -- upvalues: ProbeFields (copy)
    p13.probe = ProbeFields.default()
end

function t1.Services.check_teleport_82db88c8(p15, p16, p17, p18) -- line: 111
    -- upvalues: rt (copy), BoardRuntime (copy), t1 (copy)
    if p17.state.flag_61 ~= 0 then
        local v7 = rt.copy(p15.host.published_board_transform)

        p15.callbacks.teleport(p15.callbacks, p15.board, p15.ground, v7, p16, p17, p18)
    end

    if bit32.band(p16.flags_1296, 524288) ~= 0 then
        local v8 = BoardRuntime.part_transforms(p15.board)[7]
        local v9 = rt.filled(4, table.create(4, 0))
        local v10 = v8.basis.columns[1]
        local v11 = v9[1]
        local v12 = v10[1]
        local v13 = v10[2]
        local v14 = v10[3]

        v11[1] = v12
        v11[2] = v13
        v11[3] = v14

        local v15 = v8.basis.columns[2]
        local v16 = v9[2]
        local v17 = v15[1]
        local v18 = v15[2]
        local v19 = v15[3]

        v16[1] = v17
        v16[2] = v18
        v16[3] = v19

        local v20 = v8.basis.columns[3]
        local v21 = v9[3]
        local v22 = v20[1]
        local v23 = v20[2]
        local v24 = v20[3]

        v21[1] = v22
        v21[2] = v23
        v21[3] = v24

        local translation = v8.translation

        v9[4] = {
            translation.x,
            translation.y,
            translation.z,
            0
        }
        p15.callbacks.teleport(p15.callbacks, p15.board, p15.ground, v9, p16, p17, p18)
        p16.flags_1296 = bit32.band(p16.flags_1296, 4294443007)
    end

    if p15.pending_teleport == nil then
        return
    end

    local v25 = rt.copy(p15.pending_teleport)

    p15.callbacks.teleport(p15.callbacks, p15.board, p15.ground, v25, p16, p17, p18)
    p15.pending_teleport = nil

    local pending_velocity = p15.pending_velocity

    p15.pending_velocity = nil

    if pending_velocity ~= nil then
        t1.apply_board_linvel(p15.board, pending_velocity)
    end
end

function t1.Services.actor_input_available_slot_4(p19) -- line: 143
    return p19.host.input_available
end

function t1.Services.transition_action_825903c8(p20) -- line: 147
    return p20.host.transition_action
end

function t1.Services.calculate_ground_position_82c02840(p21, p22) -- line: 155
    -- upvalues: v3 (copy), t1 (copy), v5 (ref), t2 (copy)
    if v5 then
        return t1.Services.calculate_ground_position_82c02840_reference(p21, p22)
    end

    return v3.ground_position_into(p21.board, p21.ground_frame, t2)
end

function t1.Services.calculate_ground_position_82c02840_reference(p23, _) -- line: 163
    -- upvalues: v3 (copy)
    return v3.ground_position(p23.board, p23.ground_frame)
end

function t1.Services.prepare_board_toolkit_82c013f0(p25, _, _, p28) -- line: 167
    -- upvalues: GroundRuntime (copy)
    local v26 = GroundRuntime.prepare_toolkit(p25.ground, p25.board, p28)

    p28.scalar_2616 = v26.absolute_speed
    p25.toolkit = v26
end

function t1.Services.process_skeleton_82bd8918(p29, p30, p31, p32) -- line: 174
    local toolkit = p29.toolkit

    if toolkit == nil then
        error("Input toolkit must precede Skeleton::ProcessData", 0)
    end

    return p29.callbacks.process_skeleton(p29.callbacks, p29.board, toolkit, p30, p31, p32)
end

function t1.Services.update_grind_manager_82d8a828(p33, _, _, p36) -- line: 182
    if p33.pending_grind ~= nil then
        error("Previous grind input was not consumed by PostInput", 0)
    end

    p33.pending_grind = p33.callbacks.prepare_grind(p33.callbacks, p33.board, p33.grind, p36, p33.world, p33.world_edges, p33.host.air_counter_40)
end

function t1.apply_board_linvel(p37, p38) -- line: 198
    -- upvalues: rt (copy), Vector3 (copy), BoardRuntime (copy)
    local v27 = Vector3.new(p38[1], p38[2], p38[3])

    for _, v28 in BoardRuntime.bodies_mut(p37) do
        v28.rates.linear_velocity = rt.copy(v27)
    end
end

return t1
