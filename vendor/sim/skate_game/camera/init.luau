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
local v1 = import("skate_game/camera/publication")
local v2 = import("skate_game/camera/graph_subject")
local v3 = import("skate_game/camera/runtime")
local v4 = import("skate_game/presentation")
local v5 = import("skate_game/debug_cam")

local function customiser_mod() -- line: 25
    -- upvalues: import (copy)
    return import("skate_game/customiser")
end

local t1 = {
    publish_camera_subject = v1.snapshot,
    CameraPublicationInputs = v1.CameraPublicationInputs,
    CameraStateOutput = v1.CameraStateOutput,
    CameraAnimationOutput = v1.CameraAnimationOutput,
    CameraAirOutput = v1.CameraAirOutput,
    CameraOffboardOutput = v1.CameraOffboardOutput,
    CameraGrindOutput = v1.CameraGrindOutput,
    CameraEventsOutput = v1.CameraEventsOutput,
    CameraPreferences = v1.CameraPreferences,
    CameraGraphEnvironment = v2.CameraGraphEnvironment,
    CameraRuntime = v3.CameraRuntime
}
local CameraRuntime = v3.CameraRuntime

local function glam_quat_from_rotation_y(p2) -- line: 51
    return {
        0,
        math.sin(p2 * 0.5),
        0,
        (math.cos(p2 * 0.5))
    }
end

local function glam_quat_mul(p3, p4) -- line: 56
    local v9 = p3[1]
    local v10 = p3[2]
    local v11 = p3[3]
    local v12 = p3[4]
    local v13 = p4[1]
    local v14 = p4[2]
    local v15 = p4[3]
    local v16 = p4[4]

    return {
        v12 * v13 + v9 * v16 + v10 * v15 - v11 * v14,
        v12 * v14 - v9 * v15 + v10 * v16 + v11 * v13,
        v12 * v15 + v9 * v14 - v10 * v13 + v11 * v16,
        v12 * v16 - v9 * v13 - v10 * v14 - v11 * v15
    }
end

local function glam_dot(p5, p6) -- line: 67
    return p5[1] * p6[1] + p5[2] * p6[2] + p5[3] * p6[3]
end

local function glam_cross(p7, p8) -- line: 71
    return {
        p7[2] * p8[3] - p8[2] * p7[3],
        p7[3] * p8[1] - p8[3] * p7[1],
        p7[1] * p8[2] - p8[1] * p7[2]
    }
end

local function glam_scale(p9, p10) -- line: 79
    return {
        p9[1] * p10,
        p9[2] * p10,
        p9[3] * p10
    }
end

local function glam_add(p11, p12) -- line: 83
    return {
        p11[1] + p12[1],
        p11[2] + p12[2],
        p11[3] + p12[3]
    }
end

local function glam_sub(p13, p14) -- line: 87
    return {
        p13[1] - p14[1],
        p13[2] - p14[2],
        p13[3] - p14[3]
    }
end

local function glam_normalize(p15) -- line: 92
    local v18 = 1 / math.sqrt(p15[1] * p15[1] + p15[2] * p15[2] + p15[3] * p15[3])

    return {
        p15[1] * v18,
        p15[2] * v18,
        p15[3] * v18
    }
end

local function glam_try_normalize(p16) -- line: 97
    local v20 = 1 / math.sqrt(p16[1] * p16[1] + p16[2] * p16[2] + p16[3] * p16[3])

    return if v20 == v20 and v20 ~= 1e999 and v20 ~= (-1e999) and v20 > 0 then {
        p16[1] * v20,
        p16[2] * v20,
        p16[3] * v20
    } else nil
end

local function glam_any_orthonormal_vector(p17) -- line: 106
    -- upvalues: rt (copy)
    local v21 = rt.signum(p17[3])
    local v22 = -1 / (v21 + p17[3])

    return {
        p17[1] * p17[2] * v22,
        v21 + p17[2] * p17[2] * v22,
        -p17[2]
    }
end

