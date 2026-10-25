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
local Vector3 = import("skate_core/math").Vector3
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local Bounds = import("skate_core/physics/board_world/query_metadata").Bounds
local v2 = import("skate_core/player/respawn")
local History, surface_allowed = v2.History, v2.surface_allowed
local Collections = import("skate_data/collections").Collections
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local triangle_segment_transient = import("skate_core/physics/triangle_query").triangle_segment_transient

local function contact_queries() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/contact_queries")
end

local function teleport_state() -- line: 34
    -- upvalues: import (copy)
    return import("skate_game/physics/teleport_state")
end

local function skater_animation() -- line: 37
    -- upvalues: import (copy)
    return import("skate_game/skater_animation")
end

local function solve() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function ground_runtime() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local v3 = false
local t1 = {}

local function map_from_bits(p2) -- line: 51
    -- upvalues: v1 (copy)
    local v4 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v4[i] = buffer.readf32(v1, 0)
    end

    return v4
end

local observe_due, v6

t1.Runtime = {}
t1.Settings = {}
t1.Scene = {}

local function scene_trait(p3) -- line: 75
    -- upvalues: t1 (copy)
    return {
        ground = function(_, p5) -- ground | line: 77
            -- upvalues: p3 (copy), t1 (copy)
            return t1.Scene.ground(p3, p5)
        end,
        location = function(_, p7) -- location | line: 80
            -- upvalues: p3 (copy), t1 (copy)
            return t1.Scene.location(p3, p7)
        end,
        occupants = function(_, p9) -- occupants | line: 83
            -- upvalues: p3 (copy), t1 (copy)
            return t1.Scene.occupants(p3, p9)
        end,
        edges = function(_, p11) -- edges | line: 86
            -- upvalues: p3 (copy), t1 (copy)
            return t1.Scene.edges(p3, p11)
        end
    }
end

function t1.Runtime.load(p12, p13, p14) -- line: 93
    -- upvalues: rt (copy), History (copy), Collections (copy)
    local function value(p15) -- line: 95
        -- upvalues: p12 (copy), Collections (copy)
        return Collections.float(p12, "Hash_12B64C0E804B0853", "default", p15)
    end

    return {
        measurements = 0,
        history = History.new({
            offboard = false,
            score = 0,
            transform = rt.copy(p13),
            stance = p14
        }),
        settings = {
            height = Collections.float(p12, "Hash_12B64C0E804B0853", "default", "Hash_C0526C883AF0ECCA"),
            radius = Collections.float(p12, "Hash_12B64C0E804B0853", "default", "Hash_CEB092E418A5B001"),
            drop = Collections.float(p12, "Hash_12B64C0E804B0853", "default", "Hash_8ABE098D3806D273"),
            normal_y = Collections.float(p12, "Hash_12B64C0E804B0853", "default", "Hash_ADD032CACF6A1C15"),
            minimum_frames = Collections.integer(p12, "Hash_12B64C0E804B0853", "default", "Hash_10B7C3A9CC8D3721")
        }
    }
end

function t1.Runtime.reset_measurements(p16) -- line: 122
    p16.measurements = 0
end

function t1.request(p17, p18) -- line: 128
    -- upvalues: rt (copy), import (copy), History (copy), scene_trait (copy)
    local SkaterAnimation = import("skate_game/skater_animation").SkaterAnimation
    local v7 = SkaterAnimation.checkpoint_stance(p18.animation)
    local respawn = p18.respawn
    local v8 = History.automatic(respawn.history, v7, (scene_trait({
        world = p17.world,
        settings = respawn.settings
    })))

    SkaterAnimation.request_checkpoint_stance(p18.animation, v8.stance)
    import("skate_game/physics/teleport_state").Runtime.reply(p18.teleport_state, {
        transform = rt.copy(v8.transform),
        on_board = not v8.offboard
    })
end

