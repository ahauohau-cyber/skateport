-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/input/gameplay_map")
local v2 = import("skate_core/input/history")
local v3 = import("skate_core/input/pad")
local v4 = import("skate_core/input/xbox")
local v5 = import("skate_core/input/tick")
local GameplayActions = v1.GameplayActions
local DEVICE_SLOTS, HistoryRecord, PadHistory = v2.DEVICE_SLOTS, v2.HistoryRecord, v2.PadHistory
local Pad = v3.Pad
local TickInput = v5.TickInput
local v6 = import("skate_game/input/stick_hz")

local function stick_hz() -- line: 24
    -- upvalues: v6 (copy)
    return v6
end

local v7 = false
local t1 = {}

function t1.set_reference(p1) -- line: 32
    -- upvalues: v7 (ref)
    v7 = p1
end

t1.ControllerStatus = {}

function t1.ControllerStatus.eq(p2, p3) -- line: 41
    if p2.tag ~= p3.tag then
        return false
    end

    if p2.tag ~= "Unavailable" then
        return true
    end

    if p2[1].tag == p3[1].tag then
        return p2[1][1] == p3[1][1]
    end

    return false
end

t1.ControllerInput = {}

local function ready_device(p4) -- line: 66
    for i = 0, #p4 - 1 do
        if p4[i + 1].tag == "Ready" then
            return i
        end
    end

    return nil
end

function t1.ControllerInput.default() -- line: 75
    -- upvalues: rt (copy), DEVICE_SLOTS (copy), HistoryRecord (copy), PadHistory (copy), Pad (copy), t1 (copy)
    return {
        active = 0,
        publications = 0,
        consumed_batches = 0,
        tick = 0,
        raw = rt.filled(DEVICE_SLOTS, t1.RawInput.default()),
        cache = rt.filled(2, rt.filled(DEVICE_SLOTS, HistoryRecord.new({}))),
        history = PadHistory.new(),
        pads = rt.from_fn(DEVICE_SLOTS, function(_) -- line: 81
            -- upvalues: Pad (copy)
            return Pad.new()
        end),
        status = rt.filled(DEVICE_SLOTS, {
            tag = "Unpolled"
        }),
        packet_numbers = {},
        mapped_actions = rt.filled(DEVICE_SLOTS, table.create(18, 0))
    }
end

function t1.ControllerInput.session_marker_actions(p6) -- line: 96
    -- upvalues: Pad (copy)
    local status = p6.status
    local v8 = #status - 1
    local v9 = false
    local v10

    for i = 0, v8 do
        if status[i + 1].tag == "Ready" then
            v10 = i
            v9 = true
            break
        end
    end

    if not v9 then
        v10 = nil
    end

    if v10 == nil then
        return false, false, false
    end

    local v11 = p6.pads[v10 + 1]

    if Pad.count(v11) == 0 then
        return false, false, false
    end

    local function flags(p7) -- line: 105
        -- upvalues: v11 (copy), Pad (copy)
        local v12 = Pad.records(v11)[p7 + 1]

        if v12 == nil then
            return 0
        end

        return v12[2]
    end

    local v13 = Pad.records(v11)[9]
    local v15 = bit32.band(if v13 == nil then 0 else v13[2], 65280) ~= 0
    local v16, v17

    if not v15 then
        v16 = v15
        v17 = v15

        return v15, v17, v16
    end

    local v18 = Pad.records(v11)[2]

    v17 = bit32.band(if v18 == nil then 0 else v18[2], 4278190080) ~= 0

    local v20 = Pad.records(v11)[1]

    return v15, v17, bit32.band(if v20 == nil then 0 else v20[2], 65280) ~= 0
end

function t1.ControllerInput.raw_input(p8) -- line: 118
    -- upvalues: rt (copy), t1 (copy)
    local status = p8.status
    local v22 = #status - 1
    local v23 = false
    local v24

    for i = 0, v22 do
        if status[i + 1].tag == "Ready" then
            v24 = i
            v23 = true
            break
        end
    end

    if not v23 then
        v24 = nil
    end

    if v24 == nil then
        return t1.RawInput.default()
    end

    return rt.copy(p8.raw[v24 + 1])
end

