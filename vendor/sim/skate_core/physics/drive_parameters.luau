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

local v2 = require(sim.import)("skate_core/physics/native_arithmetic")
local t1 = {}

local function struct_eq(p2, p3) -- line: 19
    -- upvalues: struct_eq (copy)
    if type(p2) ~= "table" or type(p3) ~= "table" then
        return p2 == p3
    end

    for v3, v4 in p2 do
        if not struct_eq(v4, p3[v3]) then
            return false
        end
    end

    for v5 in p3 do
        if p2[v5] == nil then
            return false
        end
    end

    return true
end

function t1.retail_f32(p4) -- line: 36
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p4)

    return (buffer.readf32(v1, 0))
end

t1.RetailDriveType = {
    NoDrive = 0,
    SoftDrive = 1,
    HardDrive = 2
}
t1.RetailDriveParams = {}
t1.RetailDriveParams.eq = struct_eq
t1.RetailDriveDynamics = {}
t1.RetailDriveDynamics.eq = struct_eq
t1.RetailTruckDriveSettings = {}
t1.RetailTruckDriveSettings.eq = struct_eq
t1.RetailTruckDriveSettings.STOCK = {
    use_linear_drives = false,
    use_hard_linear_drives = true,
    angular_displacement = 10,
    angular_damping = 0,
    angular_strength = 11
}
t1.RetailDriveParams.DISABLED = {
    spring_or_max_velocity = 0,
    damping = 0,
    max_strength = 0,
    drive_type = t1.RetailDriveType.NoDrive
}

function t1.retail_truck_drive_dynamics(p5) -- line: 83
    -- upvalues: rt (copy), t1 (copy)
    return {
        linear = if not p5.use_linear_drives then rt.copy(t1.RetailDriveParams.DISABLED)
            elseif p5.use_hard_linear_drives then {
                damping = 0,
                spring_or_max_velocity = t1.retail_f32(1169915903),
                max_strength = t1.retail_f32(1219479551),
                drive_type = t1.RetailDriveType.HardDrive
            }
            else {
                spring_or_max_velocity = t1.retail_f32(1203982336),
                damping = t1.soft_linear_damping(),
                max_strength = t1.retail_f32(1219479551),
                drive_type = t1.RetailDriveType.SoftDrive
            },
        angular = {
            spring_or_max_velocity = p5.angular_displacement * t1.retail_f32(1114636287),
            damping = p5.angular_damping,
            max_strength = p5.angular_strength * t1.retail_f32(1163984894),
            drive_type = t1.RetailDriveType.HardDrive
        }
    }
end

function t1.retail_wheel_drive_dynamics(p6) -- line: 114
    -- upvalues: t1 (copy)
    if p6 then
        return {
            linear = {
                damping = 0,
                spring_or_max_velocity = t1.retail_f32(1169915903),
                max_strength = t1.retail_f32(1219479551),
                drive_type = t1.RetailDriveType.HardDrive
            },
            angular = {
                spring_or_max_velocity = 0,
                damping = 0,
                max_strength = 0,
                drive_type = t1.RetailDriveType.NoDrive
            }
        }
    end

    return {
        linear = {
            spring_or_max_velocity = t1.retail_f32(1163984896),
            damping = t1.retail_f32(1114636288),
            max_strength = t1.retail_f32(1192009727),
            drive_type = t1.RetailDriveType.SoftDrive
        },
        angular = {
            spring_or_max_velocity = 0,
            damping = 0,
            max_strength = 0,
            drive_type = t1.RetailDriveType.NoDrive
        }
    }
end

t1.RetailDriveFrameRaw = {}
t1.RetailDriveFrameRaw.eq = struct_eq
t1.RetailDriveFramesRaw = {}
t1.RetailDriveFramesRaw.eq = struct_eq

function t1.soft_linear_damping() -- line: 163
    -- upvalues: v2 (copy), t1 (copy)
    local v6 = t1.retail_f32(1203982336)
    local v7 = v2.reciprocal_square_root_estimate(v6)
    local v8 = v7 * v7
    local v9 = v7 * 0.5 * (-v6 * v8 + 1) + v7
    local v10 = v9 * v9
    local v11 = v9 * 0.5 * (-v6 * v10 + 1) + v9

    return (if v6 == 0 then 0 else v6 * v11) * t1.retail_f32(1073741824)
end

return t1
