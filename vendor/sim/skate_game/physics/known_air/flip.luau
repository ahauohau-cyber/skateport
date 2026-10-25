-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/known_air/math")
local IDENTITY = import("skate_core/physics/skeleton_animation_record").IDENTITY
local rotate, scale, normalized, xyz = v1.rotate, v1.scale, v1.normalized, v1.xyz
local t1 = {
    Runtime = {}
}

function t1.Runtime.reset_flip(p1) -- line: 19
    -- upvalues: rt (copy), IDENTITY (copy), rotate (copy), xyz (copy)
    local reckoning_frames = p1.physics.riding.reckoning_frames
    local up = p1.physics.riding.reckoning.up
    local v2 = rotate(reckoning_frames.body_flip, {
        up.x,
        up.y,
        up.z,
        0
    })

    p1.physics.riding.reckoning.up = xyz(v2)
    reckoning_frames.heading = rotate(reckoning_frames.body_flip, reckoning_frames.heading)
    reckoning_frames.body_flip = rt.copy(IDENTITY)

    local state = p1.skater.air_reckoning.state

    state.flip_active = false
    state.flip_speed = 0
    state.flip_side = false
    state.flip_angle = 0
end

function t1.Runtime.begin_flip(p2, p3) -- line: 33
    -- upvalues: rt (copy), IDENTITY (copy), scale (copy), normalized (copy)
    local state = p2.skater.air_reckoning.state

    if state.flip_active then
        return
    end

    p2.physics.riding.reckoning_frames.body_flip = rt.copy(IDENTITY)
    state.flip_speed = 0
    state.flip_angle = 0

    local v3 = rt.copy(p2.physics.riding.reckoning_frames.system)

    if p2.toolkit.control_sign < 0 then
        v3[1] = scale(v3[1], -1)
        v3[3] = scale(v3[3], -1)
    end

    local v4 = p2.skater.animation_input.fields.body_spin * 4

    if -v4 >= 0 then
        v4 = 0
    end

    if not (1 - v4 >= 0) then
        v4 = 1
    end

    local v5 = scale(p2.skater.known_air.flip_axis_adjustment, v4)
    local v6 = table.create(4)

    for i = 1, 4 do
        v6[i] = v3[3][i] * v5[3] + (v3[2][i] * v5[2] + v3[1][i])
    end

    state.flip_axis = normalized(v6)

    if p3 then
        state.flip_axis = scale(state.flip_axis, -1)
    end

    state.flip_side = p3
    state.flip_active = true
end

return t1