local function glam_quat_mul_vec3(p18, p19) -- line: 114
    -- upvalues: glam_cross (copy)
    local v23 = p18[4]
    local t2 = {
        p18[1],
        p18[2],
        p18[3]
    }
    local v24 = t2[1] * t2[1] + t2[2] * t2[2] + t2[3] * t2[3]
    local v25 = v23 * v23 - v24
    local t3 = {
        p19[1] * v25,
        p19[2] * v25,
        p19[3] * v25
    }
    local v26 = (p19[1] * t2[1] + p19[2] * t2[2] + p19[3] * t2[3]) * 2
    local t4 = {
        t2[1] * v26,
        t2[2] * v26,
        t2[3] * v26
    }
    local t5 = {
        t3[1] + t4[1],
        t3[2] + t4[2],
        t3[3] + t4[3]
    }
    local v27 = glam_cross(t2, p19)
    local v28 = v23 * 2
    local t6 = {
        v27[1] * v28,
        v27[2] * v28,
        v27[3] * v28
    }

    return {
        t5[1] + t6[1],
        t5[2] + t6[2],
        t5[3] + t6[3]
    }
end

local function glam_quat_from_rotation_axes(p20, p21, p22) -- line: 125
    local v29 = p20[1]
    local v30 = p20[2]
    local v31 = p20[3]
    local v32 = p21[1]
    local v33 = p21[2]
    local v34 = p21[3]
    local v35 = p22[1]
    local v36 = p22[2]
    local v37 = p22[3]

    if v37 <= 0 then
        local v38 = v33 - v29
        local v39 = 1 - v37

        if v38 <= 0 then
            local v40 = v39 - v38
            local v41 = 0.5 / math.sqrt(v40)

            return {
                v40 * v41,
                (v30 + v32) * v41,
                (v31 + v35) * v41,
                (v34 - v36) * v41
            }
        end

        local v42 = v39 + v38
        local v43 = 0.5 / math.sqrt(v42)

        return {
            (v30 + v32) * v43,
            v42 * v43,
            (v34 + v36) * v43,
            (v35 - v31) * v43
        }
    end

    local v44 = v33 + v29
    local v45 = 1 + v37

    if v44 <= 0 then
        local v46 = v45 - v44
        local v47 = 0.5 / math.sqrt(v46)

        return {
            (v31 + v35) * v47,
            (v34 + v36) * v47,
            v46 * v47,
            (v30 - v32) * v47
        }
    end

    local v48 = v45 + v44
    local v49 = 0.5 / math.sqrt(v48)

    return {
        (v34 - v36) * v49,
        (v35 - v31) * v49,
        (v30 - v32) * v49,
        v48 * v49
    }
end

local function bevy_dir3(p23) -- line: 163
    local v51 = math.sqrt(p23[1] * p23[1] + p23[2] * p23[2] + p23[3] * p23[3])

    if v51 == v51 and v51 ~= 1e999 and v51 ~= (-1e999) and v51 > 0 then
        local v52 = 1 / v51

        return {
            p23[1] * v52,
            p23[2] * v52,
            p23[3] * v52
        }
    end

    return nil
end

local function bevy_transform_looking_at(p24, p25, p26) -- line: 172
    -- upvalues: glam_cross (copy), glam_any_orthonormal_vector (copy), glam_quat_from_rotation_axes (copy)
    local t7 = {
        p25[1] - p24[1],
        p25[2] - p24[2],
        p25[3] - p24[3]
    }
    local v54 = math.sqrt(t7[1] * t7[1] + t7[2] * t7[2] + t7[3] * t7[3])
    local v55 = v54 == v54 and v54 ~= 1e999 and v54 ~= (-1e999)
    local t8

    if v55 and v54 > 0 then
        local v56 = 1 / v54

        t8 = {
            t7[1] * v56,
            t7[2] * v56,
            t7[3] * v56
        }
    end

    local t9 = if t8 == nil then { 0, 0, 1 } else {
        t8[1] * -1,
        t8[2] * -1,
        t8[3] * -1
    }
    local v58 = math.sqrt(p26[1] * p26[1] + p26[2] * p26[2] + p26[3] * p26[3])
    local v59 = v58 == v58 and v58 ~= 1e999 and v58 ~= (-1e999)
    local t10

    if v59 and v58 > 0 then
        local v60 = 1 / v58

        t10 = {
            p26[1] * v60,
            p26[2] * v60,
            p26[3] * v60
        }
    end

    local v61 = t10 or { 0, 1, 0 }
    local v62 = glam_cross(v61, t9)
    local v64 = 1 / math.sqrt(v62[1] * v62[1] + v62[2] * v62[2] + v62[3] * v62[3])
    local v65 = if not (v64 == v64 and v64 ~= 1e999 and v64 ~= (-1e999) and v64 > 0) then nil else {
        v62[1] * v64,
        v62[2] * v64,
        v62[3] * v64
    }

    if v65 == nil then
        v65 = glam_any_orthonormal_vector(v61)
    end

    local v66 = glam_cross(t9, v65)

    return {
        translation = {
            p24[1],
            p24[2],
            p24[3]
        },
        rotation = glam_quat_from_rotation_axes(v65, v66, t9),
        scale = { 1, 1, 1 }
    }
