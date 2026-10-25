-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local IntentMap = require(sim.import)("skate_core/graph/intents").IntentMap
local t1 = {}

local function debug_string_vec(p1) -- line: 17
    local v1 = table.create(#p1)

    for v2, v3 in p1 do
        v1[v2] = "\"" .. string.gsub(v3, "[\\\"\n\r\t]", function(p2) -- line: 20
            if p2 == "\\" then
                return "\\\\"
            end

            if p2 == "\"" then
                return "\\\""
            end

            if p2 == "\n" then
                return "\\n"
            end

            if p2 == "\r" then
                return "\\r"
            end

            return "\\t"
        end) .. "\""
    end

    return "[" .. table.concat(v1, ", ") .. "]"
end

t1.AuthoredSignals = {}

function t1.AuthoredSignals.default() -- line: 40
    -- upvalues: IntentMap (copy)
    return {
        values = IntentMap.default()
    }
end

function t1.AuthoredSignals.from_values(p3) -- line: 44
    -- upvalues: rt (copy)
    return {
        values = rt.copy(p3)
    }
end

function t1.AuthoredSignals.into_values(p4) -- line: 48
    return p4.values
end

function t1.AuthoredSignals.get(p5, p6) -- line: 52
    -- upvalues: IntentMap (copy)
    return IntentMap.get(p5.values, p6)
end

function t1.AuthoredSignals.contains(p7, p8) -- line: 56
    -- upvalues: IntentMap (copy)
    return IntentMap.contains_key(p7.values, p8)
end

t1.WipeoutControls = {}

function t1.WipeoutControls.default() -- line: 63
    return {
        request = false,
        gesture = nil,
        air_body_tweak = { 0, 0 }
    }
end

t1.BoardControls = {}

function t1.BoardControls.default() -- line: 70
    return {
        drop_requested = false,
        throw_requested = false,
        retrieve_requested = false
    }
end

t1.ActionControls = {}

function t1.ActionControls.default() -- line: 77
    -- upvalues: t1 (copy)
    return {
        wipeout = t1.WipeoutControls.default(),
        board = t1.BoardControls.default(),
        authored_values = t1.AuthoredSignals.default()
    }
end

function t1.ActionControls.has(p9, p10) -- line: 85
    -- upvalues: t1 (copy)
    return t1.AuthoredSignals.contains(p9.authored_values, p10)
end

function t1.ActionControls.value(p11, p12) -- line: 89
    -- upvalues: t1 (copy)
    return t1.AuthoredSignals.get(p11.authored_values, p12)
end

function t1.ActionControls.authored_values(p13) -- line: 94
    -- upvalues: rt (copy), t1 (copy)
    return t1.AuthoredSignals.into_values(rt.copy(p13.authored_values))
end

t1.MotionEffects = {}

function t1.MotionEffects.default() -- line: 101
    -- upvalues: t1 (copy)
    return {
        values = t1.AuthoredSignals.default()
    }
end

function t1.MotionEffects.from_values(p14) -- line: 105
    -- upvalues: t1 (copy)
    return {
        values = t1.AuthoredSignals.from_values(p14)
    }
end

function t1.MotionEffects.apply_to(p15, p16) -- line: 110
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p16, t1.AuthoredSignals.into_values(rt.copy(p15.values)))
end

t1.ActionInput = {}

function t1.ActionInput.default() -- line: 117
    -- upvalues: t1 (copy)
    return {
        values = t1.AuthoredSignals.default()
    }
end

function t1.ActionInput.from_values(p17) -- line: 121
    -- upvalues: t1 (copy)
    return {
        values = t1.AuthoredSignals.from_values(p17)
    }
end

function t1.ActionInput.into_values(p18) -- line: 125
    -- upvalues: t1 (copy)
    return t1.AuthoredSignals.into_values(p18.values)
end

t1.PriorMotionState = {}

function t1.PriorMotionState.default() -- line: 132
    -- upvalues: t1 (copy)
    return {
        values = t1.AuthoredSignals.default()
    }
end

function t1.PriorMotionState.from_values(p19) -- line: 136
    -- upvalues: t1 (copy)
    return {
        values = t1.AuthoredSignals.from_values(p19)
    }
end

function t1.PriorMotionState.into_values(p20) -- line: 140
    -- upvalues: t1 (copy)
    return t1.AuthoredSignals.into_values(p20.values)
end

t1.GraphDiagnostics = {}
t1.GraphDiagnostics.CAPACITY = 64

function t1.GraphDiagnostics.default() -- line: 152
    return {
        overflowed = false,
        messages = {}
    }
end

