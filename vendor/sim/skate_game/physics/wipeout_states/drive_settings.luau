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
local Collections = import("skate_data/collections").Collections
local PhysicsSkeleton = import("skate_data/physics_skeleton").PhysicsSkeleton
local t1 = {}

local function path_join(p2, p3) -- line: 22
    if p2 == nil then
        return p3
    end

    return tostring(p2) .. "/" .. p3
end

function t1.load(p4, p5, p6) -- line: 31
    -- upvalues: rt (copy), v1 (copy), Collections (copy), PhysicsSkeleton (copy)
    local PHYS_TPOSE = PhysicsSkeleton.load(if p5 == nil then "private/stock/physics-skeletons.json" else tostring(p5) .. "/" .. "private/stock/physics-skeletons.json", p6, "PHYS_TPOSE")

    if #PHYS_TPOSE.bones ~= 24 then
        error("Wipeout requires the actual24 physical skeleton parts", 0)
    end

    local v2 = rt.filled(24, table.create(5, 0))

    for i = 1, 23 do
        local v3 = string.format("PART_%s", PHYS_TPOSE.bones[i + 1].name)
        local v4 = Collections.words(p4, "physics_skeleton_drives", "default", v3, 9)
        local v5 = i + 1

        buffer.writeu32(v1, 0, v4[1])

        local v7 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v4[2])

        local v9 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v4[3])

        local v11 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v4[4])

        local v13 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v4[5])
        v2[v5] = {
            v7,
            v9,
            v11,
            v13,
            (buffer.readf32(v1, 0))
        }
    end

    local t2 = {
        "root_drive_start_scalar",
        "root_drive_scalar",
        "root_drive_controlled_scalar",
        "root_drive_end_scalar"
    }
    local v15 = table.create(4, 0)

    for i = 0, #t2 - 1 do
        v15[i + 1] = Collections.float(p4, "physics_skeleton_drives", "default", t2[i + 1])
    end

    local DriveStrengthLocal = Collections.float(p4, "animation", "default", "DriveStrengthLocal")
    local DriveStrengthRootLocal = Collections.float(p4, "animation", "default", "DriveStrengthRootLocal")
    local HookSoftDsp = Collections.float(p4, "physics_animation", "default", "HookSoftDsp")
    local HookSoftStr = Collections.float(p4, "physics_animation", "default", "HookSoftStr")
    local HookSoftDmp = Collections.float(p4, "physics_animation", "default", "HookSoftDmp")

    return {
        bone = v2,
        root = v15,
        strength = { DriveStrengthLocal, DriveStrengthRootLocal },
        hook_spring = HookSoftDsp,
        hook_strength = HookSoftStr,
        hook_damping = HookSoftDmp
    }
end

return t1
