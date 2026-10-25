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
local affine = import("skate_game/physics/offboard/board_possession").affine
local retail_quaternion_from_basis = import("skate_core/physics/drive_frames").retail_quaternion_from_basis
local RetailDriveType = import("skate_core/physics/drive_parameters").RetailDriveType
local build_drive_rows = import("skate_core/physics/drive_solver").build_drive_rows
local pack_world_inverse_inertia = import("skate_core/physics/rigid_body").pack_world_inverse_inertia
local prepare_bone_drive_frames = import("skate_core/physics/skeleton_body").prepare_bone_drive_frames
local t1 = {}
local build_drive_rows_into = import("skate_core/physics/drive_solver/builder").build_drive_rows_into
local drive_body_into = import("skate_core/physics/skeleton_body/drives").drive_body_into
local prepare_bone_drive_frames_in_place = import("skate_core/physics/skeleton_body/drive_frames").prepare_bone_drive_frames_in_place

local function solver_packing() -- line: 37
    -- upvalues: import (copy)
    return import("skate_core/physics/solver/packing")
end

local function drive_frame(p2) -- line: 42
    -- upvalues: affine (copy), retail_quaternion_from_basis (copy)
    local v2 = affine(p2)

    return {
        orientation = retail_quaternion_from_basis(v2.basis),
        translation = v2.translation
    }
end

local function drive_params(p3) -- line: 50
    -- upvalues: v1 (copy), RetailDriveType (copy)
    local t2 = {}

    buffer.writeu32(v1, 0, p3[1])
    t2.spring_or_max_velocity = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p3[2])
    t2.damping = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p3[3])
    t2.max_strength = buffer.readf32(v1, 0)
    t2.drive_type = RetailDriveType.HardDrive

    return t2
end

local v6
local t3 = {
    false,
    false
}

local function abandon_pool() -- line: 65
    -- upvalues: import (copy), t3 (copy)
    local v7 = t3[1]

    if v7 then
        import("skate_core/physics/solver/packing").unregister_drive_rows(v7.row)
        t3[1] = false
    end

    local v8 = t3[2]

    if v8 then
        import("skate_core/physics/solver/packing").unregister_drive_rows(v8.row)
        t3[2] = false
    end
end

function t1.append(p4, p5, p6, p7, p8, p9, p10) -- line: 99
    -- upvalues: v1 (copy), import (copy), affine (copy), retail_quaternion_from_basis (copy), RetailDriveType (copy), build_drive_rows (copy), t1 (copy), build_drive_rows_into (copy), drive_body_into (copy), prepare_bone_drive_frames_in_place (copy), v6 (ref), t3 (copy)
    if v6 ~= p4 then
        local v9 = t3[1]

        if v9 then
            import("skate_core/physics/solver/packing").unregister_drive_rows(v9.row)
            t3[1] = false
        end

        local v10 = t3[2]

        if v10 then
            import("skate_core/physics/solver/packing").unregister_drive_rows(v10.row)
            t3[2] = false
        end

        v6 = p4
    end

    for i = 0, 1 do
        if bit32.band(bit32.bor(p5.state_flags, p6[i + 1].state_flags), 4) ~= 0 then
            local v12 = p4.hands[i + 1]
            local v13 = t3[i + 1]
            local v14 = if v13 then drive_body_into(v13.state_a, p6[i + 1], p8[i + 1]) else t1.body(p6[i + 1], p8[i + 1])
            local v15 = if v13 then drive_body_into(v13.state_b, p5, p7) else t1.body(p5, p7)
            local v16 = affine(v12.child)
            local t4 = {
                orientation = retail_quaternion_from_basis(v16.basis),
                translation = v16.translation
            }
            local v17 = affine(v12.parent)
            local v18 = prepare_bone_drive_frames_in_place({
                body_a = t4,
                body_b = {
                    orientation = retail_quaternion_from_basis(v17.basis),
                    translation = v17.translation
                }
            })
            local v19 = v12.dynamics[1]
            local t6 = {}

            buffer.writeu32(v1, 0, v19[1])
            t6.spring_or_max_velocity = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v19[2])
            t6.damping = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v19[3])
            t6.max_strength = buffer.readf32(v1, 0)
            t6.drive_type = RetailDriveType.HardDrive

            local v23 = v12.dynamics[2]
            local t7 = {}

            buffer.writeu32(v1, 0, v23[1])
            t7.spring_or_max_velocity = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v23[2])
            t7.damping = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v23[3])
            t7.max_strength = buffer.readf32(v1, 0)
            t7.drive_type = RetailDriveType.HardDrive

            local t8 = {
                linear = t6,
                angular = t7
            }
            local v27

            if v13 then
                v27 = build_drive_rows_into(v13.row, v14, v15, v18, t8, p9)
            else
                v27 = build_drive_rows(v14, v15, v18, t8, p9)
                t3[i + 1] = {
                    state_a = v14,
                    state_b = v15,
                    row = v27
                }
                import("skate_core/physics/solver/packing").register_drive_rows(v27)
            end

            table.insert(p10, v27)
        end
    end
