-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    DevicePacket = {},
    DeviceError = {}
}

function t1.DeviceError.eq(p1, p2) -- line: 47
    if p1.tag == p2.tag then
        return p1[1] == p2[1]
    end

    return false
end

t1.CapabilityCache = {}

function t1.CapabilityCache.default() -- line: 58
    return {
        value = nil
    }
end

function t1.CapabilityCache.invalidate(p3) -- line: 62
    p3.value = nil
end

function t1.CapabilityCache.get(p4, p5, p6) -- line: 67
    local v1 = p4.value == nil
    local v2, v3

    if not v1 then
        v2 = p4.value[1]
        v3 = p5 < p4.value[2]
    end

    if not v1 and v3 then
        return v2
    end

    p4.value = nil

    local v4 = p6()

    p4.value = {
        v4,
        p5 + 1
    }

    return v4
end

t1.windows = {}
t1.windows.Gamepad = {}
t1.windows.State = {}
t1.windows.Vibration = {}
t1.windows.Capabilities = {}

function t1.windows.XInputGetState(p7, p8) -- line: 96
    local v5 = if p8 == nil then nil else p8[p7 + 1]

    if v5 == nil then
        return 1167, nil
    end

    local v6 = v5.result or 0

    if v6 ~= 0 then
        return v6, nil
    end

    local gamepad = v5.gamepad

    return 0, {
        number = v5.number,
        gamepad = {
            buttons = gamepad.buttons,
            left_trigger = gamepad.left_trigger,
            right_trigger = gamepad.right_trigger,
            left_x = gamepad.left_x,
            left_y = gamepad.left_y,
            right_x = gamepad.right_x,
            right_y = gamepad.right_y
        }
    }
end

function t1.windows.XInputGetCapabilities(p9, _, p11) -- line: 123
    local v7 = if p11 == nil then nil else p11[p9 + 1]

    if v7 == nil then
        return 1167, nil
    end

    local v8 = v7.capabilities_result or 0

    if v8 ~= 0 then
        return v8, nil
    end

    return 0, {
        subtype = if v7.subtype == nil then 1 else v7.subtype
    }
end

function t1.windows.poll(p12, p13, p14) -- line: 136
    -- upvalues: t1 (copy)
    local v9, v10 = t1.windows.XInputGetState(p12, p14)

    if v9 ~= 0 then
        t1.CapabilityCache.invalidate(p13)
    end

    if v9 == 1167 then
        error({
            tag = "Disconnected"
        }, 0)
    end

    if v9 ~= 0 then
        error({
            tag = "State",
            v9
        }, 0)
    end

    local v11 = if p14 == nil or p14.now == nil then os.clock() else p14.now
    local v12 = t1.CapabilityCache.get(p13, v11, function() -- line: 149
        -- upvalues: p12 (copy), p14 (copy), t1 (copy)
        local v13, v14 = t1.windows.XInputGetCapabilities(p12, 1, p14)

        if v13 ~= 0 then
            error({
                tag = "Capabilities",
                v13
            }, 0)
        end

        return v14.subtype
    end)

    return {
        number = v10.number,
        state = {
            buttons = v10.gamepad.buttons,
            triggers = {
                v10.gamepad.left_trigger,
                v10.gamepad.right_trigger
            },
            left = {
                v10.gamepad.left_x,
                v10.gamepad.left_y
            },
            right = {
                v10.gamepad.right_x,
                v10.gamepad.right_y
            }
        },
        subtype = v12
    }
end

function t1.poll_cached(p15, p16, p17) -- line: 170
    -- upvalues: t1 (copy)
    if not (p15 < 4) then
        error("assertion failed: index < 4", 0)
    end

    return t1.windows.poll(p15, p16, p17)
end

function t1.poll(p18, p19) -- line: 178
    -- upvalues: t1 (copy)
    return t1.poll_cached(p18, t1.CapabilityCache.default(), p19)
end

return t1
