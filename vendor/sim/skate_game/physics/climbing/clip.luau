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

require(sim.import)

local t1 = {}

local function glam_lerp(p2, p3, p4) -- line: 24
    local v1 = 1 - p4

    return {
        p2[1] * v1 + p3[1] * p4,
        p2[2] * v1 + p3[2] * p4,
        p2[3] * v1 + p3[3] * p4
    }
end

local function glam_quat_normalize(p5) -- line: 30
    local v3 = 1 / math.sqrt(p5[1] * p5[1] + p5[2] * p5[2] + p5[3] * p5[3] + p5[4] * p5[4])

    return {
        p5[1] * v3,
        p5[2] * v3,
        p5[3] * v3,
        p5[4] * v3
    }
end

local function glam_acos_approx(p6) -- line: 36
    local v4 = p6 >= 0
    local v5 = math.abs(p6)
    local v6 = 1 - v5

    if v6 < 0 then
        v6 = 0
    end

    local v7 = math.sqrt(v6)
    local v8 = (((((((v5 * -0.0012624911 + 0.00667009) * v5 - 0.017088126) * v5 + 0.03089188) * v5 - 0.050174303) * v5 + 0.08897899) * v5 - 0.2145988) * v5 + 1.5707963) * v7

    if v4 then
        return v8
    end

    return 3.141592653589793 - v8
end

local function glam_quat_slerp(p7, p8, p9) -- line: 60
    -- upvalues: rt (copy), glam_quat_normalize (copy)
    local v9 = p7[1] * p8[1] + p7[2] * p8[2] + p7[3] * p8[3] + p7[4] * p8[4]
    local v10 = p8[1]
    local v11 = p8[2]
    local v12 = p8[3]
    local v13 = p8[4]

    if v9 < 0 then
        v10 = -v10
        v11 = -v11
        v12 = -v12
        v13 = -v13
        v9 = -v9
    end

    if 1 - rt.F32_EPSILON < v9 then
        local v14 = 1 - p9

        return (glam_quat_normalize({
            p7[1] * v14 + v10 * p9,
            p7[2] * v14 + v11 * p9,
            p7[3] * v14 + v12 * p9,
            p7[4] * v14 + v13 * p9
        }))
    end

    local v15 = v9 >= 0
    local v16 = math.abs(v9)
    local v17 = 1 - v16

    if v17 < 0 then
        v17 = 0
    end

    local v18 = math.sqrt(v17)
    local v19 = (((((((v16 * -0.0012624911 + 0.00667009) * v16 - 0.017088126) * v16 + 0.03089188) * v16 - 0.050174303) * v16 + 0.08897899) * v16 - 0.2145988) * v16 + 1.5707963) * v18

    if not v15 then
        v19 = 3.141592653589793 - v19
    end

    local v21 = math.sin(v19 * (1 - p9))
    local v23 = math.sin(v19 * p9)
    local v24 = 1 / math.sin(v19)

    return {
        (p7[1] * v21 + v10 * v23) * v24,
        (p7[2] * v21 + v11 * v23) * v24,
        (p7[3] * v21 + v12 * v23) * v24,
        (p7[4] * v21 + v13 * v23) * v24
    }
end

local function glam_mat4_mul(p10, p11) -- line: 88
    local v25 = table.create(4)

    for i = 1, 4 do
        local v26 = p11[i]
        local v27 = v26[1]
        local v28 = v26[2]
        local v29 = v26[3]
        local v30 = v26[4]

        v25[i] = {
            p10[1][1] * v27 + p10[2][1] * v28 + p10[3][1] * v29 + p10[4][1] * v30,
            p10[1][2] * v27 + p10[2][2] * v28 + p10[3][2] * v29 + p10[4][2] * v30,
            p10[1][3] * v27 + p10[2][3] * v28 + p10[3][3] * v29 + p10[4][3] * v30,
            p10[1][4] * v27 + p10[2][4] * v28 + p10[3][4] * v29 + p10[4][4] * v30
        }
    end

    return v25
end

local function glam_transform_to_matrix(p12) -- line: 104
    local rotation = p12.rotation
    local v31 = rotation[1]
    local v32 = rotation[2]
    local v33 = rotation[3]
    local v34 = rotation[4]
    local v35 = v31 + v31
    local v36 = v32 + v32
    local v37 = v33 + v33
    local v38 = v31 * v35
    local v39 = v31 * v36
    local v40 = v31 * v37
    local v41 = v32 * v36
    local v42 = v32 * v37
    local v43 = v33 * v37
    local v44 = v34 * v35
    local v45 = v34 * v36
    local v46 = v34 * v37
    local v47 = p12.scale[1]
    local v48 = p12.scale[2]
    local v49 = p12.scale[3]
    local translation = p12.translation

    return {
        {
            (1 - (v41 + v43)) * v47,
            (v39 + v46) * v47,
            (v40 - v45) * v47,
            0 * v47
        },
        {
            (v39 - v46) * v48,
            (1 - (v38 + v43)) * v48,
            (v42 + v44) * v48,
            0 * v48
        },
        {
            (v40 + v45) * v49,
            (v42 - v44) * v49,
            (1 - (v38 + v41)) * v49,
            0 * v49
        },
        {
            translation[1],
            translation[2],
            translation[3],
            1
        }
    }
