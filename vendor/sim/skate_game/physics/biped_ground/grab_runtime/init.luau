-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/biped_ground/grab_runtime/selection")
local v2 = import("skate_core/player/offboard/grab_scene")
local Record, closest_point = v2.Record, v2.closest_point

local function grab_scene() -- line: 18
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/grab_scene")
end

local t1 = {
    Owner = {}
}
local Owner = t1.Owner

function t1.Owner.default() -- line: 44
    return {
        query_result = nil,
        validation = nil,
        interactable_request = nil,
        interactable_result = nil,
        interactable_latched = false,
        flags_12836 = 0,
        queries = {},
        pending = {},
        validated = {},
        requests = {},
        data = {},
        data_ready = { false, false },
        query_position = { 0, 0, 0, 0 },
        validation_position = { 0, 0, 0, 0 }
    }
end

t1.Publication = {}

local validate

function t1.Owner.query(p1, p2) -- line: 73
    -- upvalues: rt (copy)
    p1.query_position = rt.copy(p2.position)
    p1.query_result = nil
    table.insert(p1.queries, p2)
end

function t1.Owner.request_primary(p3, p4) -- line: 79
    p3.requests[1] = p4
    p3.data[1] = nil
    p3.data_ready[1] = false
end

function t1.Owner.request_interactable(p5, p6, p7) -- line: 86
    -- upvalues: rt (copy)
    local v3 = rt.from_fn(5, function(p8) -- line: 87
        -- upvalues: p6 (copy), p7 (copy), rt (copy)
        local v4 = rt.copy(p6[4])

        v4[2] += p8 * 0.35999998450279236

        return {
            start = v4,
            ["end"] = {
                p6[3][1] * 2 + v4[1],
                p6[3][2] * 2 + v4[2],
                p6[3][3] * 2 + v4[3],
                p6[3][4] * 2 + v4[4]
            },
            radius = 0.2,
            group = p7.matching_id_2952,
            reject_flags = 0,
            source_pool_mask = 2,
            selection_flags = p7.selection_flags_2948
        }
    end)

    if p5.interactable_request == nil then
        p5.interactable_request = v3
    end

    p5.interactable_result = nil
end

function t1.Owner.execute_queries(p9, p10) -- line: 115
    -- upvalues: rt (copy), import (copy)
    local Scene = import("skate_game/physics/offboard/grab_scene").Scene

    for _, v5 in ipairs(p9.queries) do
        p9.query_result = Scene.query(p10, v5)
    end

    table.clear(p9.queries)

    local v6 = p9.requests[1]

    p9.requests[1] = nil

    if v6 ~= nil then
        p9.data[1] = Scene.resolve(p10, v6)
        p9.data_ready[1] = true
    end

    local v7 = p9.requests[2]

    p9.requests[2] = nil

    if v7 ~= nil then
        p9.data[2] = Scene.resolve(p10, v7)
        p9.data_ready[2] = true
    end

    local interactable_request = p9.interactable_request

    p9.interactable_request = nil

    if interactable_request == nil then
        return
    end

    local v8 = rt.F32_MAX
    local v9

    for i = 1, 5 do
        local v10 = interactable_request[i]
        local v11 = Scene.line(p10, v10)

        if v11 ~= nil and v11.fraction ~= 0 and v11.fraction < v8 and v11.assembly ~= nil then
            local v12 = Scene.eligible_object(p10, v11)

            if v12 ~= nil then
                v9 = v12
                v8 = v11.fraction
            end
        end
    end

    p9.interactable_result = {
        tag = "Some",
        v9
    }
end