end

function t1.append_reference(p11, p12, p13, p14, p15, p16, p17) -- line: 148
    -- upvalues: rt (copy), v1 (copy), affine (copy), retail_quaternion_from_basis (copy), RetailDriveType (copy), build_drive_rows (copy), prepare_bone_drive_frames (copy), t1 (copy)
    for i = 0, 1 do
        if bit32.band(bit32.bor(p12.state_flags, p13[i + 1].state_flags), 4) ~= 0 then
            local v29 = rt.copy(p11.hands[i + 1])

            local function frame(p18) -- line: 154
                -- upvalues: affine (copy), retail_quaternion_from_basis (copy)
                local v30 = affine(p18)

                return {
                    orientation = retail_quaternion_from_basis(v30.basis),
                    translation = v30.translation
                }
            end

            local function params(p19) -- line: 162
                -- upvalues: v1 (copy), RetailDriveType (copy)
                local t9 = {}

                buffer.writeu32(v1, 0, p19[1])
                t9.spring_or_max_velocity = buffer.readf32(v1, 0)
                buffer.writeu32(v1, 0, p19[2])
                t9.damping = buffer.readf32(v1, 0)
                buffer.writeu32(v1, 0, p19[3])
                t9.max_strength = buffer.readf32(v1, 0)
                t9.drive_type = RetailDriveType.HardDrive

                return t9
            end

            local v34 = t1.body(p13[i + 1], p15[i + 1])
            local v35 = t1.body(p12, p14)
            local v36 = affine(v29.child)
            local t10 = {
                orientation = retail_quaternion_from_basis(v36.basis),
                translation = v36.translation
            }
            local v37 = affine(v29.parent)
            local v38 = prepare_bone_drive_frames({
                body_a = t10,
                body_b = {
                    orientation = retail_quaternion_from_basis(v37.basis),
                    translation = v37.translation
                }
            })
            local v39 = v29.dynamics[1]
            local t12 = {}

            buffer.writeu32(v1, 0, v39[1])
            t12.spring_or_max_velocity = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v39[2])
            t12.damping = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v39[3])
            t12.max_strength = buffer.readf32(v1, 0)
            t12.drive_type = RetailDriveType.HardDrive

            local v43 = v29.dynamics[2]
            local t13 = {}

            buffer.writeu32(v1, 0, v43[1])
            t13.spring_or_max_velocity = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v43[2])
            t13.damping = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v43[3])
            t13.max_strength = buffer.readf32(v1, 0)
            t13.drive_type = RetailDriveType.HardDrive
            table.insert(p17, build_drive_rows(v34, v35, v38, {
                linear = t12,
                angular = t13
            }, p16))
        end
    end
end

function t1.body(p20, p21) -- line: 193
    -- upvalues: rt (copy), pack_world_inverse_inertia (copy)
    local rates = p20.rates

    return {
        reaction_index = p21,
        state = p20.state_flags,
        orientation = rt.copy(rates.orientation),
        basis = rt.copy(rates.basis),
        center_of_mass = rt.copy(rates.position),
        linear_velocity = rt.copy(rates.linear_velocity),
        angular_velocity = rt.copy(rates.angular_velocity),
        force_acceleration = rt.copy(rates.force_acceleration),
        torque_acceleration = rt.copy(rates.torque_acceleration),
        inverse_mass = p20.inertia.inverse_mass,
        world_inverse_inertia = pack_world_inverse_inertia(rates.world_inverse_inertia)
    }
end

return t1