function t1.ControllerInput.discard_gameplay(p9) -- line: 127
    -- upvalues: rt (copy), DEVICE_SLOTS (copy), PadHistory (copy), Pad (copy)
    p9.history = PadHistory.new()
    p9.pads = rt.from_fn(DEVICE_SLOTS, function(_) -- line: 129
        -- upvalues: Pad (copy)
        return Pad.new()
    end)
    p9.mapped_actions = rt.filled(DEVICE_SLOTS, table.create(18, 0))
end

function t1.ControllerInput.player_actions(p11) -- line: 136
    -- upvalues: GameplayActions (copy)
    local status = p11.status
    local v25 = #status - 1
    local v26 = false
    local v27

    for i = 0, v25 do
        if status[i + 1].tag == "Ready" then
            v27 = i
            v26 = true
            break
        end
    end

    if not v26 then
        v27 = nil
    end

    if v27 == nil then
        v27 = 0
    end

    return GameplayActions.from_pad(p11.pads[v27 + 1])
end

function t1.ControllerInput.tick_values_into(p12, p13) -- line: 148
    -- upvalues: GameplayActions (copy)
    local status = p12.status
    local v28 = #status - 1
    local v29 = false
    local v30

    for i = 0, v28 do
        if status[i + 1].tag == "Ready" then
            v30 = i
            v29 = true
            break
        end
    end

    if not v29 then
        v30 = nil
    end

    if v30 ~= nil then
        GameplayActions.from_pad_into(p12.pads[v30 + 1], p13)
    else
        GameplayActions.zeros_into(p13)
    end

    return p12.tick, v30 ~= nil
end

function t1.ControllerInput.tick_input(p14) -- line: 158
    -- upvalues: GameplayActions (copy), TickInput (copy)
    local status = p14.status
    local v31 = #status - 1
    local v32 = false
    local v33

    for i = 0, v31 do
        if status[i + 1].tag == "Ready" then
            v33 = i
            v32 = true
            break
        end
    end

    if not v32 then
        v33 = nil
    end

    local v34 = v33 ~= nil
    local v35 = if v33 == nil then GameplayActions.from_values(table.create(18, 0)) else GameplayActions.from_pad(p14.pads[v33 + 1])

    return TickInput.new(p14.tick, v35, v34)
end

function t1.ControllerInput.collect(p15, p16) -- line: 175
    -- upvalues: rt (copy), v4 (copy), HistoryRecord (copy), PadHistory (copy), t1 (copy)
    local v36 = bit32.bxor(p15.active, 1)

    for i = 0, #p16 - 1 do
        local v37 = p16[i + 1]

        if v37.tag == "Ok" then
            local v38 = v37[1]

            p15.raw[i + 1] = {
                buttons = v38.state.buttons,
                triggers = {
                    v38.state.triggers[1] / 255,
                    v38.state.triggers[2] / 255
                },
                left = {
                    v38.state.left[1] / 32768,
                    v38.state.left[2] / 32768
                },
                right = {
                    v38.state.right[1] / 32768,
                    v38.state.right[2] / 32768
                }
            }

            local v39 = v4.convert(v38.state, if v38.subtype == 7 then 1 else 0)

            p15.cache[v36 + 1][i + 1] = HistoryRecord.new(v39)
            p15.packet_numbers[i + 1] = v38.number
            p15.status[i + 1] = {
                tag = "Ready"
            }
        else
            local v40 = v37[1]

            p15.raw[i + 1] = t1.RawInput.default()
            HistoryRecord.clear_count(p15.cache[v36 + 1][i + 1])
            p15.packet_numbers[i + 1] = nil
            p15.status[i + 1] = {
                tag = "Unavailable",
                (rt.copy(v40))
            }
        end
    end

    p15.active = v36
    PadHistory.publish(p15.history, p15.cache[p15.active + 1])
    p15.publications += 1
end

local t2 = {}

