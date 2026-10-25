-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function scoring_hud() -- line: 27
    -- upvalues: import (copy)
    return import("skate_game/scoring_hud")
end

local function apt_vm() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/apt_vm")
end

local v1 = import("skate_game/apt_vm")
local v2 = import("skate_game/apt_movie")
local Vm = v1.Vm
local Movie = v2.Movie
local t1 = {
    Input = {}
}

local function value_eq(p1, p2) -- line: 61
    if p1.tag == p2.tag then
        return p1[1] == p2[1]
    end

    return false
end

function t1.Input.eq(p3, p4) -- line: 66
    if p3.sequence_score ~= p4.sequence_score
        or p3.line_score ~= p4.line_score
        or p3.sequence_timer ~= p4.sequence_timer
        or p3.line_time ~= p4.line_time
        or p3.line_capacity ~= p4.line_capacity
        or p3.multiplier ~= p4.multiplier
        or p3.clean ~= p4.clean
        or p3.sketchy ~= p4.sketchy
        or p3.trick_name ~= p4.trick_name
        or p3.stance[1] ~= p4.stance[1]
        or p3.stance[2] ~= p4.stance[2]
        or p3.stance[3] ~= p4.stance[3]
        or p3.stance[4] ~= p4.stance[4] then
        return false
    end

    for i = 1, 5 do
        local v3 = p3.trick_metrics[i]
        local v4 = p4.trick_metrics[i]

        if v3.tag ~= v4.tag or v3[1] ~= v4[1] then
            return false
        end
    end

    if #p3.context_tricks ~= #p4.context_tricks then
        return false
    end

    for i = 1, #p3.context_tricks do
        local v5 = p3.context_tricks[i]
        local v6 = p4.context_tricks[i]

        if v5.tag ~= v6.tag or v5[1] ~= v6[1] then
            return false
        end
    end

    return true
end

t1.Bindings = {}
t1.Runtime = {}

