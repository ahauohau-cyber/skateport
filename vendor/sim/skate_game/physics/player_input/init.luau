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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_is_finite(p3) -- line: 24
    if p3 ~= p3 or p3 == 1e999 then
        return false
    end

    return p3 ~= (-1e999)
end

local import = require(sim.import)
local v8 = import("skate_game/physics/player_input/dynamic_normal")
local v9 = import("skate_game/physics/player_input/grind")
local v10 = import("skate_game/physics/player_input/grind_output")
local v11 = import("skate_game/physics/player_input/initial")
local v12 = import("skate_game/physics/player_input/output_reset")
local v13 = import("skate_game/physics/player_input/pre_input")
local v14 = import("skate_game/physics/player_input/reset")
local v15 = import("skate_game/physics/player_input/services")
local Vector3 = import("skate_core/math").Vector3
local BoardDynamicNormal = import("skate_core/physics/board_dynamic_normal").BoardDynamicNormal
local publish_board_input = import("skate_core/physics/board_input_output").publish_board_input
local v16 = import("skate_core/player/input_phase")
local PhysicalPlayerInput, ProcessedPhysicsInput, ProcessedPhysicsSnapshot = v16.PhysicalPlayerInput, v16.ProcessedPhysicsInput, v16.ProcessedPhysicsSnapshot
local v17 = false
local t1 = {}

t1.reset_outputs = v12.reset_outputs

local reset_outputs = v12.reset_outputs

t1.InputHostFrame = v15.InputHostFrame
t1.PlayerInputCallbacks = v15.PlayerInputCallbacks
t1.InputStage = {}
t1.PlayerInputRuntime = {}

function t1.PlayerInputRuntime.pending_teleport(p4) -- line: 74
    -- upvalues: rt (copy)
    return rt.copy(p4.pending_teleport)
end

function t1.PlayerInputRuntime.request_teleport(p5, p6) -- line: 79
    -- upvalues: t1 (copy)
    return t1.PlayerInputRuntime.request_teleport_ex(p5, p6, nil)
end

function t1.PlayerInputRuntime.request_teleport_ex(p7, p8, p9) -- line: 84
    -- upvalues: rt (copy)
    if p7.pending_teleport ~= nil then
        error("A pending teleport must complete before replacement", 0)
    end

    if p9 ~= nil then
        for _, v18 in p9 do
            if v18 ~= v18 or v18 == 1e999 or v18 == (-1e999) or math.abs(v18) > 200 then
                error("Teleport velocity out of range", 0)
            end
        end
    end

    p7.pending_teleport = rt.copy(p8)
    p7.pending_velocity = rt.copy(p9)
end

function t1.PlayerInputRuntime.load(p10) -- line: 101
    -- upvalues: v8 (copy), v9 (copy), v11 (copy), v13 (copy), v14 (copy), BoardDynamicNormal (copy), PhysicalPlayerInput (copy), ProcessedPhysicsInput (copy), reset_outputs (copy)
    local v19 = PhysicalPlayerInput.default()

    reset_outputs(v19)

    local v20 = ProcessedPhysicsInput.default()

    v14.reset_processed(v20)

    return {
        toolkit = nil,
        pending_teleport = nil,
        pending_velocity = nil,
        pending_grind = nil,
        grind_observation = nil,
        player = v11.player(p10),
        physical = v19,
        processed = v20,
        dynamic_normal = BoardDynamicNormal.new(),
        normal_settings = v8.settings(p10),
        pre_input = v13.PreInputManager.new(),
        grind = v9.GrindInputState.load(p10)
    }
end

function t1.PlayerInputRuntime.processed_snapshot(p11, p12) -- line: 133
    -- upvalues: t1 (copy), v17 (ref)
    if v17 then
        return t1.PlayerInputRuntime.processed_snapshot_reference(p11, p12)
    end

    return {
        tick = p12,
        input = p11.processed
    }
end

function t1.PlayerInputRuntime.processed_snapshot_reference(p13, p14) -- line: 141
    -- upvalues: ProcessedPhysicsSnapshot (copy)
    return ProcessedPhysicsSnapshot.new(p14, p13.processed)
end

function t1.PlayerInputRuntime.update_dynamic_normal(p15, p16, p17) -- line: 147
    -- upvalues: BoardDynamicNormal (copy)
    BoardDynamicNormal.update(p15.dynamic_normal, p16.ground, p17, p15.processed.scalar_2656, p15.normal_settings)
end

