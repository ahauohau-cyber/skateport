-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/animation/skeleton_input/name")
local v2 = import("skate_core/player/offboard/toggle_board")
local v3 = import("skate_game/graph_host/motion_channels")
local encode = v1.encode
local Clip, State = v2.Clip, v2.State
local MotionChannels = v3.MotionChannels
local t1 = {}
local v4

local function motion() -- line: 25
    -- upvalues: import (copy), v4 (ref)
    local v5 = v4

    if v5 == nil then
        v5 = import("skate_game/graph_host/motion")
        v4 = v5
    end

    return v5
end

t1.Physical = {}
t1.CHANNEL = "RetrieveBoard"

local CHANNEL = t1.CHANNEL
local publish, attribute

function t1.execute(p1, p2, p3, p4, p5, p6) -- line: 55
    -- upvalues: import (copy), Clip (copy), State (copy), MotionChannels (copy), v4 (ref), CHANNEL (copy), publish (ref), attribute (ref)
    if p6 == 0 then
        State.begin(p1)
    elseif p6 == 1 then
        if p4 == nil then
            error("ToggleBoard requires completed board-possession output (OffBoard36/40/304/311/313 and bundle28 byte87)", 0)
        end

        if p5 == nil then
            error("ToggleBoard requires the actual animation mirror state", 0)
        end

        local t2 = {
            grabbing_object = p4.grabbing_object,
            holding_board = p4.holding_board,
            retrieval_blocked = p4.retrieval_blocked,
            retrieval_active = p4.retrieval_active,
            yaw_radians = p4.yaw_radians,
            pitch_radians = p4.pitch_radians,
            mirrored = p5,
            drop_requested = p3.drop_requested,
            throw_requested = p3.throw_requested,
            retrieve_requested = p3.retrieve_requested
        }
        local v6 = MotionChannels.has(p2.channels, CHANNEL)
        local v7 = MotionChannels.remaining(p2.channels, CHANNEL)
        local v8 = MotionChannels.elapsed(p2.channels, CHANNEL)
        local v9 = State.update(p1, t2, {
            exists = v6,
            remaining = v7,
            elapsed = v8
        })

        if v9.retrieving then
            publish(p2, "OB_RetrievingBoard")
        end

        if v9.dropping then
            publish(p2, "OB_DroppingBoard")
        end

        local channel = v9.channel

        if channel == nil or channel.tag ~= "Stop" then
            if channel ~= nil then
                local v10, v11

                if channel.tag == "BlendTo" then
                    v10 = channel[1]
                    v11 = false
                elseif channel.tag == "SequenceTo" then
                    v10 = channel[1]
                    v11 = true
                else
                    error("internal error: entered unreachable code", 0)
                end

                local v12 = v10 == "FrontOut" or v10 == "BackOut"
                local v13 = v11 or v12
                local t3 = {
                    priority = 0,
                    keep_alive = false,
                    mirrored = false,
                    speed = 1,
                    blend_in = 0.25,
                    blend_out = 0.25,
                    use_attributes = true,
                    hold_during_blend_in = v13,
                    hold_during_blend_out = v13
                }
                local v14 = v4

                if v14 == nil then
                    v14 = import("skate_game/graph_host/motion")
                    v4 = v14
                end

                v14.MotionAnimation.transition_channel(p2, CHANNEL, Clip.name(v10), t3, {
                    under = 0,
                    matching = 0,
                    use_channels_from_weights = false,
                    kind = v11 and 4 or 2,
                    seconds = v11 and 0 or 0.25
                }, true, not v11 and not v12)
            end
        else
            MotionChannels.end_with(p2.channels, CHANNEL, channel.blend_seconds, false)
        end

        if v9.retrieve then
            publish(p2, "OB_RetrieveBoard")
        end

        local yaw_pitch = v9.yaw_pitch

        if yaw_pitch ~= nil then
            local v16 = yaw_pitch[1]
            local v17 = yaw_pitch[2]

            attribute(p2, "yaw", v16)
            attribute(p2, "pitch", v17)
        end
    end
end

function publish(p7, p8) -- line: 148
    -- upvalues: import (copy), encode (copy), v4 (ref), attribute (ref)
    local v18 = v4

    if v18 == nil then
        v18 = import("skate_game/graph_host/motion")
        v4 = v18
    end

    v18.MotionAnimation.emit_packet(p7, encode(p8), 1)
    attribute(p7, p8, 1)
end

t1.publish = publish

function attribute(p9, p10, p11) -- line: 159
    -- upvalues: import (copy), encode (copy), v4 (ref)
    local v19 = v4

    if v19 == nil then
        v19 = import("skate_game/graph_host/motion")
        v4 = v19
    end

    v19.MotionAnimation.set_attribute(p9, {
        normalized = false,
        sequence_id = -1,
        name = encode(p10),
        value = p11
    })
end

t1.attribute = attribute

return t1
