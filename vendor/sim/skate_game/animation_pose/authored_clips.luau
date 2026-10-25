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
local HttpService = game:GetService("HttpService")
local v9 = import("skate_core/animation/pose_add")
local AnimationFrames, ClipFrames = import("skate_data/animation_frames").AnimationFrames, import("skate_data/animation_frames").ClipFrames
local v10

local function super() -- line: 49
    -- upvalues: import (copy), v10 (ref)
    local v11 = v10

    if v11 == nil then
        v11 = import("skate_game/animation_pose")
        v10 = v11
    end

    return v11
end

local t1 = {}

local function glam_mat4_from_cols_array(p5) -- line: 61
    -- upvalues: rt (copy)
    local fround = rt.fround

    return {
        {
            fround(p5[1]),
            fround(p5[2]),
            fround(p5[3]),
            fround(p5[4])
        },
        {
            fround(p5[5]),
            fround(p5[6]),
            fround(p5[7]),
            fround(p5[8])
        },
        {
            fround(p5[9]),
            fround(p5[10]),
            fround(p5[11]),
            fround(p5[12])
        },
        {
            fround(p5[13]),
            fround(p5[14]),
            fround(p5[15]),
            fround(p5[16])
        }
    }
end

local function glam_mat4_identity() -- line: 71
    return {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 1 }
    }
end

local function glam_mat4_is_finite(p6) -- line: 81
    for i = 1, 4 do
        local v12 = p6[i][1]

        if v12 ~= v12 or v12 == 1e999 or v12 == (-1e999) then
            return false
        end

        local v13 = p6[i][2]

        if v13 ~= v13 or v13 == 1e999 or v13 == (-1e999) then
            return false
        end

        local v14 = p6[i][3]
        local v15, v16

        if v14 == v14 and v14 ~= 1e999 and v14 ~= (-1e999) then
            local v17 = p6[i][4]

            v15 = v17 == v17 and v17 ~= 1e999 and v17 ~= (-1e999)
            v16 = false
        else
            v16 = true
        end

        if v16 or not v15 then
            return false
        end
    end

    return true
end

local function glam_mat4_mul(p7, p8) -- line: 93
    local v18 = table.create(4)

    for i = 1, 4 do
        local v19 = p8[i]
        local v20 = v19[1]
        local v21 = v19[2]
        local v22 = v19[3]
        local v23 = v19[4]

        v18[i] = {
            p7[1][1] * v20 + p7[2][1] * v21 + p7[3][1] * v22 + p7[4][1] * v23,
            p7[1][2] * v20 + p7[2][2] * v21 + p7[3][2] * v22 + p7[4][2] * v23,
            p7[1][3] * v20 + p7[2][3] * v21 + p7[3][3] * v22 + p7[4][3] * v23,
            p7[1][4] * v20 + p7[2][4] * v21 + p7[3][4] * v22 + p7[4][4] * v23
        }
    end

    return v18
end

