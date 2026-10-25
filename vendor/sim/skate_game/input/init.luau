-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/input/controllers")
local v2 = import("skate_game/input/platform")
local v3 = import("skate_core/input/tick")
local v4 = import("skate_core/input/gameplay_map")
local TickInput = v3.TickInput
local GameplayActions = v4.GameplayActions

local function modding() -- line: 18
    -- upvalues: import (copy)
    return import("skate_game/modding")
end

local t1 = {
    ControllerInput = v1.ControllerInput,
    ControllerStatus = v1.ControllerStatus,
    RawInput = v1.RawInput,
    PublishedTickInput = {}
}

function t1.PublishedTickInput.default() -- line: 33
    -- upvalues: TickInput (copy), GameplayActions (copy)
    return { TickInput.new(0, GameplayActions.from_values(table.create(18, 0)), false) }
end

t1.InputPlugin = {}

function t1.poll_controllers(p1, p2, p3, p4, p5, p6) -- line: 50
    -- upvalues: rt (copy), v1 (copy), v2 (copy)
    local v5 = rt.copy(p1.status)

    v1.ControllerInput.collect(p1, rt.from_fn(4, function(p7) -- line: 54
        -- upvalues: p2 (copy), p3 (copy), p4 (copy), p5 (copy), p6 (copy), v2 (copy)
        if p3 and (not p4 and p2 == nil or p2 ~= nil and p2 ~= p7) then
            v2.CapabilityCache.invalidate(p5[p7 + 1])

            return {
                tag = "Err",
                {
                    tag = "Disconnected"
                }
            }
        end

        local poll_cached = v2.poll_cached
        local v6 = p5[p7 + 1]
        local ok, result = pcall(poll_cached, p7, v6, p6)

        if ok then
            return {
                tag = "Ok",
                result
            }
        end

        if type(result) ~= "table" then
            error(result, 0)
        end

        return {
            tag = "Err",
            result
        }
    end))

    for i = 0, #v5 - 1 do
        local v7 = v5[i + 1]
        local v8 = p1.status[i + 1]

        if v1.ControllerStatus.eq(v7, v8) then
        end
    end
end

local v9 = false

function t1.set_reference(p8) -- line: 93
    -- upvalues: v9 (ref)
    v9 = p8
end

function t1.publish_actions(p9, p10, p11, p12, p13) -- line: 107
    -- upvalues: v1 (copy), GameplayActions (copy), t1 (copy), v9 (ref)
    local v10 = p10[1]
    local actions = if type(v10) == "table" then v10.actions else nil
    local values = if type(actions) == "table" then actions.values else nil
    local v11 = true

    if v9 then
    elseif type(values) == "table" and p13 == nil then
        if not p11 or p12 then
            v1.ControllerInput.discard_gameplay(p9)
        end

        v11 = false
    end

    if v11 then
        return t1.publish_actions_reference(p9, p10, p11, p12, p13)
    end

    v1.ControllerInput.publish_actions(p9)

    local v12, v13 = v1.ControllerInput.tick_values_into(p9, values)

    if p12 then
        GameplayActions.zeros_into(values)
    end

    v10.tick = v12
    v10.controller_available = v13

    for v14 in v10 do
        if v14 ~= "tick" and v14 ~= "actions" and v14 ~= "controller_available" then
            v10[v14] = nil
        end
    end

    for v15 in actions do
        if v15 ~= "values" then
            actions[v15] = nil
        end
    end

    if p9.stick_hz ~= nil and not p12 then
        v10.stick_hz = p9.stick_hz
    end
end

function t1.publish_actions_reference(p14, p15, p16, p17, p18) -- line: 146
    -- upvalues: rt (copy), import (copy), v1 (copy), TickInput (copy), GameplayActions (copy)
    local v16 = not p16 or p17

    if v16 then
        v1.ControllerInput.discard_gameplay(p14)
    end

    v1.ControllerInput.publish_actions(p14)

    local v17 = v1.ControllerInput.tick_input(p14)
    local v18 = rt.copy(GameplayActions.values(TickInput.actions(v17)))

    if not v16 and p18 ~= nil then
        import("skate_game/modding").override_actions(p18, v18)
    end

    local v19 = TickInput.new(TickInput.tick(v17), GameplayActions.from_values(v18), TickInput.controller_available(v17))

    if p17 then
        p15[1] = TickInput.new(TickInput.tick(v19), GameplayActions.from_values(table.create(18, 0)), TickInput.controller_available(v19))
    else
        p15[1] = v19

        if p14.stick_hz ~= nil then
            v19.stick_hz = p14.stick_hz
        end
    end
end

return t1
