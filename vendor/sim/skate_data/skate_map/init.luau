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

local import = require(sim.import)

local function texture_decode() -- line: 29
    -- upvalues: import (copy)
    return import("skate_data/skate_map/texture_decode")
end

local function storage_v15() -- line: 32
    -- upvalues: import (copy)
    return import("skate_data/skate_map/storage_v15")
end

local t1 = {
    external = {
        zlib = nil,
        zstd = nil
    },
    SkateMap = {},
    Material = {},
    Texture = {},
    Vertex = {},
    Collision = {},
    Geometry = {},
    Rail = {},
    Door = {},
    Light = {},
    Route = {},
    Extension = {},
    Reader = {}
}
local Reader = t1.Reader

t1.StoredBlock = {}

local StoredBlock = t1.StoredBlock

local function bytes_to_string(p3) -- line: 86
    local v2 = #p3
    local v3 = buffer.create(v2)

    for i = 1, v2 do
        local v4 = p3[i]

        buffer.writeu8(v3, i - 1, v4)
    end

    return buffer.tostring(v3)
end

function t1.tag_is(p4, p5) -- line: 95
    if p4[1] == string.byte(p5, 1) and p4[2] == string.byte(p5, 2) and p4[3] == string.byte(p5, 3) then
        return p4[4] == string.byte(p5, 4)
    end

    return false
end

function t1.validate_static_objects(p6, p7) -- line: 108
    -- upvalues: Reader (copy)
    if p7.schema ~= 3 then
        error("Unsupported MOBJ schema", 0)
    end

    local t2 = {
        at = 0,
        bytes = p7.payload
    }
    local v5 = Reader.u(t2)

    Reader.check_count(t2, v5, 80)

    local t3 = {}

    for _ = 0, v5 - 1 do
        local v6 = Reader.u(t2)

        if t3[v6] then
            error("Duplicate MOBJ identity", 0)
        end

        t3[v6] = true

        local v7 = Reader.string(t2)

        Reader.floats(t2, 3)

        for _, v8 in {
                #p6.geometry.indices,
                #p6.geometry.collision
            } do
            if v8 < Reader.u(t2) + Reader.u(t2) then
                error(("MOBJ %* geometry range is invalid"):format(v7), 0)
            end
        end

        local v9 = Reader.u(t2)

        Reader.check_count(t2, v9, 4)

        for _ = 0, v9 - 1 do
            if Reader.u(t2) >= #p6.rails then
                error(("MOBJ %* rail index is invalid"):format(v7), 0)
            end
        end

        if Reader.u(t2) ~= 0 then
            error(("MOBJ %* requests object physics, which requires a body adapter"):format(v7), 0)
        end

        if Reader.u(t2) > 2 then
            error(("MOBJ %* collision shape is invalid"):format(v7), 0)
        end

        Reader.floats(t2, 6)

        for _ = 0, 1 do
            if Reader.u(t2) > 1 then
                error(("MOBJ %* has an invalid boolean"):format(v7), 0)
            end
        end
    end

    if t2.at ~= #t2.bytes then
        error("MOBJ has trailing data", 0)
    end
end

function Reader.take(p8, p9) -- line: 156
    local v10 = p8.at + p9

    if #p8.bytes < v10 then
        error(("Truncated SKATE at byte %* (need %*)"):format(p8.at, p9), 0)
    end

    local v11 = table.create(p9)

    table.move(p8.bytes, p8.at + 1, v10, 1, v11)
    p8.at = v10

    return v11
end

function Reader.u(p10) -- line: 166
    -- upvalues: Reader (copy)
    local v12 = Reader.take(p10, 4)

    return ((v12[4] * 256 + v12[3]) * 256 + v12[2]) * 256 + v12[1]
end

function Reader.f(p11) -- line: 170
    -- upvalues: v1 (copy), Reader (copy)
    buffer.writeu32(v1, 0, (Reader.u(p11)))

    local v14 = buffer.readf32(v1, 0)

    if v14 ~= v14 or v14 == 1e999 or v14 == (-1e999) then
        error(`Non-finite SKATE float at { p11.at - 4 }`, 0)
    end

    return v14
end

function Reader.floats(p12, p13) -- line: 178
    -- upvalues: Reader (copy)
    local v15 = table.create(p13, 0)

    for i = 1, p13 do
        v15[i] = Reader.f(p12)
    end

    return v15
