-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local inverse_affine = import("skate_core/animation/foot_ik").inverse_affine
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local RetailDriveType = import("skate_core/physics/drive_parameters").RetailDriveType
local IDENTITY = import("skate_core/physics/skeleton_animation_record").IDENTITY
local v1 = import("skate_core/physics/skeleton_body")
local bone_drive_frames, BoneDriveDynamics = v1.bone_drive_frames, v1.BoneDriveDynamics
local bone_drive_frames_into = import("skate_core/physics/skeleton_body/drive_frames").bone_drive_frames_into
local t1 = {
    FREQUENCY_SQUARED = 3599.99951171875
}
local FREQUENCY_SQUARED = t1.FREQUENCY_SQUARED

t1.Settings = {}
t1.Weights = {}

local to_bits, from_bits = rt.to_bits, rt.from_bits
local v2 = table.create(24)

local function inverse_affine_scratch(p1, p2, p3) -- line: 65
    -- upvalues: to_bits (copy), from_bits (copy)
    local v3 = p3[1]
    local v4 = p3[2]
    local v5 = p3[3]
    local v6 = p3[4]
    local v7 = v3[1]
    local v8 = v3[2]
    local v9 = v3[3]
    local v10 = v4[1]
    local v11 = v4[2]
    local v12 = v4[3]
    local v13 = v5[1]
    local v14 = v5[2]
    local v15 = v5[3]
    local v16 = -v12 * v14 + v11 * v15
    local v17 = -v10 * v15 + v12 * v13
    local v18 = -v11 * v13 + v10 * v14
    local v19 = -v15 * v8 + v14 * v9
    local v20 = -v13 * v9 + v15 * v7
    local v21 = -v14 * v7 + v13 * v8
    local v22 = -v9 * v11 + v8 * v12
    local v23 = -v7 * v12 + v9 * v10
    local v24 = -v8 * v10 + v7 * v11
    local v25 = v7 * v16 + v8 * v17 + v9 * v18
    local v26 = 1 / v25
    local v27 = v26 * (-v26 * v25 + 1) + v26
    local v28 = v27 * (-v27 * v25 + 1) + v27
    local v29 = v16 * v28
    local v30 = v19 * v28
    local v31 = v22 * v28
    local v32 = v19 * v28
    local v33 = v17 * v28
    local v34 = v20 * v28
    local v35 = v23 * v28
    local v36 = v20 * v28
    local v37 = v18 * v28
    local v38 = v21 * v28
    local v39 = v24 * v28
    local v40 = v21 * v28
    local v42 = from_bits((bit32.bxor(to_bits(v6[1]), 2147483648)))
    local v44 = from_bits((bit32.bxor(to_bits(v6[2]), 2147483648)))
    local v46 = from_bits((bit32.bxor(to_bits(v6[3]), 2147483648)))
    local v47 = p1[p2]

    if v47 == nil then
        v47 = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        }
        p1[p2] = v47
    end

    local v48 = v47[1]

    v48[1] = v29
    v48[2] = v30
    v48[3] = v31
    v48[4] = v32

    local v49 = v47[2]

    v49[1] = v33
    v49[2] = v34
    v49[3] = v35
    v49[4] = v36

    local v50 = v47[3]

    v50[1] = v37
    v50[2] = v38
    v50[3] = v39
    v50[4] = v40

    local v51 = v47[4]
    local v52 = v46 * v37 + (v44 * v33 + v42 * v29)
    local v53 = v46 * v38 + (v44 * v34 + v42 * v30)
    local v54 = v46 * v39 + (v44 * v35 + v42 * v31)
    local v55 = v46 * v40 + (v44 * v36 + v42 * v32)

    v51[1] = v52
    v51[2] = v53
    v51[3] = v54
    v51[4] = v55
end