function t1.ControllerInput.collect_stick_hz(p17, p18) -- line: 220
    -- upvalues: rt (copy), v2 (copy), v6 (copy), t2 (copy)
    p17.stick_hz = nil

    if p17.stick_hz_hold then
        p17.stick_hz_hold = nil
    else
        local history = p17.history
        local HISTORY_CAPACITY = v2.HISTORY_CAPACITY
        local v41 = rt.irem(history.write - history.read - 1 + HISTORY_CAPACITY, HISTORY_CAPACITY)

        if not (v41 < 2) then
            local status = p17.status
            local v42 = #status - 1
            local v43 = false
            local v44

            for i = 0, v42 do
                if status[i + 1].tag == "Ready" then
                    v44 = i
                    v43 = true
                    break
                end
            end

            if not v43 then
                v44 = nil
            end

            if v44 ~= nil then
                local v45 = v6.pick(v41, p18, t2)

                if #v45 ~= 0 then
                    local t3 = {}

                    for _, v46 in v45 do
                        local v47 = rt.irem(history.read + v46, HISTORY_CAPACITY)
                        local v48 = history.batches[v47 + 1][v44 + 1]

                        if v48 == nil or v48.count < 24 then
                            return
                        end

                        local values = v48.values

                        table.insert(t3, {
                            rt.fround(rt.fround(values[21]) - rt.fround(values[22])),
                            rt.fround(rt.fround(values[23]) - rt.fround(values[24]))
                        })
                    end

                    p17.stick_hz = t3
                end
            end
        end
    end
end

function t1.ControllerInput.publish_actions(p19) -- line: 258
    -- upvalues: GameplayActions (copy), PadHistory (copy), v6 (copy), t1 (copy), v7 (ref)
    if v7 then
        return t1.ControllerInput.publish_actions_reference(p19)
    end

    local per_tick = v6.per_tick

    if per_tick > 1 then
        t1.ControllerInput.collect_stick_hz(p19, per_tick)
    elseif p19.stick_hz ~= nil then
        p19.stick_hz = nil
    end

    p19.tick += 1

    if not PadHistory.drain_to_latest(p19.history, p19.pads) then
        return false
    end

    local mapped_actions = p19.mapped_actions

    for i = 0, #p19.pads - 1 do
        local v49 = p19.pads[i + 1]
        local v50 = mapped_actions[i + 1]

        if type(v50) == "table" then
            GameplayActions.from_pad_into(v49, v50)
        else
            mapped_actions[i + 1] = GameplayActions.from_pad_into(v49, table.create(18))
        end
    end

    p19.consumed_batches += 1

    return true
end

function t1.ControllerInput.publish_actions_reference(p20) -- line: 287
    -- upvalues: rt (copy), GameplayActions (copy), PadHistory (copy), v6 (copy), t1 (copy)
    local per_tick = v6.per_tick

    if per_tick > 1 then
        t1.ControllerInput.collect_stick_hz(p20, per_tick)
    elseif p20.stick_hz ~= nil then
        p20.stick_hz = nil
    end

    p20.tick += 1

    if not PadHistory.drain_to_latest(p20.history, p20.pads) then
        return false
    end

    for i = 0, #p20.pads - 1 do
        local v51 = p20.pads[i + 1]
        local v52 = GameplayActions.from_pad(v51)

        p20.mapped_actions[i + 1] = rt.from_fn(18, function(p21) -- line: 301
            -- upvalues: v52 (copy), GameplayActions (copy)
            return GameplayActions.value(v52, 64 + p21)
        end)
    end

    p20.consumed_batches += 1

    return true
end

function t1.ControllerInput.sample_raw_for_test(p22, p23) -- line: 313
    -- upvalues: rt (copy), t1 (copy)
    t1.ControllerInput.collect(p22, {
        {
            tag = "Ok",
            {
                subtype = 1,
                number = rt.wrapping_add_u32(p22.publications % 4294967296, 1),
                state = rt.copy(p23)
            }
        },
        {
            tag = "Err",
            {
                tag = "Disconnected"
            }
        },
        {
            tag = "Err",
            {
                tag = "Disconnected"
            }
        },
        {
            tag = "Err",
            {
                tag = "Disconnected"
            }
        }
    })

    if not t1.ControllerInput.publish_actions(p22) then
        error("assertion failed: self.publish_actions()", 0)
    end
end

t1.RawInput = {}

function t1.RawInput.default() -- line: 335
    return {
        buttons = 0,
        triggers = { 0, 0 },
        left = { 0, 0 },
        right = { 0, 0 }
    }
end

return t1