function t1.PlayerInputRuntime.publish_board(p18, p19) -- line: 159
    -- upvalues: rt (copy), v1 (copy), publish_board_input (copy), t1 (copy)
    local toolkit = p18.toolkit

    if toolkit == nil then
        error("Board output requires the current input toolkit", 0)
    end

    publish_board_input(p18.physical, p19.motion, p19.ground, {
        processed_forward = t1.xyz(toolkit.deck[3]),
        reckoning_normal_1216 = rt.copy(p19.reckoning.ground_normal),
        reckoning_ground_up = t1.xyz(p19.reckoning_frames.ground[2]),
        retained_ground_normal_112 = rt.copy(p18.dynamic_normal.normal),
        processed_flags_2476 = p18.processed.flags_2476
    })

    local wheel_normal = p19.ground.wheel_normal
    local ground = p18.physical.ground
    local x = wheel_normal.x
    local v21

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v22 = math.abs(x) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if x < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v21 = buffer.readu32(v1, 0)
    end

    local y = wheel_normal.y
    local v25

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v26 = math.abs(y) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27

        if y < 0 then
            v25 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v25 = buffer.readu32(v1, 0)
    end

    local z = wheel_normal.z
    local v29

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v30 = math.abs(z) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

        if z < 0 then
            v29 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v29 = buffer.readu32(v1, 0)
    end

    buffer.writef32(v1, 0, 0)
    ground.vector_80 = {
        v21,
        v25,
        v29,
        (buffer.readu32(v1, 0))
    }
    p18.physical.ground.flag_273 = bit32.band(p18.processed.flags_2468, 1048576) == 0 and 0 or 1
end

local function debug_error(p20) -- line: 179
    if type(p20) ~= "table" or p20.tag ~= "Service" then
        if type(p20) ~= "table" or p20.tag ~= "InvalidStateVariant" then
            return (tostring(p20))
        end

        return "InvalidStateVariant(" .. tostring(p20[1]) .. ")"
    end

    local v36 = tostring(p20[1])
    local v37 = string.gsub(v36, "\\", "\\\\")
    local v38 = string.gsub(v37, "\"", "\\\"")
    local v39 = string.gsub(v38, "\n", "\\n")
    local v40 = string.gsub(v39, "\r", "\\r")

    return "Service(\"" .. string.gsub(v40, "\t", "\\t") .. "\")"
end

local t3 = {
    "update_pre_input_manager_82d81610",
    "reset_processed_input_82bf9ef0",
    "actor_query_slot_56",
    "actor_query_slot_44",
    "reset_player_probe_82d7a330",
    "check_teleport_82db88c8",
    "actor_input_available_slot_4",
    "transition_action_825903c8",
    "calculate_ground_position_82c02840",
    "prepare_board_toolkit_82c013f0",
    "process_skeleton_82bd8918",
    "update_grind_manager_82d8a828"
}
local v41
local t4 = {
    "board",
    "ground",
    "ground_frame",
    "host",
    "callbacks",
    "pre_input",
    "grind",
    "world",
    "world_edges",
    "pending_grind",
    "toolkit",
    "pending_teleport",
    "pending_velocity"
}
local v42
local v43 = false

function t1.set_reference(p21) -- line: 235
    -- upvalues: v17 (ref)
    v17 = p21
end

function t1.PlayerInputRuntime.process_stage(p22, p23, p24, p25, p26, p27, p28, p29, p30, p31) -- line: 258
    -- upvalues: v15 (copy), v16 (copy), t1 (copy), v17 (ref), debug_error (copy), t3 (copy), v41 (ref), t4 (copy), v42 (ref), v43 (ref)
    if v17 then
        return t1.PlayerInputRuntime.process_stage_reference(p22, p23, p24, p25, p26, p27, p28, p29, p30, p31)
    end

    local v44 = v41

    if v44 == nil then
        v44 = {}

        for _, v45 in t3 do
            v44[v45] = v15.Services[v45]
        end

        v41 = v44
    end

    local v46 = not v43
    local v47

    if v46 then
        v47 = v42

        if v47 == nil then
            v47 = table.clone(v44)
            v42 = v47
        end

        v43 = true
    else
        v47 = table.clone(v44)
    end

    v47.board = p23
    v47.ground = p24
    v47.ground_frame = p25
    v47.host = p27
    v47.callbacks = p28
    v47.pre_input = p22.pre_input
    v47.grind = p22.grind
    v47.world = p30
    v47.world_edges = p31
    v47.pending_grind = p22.pending_grind
    v47.toolkit = p22.toolkit
    v47.pending_teleport = p22.pending_teleport
    v47.pending_velocity = p22.pending_velocity

    local ok, result

    if p29.tag == "ThroughTeleport" then
        local start_input = v16.start_input
        local player, physical, processed = p22.player, p22.physical, p22.processed

        ok, result = pcall(start_input, player, physical, p26, processed, v47)
    else
        local v48 = p29[1]
        local finish_input = v16.finish_input
        local player, physical, processed = p22.player, p22.physical, p22.processed

        ok, result = pcall(finish_input, v48, player, physical, p26, processed, v47)

        if ok then
            result = nil
        end
    end

    p22.pending_grind = v47.pending_grind
    p22.toolkit = v47.toolkit
    p22.pending_teleport = v47.pending_teleport
    p22.pending_velocity = v47.pending_velocity

    if v46 then
        for _, v49 in t4 do
            v47[v49] = nil
        end

        v43 = false
    end

    if not ok then
        error("Player input: " .. debug_error(result), 0)
    end

    return result
