-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/foot_ik/drive")
local v2 = import("skate_core/physics/board")
local v3 = import("skate_core/physics/board_runtime")
local v4 = import("skate_core/physics/contact_feedback")
local v5 = import("skate_core/physics/skeleton_output")
local v6 = import("skate_core/physics/skeleton_output/correction")
local v7 = import("skate_core/physics/skeleton_output/wobble")
local v8 = import("skate_core/physics/truck_frames")
local Collections = import("skate_data/collections").Collections
local Geometry = v1.Geometry
local BodyId = v2.BodyId
local BoardRuntime = v3.BoardRuntime
local SkeletonOutput = v5.SkeletonOutput
local steering_truck_transforms = v8.steering_truck_transforms
local to_matrix
local t1 = {}

t1.SkeletonOutput = {}

local function eq_ignore_ascii_case(p1, p2) -- line: 41
    if #p1 == #p2 then
        return string.lower(p1) == string.lower(p2)
    end

    return false
end

function t1.SkeletonOutput.load(p3, p4, p5) -- line: 46
    -- upvalues: rt (copy), v6 (copy), v7 (copy), Collections (copy), Geometry (copy)
    local v9 = table.create(24)

    for i = 0, #p5.bone_indices - 1 do
        local v10 = p5.bone_indices[i + 1]
        local v11 = p4.parents[v10 + 1]

        if v11 == nil then
            error("Missing output bone ancestor", 0)
        end

        local n1 = 0

        while v11 >= 0 do
            if #p4.parents <= v11 or #p4.parents <= n1 then
                error("Invalid physical output hierarchy", 0)
            end

            local v12 = #p5.bone_indices - 1
            local v13

            for j = 0, v12 do
                if p5.bone_indices[j + 1] == v11 then
                    v13 = j
                    break
                end
            end

            if v13 == nil then
                v11 = p4.parents[v11 + 1]
                n1 += 1
                continue
            end

            v9[i + 1] = v13
            break
        end
    end

    local function bone(p6) -- line: 76
        -- upvalues: p4 (copy)
        for i = 0, #p4.bone_names - 1 do
            local v14 = p4.bone_names[i + 1]

            if #v14 == #p6 and string.lower(v14) == string.lower(p6) then
                return i
            end
        end

        error(string.format("Missing stock output bone %s", p6), 0)
    end

    local function scalar(p7) -- line: 84
        -- upvalues: p3 (copy), Collections (copy)
        return Collections.float(p3, "physics_skeleton", "default", p7)
    end

    local t2 = {
        front_truck = bone("Truck_Front"),
        back_truck = bone("Truck_Back"),
        front_left_wheel = bone("Left_WheelFront"),
        front_right_wheel = bone("Right_WheelFront"),
        back_left_wheel = bone("Left_WheelBack"),
        back_right_wheel = bone("Right_WheelBack")
    }

    local function graph(p8) -- line: 103
        -- upvalues: p3 (copy), rt (copy), Collections (copy)
        local v15 = rt.map(Collections.words(p3, "physics_deck_wobble", "default", p8, 20), rt.from_bits)

        return {
            x = rt.slice(v15, 4, 12),
            y = rt.slice(v15, 12, 20)
        }
    end

    local v16 = Geometry.new(v9, p5.physics_frames)
    local TruckTiltScalar = Collections.float(p3, "physics_skeleton", "default", "TruckTiltScalar")
    local TruckTiltMaxAngle = Collections.float(p3, "physics_skeleton", "default", "TruckTiltMaxAngle")
    local TruckTiltWobbleScalar = Collections.float(p3, "physics_skeleton", "default", "TruckTiltWobbleScalar")
    local TruckDisplacementMax = Collections.float(p3, "physics_skeleton", "default", "TruckDisplacementMax")

    return {
        pose = {
            bone_indices = rt.copy(p5.bone_indices),
            geometry = v16,
            board_bones = t2,
            board_settings = {
                truck_tilt_scalar = TruckTiltScalar,
                truck_tilt_max_angle = TruckTiltMaxAngle,
                truck_tilt_wobble_scalar = TruckTiltWobbleScalar,
                truck_displacement_max = TruckDisplacementMax
            }
        },
        wobble = v7.Wobble.default(),
        deck_wobble = v7.Output.default(),
        correction = v6.CorrectionState.default(),
        compression_rest_height = Collections.float(p3, "physicstrucks", "default", "TruckYPos"),
        wobble_settings = {
            takeoff_tilt = graph("TiltVsTimeTakeOff"),
            landing_tilt = graph("TiltVsTimeLanding"),
            takeoff_squish = graph("SquishVsTimeTakeOff"),
            landing_squish = graph("SquishVsTimeLanding"),
            maximum_time = Collections.float(p3, "physics_deck_wobble", "default", "MaxTime")
        }
    }