function t1.observe(p19, p20) -- line: 175
    -- upvalues: rt (copy), v1 (copy), import (copy), History (copy), v3 (ref), t1 (copy), observe_due (ref), v6 (ref)
    if v3 then
        return t1.observe_reference(p19, p20)
    end

    local physical = p20.player_input.physical
    local respawn = p20.respawn

    respawn.measurements = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(respawn.measurements), rt.to_u32(1)))

    local history = respawn.history
    local current_position = history.current_position
    local vector_64 = physical.reckoning.vector_64
    local v9 = #vector_64

    if type(current_position) ~= "table" or #current_position ~= v9 then
        local v10 = table.create(#vector_64)

        for i = 1, #vector_64 do
            buffer.writeu32(v1, 0, vector_64[i])
            v10[i] = buffer.readf32(v1, 0)
        end

        history.current_position = v10
    else
        for i = 1, v9 do
            buffer.writeu32(v1, 0, vector_64[i])
            current_position[i] = buffer.readf32(v1, 0)
        end
    end

    if not History.recording_due(history, respawn.measurements, p20.animated_skeleton.roots.animation_to_world[4]) or physical.state.flag_69 ~= 0 then
        return
    end

    local state_16 = physical.state.state_16

    if state_16 == 100 or state_16 == 104 then
        local processed = p20.player_input.processed
        local v13, v14

        if p20.player_state.state_count <= respawn.settings.minimum_frames then
            v13 = import("skate_game/physics/solve").deck_frame_into(p19.board, v6)
            v6 = v13

            if bit32.band(processed.flags_2468, 1048576) ~= 0 then
                t1.flip(v13)
            end

            v14 = false
        elseif bit32.band(processed.grind.flags_1516, 134217728) == 0 then
            v14 = true
        else
            v13 = import("skate_game/physics/solve").deck_frame_into(p19.board, v6)
            v6 = v13

            if bit32.band(processed.flags_2468, 1048576) ~= 0 then
                t1.flip(v13)
            end

            v14 = false
        end

        if not v14 then
            v13[4][2] += 0.2

            local heading = t1.heading
            local vector_80 = physical.skateboard.vector_80
            local v15 = table.create(#vector_80)

            for i = 1, #vector_80 do
                buffer.writeu32(v1, 0, vector_80[i])
                v15[i] = buffer.readf32(v1, 0)
            end

            history.current_orientation = heading(v13, v15)

            return
        end
    elseif state_16 ~= 500 and state_16 ~= 502 or p20.player_state.state_count <= respawn.settings.minimum_frames or p20.biped_ground.controller.state.contact.active then
        return
    end

    return observe_due(p19, p20)
end

function t1.observe_reference(p21, p22) -- line: 238
    -- upvalues: rt (copy), observe_due (ref)
    local respawn = p22.respawn

    respawn.measurements = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(respawn.measurements), rt.to_u32(1)))

    return observe_due(p21, p22)
end