end

function Reader.string(p14) -- line: 185
    -- upvalues: Reader (copy), bytes_to_string (copy)
    local v16 = Reader.u(p14)
    local v17 = bytes_to_string(Reader.take(p14, v16))

    if utf8.len(v17) == nil then
        error("Invalid SKATE UTF-8", 0)
    end

    return v17
end

function Reader.check_count(p15, p16, p17) -- line: 193
    -- upvalues: rt (copy)
    if rt.idiv(#p15.bytes - p15.at, p17) < p16 then
        error("SKATE count exceeds remaining data", 0)
    end
end

function Reader.points(p18) -- line: 198
    -- upvalues: Reader (copy)
    local v18 = Reader.u(p18)

    Reader.check_count(p18, v18, 12)

    local v19 = table.create(v18)

    for _ = 0, v18 - 1 do
        table.insert(v19, Reader.floats(p18, 3))
    end

    return v19
end

function Reader.stored_block(p19, p20) -- line: 207
    -- upvalues: Reader (copy)
    if p20 > 2147483648 then
        error("SKATE decoded block exceeds 2 GiB reader limit", 0)
    end

    local v20 = Reader.u(p19)
    local v21 = Reader.u(p19)

    return {
        expected = p20,
        method = v20,
        bytes = Reader.take(p19, v21)
    }
end

function Reader.stored(p21, p22) -- line: 216
    -- upvalues: Reader (copy), StoredBlock (copy)
    return StoredBlock.decode(Reader.stored_block(p21, p22))
end

function Reader.geometry(p23, p24, p25, p26) -- line: 220
    -- upvalues: rt (copy), Reader (copy)
    local v22 = p24[1]
    local v23 = p24[2]
    local v24 = p24[3]

    Reader.check_count(p23, v22, p26 >= 12 and 56 or 44)

    local v25 = table.create(v22)

    for _ = 0, v22 - 1 do
        table.insert(v25, {
            position = Reader.floats(p23, 3),
            normal = Reader.floats(p23, 3),
            uv = Reader.floats(p23, 2),
            lightmap_uv = Reader.floats(p23, 2),
            material = Reader.u(p23),
            decal_uv = if p26 >= 12 then Reader.floats(p23, 2) else nil,
            tangent_frame = if p26 >= 12 then Reader.take(p23, 4) else nil
        })
    end

    Reader.check_count(p23, v23, 4)

    local v26 = table.create(v23)

    for _ = 0, v23 - 1 do
        table.insert(v26, Reader.u(p23))
    end

    Reader.check_count(p23, v24, p26 >= 11 and 48 or 44)

    local v27 = table.create(v24)

    for _ = 0, v24 - 1 do
        local t5 = {
            Reader.floats(p23, 3),
            Reader.floats(p23, 3),
            (Reader.floats(p23, 3))
        }
        local v28 = Reader.u(p23)
        local v29 = Reader.u(p23)
        local t6

        if p26 >= 11 then
            local v30 = Reader.take(p23, 4)

            if v30[4] ~= 0 then
                t6 = {
                    v30[1],
                    v30[2],
                    v30[3]
                }
            end
        end

        table.insert(v27, {
            points = t5,
            surface = v28,
            material = v29,
            native_edges = t6
        })
    end

    local function valid_material(p27) -- line: 265
        -- upvalues: p25 (copy)
        if p27 > 0 then
            return p27 <= p25
        end

        return false
    end

    local v31 = false

    for _, v32 in v25 do
        local material = v32.material

        if not (material > 0 and material <= p25) then
            v31 = true
            break
        end
    end

    if not v31 then
        for _, v33 in v27 do
            local material = v33.material

            if not (material > 0 and material <= p25) or v33.surface == 0 then
                v31 = true
                break
            end
        end
    end

    if v31 then
        error("SKATE invalid material/surface reference", 0)
    end

    local v34 = rt.irem(#v26, 3) ~= 0

    if not v34 then
        for _, v35 in v26 do
            if #v25 <= v35 then
                v34 = true
                break
            end
        end
    end

    if v34 then
        error("SKATE invalid triangle indices", 0)
    end

    for i = 0, rt.idiv(#v26, 3) - 1 do
        local material = v25[v26[i * 3 + 1] + 1].material

        for j = 0, 2 do
            if v25[v26[i * 3 + j + 1] + 1].material ~= material then
                error("SKATE triangle mixes materials", 0)
            end
        end
    end

    for _, v36 in v27 do
        local v37 = v36.points[1]
        local v38 = v36.points[2]
        local v39 = v36.points[3]
        local t8 = {
            v38[1] - v37[1],
            v38[2] - v37[2],
            v38[3] - v37[3]
        }
        local t9 = {
            v39[1] - v37[1],
            v39[2] - v37[2],
            v39[3] - v37[3]
        }
        local n1 = 0

        for _, v40 in {
                t8[2] * t9[3] - t8[3] * t9[2],
                t8[3] * t9[1] - t8[1] * t9[3],
                t8[1] * t9[2] - t8[2] * t9[1]
            } do
            n1 += v40 * v40
        end

        if n1 ~= n1 or n1 == 1e999 or n1 == (-1e999) or n1 <= 0 then
            error("SKATE degenerate collision triangle", 0)
        end
    end

    return {
        vertices = v25,
        indices = v26,
        collision = v27
    }
end

function StoredBlock.decode(p28) -- line: 332
    -- upvalues: rt (copy), import (copy), t1 (copy)
    local expected, method, bytes = p28.expected, p28.method, p28.bytes
    local result

    if method == 0 then
        result = rt.slice(bytes, 0)
    elseif method == 1 then
        local zlib = t1.external.zlib

        if zlib == nil then
            error("SKATE DEFLATE: zlib decoder is not available in Luau (set skate_map.external.zlib)", 0)
        end

        local v41 = expected + 1
        local v42, v43

        v42, result, v43 = pcall(zlib, bytes, v41)

        if not v42 then
            error(("SKATE DEFLATE: %*"):format(result), 0)
        end

        if v43 ~= #bytes then
            error("SKATE compressed block has unused input", 0)
        end
    elseif method == 2 then
        local zstd = t1.external.zstd

        if zstd == nil then
            error("SKATE Zstandard: zstd decoder is not available in Luau (set skate_map.external.zstd)", 0)
        end

        local v44 = expected + 1
        local ok

        ok, result = pcall(zstd, bytes, v44)

        if not ok then
            error(("SKATE Zstandard: %*"):format(result), 0)
        end
    else
        if method >= 3 and method <= 10 then
            return import("skate_data/skate_map/storage_v15").decode(method, bytes, expected)
        end

        result = nil
        error(("Unsupported SKATE storage method %*"):format(method), 0)
    end

    if #result ~= expected then
        error("SKATE decoded block size mismatch", 0)
    end

    return result
end

local SkateMap = t1.SkateMap

function SkateMap.load(p29) -- line: 385
    -- upvalues: sim (copy), rt (copy), t1 (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local maps = sim_data and sim_data:FindFirstChild("maps")
    local v45 = maps and maps:FindFirstChild(p29)

    if not v45 then
        error(("sim_data: no exported map \"%*\" (run tools/export_collision.py and install roblox/sim_data)"):format(p29), 0)
    end

    if not v45:IsA("ModuleScript") then
        v45 = v45:FindFirstChild("init") or v45:FindFirstChild("index")

        if not v45 then
            error(("sim_data: map \"%*\" has no index module"):format(p29), 0)
        end
    end

    local v47 = require(v45)
    local t10 = {}

    for _, v48 in v47.records("materials") do
        table.insert(t10, {
            retail_definition = nil,
            name = v48.name,
            flags = v48.flags,
            friction = v48.friction,
            restitution = v48.restitution,
            color = rt.copy(v48.color),
            roughness = v48.roughness,
            emissive = v48.emissive,
            textures = rt.copy(v48.textures),
            indirect_strength = v48.indirect_strength,
            alpha_mode = v48.alpha_mode,
            alpha_cutoff = v48.alpha_cutoff,
            audio = v48.audio,
            physics = v48.physics,
            pattern = v48.pattern,
            depth_layer = v48.depth_layer
        })
    end

    local v49 = table.create(v47.collision_count)

    if v47.collision_count > 0 then
        local collision_points = v47.stream("collision_points")
        local collision_surface = v47.stream("collision_surface")
        local collision_material = v47.stream("collision_material")
        local collision_edges = v47.stream("collision_edges")

        for i = 0, v47.collision_count - 1 do
            local v50 = i * 36
            local v51 = i * 4

            table.insert(v49, {
                points = {
                    {
                        buffer.readf32(collision_points, v50),
                        buffer.readf32(collision_points, v50 + 4),
                        (buffer.readf32(collision_points, v50 + 8))
                    },
                    {
                        buffer.readf32(collision_points, v50 + 12),
                        buffer.readf32(collision_points, v50 + 16),
                        (buffer.readf32(collision_points, v50 + 20))
                    },
                    {
                        buffer.readf32(collision_points, v50 + 24),
                        buffer.readf32(collision_points, v50 + 28),
                        (buffer.readf32(collision_points, v50 + 32))
                    }
                },
                surface = buffer.readu32(collision_surface, i * 4),
                material = buffer.readu32(collision_material, i * 4),
                native_edges = if buffer.readu8(collision_edges, v51 + 3) == 0 then nil else {
                    buffer.readu8(collision_edges, v51),
                    buffer.readu8(collision_edges, v51 + 1),
                    (buffer.readu8(collision_edges, v51 + 2))
                }
            })
        end
    end

    local v60 = table.create(v47.rail_count)
    local rail_native = v47.stream("rail_native")
    local rail_points = v47.stream("rail_points")
    local n2 = 0
    local n3 = 0

    for _, v61 in v47.records("rails") do
        local t15 = {
            native = nil,
            name = v61.name,
            closed = v61.closed,
            points = {}
        }

        if v61.native ~= nil then
            if t1.NATIVE_TABLES then
                local v66 = table.create(v61.native)

                for j = 0, v61.native - 1 do
                    local v67 = n2 + j

                    v66[j + 1] = buffer.readu8(rail_native, v67)
                end

                t15.native = v66
            else
                local native = v61.native
                local t17 = {}
                local v68 = n2

                t15.native = setmetatable(t17, {
                    __index = function(_, p31) -- __index | line: 469
                        -- upvalues: rail_native (copy), native (copy), v68 (copy)
                        return if type(p31) == "number" and p31 >= 1 and p31 <= native and p31 % 1 == 0 then buffer.readu8(rail_native, v68 + p31 - 1) else nil
                    end,
                    __len = function() -- __len | line: 475
                        -- upvalues: native (copy)
                        return native
                    end,
                    __newindex = function() -- __newindex | line: 478
                        error("skate_map: a native rail payload is read-only", 0)
                    end,
                    stream = rail_native,
                    offset = n2,
                    size = native
                })
            end

            n2 += v61.native
        else
            for _ = 1, v61.points do
                table.insert(t15.points, {
                    buffer.readf32(rail_points, n3),
                    buffer.readf32(rail_points, n3 + 4),
                    (buffer.readf32(rail_points, n3 + 8))
                })
                n3 += 12
            end
        end

        table.insert(v60, t15)
    end

    local t19 = {}

    for _, v70 in v47.extensions do
        local t20 = {}

        if v70.tag == "RWCM" then
            t20.sim_data_map = p29
        elseif v70.tag == "WMET" then
            t20.sim_data_json = {
                grind_coordinate_policy = {
                    mode = v47.wmet.grind_coordinate_policy_mode
                },
                grind_splines = if v47.wmet.has_grind_splines then v47.records("wmet_grind_splines") else nil
            }
        end

        table.insert(t19, {
            tag = { string.byte(v70.tag, 1, 4) },
            schema = v70.schema,
            payload = t20
        })
    end

    return {
        version = v47.version,
        name = v47.name,
        spawn = rt.copy(v47.spawn),
        heading = v47.heading,
        environment = rt.copy(v47.environment),
        materials = t10,
        textures = {},
        geometry = {
            vertices = {},
            indices = {},
            collision = v49
        },
        rails = v60,
        doors = {},
        lights = {},
        routes = {},
        extensions = t19
    }
end

function SkateMap.parse(p32) -- line: 536
    -- upvalues: SkateMap (copy)
    return SkateMap.parse_with_decode_workers(p32, 1)
end

function SkateMap.parse_with_decode_workers(p33, p34) -- line: 543
    -- upvalues: SkateMap (copy)
    return SkateMap.parse_inner(p33, p34, true)
end

function SkateMap.parse_render_only(p35) -- line: 549
    -- upvalues: SkateMap (copy)
    local v71 = SkateMap.parse_inner(p35, 4, false)
    local v72 = false

    for _, v73 in v71.extensions do
        local tag = v73.tag

        if tag[1] ~= 87 or tag[2] ~= 77 or tag[3] ~= 69 or tag[4] ~= 84 then
            v72 = true
            break
        end
    end

    if #v71.geometry.collision ~= 0
        or #v71.rails ~= 0
        or #v71.doors ~= 0
        or #v71.lights ~= 0
        or #v71.routes ~= 0
        or v72 then
        error("SKATE render-only package contains non-presentation data", 0)
    end

    return v71
end

function SkateMap.parse_inner(p36, p37, p38) -- line: 571
    -- upvalues: rt (copy), import (copy), Reader (copy)
    local v74 = {
        at = 0,
        bytes = p36
    }
    local v75 = Reader.take(v74, 8)

    local function is_ascii_digit(p39) -- line: 575
        if p39 >= 48 then
            return p39 <= 57
        end

        return false
    end

    local v76 = false

    if v75[1] == 83 and v75[2] == 75 and v75[3] == 65 and v75[4] == 84 and v75[5] == 69 and v75[8] == 0 then
        local v77 = v75[6]

        if v77 >= 48 and v77 <= 57 then
            local v78 = v75[7]

            v76 = v78 >= 48 and v78 <= 57
        end
    end

    if not v76 then
        error("Invalid SKATE magic/version", 0)
    end

    local v79 = (v75[6] - 48) * 10 + v75[7] - 48

    if not (v79 >= 1 and v79 <= 15) then
        error("Unsupported SKATE version: reader supports 01 through 15; newer packages require an update", 0)
    end

    if Reader.u(v74) ~= 305419896 then
        error("Invalid SKATE endian marker", 0)
    end

    local v80 = Reader.string(v74)

    if #v80 == 0 then
        error("Empty SKATE map name", 0)
    end

    local v81 = Reader.floats(v74, 3)
    local v82 = Reader.f(v74)
    local v83 = if v79 >= 6 then 45 elseif v79 >= 3 then 14 else 12
    local v84 = table.create(v83)

    for _ = 0, v83 - 1 do
        table.insert(v84, Reader.f(v74))
    end

    local v85 = table.create(9, 0)

    for i = 1,
    if v79 >= 8 then 9
        elseif v79 >= 7 then 8
        elseif v79 >= 4 then 7
        else 6 do
        v85[i] = Reader.u(v74)
    end

    local v86

    if v79 >= 15 then
        local v87 = Reader.u(v74)

        v86 = Reader.stored(v74, v87)
    end

    local v88

    if v86 ~= nil then
        v74, v88 = {
            at = 0,
            bytes = v86
        }, v74
    end

    Reader.check_count(v74, v85[1], v79 >= 2 and 80 or 48)

    local t23 = {}

    for _ = 0, v85[1] - 1 do
        local t24 = {
            name = Reader.string(v74),
            flags = Reader.u(v74),
            friction = Reader.f(v74),
            restitution = Reader.f(v74),
            color = Reader.floats(v74, 3),
            roughness = Reader.f(v74),
            emissive = Reader.f(v74),
            textures = {
                Reader.u(v74),
                Reader.u(v74),
                0, 0, 0
            },
            indirect_strength = Reader.f(v74),
            alpha_mode = 0,
            alpha_cutoff = 0.5,
            audio = 3,
            physics = 1,
            pattern = 0,
            depth_layer = nil,
            retail_definition = nil
        }

        if v79 >= 2 then
            t24.textures[3] = Reader.u(v74)
            t24.textures[4] = Reader.u(v74)
            t24.textures[5] = Reader.u(v74)
            t24.alpha_mode = Reader.u(v74)
            t24.alpha_cutoff = Reader.f(v74)
            t24.audio = Reader.u(v74)
            t24.physics = Reader.u(v74)
            t24.pattern = Reader.u(v74)
        end

        if v79 >= 13 then
            local v89 = Reader.u(v74)

            if v89 > 3 then
                error("Invalid SKATE depth layer", 0)
            end

            t24.depth_layer = v89
        end

        if v79 >= 12 and Reader.u(v74) ~= 0 then
            local at = v74.at

            Reader.take(v74, 16)
            Reader.string(v74)
            Reader.take(v74, 8)

            local v90 = Reader.u(v74)

            Reader.check_count(v74, v90, 20)

            for _ = 0, v90 - 1 do
                Reader.string(v74)

                local v91 = Reader.u(v74)
                local v92 = Reader.u(v74)
                local v93 = Reader.u(v74)
                local v94 = Reader.u(v74)

                if v85[2] < v91 or v92 > 2 or v93 > 1 or v94 > 1 then
                    error("Invalid SKATE retail texture binding", 0)
                end
            end

            local v95 = Reader.u(v74)

            Reader.check_count(v74, v95, 8)

            for _ = 0, v95 - 1 do
                Reader.string(v74)

                local v96 = Reader.u(v74)

                Reader.check_count(v74, v96, 4)

                for _ = 0, v96 - 1 do
                    Reader.string(v74)
                end
            end

            Reader.string(v74)
            t24.retail_definition = rt.slice(v74.bytes, at, v74.at)
        end

        local v97 = false

        for _, v98 in t24.textures do
            if v85[2] < v98 then
                v97 = true
                break
            end
        end

        if #t24.name == 0
            or v97
            or t24.alpha_mode > 2
            or t24.audio > 127
            or t24.physics > 13
            or t24.pattern > 15
            or t24.friction < 0
            or t24.restitution < 0
            or not (t24.roughness >= 0)
            or not (t24.roughness <= 1)
            or not (t24.alpha_cutoff >= 0)
            or not (t24.alpha_cutoff <= 1)
            or t24.indirect_strength < 0 then
            error("Invalid SKATE material", 0)
        end

        table.insert(t23, t24)
    end

    if v88 ~= nil then
        if v74.at ~= #v74.bytes then
            error("SKATE material block has trailing bytes", 0)
        end

        v74 = v88
    end

    Reader.check_count(v74, v85[2], 20)

    local t25 = {}
    local t26 = {}

    for _ = 0, v85[2] - 1 do
        local v99 = Reader.string(v74)
        local v100 = Reader.u(v74)
        local v101 = Reader.u(v74)
        local v102 = Reader.u(v74)

        if v100 == 0 ~= (v101 == 0) or v100 > 16384 or v101 > 16384 or v102 > 1 then
            error("Invalid SKATE embedded texture", 0)
        end

        local v103 = v100 * v101 * 4
        local v104

        if v79 >= 9 then
            v104 = Reader.stored_block(v74, v103)
        else
            local v105 = Reader.u(v74)

            if v105 ~= v103 then
                error("Invalid SKATE embedded texture size", 0)
            end

            v104 = {
                method = 0,
                expected = v103,
                bytes = Reader.take(v74, v105)
            }
        end

        local v106

        if v79 >= 15 and v104.method == 11 then
            if #v104.bytes ~= 4 then
                error("Invalid SKATE texture reference size", 0)
            end

            local bytes = v104.bytes

            v106 = t26[((bytes[4] * 256 + bytes[3]) * 256 + bytes[2]) * 256 + bytes[1] + 1]

            if v106 == nil then
                error("Invalid SKATE forward texture reference", 0)
            end

            if v106.expected ~= v103 then
                error("SKATE texture reference size mismatch", 0)
            end
        else
            v106 = v104
        end

        table.insert(t26, v106)
        table.insert(t25, {
            name = v99,
            width = v100,
            height = v101,
            color_space = v102,
            rgba = {}
        })
    end

    import("skate_data/skate_map/texture_decode").decode(t25, t26, p37)

    local t28 = {
        v85[3],
        v85[4],
        v85[5]
    }
    local v107

    if v79 >= 9 then
        local v108 = Reader.stored(v74, v85[3] * (if v79 >= 12 then 56 else 44))
        local v109 = Reader.stored(v74, v85[4] * 4)

        table.move(v109, 1, #v109, #v108 + 1, v108)

        local v110 = Reader.stored(v74, v85[5] * (if v79 >= 11 then 48 else 44))

        table.move(v110, 1, #v110, #v108 + 1, v108)
        v107 = Reader.geometry({
            at = 0,
            bytes = v108
        }, t28, #t23, v79)
    else
        v107 = Reader.geometry(v74, t28, #t23, v79)
    end

    if #t23 == 0 or #v107.vertices == 0 or #v107.indices == 0 then
        error("SKATE requires materials and render geometry", 0)
    end

    Reader.check_count(v74, v85[6], 12)

    local t29 = {}

    for _ = 0, v85[6] - 1 do
        local v111 = Reader.string(v74)
        local v112 = Reader.u(v74) ~= 0
        local v113 = if v79 >= 10 then Reader.u(v74) else 0
        local v114, v115

        if v113 == 0 then
            v114 = Reader.points(v74)
        elseif v113 == 1 then
            local at = v74.at

            Reader.take(v74, 24)

            local v116 = Reader.u(v74)

            Reader.check_count(v74, v116, 120)
            Reader.take(v74, v116 * 120)
            v114 = {}
            v115 = rt.slice(v74.bytes, at, v74.at)
        else
            error("Unsupported SKATE rail representation", 0)
        end

        table.insert(t29, {
            name = v111,
            closed = v112,
            points = v114,
            native = v115
        })
    end

    Reader.check_count(v74, v85[7], 120)

    local t31 = {}

    for _ = 0, v85[7] - 1 do
        local t32 = {
            name = Reader.string(v74),
            frame = {
                Reader.floats(v74, 3),
                Reader.floats(v74, 3),
                Reader.floats(v74, 3),
                Reader.floats(v74, 3),
                Reader.floats(v74, 3),
                (Reader.floats(v74, 3))
            },
            motion = Reader.floats(v74, 5),
            response = if v79 >= 5 then Reader.floats(v74, 3) else nil,
            friction = Reader.f(v74),
            restitution = Reader.f(v74),
            surface = Reader.u(v74)
        }
        local v117 = Reader.u(v74)
        local v118 = Reader.u(v74)
        local v119 = Reader.u(v74)

        t32.geometry = Reader.geometry(v74, { v117, v118, v119 }, #t23, v79)
        table.insert(t31, t32)
    end

    Reader.check_count(v74, v85[8], 64)

    local t33 = {}

    for _ = 0, v85[8] - 1 do
        local t34 = {
            name = Reader.string(v74),
            kind = Reader.u(v74),
            position = Reader.floats(v74, 3),
            direction = Reader.floats(v74, 3),
            color = Reader.floats(v74, 3),
            intensity = Reader.f(v74),
            range = Reader.f(v74),
            radius = Reader.f(v74),
            inner_cos = Reader.f(v74),
            outer_cos = Reader.f(v74)
        }

        if t34.kind > 2
            or t34.range <= 0
            or t34.intensity < 0
            or t34.radius < 0
            or not (t34.inner_cos >= -1)
            or not (t34.inner_cos <= 1)
            or not (t34.outer_cos >= -1)
            or not (t34.outer_cos <= 1) then
            error("Invalid SKATE light", 0)
        end

        table.insert(t33, t34)
    end

    Reader.check_count(v74, v85[9], 24)

    local t35 = {}

    for _ = 0, v85[9] - 1 do
        local v120 = Reader.string(v74)
        local v121 = Reader.u(v74) ~= 0
        local v122 = Reader.u(v74)
        local v123 = Reader.f(v74)
        local v124 = Reader.f(v74)

        table.insert(t35, {
            rail = {
                native = nil,
                name = v120,
                closed = v121,
                points = Reader.points(v74)
            },
            skaters = v122,
            speed = v123,
            spacing = v124
        })
    end

    local t37 = {}

    if v79 >= 12 then
        local v125 = Reader.u(v74)

        Reader.check_count(v74, v125, 20)

        for _ = 0, v125 - 1 do
            local v126 = Reader.take(v74, 4)
            local v127 = Reader.u(v74)
            local v128 = Reader.u(v74)

            table.insert(t37, {
                tag = v126,
                schema = v127,
                payload = Reader.stored(v74, v128)
            })
        end
    end

    local v129 = false

    for _, v130 in t37 do
        local tag = v130.tag

        if tag[1] == 82 and tag[2] == 87 and tag[3] == 67 and tag[4] == 77 and v130.schema == 1 and #v130.payload ~= 0 then
            v129 = true
            break
        end
    end

    if p38 and #v107.collision == 0 and not v129 then
        error("SKATE requires triangle collision or an embedded RWCM archive", 0)
    end

    if v74.at ~= #p36 then
        error(`SKATE contains { #p36 - v74.at } unexplained trailing bytes`, 0)
    end

    return {
        version = v79,
        name = v80,
        spawn = v81,
        heading = v82,
        environment = v84,
        materials = t23,
        textures = t25,
        geometry = v107,
        rails = t29,
        doors = t31,
        lights = t33,
        routes = t35,
        extensions = t37
    }
end

return t1
