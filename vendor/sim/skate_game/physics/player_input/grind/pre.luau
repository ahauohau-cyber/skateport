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

local function parent() -- line: 16
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind")
end

local v2 = import("skate_core/physics/grind_contact/investigator")
local v3 = import("skate_core/physics/grind_contact/manager")
local v4 = import("skate_core/air/trajectory/grind_surface")
local v5 = import("skate_core/player/input_phase")
local GrindInvestigationFields, copy_into = v5.GrindInvestigationFields, v5.copy_into
local assign_into = GrindInvestigationFields.assign_into
local PointGraph = import("skate_core/point_graph").PointGraph
local StaticProvider = import("skate_game/grind_world").StaticProvider
local v6 = false
local t1 = {}

function t1.set_reference(p2) -- line: 33
    -- upvalues: v6 (ref)
    v6 = p2
end

local v7 = v5.freeze_deep(GrindInvestigationFields.default())
local self = setmetatable({}, {
    __mode = "k"
})
local t4 = {
    0, 0, 0, 0
}

t1.GrindInputState = {}

function t1.GrindInputState.pre_update(p3, p4, p5, p6, p7, p8) -- line: 68
    -- upvalues: rt (copy), v1 (copy), import (copy), v2 (copy), v3 (copy), v4 (copy), GrindInvestigationFields (copy), copy_into (copy), assign_into (copy), PointGraph (copy), StaticProvider (copy), t1 (copy), v6 (ref), v7 (copy), self (copy), t4 (copy)
    local GrindInputState, float, raw, v9, v10

    if v6 then
        v10 = true
    elseif type(p3.investigation) == "table" then
        local v11 = import("skate_game/physics/player_input/grind")

        GrindInputState = v11.GrindInputState
        float = v11.float
        raw = v11.raw

        local direction_1136 = p3.investigation.direction_1136

        buffer.writeu32(v1, 0, direction_1136[1])

        local v13 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, direction_1136[2])

        local v15 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, direction_1136[3])

        local v17 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, direction_1136[4])

        local v19 = buffer.readf32(v1, 0)

        t4[1] = v13
        t4[2] = v15
        t4[3] = v17
        t4[4] = v19
        copy_into(p3, "previous_direction", t4)
        assign_into(p3.investigation, v7)
        GrindInputState.permission(p3, p4, p7.air_counter)

        if bit32.band(p4.flags_2476, 16777216) == 0 then
            v9 = StaticProvider.query(p5, {
                p7.board[4][1] - 1.2,
                p7.board[4][2] - 1.2,
                p7.board[4][3] - 1.2
            }, {
                p7.board[4][1] + 1.2,
                p7.board[4][2] + 1.2,
                p7.board[4][3] + 1.2
            })
        else
            v9 = {}
        end

        v10 = false
    else
        v10 = true
    end

    if v10 then
        return t1.GrindInputState.pre_update_reference(p3, p4, p5, p6, p7, p8)
    end

    local v20 = GrindInputState.material_mode(p3, p4, #v9 ~= 0, p7.air_targeting_grind_9653)

    p8.apply_material_mode(p8, v20)
    GrindInputState.advance_history(p3, p4)

    local v21 = table.create(#v9)

    for v22, v23 in v9 do
        v21[v22] = rt.copy(StaticProvider.primitives(p5)[v23 + 1])
    end

    local investigate = v2.investigate
    local t5 = {
        board = rt.copy(p7.board),
        admission = {
            category = p4.category_2512,
            state = p4.state_2508,
            speed = p4.scalar_2652,
            velocity = float(p4.vectors_400_416[1]),
            threshold_vs_slope = p3.settings.slope_threshold
        },
        flags_2468 = p4.flags_2468,
        flags_2472 = p4.flags_2472,
        flags_2476 = p4.flags_2476,
        flags_2484 = p4.flags_2484,
        tip_state = p7.tip_state,
        truck_to_wheel = p3.settings.truck_to_wheel,
        deck_to_truck = p3.settings.deck_to_truck,
        test_above = p3.settings.test_above,
        test_below = p3.settings.test_below,
        translation = p7.translation_2796,
        stability_nudge = p7.stability_nudge_2800,
        balance = p7.balance_2720,
        reference_right = float(p4.vectors_464_480_496_512_528[1]),
        ground_frames = p3.grounded_frames,
        low_wheel_frames = p3.low_wheel_frames
    }
    local disabled = p3.disabled

    if not disabled then
        disabled = p3.grind_history ~= 0 and p4.grind_words_2532_2536[2] ~= 2
    end

    t5.forbidden = disabled

    local v24 = investigate(t5, v21)
    local v25 = self[p3]

    if v25 ~= nil then
        assign_into(v25, v7)
    else
        v25 = GrindInvestigationFields.default()
        self[p3] = v25
    end

    local t6, t7

    if v24.candidate ~= nil then
        local candidate = v24.candidate
        local geometry = candidate.geometry
        local v29 = v21[geometry.primitive + 1]
        local v30 = StaticProvider.metadata(p5, v9[geometry.primitive + 1])

        if v30 == nil then
            error("Selected static grind primitive lacks metadata", 0)
        end

        t6 = {
            spline_guids = rt.copy(v30.spline_guids)
        }
        v25.valid_1488 = true
        v25.family_1248 = candidate.kind
        v25.entry_kind_1252 = candidate.entry_kind
        v25.tangent_1104 = raw(geometry.direction)
        v25.point_1120 = raw(geometry.centre)
        v25.direction_1136 = raw(v3.directed_tangent(rt.copy(v29.start), rt.copy(v29["end"]), float(p4.vectors_400_416[1]), rt.copy(p3.previous_direction)))
        v25.primitive_start_1264 = raw(v29.start)
        v25.primitive_end_1280 = raw(v29["end"])
        v25.owner_1296 = v29.owner
        v25.primitive_flags_1300 = bit32.band(v30.flags, 2147483648)
        v25.flags_1516 = candidate.front and 536870912 or 0

        if candidate.kind == 0 then
            v25.front_contact_1200 = raw(geometry.front)
            v25.rear_contact_1216 = raw(geometry.rear)
        elseif candidate.kind == 3 then
            v25.front_contact_1200 = raw(geometry.centre)
        end

        local t8 = {
            start = rt.copy(v29.start),
            ["end"] = rt.copy(v29["end"]),
            reference = rt.copy(geometry.centre),
            optional_probe = if p4.state_2508 == 402 then rt.copy(p7.board[4]) else nil,
            deck_center_to_truck = p3.settings.deck_to_truck
        }

        t7 = {
            input = t8,
            plan = v4.prepare(rt.copy(t8)),
            hits = {}
        }
    else
        p3.previous_proximity = v24.proximity ~= nil

        if v24.proximity ~= nil then
            local proximity = v24.proximity
            local v26 = v21[proximity.contact.primitive + 1]
            local v27 = StaticProvider.metadata(p5, v9[proximity.contact.primitive + 1])

            if v27 == nil then
                error("Static grind proximity lacks metadata", 0)
            end

            v25.vector_1232 = raw(proximity.contact.position)
            v25.second_start_1312 = raw(v26.start)
            v25.second_end_1328 = raw(v26["end"])
            v25.second_owner_1344 = v26.owner
            v25.second_flags_1348 = bit32.band(v27.flags, 2147483648)
            v25.flags_1516 = bit32.bor(134217728, proximity.deck_contact and 67108864 or 0)
        end
    end

    copy_into(p3, "previous_velocity", p4.vectors_400_416[1])
    p3.friction_vs_time = PointGraph.evaluate(p3.settings.friction, p3.elapsed)
    v25.friction_1496 = p3.friction_vs_time
    assign_into(p3.investigation, v25)

    if t7 ~= nil and t7.plan ~= nil then
        local plan = t7.plan

        for i = 0, #plan.probes - 1 do
            local v31 = rt.copy(plan.probes[i + 1])

            t7.hits[i + 1] = p8.surface_probe(p8, p6, {
                p4.actor_query_2948,
                p4.actor_query_2952
            }, i, v31)
        end
    end

    return {
        fields = v25,
        geometry = t7,
        metadata = t6
    }
end

function t1.GrindInputState.pre_update_reference(p9, p10, p11, p12, p13, p14) -- line: 235
    -- upvalues: rt (copy), import (copy), v2 (copy), v3 (copy), v4 (copy), GrindInvestigationFields (copy), PointGraph (copy), StaticProvider (copy)
    local v32 = import("skate_game/physics/player_input/grind")
    local GrindInputState, float, raw = v32.GrindInputState, v32.float, v32.raw

    p9.previous_direction = float(p9.investigation.direction_1136)
    p9.investigation = GrindInvestigationFields.default()
    GrindInputState.permission(p9, p10, p13.air_counter)

    local v33 = if bit32.band(p10.flags_2476, 16777216) == 0 then StaticProvider.query(p11, {
        p13.board[4][1] - 1.2,
        p13.board[4][2] - 1.2,
        p13.board[4][3] - 1.2
    }, {
        p13.board[4][1] + 1.2,
        p13.board[4][2] + 1.2,
        p13.board[4][3] + 1.2
    }) else {}
    local v34 = GrindInputState.material_mode(p9, p10, #v33 ~= 0, p13.air_targeting_grind_9653)

    p14.apply_material_mode(p14, v34)
    GrindInputState.advance_history(p9, p10)

    local v35 = table.create(#v33)

    for v36, v37 in v33 do
        v35[v36] = rt.copy(StaticProvider.primitives(p11)[v37 + 1])
    end

    local investigate = v2.investigate
    local t9 = {
        board = rt.copy(p13.board),
        admission = {
            category = p10.category_2512,
            state = p10.state_2508,
            speed = p10.scalar_2652,
            velocity = float(p10.vectors_400_416[1]),
            threshold_vs_slope = p9.settings.slope_threshold
        },
        flags_2468 = p10.flags_2468,
        flags_2472 = p10.flags_2472,
        flags_2476 = p10.flags_2476,
        flags_2484 = p10.flags_2484,
        tip_state = p13.tip_state,
        truck_to_wheel = p9.settings.truck_to_wheel,
        deck_to_truck = p9.settings.deck_to_truck,
        test_above = p9.settings.test_above,
        test_below = p9.settings.test_below,
        translation = p13.translation_2796,
        stability_nudge = p13.stability_nudge_2800,
        balance = p13.balance_2720,
        reference_right = float(p10.vectors_464_480_496_512_528[1]),
        ground_frames = p9.grounded_frames,
        low_wheel_frames = p9.low_wheel_frames
    }
    local disabled = p9.disabled

    if not disabled then
        disabled = p9.grind_history ~= 0 and p10.grind_words_2532_2536[2] ~= 2
    end

    t9.forbidden = disabled

    local v38 = investigate(t9, v35)
    local v39 = GrindInvestigationFields.default()
    local t10, t11

    if v38.candidate ~= nil then
        local candidate = v38.candidate
        local geometry = candidate.geometry
        local v43 = v35[geometry.primitive + 1]
        local v44 = StaticProvider.metadata(p11, v33[geometry.primitive + 1])

        if v44 == nil then
            error("Selected static grind primitive lacks metadata", 0)
        end

        t10 = {
            spline_guids = rt.copy(v44.spline_guids)
        }
        v39.valid_1488 = true
        v39.family_1248 = candidate.kind
        v39.entry_kind_1252 = candidate.entry_kind
        v39.tangent_1104 = raw(geometry.direction)
        v39.point_1120 = raw(geometry.centre)
        v39.direction_1136 = raw(v3.directed_tangent(rt.copy(v43.start), rt.copy(v43["end"]), float(p10.vectors_400_416[1]), rt.copy(p9.previous_direction)))
        v39.primitive_start_1264 = raw(v43.start)
        v39.primitive_end_1280 = raw(v43["end"])
        v39.owner_1296 = v43.owner
        v39.primitive_flags_1300 = bit32.band(v44.flags, 2147483648)
        v39.flags_1516 = candidate.front and 536870912 or 0

        if candidate.kind == 0 then
            v39.front_contact_1200 = raw(geometry.front)
            v39.rear_contact_1216 = raw(geometry.rear)
        elseif candidate.kind == 3 then
            v39.front_contact_1200 = raw(geometry.centre)
        end

        local t12 = {
            start = rt.copy(v43.start),
            ["end"] = rt.copy(v43["end"]),
            reference = rt.copy(geometry.centre),
            optional_probe = if p10.state_2508 == 402 then rt.copy(p13.board[4]) else nil,
            deck_center_to_truck = p9.settings.deck_to_truck
        }

        t11 = {
            input = t12,
            plan = v4.prepare(rt.copy(t12)),
            hits = {}
        }
    else
        p9.previous_proximity = v38.proximity ~= nil

        if v38.proximity ~= nil then
            local proximity = v38.proximity
            local v40 = v35[proximity.contact.primitive + 1]
            local v41 = StaticProvider.metadata(p11, v33[proximity.contact.primitive + 1])

            if v41 == nil then
                error("Static grind proximity lacks metadata", 0)
            end

            v39.vector_1232 = raw(proximity.contact.position)
            v39.second_start_1312 = raw(v40.start)
            v39.second_end_1328 = raw(v40["end"])
            v39.second_owner_1344 = v40.owner
            v39.second_flags_1348 = bit32.band(v41.flags, 2147483648)
            v39.flags_1516 = bit32.bor(134217728, proximity.deck_contact and 67108864 or 0)
        end
    end

    p9.previous_velocity = rt.copy(p10.vectors_400_416[1])
    p9.friction_vs_time = PointGraph.evaluate(p9.settings.friction, p9.elapsed)
    v39.friction_1496 = p9.friction_vs_time
    p9.investigation = rt.copy(v39)

    if t11 ~= nil and t11.plan ~= nil then
        local plan = t11.plan

        for i = 0, #plan.probes - 1 do
            local v45 = rt.copy(plan.probes[i + 1])

            t11.hits[i + 1] = p14.surface_probe(p14, p12, {
                p10.actor_query_2948,
                p10.actor_query_2952
            }, i, v45)
        end
    end

    return {
        fields = v39,
        geometry = t11,
        metadata = t10
    }
end

return t1
