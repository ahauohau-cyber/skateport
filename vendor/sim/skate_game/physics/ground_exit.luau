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
local GroundRuntime = import("skate_game/physics/ground_runtime").GroundRuntime
local clamp_jump_velocity = import("skate_core/air/state").clamp_jump_velocity
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local PumpingState = import("skate_core/riding/pumping/state").PumpingState

return {
    exit = function(p2, p3) -- exit | line: 24
        -- upvalues: rt (copy), v1 (copy), GroundRuntime (copy), clamp_jump_velocity (copy), BoardRuntime (copy), PumpingState (copy)
        local state = p3.ground.state

        state.steering_damped_turn_2644 = 0
        state.steering_push_scalar_2640 = 1
        PumpingState.reset(p3.ground.pumping)

        local v2 = BoardRuntime.bodies_mut(p2.board)

        for i = 1, #v2 do
            v2[i].inertia.linear_drag = 0
        end

        p2.settings.wheel_material = rt.copy(p2.settings.standard_wheel_material)

        if state.flag_2708 then
            local processed = p3.player_input.processed
            local t2 = {
                0,
                processed.gravity_2648,
                0, 0
            }
            local t3 = {
                t2[1] * processed.timestep_2604 + state.vector_2688[1],
                t2[2] * processed.timestep_2604 + state.vector_2688[2],
                t2[3] * processed.timestep_2604 + state.vector_2688[3],
                t2[4] * processed.timestep_2604 + state.vector_2688[4]
            }

            buffer.writeu32(v1, 0, processed.vectors_400_416[1][1])

            local v4 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, processed.vectors_400_416[1][2])

            local v6 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, processed.vectors_400_416[1][3])

            local v8 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, processed.vectors_400_416[1][4])

            local v10 = clamp_jump_velocity(t3, {
                v4,
                v6,
                v8,
                (buffer.readf32(v1, 0))
            })

            GroundRuntime.set_animated_velocity(p3.ground_runtime, p2.board, v10)
        end
    end
}
