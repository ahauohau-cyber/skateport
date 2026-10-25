-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_data/abin")
local v2 = import("skate_data/animation_metadata")
local v3 = import("skate_data/sha256")
local Bank = v1.Bank
local AnimationMetadata = v2.AnimationMetadata
local t1 = {}

local function error_text(p1) -- line: 19
    -- upvalues: v1 (copy)
    if type(p1) == "table" and p1.message ~= nil and p1.offset ~= nil then
        return v1.Error.to_string(p1)
    end

    return (tostring(p1))
end

t1.AnimationBanks = {}

function t1.AnimationBanks.load(p2) -- line: 32
    -- upvalues: v1 (copy), v3 (copy), Bank (copy), error_text (copy)
    local t2 = {}
    local t3 = {}

    for _, v4 in { "OnBoard", "OffBoard" } do
        local v5 = string.format("private/stock/data/anim/%s.abin", v4)

        if p2 ~= nil and p2 ~= "" then
            v5 = p2 .. "/" .. v5
        end

        local load = Bank.load
        local ok, result = pcall(load, v5)

        if not ok then
            error(string.format("%s: %s", v4, error_text(result)), 0)
        end

        local validate_positional_parts = Bank.validate_positional_parts
        local ok2, result2 = pcall(validate_positional_parts, result)

        if not ok2 then
            error(if type(result2) ~= "table" then tostring(result2) elseif result2.message == nil or result2.offset == nil then tostring(result2) else v1.Error.to_string(result2), 0)
        end

        local v6 = Bank.source_sha256(result)

        if v6 == nil then
            v6 = v3.digest(Bank.bytes(result))
        end

        table.insert(t3, v6)
        table.insert(t2, result)
    end

    local v7 = Bank.hierarchy(t2[1])

    if v7 == nil then
        error("OnBoard has no animation hierarchy", 0)
    end

    local v8 = Bank.hierarchy(t2[2])

    if v8 == nil then
        error("OffBoard has no animation hierarchy", 0)
    end

    if not v1.Hierarchy.compatible_with(v7, v8) then
        error("Skater animation bank hierarchies differ", 0)
    end

    return {
        banks = t2,
        identities = t3
    }
end

function t1.AnimationBanks.metadata(p3) -- line: 70
    -- upvalues: AnimationMetadata (copy)
    local v9 = AnimationMetadata.from_bank(p3.banks[1], "OnBoard.abin", p3.identities[1])

    AnimationMetadata.merge(v9, AnimationMetadata.from_bank(p3.banks[2], "OffBoard.abin", p3.identities[2]))

    return v9
end

return t1