local function glam_mat4_inverse(p9) -- line: 110
    local v24 = p9[1][1]
    local v25 = p9[1][2]
    local v26 = p9[1][3]
    local v27 = p9[1][4]
    local v28 = p9[2][1]
    local v29 = p9[2][2]
    local v30 = p9[2][3]
    local v31 = p9[2][4]
    local v32 = p9[3][1]
    local v33 = p9[3][2]
    local v34 = p9[3][3]
    local v35 = p9[3][4]
    local v36 = p9[4][1]
    local v37 = p9[4][2]
    local v38 = p9[4][3]
    local v39 = p9[4][4]
    local v40 = v24 * v29 - v28 * v25
    local v41 = v24 * v30 - v28 * v26
    local v42 = v24 * v31 - v28 * v27
    local v43 = v25 * v30 - v29 * v26
    local v44 = v25 * v31 - v29 * v27
    local v45 = v26 * v31 - v30 * v27
    local v46 = v34 * v39 - v38 * v35
    local v47 = v33 * v39 - v37 * v35
    local v48 = v33 * v38 - v37 * v34
    local v49 = v32 * v39 - v36 * v35
    local v50 = v32 * v38 - v36 * v34
    local v51 = v32 * v37 - v36 * v33
    local v52 = v40 * v46 - v41 * v47 + v42 * v48 + v43 * v49 - v44 * v50 + v45 * v51
    local v53 = 1 / v52

    return {
        {
            (v29 * v46 - v30 * v47 + v31 * v48) * v53,
            (-v25 * v46 + v26 * v47 - v27 * v48) * v53,
            (v37 * v45 - v38 * v44 + v39 * v43) * v53,
            (-v33 * v45 + v34 * v44 - v35 * v43) * v53
        },
        {
            (-v28 * v46 + v30 * v49 - v31 * v50) * v53,
            (v24 * v46 - v26 * v49 + v27 * v50) * v53,
            (-v36 * v45 + v38 * v42 - v39 * v41) * v53,
            (v32 * v45 - v34 * v42 + v35 * v41) * v53
        },
        {
            (v28 * v47 - v29 * v49 + v31 * v51) * v53,
            (-v24 * v47 + v25 * v49 - v27 * v51) * v53,
            (v36 * v44 - v37 * v42 + v39 * v40) * v53,
            (-v32 * v44 + v33 * v42 - v35 * v40) * v53
        },
        {
            (-v28 * v48 + v29 * v50 - v30 * v51) * v53,
            (v24 * v48 - v25 * v50 + v26 * v51) * v53,
            (-v36 * v43 + v37 * v41 - v38 * v40) * v53,
            (v32 * v43 - v33 * v41 + v34 * v40) * v53
        }
    }, v52
end

local function glam_quat_from_rotation_axes(p10, p11, p12) -- line: 159
    local v54 = p10[1]
    local v55 = p10[2]
    local v56 = p10[3]
    local v57 = p11[1]
    local v58 = p11[2]
    local v59 = p11[3]
    local v60 = p12[1]
    local v61 = p12[2]
    local v62 = p12[3]

    if v62 <= 0 then
        local v63 = v58 - v54
        local v64 = 1 - v62

        if v63 <= 0 then
            local v65 = v64 - v63
            local v66 = 0.5 / math.sqrt(v65)

            return {
                v65 * v66,
                (v55 + v57) * v66,
                (v56 + v60) * v66,
                (v59 - v61) * v66
            }
        end

        local v67 = v64 + v63
        local v68 = 0.5 / math.sqrt(v67)

        return {
            (v55 + v57) * v68,
            v67 * v68,
            (v59 + v61) * v68,
            (v60 - v56) * v68
        }
    end

    local v69 = v58 + v54
    local v70 = 1 + v62

    if v69 <= 0 then
        local v71 = v70 - v69
        local v72 = 0.5 / math.sqrt(v71)

        return {
            (v56 + v60) * v72,
            (v59 + v61) * v72,
            v71 * v72,
            (v55 - v57) * v72
        }
    end

    local v73 = v70 + v69
    local v74 = 0.5 / math.sqrt(v73)

    return {
        (v59 - v61) * v74,
        (v60 - v56) * v74,
        (v55 - v57) * v74,
        v73 * v74
    }
end