end

t1.File = {}
t1.Clip = {}

local Clip = t1.Clip

t1.Clips = {}

local decode

local function deserialize_file(p13) -- line: 147
    local function v50() -- line: 148
        -- upvalues: p13 (copy)
        return game:GetService("HttpService"):JSONDecode(p13)
    end

    local ok, result = pcall(v50)

    if not ok then
        error(tostring(result), 0)
    end

    if type(result) ~= "table" then
        error("invalid type: expected struct File", 0)
    end

    if type(result.version) ~= "number" then
        error("missing field `version`", 0)
    end

    if type(result.clips) ~= "table" then
        error("missing field `clips`", 0)
    end

    local t2 = {}

    for v51, v52 in ipairs(result.clips) do
        if type(v52) ~= "table" then
            error("invalid type: expected struct Clip", 0)
        end

        if type(v52.name) ~= "string" then
            error("missing field `name`", 0)
        end

        if type(v52.fps) ~= "number" then
            error("missing field `fps`", 0)
        end

        if type(v52.names) ~= "table" then
            error("missing field `names`", 0)
        end

        if type(v52.parents) ~= "table" then
            error("missing field `parents`", 0)
        end

        if type(v52.frames) ~= "table" then
            error("missing field `frames`", 0)
        end

        for _, v53 in ipairs(v52.names) do
            if type(v53) ~= "string" then
                error("invalid type: expected a string", 0)
            end
        end

        for _, v54 in ipairs(v52.parents) do
            if type(v54) ~= "number" then
                error("invalid type: expected i32", 0)
            end
        end

        for _, v55 in ipairs(v52.frames) do
            if type(v55) ~= "table" then
                error("invalid type: expected a sequence", 0)
            end

            for _, v56 in ipairs(v55) do
                if type(v56) ~= "table" or #v56 ~= 10 then
                    error("invalid length, expected an array of length 10", 0)
                end

                for _, v57 in ipairs(v56) do
                    if type(v57) ~= "number" then
                        error("invalid type: expected f32", 0)
                    end
                end
            end
        end

        t2[v51] = {
            name = v52.name,
            fps = v52.fps,
            names = v52.names,
            parents = v52.parents,
            frames = v52.frames
        }
    end

    return {
        version = result.version,
        clips = t2
    }
end

function t1.Clips.load(_, p15) -- line: 223
    -- upvalues: Clip (copy), deserialize_file (copy)
    if p15 == nil then
        return nil
    end

    local ok, result = pcall(deserialize_file, p15)

    if not ok then
        error(("Climbing clips: %*"):format(result), 0)
    end

    if result.version ~= 1 then
        error("Unsupported climbing clip version", 0)
    end

    for _, v58 in ipairs(result.clips) do
        Clip.validate(v58)
    end

    local function take(p16) -- line: 237
        -- upvalues: result (copy)
        for v59, v60 in ipairs(result.clips) do
            if v60.name == p16 then
                return table.remove(result.clips, v59)
            end
        end

        error(("Missing climbing clip %*"):format(p16), 0)
    end

    local reach = take("reach")
    local mantle = take("mantle")
    local v61 = #reach.names == #mantle.names and #reach.parents == #mantle.parents

    if v61 then
        for i = 1, #reach.names do
            if reach.names[i] ~= mantle.names[i] then
                v61 = false
                break
            end
        end
    end

    if v61 then
        for i = 1, #reach.parents do
            if reach.parents[i] ~= mantle.parents[i] then
                v61 = false
                break
            end
        end
    end

    if not v61 then
        error("Climbing clips must share a skeleton", 0)
    end

    return {
        reach = reach,
        mantle = mantle
    }
end

