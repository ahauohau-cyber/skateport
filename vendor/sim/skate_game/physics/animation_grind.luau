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
local GrindState = import("skate_core/physics/filtered_state").GrindState
local observations, xyz, name_text
local t1 = {}

function t1.publish(p2, p3, p4, p5, p6, p7) -- line: 25
    -- upvalues: observations (ref)
    local v2, v3, v4 = observations(p3, p4, p5, p6, p7)

    p2.grind_physical = v3
    p2.grind_conditions = v4

    return v2
end

function observations(p8, p9, p10, p11, p12) -- line: 33
    -- upvalues: rt (copy), GrindState (copy), xyz (ref), name_text (ref)
    local v5, v6

    if p9 ~= nil then
        if p9.category ~= p8.filtered_state_0 then
            error("Grind graph received inconsistent completed filtered outputs", 0)
        end

        v6 = p9.grinding
        v5 = rt.copy(p9.grind)
    elseif p8.filtered_state_0 == 0 then
        v6 = false
        v5 = GrindState.default()
    else
        error("Grind graph requires the completed filtered state owner", 0)
    end

    local v7 = name_text(v5.name)
    local t2 = {
        grinding = v6,
        grind_name = rt.copy(v5.name),
        ground_axis = xyz(p8.skateboard.vector_80),
        board_axis = rt.copy(p12),
        ground_flag_273 = p8.ground.flag_273 ~= 0,
        animation_mirrored = p11,
        height = p10,
        crouch = v5.crouch,
        twist = p8.skeleton.twist_504
    }
    local t3 = {
        filtered_grinding_80 = v6,
        blunting_136 = p8.grinds.words_136_140[1],
        approach_268 = p8.grinds.animation_chromosome_268[1],
        trick_out_240 = p8.grinds.trick_out_240,
        air_grind_443 = p8.air.flag_443 ~= 0,
        air_time_184 = p8.air.scalar_184,
        dropping_in_324 = p8.grinds.dropping_in_324 ~= 0
    }

    return {
        category = p8.filtered_state_0,
        grinding = v6,
        grind_name = v7
    }, t2, t3
end

t1.observations = observations

function xyz(p13) -- line: 84
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p13[1])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p13[2])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p13[3])

    return {
        v9,
        v11,
        (buffer.readf32(v1, 0))
    }
end

t1.xyz = xyz

function name_text(p14) -- line: 93
    -- upvalues: rt (copy), encode (copy)
    local t4 = {}
    local v13 = false

    for _, v14 in p14[1] do
        local v15 = v13
        local v16 = v14

        for _, v17 in { 79235168, 2085136, 54872, 1444, 38, 1 } do
            local v18 = rt.idiv(v16, v17)

            v16 = rt.irem(v16, v17)

            if v18 == 0 then
                v15 = true
            else
                if v15 then
                    error("Filtered grind name contains a nonterminal NUL", 0)
                end

                local v19

                if v18 >= 1 and v18 <= 10 then
                    v19 = 48 + (v18 - 1)
                elseif v18 >= 11 and v18 <= 36 then
                    v19 = 65 + (v18 - 11)
                elseif v18 == 37 then
                    v19 = 95
                else
                    error("Filtered grind name is outside the stock alphabet", 0)
                end

                table.insert(t4, (string.char(v19)))
            end

            v13 = v15
        end
    end

    local v21 = table.concat(t4)
    local v22 = encode(v21)

    for i = 1, 5 do
        if v22[1][i] ~= p14[1][i] then
            error("Filtered grind name did not round trip", 0)
        end
    end

    return v21
end

t1.name_text = name_text

return t1
