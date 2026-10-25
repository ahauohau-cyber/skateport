-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    Entry = {}
}

function t1.Entry.asset_path(p1, p2) -- line: 24
    return (("%*entries/%*/%*"):format(if p1.asset_prefix == "" then "characters://" else p1.asset_prefix, p1.id, p2))
end

function t1.native_animation_style(p3) -- line: 30
    if p3 == "danny_way" then
        return "DannyWay"
    end

    if p3 == "mike_carroll" then
        return "MikeCarroll"
    end

    if p3 == "pj_ladd" then
        return "PJLadd"
    end

    if p3 == "jason_dill" then
        return "JasonDill"
    end

    if p3 == "jerry_hsu" then
        return "JerryHsu"
    end

    if p3 == "rob_dyrdek" then
        return "RobDyrdek"
    end

    return "Aggressive"
end

t1.CustomModels = {}

function t1.CustomModels.default() -- line: 56
    return {
        open = false,
        just_opened = false,
        active = nil,
        request = nil,
        status = "",
        selected = 0,
        scroll = 0,
        filter = 0,
        dirty = false,
        entries = {}
    }
end

function t1.CustomModels.native_style(p4) -- line: 72
    -- upvalues: t1 (copy)
    if p4.active == nil then
        return nil
    end

    for _, v1 in p4.entries do
        if v1.id == p4.active then
            if v1.native == nil then
                return nil
            end

            return t1.native_animation_style(v1.native.key)
        end
    end

    return nil
end

function t1.CustomModels.visible_entries(p5) -- line: 88
    local t2 = {}

    for _, v2 in p5.entries do
        if if p5.filter == 1 then v2.native ~= nil and v2.native.category == "Pro" elseif p5.filter == 2 then v2.native ~= nil and v2.native.category == "Special" else p5.filter ~= 3 or v2.native == nil then
            table.insert(t2, v2)
        end
    end

    return t2
end

function t1.CustomModels.begin(p6) -- line: 108
    p6.open = true
    p6.just_opened = true
    p6.dirty = true
end

function t1.CustomModels.request_stock(p7) -- line: 114
    p7.request = {
        tag = "Some",
        nil
    }
end

function t1.valid_id(p8) -- line: 119
    if #p8 == 64 then
        return string.find(p8, "^[0-9a-f]+$") ~= nil
    end

    return false
end

return t1
