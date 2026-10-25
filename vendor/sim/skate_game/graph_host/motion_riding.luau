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
local encode = import("skate_core/animation/skeleton_input/name").encode
local Attributes = import("skate_data/state_graph/attributes").Attributes
local Collections = import("skate_data/collections").Collections
local v2

local function motion_animation() -- line: 26
    -- upvalues: import (copy), v2 (ref)
    local v3 = v2

    if v3 == nil then
        v3 = import("skate_game/graph_host/motion_animation")
        v2 = v3
    end

    return v3
end

local t1 = {}

function t1.body_tilt_settings(p2) -- line: 38
    -- upvalues: v1 (copy), Collections (copy)
    local v4 = Collections.words(p2, "anim_motion", "body_tilt", "body_tilt_bodyspin_factor", 12)

    local function float(p3) -- line: 40
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "anim_motion", "body_tilt", p3)
    end

    local t2 = {}

    buffer.writeu32(v1, 0, v4[5])

    local v6 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[6])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[7])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[8])
    t2.x = {
        v6,
        v8,
        v10,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v4[9])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[10])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[11])

    local v17 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v4[12])
    t2.y = {
        v13,
        v15,
        v17,
        (buffer.readf32(v1, 0))
    }

    return {
        body_spin_factor = t2,
        ground_velocity = Collections.float(p2, "anim_motion", "body_tilt", "body_tilt_ground_clamp_vel"),
        ground_acceleration = Collections.float(p2, "anim_motion", "body_tilt", "body_tilt_ground_clamp_acc"),
        air_velocity = Collections.float(p2, "anim_motion", "body_tilt", "body_tilt_air_clamp_vel"),
        air_acceleration = Collections.float(p2, "anim_motion", "body_tilt", "body_tilt_air_clamp_acc")
    }
end

t1.ForceMode = {}

function t1.ForceMode.native_value(p4) -- line: 73
    if p4 == "AnimationData" then
        return 0
    end

    if p4 == "PhysicsBoard" then
        return 1
    end

    return 2
end

t1.RidingOperation = {}

function t1.RidingOperation.parse(p5) -- line: 93
    -- upvalues: v1 (copy), encode (copy), Attributes (copy)
    local name = Attributes.text(p5, "name")

    if name == nil then
        return nil
    end

    if name == "CreateAttribute" then
        local always = Attributes.get(p5, "always")
        local t3, v19

        if always ~= nil then
            buffer.writeu32(v1, 0, always.float_bits)

            local v21 = buffer.readf32(v1, 0)

            t3 = { v21, v21, 0 }
            v19 = false
        elseif Attributes.get(p5, "begin") == nil and Attributes.get(p5, "update") == nil and Attributes.get(p5, "end") == nil then
            t3 = { nil, 0, nil }
            v19 = false
        else
            t3 = {}

            local t4 = {
                "begin",
                "update",
                "end"
            }

            for i = 1, 3 do
                local v20 = Attributes.get(p5, t4[i])

                if v20 ~= nil then
                    buffer.writeu32(v1, 0, v20.float_bits)
                    t3[i] = buffer.readf32(v1, 0)
                end
            end

            v19 = Attributes.boolean_byte(p5, "set", 0) ~= 0
        end

        local attName = Attributes.text(p5, "attName")

        if attName == nil then
            attName = ""
        end

        return {
            tag = "CreateAttribute",
            name = encode(attName),
            values = t3,
            set = v19
        }
    end

    if name == "SetDistComToBoard" then
        local attribute = Attributes.text(p5, "attribute")

        if attribute == nil then
            attribute = ""
        end

        return {
            tag = "SetDistComToBoard",
            name = encode(attribute),
            manually = Attributes.boolean_byte(p5, "setManually", 0) ~= 0,
            adjust_for_velocity = Attributes.boolean_byte(p5, "adjustForVel", 0) ~= 0
        }
    end

    if name == "ForcePhysics" then
        local force = Attributes.text(p5, "force")

        if force == nil then
            force = "FOLLOW_ANIMATION_DATA"
        end

        return {
            tag = "ForcePhysics",
            if force == "FORCE_PHYSICS_SKATEBOARD" then "PhysicsBoard" elseif force == "FORCE_ANIM_SKATEBOARD" then "AnimationBoard" else "AnimationData"
        }
    end

    if name == "UpdateTimeSinceTeleport" then
        return {
            tag = "TimeSinceTeleport"
        }
    end

    if name == "UpdateTimeSinceKickturn" then
        return {
            tag = "TimeSinceKickturn"
        }
    end

    if name == "UpdateManualOutTimer" then
        return {
            tag = "ManualOutTimer"
        }
    end

    if name ~= "SetManualOutTimer" then
        return nil
    end

    buffer.writeu32(v1, 0, (Attributes.float_bits(p5, "length", 1042938855)))

    return {
        tag = "SetManualOutTimer",
        (buffer.readf32(v1, 0))
    }