function t1.update(p4, p5, p6, p7) -- line: 146
    -- upvalues: IDENTITY (copy), bone_drive_frames (copy), BoneDriveDynamics (copy), bone_drive_frames_into (copy), v2 (copy), inverse_affine_scratch (copy)
    v2[1] = IDENTITY

    for i = 1, 23 do
        inverse_affine_scratch(v2, i + 1, p5[i + 1])
    end

    local start, v56, controlled, upper_extra = p7.start, p7["end"], p7.controlled, p7.upper_extra
    local lower_extra = p7.lower_extra
    local v57 = 1 - start - v56 - controlled
    local strength, root = p6.strength, p6.root

    for i = 1, 22 do
        local v58 = p4.bones[i + 1]

        if v58 == nil then
            error("Original22 bone drives exist", 0)
        end

        local v59 = p6.bone[i + 1]
        local v60 = i >= 3 and i <= 10
        local v61 = i >= 15 and i <= 22
        local dynamics = v58.dynamics
        local v62, v63

        if not (v60 and upper_extra > 0) and (not v61 or not (lower_extra > 0)) then
            dynamics.mode = 4

            local v64 = v59[1]
            local v65 = v59[2]
            local v66 = v59[3]
            local v67 = v59[4]
            local v68 = v66 * controlled + (v64 * start + (v65 * v57 + v67 * v56))
            local v69 = root[1] * v64
            local v70 = root[2] * v65
            local v71 = root[3] * v66
            local v72 = root[4] * v67
            local v73 = v71 * controlled + (v69 * start + (v72 * v56 + v70 * v57))

            v62 = v68 * strength[1]
            v63 = v73 * strength[2]
        else
            dynamics.mode = 5

            local v74 = (if v60 then upper_extra else lower_extra) * v59[5]

            v62 = v74 * strength[1]
            v63 = v74 * strength[2]
        end

        local strengths = dynamics.strengths

        if type(strengths) == "table" and strengths ~= strength and #strengths == 2 then
            strengths[1] = v62
            strengths[2] = v63
        else
            dynamics.strengths = { v62, v63 }
        end

        local active, frames = v58.active, v58.frames

        if active[1] then
            local v75 = frames[1]

            if v75 == nil or v75 == frames[2] then
                frames[1] = bone_drive_frames(p5[i + 1], v2[i + 1], v2[v58.parent[1] + 1])
            else
                bone_drive_frames_into(v75, p5[i + 1], v2[i + 1], v2[v58.parent[1] + 1])
            end

            BoneDriveDynamics.enable(dynamics, 0, v62, p4.settings.bone)
        end

        if active[2] then
            local v76 = frames[2]

            if v76 == nil or v76 == frames[1] then
                frames[2] = bone_drive_frames(p5[i + 1], v2[i + 1], v2[v58.parent[2] + 1])
            else
                bone_drive_frames_into(v76, p5[i + 1], v2[i + 1], v2[v58.parent[2] + 1])
            end

            BoneDriveDynamics.enable(dynamics, 1, v63, p4.settings.bone)
        end
    end

    return v57
end

function t1.update_reference(p8, p9, p10, p11) -- line: 219
    -- upvalues: rt (copy), inverse_affine (copy), IDENTITY (copy), bone_drive_frames (copy), BoneDriveDynamics (copy)
    local v77 = rt.filled(24, IDENTITY)

    for i = 1, 23 do
        v77[i + 1] = inverse_affine(p9[i + 1])
    end

    local v78 = 1 - p11.start - p11["end"] - p11.controlled

    for i = 1, 22 do
        local v79 = p8.bones[i + 1]

        if v79 == nil then
            error("Original22 bone drives exist", 0)
        end

        local v80 = p10.bone[i + 1]
        local v81 = i >= 3 and i <= 10
        local v82 = i >= 15 and i <= 22
        local t2

        if not (v81 and p11.upper_extra > 0) and (not v82 or not (p11.lower_extra > 0)) then
            v79.dynamics.mode = 4

            local v83 = v80[1]
            local v84 = v80[2]
            local v85 = v80[3]
            local v86 = v80[4]
            local v87 = v85 * p11.controlled + (v83 * p11.start + (v84 * v78 + v86 * p11["end"]))
            local v88 = p10.root[1] * v83
            local v89 = p10.root[2] * v84
            local v90 = p10.root[3] * v85
            local v91 = p10.root[4] * v86
            local v92 = v90 * p11.controlled + (v88 * p11.start + (v91 * p11["end"] + v89 * v78))

            t2 = {
                v87 * p10.strength[1],
                v92 * p10.strength[2]
            }
        else
            v79.dynamics.mode = 5

            local v93 = (if v81 then p11.upper_extra else p11.lower_extra) * v80[5]

            t2 = {
                v93 * p10.strength[1],
                v93 * p10.strength[2]
            }
        end

        v79.dynamics.strengths = rt.copy(t2)

        for j = 0, 1 do
            if v79.active[j + 1] then
                v79.frames[j + 1] = bone_drive_frames(p9[i + 1], v77[i + 1], v77[v79.parent[j + 1] + 1])
                BoneDriveDynamics.enable(v79.dynamics, j, t2[j + 1], p8.settings.bone)
            end
        end
    end

    return v78
end

function t1.set_linear_root(p12, p13, p14) -- line: 267
    -- upvalues: inverse_length_squared (copy), RetailDriveType (copy), t1 (copy), FREQUENCY_SQUARED (copy)
    local v94 = t1.clamp(p14)
    local hook_spring = p13.hook_spring
    local v95 = if hook_spring == 0 then 0 else hook_spring * inverse_length_squared(hook_spring, 2)

    p12.targets.dynamics[1].linear = {
        spring_or_max_velocity = hook_spring * v94,
        damping = v95 * 2 - hook_spring * 0.01600000075995922,
        max_strength = p13.hook_strength * v94 * FREQUENCY_SQUARED,
        drive_type = RetailDriveType.SoftDrive
    }
end

function t1.set_angular_root(p15, p16, p17) -- line: 286
    -- upvalues: RetailDriveType (copy), t1 (copy), FREQUENCY_SQUARED (copy)
    local v96 = t1.clamp(p17)

    p15.targets.dynamics[1].angular = {
        spring_or_max_velocity = p16.hook_spring * v96,
        damping = p16.hook_damping,
        max_strength = p16.hook_strength * v96 * FREQUENCY_SQUARED,
        drive_type = RetailDriveType.SoftDrive
    }
end

function t1.clamp(p18) -- line: 296
    local v97 = if -p18 >= 0 then 0 else p18

    if 1 - v97 >= 0 then
        return v97
    end

    return 1
end

return t1
