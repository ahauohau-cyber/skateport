-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/animation/output/actor_packet")
local v2 = import("skate_core/animation/output/attributes")
local v3 = import("skate_core/animation/output/intents")
local v4 = import("skate_core/animation/output/motion_graph_packet")
local v5 = import("skate_core/animation/output/packet_reset")
local v6 = import("skate_core/animation/output/physics_packet")
local PacketAttributes = v2.PacketAttributes
local IntentMap = v3.IntentMap
local t1 = {
    PhysicsInputPacket = {},
    AnimationPublication = {},
    IntentPublication = {},
    MotionGraphPublication = {},
    PublicationError = {},
    PhysicsPacketBinding = {}
}

function t1.PhysicsPacketBinding.packet(p1) -- line: 53
    return p1.packet
end

function t1.compose(p2, p3, p4, p5, p6) -- line: 62
    -- upvalues: v1 (copy), v4 (copy), v5 (copy), v6 (copy), PacketAttributes (copy), IntentMap (copy)
    local reset = v5.reset
    local pose, reset2 = p2.pose, p2.reset
    local ok, result = pcall(reset, pose, reset2)

    if not ok then
        error({
            tag = "Pose",
            result
        }, 0)
    end

    local publish = v6.publish
    local state, completed, poses = p3.state, p3.completed, p3.poses
    local pose2 = p2.pose
    local signal_name = p3.signal_name
    local ok2, result2 = pcall(publish, state, completed, poses, pose2, 0.01666666753590107, signal_name)

    if not ok2 then
        error({
            tag = "Pose",
            result2
        }, 0)
    end

    v4.publish(p4.state, p2.motion_graph)

    if p4.intents.tag == "MotionGraph" then
        local v7 = p4.intents[1]

        IntentMap.replace_from(p2.intents, v7)
    end

    PacketAttributes.replace_from(p2.attributes, p4.attributes, p3.tree_attributes)

    local publish2 = v1.publish
    local pose3, reset3, actor = p2.pose, p2.reset, p2.actor
    local ok3, result3 = pcall(publish2, p5, pose3, reset3, actor, p6)

    if not ok3 then
        error({
            tag = "RuntimeService",
            result3
        }, 0)
    end

    return {
        packet = p2
    }
end

return t1