function observe_due(p23, p24) -- line: 248
    -- upvalues: rt (copy), v1 (copy), import (copy), History (copy), t1 (copy), scene_trait (copy)
    local physical, processed = p24.player_input.physical, p24.player_input.processed
    local v17 = import("skate_game/physics/solve").deck_frame(p23.board)

    if bit32.band(processed.flags_2468, 1048576) ~= 0 then
        t1.flip(v17)
    end

    v17[4][2] += 0.2

    local v18 = rt.copy(p24.animated_skeleton.roots.animation_to_world)

    if bit32.band(processed.flags_2476, 4) ~= 0 then
        t1.flip(v18)
    end

    local vector_80 = physical.skateboard.vector_80
    local v19 = table.create(#vector_80)

    for i = 1, #vector_80 do
        buffer.writeu32(v1, 0, vector_80[i])
        v19[i] = buffer.readf32(v1, 0)
    end

    local v21 = import("skate_game/skater_animation").SkaterAnimation.checkpoint_stance(p24.animation)
    local respawn = p24.respawn
    local v23 = bit32.band(bit32.rshift(processed.left_surface_2596, 7), 31)
    local t3 = {
        alternate_world = false,
        measurements = respawn.measurements,
        root_position = rt.copy(p24.animated_skeleton.roots.animation_to_world[4])
    }
    local vector_64 = physical.reckoning.vector_64
    local v24 = table.create(#vector_64)

    for i = 1, #vector_64 do
        buffer.writeu32(v1, 0, vector_64[i])
        v24[i] = buffer.readf32(v1, 0)
    end

    t3.com_position = v24
    t3.teleport_requested = physical.state.flag_69 ~= 0
    t3.physical_state = physical.state.state_16
    t3.state_frames = p24.player_state.state_count
    t3.ground_suppressed = bit32.band(processed.grind.flags_1516, 134217728) ~= 0
    t3.offboard_correction = p24.biped_ground.controller.state.contact.active
    t3.ground_category = bit32.band(import("skate_game/physics/ground_runtime").active_surface(p23.riding, p23.board), 65535)
    t3.foot_categories = { v23, v23 }
    t3.riding_transform = t1.heading(v17, v19)
    t3.offboard_transform = v18
    t3.stance = v21

    return History.observe(respawn.history, t3, respawn.settings.minimum_frames, (scene_trait({
        world = p23.world,
        settings = respawn.settings
    })))
end

function t1.flip(p25) -- line: 296
    for _, v27 in { 0, 2 } do
        local v28 = p25[v27 + 1]
        local v29 = table.create(#v28)

        for i = 1, #v28 do
            v29[i] = -v28[i]
        end

        p25[v27 + 1] = v29
    end
end

function t1.heading(p26, p27) -- line: 309
    -- upvalues: rt (copy)
    local v30 = rt.copy(p26)
    local v31 = p27[1] * p27[1] + p27[2] * p27[2] + p27[3] * p27[3]

    if v31 > 0.25 then
        local v32 = 1 / math.sqrt(v31)
        local t4 = {
            p27[1] * v32,
            0,
            p27[3] * v32,
            0
        }

        if t4[1] * t4[1] + t4[3] * t4[3] > 0.9 then
            v30[1] = {
                t4[3],
                0,
                -t4[1],
                0
            }
            v30[2] = { 0, 1, 0, 0 }
            v30[3] = t4
        end
    end

    return v30
end

function t1.Scene.ground_reference(p28, p29) -- line: 326
    -- upvalues: rt (copy), import (copy), surface_allowed (copy)
    local v33 = rt.copy(p29[4])

    v33[2] += 0.1

    local v34 = rt.copy(v33)

    v34[2] -= 10

    local function probe(p30, p31, p32) -- line: 331
        -- upvalues: rt (copy)
        return {
            start = rt.copy(p30),
            ["end"] = rt.copy(p31),
            radius = p32
        }
    end

    local v35 = import("skate_game/physics/offboard/contact_queries").query(p28.world, {
        start = rt.copy(v33),
        ["end"] = rt.copy(v34),
        radius = 0
    }, 0)

    if v35 ~= nil then
        local v37 = bit32.band(bit32.rshift(v35.packed_surface, 7), 31)

        if not (v35.geometry.normal.y < p28.settings.normal_y) and not (v33[2] - v35.geometry.position.y > p28.settings.drop) and surface_allowed(v37) then
            local v38 = rt.copy(v33)

            v38[2] += p28.settings.radius

            local v39 = rt.copy(v38)

            v39[2] += p28.settings.height

            local query = import("skate_game/physics/offboard/contact_queries").query
            local world = p28.world
            local radius = p28.settings.radius

            if query(world, {
                start = rt.copy(v38),
                ["end"] = rt.copy(v39),
                radius = radius
            }, 0) ~= nil then
                return nil
            end

            local position = v35.geometry.position

            return {
                position = {
                    position.x,
                    position.y,
                    position.z,
                    0
                },
                offboard = v37 == 8
            }
        end
    end

    return nil
end

local eq, IDENTITY = RetailAffineTransform.eq, RetailAffineTransform.IDENTITY
local t6 = {
    Ground = 1,
    Island = 2,
    Conditional = 3
}
local v40 = rt.to_i32(0)
local self = setmetatable({}, {
    __mode = "k"
})

local function build_scene_index(p33) -- line: 414
    -- upvalues: eq (copy), IDENTITY (copy), t6 (copy), v40 (copy)
    local meshes = p33.meshes
    local v42 = #meshes
    local v43 = table.create(v42, 0)
    local v44 = table.create(v42, 0)
    local v45 = table.create(v42, 0)
    local v46 = table.create(v42, false)
    local n1 = (-1e999)

    for i = 1, v42 do
        local v47 = meshes[i]
        local triangle_range = v47.triangle_range
        local start, v48 = triangle_range.start, triangle_range["end"]

        if type(start) ~= "number" or type(v48) ~= "number" or not (n1 <= start) or not (start <= v48) or not eq(v47.local_to_world, IDENTITY) then
            return false
        end

        n1 = v48
        v43[i] = start
        v44[i] = v48
        v45[i] = t6[v47.pool] or 0

        if v47.matching_group == -1 then
            v46[i] = true
        else
            v46[i] = v47.matching_group == v40
        end
    end

    return {
        meshes = meshes,
        count = v42,
        starts = v43,
        stops = v44,
        ranks = v45,
        groups = v46
    }
end

local function scene_index_of(p34) -- line: 444
    -- upvalues: self (copy), build_scene_index (copy)
    local v49 = self[p34]
    local result, v50

    if v49 ~= nil then
        if v49 == false or v49.meshes == p34.meshes and v49.count == #p34.meshes then
            result = v49
            v50 = true
        else
            v50 = false
        end
    else
        v50 = false
    end

    if not v50 then
        local ok

        ok, result = pcall(build_scene_index, p34)

        if not ok then
            result = false
        end

        self[p34] = result
    end

    return result or nil
end

local v51 = Vector3.new(0, 0, 0)
local v52 = Vector3.new(0, 0, 0)
local v53 = Vector3.new(0, 0, 0)
local v54 = Vector3.new(0, 0, 0)
local v55 = Vector3.new(0, 0, 0)
local v56 = Vector3.new(0, 0, 0)
local t9 = {
    v54,
    v55,
    v56
}
local v57 = Vector3.new(0, 0, 0)
local v58 = Vector3.new(0, 0, 0)
local t10 = {
    0, 0, 0
}
local t11 = {
    fraction = 0,
    position = v57,
    normal = v58,
    volume_parameter = t10
}
local v59 = false
local n2 = -1

local function scene_test(p35, p36, p37) -- line: 478
    -- upvalues: triangle_segment_transient (copy), v51 (copy), v53 (copy), v54 (copy), v55 (copy), v56 (copy), t9 (copy), v57 (copy), v58 (copy), t10 (copy), t11 (copy)
    local triangle = p35.triangle
    local vertices = triangle.vertices

    if #vertices ~= 3 then
        return nil
    end

    local local_to_world = p36.local_to_world
    local translation = local_to_world.translation
    local columns = local_to_world.basis.columns
    local v60 = columns[1]
    local v61 = columns[2]
    local v62 = columns[3]
    local v63 = vertices[1]

    v54.x = v62[1] * v63.z + (v61[1] * v63.y + (v60[1] * v63.x + translation.x))
    v54.y = v62[2] * v63.z + (v61[2] * v63.y + (v60[2] * v63.x + translation.y))
    v54.z = v62[3] * v63.z + (v61[3] * v63.y + (v60[3] * v63.x + translation.z))

    local v64 = vertices[2]

    v55.x = v62[1] * v64.z + (v61[1] * v64.y + (v60[1] * v64.x + translation.x))
    v55.y = v62[2] * v64.z + (v61[2] * v64.y + (v60[2] * v64.x + translation.y))
    v55.z = v62[3] * v64.z + (v61[3] * v64.y + (v60[3] * v64.x + translation.z))

    local v65 = vertices[3]

    v56.x = v62[1] * v65.z + (v61[1] * v65.y + (v60[1] * v65.x + translation.x))
    v56.y = v62[2] * v65.z + (v61[2] * v65.y + (v60[2] * v65.x + translation.y))
    v56.z = v62[3] * v65.z + (v61[3] * v65.y + (v60[3] * v65.x + translation.z))
    v57.x = 0
    v57.y = 0
    v57.z = 0
    t11.position = v57
    v58.x = 0
    v58.y = 0
    v58.z = 0
    t11.normal = v58
    t11.fraction = 0
    t10[1] = 0
    t10[2] = 0
    t10[3] = 0
    t11.volume_parameter = t10

    return triangle_segment_transient(t11, v51, v53, t9, p37, triangle.fatness)
end

local function scene_scan(p38, p39, p40, p41, p42, p43, p44, p45, p46, p47, p48) -- line: 521
    -- upvalues: BoardWorld (copy), v51 (copy), v52 (copy), v53 (copy), t11 (copy), n2 (ref), scene_test (copy)
    v51.x = p41
    v51.y = p42
    v51.z = p43
    v52.x = p44
    v52.y = p45
    v52.z = p46

    local v66 = p44 - p41
    local v67 = p45 - p42
    local v68 = p46 - p43

    v53.x = v66
    v53.y = v67
    v53.z = v68

    local v69 = BoardWorld.line_candidates(p38, v51, v52, p47)
    local v70 = #v69

    if v70 == 0 then
        return true, false
    end

    local v71 = v69[1][1]

    for i = 2, v70 do
        local v72 = v69[i][1]

        if not (v71 <= v72) then
            return false
        end

        v71 = v72
    end

    local meshes, count, starts, stops = p40.meshes, p40.count, p40.starts, p40.stops
    local ranks, groups = p40.ranks, p40.groups
    local v73 = p39.island_flags == 3

    if p48 then
        local v74 = n2

        if v69[1][1] <= v74 and v74 <= v71 then
            local n3 = 1
            local v75 = v70

            while n3 < v75 do
                local v76 = n3 + (v75 - n3) // 2

                if v69[v76][1] < v74 then
                    n3 = v76 + 1
                else
                    v75 = v76
                end
            end

            if v69[n3][1] == v74 then
                local v77 = 1
                local v78 = count + 1

                while v77 < v78 do
                    local v79 = v77 + (v78 - v77) // 2

                    if stops[v79] <= v74 then
                        v77 = v79 + 1
                    else
                        v78 = v79
                    end
                end

                if v77 <= count and starts[v77] <= v74 and groups[v77] then
                    local v80 = ranks[v77]

                    if v80 == 1 or v80 == 2 or v80 == 3 and v73 then
                        local v81 = scene_test(v69[n3][2], meshes[v77], p47)

                        if v81 == nil then
                            return false
                        end

                        if v81 then
                            return true, true
                        end
                    end
                end
            end
        end

        local n4 = 1

        for i = 1, v70 do
            local v82 = v69[i]
            local v83 = v82[1]

            while n4 <= count and stops[n4] <= v83 do
                n4 += 1
            end

            if count < n4 then
                break
            end

            if starts[n4] <= v83 and groups[n4] then
                local v84 = ranks[n4]

                if v84 == 1 or v84 == 2 or v84 == 3 and v73 then
                    local v85 = scene_test(v82[2], meshes[n4], p47)

                    if v85 == nil then
                        return false
                    end

                    if v85 then
                        n2 = v83

                        return true, true
                    end
                end
            end
        end

        return true, false
    end

    local v86 = false
    local n5 = 0
    local fraction = 0
    local x = 0
    local y = 0
    local z = 0
    local x2 = 0
    local y2 = 0
    local z2 = 0

    for i = 1, 3 do
        if i ~= 3 or v73 then
            local n6 = 1

            for j = 1, v70 do
                local v87 = v69[j]
                local v88 = v87[1]

                while n6 <= count and stops[n6] <= v88 do
                    n6 += 1
                end

                if count < n6 then
                    break
                end

                if starts[n6] <= v88 and ranks[n6] == i and groups[n6] then
                    local v89 = scene_test(v87[2], meshes[n6], p47)

                    if v89 == nil then
                        return false
                    end

                    if v89 and (not v86 or t11.fraction < fraction) then
                        n5 = v88
                        fraction = t11.fraction

                        local normal, position = t11.normal, t11.position

                        x = normal.x
                        y = normal.y
                        z = normal.z
                        x2 = position.x
                        y2 = position.y
                        z2 = position.z
                        v86 = true
                    end
                end
            end
        end
    end

    return true, v86, n5, fraction, x, y, z, x2, y2, z2
end

function t1.scene_scan(p49, p50, p51, p52, p53, p54, p55, p56, p57) -- line: 659
    -- upvalues: BoardWorld (copy), self (copy), build_scene_index (copy), scene_scan (copy)
    local v90 = BoardWorld.query_metadata(p49)
    local v91 = self[v90]
    local result, v92

    if v91 ~= nil then
        if v91 == false or v91.meshes == v90.meshes and v91.count == #v90.meshes then
            result = v91
            v92 = true
        else
            v92 = false
        end
    else
        v92 = false
    end

    if not v92 then
        local ok

        ok, result = pcall(build_scene_index, v90)

        if not ok then
            result = false
        end

        self[v90] = result
    end

    local v93 = result or nil

    if v93 == nil then
        return false
    end

    return scene_scan(p49, v90, v93, p50, p51, p52, p53, p54, p55, p56, p57)
end

function t1.scene_hints(p58, p59) -- line: 668
    -- upvalues: v59 (ref), n2 (ref)
    local v94 = v59
    local v95 = n2

    if p58 ~= nil then
        v59 = p58
    end

    if p59 ~= nil then
        n2 = p59
    end

    return v94, v95
end

function t1.set_reference(p60) -- line: 679
    -- upvalues: v3 (ref)
    v3 = p60
end

function t1.Scene.ground(p61, p62) -- line: 684
    -- upvalues: surface_allowed (copy), v3 (ref), t1 (copy), self (copy), build_scene_index (copy), v59 (ref), scene_scan (copy)
    if v3 then
        return t1.Scene.ground_reference(p61, p62)
    end

    local world = p61.world
    local v96 = p62[4]
    local query_metadata = world.query_metadata
    local result, v97

    if type(v96) ~= "table" or query_metadata == nil then
        v97 = true
    else
        result = self[query_metadata]

        if result ~= nil then
            if result ~= false and (result.meshes ~= query_metadata.meshes or result.count ~= #query_metadata.meshes) then
                local ok

                ok, result = pcall(build_scene_index, query_metadata)

                if not ok then
                    result = false
                end

                self[query_metadata] = result
            end
        else
            local ok

            ok, result = pcall(build_scene_index, query_metadata)

            if not ok then
                result = false
            end

            self[query_metadata] = result
        end

        v97 = false
    end

    local v98 = not v97 and result or nil

    if v98 == nil then
        return t1.Scene.ground_reference(p61, p62)
    end

    local settings = p61.settings
    local radius, height = settings.radius, settings.height
    local v99 = v96[1]
    local v100 = v96[2] + 0.1
    local v101 = v96[3]
    local v102 = v100 - 10
    local v103 = v100 + radius
    local v104 = v103 + height
    local v105 = v59

    if v105 then
        local v106, v107 = scene_scan(world, query_metadata, v98, v99, v103, v101, v99, v104, v101, radius, true)

        if not v106 then
            return t1.Scene.ground_reference(p61, p62)
        end

        if v107 then
            return nil
        end

        v59 = false
    end

    local v108, v109, v110, _, _, v111, _, v112, v113, v114 = scene_scan(world, query_metadata, v98, v99, v100, v101, v99, v102, v101, 0, false)

    if not v108 then
        return t1.Scene.ground_reference(p61, p62)
    end

    if v109 then
        local v117 = bit32.band(bit32.rshift(query_metadata.packed_surfaces[v110 + 1], 7), 31)

        if not (v111 < settings.normal_y) and not (v100 - v113 > settings.drop) and surface_allowed(v117) then
            if not v105 then
                local v118, v119 = scene_scan(world, query_metadata, v98, v99, v103, v101, v99, v104, v101, radius, true)

                if not v118 then
                    return t1.Scene.ground_reference(p61, p62)
                end

                if v119 then
                    v59 = true

                    return nil
                end
            end

            return {
                position = { v112, v113, v114, 0 },
                offboard = v117 == 8
            }
        end
    end

    return nil
end

function t1.Scene.location(_, _) -- line: 745
    return true
end

function t1.Scene.occupants(p65, _) -- line: 751
    -- upvalues: BoardWorld (copy)
    BoardWorld.query_metadata(p65.world)

    return true
end

function t1.Scene.edges(p67, p68) -- line: 760
    -- upvalues: rt (copy), Vector3 (copy), BoardWorld (copy), Bounds (copy)
    local v120 = rt.copy(p68[4])
    local t12 = {
        min = Vector3.new(v120[1] - 0.3, v120[2] - 0.6, v120[3] - 0.3),
        max = Vector3.new(v120[1] + 0.3, v120[2] + 0.6, v120[3] + 0.3)
    }
    local n7 = 0

    for _, v121 in BoardWorld.query_metadata(p67.world).static_edges do
        if Bounds.overlaps(v121.local_bounds, t12) then
            if n7 >= 40 then
                break
            end

            n7 += 1

            local t13 = {
                v121.start.x,
                v121.start.y,
                v121.start.z
            }
            local t14 = {
                v121["end"].x,
                v121["end"].y,
                v121["end"].z
            }
            local t15 = {
                t14[1] - t13[1],
                t14[2] - t13[2],
                t14[3] - t13[3]
            }
            local v122 = 0 + t15[1] * t15[1] + t15[2] * t15[2] + t15[3] * t15[3]
            local v123 = 0 + (v120[1] - t13[1]) * t15[1] + (v120[2] - t13[2]) * t15[2] + (v120[3] - t13[3]) * t15[3]
            local v124 = if v122 > 0 then rt.clamp(v123 / v122, 0, 1) else 0

            if 0 + (v120[1] - t13[1] - t15[1] * v124) ^ 2 + (v120[2] - t13[2] - t15[2] * v124) ^ 2 + (v120[3] - t13[3] - t15[3] * v124) ^ 2 < 0.09 then
                return false
            end
        end
    end

    return true
end

return t1
