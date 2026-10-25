-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/shot")
local v2 = import("skate_core/camera/positioner")
local v3 = import("skate_core/camera/vector_tracker")
local v4 = import("skate_core/camera/manager_state")
local v5 = import("skate_core/trigonometry")
local Shot, blend_interval, blend_interval_lanes, filter_blend_value = v1.Shot, v1.blend_interval, v1.blend_interval_lanes, v1.filter_blend_value
local position_from_angles = v2.position_from_angles

local function eq_ignore_ascii_case(p1, p2) -- line: 20
    return string.lower(p1) == string.lower(p2)
end

local PERF = import("skate_core/camera/tracker").PERF
local t1 = {}

t1.ShotDefinition = {}

function t1.ShotDefinition.initial() -- line: 36
    -- upvalues: Shot (copy)
    return {
        name = "",
        shot_type = 0,
        transition_time = 0.5,
        transition_units = 0,
        blend_value = 0,
        blend_type = 0,
        blend_smoothing = 0,
        shot = Shot.new(),
        children = { nil, nil, nil },
        blend_points = { 0, 0, 0 }
    }
end

t1.ShotDatabase = {}
t1.ShotEnvironment = {}
t1.ShotPlacement = {}
t1.ShotNode = {}

function t1.ShotNode.new(p3) -- line: 67
    return {
        definition = p3,
        children = {}
    }
end

function t1.ShotNode.setup(p4, p5, p6, p7, p8) -- line: 76
    -- upvalues: rt (copy), t1 (copy)
    if p4.definition.shot_type ~= 1 then
        return p8
    end

    table.insert(p7, p4.definition.name)

    local v6 = p8

    for i = 0, 2 do
        local v7 = p4.definition.children[i + 1]

        if v7 == nil then
            break
        end

        for _, v8 in ipairs(p7) do
            if string.lower(v8) == string.lower(v7) then
                error(("Cyclic stock camera shot %*"):format(v7), 0)
            end
        end

        local v9 = v6 + 1

        if v9 > 64 then
            error("Stock camera shot exceeds its 64-child capacity", 0)
        end

        local v10 = t1.ShotNode.new(rt.copy(p5.load(p5, v7)))

        v6 = t1.ShotNode.setup(v10, p5, p6, p7, v9)
        table.insert(p4.children, v10)
    end

    table.remove(p7)
    p4.definition.blend_value = p6.raw_blend_value(p6, p4.definition.blend_type, p4.definition.blend_value, 0)

    return v6
end

