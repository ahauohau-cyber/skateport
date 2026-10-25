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

require(sim.import)

local t1 = {
    RetailTriangle = {}
}

local function span(p5, p6, p7) -- line: 50
    if p6 + p7 > #p5 then
        error(("Truncated RWCM at %* (need %*)"):format(p6, p7), 0)
    end

    local v9 = table.create(p7)

    table.move(p5, p6 + 1, p6 + p7, 1, v9)

    return v9
end

t1.span = span

function t1.be16(p8, p9) -- line: 60
    -- upvalues: span (copy)
    local v10 = span(p8, p9, 2)

    return v10[1] * 256 + v10[2]
end

function t1.be32(p10, p11) -- line: 65
    -- upvalues: span (copy)
    local v11 = span(p10, p11, 4)

    return ((v11[1] * 256 + v11[2]) * 256 + v11[3]) * 256 + v11[4]
end

function t1.le32(p12, p13) -- line: 71
    -- upvalues: span (copy)
    local v12 = span(p12, p13, 4)

    return ((v12[4] * 256 + v12[3]) * 256 + v12[2]) * 256 + v12[1], p13 + 4
end

local function id(p14, p15, p16) -- line: 79
    -- upvalues: span (copy)
    local v13

    if p16 == 1 then
        v13 = span(p14, p15, 1)[1]
    elseif p16 == 2 then
        local v14 = span(p14, p15, 2)

        v13 = v14[2] * 256 + v14[1]
    else
        error(("Unsupported RWCM ID width %*"):format(p16), 0)
    end

    return v13, p15 + p16
end

t1.id = id

local mesh_clusters, decode_cluster