function t1.Clip.validate(p17) -- line: 271
    local fps = p17.fps
    local v62 = fps == fps and fps ~= 1e999 and fps ~= (-1e999) and p17.fps > 0 and p17.fps <= 240 and #p17.frames >= 2 and #p17.names ~= 0 and #p17.parents == #p17.names

    if v62 then
        for i = 0, #p17.parents - 1 do
            local v63 = p17.parents[i + 1]

            if not (v63 >= -1 and v63 < i) then
                v62 = false
                break
            end
        end
    end

    if v62 then
        for i = 0, #p17.names - 1 do
            local v64 = p17.names[i + 1]
            local v65 = false

            for j = 1, i do
                if p17.names[j] == v64 then
                    v65 = true
                    break
                end
            end

            if v65 then
                v62 = false
                break
            end
        end
    end

    if v62 then
        local v66 = v62

        for _, v67 in ipairs(p17.frames) do
            if #v67 ~= #p17.names then
                v62 = false
                break
            end

            for _, v68 in ipairs(v67) do
                local v69 = true

                for _, v70 in ipairs(v68) do
                    if v70 ~= v70 or v70 == 1e999 or v70 == (-1e999) then
                        v69 = false
                        break
                    end
                end

                if v69 and not (v68[1] > 1E-04 and v68[2] > 1E-04 and v68[3] > 1E-04) then
                    v69 = false
                end

                v69 = v69 and math.abs(math.sqrt(v68[4] * v68[4] + v68[5] * v68[5] + v68[6] * v68[6] + v68[7] * v68[7]) - 1) < 0.01

                if not v69 then
                    v66 = false
                    break
                end
            end

            if not v66 then
                v62 = v66
                break
            end

            v62 = v66
        end
    end

    if not v62 then
        error(("Invalid climbing clip %*"):format(p17.name), 0)
    end

    for _, v73 in ipairs({
            "HIPS",
            "SPINE3",
            "LEFTSHOULDER",
            "RIGHTSHOULDER",
            "LEFTARM",
            "RIGHTARM",
            "LEFTFOREARM",
            "RIGHTFOREARM",
            "LEFTHAND",
            "RIGHTHAND",
            "LEFTFOOT",
            "RIGHTFOOT",
            "SKATEBOARD_ROOT"
        }) do
        local v74 = false

        for _, v75 in ipairs(p17.names) do
            if v75 == v73 then
                v74 = true
                break
            end
        end

        if not v74 then
            error(("Missing climbing bone %*"):format(v73), 0)
        end
    end
end

function t1.Clip.duration(p18) -- line: 374
    return (#p18.frames - 1) / p18.fps
end

function t1.Clip.sample(p19, p20) -- line: 379
    -- upvalues: rt (copy), t1 (copy), decode (ref)
    local v76 = rt.clamp(p20 * p19.fps, 0, #p19.frames - 1)
    local v77 = rt.f_to_usize((math.floor(v76)))
    local v80 = math.min(v77 + 1, #p19.frames - 1)
    local v81 = p19.frames[v77 + 1]
    local v82 = p19.frames[v80 + 1]
    local t3 = {}

    for i = 1, math.min(#v81, #v82) do
        t3[i] = t1.blend(decode(v81[i]), decode(v82[i]), rt.fract(v76))
    end

    return t3
end

function t1.Clip.globals(p21, p22) -- line: 393
    -- upvalues: glam_mat4_mul (copy), glam_transform_to_matrix (copy)
    local v85 = table.create(#p22)

    for i = 0, #p22 - 1 do
        local v86 = glam_transform_to_matrix(p22[i + 1])

        if p21.parents[i + 1] < 0 then
            v85[i + 1] = v86
        else
            v85[i + 1] = glam_mat4_mul(v85[p21.parents[i + 1] + 1], v86)
        end
    end

    return v85
end

function t1.Clip.index(p23, p24) -- line: 407
    for v87, v88 in ipairs(p23.names) do
        if v88 == p24 then
            return v87 - 1
        end
    end

    error("called `Option::unwrap()` on a `None` value", 0)
end

function t1.Clip.hands(p25, p26) -- line: 417
    -- upvalues: Clip (copy)
    local v89 = p26[Clip.index(p25, "LEFTHAND") + 1][4]
    local v90 = p26[Clip.index(p25, "RIGHTHAND") + 1][4]

    return {
        (v89[1] + v90[1]) * 0.5,
        (v89[2] + v90[2]) * 0.5,
        (v89[3] + v90[3]) * 0.5
    }
end

function t1.Clip.feet(p27, p28) -- line: 424
    -- upvalues: Clip (copy)
    local v91 = p28[Clip.index(p27, "LEFTFOOT") + 1][4]
    local v92 = p28[Clip.index(p27, "RIGHTFOOT") + 1][4]

    return {
        (v91[1] + v92[1]) * 0.5 - 0,
        (v91[2] + v92[2]) * 0.5 - 0.11,
        (v91[3] + v92[3]) * 0.5 - 0
    }
end

function t1.decode(p29) -- line: 436
    -- upvalues: glam_quat_normalize (copy)
    return {
        scale = {
            p29[1],
            p29[2],
            p29[3]
        },
        rotation = glam_quat_normalize({
            p29[4],
            p29[5],
            p29[6],
            p29[7]
        }),
        translation = {
            p29[8],
            p29[9],
            p29[10]
        }
    }
end

decode = t1.decode

function t1.blend(p30, p31, p32) -- line: 446
    -- upvalues: glam_lerp (copy), glam_quat_slerp (copy)
    return {
        translation = glam_lerp(p30.translation, p31.translation, p32),
        rotation = glam_quat_slerp(p30.rotation, p31.rotation, p32),
        scale = glam_lerp(p30.scale, p31.scale, p32)
    }
end

return t1