function t1.GraphDiagnostics.push(p21, p22) -- line: 156
    -- upvalues: t1 (copy)
    if #p21.messages < t1.GraphDiagnostics.CAPACITY then
        table.insert(p21.messages, p22)
    else
        p21.overflowed = true
    end
end

function t1.GraphDiagnostics.is_empty(p23) -- line: 164
    if #p23.messages == 0 then
        return not p23.overflowed
    end

    return false
end

function t1.GraphDiagnostics.clear(p24) -- line: 168
    table.clear(p24.messages)
    p24.overflowed = false
end

function t1.GraphDiagnostics.join(p25, p26) -- line: 173
    local v4 = table.concat(p25.messages, p26)

    if not p25.overflowed then
        return v4
    end

    return (if #v4 == 0 then v4 else v4 .. p26) .. "graph diagnostics truncated after 64 entries"
end

t1.GraphCapabilityReport = {}

function t1.GraphCapabilityReport.default() -- line: 192
    return {
        supported_operations = 0,
        unsupported_operations = {},
        unsupported_conditions = {},
        unsupported_hooks = {}
    }
end

function t1.GraphCapabilityReport.require_complete(p27, p28) -- line: 202
    -- upvalues: debug_string_vec (copy)
    if #p27.unsupported_operations == 0 and #p27.unsupported_conditions == 0 and #p27.unsupported_hooks == 0 then
        return
    end

    error(p28 .. " contains unsupported authored features: operations=" .. debug_string_vec(p27.unsupported_operations) .. ", conditions=" .. debug_string_vec(p27.unsupported_conditions) .. ", hooks=" .. debug_string_vec(p27.unsupported_hooks), 0)
end

t1.TurningOutput = {}

function t1.TurningOutput.default() -- line: 221
    return {
        turn = 0,
        raw_turn = 0,
        hard_turn = 0
    }
end

t1.GraphEffects = {}

function t1.GraphEffects.default() -- line: 229
    return {
        state_requests = {}
    }
end

t1.ActionGraphInput = {}
t1.ActionGraphOutput = {}

function t1.ActionGraphOutput.from_host(p29, p30, p31, p32) -- line: 247
    -- upvalues: rt (copy), IntentMap (copy), t1 (copy)
    local function get_or_zero(p33, p34) -- line: 248
        -- upvalues: IntentMap (copy)
        local v5 = IntentMap.get(p33, p34)

        if v5 == nil then
            return 0
        end

        return v5
    end

    local WipeOutRequest = IntentMap.contains_key(p30, "WipeOutRequest")
    local OB_AirBodyTweakX = IntentMap.get(p30, "OB_AirBodyTweakX")

    if OB_AirBodyTweakX == nil then
        OB_AirBodyTweakX = 0
    end

    local OB_AirBodyTweakY = IntentMap.get(p30, "OB_AirBodyTweakY")

    if OB_AirBodyTweakY == nil then
        OB_AirBodyTweakY = 0
    end

    local t2 = {
        OB_AirBodyTweakX,
        OB_AirBodyTweakY
    }
    local WipeoutGestureX = IntentMap.get(p30, "WipeoutGestureX")
    local WipeoutGestureY = IntentMap.get(p30, "WipeoutGestureY")
    local t3 = {
        tick = p29,
        controls = {
            wipeout = {
                request = WipeOutRequest,
                air_body_tweak = t2,
                gesture = if WipeoutGestureX == nil or WipeoutGestureY == nil then nil else { WipeoutGestureX, WipeoutGestureY }
            },
            board = {
                drop_requested = IntentMap.contains_key(p30, "OB_DropBoard"),
                throw_requested = IntentMap.contains_key(p30, "OB_ThrowBoard"),
                retrieve_requested = IntentMap.contains_key(p30, "OB_RetrieveBoard")
            },
            authored_values = t1.AuthoredSignals.from_values(p30)
        },
        motion_effects = t1.MotionEffects.from_values(p31)
    }
    local Turn = IntentMap.get(p31, "Turn")

    if Turn == nil then
        Turn = 0
    end

    local t4 = {}

    t4.turn = Turn

    local RawTurn = IntentMap.get(p31, "RawTurn")

    t4.raw_turn = if RawTurn == nil then 0 else RawTurn

    local HardTurn = IntentMap.get(p31, "HardTurn")

    t4.hard_turn = if HardTurn == nil then 0 else HardTurn
    t3.turning = t4
    t3.animation_attributes = rt.copy(p32)
    t3.effects = t1.GraphEffects.default()

    return t3
end

t1.MotionGraphInput = {}

return t1
