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

local import = require(sim.import)

local function presentation() -- line: 22
    -- upvalues: import (copy)
    return import("skate_game/presentation")
end

local function input_mod() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/input")
end

local function graphics_menu() -- line: 29
    -- upvalues: import (copy)
    return import("skate_game/graphics_menu")
end

local function multiplayer() -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/multiplayer")
end

local t1 = {
    WINDOW = 30,
    SELECT = 32,
    A = 4096,
    B = 8192,
    Y = 32768
}
local WINDOW, SELECT, A, B = t1.WINDOW, t1.SELECT, t1.A, t1.B
local Y = t1.Y

local function glam_quat_mul(p2, p3) -- line: 50
    local v1 = p2[1]
    local v2 = p2[2]
    local v3 = p2[3]
    local v4 = p2[4]
    local v5 = p3[1]
    local v6 = p3[2]
    local v7 = p3[3]
    local v8 = p3[4]

    return {
        v4 * v5 + v1 * v8 + v2 * v7 - v3 * v6,
        v4 * v6 - v1 * v7 + v2 * v8 + v3 * v5,
        v4 * v7 + v1 * v6 - v2 * v5 + v3 * v8,
        v4 * v8 - v1 * v5 - v2 * v6 - v3 * v7
    }
end

local function glam_quat_from_rotation_y(p4) -- line: 62
    return {
        0,
        math.sin(p4 * 0.5),
        0,
        (math.cos(p4 * 0.5))
    }
end

local function glam_quat_from_rotation_x(p5) -- line: 67
    return {
        math.sin(p5 * 0.5),
        0, 0,
        (math.cos(p5 * 0.5))
    }
end

local function glam_quat_from_rotation_z(p6) -- line: 72
    return {
        0, 0,
        math.sin(p6 * 0.5),
        (math.cos(p6 * 0.5))
    }
end

local function glam_quat_from_euler_yxz(p7, p8, p9) -- line: 77
    -- upvalues: glam_quat_mul (copy)
    return (glam_quat_mul(glam_quat_mul({
        0,
        math.sin(p7 * 0.5),
        0,
        (math.cos(p7 * 0.5))
    }, {
        math.sin(p8 * 0.5),
        0, 0,
        (math.cos(p8 * 0.5))
    }), {
        0, 0,
        math.sin(p9 * 0.5),
        (math.cos(p9 * 0.5))
    }))
end

local function glam_quat_to_euler_yxz(p10) -- line: 87
    -- upvalues: rt (copy)
    local v28 = p10[1]
    local v29 = p10[2]
    local v30 = p10[3]
    local v31 = p10[4]
    local v32 = v28 + v28
    local v33 = v29 + v29
    local v34 = v30 + v30
    local v35 = v28 * v32
    local v36 = v28 * v33
    local v37 = v28 * v34
    local v38 = v29 * v33
    local v39 = v29 * v34
    local v40 = v30 * v34
    local v41 = v31 * v32
    local v42 = v31 * v33
    local v43 = v31 * v34
    local v44 = 1 - (v38 + v40)
    local v45 = v36 + v43
    local v46 = v36 - v43
    local v47 = 1 - (v35 + v40)
    local v48 = v37 + v42
    local v49 = v39 - v41
    local v50 = 1 - (v35 + v38)
    local v52 = math.sqrt(v50 * v50 + v48 * v48)
    local v53, v54, v55

    if 16 * rt.F32_EPSILON < v52 then
        v54 = math.atan2(v45, v47)
        v53 = math.atan2(-v49, v52)
        v55 = math.atan2(v48, v50)
    else
        v54 = math.atan2(-v46, v44)
        v53 = math.atan2(-v49, v52)
        v55 = 0
    end

    return v55, v53, v54
end

