-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p4) -- line: 28
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

local import = require(sim.import)
local v9 = import("skate_game/grind_world/octree")
local Bounds, Octree = v9.Bounds, v9.Octree
local v10 = import("skate_game/grind_world/spline")
local v11 = import("skate_data/skate_map")
local by_provider = import("skate_core/physics/board_world/objects").by_provider
local t1 = {
    SourceIdentity = {}
}

function t1.SourceIdentity.eq(p5, p6) -- line: 54
    if p5.stream_file == p6.stream_file and p5.asset_id == p6.asset_id and p5.section_index == p6.section_index then
        return p5.section_offset == p6.section_offset
    end

    return false
end

t1.Asset = {}
t1.StaticProvider = {}

local StaticProvider = t1.StaticProvider
local string_, number, parse_id

local function json_from_slice(p7) -- line: 73
    if p7.sim_data_json ~= nil then
        return p7.sim_data_json
    end

    local v12 = #p7
    local v13 = buffer.create(v12)

    for i = 1, v12 do
        local v14 = p7[i]

        buffer.writeu8(v13, i - 1, v14)
    end

    return game:GetService("HttpService"):JSONDecode(buffer.tostring(v13))
end

local function is_array(p8) -- line: 85
    if type(p8) ~= "table" then
        return false
    end

    if #p8 > 0 then
        return true
    end

    return next(p8) == nil
end

local v15 = false

function t1.set_reference(p9) -- line: 115
    -- upvalues: v15 (ref)
    local v16 = v15

    v15 = p9

    return v16
end

local readu32, readf32 = buffer.readu32, buffer.readf32

local function native_views(p10) -- line: 121
    for _, v17 in p10 do
        local mt = if v17.native ~= nil then getmetatable(v17.native) else nil

        if type(mt) ~= "table" or mt.stream == nil then
            return false
        end
    end

    return true
end

local v18 = buffer.create(4)

local function fr(p11) -- line: 131
    -- upvalues: v1 (copy), readf32 (copy), v18 (copy)
    if p11 ~= 0 and p11 > -1.1754943508222875E-38 and p11 < 1.1754943508222875E-38 then
        if p11 ~= 0 and p11 > -1.1754943508222875E-38 and p11 < 1.1754943508222875E-38 then
            local v20 = math.abs(p11) * 7.1362384635298E+44
            local v19 = math.floor(v20)
            local v21 = v20 - v19

            if v21 > 0.5 or v21 == 0.5 and v19 % 2 == 1 then
                v19 += 1
            end

            local v22 = v19 * 1.401298464324817E-45

            if p11 < 0 then
                return -v22
            end

            return v22
        end

        buffer.writef32(v1, 0, p11)

        return (buffer.readf32(v1, 0))
    end

    buffer.writef32(v18, 0, p11)

    return (readf32(v18, 0))
end

local self = setmetatable({}, {
    __mode = "k"
})