end

function t1.SkeletonOutput.trigger_wobble(p9, p10, p11) -- line: 155
    -- upvalues: v7 (copy)
    v7.Wobble.trigger(p9.wobble, p10, p11)
end

function t1.SkeletonOutput.average_compressions_reference(p12, p13) -- line: 161
    -- upvalues: v4 (copy), BodyId (copy), BoardRuntime (copy), t1 (copy)
    local v17 = t1.to_matrix_reference(BoardRuntime.body_transform(p13, BodyId.Deck))
    local t3 = {
        t1.to_matrix_reference(BoardRuntime.body_transform(p13, BodyId.ORDER[1]))[4],
        t1.to_matrix_reference(BoardRuntime.body_transform(p13, BodyId.ORDER[2]))[4],
        t1.to_matrix_reference(BoardRuntime.body_transform(p13, BodyId.ORDER[3]))[4],
        t1.to_matrix_reference(BoardRuntime.body_transform(p13, BodyId.ORDER[4]))[4]
    }

    return v4.average_wheel_compressions(v17, t3, p12.compression_rest_height)
end

local function body_matrix(p14, p15) -- line: 177
    -- upvalues: BodyId (copy)
    local rates = p14.bodies[BodyId.index(p15) + 1].rates
    local columns = rates.basis.columns
    local v18 = columns[1]
    local v19 = columns[2]
    local v20 = columns[3]
    local position = rates.position

    return {
        {
            v18[1],
            v18[2],
            v18[3],
            0
        },
        {
            v19[1],
            v19[2],
            v19[3],
            0
        },
        {
            v20[1],
            v20[2],
            v20[3],
            0
        },
        {
            position.x,
            position.y,
            position.z,
            0
        }
    }
end

t1.body_matrix = body_matrix

function t1.body_translation(p16, p17) -- line: 196
    -- upvalues: BodyId (copy)
    local position = p16.bodies[BodyId.index(p17) + 1].rates.position

    return {
        position.x,
        position.y,
        position.z,
        0
    }
end

local t4 = {
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 }
}
local t5 = {
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 }
}

function t1.SkeletonOutput.average_compressions(p18, p19) -- line: 220
    -- upvalues: v4 (copy), BodyId (copy), t4 (copy), t5 (copy)
    local bodies = p19.bodies
    local rates = bodies[BodyId.index(BodyId.Deck) + 1].rates
    local columns = rates.basis.columns
    local v21 = columns[1]
    local v22 = columns[2]
    local v23 = columns[3]
    local position = rates.position
    local v24 = t4[1]
    local v25 = v21[1]
    local v26 = v21[2]
    local v27 = v21[3]

    v24[1] = v25
    v24[2] = v26
    v24[3] = v27
    v24[4] = 0

    local v28 = t4[2]
    local v29 = v22[1]
    local v30 = v22[2]
    local v31 = v22[3]

    v28[1] = v29
    v28[2] = v30
    v28[3] = v31
    v28[4] = 0

    local v32 = t4[3]
    local v33 = v23[1]
    local v34 = v23[2]
    local v35 = v23[3]

    v32[1] = v33
    v32[2] = v34
    v32[3] = v35
    v32[4] = 0

    local v36 = t4[4]
    local x, y, z = position.x, position.y, position.z

    v36[1] = x
    v36[2] = y
    v36[3] = z
    v36[4] = 0

    for i = 1, 4 do
        local position = bodies[BodyId.index(BodyId.ORDER[i]) + 1].rates.position
        local v37 = t5[i]
        local x, y, z = position.x, position.y, position.z

        v37[1] = x
        v37[2] = y
        v37[3] = z
        v37[4] = 0
    end

    return v4.average_wheel_compressions(t4, t5, p18.compression_rest_height)
end

function t1.SkeletonOutput.advance_wobble(p20, p21, p22) -- line: 253
    -- upvalues: rt (copy), v7 (copy)
    p20.deck_wobble = v7.Wobble.update(p20.wobble, p20.wobble_settings)

    if not p20.deck_wobble.sampled then
        return rt.copy(p22)
    end

    v7.apply(rt.copy(p20.deck_wobble), p21.record.pose[1])

    return rt.copy(p21.record.pose[1])
end