end

t1.GameplayCamera = {}
t1.CameraPlugin = {}

function t1.spawn(p27, p28) -- line: 200
    -- upvalues: CameraRuntime (copy)
    local load = CameraRuntime.load
    local asset_root = p27.asset_root
    local ok, result = pcall(load, asset_root, p28)

    if not ok then
        error(("Cannot initialize normal gameplay camera: %*"):format((tostring(result))), 0)
    end

    return result
end

function t1.present(p29, p30, p31, p32, p33, p34) -- line: 223
    -- upvalues: rt (copy), import (copy), v4 (copy), v5 (copy), CameraRuntime (copy), glam_quat_mul (copy), glam_cross (copy), glam_quat_mul_vec3 (copy), bevy_transform_looking_at (copy)
    if p30 ~= nil then
        local v67 = p30.width / p30.height

        if v67 == v67 and v67 ~= 1e999 and v67 ~= (-1e999) and v67 > 0 then
            CameraRuntime.set_aspect_ratio(p29, v67)
        end
    end

    local v68, v69, v70 = v4.Presentation.view(p31, p33, p32)

    if v68 == nil then
        return
    end

    local v71 = v5.DebugCam.pose(p29)
    local v72 = v4.blend(v68.camera, v69.camera, v70)

    if p33.active then
        local free_camera = p33.free_camera

        if free_camera ~= nil then
            v72 = rt.copy(free_camera)
        end
    elseif v71 ~= nil then
        v72 = v71
    end

    local v73 = v68.fov + (v69.fov - v68.fov) * v70

    if p34 ~= nil and p34.open then
        local v74, v75, v76 = import("skate_game/customiser").Customiser.preview_camera(p34)
        local translation = v69.root.translation
        local t11 = {
            0,
            v74,
            0
        }
        local t12 = {
            translation[1] + t11[1],
            translation[2] + t11[2],
            translation[3] + t11[3]
        }
        local v80 = glam_quat_mul_vec3(glam_quat_mul(v69.root.rotation, {
            0,
            math.sin(v76 * 0.5),
            0,
            (math.cos(v76 * 0.5))
        }), { 0, 0.25, v75 })
        local t13 = {
            t12[1] + v80[1],
            t12[2] + v80[2],
            t12[3] + v80[3]
        }
        local v82 = 1 / math.sqrt(v80[1] * v80[1] + v80[2] * v80[2] + v80[3] * v80[3])
        local v83 = glam_cross({
            v80[1] * v82,
            v80[2] * v82,
            v80[3] * v82
        }, { 0, 1, 0 })
        local v85 = 1 / math.sqrt(v83[1] * v83[1] + v83[2] * v83[2] + v83[3] * v83[3])
        local t14 = {
            v83[1] * v85,
            v83[2] * v85,
            v83[3] * v85
        }
        local v86 = v75 * 0.265625
        local t15 = {
            t14[1] * v86,
            t14[2] * v86,
            t14[3] * v86
        }

        v73 = 0.8726646259971648
        v72 = bevy_transform_looking_at(t13, {
            t12[1] + t15[1],
            t12[2] + t15[2],
            t12[3] + t15[3]
        }, { 0, 1, 0 })
    end

    return v72, v73
end

return t1