local function glam_quat_mul_vec3(p11, p12) -- line: 117
    local v59 = p11[4]
    local v60 = p11[1]
    local v61 = p11[2]
    local v62 = p11[3]
    local v63 = v60 * v60 + v61 * v61 + v62 * v62
    local v64 = v59 * v59 - v63
    local v65 = (p12[1] * v60 + p12[2] * v61 + p12[3] * v62) * 2
    local v66 = v59 * 2

    return {
        p12[1] * v64 + v60 * v65 + (v61 * p12[3] - p12[2] * v62) * v66,
        p12[2] * v64 + v61 * v65 + (v62 * p12[1] - p12[3] * v60) * v66,
        p12[3] * v64 + v62 * v65 + (v60 * p12[2] - p12[1] * v61) * v66
    }
end

t1.Frame = {}
t1.Replay = {}

local Replay = t1.Replay

function t1.Replay.default() -- line: 148
    return {
        active = false,
        free_camera = nil,
        cursor = 0,
        playing = false,
        previous_buttons = 0,
        release_controls = false,
        frames = {}
    }
end

t1.PACK_FRAMES = true

local t3 = {}

local function is_numbers(p13, p14) -- line: 180
    if type(p13) ~= "table" or #p13 ~= p14 then
        return false
    end

    local n1 = 0

    for v67, v68 in next, p13 do
        if type(v68) ~= "number" or type(v67) ~= "number" then
            return false
        end

        n1 += 1
    end

    return n1 == p14
end

local function is_transform(p15) -- line: 194
    -- upvalues: is_numbers (copy)
    if type(p15) ~= "table" or getmetatable(p15) ~= nil then
        return false
    end

    local n2 = 0

    for _ in next, p15 do
        n2 += 1
    end

    if n2 == 3 then
        return is_numbers(p15.translation, 3) and is_numbers(p15.rotation, 4) and is_numbers(p15.scale, 3)
    end

    return false
end

local function pack_transform(p16, p17, p18) -- line: 208
    local translation, rotation, scale = p18.translation, p18.rotation, p18.scale

    buffer.writef64(p16, p17, translation[1])
    buffer.writef64(p16, p17 + 8, translation[2])
    buffer.writef64(p16, p17 + 16, translation[3])
    buffer.writef64(p16, p17 + 24, rotation[1])
    buffer.writef64(p16, p17 + 32, rotation[2])
    buffer.writef64(p16, p17 + 40, rotation[3])
    buffer.writef64(p16, p17 + 48, rotation[4])
    buffer.writef64(p16, p17 + 56, scale[1])
    buffer.writef64(p16, p17 + 64, scale[2])
    buffer.writef64(p16, p17 + 72, scale[3])
end