end

t1.RidingState = {}

function t1.RidingState.new() -- line: 184
    return {
        time_since_teleport = 0,
        time_since_kickturn = 0,
        manual_out_timer = 0,
        dark = false,
        last_good_landing_velocity = 0,
        force_mode = nil
    }
end

function t1.RidingState.execute(p6, p7, p8, p9, p10, p11, p12, p13) -- line: 200
    -- upvalues: rt (copy), import (copy), v2 (ref)
    local tag = p7.tag

    if tag == "CreateAttribute" then
        local name, values, set = p7.name, p7.values, p7.set
        local v23 = values[p8 + 1]

        if v23 ~= nil then
            local v24 = v2

            if v24 == nil then
                v24 = import("skate_game/graph_host/motion_animation")
                v2 = v24
            end

            local MotionAnimation = v24.MotionAnimation

            MotionAnimation.emit_packet(p10, rt.copy(name), v23)

            if set then
                MotionAnimation.set_attribute(p10, {
                    normalized = false,
                    sequence_id = -1,
                    name = rt.copy(name),
                    value = v23
                })
            end
        end
    elseif tag == "SetDistComToBoard" then
        local name, manually, adjust_for_velocity = p7.name, p7.manually, p7.adjust_for_velocity

        if p8 == 0 then
            local v25

            if manually then
                v25 = 0.6499999761581421
            else
                if p12 == nil then
                    error("SetDistComToBoard requires actual PhysOutAnimation distance", 0)
                end

                v25 = p12
            end

            local v26

            if adjust_for_velocity then
                v26 = p9.dt * p6.last_good_landing_velocity

                if not (0.15000000596046448 - v26 >= 0) then
                    v26 = 0.15000000596046448
                end
            else
                v26 = 0
            end

            local v27 = v2

            if v27 == nil then
                v27 = import("skate_game/graph_host/motion_animation")
                v2 = v27
            end

            v27.MotionAnimation.set_attribute(p10, {
                normalized = false,
                sequence_id = -1,
                name = rt.copy(name),
                value = v25 - v26
            })
        end
    elseif tag == "ForcePhysics" then
        if p8 == 0 then
            p6.force_mode = p7[1]
        end
    elseif tag == "TimeSinceTeleport" then
        if p8 == 1 then
            if p11 == nil then
                error("UpdateTimeSinceTeleport needs filtered physical state", 0)
            end

            if p11 == 5 then
                p6.time_since_teleport = 0
            else
                p6.time_since_teleport += p9.dt
            end
        end
    elseif tag == "TimeSinceKickturn" then
        if p8 == 1 then
            p6.time_since_kickturn += p9.dt
        end
    elseif tag == "ManualOutTimer" then
        if p8 == 2 then
            p6.manual_out_timer = 0
        elseif p8 == 1 and not p13 then
            local v28 = p6.manual_out_timer - p9.dt

            if not (v28 >= 0) then
                v28 = 0
            end

            p6.manual_out_timer = v28
        end
    elseif tag == "SetManualOutTimer" and p8 == 2 then
        p6.manual_out_timer = p7[1]
    end
end

return t1