function t1.SkeletonOutput.publish(p23, p24, p25, p26, p27, p28, p29, p30, p31) -- line: 272
    -- upvalues: rt (copy), BodyId (copy), SkeletonOutput (copy), steering_truck_transforms (copy), to_matrix (ref), body_matrix (copy)
    local t6 = {
        body_matrix(p26, BodyId.ORDER[1]),
        body_matrix(p26, BodyId.ORDER[2]),
        body_matrix(p26, BodyId.ORDER[3]),
        body_matrix(p26, BodyId.ORDER[4]),
        body_matrix(p26, BodyId.ORDER[5]),
        body_matrix(p26, BodyId.ORDER[6])
    }
    local v38 = rt.map(steering_truck_transforms(p27, p28), to_matrix)
    local pose = p25.record.pose
    local v39 = table.create(24)

    for i = 1, 24 do
        v39[i] = pose[i]
    end

    SkeletonOutput.publish(p23.pose, {
        physical_parts = v39,
        world_to_animation = p24.roots.world_to_animation,
        board = {
            bodies = t6,
            skeleton_board = v39[1],
            truck_frames = v38,
            deck_wobble_tilt = p23.deck_wobble.tilt,
            deck_wobble_squish = p23.deck_wobble.squish,
            average_compression = p29
        }
    }, p30, p31)
end

function t1.SkeletonOutput.publish_owned_globals(p32, p33, p34, p35, p36, p37, p38, p39, p40) -- line: 331
    -- upvalues: rt (copy), BodyId (copy), SkeletonOutput (copy), steering_truck_transforms (copy), to_matrix (ref), body_matrix (copy)
    local t7 = {
        body_matrix(p35, BodyId.ORDER[1]),
        body_matrix(p35, BodyId.ORDER[2]),
        body_matrix(p35, BodyId.ORDER[3]),
        body_matrix(p35, BodyId.ORDER[4]),
        body_matrix(p35, BodyId.ORDER[5]),
        body_matrix(p35, BodyId.ORDER[6])
    }
    local v40 = rt.map(steering_truck_transforms(p36, p37), to_matrix)
    local pose = p34.record.pose
    local v41 = table.create(24)

    for i = 1, 24 do
        v41[i] = pose[i]
    end

    SkeletonOutput.publish_owned_globals(p32.pose, {
        physical_parts = v41,
        world_to_animation = p33.roots.world_to_animation,
        board = {
            bodies = t7,
            skeleton_board = v41[1],
            truck_frames = v40,
            deck_wobble_tilt = p32.deck_wobble.tilt,
            deck_wobble_squish = p32.deck_wobble.squish,
            average_compression = p38
        }
    }, p39, p40)
end

local v42 = table.create(6)

for i = 1, 6 do
    v42[i] = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }
end

local v43 = table.create(2)

for i = 1, 2 do
    v43[i] = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }
end

local t8 = {
    skeleton_board = nil,
    deck_wobble_tilt = 0,
    deck_wobble_squish = 0,
    average_compression = nil,
    bodies = v42,
    truck_frames = v43
}
local t9 = {
    physical_parts = nil,
    world_to_animation = nil,
    board = t8
}