local function pack_pose(p19) -- line: 223
    -- upvalues: t3 (copy), is_numbers (copy), is_transform (copy)
    if type(p19) ~= "table" or getmetatable(p19) ~= nil then
        return nil
    end

    if type(p19.fov) == "number" then
        local n3 = 0

        for _ in next, p19 do
            n3 += 1
        end

        local bones = p19.bones

        if n3 ~= 4 or not is_transform(p19.root) or not is_transform(p19.camera) or type(bones) ~= "table" then
            return nil
        end

        local v88 = #bones
        local n4 = 0

        for v89, v90 in next, bones do
            n4 += 1

            if type(v89) ~= "number" or type(v90) ~= "table" or #v90 ~= 4 then
                return nil
            end

            local n5 = 0

            for _ in next, v90 do
                n5 += 1
            end

            if n5 ~= 4 or not is_numbers(v90[1], 4) or not is_numbers(v90[2], 4) or not is_numbers(v90[3], 4) or not is_numbers(v90[4], 4) then
                return nil
            end
        end

        if n4 ~= v88 then
            return nil
        end

        local v91 = (v88 * 16 + 22) * 8
        local v92 = #t3
        local v93

        for i = v92, 1, -1 do
            if buffer.len(t3[i]) == v91 then
                v93 = table.remove(t3, i)
                break
            end
        end

        local v94 = v93 or buffer.create(v91)

        buffer.writef64(v94, 0, p19.fov)

        local root = p19.root
        local translation, rotation, scale = root.translation, root.rotation, root.scale

        buffer.writef64(v94, 8, translation[1])
        buffer.writef64(v94, 16, translation[2])
        buffer.writef64(v94, 24, translation[3])
        buffer.writef64(v94, 32, rotation[1])
        buffer.writef64(v94, 40, rotation[2])
        buffer.writef64(v94, 48, rotation[3])
        buffer.writef64(v94, 56, rotation[4])
        buffer.writef64(v94, 64, scale[1])
        buffer.writef64(v94, 72, scale[2])
        buffer.writef64(v94, 80, scale[3])

        local camera = p19.camera
        local translation2, rotation2, scale2 = camera.translation, camera.rotation, camera.scale

        buffer.writef64(v94, 88, translation2[1])
        buffer.writef64(v94, 96, translation2[2])
        buffer.writef64(v94, 104, translation2[3])
        buffer.writef64(v94, 112, rotation2[1])
        buffer.writef64(v94, 120, rotation2[2])
        buffer.writef64(v94, 128, rotation2[3])
        buffer.writef64(v94, 136, rotation2[4])
        buffer.writef64(v94, 144, scale2[1])
        buffer.writef64(v94, 152, scale2[2])
        buffer.writef64(v94, 160, scale2[3])
        buffer.writef64(v94, 168, v88)

        local n6 = 176

        for i = 1, v88 do
            local v115 = bones[i]

            for j = 1, 4 do
                local v116 = v115[j]

                buffer.writef64(v94, n6, v116[1])
                buffer.writef64(v94, n6 + 8, v116[2])
                buffer.writef64(v94, n6 + 16, v116[3])
                buffer.writef64(v94, n6 + 24, v116[4])
                n6 += 32
            end
        end

        return v94
    end

    return nil
end

local function unpack_transform(p20, p21) -- line: 287
    return {
        translation = {
            buffer.readf64(p20, p21),
            buffer.readf64(p20, p21 + 8),
            (buffer.readf64(p20, p21 + 16))
        },
        rotation = {
            buffer.readf64(p20, p21 + 24),
            buffer.readf64(p20, p21 + 32),
            buffer.readf64(p20, p21 + 40),
            (buffer.readf64(p20, p21 + 48))
        },
        scale = {
            buffer.readf64(p20, p21 + 56),
            buffer.readf64(p20, p21 + 64),
            (buffer.readf64(p20, p21 + 72))
        }
    }
end

local function unpack_pose(p22) -- line: 301
    -- upvalues: unpack_transform (copy)
    local v140 = buffer.readf64(p22, 168)
    local v141 = table.create(v140)
    local n7 = 176

    for i = 1, v140 do
        local v142 = table.create(4)

        for j = 1, 4 do
            v142[j] = {
                buffer.readf64(p22, n7),
                buffer.readf64(p22, n7 + 8),
                buffer.readf64(p22, n7 + 16),
                (buffer.readf64(p22, n7 + 24))
            }
            n7 += 32
        end

        v141[i] = v142
    end

    return {
        root = unpack_transform(p22, 8),
        bones = v141,
        camera = unpack_transform(p22, 88),
        fov = buffer.readf64(p22, 0)
    }
end

local t5 = {
    __index = function(p23, p24) -- __index | line: 328
        -- upvalues: unpack_pose (copy)
        local v149 = p24 == "pose"
        local packed, v150

        if v149 then
            packed = rawget(p23, "packed")
            v150 = packed == nil
        end

        return if v149 and not v150 then unpack_pose(packed) else nil
    end
}

local function frame_bone_count(p25) -- line: 340
    local packed = rawget(p25, "packed")

    if packed == nil then
        return #p25.pose.bones
    end

    return (buffer.readf64(packed, 168))
end

t1.pack_pose = pack_pose
t1.unpack_pose = unpack_pose

