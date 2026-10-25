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

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

require(sim.import)

local t1 = {
    PhysicsBone = {}
}

function t1.PhysicsBone.size(p3) -- line: 27
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3.words[9])

    local v3 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p3.words[10])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p3.words[11])

    return {
        v3,
        v5,
        (buffer.readf32(v1, 0))
    }
end

function t1.PhysicsBone.rotation(p4) -- line: 32
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p4.words[13])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4.words[14])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4.words[15])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4.words[16])

    return {
        v8,
        v10,
        v12,
        (buffer.readf32(v1, 0))
    }
end

function t1.PhysicsBone.translation(p5) -- line: 42
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p5.words[17])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5.words[18])

    local v17 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5.words[19])

    return {
        v15,
        v17,
        (buffer.readf32(v1, 0))
    }
end

t1.PhysicsSkeleton = {}
t1.File = {}

local function eq_ignore_ascii_case(p6, p7) -- line: 53
    if #p6 ~= #p7 then
        return false
    end

    local function v19(p8) -- line: 57
        return (string.char(string.byte(p8) + 32))
    end

    return string.gsub(p6, "[A-Z]", v19) == string.gsub(p7, "[A-Z]", v19)
end

local function file_from_value(p9) -- line: 65
    -- upvalues: rt (copy)
    local function strict(p10, p11) -- line: 66
        for v21 in p10 do
            if not p11[v21] then
                error(("unknown field `%*`"):format(v21), 0)
            end
        end
    end

    strict(p9, {
        version = true,
        source_sha256 = true,
        skeletons = true
    })

    local version = p9.version

    if type(version) ~= "number" or type(p9.source_sha256) ~= "string" or type(p9.skeletons) ~= "table" then
        error("invalid physics skeleton file", 0)
    end

    local v23 = table.create(#p9.skeletons)

    for v24, v25 in p9.skeletons do
        strict(v25, {
            name = true,
            source_offset = true,
            bones = true
        })

        if type(v25.name) == "string" then
            if type(v25.source_offset) ~= "number" or type(v25.bones) ~= "table" then
                error("invalid physics skeleton", 0)
            end
        else
            error("invalid physics skeleton", 0)
        end

        local v26 = table.create(#v25.bones)

        for v27, v28 in v25.bones do
            strict(v28, {
                name = true,
                source_offset = true,
                words = true
            })

            if type(v28.name) == "string" then
                if type(v28.source_offset) ~= "number" or type(v28.words) ~= "table" then
                    error("invalid physics bone", 0)
                end
            else
                error("invalid physics bone", 0)
            end

            if #v28.words ~= 28 then
                error(`invalid length {#v28.words}, expected an array of length 28`, 0)
            end

            v26[v27] = {
                name = v28.name,
                source_offset = v28.source_offset,
                words = rt.copy(v28.words)
            }
        end

        v23[v24] = {
            name = v25.name,
            source_offset = v25.source_offset,
            bones = v26
        }
    end

    return {
        version = p9.version,
        source_sha256 = p9.source_sha256,
        skeletons = v23
    }
end

function t1.PhysicsSkeleton.load(_, p13, p14) -- line: 102
    -- upvalues: sim (copy), t1 (copy), eq_ignore_ascii_case (copy), file_from_value (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local physics_skeletons = sim_data and sim_data:FindFirstChild("physics_skeletons")

    if not physics_skeletons then
        error("private/stock/physics-skeletons.json: ReplicatedStorage.Skate3.sim_data.physics_skeletons is not installed", 0)
    end

    local v29 = file_from_value(require(physics_skeletons))

    if v29.version ~= 1 or v29.source_sha256 ~= p13 then
        error("Physics skeleton bank identity or format differs from animation data", 0)
    end

    local t2 = {}

    for _, v30 in v29.skeletons do
        if t2[v30.name] then
            error("Converted physics skeleton has unresolved duplicate names", 0)
        end

        t2[v30.name] = true
    end

    local v31

    for _, v32 in v29.skeletons do
        if eq_ignore_ascii_case(v32.name, p14) then
            v31 = v32
            break
        end
    end

    if v31 == nil then
        error(string.format("Required stock physics skeleton %s is absent", p14), 0)
    end

    local t3 = {}

    if #v31.bones == 0 or #v31.bones > 255 then
        error("Invalid stock physical bone count", 0)
    end

    for _, v33 in v31.bones do
        local v34 = t3[v33.name] == true

        t3[v33.name] = true

        if not v34 then
            for _, v35 in t1.PhysicsBone.size(v33) do
                if v35 ~= v35 or v35 == 1e999 or v35 == (-1e999) then
                    v34 = true
                    break
                end
            end
        end

        if not v34 then
            for _, v36 in t1.PhysicsBone.rotation(v33) do
                if v36 ~= v36 or v36 == 1e999 or v36 == (-1e999) then
                    v34 = true
                    break
                end
            end
        end

        if not v34 then
            for _, v37 in t1.PhysicsBone.translation(v33) do
                if v37 ~= v37 or v37 == 1e999 or v37 == (-1e999) then
                    v34 = true
                    break
                end
            end
        end

        if v34 then
            error(string.format("Invalid or repeated stock physics bone %s", v33.name), 0)
        end
    end

    return v31
end

return t1
