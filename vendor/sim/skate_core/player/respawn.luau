-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local IDENTITY = require(sim.import)("skate_core/physics/skeleton_animation_record").IDENTITY
local t1 = {
    Candidate = {},
    Validation = {},
    Ground = {},
    Observation = {},
    History = {}
}
local History = t1.History

function t1.History.new(p1) -- line: 58
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        cooldown = 20,
        initial = rt.copy(p1),
        entries = { rt.copy(p1) },
        current_orientation = rt.copy(IDENTITY),
        current_position = rt.copy(p1.transform[4])
    }
end

function t1.History.observe(p2, p3, p4, p5) -- line: 71
    -- upvalues: rt (copy), t1 (copy), History (copy)
    p2.current_position = rt.copy(p3.com_position)

    if History.recording_due(p2, p3.measurements, p3.root_position) and not p3.teleport_requested then
        local v1, v2, v3

        if p3.physical_state == 100 or p3.physical_state == 104 then
            p2.current_orientation = rt.copy(p3.riding_transform)

            if p3.state_frames <= p4 or p3.ground_suppressed or not t1.surface_allowed(p3.ground_category) then
                return
            end

            v1 = rt.copy(p3.riding_transform)
            v2 = p3.ground_category == 8
            v3 = t1.surface_score(p3.ground_category)
        else
            if p3.physical_state ~= 500 and p3.physical_state ~= 502 or p3.state_frames <= p4 or p3.offboard_correction then
                return
            end

            v1 = rt.copy(p3.offboard_transform)
            v2 = true
            v3 = rt.fmax(t1.surface_score(p3.foot_categories[1]), t1.surface_score(p3.foot_categories[2]))
        end

        if p5.location(p5, v1) and p5.edges(p5, v1) and (p3.alternate_world or p5.ground(p5, v1) ~= nil) then
            History.insert(p2, {
                transform = v1,
                stance = p3.stance,
                offboard = v2,
                score = v3
            })
        end
    end
end

function t1.History.recording_due(p6, p7, p8) -- line: 118
    -- upvalues: t1 (copy)
    local v4 = p7 >= 120

    if not v4 then
        p6.cooldown = 0
    end

    if p6.cooldown > 0 then
        p6.cooldown -= 1
        v4 = false
    end

    if not v4 then
        return false
    end

    local v5 = #p6.entries - 1
    local v6 = false

    for i = v5, 0, -1 do
        local v7 = p6.entries[i + 1]

        if t1.distance_squared(v7.transform[4], p8) < 2.25 then
            v6 = true
            break
        end
    end

    return not v6
end

function t1.History.insert(p9, p10) -- line: 142
    -- upvalues: rt (copy)
    if #p9.entries == 32 then
        table.remove(p9.entries, 1)
    end

    table.insert(p9.entries, rt.copy(p10))
    p9.cooldown = 20
end

function t1.History.pop_best(p11) -- line: 154
    local v8 = #p11.entries - 1
    local n1 = -99990
    local n2 = 0
    local v9

    for i = v8, 0, -1 do
        local score = p11.entries[i + 1].score

        if n2 < 1 then
            score -= 100
        end

        if n2 > 5 then
            score -= 200
        end

        if n1 < score then
            n1 = score
            v9 = i
        end

        n2 += 1
    end

    if v9 == nil then
        return nil
    end

    return table.remove(p11.entries, v9 + 1)
end

function t1.History.automatic(p12, p13, p14) -- line: 181
    -- upvalues: rt (copy), History (copy)
    local v10 = rt.copy(p12.current_orientation)

    v10[4] = rt.copy(p12.current_position)

    local v11 = p14.ground(p14, v10)

    if v11 ~= nil and p14.location(p14, v10) and p14.occupants(p14, v10) and p14.edges(p14, v10) then
        if v11.offboard then
            v10[4][2] = v11.position[2]
        end

        return {
            score = 0,
            transform = v10,
            stance = p13,
            offboard = v11.offboard
        }
    end

    while true do
        local v12 = History.pop_best(p12)

        if v12 == nil then
            break
        end

        if not (p14.location(p14, v12.transform) and p14.occupants(p14, v12.transform)) then
            continue
        end

        return v12
    end

    local v13 = p12.entries[#p12.entries]

    if v13 == nil then
        return {
            offboard = false,
            score = 0,
            transform = rt.copy(p12.initial.transform),
            stance = p13
        }
    end

    return rt.copy(v13)
end

function t1.surface_allowed(p15) -- line: 221
    return not (p15 == 5 or p15 == 6 or p15 == 9 or p15 == 12 or p15 == 13)
end

function t1.surface_score(p16) -- line: 226
    if p16 == 1 or p16 == 2 then
        return 100
    end

    if p16 == 3 or p16 == 4 then
        return 50
    end

    if p16 == 11 then
        return 20
    end

    return 0
end

function t1.distance_squared(p17, p18) -- line: 238
    return (p17[1] - p18[1]) ^ 2 + (p17[2] - p18[2]) ^ 2 + (p17[3] - p18[3]) ^ 2
end

return t1