local function grow(p12, p13) -- line: 143
    -- upvalues: rt (copy), v9 (copy), Bounds (copy), Octree (copy), self (copy)
    local v24 = self[p12]
    local tree = v24.tree

    if tree == nil then
        local spatial = v24.spatial
        local indices = p12.indices
        local v25 = table.create(#indices)

        for v26, v27 in indices do
            local v28 = 6 * v27

            v25[v26] = {
                min = {
                    spatial[v28 + 1],
                    spatial[v28 + 2],
                    spatial[v28 + 3]
                },
                max = {
                    spatial[v28 + 4],
                    spatial[v28 + 5],
                    spatial[v28 + 6]
                }
            }
        end

        if #v25 > 65535 then
            error("Native grind octree exceeds uint16 entry capacity", 0)
        end

        tree = {
            node_capacity = rt.idiv(#v25, 2) + 1,
            nodes = { v9.Node.new(Bounds.cube(p12.bounds)) },
            bounds = v25
        }
        v24.tree = tree
        v24.next = 0
    end

    local elapsed = os.clock()
    local v29 = #tree.bounds
    local v30 = v24.next
    local v31

    while true do
        if v30 < v29 then
            Octree.insert(tree, v30)
            v30 += 1

            if p13 ~= nil and v30 % 16 == 0 and p13 <= os.clock() - elapsed then
                v31 = v30
                break
            end

            continue
        end

        v31 = v30
        break
    end

    v24.next = v31

    if v31 < v29 then
        return nil
    end

    p12.tree = tree
    self[p12] = nil

    return tree
end

function StaticProvider.complete(p14) -- line: 188
    -- upvalues: grow (copy)
    for _, v32 in p14.assets do
        if v32.tree == false then
            grow(v32)
        end
    end

    return p14
end

function StaticProvider.grow_step(p15, p16, p17, p18, p19, p20) -- line: 198
    -- upvalues: grow (copy)
    local n1 = 1e999
    local n2 = 0
    local v33

    for _, v34 in p15.assets do
        if v34.tree == false then
            local bounds = v34.bounds
            local v37 = math.max(bounds.min[1] - p16, 0, p16 - bounds.max[1])
            local v40 = math.max(bounds.min[2] - p17, 0, p17 - bounds.max[2])
            local v43 = math.max(bounds.min[3] - p18, 0, p18 - bounds.max[3])
            local v44 = v37 * v37 + v40 * v40 + v43 * v43

            if p20 == nil or v44 <= p20 * p20 then
                n2 += 1

                if v44 < n1 then
                    n1 = v44
                    v33 = v34
                end
            end
        end
    end

    if v33 ~= nil and grow(v33, p19) ~= nil then
        n2 -= 1
    end

    return n2
end

local function fast_provider(p21, p22) -- line: 220
    -- upvalues: rt (copy), v1 (copy), string_ (ref), number (ref), parse_id (ref), readu32 (copy), readf32 (copy), v18 (copy), self (copy)
    local rails = p21.rails
    local v45 = #rails

    if v45 > 65535 then
        error("Pegasus spline table exceeds its uint16 rail count", 0)
    end

    local v46 = table.create(v45)
    local v47 = table.create(v45)
    local v48 = table.create(v45)
    local n3 = 0
    local v49, v50, v51, offset, v52, v53, v54, v55, rail_index, v56, v57

    for i = 1, v45 do
        v50 = rails[i]
        v51 = v50.native
        v49 = getmetatable(v51)
        v51 = v49.stream
        offset = v49.offset
        v52 = v49.size

        if v52 < 28 then
            error(("Truncated native rail %*"):format(v50.name), 0)
        end

        v54 = offset + 24

        if readu32(v51, v54) ~= rt.idiv(v52 - 28, 120) or rt.irem(v52 - 28, 120) ~= 0 then
            error(("Invalid native rail segment count: %*"):format(v50.name), 0)
        end

        v53 = rt.idiv(rt.idiv(v52, 4) - 7, 30)

        if v53 == 0 then
            error(("Rail %* has no segments"):format(v50.name), 0)
        end

        for j = 0, v53 - 1 do
            v52 = offset + 28 + j * 120

            for k = 0, 27 do
                v56 = v52 + k * 4
                v57 = readu32(v51, v56)

                if bit32.band(v57, 2139095040) == 2139095040 then
                    error(("Non-finite spline data in %*"):format(v50.name), 0)
                end
            end

            for n = 0, 2 do
                rail_index = v52 + 80 + n * 4
                v55 = readf32(v51, rail_index)
                v56 = v52 + 96 + n * 4

                if readf32(v51, v56) < v55 then
                    error(("Inverted spline bounds in %*"):format(v50.name), 0)
                end
            end
        end

        v46[i] = v51
        v47[i] = offset
        v48[i] = v53
        n3 += v53
    end

    if n3 * 144 + (v45 * 32 + 16) > 4294967295 then
        error("Spline blob exceeds uint32 offsets", 0)
    end

    local v58 = table.create(n3)
    local v59 = table.create(n3)

    v49 = table.create(v45)
    v50 = table.create(v45)

    local n4 = 0
    local v60, v61, v62, v63, stream_file, asset_id, v64, v65, v66, v67, v68

    for i = 1, v45 do
        v53 = v46[i]
        v60 = v47[i]
        v54 = string.format("0x%08X%08X", readu32(v53, v60 + 4), (readu32(v53, v60)))

        local v69 = string.format

        v57 = v60 + 12
        v61 = readu32(v53, v57)
        rail_index = v60 + 8
        v69 = v69("0x%08X%08X", v61, (readu32(v53, rail_index)))
        v49[i] = v54
        v50[i] = v69

        for j = 0, v48[i] - 1 do
            v57 = v60 + 28 + j * 120
            v63 = v57 + 48
            v56 = readf32(v53, v63)
            v66 = v57 + 52
            v62 = readf32(v53, v66)
            v64 = v57 + 56
            v63 = readf32(v53, v64)
            v65 = v57 + 60
            rail_index = {
                v56,
                v62,
                v63,
                (readf32(v53, v65))
            }
            v66 = readf32(v53, v57)
            v67 = v57 + 16
            v63 = v66 + readf32(v53, v67)
            v67 = v57 + 32
            v62 = v63 + (readf32(v53, v67) + rail_index[1])
            v67 = v57 + 4
            v64 = readf32(v53, v67)
            stream_file = v57 + 20
            v66 = v64 + readf32(v53, stream_file)
            stream_file = v57 + 36
            v63 = v66 + (readf32(v53, stream_file) + rail_index[2])
            stream_file = v57 + 8
            v65 = readf32(v53, stream_file)
            asset_id = v57 + 24
            v64 = v65 + readf32(v53, asset_id)
            asset_id = v57 + 40
            v66 = v64 + (readf32(v53, asset_id) + rail_index[3])
            asset_id = v57 + 12
            v67 = readf32(v53, asset_id)
            v68 = v57 + 28
            v65 = v67 + readf32(v53, v68)
            v68 = v57 + 44
            v56 = {
                v62,
                v63,
                v66,
                v65 + (readf32(v53, v68) + rail_index[4])
            }
            v57 = 0 + (v56[1] - rail_index[1]) ^ 2 + (v56[2] - rail_index[2]) ^ 2 + (v56[3] - rail_index[3]) ^ 2

            if v57 ~= v57 or v57 == 1e999 or v57 == (-1e999) then
                error(("Spline segment %* has a non-finite contact chord"):format(n4), 0)
            end

            v63 = v56[1] - rail_index[1]

            if math.abs(v63) <= 1.52587890625E-05 then
                v63 = v56[3] - rail_index[3]
                v57 = math.abs(v63) <= 1.52587890625E-05
            else
                v57 = false
            end

            n4 += 1
            v58[n4] = {
                start = rail_index,
                ["end"] = v56,
                owner = i
            }
            v62 = {
                spline_guids = { v54, v69 },
                segment_index = j,
                flags = v57 and 2147483648 or 0
            }
            v59[n4] = v62
        end
    end

    local t4 = {}
    local t5 = {}

    v52 = table.create(n3 * 6, 0)
    v53 = table.create(n3)
    v60 = table.create(n3)
    v54 = table.create(v45)
    v55 = #p22

    local v70 = math.min(v55, v45) - 1

    n4 = 0

    local section_index, section_offset, v71, v72, v73, v74, v75, v76

    for i = 0, v70 do
        v61 = p22[i + 1]
        v55 = rails[i + 1]
        v57 = {
            stream_file = string_(v61, "stream_file"),
            asset_id = string_(v61, "asset_id"),
            section_index = number(v61, "section_index"),
            section_offset = number(v61, "section_offset")
        }
        rail_index = number(v61, "rail_index")
        v56 = ("%*_%*_%*"):format(v57.asset_id, v57.section_index, rail_index)

        if v55.name ~= v56 then
            error(("Stock rail provenance/name mismatch: %*"):format(v55.name), 0)
        end

        v62 = v46[i + 1]
        v63 = v47[i + 1]
        v66 = v48[i + 1]
        v64 = v49[i + 1]
        v65 = v50[i + 1]
        asset_id = {
            v64,
            v65
        }
        table.insert(v54, asset_id)

        local v77 = false

        if parse_id(v61, "spline_id") == v64 and number(v61, "segment_count") == v66 and parse_id(v61, "type_signature") == v65 then
            v67 = number(v61, "flags")
            v68 = v63 + 16

            if v67 == readu32(v62, v68) then
                v67 = number(v61, "trailing_word")
                v68 = v63 + 20

                if v67 == readu32(v62, v68) and type(v61) == "table" then
                    v77 = v61.closed == v55.closed
                end
            end
        end

        if not v77 then
            error(("Stock rail native identity/count mismatch: %*"):format(v55.name), 0)
        end

        v65 = table.concat
        stream_file = v57.stream_file
        asset_id = v57.asset_id
        section_index = v57.section_index
        v68 = tostring(section_index)
        section_offset = v57.section_offset
        v65 = v65({
            stream_file,
            asset_id,
            v68,
            (tostring(section_offset))
        }, "\000")
        v64 = t5[v65]

        if v64 == nil then
            v64 = #t4
            asset_id = {
                v57,
                {}
            }
            table.insert(t4, asset_id)
            t5[v65] = v64
        end

        v65 = t4[v64 + 1][2]
        v67 = v66 - 1

        for j = 0, v67 do
            v56 = v63 + 28 + j * 120
            v57 = n4 * 6

            for k = 0, 2 do
                v71 = readf32(v62, v56 + 80 + k * 4)
                v74 = v56 + 96 + k * 4
                v72 = readf32(v62, v74)

                local v78 = v72 + v71
                local v79, v80, v81

                if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
                    if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
                        v79 = math.abs(v78) * 7.1362384635298E+44
                        v80 = math.floor(v79)
                        v81 = v79 - v80
                        v61 = (if v81 > 0.5 or v81 == 0.5 and v80 % 2 == 1 then v80 + 1 else v80) * 1.401298464324817E-45

                        if v78 < 0 then
                            v61 = -v61
                        end
                    else
                        buffer.writef32(v1, 0, v78)
                        v61 = buffer.readf32(v1, 0)
                    end
                else
                    buffer.writef32(v18, 0, v78)
                    v61 = readf32(v18, 0)
                end

                v73 = v61 * 0.5

                local v82

                if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
                    if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
                        v82 = math.abs(v73) * 7.1362384635298E+44
                        v79 = math.floor(v82)

                        local v83 = v82 - v79

                        v74 = (if v83 > 0.5 or v83 == 0.5 and v79 % 2 == 1 then v79 + 1 else v79) * 1.401298464324817E-45

                        if v73 < 0 then
                            v74 = -v74
                        end
                    else
                        buffer.writef32(v1, 0, v73)
                        v74 = buffer.readf32(v1, 0)
                    end
                else
                    buffer.writef32(v18, 0, v73)
                    v74 = readf32(v18, 0)
                end

                local v84 = v72 - v71
                local v85, v86, v87

                if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
                    if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
                        v85 = math.abs(v84) * 7.1362384635298E+44
                        v86 = math.floor(v85)
                        v87 = v85 - v86
                        v82 = (if v87 > 0.5 or v87 == 0.5 and v86 % 2 == 1 then v86 + 1 else v86) * 1.401298464324817E-45

                        if v84 < 0 then
                            v82 = -v82
                        end
                    else
                        buffer.writef32(v1, 0, v84)
                        v82 = buffer.readf32(v1, 0)
                    end
                else
                    buffer.writef32(v18, 0, v84)
                    v82 = readf32(v18, 0)
                end

                v75 = v82 * 0.5

                if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
                    if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
                        v79 = math.abs(v75) * 7.1362384635298E+44
                        v80 = math.floor(v79)
                        v81 = v79 - v80
                        v78 = (if v81 > 0.5 or v81 == 0.5 and v80 % 2 == 1 then v80 + 1 else v80) * 1.401298464324817E-45

                        if v75 < 0 then
                            v78 = -v78
                        end
                    else
                        buffer.writef32(v1, 0, v75)
                        v78 = buffer.readf32(v1, 0)
                    end
                else
                    buffer.writef32(v18, 0, v75)
                    v78 = readf32(v18, 0)
                end

                v75 = v57 + 1 + k
                v84 = v74 - v78

                if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
                    if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
                        v76 = math.abs(v84) * 7.1362384635298E+44
                        v80 = math.floor(v76)
                        v81 = v76 - v80
                        v72 = (if v81 > 0.5 or v81 == 0.5 and v80 % 2 == 1 then v80 + 1 else v80) * 1.401298464324817E-45

                        if v84 < 0 then
                            v72 = -v72
                        end
                    else
                        buffer.writef32(v1, 0, v84)
                        v72 = buffer.readf32(v1, 0)
                    end
                else
                    buffer.writef32(v18, 0, v84)
                    v72 = readf32(v18, 0)
                end

                v52[v75] = v72
                v75 = v57 + 4 + k
                v84 = v74 + v78

                if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
                    if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
                        v85 = math.abs(v84) * 7.1362384635298E+44
                        v86 = math.floor(v85)
                        v87 = v85 - v86
                        v82 = (if v87 > 0.5 or v87 == 0.5 and v86 % 2 == 1 then v86 + 1 else v86) * 1.401298464324817E-45

                        if v84 < 0 then
                            v82 = -v82
                        end
                    else
                        buffer.writef32(v1, 0, v84)
                        v82 = buffer.readf32(v1, 0)
                    end
                else
                    buffer.writef32(v18, 0, v84)
                    v82 = readf32(v18, 0)
                end

                v52[v75] = v82
            end

            table.insert(v65, n4)
            table.insert(v53, v64)
            table.insert(v60, rail_index)
            n4 += 1
        end
    end

    v70 = table.create(#t4)

    for _, v88 in t4 do
        v57 = v88[1]
        rail_index = v88[2]

        if #rail_index == 0 then
            error("Empty stock grind source section", 0)
        end

        v49 = 6 * rail_index[1]
        v56 = v52[v49 + 1]
        v62 = v52[v49 + 2]
        v63 = v52[v49 + 3]
        v66 = v52[v49 + 4]
        v64 = v52[v49 + 5]
        v65 = v52[v49 + 6]
        v67 = #rail_index

        for n = 2, v67 do
            v49 = 6 * rail_index[n]
            v56 = rt.fmin(v56, v52[v49 + 1])
            v62 = rt.fmin(v62, v52[v49 + 2])
            v63 = rt.fmin(v63, v52[v49 + 3])
            v66 = rt.fmax(v66, v52[v49 + 4])
            v64 = rt.fmax(v64, v52[v49 + 5])
            v65 = rt.fmax(v65, v52[v49 + 6])
        end

        v49 = {}
        v67 = {}
        asset_id = v56 - 1

        if asset_id == 0 then
            buffer.writef32(v18, 0, asset_id)
            v50 = readf32(v18, 0)
        elseif asset_id > -1.1754943508222875E-38 and asset_id < 1.1754943508222875E-38 then
            if asset_id == 0 then
                buffer.writef32(v1, 0, asset_id)
                v50 = buffer.readf32(v1, 0)
            elseif asset_id > -1.1754943508222875E-38 and asset_id < 1.1754943508222875E-38 then
                local v89 = math.abs(asset_id) * 7.1362384635298E+44

                section_offset = math.floor(v89)
                v48 = v89 - section_offset

                if v48 > 0.5 or v48 == 0.5 and section_offset % 2 == 1 then
                    section_offset += 1
                end

                v50 = section_offset * 1.401298464324817E-45

                if asset_id < 0 then
                    v50 = -v50
                end
            else
                buffer.writef32(v1, 0, asset_id)
                v50 = buffer.readf32(v1, 0)
            end
        else
            buffer.writef32(v18, 0, asset_id)
            v50 = readf32(v18, 0)
        end

        v68 = v62 - 1

        local v90

        if v68 == 0 then
            buffer.writef32(v18, 0, v68)
            v90 = readf32(v18, 0)
        elseif v68 > -1.1754943508222875E-38 and v68 < 1.1754943508222875E-38 then
            if v68 == 0 then
                buffer.writef32(v1, 0, v68)
                v90 = buffer.readf32(v1, 0)
            elseif v68 > -1.1754943508222875E-38 and v68 < 1.1754943508222875E-38 then
                local v91 = math.abs(v68) * 7.1362384635298E+44

                v76 = math.floor(v91)
                v45 = v91 - v76

                if v45 > 0.5 or v45 == 0.5 and v76 % 2 == 1 then
                    v76 += 1
                end

                v90 = v76 * 1.401298464324817E-45

                if v68 < 0 then
                    v90 = -v90
                end
            else
                buffer.writef32(v1, 0, v68)
                v90 = buffer.readf32(v1, 0)
            end
        else
            buffer.writef32(v18, 0, v68)
            v90 = readf32(v18, 0)
        end

        section_index = v63 - 1

        if section_index == 0 then
            buffer.writef32(v18, 0, section_index)
            rails = readf32(v18, 0)
        elseif section_index > -1.1754943508222875E-38 and section_index < 1.1754943508222875E-38 then
            if section_index == 0 then
                buffer.writef32(v1, 0, section_index)
                rails = buffer.readf32(v1, 0)
            elseif section_index > -1.1754943508222875E-38 and section_index < 1.1754943508222875E-38 then
                v72 = math.abs(section_index) * 7.1362384635298E+44
                v71 = math.floor(v72)
                v73 = v72 - v71

                if v73 > 0.5 or v73 == 0.5 and v71 % 2 == 1 then
                    v71 += 1
                end

                rails = v71 * 1.401298464324817E-45

                if section_index < 0 then
                    rails = -rails
                end
            else
                buffer.writef32(v1, 0, section_index)
                rails = buffer.readf32(v1, 0)
            end
        else
            buffer.writef32(v18, 0, section_index)
            rails = readf32(v18, 0)
        end

        v67[1] = v50
        v67[2] = v90
        v67[3] = rails
        v49.min = v67
        v67 = {}
        asset_id = v66 + 1

        if asset_id == 0 then
            buffer.writef32(v18, 0, asset_id)
            v68 = readf32(v18, 0)
        elseif asset_id > -1.1754943508222875E-38 and asset_id < 1.1754943508222875E-38 then
            if asset_id == 0 then
                buffer.writef32(v1, 0, asset_id)
                v68 = buffer.readf32(v1, 0)
            elseif asset_id > -1.1754943508222875E-38 and asset_id < 1.1754943508222875E-38 then
                v76 = math.abs(asset_id) * 7.1362384635298E+44
                v72 = math.floor(v76)

                local v92 = v76 - v72

                if v92 > 0.5 or v92 == 0.5 and v72 % 2 == 1 then
                    v72 += 1
                end

                v68 = v72 * 1.401298464324817E-45

                if asset_id < 0 then
                    v68 = -v68
                end
            else
                buffer.writef32(v1, 0, asset_id)
                v68 = buffer.readf32(v1, 0)
            end
        else
            buffer.writef32(v18, 0, asset_id)
            v68 = readf32(v18, 0)
        end

        local v93 = v64 + 1

        if v93 == 0 then
            buffer.writef32(v18, 0, v93)
            section_index = readf32(v18, 0)
        elseif v93 > -1.1754943508222875E-38 and v93 < 1.1754943508222875E-38 then
            if v93 == 0 then
                buffer.writef32(v1, 0, v93)
                section_index = buffer.readf32(v1, 0)
            elseif v93 > -1.1754943508222875E-38 and v93 < 1.1754943508222875E-38 then
                v72 = math.abs(v93) * 7.1362384635298E+44
                v71 = math.floor(v72)
                v73 = v72 - v71

                if v73 > 0.5 or v73 == 0.5 and v71 % 2 == 1 then
                    v71 += 1
                end

                section_index = v71 * 1.401298464324817E-45

                if v93 < 0 then
                    section_index = -section_index
                end
            else
                buffer.writef32(v1, 0, v93)
                section_index = buffer.readf32(v1, 0)
            end
        else
            buffer.writef32(v18, 0, v93)
            section_index = readf32(v18, 0)
        end

        local v94 = v65 + 1

        if v94 == 0 then
            buffer.writef32(v18, 0, v94)
            section_offset = readf32(v18, 0)
        elseif v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
            if v94 == 0 then
                buffer.writef32(v1, 0, v94)
                section_offset = buffer.readf32(v1, 0)
            elseif v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
                v71 = math.abs(v94) * 7.1362384635298E+44
                v74 = math.floor(v71)
                v75 = v71 - v74

                if v75 > 0.5 or v75 == 0.5 and v74 % 2 == 1 then
                    v74 += 1
                end

                section_offset = v74 * 1.401298464324817E-45

                if v94 < 0 then
                    section_offset = -section_offset
                end
            else
                buffer.writef32(v1, 0, v94)
                section_offset = buffer.readf32(v1, 0)
            end
        else
            buffer.writef32(v18, 0, v94)
            section_offset = readf32(v18, 0)
        end

        v67[1] = v68
        v67[2] = section_index
        v67[3] = section_offset
        v49.max = v67
        v65 = {
            tree = false,
            source = v57,
            bounds = v49,
            indices = rail_index
        }
        self[v65] = {
            spatial = v52
        }
        table.insert(v70, v65)
    end

    return {
        primitives = v58,
        metadata = v59,
        rail_guids = v54,
        assets = v70,
        source_for_primitive = v53,
        source_rail_indices = v60
    }
end

function StaticProvider.new(p23) -- line: 406
    -- upvalues: rt (copy), v1 (copy), Bounds (copy), Octree (copy), v10 (copy), v11 (copy), StaticProvider (copy), string_ (ref), number (ref), parse_id (ref), json_from_slice (copy), v15 (ref), native_views (copy), fast_provider (copy)
    if p23 == nil or #p23.rails == 0 then
        return {
            primitives = {},
            metadata = {},
            rail_guids = {},
            assets = {},
            source_for_primitive = {},
            source_rail_indices = {}
        }
    end

    local v95 = true

    for _, v96 in p23.rails do
        if v96.native ~= nil then
            v95 = false
            break
        end
    end

    if v95 then
        return StaticProvider.authored(p23.rails)
    end

    local t6 = {}

    for _, v97 in p23.extensions do
        if v11.tag_is(v97.tag, "WMET") then
            table.insert(t6, v97)
        end
    end

    local v98 = t6[1]

    if v98 == nil then
        error("Stock grind provider requires WMET source identity metadata", 0)
    end

    if v98.schema ~= 1 or t6[2] ~= nil then
        error("Expected exactly one WMET schema 1 extension", 0)
    end

    local payload = v98.payload
    local ok, result = pcall(json_from_slice, payload)

    if not ok then
        error(("Invalid WMET: %*"):format(result), 0)
    end

    local grind_coordinate_policy = if type(result) == "table" then result.grind_coordinate_policy else nil

    if (if type(grind_coordinate_policy) == "table" then grind_coordinate_policy.mode else nil) ~= "world_space" then
        error("Static grind provider requires verified world_space spline payloads", 0)
    end

    local grind_splines = result.grind_splines

    if type(grind_splines) ~= "table" or not (#grind_splines > 0) and next(grind_splines) ~= nil then
        error("WMET grind_splines array missing", 0)
    end

    if #grind_splines ~= #p23.rails then
        error("WMET/package rail count mismatch", 0)
    end

    if not v15 and native_views(p23.rails) then
        return (fast_provider(p23, grind_splines))
    end

    local v100 = v10.build(p23)
    local v101, v102 = v10.decoded_from_blob(v100)

    local function word(p24) -- line: 471
        -- upvalues: v100 (copy)
        return ((v100[p24 + 1] * 256 + v100[p24 + 2]) * 256 + v100[p24 + 3]) * 256 + v100[p24 + 4]
    end

    local t7 = {}
    local t8 = {}
    local v103 = table.create(#v101)
    local v104 = table.create(#v101)
    local v105 = table.create(#v101)
    local v106 = table.create(#p23.rails)
    local v109 = math.min(#grind_splines, #p23.rails) - 1
    local n5 = 0

    for i = 0, v109 do
        local v110 = grind_splines[i + 1]
        local v111 = p23.rails[i + 1]

        if v111.native == nil then
            error(("Stock rail %* lacks native cubic payload"):format(v111.name), 0)
        end

        local t9 = {
            stream_file = string_(v110, "stream_file"),
            asset_id = string_(v110, "asset_id"),
            section_index = number(v110, "section_index"),
            section_offset = number(v110, "section_offset")
        }
        local rail_index = number(v110, "rail_index")
        local v112 = ("%*_%*_%*"):format(t9.asset_id, t9.section_index, rail_index)

        if v111.name ~= v112 then
            error(("Stock rail provenance/name mismatch: %*"):format(v111.name), 0)
        end

        local v113 = i * 32 + 16
        local v114 = v113 + 20
        local v115 = ((v100[v114 + 1] * 256 + v100[v114 + 2]) * 256 + v100[v114 + 3]) * 256 + v100[v114 + 4]
        local v116 = v113 + 24
        local v117 = ((v100[v116 + 1] * 256 + v100[v116 + 2]) * 256 + v100[v116 + 3]) * 256 + v100[v116 + 4]
        local v118 = rt.idiv(v117 - v115, 144) + 1
        local format = string.format
        local v119 = ((v100[v113 + 1] * 256 + v100[v113 + 2]) * 256 + v100[v113 + 3]) * 256 + v100[v113 + 4]
        local v120 = v113 + 4
        local v121 = format("0x%08X%08X", v119, ((v100[v120 + 1] * 256 + v100[v120 + 2]) * 256 + v100[v120 + 3]) * 256 + v100[v120 + 4])
        local format2 = string.format
        local v122 = v113 + 8
        local v123 = ((v100[v122 + 1] * 256 + v100[v122 + 2]) * 256 + v100[v122 + 3]) * 256 + v100[v122 + 4]
        local v124 = v113 + 12
        local v125 = format2("0x%08X%08X", v123, ((v100[v124 + 1] * 256 + v100[v124 + 2]) * 256 + v100[v124 + 3]) * 256 + v100[v124 + 4])

        table.insert(v106, {
            v121,
            v125
        })

        local v126 = false

        if parse_id(v110, "spline_id") == v121 and number(v110, "segment_count") == v118 and parse_id(v110, "type_signature") == v125 then
            local flags = number(v110, "flags")
            local v127 = v113 + 16

            if flags == ((v100[v127 + 1] * 256 + v100[v127 + 2]) * 256 + v100[v127 + 3]) * 256 + v100[v127 + 4] then
                local trailing_word = number(v110, "trailing_word")
                local v128 = v113 + 28

                if trailing_word == ((v100[v128 + 1] * 256 + v100[v128 + 2]) * 256 + v100[v128 + 3]) * 256 + v100[v128 + 4] and type(v110) == "table" then
                    v126 = v110.closed == v111.closed
                end
            end
        end

        if not v126 then
            error(("Stock rail native identity/count mismatch: %*"):format(v111.name), 0)
        end

        local v130 = table.concat({
            t9.stream_file,
            t9.asset_id,
            tostring(t9.section_index),
            (tostring(t9.section_offset))
        }, "\000")
        local v131 = t8[v130]

        if v131 == nil then
            v131 = #t7
            table.insert(t7, {
                t9,
                {}
            })
            t8[v130] = v131
        end

        for j = 0, v118 - 1 do
            local v132 = v115 + j * 144
            local t12 = {}
            local v133 = v132 + 80 + 0

            buffer.writeu32(v1, 0, ((v100[v133 + 1] * 256 + v100[v133 + 2]) * 256 + v100[v133 + 3]) * 256 + v100[v133 + 4])

            local v135 = buffer.readf32(v1, 0)
            local v136 = v132 + 80 + 4

            buffer.writeu32(v1, 0, ((v100[v136 + 1] * 256 + v100[v136 + 2]) * 256 + v100[v136 + 3]) * 256 + v100[v136 + 4])

            local v138 = buffer.readf32(v1, 0)
            local v139 = v132 + 80 + 8

            buffer.writeu32(v1, 0, ((v100[v139 + 1] * 256 + v100[v139 + 2]) * 256 + v100[v139 + 3]) * 256 + v100[v139 + 4])
            t12.min = {
                v135,
                v138,
                (buffer.readf32(v1, 0))
            }

            local v141 = v132 + 96 + 0

            buffer.writeu32(v1, 0, ((v100[v141 + 1] * 256 + v100[v141 + 2]) * 256 + v100[v141 + 3]) * 256 + v100[v141 + 4])

            local v143 = buffer.readf32(v1, 0)
            local v144 = v132 + 96 + 4

            buffer.writeu32(v1, 0, ((v100[v144 + 1] * 256 + v100[v144 + 2]) * 256 + v100[v144 + 3]) * 256 + v100[v144 + 4])

            local v146 = buffer.readf32(v1, 0)
            local v147 = v132 + 96 + 8

            buffer.writeu32(v1, 0, ((v100[v147 + 1] * 256 + v100[v147 + 2]) * 256 + v100[v147 + 3]) * 256 + v100[v147 + 4])
            t12.max = {
                v143,
                v146,
                (buffer.readf32(v1, 0))
            }
            table.insert(v103, Bounds.identity_transformed(t12))
            table.insert(t7[v131 + 1][2], n5)
            table.insert(v104, v131)
            table.insert(v105, rail_index)
            n5 += 1
        end
    end

    local v150 = table.create(#t7)

    for _, v151 in t7 do
        local v152 = v151[1]
        local v153 = v151[2]

        if #v153 == 0 then
            error("Empty stock grind source section", 0)
        end

        local v154 = rt.copy(v103[v153[1] + 1])

        for k = 2, #v153 do
            v154 = Bounds.union(v154, v103[v153[k] + 1])
        end

        local v155 = Bounds.padded(v154)
        local v156 = table.create(#v153)

        for _, v157 in v153 do
            table.insert(v156, rt.copy(v103[v157 + 1]))
        end

        table.insert(v150, {
            source = v152,
            bounds = v155,
            indices = v153,
            tree = Octree.new(v155, v156)
        })
    end

    return {
        primitives = v101,
        metadata = v102,
        rail_guids = v106,
        assets = v150,
        source_for_primitive = v104,
        source_rail_indices = v105
    }
end

function StaticProvider.authored(p25) -- line: 576
    -- upvalues: rt (copy), Bounds (copy), Octree (copy), v10 (copy)
    local v159 = v10.build_rails(p25)
    local v160, v161 = v10.decoded_from_blob(v159)

    local function word(p26) -- line: 579
        -- upvalues: v159 (copy)
        return ((v159[p26 + 1] * 256 + v159[p26 + 2]) * 256 + v159[p26 + 3]) * 256 + v159[p26 + 4]
    end

    local v162 = table.create(#p25)

    for i = 0, #p25 - 1 do
        local v163 = i * 32 + 16
        local format = string.format
        local v164 = ((v159[v163 + 1] * 256 + v159[v163 + 2]) * 256 + v159[v163 + 3]) * 256 + v159[v163 + 4]
        local v165 = v163 + 4
        local v166 = format("0x%08X%08X", v164, ((v159[v165 + 1] * 256 + v159[v165 + 2]) * 256 + v159[v165 + 3]) * 256 + v159[v165 + 4])
        local format2 = string.format
        local v167 = v163 + 8
        local v168 = ((v159[v167 + 1] * 256 + v159[v167 + 2]) * 256 + v159[v167 + 3]) * 256 + v159[v167 + 4]
        local v169 = v163 + 12

        table.insert(v162, {
            v166,
            format2("0x%08X%08X", v168, ((v159[v169 + 1] * 256 + v159[v169 + 2]) * 256 + v159[v169 + 3]) * 256 + v159[v169 + 4])
        })
    end

    local v170 = table.create(#v160)

    for _, v171 in v160 do
        table.insert(v170, {
            min = rt.from_fn(3, function(p27) -- line: 593
                -- upvalues: v171 (copy), rt (copy)
                return rt.fmin(v171.start[p27 + 1], v171["end"][p27 + 1])
            end),
            max = rt.from_fn(3, function(p28) -- line: 596
                -- upvalues: v171 (copy), rt (copy)
                return rt.fmax(v171.start[p28 + 1], v171["end"][p28 + 1])
            end)
        })
    end

    local t16

    if #v170 > 0 then
        local v172 = rt.copy(v170[1])

        for i = 2, #v170 do
            v172 = Bounds.union(v172, v170[i])
        end

        local v173 = Bounds.padded(v172)
        local v174 = table.create(#v160)

        for i = 0, #v160 - 1 do
            table.insert(v174, i)
        end

        t16 = {
            {
                source = {
                    stream_file = "",
                    asset_id = "host-authored",
                    section_index = 0,
                    section_offset = 0
                },
                bounds = v173,
                indices = v174,
                tree = Octree.new(v173, rt.copy(v170))
            }
        }
    else
        t16 = {}
    end

    local v175 = table.create(#v160)

    for _, v176 in v160 do
        table.insert(v175, v176.owner - 1)
    end

    return {
        source_for_primitive = rt.filled(#v160, 0),
        primitives = v160,
        metadata = v161,
        rail_guids = v162,
        assets = t16,
        source_rail_indices = v175
    }
end

function StaticProvider.primitives(p29) -- line: 637
    return p29.primitives
end

function StaticProvider.metadata(p30, p31) -- line: 642
    return p30.metadata[p31 + 1]
end

function StaticProvider.spline_guids(p32, p33) -- line: 648
    -- upvalues: rt (copy)
    if p33 < 1 then
        return nil
    end

    local v178 = p33 - 1
    local v179 = p32.rail_guids[v178 + 1]

    if v179 == nil then
        return nil
    end

    return rt.copy(v179)
end

function StaticProvider.source_rail_index(p34, p35) -- line: 661
    return p34.source_rail_indices[p35 + 1]
end

function StaticProvider.source(p36, p37) -- line: 666
    local v180 = p36.source_for_primitive[p37 + 1]

    return if v180 ~= nil then p36.assets[v180 + 1].source else nil
end

function StaticProvider.query(p38, p39, p40) -- line: 678
    -- upvalues: rt (copy), Bounds (copy), Octree (copy), by_provider (copy), grow (copy)
    for i = 1, 3 do
        local v181 = p39[i]
        local v182 = false

        if v181 == v181 and v181 ~= 1e999 and v181 ~= (-1e999) then
            local v183 = p40[i]

            v182 = v183 == v183 and v183 ~= 1e999 and v183 ~= (-1e999) and not (p39[i] > p40[i])
        end

        if not v182 then
            error("Invalid grind query bounds", 0)
        end
    end

    local t17 = {
        min = rt.copy(p39),
        max = rt.copy(p40)
    }
    local t18 = {
        p39[1] - p40[1],
        p39[2] - p40[2],
        p39[3] - p40[3]
    }

    if not (t18[1] * t18[1] + t18[2] * t18[2] + t18[3] * t18[3] > 1.52587890625E-05) then
        return {}
    end

    local t19 = {}

    for _, v184 in p38.assets do
        if Bounds.overlaps(v184.bounds, t17) then
            local tree = v184.tree

            if tree == false then
                tree = grow(v184)
            end

            for _, v185 in Octree.query(tree, t17, 40 - #t19) do
                table.insert(t19, v184.indices[v185 + 1])
            end

            if #t19 == 40 then
                break
            end
        end
    end

    local v187 = by_provider[p38]

    if v187 ~= nil and #t19 < 40 then
        v187.rails_into(v187, t17, t19)
    end

    return t19
end

function string_(p41, p42) -- line: 714
    local v188 = if type(p41) == "table" then p41[p42] else nil

    if type(v188) ~= "string" then
        error(("WMET rail missing string %*"):format(p42), 0)
    end

    return v188
end

t1.string = string_

function number(p43, p44) -- line: 722
    local v189 = if type(p43) == "table" then p43[p44] else nil

    if type(v189) ~= "number" or v189 < 0 or v189 ~= math.floor(v189) or v189 > 18446744073709552000 then
        error(("WMET rail missing unsigned %*"):format(p44), 0)
    end

    return v189
end

t1.number = number

function parse_id(p45, p46) -- line: 732
    -- upvalues: string_ (ref)
    local v190 = string_(p45, p46)

    if string.sub(v190, 1, 2) == "0x" then
        v190 = string.sub(v190, 3)
    end

    if string.sub(v190, 1, 1) == "+" then
        v190 = string.sub(v190, 2)
    end

    if #v190 == 0 or string.find(v190, "[^0-9a-fA-F]") ~= nil then
        error(("Invalid WMET %*"):format(p46), 0)
    end

    local v191 = string.gsub(v190, "^0+", "")

    if #v191 > 16 then
        error(("Invalid WMET %*"):format(p46), 0)
    end

    return "0x" .. string.rep("0", 16 - #v191) .. string.upper(v191)
end

t1.parse_id = parse_id

return t1
