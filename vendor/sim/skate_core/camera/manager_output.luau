-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local v2 = import("skate_core/camera/manager_frame")
local v3 = import("skate_core/camera/shake")
local length = v1.length
local CameraFrame = v2.CameraFrame
local ShakeEffect = v3.ShakeEffect
local t1 = {
    CameraMan = {}
}

function t1.CameraMan.finish_frame_reference(p1, p2, p3, p4, p5, p6) -- line: 23
    -- upvalues: rt (copy), length (copy), CameraFrame (copy), ShakeEffect (copy)
    local v4 = rt.copy(p1.frame.basis)
    local v5 = rt.copy(p1.frame.position)
    local v6 = rt.copy(p1.orientation.basis)
    local v7 = rt.copy(p1.rig.positioner.position)

    CameraFrame.motion(p1.frame, p2, v6, v7)

    local v8 = p3.rig.wiping_out == 0 or bit32.band(p1.rig.positioner.flags, 128) ~= 0 or p3.rig.broken_bone_slowmo ~= 0
    local v9 = rt.copy(p1.rig.fields.velocity)
    local v10 = length({
        v9[1],
        0,
        v9[3],
        0
    }) * (if p3.flag_652 == 0 then 1 else 0.8799999952316284)
    local v11 = length({
        p1.rig.fields.anchor[1] - v7[1],
        p1.rig.fields.anchor[2] - v7[2],
        p1.rig.fields.anchor[3] - v7[3],
        p1.rig.fields.anchor[4] - v7[4]
    })
    local v12 = ShakeEffect.update(p1.shake[1], p2, v10, v11, v6, v8, p5[1], p4)
    local update = ShakeEffect.update
    local v13 = p1.shake[2]

    if p3.shake_variant ~= 0 then
        v10 *= 50
    end

    local v14 = update(v13, p2, v10, v11, v6, v8, p5[2], p4)
    local v15 = if p3.shake_variant == 0 then 0 else 1

    p1.frame.basis = rt.copy(({ v12, v14 })[v15 + 1])
    p1.frame.position = rt.copy(v7)
    p1.frame.shake_translation = rt.copy(p1.shake[v15 + 1].translation)
    p1.rig.fields.offset = rt.copy(p1.frame.shake_translation)

    local frame = p1.frame

    if bit32.band(p1.rig.positioner.flags, 64) == 0 then
        frame.discontinuity = p6
    else
        frame.discontinuity = true
    end

    if p1.frame.discontinuity then
        p1.frame.previous_basis = rt.copy(p1.frame.basis)
        p1.frame.previous_position = rt.copy(v7)
    else
        p1.frame.previous_basis = v4
        p1.frame.previous_position = v5
    end

    p1.frame.field_of_view_degrees = p1.state.field_of_view
    p1.frame.opacity = p1.state.opacity
    p1.frame.blur = p1.state.blur
end

local PERF = import("skate_core/camera/tracker").PERF
local length3 = v1.length3

local function copy_basis(p7, p8) -- line: 94
    local columns = p7.columns
    local columns2 = p8.columns
    local v16 = columns[1]
    local v17 = columns2[1]
    local v18 = v17[1]
    local v19 = v17[2]
    local v20 = v17[3]

    v16[1] = v18
    v16[2] = v19
    v16[3] = v20

    local v21 = columns[2]
    local v22 = columns2[2]
    local v23 = v22[1]
    local v24 = v22[2]
    local v25 = v22[3]

    v21[1] = v23
    v21[2] = v24
    v21[3] = v25

    local v26 = columns[3]
    local v27 = columns2[3]
    local v28 = v27[1]
    local v29 = v27[2]
    local v30 = v27[3]

    v26[1] = v28
    v26[2] = v29
    v26[3] = v30
end

function t1.CameraMan.finish_frame(p9, p10, p11, p12, p13, p14) -- line: 103
    -- upvalues: CameraFrame (copy), ShakeEffect (copy), t1 (copy), PERF (copy), length3 (copy), copy_basis (copy)
    if PERF.reference then
        return t1.CameraMan.finish_frame_reference(p9, p10, p11, p12, p13, p14)
    end

    local frame, rig = p9.frame, p9.rig
    local positioner, fields = rig.positioner, rig.fields
    local basis = p9.orientation.basis
    local position = positioner.position
    local v31 = position[1]
    local v32 = position[2]
    local v33 = position[3]
    local v34 = position[4]

    CameraFrame.motion(frame, p10, basis, position)

    local rig2 = p11.rig
    local flags = positioner.flags
    local v35 = rig2.wiping_out == 0 or bit32.band(flags, 128) ~= 0 or rig2.broken_bone_slowmo ~= 0
    local velocity = fields.velocity
    local v36 = length3(velocity[1], 0, velocity[3]) * (if p11.flag_652 == 0 then 1 else 0.8799999952316284)
    local anchor = fields.anchor
    local v37 = length3(anchor[1] - v31, anchor[2] - v32, anchor[3] - v33)
    local v38 = p11.shake_variant ~= 0
    local v39 = bit32.band(flags, 64) ~= 0 or p14
    local position2 = frame.position

    if not v39 then
        copy_basis(frame.previous_basis, frame.basis)

        local previous_position = frame.previous_position
        local v40 = position2[1]
        local v41 = position2[2]
        local v42 = position2[3]
        local v43 = position2[4]

        previous_position[1] = v40
        previous_position[2] = v41
        previous_position[3] = v42
        previous_position[4] = v43
    end

    local shake = p9.shake
    local basis2 = frame.basis

    ShakeEffect.update_into(shake[1], p10, v36, v37, basis, v35, p13[1], p12, if v38 then nil else basis2)

    local update_into = ShakeEffect.update_into
    local v44 = shake[2]

    if v38 then
        v36 *= 50
    end

    update_into(v44, p10, v36, v37, basis, v35, p13[2], p12, if v38 then basis2 else nil)
    position2[1] = v31
    position2[2] = v32
    position2[3] = v33
    position2[4] = v34

    local translation = shake[if v38 then 2 else 1].translation
    local v45 = translation[1]
    local v46 = translation[2]
    local v47 = translation[3]
    local v48 = translation[4]
    local shake_translation = frame.shake_translation

    shake_translation[1] = v45
    shake_translation[2] = v46
    shake_translation[3] = v47
    shake_translation[4] = v48

    local offset = fields.offset

    offset[1] = v45
    offset[2] = v46
    offset[3] = v47
    offset[4] = v48
    frame.discontinuity = v39

    if v39 then
        copy_basis(frame.previous_basis, basis2)

        local previous_position = frame.previous_position

        previous_position[1] = v31
        previous_position[2] = v32
        previous_position[3] = v33
        previous_position[4] = v34
    end

    local state = p9.state

    frame.field_of_view_degrees = state.field_of_view
    frame.opacity = state.opacity
    frame.blur = state.blur
end

return t1