function t1.ShotNode.update(p9, p10, p11) -- line: 114
    -- upvalues: v5 (copy), Shot (copy), blend_interval_lanes (copy), filter_blend_value (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.ShotNode.update_reference(p9, p10, p11)
    end

    local definition = p9.definition

    if definition.shot_type == 0 then
        local compass_north = definition.shot.compass_north

        if compass_north == 6 and p11.special_camera_flag(p11) then
            compass_north = 5
        end

        local v11 = p11.compass_north(p11, compass_north)
        local v12 = p11.heading_mirror(p11)

        Shot.update_normal(p9.definition.shot, v11, v12)
    else
        local children = p9.children

        if #children ~= 0 then
            local v13 = p11.raw_blend_value(p11, definition.blend_type, definition.blend_value, p10)
            local blend_points = definition.blend_points
            local v14 = #children

            definition.blend_value = filter_blend_value(definition.blend_value, v13, definition.blend_smoothing, blend_points[1], blend_points[v14])

            local v15, v16, v17 = blend_interval_lanes(blend_points, v14, definition.blend_value)

            if v15 ~= nil then
                local v18 = v5.sin(v17 * 3.1415927410125732 - 1.5707963705062866) * 0.5 + 0.5
                local v19 = children[v15 + 1]
                local v20 = children[v16 + 1]

                t1.ShotNode.update(v19, p10, p11)
                t1.ShotNode.update(v20, p10, p11)
                Shot.interpolate_from(definition.shot, v19.definition.shot, v20.definition.shot, v18)
            end
        end
    end
end

function t1.ShotNode.update_reference(p12, p13, p14) -- line: 155
    -- upvalues: rt (copy), v5 (copy), Shot (copy), blend_interval (copy), filter_blend_value (copy), t1 (copy)
    if p12.definition.shot_type == 0 then
        local compass_north = p12.definition.shot.compass_north

        if compass_north == 6 and p14.special_camera_flag(p14) then
            compass_north = 5
        end

        local v21 = p14.compass_north(p14, compass_north)
        local v22 = p14.heading_mirror(p14)

        Shot.update_normal(p12.definition.shot, v21, v22)
    else
        local definition = p12.definition

        if #p12.children ~= 0 then
            local v23 = p14.raw_blend_value(p14, definition.blend_type, definition.blend_value, p13)

            definition.blend_value = filter_blend_value(definition.blend_value, v23, definition.blend_smoothing, definition.blend_points[1], definition.blend_points[#p12.children])

            local v27 = blend_interval(definition.blend_points, {
                #p12.children > 0,
                #p12.children > 1,
                #p12.children > 2
            }, definition.blend_value)

            if v27 ~= nil then
                local v28 = v27[1]
                local v29 = v27[2]
                local v30 = v27[3]
                local v31 = v5.sin(v30 * 3.1415927410125732 - 1.5707963705062866) * 0.5 + 0.5

                t1.ShotNode.update_reference(p12.children[v28 + 1], p13, p14)
                t1.ShotNode.update_reference(p12.children[v29 + 1], p13, p14)
                Shot.interpolate_from(definition.shot, rt.copy(p12.children[v28 + 1].definition.shot), rt.copy(p12.children[v29 + 1].definition.shot), v31)
            end
        end
    end
end

t1.ShotManager = {}

function t1.ShotManager.new() -- line: 208
    -- upvalues: Shot (copy), t1 (copy)
    return {
        elapsed = 0,
        transition_distance = 0,
        transition_duration = 0,
        transition_override = -1,
        instant_changes = false,
        current = t1.ShotNode.new(t1.ShotDefinition.initial()),
        previous = Shot.new(),
        interpolated = Shot.new()
    }
end

function t1.ShotManager.current(p15) -- line: 222
    return p15.current.definition
end

function t1.ShotManager.apply_graph_transition(p16, p17, p18) -- line: 228
    if p17 >= 0 then
        p16.current.definition.transition_time = p17
    elseif p16.transition_override >= 0 then
        p16.current.definition.transition_time = p16.transition_override
    end

    if p18 >= 0 then
        p16.transition_override = p18
    else
        p16.transition_override = -1
    end
end

function t1.ShotManager.first_leaf(p19) -- line: 238
    -- upvalues: rt (copy)
    local v32 = p19.current

    while true do
        local v33 = v32.children[1]

        if v33 == nil then
            break
        end

        v32 = v33
    end

    return rt.copy(v32.definition.shot)
end

function t1.ShotManager.set_shot(p20, p21, p22, p23, p24, p25) -- line: 251
    -- upvalues: rt (copy), v3 (copy), position_from_angles (copy), t1 (copy)
    if not p22 then
        local name = p20.current.definition.name

        if string.lower(name) == string.lower(p21) then
            return false
        end
    end

    local v34 = t1.ShotNode.new(rt.copy(p23.load(p23, p21)))

    p20.previous = rt.copy(p20.interpolated)

    if v34.definition.shot.use_previous_shot ~= 0 then
        local shot = v34.definition.shot

        shot.distance = p20.interpolated.distance
        shot.lens_length = p20.interpolated.lens_length
        shot.position_heading = p20.interpolated.position_heading
        shot.position_elevation = p20.interpolated.position_elevation
        shot.framing = rt.copy(p20.interpolated.framing)
        shot.arm_orientation = rt.copy(p20.interpolated.arm_orientation)
    end

    p20.current = v34

    if p20.instant_changes then
        t1.ShotManager.make_instant(p20)
    else
        p20.elapsed = 0
    end

    t1.ShotNode.setup(p20.current, p23, p24, {}, 0)

    local v35 = rt.copy(p20.current.definition.shot)
    local v36 = position_from_angles(p25.anchor, { 0, 0, 0, 0 }, v35.position_elevation, v35.position_heading, v35.distance, p25.clamp_height, p25.floor_height)
    local t3 = {}

    t3[1] = v36[1] - p25.camera_position[1]
    t3[2] = v36[2] - p25.camera_position[2]
    t3[3] = v36[3] - p25.camera_position[3]
    t3[4] = v36[4] - p25.camera_position[4]
    p20.transition_distance = v3.length(t3)

    return true
end

function t1.ShotManager.update(p26, p27, p28) -- line: 297
    -- upvalues: Shot (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.ShotManager.update_reference(p26, p27, p28)
    end

    p26.elapsed = p27 + p26.elapsed
    t1.ShotNode.update(p26.current, p27, p28)
    p26.transition_duration = t1.ShotManager.duration(p26, false)

    local v37 = if p26.transition_duration <= 0 then 1 else p26.elapsed / p26.transition_duration

    if -v37 >= 0 then
        v37 = 0
    end

    if not (1 - v37 >= 0) then
        v37 = 1
    end

    Shot.interpolate_from(p26.interpolated, p26.previous, p26.current.definition.shot, v37)

    return v37
end

function t1.ShotManager.update_reference(p29, p30, p31) -- line: 316
    -- upvalues: rt (copy), Shot (copy), t1 (copy)
    p29.elapsed = p30 + p29.elapsed
    t1.ShotNode.update_reference(p29.current, p30, p31)
    p29.transition_duration = t1.ShotManager.duration(p29, false)

    local v38 = if p29.transition_duration <= 0 then 1 else p29.elapsed / p29.transition_duration

    if -v38 >= 0 then
        v38 = 0
    end

    if not (1 - v38 >= 0) then
        v38 = 1
    end

    Shot.interpolate_from(p29.interpolated, rt.copy(p29.previous), rt.copy(p29.current.definition.shot), v38)

    return v38
end

function t1.ShotManager.make_instant(p32) -- line: 337
    -- upvalues: t1 (copy)
    p32.transition_override = -1
    p32.elapsed = t1.ShotManager.duration(p32, false)
end

function t1.ShotManager.is_transitioning(p33) -- line: 344
    -- upvalues: t1 (copy)
    return p33.elapsed < t1.ShotManager.duration(p33, true)
end

function t1.ShotManager.framing_fraction(p34) -- line: 349
    -- upvalues: v4 (copy), v5 (copy), t1 (copy)
    local v39 = t1.ShotManager.duration(p34, true)

    if v39 <= 0 then
        return 1
    end

    local v40 = v4.clamp(p34.elapsed / v39, 0, 1)

    return v5.sin(v40 * 3.1415927410125732 + -1.5707963705062866) * 0.5 + 0.5
end

function t1.ShotManager.duration(p35, p36) -- line: 358
    local definition = p35.current.definition

    if definition.transition_units == 1 then
        return definition.transition_time * 0.01666666753590107
    end

    if definition.transition_units ~= 2 then
        return definition.transition_time
    end

    local v41 = if not (p36 and definition.transition_time <= 0) then definition.transition_time else 9.999999747378752E-05

    return p35.transition_distance / v41
end

return t1
