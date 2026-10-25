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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_game/physics/ground_animation/board")
local v9 = import("skate_game/physics/ground_animation/settings")
local v10 = import("skate_game/physics/ground_animation/skeleton")
local GroundRuntime = import("skate_game/physics/ground_runtime").GroundRuntime
local RidingOutputs = import("skate_game/physics/riding_outputs").RidingOutputs
local GroundJump = import("skate_core/air/ground_jump").GroundJump
local clamp_jump_velocity = import("skate_core/air/state").clamp_jump_velocity
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local t1 = {
    GroundAnimationSettings = v9.GroundAnimationSettings
}

local function from_bits4(p4) -- line: 52
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p4[1])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[2])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[3])

    local v16 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[4])

    return {
        v12,
        v14,
        v16,
        (buffer.readf32(v1, 0))
    }
end

t1.GroundAnimationRuntime = {}

function t1.GroundAnimationRuntime.default() -- line: 63
    -- upvalues: GroundJump (copy)
    return {
        launched = false,
        jump = GroundJump.default(),
        launch_velocity = { 0, 0, 0, 0 }
    }
end

function t1.GroundAnimationRuntime.fill(p5, p6, p7) -- line: 72
    -- upvalues: v1 (copy)
    if bit32.band(p6.flags_2468, 4194304) ~= 0 then
        local v18 = p5.jump.velocity[1]

        buffer.writeu32(v1, 0, p6.vectors_400_416[1][1])

        local v20 = v18 - buffer.readf32(v1, 0)
        local v21

        if v20 == 0 then
            buffer.writef32(v1, 0, v20)
            v21 = buffer.readu32(v1, 0)
        elseif v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
            local v22 = math.abs(v20) * 7.1362384635298E+44

            v21 = math.floor(v22)

            local v23 = v22 - v21

            if v23 > 0.5 or v23 == 0.5 and v21 % 2 == 1 then
                v21 += 1
            end

            if v20 < 0 then
                v21 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v20)
            v21 = buffer.readu32(v1, 0)
        end

        local v24 = p5.jump.velocity[2]

        buffer.writeu32(v1, 0, p6.vectors_400_416[1][2])

        local v26 = v24 - buffer.readf32(v1, 0)
        local v27

        if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
            local v28 = math.abs(v26) * 7.1362384635298E+44
            local v29 = math.floor(v28)
            local v30 = v28 - v29

            v27 = if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29

            if v26 < 0 then
                v27 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v26)
            v27 = buffer.readu32(v1, 0)
        end

        local v31 = p5.jump.velocity[3]

        buffer.writeu32(v1, 0, p6.vectors_400_416[1][3])

        local v33 = v31 - buffer.readf32(v1, 0)
        local v34

        if v33 ~= 0 and v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
            local v35 = math.abs(v33) * 7.1362384635298E+44
            local v36 = math.floor(v35)
            local v37 = v35 - v36

            v34 = if v37 > 0.5 or v37 == 0.5 and v36 % 2 == 1 then v36 + 1 else v36

            if v33 < 0 then
                v34 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v33)
            v34 = buffer.readu32(v1, 0)
        end

        local v38 = p5.jump.velocity[4]

        buffer.writeu32(v1, 0, p6.vectors_400_416[1][4])

        local v40 = v38 - buffer.readf32(v1, 0)
        local v41

        if v40 ~= 0 and v40 > -1.1754943508222875E-38 and v40 < 1.1754943508222875E-38 then
            local v42 = math.abs(v40) * 7.1362384635298E+44
            local v43 = math.floor(v42)
            local v44 = v42 - v43

            v41 = if v44 > 0.5 or v44 == 0.5 and v43 % 2 == 1 then v43 + 1 else v43

            if v40 < 0 then
                v41 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v40)
            v41 = buffer.readu32(v1, 0)
        end

        p7.jump_velocity_delta_112 = {
            v21,
            v27,
            v34,
            v41
        }
    end

    if p5.launched then
        p7.launched_442 = 1

        local v45 = p5.launch_velocity[1]
        local v46

        if v45 == 0 then
            buffer.writef32(v1, 0, v45)
            v46 = buffer.readu32(v1, 0)
        elseif v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
            local v47 = math.abs(v45) * 7.1362384635298E+44

            v46 = math.floor(v47)

            local v48 = v47 - v46

            if v48 > 0.5 or v48 == 0.5 and v46 % 2 == 1 then
                v46 += 1
            end

            if v45 < 0 then
                v46 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v45)
            v46 = buffer.readu32(v1, 0)
        end

        local v49 = p5.launch_velocity[2]
        local v50

        if v49 ~= 0 and v49 > -1.1754943508222875E-38 and v49 < 1.1754943508222875E-38 then
            local v51 = math.abs(v49) * 7.1362384635298E+44
            local v52 = math.floor(v51)
            local v53 = v51 - v52

            v50 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

            if v49 < 0 then
                v50 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v49)
            v50 = buffer.readu32(v1, 0)
        end

        local v54 = p5.launch_velocity[3]
        local v55

        if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
            local v56 = math.abs(v54) * 7.1362384635298E+44
            local v57 = math.floor(v56)
            local v58 = v56 - v57

            v55 = if v58 > 0.5 or v58 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

            if v54 < 0 then
                v55 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v54)
            v55 = buffer.readu32(v1, 0)
        end

        local v59 = p5.launch_velocity[4]
        local v60

        if v59 ~= 0 and v59 > -1.1754943508222875E-38 and v59 < 1.1754943508222875E-38 then
            local v61 = math.abs(v59) * 7.1362384635298E+44
            local v62 = math.floor(v61)
            local v63 = v61 - v62

            v60 = if v63 > 0.5 or v63 == 0.5 and v62 % 2 == 1 then v62 + 1 else v62

            if v59 < 0 then
                v60 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v59)
            v60 = buffer.readu32(v1, 0)
        end

        p7.launch_velocity_128 = {
            v46,
            v50,
            v55,
            v60
        }
    end
