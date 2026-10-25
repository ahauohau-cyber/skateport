-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local AttributeName = import("skate_core/animation/output/attributes").AttributeName
local v9 = import("skate_core/physics/native_arithmetic")
local dot3, reciprocal_square_root_estimate = v9.dot3, v9.reciprocal_square_root_estimate
local push_contact = encode("push_contact")
local brake_contact = encode("brake_contact")
local right_hand_grab = encode("right_hand_grab")
local left_hand_grab = encode("left_hand_grab")
local righthand = encode("righthand")
local t1 = {}

t1.ContactEventState = {}

function t1.ContactEventState.eq(p4, p5) -- line: 55
    if p4.bone == p5.bone then
        return p4.push_speed == p5.push_speed
    end

    return false
end

t1.ContactEventPose = {}

local function replace(p6, p7, p8) -- line: 70
    return (bit32.bor(bit32.band(p6, (bit32.bnot((bit32.lshift(1, p7))))), (bit32.lshift(if p8 then 1 else 0, p7))))
end

function t1.dispatch(p9, p10, p11, p12) -- line: 78
    -- upvalues: rt (copy), v1 (copy), AttributeName (copy), dot3 (copy), reciprocal_square_root_estimate (copy), push_contact (copy), brake_contact (copy), right_hand_grab (copy), left_hand_grab (copy), righthand (copy)
    local v15 = p9.kind == 3
    local v16 = if v15 then bit32.band(p9.status, 12) == 0 else nil

    if not v15 or v16 then
        return
    end

    local t2 = {
        0, 0, 0, 0, 0, 0
    }

    for i = 0, 5 do
        local v17 = p9.payload[1][i + 1]

        if v17 == nil then
            error("Active animation bone event has incomplete payload", 0)
        end

        t2[i + 1] = v17
    end

    local t3 = { rt.slice(t2, 0, 5) }

    buffer.writeu32(v1, 0, t2[6])

    local v19 = buffer.readf32(v1, 0)
    local v20 = #p10.bone_names - 1
    local n1 = -1

    for i = 0, v20 do
        if AttributeName.eq(p10.bone_names[i + 1], t3) then
            n1 = i
            break
        end
    end

    p12.bone = n1

    if AttributeName.eq(p9.name, push_contact) then
        p11.flags2468 = bit32.bor(p11.flags2468, 134217728)

        local flags2468_2 = p11.flags2468
        local v21 = p12.bone == p10.right_toe_bone

        p11.flags2468 = bit32.bor(bit32.band(flags2468_2, 4227858431), (bit32.lshift(if v21 then 1 else 0, 26)))

        local flags2468_3 = p11.flags2468
        local v25 = v19 == 1

        p11.flags2468 = bit32.bor(bit32.band(flags2468_3, 4261412863), (bit32.lshift(if v25 then 1 else 0, 25)))

        local flags2468_4 = p11.flags2468
        local v29 = v19 == -1

        p11.flags2468 = bit32.bor(bit32.band(flags2468_4, 4278190079), (bit32.lshift(if v29 then 1 else 0, 24)))

        local v33 = p10.hierarchy[p10.trajectory_bone + 1]

        if v33 == nil then
            error("Push contact requires the actual animation trajectory bone", 0)
        end

        local v34 = rt.copy(v33[4])
        local v35 = dot3(v34, v34)
        local v36

        if v35 ~= 0 and v35 > -1.1754943508222875E-38 and v35 < 1.1754943508222875E-38 then
            local v37 = math.abs(v35) * 7.1362384635298E+44
            local v38 = math.floor(v37)
            local v39 = v37 - v38

            v36 = (if v39 > 0.5 or v39 == 0.5 and v38 % 2 == 1 then v38 + 1 else v38) * 1.401298464324817E-45

            if v35 < 0 then
                v36 = -v36
            end
        else
            buffer.writef32(v1, 0, v35)
            v36 = buffer.readf32(v1, 0)
        end

        local v40 = reciprocal_square_root_estimate(v36)
        local v41 = v40 * 0.5 * (-v36 * (v40 * v40) + 1) + v40
        local v42 = v41 * 0.5 * (-v36 * (v41 * v41) + 1) + v41
        local v43 = (if v36 == 0 then 0 else v36 * v42) * (1 / p10.timestep)

        if v19 == 1 then
            p12.push_speed = v43
        else
            p12.push_speed = 0
        end
    elseif AttributeName.eq(p9.name, brake_contact) then
        p11.flags2468 = bit32.bor(p11.flags2468, 268435456)

        local flags2468_2 = p11.flags2468
        local v44 = v19 == 1

        p11.flags2468 = bit32.bor(bit32.band(flags2468_2, 3221225471), (bit32.lshift(if v44 then 1 else 0, 30)))

        local flags2468_3 = p11.flags2468
        local v48 = v19 == -1

        p11.flags2468 = bit32.bor(bit32.band(flags2468_3, 4286578687), (bit32.lshift(if v48 then 1 else 0, 23)))
    elseif AttributeName.eq(p9.name, right_hand_grab) or AttributeName.eq(p9.name, left_hand_grab) then
        p11.flags2472 = bit32.bor(p11.flags2472, AttributeName.eq(t3, righthand) and 256 or 128)
    end
end

t1.replace = replace

return t1