function t1.Owner.sync(p11, p12, p13) -- line: 153
    -- upvalues: rt (copy), import (copy), Record (copy), closest_point (copy), validate (ref)
    local Scene = import("skate_game/physics/offboard/grab_scene").Scene

    p11.flags_12836 = bit32.band(p11.flags_12836, 191)

    local validation = p11.validation

    p11.validation = nil

    if validation ~= nil then
        if bit32.band(p11.flags_12836, 128) ~= 0 then
            validate(p11.pending, validation)

            local query_result = p11.query_result

            if query_result ~= nil then
                for i = 1, #p11.pending do
                    local v13

                    for _, v14 in ipairs(query_result) do
                        if Record.descriptor(v14).kind == Record.descriptor(p11.pending[i]).kind and Record.descriptor(v14).id == Record.descriptor(p11.pending[i]).id then
                            v13 = v14
                            break
                        end
                    end

                    if v13 ~= nil then
                        p11.pending[i] = rt.copy(v13)
                    end
                end
            end
        end

        p11.validated = rt.copy(p11.pending)
        p11.flags_12836 = bit32.bor(bit32.band(bit32.rshift(p11.flags_12836, 1), 64), (bit32.band(p11.flags_12836, 63)))
        p11.validation_position = { 0, 0, 0, 0 }
    end

    local query_result = p11.query_result

    p11.query_result = nil

    if query_result == nil then
        return
    end

    local t2 = {}

    for i = 1, math.min(#query_result, 5) do
        t2[i] = query_result[i]
    end

    p11.pending = t2
    p11.validation_position = rt.copy(p11.query_position)
    p11.query_position = { 0, 0, 0, 0 }
    p11.flags_12836 = bit32.bor(p11.flags_12836, 128)

    local t3 = {}
    local n1 = 0

    for _, v19 in ipairs(p11.pending) do
        local v20 = closest_point(rt.copy(p11.validation_position), Record.endpoints(v19))
        local v21 = rt.copy(p11.validation_position)
        local v22 = v21[2] - 0.4000000059604645

        for _ = 1, 3 do
            v21[2] = v22
            v20[2] = v22
            n1 += 1
            t3[n1] = Scene.line(p12, {
                start = rt.copy(v21),
                ["end"] = rt.copy(v20),
                radius = 0.2,
                group = p13.matching_id_2952,
                reject_flags = 0,
                source_pool_mask = 7,
                selection_flags = p13.selection_flags_2948
            })
            v22 += 0.4000000059604645
        end
    end

    p11.validation = t3
end

function t1.Owner.best(p14, p15) -- line: 228
    -- upvalues: v1 (copy)
    return v1.best(p14.validated, p15)
end

function t1.Owner.invalidate(p16) -- line: 234
    table.clear(p16.queries)
    p16.query_result = nil
    p16.validation = nil
    p16.data_ready = { false, false }
    p16.flags_12836 = bit32.band(p16.flags_12836, 63)
end

function t1.Owner.enter_reset(p17) -- line: 243
    -- upvalues: Owner (copy)
    Owner.invalidate(p17)
    p17.interactable_result = nil
end

function t1.Owner.publish(p18) -- line: 250
    -- upvalues: rt (copy), Record (copy)
    local t4 = {}

    for i = 0, 1 do
        local v23

        if p18.data_ready[i + 1] then
            local v24 = p18.data[i + 1]

            if v24 ~= nil and Record.valid(v24) then
                v23 = rt.copy(v24)
            end
        end

        p18.data_ready[i + 1] = false
        t4[i + 1] = v23
    end

    local interactable_result = p18.interactable_result

    p18.interactable_result = nil

    if interactable_result ~= nil then
        p18.interactable_latched = interactable_result[1] ~= nil
    end

    return {
        records = t4,
        object = interactable_result
    }
end

function t1.validate(p19, p20) -- line: 274
    -- upvalues: Record (copy)
    local n2 = 0
    local n3 = 0

    while n2 < #p19 do
        local v25 = Record.assembly(p19[n2 + 1])
        local v26 = false

        for _ = 1, 3 do
            local v27 = p20[n3 + 1]
            local v28 = if v27 == nil then v26 else v27.assembly == nil or v25 ~= nil and v27.assembly ~= v25

            n3 += 1

            if v28 then
                v26 = v28
                break
            end

            v26 = v28
        end

        if v26 then
            local v29 = #p19

            p19[n2 + 1] = p19[v29]
            p19[v29] = nil
        else
            n2 += 1
        end
    end
end

validate = t1.validate

return t1