function t1.SkeletonOutput.publish_owned(p41, p42, p43, p44, p45, p46, p47, p48, p49) -- line: 430
    -- upvalues: BodyId (copy), SkeletonOutput (copy), steering_truck_transforms (copy), v42 (copy), v43 (copy), t8 (copy), t9 (copy)
    local bodies = p44.bodies

    for i = 1, 6 do
        local rates = bodies[BodyId.index(BodyId.ORDER[i]) + 1].rates
        local columns = rates.basis.columns
        local v44 = columns[1]
        local v45 = columns[2]
        local v46 = columns[3]
        local position = rates.position
        local v47 = v42[i]
        local v48 = v47[1]
        local v49 = v44[1]
        local v50 = v44[2]
        local v51 = v44[3]

        v48[1] = v49
        v48[2] = v50
        v48[3] = v51
        v48[4] = 0

        local v52 = v47[2]
        local v53 = v45[1]
        local v54 = v45[2]
        local v55 = v45[3]

        v52[1] = v53
        v52[2] = v54
        v52[3] = v55
        v52[4] = 0

        local v56 = v47[3]
        local v57 = v46[1]
        local v58 = v46[2]
        local v59 = v46[3]

        v56[1] = v57
        v56[2] = v58
        v56[3] = v59
        v56[4] = 0

        local v60 = v47[4]
        local x, y, z = position.x, position.y, position.z

        v60[1] = x
        v60[2] = y
        v60[3] = z
        v60[4] = 0
    end

    local v61 = steering_truck_transforms(p45, p46)

    for i = 1, 2 do
        local v62 = v61[i]
        local columns = v62.basis.columns
        local v63 = columns[1]
        local v64 = columns[2]
        local v65 = columns[3]
        local translation = v62.translation
        local v66 = v43[i]
        local v67 = v66[1]
        local v68 = v63[1]
        local v69 = v63[2]
        local v70 = v63[3]

        v67[1] = v68
        v67[2] = v69
        v67[3] = v70
        v67[4] = 0

        local v71 = v66[2]
        local v72 = v64[1]
        local v73 = v64[2]
        local v74 = v64[3]

        v71[1] = v72
        v71[2] = v73
        v71[3] = v74
        v71[4] = 0

        local v75 = v66[3]
        local v76 = v65[1]
        local v77 = v65[2]
        local v78 = v65[3]

        v75[1] = v76
        v75[2] = v77
        v75[3] = v78
        v75[4] = 0

        local v79 = v66[4]
        local x, y, z = translation.x, translation.y, translation.z

        v79[1] = x
        v79[2] = y
        v79[3] = z
        v79[4] = 0
    end

    local pose = p43.record.pose

    t8.skeleton_board = pose[1]
    t8.deck_wobble_tilt = p41.deck_wobble.tilt
    t8.deck_wobble_squish = p41.deck_wobble.squish
    t8.average_compression = p47
    t9.physical_parts = pose
    t9.world_to_animation = p42.roots.world_to_animation
    SkeletonOutput.publish_owned(p41.pose, t9, p48, p49)
    t8.skeleton_board = nil
    t8.average_compression = nil
    t9.physical_parts = nil
    t9.world_to_animation = nil
end

function t1.SkeletonOutput.publish_reference(p50, p51, p52, p53, p54, p55, p56, p57, p58) -- line: 503
    -- upvalues: rt (copy), BodyId (copy), BoardRuntime (copy), SkeletonOutput (copy), steering_truck_transforms (copy), to_matrix (ref)
    local t10 = {
        to_matrix(BoardRuntime.body_transform(p53, BodyId.ORDER[1])),
        to_matrix(BoardRuntime.body_transform(p53, BodyId.ORDER[2])),
        to_matrix(BoardRuntime.body_transform(p53, BodyId.ORDER[3])),
        to_matrix(BoardRuntime.body_transform(p53, BodyId.ORDER[4])),
        to_matrix(BoardRuntime.body_transform(p53, BodyId.ORDER[5])),
        to_matrix(BoardRuntime.body_transform(p53, BodyId.ORDER[6]))
    }
    local v80 = rt.map(steering_truck_transforms(p54, p55), to_matrix)
    local v81 = rt.from_fn(24, function(p59) -- line: 523
        -- upvalues: p52 (copy), rt (copy)
        return rt.copy(p52.record.pose[p59 + 1])
    end)

    SkeletonOutput.publish(p50.pose, {
        physical_parts = v81,
        world_to_animation = p51.roots.world_to_animation,
        board = {
            bodies = t10,
            skeleton_board = v81[1],
            truck_frames = v80,
            deck_wobble_tilt = p50.deck_wobble.tilt,
            deck_wobble_squish = p50.deck_wobble.squish,
            average_compression = p56
        }
    }, p57, p58)
end

function to_matrix(p60) -- line: 544
    local columns = p60.basis.columns
    local v82 = columns[1]
    local v83 = columns[2]
    local v84 = columns[3]
    local translation = p60.translation

    return {
        {
            v82[1],
            v82[2],
            v82[3],
            0
        },
        {
            v83[1],
            v83[2],
            v83[3],
            0
        },
        {
            v84[1],
            v84[2],
            v84[3],
            0
        },
        {
            translation.x,
            translation.y,
            translation.z,
            0
        }
    }
end

t1.to_matrix = to_matrix

function t1.to_matrix_reference(p61) -- line: 561
    -- upvalues: rt (copy)
    local v85 = rt.filled(4, table.create(4, 0))

    for i = 0, 2 do
        local v86 = p61.basis.columns[i + 1]

        v85[i + 1][1] = v86[1]
        v85[i + 1][2] = v86[2]
        v85[i + 1][3] = v86[3]
    end

    v85[4] = {
        p61.translation.x,
        p61.translation.y,
        p61.translation.z,
        0
    }

    return v85
end

return t1
