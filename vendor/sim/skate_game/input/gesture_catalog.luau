-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    Group = {
        Square = 0,
        Nose = 1,
        Tail = 2,
        Nose90 = 3,
        Tail90 = 4,
        NoseN90 = 5,
        TailN90 = 6
    }
}

function t1.Group.parse(p1) -- line: 27
    -- upvalues: t1 (copy)
    if p1 == "Square" then
        return t1.Group.Square
    end

    if p1 == "Nose" then
        return t1.Group.Nose
    end

    if p1 == "Tail" then
        return t1.Group.Tail
    end

    if p1 == "90Nose" then
        return t1.Group.Nose90
    end

    if p1 == "90Tail" then
        return t1.Group.Tail90
    end

    if p1 == "N90Nose" then
        return t1.Group.NoseN90
    end

    if p1 == "N90Tail" then
        return t1.Group.TailN90
    end

    error("HasGestureIntent has undefined group `" .. p1 .. "`", 0)
end

function t1.Group.has_intent(p2, p3) -- line: 50
    -- upvalues: t1 (copy)
    local v1 = if p2 == t1.Group.Square or p2 == t1.Group.Nose or p2 == t1.Group.Tail then {}
        elseif p2 == t1.Group.Nose90 then t1.NOSE_90
        elseif p2 == t1.Group.Tail90 then t1.TAIL_90
        elseif p2 == t1.Group.NoseN90 then t1.NOSE_N90
        else t1.TAIL_N90

    for _, v2 in t1.COMMON do
        if p3(v2) then
            return true
        end
    end

    for _, v3 in v1 do
        if p3(v3) then
            return true
        end
    end

    return false
end

t1.COMMON = {
    "Ollie",
    "PopShuvit",
    "FSPopShuvit",
    "VarialKickflip",
    "VarialHeelflip",
    "Hardflip",
    "InwardHeelflip",
    "360PopShuvit",
    "FS360PopShuvit",
    "360Flip",
    "Laserflip",
    "360Hardflip",
    "360InwardHeelflip",
    "Kickflip",
    "Heelflip",
    "Nollie",
    "N_PopShuvit",
    "N_FSPopShuvit",
    "N_VarialKickflip",
    "N_VarialHeelflip",
    "N_Hardflip",
    "N_InwardHeelflip",
    "N_360PopShuvit",
    "N_FS360PopShuvit",
    "N_360Flip",
    "N_Laserflip",
    "N_360Hardflip",
    "N_360InwardHeelflip",
    "N_Kickflip",
    "N_Heelflip"
}
t1.TAIL_90 = {
    "90_Ollie",
    "90_PopShuvit",
    "90_FSPopShuvit",
    "90_VarialKickflip",
    "90_VarialHeelflip",
    "90_Hardflip",
    "90_InwardHeelflip",
    "90_360PopShuvit",
    "90_FS360PopShuvit",
    "90_360Flip",
    "90_Laserflip",
    "90_360Hardflip",
    "90_360InwardHeelflip",
    "90_Kickflip",
    "90_Heelflip"
}
t1.TAIL_N90 = {
    "N90_Ollie",
    "N90_PopShuvit",
    "N90_FSPopShuvit",
    "N90_VarialKickflip",
    "N90_VarialHeelflip",
    "N90_Hardflip",
    "N90_InwardHeelflip",
    "N90_360PopShuvit",
    "N90_FS360PopShuvit",
    "N90_360Flip",
    "N90_Laserflip",
    "N90_360Hardflip",
    "N90_360InwardHeelflip",
    "N90_Kickflip",
    "N90_Heelflip"
}
t1.NOSE_90 = {
    "90_Nollie",
    "90_N_PopShuvit",
    "90_N_FSPopShuvit",
    "90_N_VarialKickflip",
    "90_N_VarialHeelflip",
    "90_N_Hardflip",
    "90_N_InwardHeelflip",
    "90_N_360PopShuvit",
    "90_N_FS360PopShuvit",
    "90_N_360Flip",
    "90_N_Laserflip",
    "90_N_360Hardflip",
    "90_N_360InwardHeelflip",
    "90_N_Kickflip",
    "90_N_Heelflip"
}
t1.NOSE_N90 = {
    "N90_Nollie",
    "N90_N_PopShuvit",
    "N90_N_FSPopShuvit",
    "N90_N_VarialKickflip",
    "N90_N_VarialHeelflip",
    "N90_N_Hardflip",
    "N90_N_InwardHeelflip",
    "N90_N_360PopShuvit",
    "N90_N_FS360PopShuvit",
    "N90_N_360Flip",
    "N90_N_Laserflip",
    "N90_N_360Hardflip",
    "N90_N_360InwardHeelflip",
    "N90_N_Kickflip",
    "N90_N_Heelflip"
}

return t1
