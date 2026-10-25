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
local Accumulator = import("skate_core/animation/skeleton_input/attribute_finalization").Accumulator
local v2 = import("skate_core/animation/skeleton_input/catalog")
local v3 = import("skate_core/animation/skeleton_input/contact_events")
local v4 = import("skate_core/animation/skeleton_input/extended_attributes")
local v5 = import("skate_core/animation/skeleton_input/scalar_attributes")
local t1 = {}

local function debug_attribute_name(p2) -- line: 25
    local v6 = p2[1]

    return "AttributeName([" .. tostring(v6[1]) .. ", " .. tostring(v6[2]) .. ", " .. tostring(v6[3]) .. ", " .. tostring(v6[4]) .. ", " .. tostring(v6[5]) .. "])"
end

local function debug_scalar_attribute(p3) -- line: 40
    local name = p3.name
    local v16 = p3.encoded_name[1]

    return "ScalarAttribute { name: \"" .. name .. "\", encoded_name: " .. ("AttributeName([" .. tostring(v16[1]) .. ", " .. tostring(v16[2]) .. ", " .. tostring(v16[3]) .. ", " .. tostring(v16[4]) .. ", " .. tostring(v16[5]) .. "])") .. ", comparison_site: " .. tostring(p3.comparison_site) .. " }"
end

local function debug_dispatch_error(p4) -- line: 50
    if type(p4) ~= "table" then
        return (tostring(p4))
    end

    if p4.tag == "EventConsumerUnavailable" then
        local v27 = p4.name[1]

        return "EventConsumerUnavailable { name: " .. ("AttributeName([" .. tostring(v27[1]) .. ", " .. tostring(v27[2]) .. ", " .. tostring(v27[3]) .. ", " .. tostring(v27[4]) .. ", " .. tostring(v27[5]) .. "])") .. " }"
    end

    local v37 = tostring(p4.tag)
    local attribute = p4.attribute
    local name = attribute.name
    local v38 = attribute.encoded_name[1]

    return v37 .. " { attribute: " .. ("ScalarAttribute { name: \"" .. name .. "\", encoded_name: " .. ("AttributeName([" .. tostring(v38[1]) .. ", " .. tostring(v38[2]) .. ", " .. tostring(v38[3]) .. ", " .. tostring(v38[4]) .. ", " .. tostring(v38[5]) .. "])") .. ", comparison_site: " .. tostring(attribute.comparison_site) .. " }") .. " }"
end

function t1.process(p5, p6, p7, p8, p9, p10, p11, p12, p13) -- line: 63
    -- upvalues: rt (copy), v1 (copy), Accumulator (copy), v2 (copy), v3 (copy), v4 (copy), v5 (copy)
    local v49 = Accumulator.new()

    for v50, v51 in p5 do
        local v52 = v50 - 1

        local function v53() -- line: 67
            -- upvalues: p6 (copy), p7 (copy), p8 (copy), p9 (copy), p10 (copy), p11 (copy), p13 (copy), v49 (copy), v51 (copy), v1 (copy), Accumulator (copy), v2 (copy), v3 (copy), v4 (copy), v5 (copy)
            if v51.kind == 3 then
                return v3.dispatch(v51, p6, p7, p9)
            end

            local dispatch_attribute = v5.dispatch_attribute
            local ok, result = pcall(dispatch_attribute, v51, p7, p11)

            if ok then
                return
            end

            if type(result) ~= "table" or result.tag ~= "KnownScalarUnavailable" then
                local _error = error
                local v54

                if type(result) == "table" then
                    if result.tag == "EventConsumerUnavailable" then
                        local v55 = result.name[1]

                        v54 = "EventConsumerUnavailable { name: " .. ("AttributeName([" .. tostring(v55[1]) .. ", " .. tostring(v55[2]) .. ", " .. tostring(v55[3]) .. ", " .. tostring(v55[4]) .. ", " .. tostring(v55[5]) .. "])") .. " }"
                    else
                        local v65 = tostring(result.tag)
                        local attribute = result.attribute
                        local name = attribute.name
                        local v66 = attribute.encoded_name[1]

                        v54 = v65 .. " { attribute: " .. ("ScalarAttribute { name: \"" .. name .. "\", encoded_name: " .. ("AttributeName([" .. tostring(v66[1]) .. ", " .. tostring(v66[2]) .. ", " .. tostring(v66[3]) .. ", " .. tostring(v66[4]) .. ", " .. tostring(v66[5]) .. "])") .. ", comparison_site: " .. tostring(attribute.comparison_site) .. " }") .. " }"
                    end
                else
                    v54 = tostring(result)
                end

                _error(("Invalid scalar payload: %*"):format(v54), 0)
            end

            local v77 = v2.lookup(v51.name)

            if v77 == nil then
                error("called `Option::unwrap()` on a `None` value", 0)
            end

            local name = v77.name

            local function scalar() -- line: 84
                -- upvalues: name (copy), v51 (copy), v1 (copy)
                local v78 = v51.payload[1][1]

                if v78 == nil then
                    error(("%*: scalar payload absent"):format(name), 0)
                end

                buffer.writeu32(v1, 0, v78)

                return (buffer.readf32(v1, 0))
            end

            if not Accumulator.dispatch(v49, name, scalar, p7, p10, p13) and not v4.dispatch(name, scalar, p7, p8, p11) then
                error(("Unimplemented known Skeleton attribute %*"):format(name), 0)
            end
        end

        local ok, result = pcall(v53)

        if not ok then
            error(("Skeleton attribute%*: %*"):format(v52, (tostring(result))), 0)
        end
    end

    Accumulator.finish(v49, p7, p8, p10, rt.copy(p12), p13)
end

return t1