end

function t1.enter(p8, p9) -- line: 92
    -- upvalues: BoardRuntime (copy), HookDriveState (copy)
    p9.ground_animation.launched = false
    p9.ground_animation.launch_velocity = { 0, 0, 0, 0 }

    local ground_lifecycle = p9.ground_lifecycle

    ground_lifecycle.skeleton_elapsed_16505 = true
    ground_lifecycle.board_animated_290 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p8.board).drive, ground_lifecycle.board_animated_290)

    if p9.wipeout.state.mode ~= 1 then
        p9.wipeout.state.mode = 1
        p9.wipeout.state.balance = 0
    end
end

function t1.advance(p10, p11) -- line: 105
    -- upvalues: rt (copy), v8 (copy), v10 (copy), RidingOutputs (copy), Vector3 (copy), from_bits4 (copy)
    p11.ground_animation.launched = false

    local processed = p11.player_input.processed
    local v64 = from_bits4(processed.animation_com_to_deck_752)
    local v65 = rt.copy(p10.riding.reckoning_frames.heading)

    RidingOutputs.update_ground_reckoning_with_heading(p10.riding, p10.board, {
        com_to_deck = Vector3.new(v64[1], v64[2], v64[3]),
        body_spin = p11.animation_input.extra.physical_body_spin
    }, processed.flags_2468, p11.animation_input.fields.balance, bit32.band(processed.flags_2476, 1073741824) ~= 0, processed, v65)
    v10.advance(p10, p11)
    p11.skeleton_output.correction.pending = true

    return v8.advance(p10, p11)
end

function t1.exit(p12, p13) -- line: 128
    -- upvalues: rt (copy), v8 (copy), GroundRuntime (copy), GroundJump (copy), clamp_jump_velocity (copy), from_bits4 (copy)
    v8.set_drag(p12, 0)
    p12.settings.wheel_material = rt.copy(p12.settings.standard_wheel_material)

    if p13.ground_animation.jump.active then
        local processed = p13.player_input.processed
        local v66 = rt.copy(p13.ground_animation.jump.velocity)

        v66[2] = processed.gravity_2648 * processed.timestep_2604 + v66[2]

        local v67 = clamp_jump_velocity(v66, (from_bits4(processed.vectors_400_416[1])))

        GroundRuntime.set_animated_velocity(p13.ground_runtime, p12.board, v67)
    end

    p13.ground_animation.jump = GroundJump.default()
end

return t1