local function glam_mat4_to_scale_rotation_translation(p13, p14) -- line: 198
    -- upvalues: rt (copy), glam_quat_from_rotation_axes (copy)
    local v75 = p13[1]
    local v76 = p13[2]
    local v77 = p13[3]
    local v79 = math.sqrt(v75[1] * v75[1] + v75[2] * v75[2] + v75[3] * v75[3] + v75[4] * v75[4]) * rt.signum(p14)
    local v81 = math.sqrt(v76[1] * v76[1] + v76[2] * v76[2] + v76[3] * v76[3] + v76[4] * v76[4])
    local v83 = math.sqrt(v77[1] * v77[1] + v77[2] * v77[2] + v77[3] * v77[3] + v77[4] * v77[4])
    local v84 = 1 / v79
    local v85 = 1 / v81
    local v86 = 1 / v83
    local v87 = glam_quat_from_rotation_axes({
        v75[1] * v84,
        v75[2] * v84,
        v75[3] * v84
    }, {
        v76[1] * v85,
        v76[2] * v85,
        v76[3] * v85
    }, {
        v77[1] * v86,
        v77[2] * v86,
        v77[3] * v86
    })

    return { v79, v81, v83 }, v87, {
        p13[4][1],
        p13[4][2],
        p13[4][3]
    }
end

local function glam_mat4_from_scale_rotation_translation(p15, p16, p17) -- line: 213
    local v88 = p16[1]
    local v89 = p16[2]
    local v90 = p16[3]
    local v91 = p16[4]
    local v92 = v88 + v88
    local v93 = v89 + v89
    local v94 = v90 + v90
    local v95 = v88 * v92
    local v96 = v88 * v93
    local v97 = v88 * v94
    local v98 = v89 * v93
    local v99 = v89 * v94
    local v100 = v90 * v94
    local v101 = v91 * v92
    local v102 = v91 * v93
    local v103 = v91 * v94
    local v104 = p15[1]
    local v105 = p15[2]
    local v106 = p15[3]

    return {
        {
            (1 - (v98 + v100)) * v104,
            (v96 + v103) * v104,
            (v97 - v102) * v104,
            0 * v104
        },
        {
            (v96 - v103) * v105,
            (1 - (v95 + v100)) * v105,
            (v99 + v101) * v105,
            0 * v105
        },
        {
            (v97 + v102) * v106,
            (v99 - v101) * v106,
            (1 - (v95 + v98)) * v106,
            0 * v106
        },
        {
            p17[1],
            p17[2],
            p17[3],
            1
        }
    }
end

local function glam_quat_mul(p18, p19) -- line: 237
    local v107 = p18[1]
    local v108 = p18[2]
    local v109 = p18[3]
    local v110 = p18[4]
    local v111 = p19[1]
    local v112 = p19[2]
    local v113 = p19[3]
    local v114 = p19[4]

    return {
        v110 * v111 + v107 * v114 + v108 * v113 - v109 * v112,
        v110 * v112 - v107 * v113 + v108 * v114 + v109 * v111,
        v110 * v113 + v107 * v112 - v108 * v111 + v109 * v114,
        v110 * v114 - v107 * v111 - v108 * v112 - v109 * v113
    }
end

local function glam_quat_mul_vec3(p20, p21) -- line: 249
    local v115 = p20[4]
    local v116 = p20[1]
    local v117 = p20[2]
    local v118 = p20[3]
    local v119 = v116 * v116 + v117 * v117 + v118 * v118
    local v120 = v115 * v115 - v119
    local v121 = (p21[1] * v116 + p21[2] * v117 + p21[3] * v118) * 2
    local v122 = v115 * 2

    return {
        p21[1] * v120 + v116 * v121 + (v117 * p21[3] - v118 * p21[2]) * v122,
        p21[2] * v120 + v117 * v121 + (v118 * p21[1] - v116 * p21[3]) * v122,
        p21[3] * v120 + v118 * v121 + (v116 * p21[2] - v117 * p21[1]) * v122
    }
end

local function glam_quat_normalize(p22) -- line: 264
    local v124 = 1 / math.sqrt(p22[1] * p22[1] + p22[2] * p22[2] + p22[3] * p22[3] + p22[4] * p22[4])

    return {
        p22[1] * v124,
        p22[2] * v124,
        p22[3] * v124,
        p22[4] * v124
    }
end