local function sim_data_index(p17) -- line: 100
    -- upvalues: sim (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local maps = sim_data and sim_data:FindFirstChild("maps")
    local v15 = maps and maps:FindFirstChild(p17)

    if not v15 then
        error(("sim_data: no exported map \"%*\" (run tools/export_collision.py and install roblox/sim_data)"):format(p17), 0)
    end

    if not v15:IsA("ModuleScript") then
        v15 = v15:FindFirstChild("init") or v15:FindFirstChild("index")

        if not v15 then
            error(("sim_data: map \"%*\" has no index module"):format(p17), 0)
        end
    end

    return require(v15)
end

local t2 = {}

function t1.release(p18) -- line: 123
    -- upvalues: t2 (copy)
    if p18 ~= nil then
        t2[p18] = nil
    else
        table.clear(t2)
    end
end

function t1.load(p19) -- line: 134
    -- upvalues: sim_data_index (copy), t2 (copy)
    local v17 = t2[p19]

    if v17 then
        return v17
    end

    local v18 = sim_data_index(p19)
    local rwcm_meshes = v18.records("rwcm_meshes")
    local rwcm_cluster_sizes = v18.stream("rwcm_cluster_sizes")
    local rwcm_points = v18.stream("rwcm_points")
    local rwcm_edges = v18.stream("rwcm_edges")
    local rwcm_surface = v18.stream("rwcm_surface")
    local rwcm_group = v18.stream("rwcm_group")
    local rwcm_one_sided = v18.stream("rwcm_one_sided")
    local v19 = table.create(v18.cluster_count)
    local n1 = 0
    local n2 = 0

    for _, v20 in rwcm_meshes do
        for _ = 1, v20.clusters do
            local v22 = buffer.readu16(rwcm_cluster_sizes, n1 * 2)

            n1 += 1

            local v23 = table.create(v22)

            for i = 1, v22 do
                local v24 = n2 * 36
                local v25 = n2 * 4

                v23[i] = {
                    points = {
                        {
                            buffer.readf32(rwcm_points, v24),
                            buffer.readf32(rwcm_points, v24 + 4),
                            (buffer.readf32(rwcm_points, v24 + 8))
                        },
                        {
                            buffer.readf32(rwcm_points, v24 + 12),
                            buffer.readf32(rwcm_points, v24 + 16),
                            (buffer.readf32(rwcm_points, v24 + 20))
                        },
                        {
                            buffer.readf32(rwcm_points, v24 + 24),
                            buffer.readf32(rwcm_points, v24 + 28),
                            (buffer.readf32(rwcm_points, v24 + 32))
                        }
                    },
                    edges = if buffer.readu8(rwcm_edges, v25 + 3) == 0 then nil else {
                        buffer.readu8(rwcm_edges, v25),
                        buffer.readu8(rwcm_edges, v25 + 1),
                        (buffer.readu8(rwcm_edges, v25 + 2))
                    },
                    surface = buffer.readu16(rwcm_surface, n2 * 2),
                    group = buffer.readu16(rwcm_group, n2 * 2),
                    one_sided = buffer.readu8(rwcm_one_sided, n2) ~= 0
                }
                n2 += 1
            end

            table.insert(v19, {
                name = v20.name,
                triangles = v23
            })
        end
    end

    if n2 ~= v18.triangle_count then
        error("RWCM triangle count mismatch", 0)
    end

    t2[p19] = v19

    return v19
end

function t1.visit_clusters_loaded(p20, p21) -- line: 184
    -- upvalues: t1 (copy)
    local n3 = 0

    for _, v47 in t1.load(p20) do
        n3 += #v47.triangles
        p21(v47.name, v47.triangles)
    end

    return n3
end

function t1.visit_clusters(p22, p23) -- line: 200
    -- upvalues: rt (copy), t1 (copy), span (copy), mesh_clusters (ref)
    if p22.sim_data_map ~= nil then
        return t1.visit_clusters_loaded(p22.sim_data_map, p23)
    end

    if #p22 < 8 then
        error(`Truncated RWCM at {0} (need {8})`, 0)
    end

    local v48 = table.create(8)

    table.move(p22, 1, 8, 1, v48)

    local t7 = {
        82, 87, 67, 77, 83, 69, 84, 49
    }

    for i = 1, 8 do
        if v48[i] ~= t7[i] then
            error("Invalid RWCMSET1 magic", 0)
        end
    end

    if 8 + 4 > #p22 then
        error(`Truncated RWCM at {8} (need {4})`, 0)
    end

    local v49 = table.create(4)

    table.move(p22, 8 + 1, 8 + 4, 1, v49)

    local v50 = ((v49[4] * 256 + v49[3]) * 256 + v49[2]) * 256 + v49[1]
    local v51 = 8 + 4

    if v50 == 0 or rt.idiv(#p22, 105) < v50 then
        error("Invalid RWCM mesh count", 0)
    end

    local v52 = v50 - 1
    local n4 = 0

    for _ = 0, v52 do
        if v51 + 4 > #p22 then
            error(("Truncated RWCM at %* (need %*)"):format(v51, 4), 0)
        end

        local v53 = table.create(4)

        table.move(p22, v51 + 1, v51 + 4, 1, v53)

        local v54 = ((v53[4] * 256 + v53[3]) * 256 + v53[2]) * 256 + v53[1]
        local v55 = v51 + 4

        if v54 == 0 or v54 > 4096 then
            error("Invalid RWCM mesh name length", 0)
        end

        local v56 = span(p22, v55, v54)
        local v57 = buffer.create(v54)

        for i = 1, v54 do
            local v58 = v56[i]

            buffer.writeu8(v57, i - 1, v58)
        end

        local v59 = buffer.tostring(v57)

        if utf8.len(v59) == nil then
            error("Invalid RWCM mesh name", 0)
        end

        local v60 = v55 + v54

        if v60 + 4 > #p22 then
            error(("Truncated RWCM at %* (need %*)"):format(v60, 4), 0)
        end

        local v61 = table.create(4)

        table.move(p22, v60 + 1, v60 + 4, 1, v61)

        local v62 = ((v61[4] * 256 + v61[3]) * 256 + v61[2]) * 256 + v61[1]
        local v63 = v60 + 4
        local v64 = span(p22, v63, v62)

        v51 = v63 + v62

        local mesh_clusters2 = mesh_clusters

        local function v65(p24) -- line: 237
            -- upvalues: p23 (copy), v59 (copy)
            p23(v59, p24)
        end

        local ok, result = pcall(mesh_clusters2, v64, v65)

        if not ok then
            error(("RWCM mesh \"%*\": %*"):format(v59, result), 0)
        end

        n4 += result
    end

    if v51 ~= #p22 then
        error("RWCM archive has trailing bytes", 0)
    end

    return n4
end

function mesh_clusters(p25, p26) -- line: 251
    -- upvalues: rt (copy), v1 (copy), span (copy), decode_cluster (ref)
    if #p25 < 96 then
        error(`Truncated RWCM at {0} (need {96})`, 0)
    end

    local v66 = table.create(96)

    table.move(p25, 1, 96, 1, v66)

    if #p25 < 84 then
        error(`Truncated RWCM at {80} (need {4})`, 0)
    end

    local v67 = table.create(4)

    table.move(p25, 81, 84, 1, v67)

    local v68 = ((v67[1] * 256 + v67[2]) * 256 + v67[3]) * 256 + v67[4]

    if v68 < 96 or #p25 < v68 then
        error("Invalid RWCM mesh size", 0)
    end

    local v69 = rt.slice(p25, 0, v68)

    if #v69 < 56 then
        error(`Truncated RWCM at {52} (need {4})`, 0)
    end

    local v70 = table.create(4)

    table.move(v69, 53, 56, 1, v70)

    local v71 = ((v70[1] * 256 + v70[2]) * 256 + v70[3]) * 256 + v70[4]

    if #v69 < 68 then
        error(`Truncated RWCM at {64} (need {4})`, 0)
    end

    local v72 = table.create(4)

    table.move(v69, 65, 68, 1, v72)

    local v73 = ((v72[1] * 256 + v72[2]) * 256 + v72[3]) * 256 + v72[4]

    if #v69 < 60 then
        error(`Truncated RWCM at {56} (need {4})`, 0)
    end

    local v74 = table.create(4)

    table.move(v69, 57, 60, 1, v74)
    buffer.writeu32(v1, 0, ((v74[1] * 256 + v74[2]) * 256 + v74[3]) * 256 + v74[4])

    local v76 = buffer.readf32(v1, 0)

    if not (v76 == v76 and v76 ~= 1e999 and v76 ~= (-1e999)) or v76 <= 0 then
        error("Invalid RWCM granularity", 0)
    end

    if v71 < 96 or v73 == 0 or rt.idiv(#v69, 4) < v73 then
        error("Invalid RWCM cluster table", 0)
    end

    span(v69, v71, v73 * 4)

    if #v69 < 62 then
        error(`Truncated RWCM at {60} (need {2})`, 0)
    end

    local v77 = table.create(2)

    table.move(v69, 61, 62, 1, v77)

    local v79 = bit32.band(v77[1] * 256 + v77[2], 16) ~= 0
    local v80 = v71 + v73 * 4
    local v81 = v73 - 1
    local n5 = 0

    for i = 0, v81 do
        local v82 = v71 + i * 4

        if v82 + 4 > #v69 then
            error(("Truncated RWCM at %* (need %*)"):format(v82, 4), 0)
        end

        local v83 = table.create(4)

        table.move(v69, v82 + 1, v82 + 4, 1, v83)

        local v84 = ((v83[1] * 256 + v83[2]) * 256 + v83[3]) * 256 + v83[4]

        if v84 < v80 then
            error("Overlapping RWCM clusters", 0)
        end

        local v85 = v84 + 8

        if v85 + 2 > #v69 then
            error(("Truncated RWCM at %* (need %*)"):format(v85, 2), 0)
        end

        local v86 = table.create(2)

        table.move(v69, v85 + 1, v85 + 2, 1, v86)

        local v87 = v86[1] * 256 + v86[2]

        if v87 < 16 then
            error("Invalid RWCM cluster size", 0)
        end

        local v88 = span(v69, v84, v87)

        v80 = v84 + v87

        local v89 = decode_cluster(v88, v76, v69[63], v69[64], v79)

        n5 += #v89
        p26(v89)
    end

    if #v69 < 44 then
        error(`Truncated RWCM at {40} (need {4})`, 0)
    end

    local v90 = table.create(4)

    table.move(v69, 41, 44, 1, v90)

    if n5 ~= ((v90[1] * 256 + v90[2]) * 256 + v90[3]) * 256 + v90[4] then
        error("RWCM triangle count mismatch", 0)
    end

    return n5
end

t1.mesh_clusters = mesh_clusters

function decode_cluster(p27, p28, p29, p30, p31) -- line: 293
    -- upvalues: rt (copy), v1 (copy), span (copy), id (copy)
    if #p27 < 2 then
        error(`Truncated RWCM at {0} (need {2})`, 0)
    end

    local v91 = table.create(2)

    table.move(p27, 1, 2, 1, v91)

    local v92 = v91[1] * 256 + v91[2]

    if #p27 < 6 then
        error(`Truncated RWCM at {4} (need {2})`, 0)
    end

    local v93 = table.create(2)

    table.move(p27, 5, 6, 1, v93)

    local v94 = (v93[1] * 256 + v93[2] + 1) * 16

    if #p27 < 4 then
        error(`Truncated RWCM at {2} (need {2})`, 0)
    end

    local v95 = table.create(2)

    table.move(p27, 3, 4, 1, v95)

    local v96 = span(p27, v94, v95[1] * 256 + v95[2])

    if v94 + 0 > #p27 then
        error(("Truncated RWCM at %* (need %*)"):format(0, v94), 0)
    end

    local v97 = table.create(v94)

    table.move(p27, 1, v94 + 0, 1, v97)

    local v98 = table.create(p27[11])

    for i = 0, p27[11] - 1 do
        local t8 = {
            0, 0, 0
        }

        for j = 0, 2 do
            local v99 = p27[13]

            if v99 == 0 then
                local v100 = j + 1
                local v101 = i * 16 + 16 + j * 4

                if v101 + 4 > #v97 then
                    error(("Truncated RWCM at %* (need %*)"):format(v101, 4), 0)
                end

                local v102 = table.create(4)

                table.move(v97, v101 + 1, v101 + 4, 1, v102)
                buffer.writeu32(v1, 0, ((v102[1] * 256 + v102[2]) * 256 + v102[3]) * 256 + v102[4])
                t8[v100] = buffer.readf32(v1, 0)
            elseif v99 == 1 then
                local to_i32 = rt.to_i32
                local v104 = j * 4 + 16

                if v104 + 4 > #v97 then
                    error(("Truncated RWCM at %* (need %*)"):format(v104, 4), 0)
                end

                local v105 = table.create(4)

                table.move(v97, v104 + 1, v104 + 4, 1, v105)

                local v106 = to_i32(((v105[1] * 256 + v105[2]) * 256 + v105[3]) * 256 + v105[4])
                local v107 = i * 6 + 28 + j * 2

                if v107 + 2 > #v97 then
                    error(("Truncated RWCM at %* (need %*)"):format(v107, 2), 0)
                end

                local v108 = table.create(2)

                table.move(v97, v107 + 1, v107 + 2, 1, v108)

                local v110 = math.clamp(v106 + (v108[1] * 256 + v108[2]), -2147483648, 2147483647)
                local v111 = j + 1
                local v112

                if v110 ~= 0 and v110 > -1.1754943508222875E-38 and v110 < 1.1754943508222875E-38 then
                    local v113 = math.abs(v110) * 7.1362384635298E+44
                    local v114 = math.floor(v113)
                    local v115 = v113 - v114

                    v112 = (if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114) * 1.401298464324817E-45

                    if v110 < 0 then
                        v112 = -v112
                    end
                else
                    buffer.writef32(v1, 0, v110)
                    v112 = buffer.readf32(v1, 0)
                end

                local v116 = v112 * p28
                local v117

                if v116 ~= 0 and v116 > -1.1754943508222875E-38 and v116 < 1.1754943508222875E-38 then
                    local v118 = math.abs(v116) * 7.1362384635298E+44
                    local v119 = math.floor(v118)
                    local v120 = v118 - v119

                    v117 = (if v120 > 0.5 or v120 == 0.5 and v119 % 2 == 1 then v119 + 1 else v119) * 1.401298464324817E-45

                    if v116 < 0 then
                        v117 = -v117
                    end
                else
                    buffer.writef32(v1, 0, v116)
                    v117 = buffer.readf32(v1, 0)
                end

                t8[v111] = v117
            elseif v99 == 2 then
                local v121 = j + 1
                local to_i32 = rt.to_i32
                local v122 = i * 12 + 16 + j * 4

                if v122 + 4 > #v97 then
                    error(("Truncated RWCM at %* (need %*)"):format(v122, 4), 0)
                end

                local v123 = table.create(4)

                table.move(v97, v122 + 1, v122 + 4, 1, v123)

                local v124 = to_i32(((v123[1] * 256 + v123[2]) * 256 + v123[3]) * 256 + v123[4])
                local v125

                if v124 ~= 0 and v124 > -1.1754943508222875E-38 and v124 < 1.1754943508222875E-38 then
                    local v126 = math.abs(v124) * 7.1362384635298E+44
                    local v127 = math.floor(v126)
                    local v128 = v126 - v127

                    v125 = (if v128 > 0.5 or v128 == 0.5 and v127 % 2 == 1 then v127 + 1 else v127) * 1.401298464324817E-45

                    if v124 < 0 then
                        v125 = -v125
                    end
                else
                    buffer.writef32(v1, 0, v124)
                    v125 = buffer.readf32(v1, 0)
                end

                local v129 = v125 * p28
                local v130

                if v129 ~= 0 and v129 > -1.1754943508222875E-38 and v129 < 1.1754943508222875E-38 then
                    local v131 = math.abs(v129) * 7.1362384635298E+44
                    local v132 = math.floor(v131)
                    local v133 = v131 - v132

                    v130 = (if v133 > 0.5 or v133 == 0.5 and v132 % 2 == 1 then v132 + 1 else v132) * 1.401298464324817E-45

                    if v129 < 0 then
                        v130 = -v130
                    end
                else
                    buffer.writef32(v1, 0, v129)
                    v130 = buffer.readf32(v1, 0)
                end

                t8[v121] = v130
            else
                error(("Unsupported RWCM vertex compression %*"):format(v99), 0)
            end

            local v134 = t8[j + 1]

            if v134 ~= v134 or v134 == 1e999 or v134 == (-1e999) then
                error("Non-finite RWCM vertex", 0)
            end
        end

        table.insert(v98, t8)
    end

    local t9 = {}
    local v135 = v92 - 1
    local n6 = 0

    for _ = 0, v135 do
        if n6 + 1 > #v96 then
            error(("Truncated RWCM at %* (need %*)"):format(n6, 1), 0)
        end

        local v136 = table.create(1)

        table.move(v96, n6 + 1, n6 + 1, 1, v136)

        local v137 = v136[1]
        local v138 = n6 + 1

        if bit32.band(v137, 15) ~= 1 then
            error(("Unsupported RWCM unit type %*; triangle units are required"):format((bit32.band(v137, 15))), 0)
        end

        if v138 + 3 > #v96 then
            error(("Truncated RWCM at %* (need %*)"):format(v138, 3), 0)
        end

        local v139 = table.create(3)

        table.move(v96, v138 + 1, v138 + 3, 1, v139)

        local v140 = v138 + 3
        local t10 = {
            { 0, 0, 0 },
            { 0, 0, 0 },
            { 0, 0, 0 }
        }

        for i = 0, 2 do
            local v141 = v98[v139[i + 1] + 1]

            if v141 == nil then
                error("RWCM missing vertex", 0)
            end

            t10[i + 1] = rt.copy(v141)
        end

        local v142, v143

        if bit32.band(v137, 32) == 0 then
            v143 = v140
        else
            if v140 + 3 > #v96 then
                error(("Truncated RWCM at %* (need %*)"):format(v140, 3), 0)
            end

            v142 = table.create(3)
            table.move(v96, v140 + 1, v140 + 3, 1, v142)
            v143 = v140 + 3
        end

        local v144

        if bit32.band(v137, 64) == 0 then
            n6 = v143
            v144 = 0
        else
            v144, n6 = id(v96, v143, p29)
        end

        local v145

        if bit32.band(v137, 128) == 0 then
            v145 = 0
        else
            v145, n6 = id(v96, n6, p30)
        end

        table.insert(t9, {
            points = t10,
            edges = v142,
            surface = v145,
            group = v144,
            one_sided = p31
        })
    end

    if n6 ~= #v96 then
        error("RWCM unit stream has trailing bytes", 0)
    end

    return t9
end

t1.decode_cluster = decode_cluster

return t1