local function push_frame(p26, p27, p28, p29, p30) -- line: 352
    -- upvalues: WINDOW (copy), t3 (copy), t5 (copy)
    local frames = p26.frames
    local v151 = frames[#frames]
    local v152 = if v151 == nil then 0 else v151.time + p29

    if p27 ~= nil then
        table.insert(frames, (setmetatable({
            time = v152,
            packed = p27,
            cut = p30
        }, t5)))
    else
        table.insert(frames, {
            time = v152,
            pose = p28,
            cut = p30
        })
    end

    while #frames > 2 and frames[2].time <= v152 - WINDOW do
        local v154 = table.remove(frames, 1)
        local packed = rawget(v154, "packed")

        if packed ~= nil and #t3 < 8 then
            rawset(v154, "packed", nil)
            table.insert(t3, packed)
        end
    end
end

function t1.Replay.record(p31, p32, p33, p34) -- line: 375
    -- upvalues: t1 (copy), pack_pose (copy), push_frame (copy)
    if p31.active then
        return
    end

    local push_frame2, v155

    if p33 == p33 and p33 ~= 1e999 and p33 ~= (-1e999) and not (p33 <= 0) then
        push_frame2 = push_frame

        if t1.PACK_FRAMES then
            v155 = pack_pose(p32)
        end

        push_frame2(p31, v155, p32, p33, p34)
    end
end

function t1.Replay.record_copy(p35, p36, p37, p38) -- line: 385
    -- upvalues: rt (copy), t1 (copy), pack_pose (copy), push_frame (copy)
    if p35.active then
        return
    end

    if p37 == p37 and p37 ~= 1e999 and p37 ~= (-1e999) and not (p37 <= 0) then
        local v156 = if t1.PACK_FRAMES then pack_pose(p36) else nil

        push_frame(p35, v156, if v156 == nil then rt.copy(p36) else nil, p37, p38)
    end
end

function t1.Replay.bounds(p39) -- line: 395
    -- upvalues: rt (copy), WINDOW (copy)
    local frames = p39.frames
    local v158 = frames[#frames]
    local v159 = if v158 == nil then 0 else v158.time
    local v160 = frames[1]

    return rt.fmax(if v160 == nil then 0 else v160.time, v159 - WINDOW), v159
end

function t1.Replay.enter(p40) -- line: 404
    -- upvalues: Replay (copy)
    if #p40.frames == 0 then
        return
    end

    p40.active = true
    p40.playing = false
    p40.free_camera = nil

    local _, v161 = Replay.bounds(p40)

    p40.cursor = v161
end

function t1.Replay.exit(p41) -- line: 416
    p41.active = false
    p41.playing = false
    p41.free_camera = nil
    p41.release_controls = true
end

function t1.Replay.seek(p42, p43) -- line: 424
    -- upvalues: rt (copy), Replay (copy)
    local v162, v163 = Replay.bounds(p42)

    if v163 < v162 then
        error("assertion failed: min <= max", 0)
    end

    p42.cursor = rt.clamp(p43, v162, v163)
end

function t1.Replay.step(p44, p45) -- line: 433
    -- upvalues: Replay (copy)
    p44.playing = false

    local frames = p44.frames
    local v164

    if p45 > 0 then
        for i = 1, #frames do
            if frames[i].time > p44.cursor + 1E-06 then
                v164 = frames[i]
                break
            end
        end
    else
        for i = #frames, 1, -1 do
            if frames[i].time < p44.cursor - 1E-06 then
                v164 = frames[i]
                break
            end
        end
    end

    if v164 ~= nil then
        Replay.seek(p44, v164.time)
    end
end

function t1.Replay.sample(p46) -- line: 459
    -- upvalues: rt (copy)
    if not p46.active then
        return nil
    end

    local frames = p46.frames
    local v165 = 0
    local v166 = #frames

    while v165 < v166 do
        local v167 = v165 + rt.idiv(v166 - v165, 2)

        if frames[v167 + 1].time <= p46.cursor then
            v165 = v167 + 1
        else
            v166 = v167
        end
    end

    local v168 = frames[(if v165 > 0 then v165 - 1 else 0) + 1]

    if v168 == nil then
        return nil
    end

    local v169 = frames[v165 + 1]

    if v169 == nil then
        v169 = v168
    end

    if not v169.cut then
        local packed = rawget(v168, "packed")
        local v170 = if packed == nil then #v168.pose.bones else buffer.readf64(packed, 168)
        local packed2 = rawget(v169, "packed")

        if v170 == (if packed2 == nil then #v169.pose.bones else buffer.readf64(packed2, 168)) then
            local v171 = if v169.time > v168.time then rt.clamp((p46.cursor - v168.time) / (v169.time - v168.time), 0, 1) else 0
            local pose = v168.pose

            return pose, if v169 == v168 then pose else v169.pose, v171
        end
    end

    local pose = v168.pose

    return pose, pose, 0
end

function t1.Replay.toggle_camera(p47) -- line: 506
    -- upvalues: import (copy), Replay (copy)
    if p47.free_camera ~= nil then
        p47.free_camera = nil
    else
        local v172, v173, v174 = Replay.sample(p47)

        if v172 ~= nil then
            p47.free_camera = import("skate_game/presentation").blend(v172.camera, v173.camera, v174)
        else
            p47.free_camera = nil
        end
    end
end

t1.ReplayPlugin = {}

function t1.live(p48) -- line: 528
    return not p48.active
end

function t1.axis(p49) -- line: 533
    -- upvalues: rt (copy)
    return rt.signum(p49) * rt.clamp((math.abs(p49) - 0.18) / 0.82, 0, 1)
end

local axis = t1.axis

function t1.controls(p50, p51, p52, p53, p54, p55, p56, p57) -- line: 550
    -- upvalues: rt (copy), import (copy), SELECT (copy), A (copy), B (copy), Y (copy), glam_quat_mul (copy), glam_quat_to_euler_yxz (copy), glam_quat_mul_vec3 (copy), Replay (copy), axis (copy)
    if p57 ~= nil and import("skate_game/multiplayer").Multiplayer.active(p57) then
        if p50.active then
            Replay.exit(p50)
        end

        return
    end

    local ControllerInput = import("skate_game/input").ControllerInput
    local v175 = ControllerInput.raw_input(p51)
    local v178 = bit32.band(v175.buttons, (bit32.band(bit32.bnot(p50.previous_buttons), 65535)))

    p50.previous_buttons = v175.buttons

    local v179 = not import("skate_game/graphics_menu").gameplay_active(p56)

    if not v179 then
        if bit32.band(v178, SELECT) ~= 0 or p52.just_pressed(p52, "F6") then
            if p50.active then
                Replay.exit(p50)
            else
                Replay.enter(p50)
            end
        elseif p50.active and bit32.band(v178, B) ~= 0 then
            Replay.exit(p50)
        end
    end

    if p50.active or p50.release_controls then
        ControllerInput.discard_gameplay(p51)

        local v180 = not p50.active and v175.buttons == 0

        if v180 then
            for _, v182 in v175.triggers do
                if not (v182 < 0.05) then
                    v180 = false
                end
            end
        end

        if v180 then
            for _, v183 in v175.left do
                if not (math.abs(v183) < 0.18) then
                    v180 = false
                end
            end

            for _, v185 in v175.right do
                if not (math.abs(v185) < 0.18) then
                    v180 = false
                end
            end
        end

        if v180 then
            p50.release_controls = false
        end
    end

    local v186

    if not p50.active or v179 then
        return
    else
        v186 = rt.fmin(p55, 0.1)

        if bit32.band(v178, Y) ~= 0 or p52.just_pressed(p52, "KeyC") then
            Replay.toggle_camera(p50)
        end
    end

    if bit32.band(v178, A) ~= 0 or p52.just_pressed(p52, "Space") then
        local _, v191 = Replay.bounds(p50)

        if v191 <= p50.cursor then
            local v192 = Replay.bounds(p50)

            Replay.seek(p50, v192)
        end

        p50.playing = not p50.playing
    end

    local function trigger(p58) -- line: 618
        -- upvalues: rt (copy)
        return rt.clamp((p58 - 0.05) / 0.95, 0, 1)
    end

    local v193 = v175.triggers[2]
    local v194 = rt.clamp((v193 - 0.05) / 0.95, 0, 1)
    local v195 = v175.triggers[1]
    local v196 = v194 - rt.clamp((v195 - 0.05) / 0.95, 0, 1) + (if p52.pressed(p52, "ArrowRight") then 1 else 0) - (if p52.pressed(p52, "ArrowLeft") then 1 else 0)

    if not (v175.triggers[1] > 0.05) and not (v175.triggers[2] > 0.05) and not p52.pressed(p52, "ArrowLeft") and not p52.pressed(p52, "ArrowRight") then
        if p50.playing then
            local v197 = p50.cursor + v186

            Replay.seek(p50, v197)

            local _, v198 = Replay.bounds(p50)

            if v198 <= p50.cursor then
                p50.playing = false
            end
        end
    else
        p50.playing = false

        local v199 = p50.cursor + v196 * v186 * 4

        Replay.seek(p50, v199)
    end

    if bit32.band(v178, 4) ~= 0 or p52.just_pressed(p52, "Comma") then
        Replay.step(p50, -1)
    end

    if bit32.band(v178, 8) ~= 0 or p52.just_pressed(p52, "Period") then
        Replay.step(p50, 1)
    end

    local free_camera = p50.free_camera

    if free_camera == nil then
        return
    end

    local v200, v201 = glam_quat_to_euler_yxz(free_camera.rotation)
    local v202 = v200 - axis(v175.right[1]) * v186 * 2
    local v203 = v201 + axis(v175.right[2]) * v186 * 2

    if p53.pressed(p53, "Right") then
        v202 -= p54.delta[1] * 0.003
        v203 -= p54.delta[2] * 0.003
    end

    local v204 = rt.clamp(v203, -1.5, 1.5)

    free_camera.rotation = glam_quat_mul(glam_quat_mul({
        0,
        math.sin(v202 * 0.5),
        0,
        (math.cos(v202 * 0.5))
    }, {
        math.sin(v204 * 0.5),
        0, 0,
        (math.cos(v204 * 0.5))
    }), { 0, 0, 0, 1 })

    local v211 = axis(v175.left[1]) + (if p52.pressed(p52, "KeyD") then 1 else 0) - (if p52.pressed(p52, "KeyA") then 1 else 0)
    local v212 = axis(v175.left[2]) + (if p52.pressed(p52, "KeyW") then 1 else 0) - (if p52.pressed(p52, "KeyS") then 1 else 0)
    local v214 = (if bit32.band(v175.buttons, 512) ~= 0 or p52.pressed(p52, "KeyE") then 1 else 0) - (if bit32.band(v175.buttons, 256) ~= 0 or p52.pressed(p52, "KeyQ") then 1 else 0)
    local t9 = {
        0,
        math.sin(v202 * 0.5),
        0,
        (math.cos(v202 * 0.5))
    }
    local v218 = if bit32.band(v175.buttons, 64) ~= 0 or p52.pressed(p52, "ShiftLeft") then 12 else 3
    local v219 = glam_quat_mul_vec3(t9, { v211, 0, -v212 })

    v219[2] += v214

    local translation = free_camera.translation

    translation[1] += v219[1] * v186 * v218
    translation[2] += v219[2] * v186 * v218
    translation[3] += v219[3] * v186 * v218
end

t1.ReplayUi = {}
t1.ReplayLabel = {}
t1.Playhead = {}

function t1.update_ui(p59) -- line: 703
    -- upvalues: Replay (copy)
    if not p59.active then
        return false, nil, nil
    end

    local v220, v221 = Replay.bounds(p59)

    return true, string.format("REPLAY  %.2f / %.2f s   |   %s   |   %s", p59.cursor - v220, v221 - v220, if p59.playing then "PLAYING" else "PAUSED", if p59.free_camera == nil then "RECORDED CAMERA" else "FREE CAMERA"), (if v220 < v221 then (p59.cursor - v220) / (v221 - v220) else 1) * 100
end

return t1