local function path_join(p23, p24) -- line: 270
    if p23 == nil or tostring(p23) == "" then
        return p24
    end

    local v125 = tostring(p23)
    local v126 = string.sub(v125, -1)

    if v126 == "/" or v126 == "\\" then
        return v125 .. p24
    end

    return v125 .. "/" .. p24
end

local function sorted_keys(p25) -- line: 283
    local t2 = {}

    for v127 in p25 do
        table.insert(t2, v127)
    end

    table.sort(t2)

    return t2
end

t1.Replacements = {}

local Replacements = t1.Replacements

function t1.Replacements.default() -- line: 297
    return { {} }
end

t1.File = {}
t1.AuthoredClip = {}

local function file_from_json(p26) -- line: 310
    -- upvalues: HttpService (copy)
    local function v128() -- line: 311
        -- upvalues: p26 (copy), HttpService (copy)
        return HttpService:JSONDecode(p26)
    end

    local ok, result = pcall(v128)

    if not ok then
        error(tostring(result), 0)
    end

    if type(result) ~= "table" then
        error("invalid type: expected struct File", 0)
    end

    for v129 in result do
        if v129 ~= "version" and v129 ~= "bone_names" and v129 ~= "clips" then
            error("unknown field `" .. tostring(v129) .. "`, expected one of `version`, `bone_names`, `clips`", 0)
        end
    end

    if type(result.version) ~= "number" then
        error("missing field `version`", 0)
    end

    if type(result.bone_names) ~= "table" then
        error("missing field `bone_names`", 0)
    end

    for _, v130 in ipairs(result.bone_names) do
        if type(v130) ~= "string" then
            error("invalid type: expected a string", 0)
        end
    end

    if type(result.clips) ~= "table" then
        error("missing field `clips`", 0)
    end

    local _ipairs = ipairs
    local clips2 = result.clips
    local t3 = {}

    for v131 in clips2 do
        table.insert(t3, v131)
    end

    table.sort(t3)

    for _, v132 in _ipairs(t3) do
        local v133 = result.clips[v132]

        if type(v133) ~= "table" then
            error("invalid type: expected struct AuthoredClip", 0)
        end

        for v134 in v133 do
            if v134 ~= "fps" and v134 ~= "frames" then
                error("unknown field `" .. tostring(v134) .. "`, expected `fps` or `frames`", 0)
            end
        end

        if type(v133.fps) ~= "number" then
            error("missing field `fps`", 0)
        end

        if type(v133.frames) ~= "table" then
            error("missing field `frames`", 0)
        end

        for _, v135 in ipairs(v133.frames) do
            if type(v135) ~= "table" then
                error("invalid type: expected a sequence", 0)
            end

            for _, v136 in ipairs(v135) do
                if type(v136) ~= "table" or #v136 ~= 16 then
                    error("invalid length, expected an array of length 16", 0)
                end

                for i = 1, 16 do
                    if type(v136[i]) ~= "number" then
                        error("invalid type: expected f32", 0)
                    end
                end
            end
        end
    end

    return result
end

function t1.Replacements.load(p27, p28, p29) -- line: 377
    -- upvalues: Replacements (copy)
    local v138

    if p27 == nil or tostring(p27) == "" then
        v138 = "private/custom/crouch-treflip.json"
    else
        local v139 = tostring(p27)
        local v140 = string.sub(v139, -1)

        v138 = if v140 == "/" or v140 == "\\" then v139 .. "private/custom/crouch-treflip.json" else v139 .. "/" .. "private/custom/crouch-treflip.json"
    end

    if p29 == nil then
        return Replacements.default()
    end

    local parse = Replacements.parse
    local ok, result = pcall(parse, p29, p28)

    if not ok then
        error(v138 .. ": " .. tostring(result), 0)
    end

    return result
end