end

function t1.PlayerInputRuntime.process_stage_reference(p32, p33, p34, p35, p36, p37, p38, p39, p40, p41) -- line: 352
    -- upvalues: rt (copy), v15 (copy), v16 (copy), debug_error (copy)
    local Services = v15.Services
    local t5 = {
        board = p33,
        ground = p34,
        ground_frame = rt.copy(p35),
        host = rt.copy(p37),
        callbacks = p38,
        pre_input = p32.pre_input,
        grind = p32.grind,
        world = p40,
        world_edges = p41,
        pending_grind = p32.pending_grind,
        toolkit = p32.toolkit,
        pending_teleport = p32.pending_teleport,
        pending_velocity = p32.pending_velocity
    }
    local t6 = {
        update_pre_input_manager_82d81610 = function(_, ...) -- update_pre_input_manager_82d81610 | line: 383
            -- upvalues: Services (copy), t5 (copy)
            return Services.update_pre_input_manager_82d81610(t5, ...)
        end,
        reset_processed_input_82bf9ef0 = function(_, ...) -- reset_processed_input_82bf9ef0 | line: 386
            -- upvalues: Services (copy), t5 (copy)
            return Services.reset_processed_input_82bf9ef0(t5, ...)
        end,
        actor_query_slot_56 = function(_, ...) -- actor_query_slot_56 | line: 389
            -- upvalues: Services (copy), t5 (copy)
            return Services.actor_query_slot_56(t5, ...)
        end,
        actor_query_slot_44 = function(_, ...) -- actor_query_slot_44 | line: 392
            -- upvalues: Services (copy), t5 (copy)
            return Services.actor_query_slot_44(t5, ...)
        end,
        reset_player_probe_82d7a330 = function(_, ...) -- reset_player_probe_82d7a330 | line: 395
            -- upvalues: Services (copy), t5 (copy)
            return Services.reset_player_probe_82d7a330(t5, ...)
        end,
        check_teleport_82db88c8 = function(_, ...) -- check_teleport_82db88c8 | line: 398
            -- upvalues: Services (copy), t5 (copy)
            return Services.check_teleport_82db88c8(t5, ...)
        end,
        actor_input_available_slot_4 = function(_, ...) -- actor_input_available_slot_4 | line: 401
            -- upvalues: Services (copy), t5 (copy)
            return Services.actor_input_available_slot_4(t5, ...)
        end,
        transition_action_825903c8 = function(_, ...) -- transition_action_825903c8 | line: 404
            -- upvalues: Services (copy), t5 (copy)
            return Services.transition_action_825903c8(t5, ...)
        end,
        calculate_ground_position_82c02840 = function(_, ...) -- calculate_ground_position_82c02840 | line: 407
            -- upvalues: Services (copy), t5 (copy)
            return Services.calculate_ground_position_82c02840(t5, ...)
        end,
        prepare_board_toolkit_82c013f0 = function(_, ...) -- prepare_board_toolkit_82c013f0 | line: 410
            -- upvalues: Services (copy), t5 (copy)
            return Services.prepare_board_toolkit_82c013f0(t5, ...)
        end,
        process_skeleton_82bd8918 = function(_, ...) -- process_skeleton_82bd8918 | line: 413
            -- upvalues: Services (copy), t5 (copy)
            return Services.process_skeleton_82bd8918(t5, ...)
        end,
        update_grind_manager_82d8a828 = function(_, ...) -- update_grind_manager_82d8a828 | line: 416
            -- upvalues: Services (copy), t5 (copy)
            return Services.update_grind_manager_82d8a828(t5, ...)
        end
    }
    local ok, result

    if p39.tag == "ThroughTeleport" then
        local start_input = v16.start_input
        local player, physical, processed = p32.player, p32.physical, p32.processed

        ok, result = pcall(start_input, player, physical, p36, processed, t6)
    else
        local v50 = p39[1]
        local finish_input = v16.finish_input
        local player, physical, processed = p32.player, p32.physical, p32.processed

        ok, result = pcall(finish_input, v50, player, physical, p36, processed, t6)

        if ok then
            result = nil
        end
    end

    p32.pending_grind = t5.pending_grind
    p32.toolkit = t5.toolkit
    p32.pending_teleport = t5.pending_teleport
    p32.pending_velocity = t5.pending_velocity

    if not ok then
        error("Player input: " .. debug_error(result), 0)
    end

    return result
end

for v51, v52 in v10.PlayerInputRuntime do
    t1.PlayerInputRuntime[v51] = v52
end

function t1.xyz(p54) -- line: 456
    -- upvalues: Vector3 (copy)
    return Vector3.new(p54[1], p54[2], p54[3])
end

return t1
