-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/solver/contact_build/geometry")
local v2 = import("skate_core/physics/solver/contact_build/input")
local v3 = import("skate_core/physics/solver/contact_build/publication")
local v4 = import("skate_core/physics/native_arithmetic")
local t1 = {
    ContactPreparation = {},
    ContactBuildError = {},
    ContactMassResponse = {},
    UnavailableContactMassResponse = {}
}

function t1.UnavailableContactMassResponse.inverse_effective_mass(_, p2) -- line: 47
    error({
        tag = "ReciprocalEstimateUnavailable",
        effective_mass = p2
    }, 0)
end

t1.NativeContactMassResponse = {}

function t1.NativeContactMassResponse.inverse_effective_mass(_, p4) -- line: 58
    -- upvalues: v4 (copy)
    local t2 = {}

    for v5, v6 in ipairs(p4) do
        t2[v5] = v4.reciprocal_estimate(v6)
    end

    return t2
end

function t1.prepare_contact(p5, p6) -- line: 67
    -- upvalues: v1 (copy), v2 (copy)
    return v1.prepare(v2.ContactInput.decode(p5), p6)
end

function t1.build_with_response(p7, p8, p9) -- line: 74
    -- upvalues: rt (copy), v3 (copy), t1 (copy)
    local v7 = t1.prepare_contact(p7, p8)
    local v8 = p9.inverse_effective_mass(p9, rt.copy(v7.effective_mass))

    rt.assign(p7, v3.compile(v7, v8))
end

function t1.build(p10, p11) -- line: 81
    -- upvalues: t1 (copy)
    local t4 = {}
    local t3 = {
        inverse_effective_mass = function(_, p13) -- inverse_effective_mass | line: 84
            -- upvalues: t4 (copy), t1 (copy)
            return t1.NativeContactMassResponse.inverse_effective_mass(t4, p13)
        end
    }
    local build_with_response = t1.build_with_response
    local ok, result = pcall(build_with_response, p10, p11, t3)

    if not ok then
        if type(result) == "table" and result.tag ~= nil then
            error("the native contact mass response is infallible", 0)
        end

        error(result, 0)
    end
end

return t1