function t1.array(p5) -- line: 114
    local v7 = table.create(#p5)

    for v8, v9 in p5 do
        v7[v8] = v9
    end

    return v7
end

local array2 = t1.array

function t1.vm_array(p6, p7) -- line: 125
    -- upvalues: Vm (copy)
    local v10 = Vm.object(p6, {
        tag = "Plain"
    })
    local n1 = 0

    for _, v11 in p7 do
        Vm.set(p6, v10, string.format("%d", n1), v11)
        n1 += 1
    end

    Vm.set(p6, v10, "length", {
        tag = "Number",
        n1
    })

    return {
        tag = "Object",
        v10
    }
end

function t1.score(p8) -- line: 138
    local v12 = string.format("%d", (math.abs(p8)))
    local t2 = {}

    if p8 < 0 then
        table.insert(t2, "-")
    end

    for i = 0, #v12 - 1 do
        if i > 0 and (#v12 - i) % 3 == 0 then
            table.insert(t2, ",")
        end

        table.insert(t2, (string.sub(v12, i + 1, i + 1)))
    end

    return table.concat(t2)
end

local score2 = t1.score

function t1.Bindings.property_changed(p9, p10, p11, p12) -- line: 157
    -- upvalues: Movie (copy)
    if p12 == "text" or p12 == "autoSize" then
        Movie.text_changed(p9.movie, p10, p11)
    end
end

function t1.Bindings.host_call(p13, p14, p15, p16, p17) -- line: 166
    -- upvalues: Movie (copy), t1 (copy)
    if Movie.method(p13.movie, p14, p15, p16, p17) then
        return {
            tag = "Undefined"
        }
    end

    local v14 = p14.objects[p15 + 1]
    local v15 = if v14 == nil then "global" elseif v14.kind.tag == "Native" then v14.kind[1] else "global"
    local v16 = t1.Bindings.call(p13, v15, p16, p17)

    if v16.tag == nil then
        return t1.vm_array(p14, v16)
    end

    return v16
end

function t1.Bindings.host(p18) -- line: 183
    -- upvalues: t1 (copy)
    return {
        property_changed = function(_, p20, p21, p22) -- property_changed | line: 185
            -- upvalues: p18 (copy), t1 (copy)
            return t1.Bindings.property_changed(p18, p20, p21, p22)
        end,
        call = function(_, p24, p25, p26, p27) -- call | line: 188
            -- upvalues: p18 (copy), t1 (copy)
            return t1.Bindings.host_call(p18, p24, p25, p26, p27)
        end
    }
end

function t1.Bindings.call(p28, p29, p30, p31) -- line: 212
    -- upvalues: rt (copy), import (copy), array2 (copy), score2 (copy)
    if p29 == "Math" and p30 == "floor" then
        local v17 = p31[1]

        if v17 == nil then
            error("Math.floor argument", 0)
        end

        return {
            tag = "Number",
            (math.floor((import("skate_game/apt_vm").Value.number(v17))))
        }
    end

    if p29 ~= "Math" or p30 ~= "random" then
        if p29 == "global" and p30 == "ASSetPropFlags" then
            return {
                tag = "Undefined"
            }
        end

        if p29 == "FELanguage" and p30 == "GetLanguage" then
            return {
                tag = "Text",
                "english"
            }
        end

        if p29 == "Tricks" and p30 == "GetLineTimerMaxPoints" then
            return {
                tag = "Number",
                p28.input.line_capacity
            }
        end

        if p29 == "Tricks" and p30 == "GetLineTimeRemaining" then
            return {
                tag = "Number",
                (rt.trunc(p28.input.line_time))
            }
        end

        if p29 == "Tricks" and p30 == "GetLineScore" then
            return {
                tag = "Number",
                p28.input.line_score
            }
        end

        if p29 == "HUDComponents" and p30 == "TrickDisplay_GetSequenceMultiplier" then
            return {
                tag = "Number",
                p28.input.multiplier
            }
        end

        if p29 == "Tricks" and p30 == "GetGeneralInfo" then
            return array2({
                {
                    tag = "Number",
                    p28.input.sequence_score
                },
                {
                    tag = "Text",
                    (score2(p28.input.sequence_score))
                },
                {
                    tag = "Bool",
                    p28.input.sketchy
                },
                {
                    tag = "Bool",
                    p28.input.clean
                },
                {
                    tag = "Number",
                    p28.input.sequence_timer
                },
                {
                    tag = "Number",
                    p28.input.line_score
                },
                {
                    tag = "Text",
                    (score2(p28.input.line_score))
                }
            })
        end

        if p29 == "Tricks" and p30 == "GetCurrentTrickStance" then
            return array2(rt.map(p28.input.stance, function(p32) -- line: 253
                return {
                    tag = "Bool",
                    p32
                }
            end))
        end

        if p29 == "Tricks" and p30 == "GetCurrentTrickName" then
            return {
                tag = "Text",
                "#" .. import("skate_game/scoring_hud").localize_trick(p28.input.trick_name, p28.text_assets)
            }
        end

        if p29 ~= "Tricks" or p30 ~= "GetCurrentTrickMetrics" then
            if p29 == "Tricks" and p30 == "TrickDisplay_GetAllTrickData" then
                return array2(rt.copy(p28.input.context_tricks))
            end

            error(("Unimplemented original HUD binding %*.%*"):format(p29, p30), 0)

            return
        end

        local v19 = rt.copy(p28.input.trick_metrics)

        v19[1] = {
            tag = "Text",
            "#" .. import("skate_game/scoring_hud").localize_trick(p28.input.trick_name, p28.text_assets)
        }

        return array2(v19)
    end

    p28.random = bit32.bxor(p28.random, (bit32.lshift(p28.random, 13)))
    p28.random = bit32.bxor(p28.random, (bit32.rshift(p28.random, 17)))
    p28.random = bit32.bxor(p28.random, (bit32.lshift(p28.random, 5)))

    return {
        tag = "Number",
        p28.random / 4294967296
    }
end

function t1.Runtime.load(p33, p34, p35) -- line: 282
    -- upvalues: Vm (copy), Movie (copy), t1 (copy)
    if p33 == nil then
        return {
            bindings = {
                random = 2654435769,
                input = p34,
                text_assets = p35
            }
        }
    end

    local v23 = Vm.new()

    for _, v24 in { "MovieClip", "Tricks", "FELanguage", "HUDComponents", "Math" } do
        local v25 = Vm.object(v23, {
            tag = "Native",
            v24
        })
        local v26 = Vm.object(v23, {
            tag = "Plain"
        })

        Vm.set(v23, v25, "prototype", {
            tag = "Object",
            v26
        })
        Vm.set(v23, v23.global, v24, {
            tag = "Object",
            v25
        })
    end

    Vm.set(v23, v23.global, "Screen_EdgeOffset", {
        tag = "Number",
        0
    })

    local v27 = Movie.load(p33)
    local t5 = {
        random = 2654435769,
        movie = v27,
        input = p34,
        text_assets = v27.text_assets
    }
    local v28 = t1.Bindings.host(t5)
    local t6 = {}

    for v29 in v27.characters do
        table.insert(t6, v29)
    end

    table.sort(t6)

    local t7 = {}

    for _, v30 in t6 do
        local frames = v27.characters[v30].frames

        if frames ~= nil then
            for _, v31 in frames do
                for _, v32 in v31.controls do
                    if v32.type_name == "do_init_action" then
                        table.insert(t7, v32.actions_offset or 0)
                    end
                end
            end
        end
    end

    for _, v34 in t7 do
        local v35 = v27.actions[string.format("%d", v34)]

        if v35 == nil then
            error("no entry found for key", 0)
        end

        Vm.run(v23, v35, v28)
    end

    Vm.begin_update(v23)
    Movie.initialize(v27, v23)

    local t8 = {
        controller = 18446744073709552000,
        vm = v23,
        bindings = t5,
        host = v28
    }

    t1.Runtime.drain(t8)

    local screen = Vm.get(v23, v27.root, "screen")

    if screen.tag ~= "Object" then
        error("Original HUD controller was not constructed", 0)
    end

    local v36 = screen[1]

    t8.controller = v36
    Vm.call_method(v23, v36, "ScreenShow", {
        {
            tag = "Bool",
            true
        }
    }, v28)
    t1.Runtime.drain(t8)

    return t8
end

function t1.Runtime.drain(p36) -- line: 356
    -- upvalues: Vm (copy)
    local movie = p36.bindings.movie
    local pending = movie.pending
    local n2 = 0

    while #pending > 0 do
        local v37 = table.remove(pending, 1)
        local v38 = v37[1]
        local v39 = v37[2]

        n2 += 1

        if n2 > 4096 then
            error("HUD frame action limit", 0)
        end

        if movie.instances[v38] ~= nil then
            local v40 = movie.actions[string.format("%d", v39)]

            if v40 == nil then
                error("Missing HUD action block", 0)
            end

            Vm.run_on(p36.vm, v38, v40, p36.host)
        end
    end
end

local t9 = {}

function t1.Runtime.update(p37, p38, p39, p40, p41) -- line: 393
    -- upvalues: rt (copy), Vm (copy), Movie (copy), t1 (copy), t9 (copy)
    local vm = p37.vm

    if vm ~= nil then
        Vm.begin_update(vm)
    end

    local input = p37.bindings.input

    p37.bindings.input = p38

    local input2 = p37.bindings.input
    local t10 = {}

    if input.multiplier ~= input2.multiplier then
        table.insert(t10, "UpdateMultiplier")
    end

    if input.sequence_timer ~= input2.sequence_timer or input.sequence_score ~= input2.sequence_score or input.clean ~= input2.clean or input.sketchy ~= input2.sketchy or input.line_score ~= input2.line_score then
        table.insert(t10, "UpdateTrickScoring")
    end

    local v41 = input.stance[1] ~= input2.stance[1]

    if input.stance[2] ~= input2.stance[2] then
        v41 = true
    end

    if input.stance[3] ~= input2.stance[3] then
        v41 = true
    end

    if input.stance[4] ~= input2.stance[4] or v41 then
        table.insert(t10, "UpdateStance")
    end

    if p39 then
        table.insert(t10, "RefreshTrickName")
    elseif p40 then
        table.insert(t10, "CurrentTrickModified")
    end

    if p41 then
        table.insert(t10, "CloseTrickDisplay")
    end

    if vm ~= nil then
        for _, v42 in t10 do
            Vm.call_method(vm, p37.controller, v42, {}, p37.host)
            t1.Runtime.drain(p37)
        end
    end

    if rt.trunc(input.line_time) ~= rt.trunc(input2.line_time) or input.line_score ~= input2.line_score then
        if vm ~= nil then
            Vm.call_method(vm, p37.controller, "UpdateLineDisplay", {}, p37.host)
            t1.Runtime.drain(p37)
        end

        table.insert(t10, "UpdateLineDisplay")
    end

    if vm ~= nil then
        local movie = p37.bindings.movie

        Movie.advance(movie, vm)
        t1.Runtime.drain(p37)
        table.clear(t9)

        local n3 = 0

        for v43 in movie.instances do
            n3 += 1
            t9[n3] = v43
        end

        Vm.collect(vm, t9)
    end

    return t10
end

return t1