function t1.Replacements.parse(p30, p31) -- line: 390
    -- upvalues: rt (copy), v1 (copy), import (copy), v9 (copy), AnimationFrames (copy), ClipFrames (copy), v10 (ref), t1 (copy), glam_mat4_from_cols_array (copy), glam_mat4_identity (copy), glam_mat4_is_finite (copy), glam_mat4_mul (copy), glam_mat4_inverse (copy), glam_mat4_to_scale_rotation_translation (copy), file_from_json (copy)
    local v141 = file_from_json(p30)
    local clips = v141.clips
    local t4 = {}

    for v142 in clips do
        table.insert(t4, v142)
    end

    table.sort(t4)

    local v143 = #v141.bone_names == #p31.bone_names

    if v143 then
        for v144, v145 in ipairs(p31.bone_names) do
            if v141.bone_names[v144] ~= v145 then
                v143 = false
                break
            end
        end
    end

    if v141.version ~= 1 or not v143 or #t4 > 32 then
        error("Authored clip format or skeleton mismatch", 0)
    end

    local v146 = v10

    if v146 == nil then
        v146 = import("skate_game/animation_pose")
        v10 = v146
    end

    local sqt = v146.sqt
    local samples = AnimationFrames.named_pose(p31, "RIG_TPOSE").samples

    local function index(p32) -- line: 408
        -- upvalues: p31 (copy)
        for v147, v148 in ipairs(p31.bone_names) do
            if v148 == p32 then
                return v147 - 1
            end
        end

        error("Missing " .. p32, 0)
    end

    local v149 = false
    local v150

    for v151, v152 in ipairs(p31.bone_names) do
        if v152 == "HIPS" then
            v150 = v151 - 1
            v149 = true
            break
        end
    end

    if not v149 then
        v150 = nil
        error("Missing HIPS", 0)
    end

    local v153 = false
    local v154

    for v155, v156 in ipairs(p31.bone_names) do
        if v156 == "SKATEBOARD_ROOT" then
            v154 = v155 - 1
            v153 = true
            break
        end
    end

    if not v153 then
        v154 = nil
        error("Missing SKATEBOARD_ROOT", 0)
    end

    local t5 = {}
    local v157 = false
    local v158

    for v159, v160 in ipairs(p31.bone_names) do
        if v160 == "RIGHTTOEBASE_REPARENTED" then
            v158 = v159 - 1
            v157 = true
            break
        end
    end

    if not v157 then
        v158 = nil
        error("Missing RIGHTTOEBASE_REPARENTED", 0)
    end

    t5[1] = {
        v158,
        index("RIGHTTOEBASE")
    }

    local v161 = false
    local v162

    for v163, v164 in ipairs(p31.bone_names) do
        if v164 == "LEFTTOEBASE_REPARENTED" then
            v162 = v163 - 1
            v161 = true
            break
        end
    end

    if not v161 then
        v162 = nil
        error("Missing LEFTTOEBASE_REPARENTED", 0)
    end

    t5[2] = {
        v162,
        index("LEFTTOEBASE")
    }

    local v165 = false
    local v166

    for v167, v168 in ipairs(p31.bone_names) do
        if v168 == "RIGHTHAND_REPARENTED" then
            v166 = v167 - 1
            v165 = true
            break
        end
    end

    if not v165 then
        v166 = nil
        error("Missing RIGHTHAND_REPARENTED", 0)
    end

    t5[3] = {
        v166,
        index("RIGHTHAND")
    }

    local v169 = false
    local v170

    for v171, v172 in ipairs(p31.bone_names) do
        if v172 == "LEFTHAND_REPARENTED" then
            v170 = v171 - 1
            v169 = true
            break
        end
    end

    if not v169 then
        v170 = nil
        error("Missing LEFTHAND_REPARENTED", 0)
    end

    t5[4] = {
        v170,
        index("LEFTHAND")
    }

    local v173 = t5[1][1]

    if t5[2][1] < v173 then
        v173 = t5[2][1]
    end

    if t5[3][1] < v173 then
        v173 = t5[3][1]
    end

    if t5[4][1] < v173 then
        v173 = t5[4][1]
    end

    local t6 = {}

    for _, v174 in ipairs(t4) do
        local v175 = v141.clips[v174]

        if v174 ~= "R_ANTIC_OLLIE_N_0_INTO" and v174 ~= "R_ANTIC_OLLIE_N_0_CYC" and v174 ~= "R_ANTIC_360SHUVIT_N_0_CYC" and v174 ~= "360FLIP_D_HIGH_G" and v174 ~= "360FLIP_D_HIGH_A" and v174 ~= "360FLIP_D_LOW_G" and v174 ~= "360FLIP_D_LOW_A" then
            error("Unsupported authored slot " .. v174, 0)
        end

        local v176 = AnimationFrames.clip(p31, v174)
        local fps = v175.fps
        local v177

        if fps == 0 then
            buffer.writef32(v1, 0, fps)
            v177 = buffer.readf32(v1, 0)
        elseif fps > -1.1754943508222875E-38 and fps < 1.1754943508222875E-38 then
            local v178 = math.abs(fps) * 7.1362384635298E+44
            local v179 = math.floor(v178)
            local v180 = v178 - v179

            if v180 > 0.5 or v180 == 0.5 and v179 % 2 == 1 then
                v179 += 1
            end

            v177 = v179 * 1.401298464324817E-45

            if fps < 0 then
                v177 = -v177
            end
        else
            buffer.writef32(v1, 0, fps)
            v177 = buffer.readf32(v1, 0)
        end

        buffer.writeu32(v1, 0, v176.fps_bits)

        if v177 ~= buffer.readf32(v1, 0) or #v175.frames ~= ClipFrames.frame_count(v176) then
            error(v174 .. ": timing differs from stock slot", 0)
        end

        local v181 = ClipFrames.frames_table(v176)

        for i = 1, math.min(#v181, #v175.frames) do
            local v184 = v181[i]
            local v185 = v175.frames[i]

            if #v185 ~= #p31.bone_names then
                error(v174 .. ": missing bones", 0)
            end

            local v186 = table.create(#v185)

            for _, v187 in ipairs(v185) do
                local v188 = glam_mat4_from_cols_array(v187)
                local _, v189 = glam_mat4_inverse(v188)
                local v190, v191 = glam_mat4_to_scale_rotation_translation(v188, v189)

                if not glam_mat4_is_finite(v188) or v189 <= 0 or rt.fmin(rt.fmin(v190[1], v190[2]), v190[3]) < 0.9 or rt.fmax(rt.fmax(v190[1], v190[2]), v190[3]) > 1.1 then
                    error(v174 .. ": invalid joint matrix", 0)
                else
                    local v192 = v191[1]

                    if v192 == v192 and v192 ~= 1e999 and v192 ~= (-1e999) then
                        local v193 = v191[2]

                        if v193 == v193 and v193 ~= 1e999 and v193 ~= (-1e999) then
                            local v194 = v191[3]

                            if v194 == v194 and v194 ~= 1e999 and v194 ~= (-1e999) then
                                local v195 = v191[4]

                                if v195 ~= v195 or v195 == 1e999 or v195 == (-1e999) or math.abs(v188[4][4] - 1) > 0.001 or math.abs(v188[1][4]) + math.abs(v188[2][4]) + math.abs(v188[3][4]) > 0.001 then
                                    error(v174 .. ": invalid joint matrix", 0)
                                end
                            else
                                error(v174 .. ": invalid joint matrix", 0)
                            end
                        else
                            error(v174 .. ": invalid joint matrix", 0)
                        end
                    else
                        error(v174 .. ": invalid joint matrix", 0)
                    end
                end

                table.insert(v186, v188)
            end

            local v202 = table.create(#v184)

            for j = 1, #v184 do
                v202[j] = glam_mat4_identity()
            end

            for k = 1, #v184 - 1 do
                local v203 = p31.parents[k + 1]
                local v204 = t1.matrix(v9.add(sqt(v184[k + 1]), sqt(samples[k + 1]), true))

                if v203 > 0 then
                    v202[k + 1] = glam_mat4_mul(v202[v203 + 1], v204)
                else
                    v202[k + 1] = v204
                end
            end

            for n = v154, v173 - 1 do
                v186[n + 1] = rt.copy(v202[n + 1])
            end

            for _, v205 in ipairs(t5) do
                local v206 = v205[1]
                local v207 = v205[2]

                v186[v206 + 1] = rt.copy(v186[v207 + 1])
            end

            local t7 = {}

            for n2 = v150, v154 - 1 do
                table.insert(t7, n2)
            end

            for _, v208 in ipairs(t5) do
                table.insert(t7, v208[1])
            end

            for _, v210 in ipairs(t7) do
                local v211 = p31.parents[v210 + 1]
                local v212 = if v211 > 0 then glam_mat4_mul(glam_mat4_inverse(v186[v211 + 1]), v186[v210 + 1]) else v186[v210 + 1]

                v184[v210 + 1] = t1.words(t1.remove_reference(v212, sqt(samples[v210 + 1])))
            end
        end

        t6[v174] = {
            name = v174,
            source_offset = v176.source_offset,
            fps_bits = v176.fps_bits,
            loop_translation_bits = rt.copy(v176.loop_translation_bits),
            loop_rotation_bits = rt.copy(v176.loop_rotation_bits),
            channel_animation = v176.channel_animation,
            channel_weights = rt.copy(v176.channel_weights),
            frames = v181
        }
    end

    return { t6 }
end

function t1.Replacements.clip(p33, p34) -- line: 543
    return p33[1][p34]
end

function t1.matrix(p35) -- line: 548
    -- upvalues: glam_mat4_from_scale_rotation_translation (copy)
    return (glam_mat4_from_scale_rotation_translation({
        p35.scale[1],
        p35.scale[2],
        p35.scale[3]
    }, {
        p35.rotation[1],
        p35.rotation[2],
        p35.rotation[3],
        p35.rotation[4]
    }, {
        p35.translation[1],
        p35.translation[2],
        p35.translation[3]
    }))
end

function t1.remove_reference(p36, p37) -- line: 557
    -- upvalues: glam_mat4_inverse (copy), glam_mat4_to_scale_rotation_translation (copy), glam_quat_mul (copy), glam_quat_mul_vec3 (copy), glam_quat_normalize (copy)
    local _, v214 = glam_mat4_inverse(p36)
    local v215, v216, v217 = glam_mat4_to_scale_rotation_translation(p36, v214)
    local rotation = p37.rotation
    local t8 = {
        -rotation[1],
        -rotation[2],
        -rotation[3],
        rotation[4]
    }
    local t9 = {
        v215[1] / p37.scale[1],
        v215[2] / p37.scale[2],
        v215[3] / p37.scale[3]
    }
    local v218 = glam_quat_mul_vec3(t8, {
        v217[1] - p37.translation[1],
        v217[2] - p37.translation[2],
        v217[3] - p37.translation[3]
    })

    return {
        scale = {
            t9[1],
            t9[2],
            t9[3],
            1
        },
        rotation = glam_quat_normalize((glam_quat_mul(t8, v216))),
        translation = {
            v218[1],
            v218[2],
            v218[3],
            1
        }
    }
end

function t1.words(p38) -- line: 578
    -- upvalues: rt (copy)
    local to_bits = rt.to_bits

    return {
        to_bits(p38.scale[1]),
        to_bits(p38.scale[2]),
        to_bits(p38.scale[3]),
        to_bits(p38.rotation[1]),
        to_bits(p38.rotation[2]),
        to_bits(p38.rotation[3]),
        to_bits(p38.rotation[4]),
        to_bits(p38.translation[1]),
        to_bits(p38.translation[2]),
        to_bits(p38.translation[3])
    }
end

return t1
