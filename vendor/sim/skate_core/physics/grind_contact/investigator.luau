-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_contact")
local v2 = import("skate_core/physics/grind_contact/admission")
local v3 = import("skate_core/physics/grind_contact/families")
local Admission = v2.Admission
local truck_contacts, deck_contact, fifty_fifty_candidate_on_splines, boardslide_candidate = v1.truck_contacts, v1.deck_contact, v1.fifty_fifty_candidate_on_splines, v1.boardslide_candidate
local v4
local t1 = {}

t1.Query = {}
t1.Proximity = {}
t1.Investigation = {}

function t1.Investigation.default() -- line: 58
    return {
        candidate = nil,
        proximity = nil
    }
end

function t1.investigate(p1, p2) -- line: 63
    -- upvalues: rt (copy), v3 (copy), t1 (copy), Admission (copy), truck_contacts (copy), deck_contact (copy), fifty_fifty_candidate_on_splines (copy), boardslide_candidate (copy), v4 (ref)
    if #p2 == 0 then
        return t1.Investigation.default()
    end

    local admission = p1.admission
    local v5 = truck_contacts(p1.board, p1.flags_2484, p1.truck_to_wheel, p1.deck_to_truck, p2)
    local v6 = v3.tip_contacts(p1.board, p1.flags_2484, p1.tip_state, p1.flags_2468, p1.deck_to_truck, p2)
    local v7 = deck_contact(p1.board, p1.flags_2484, p1.test_above, p1.test_below, p1.deck_to_truck, p2)
    local v8 = v3.inverted_contact(p1.board, p1.flags_2484, p1.test_above, p1.test_below, p2)

    if not p1.forbidden then
        local function fifty() -- line: 75
            -- upvalues: p1 (copy), p2 (copy), admission (copy), v5 (copy), Admission (copy), fifty_fifty_candidate_on_splines (copy)
            local v9 = fifty_fifty_candidate_on_splines(p1.board, {
                p1.translation,
                p1.stability_nudge
            }, v5, p2)

            if v9 ~= nil then
                local v10 = Admission.test(admission, 401, v9.direction, false)

                if v10.allowed then
                    return {
                        front = false,
                        kind = 0,
                        geometry = v9,
                        entry_kind = v10.kind
                    }
                end
            end

            return nil
        end

        local function five() -- line: 87
            -- upvalues: p1 (copy), p2 (copy), admission (copy), v5 (copy), v3 (copy)
            return v3.five_o(p1.board, v5, p2, admission.velocity, p1.flags_2476, p1.flags_2472, p1.ground_frames, p1.translation, admission)
        end

        local function tip() -- line: 100
            -- upvalues: p1 (copy), p2 (copy), admission (copy), v6 (copy), v3 (copy)
            return v3.tipslide(p1.board, v6, p2, admission.velocity, admission.category, p1.flags_2476, p1.flags_2472, p1.ground_frames, p1.balance, p1.reference_right, admission)
        end

        local function slide() -- line: 115
            -- upvalues: p1 (copy), p2 (copy), admission (copy), v7 (copy), rt (copy), Admission (copy), boardslide_candidate (copy)
            if v7 == nil then
                return nil
            end

            local v11 = boardslide_candidate(p1.board, v7, p2[v7.primitive + 1], admission.velocity, admission.category, rt.to_i32(p1.low_wheel_frames), p1.flags_2476, p1.deck_to_truck, p1.truck_to_wheel, admission)

            return if v11 ~= nil then {
                front = false,
                kind = 1,
                geometry = v11,
                entry_kind = Admission.test(admission, 400, v11.direction, false).kind
            } else nil
        end

        local function dark() -- line: 142
            -- upvalues: p1 (copy), p2 (copy), admission (copy), v8 (copy), v3 (copy)
            if v8 == nil then
                return nil
            end

            return v3.darkslide(p1.board, v8, p2[v8.primitive + 1], admission.velocity, admission.category, p1.low_wheel_frames, admission)
        end

        local v12 = if admission.state == 401 or admission.state == 403 then fifty() or v3.five_o(p1.board, v5, p2, admission.velocity, p1.flags_2476, p1.flags_2472, p1.ground_frames, p1.translation, admission)
            elseif admission.state == 402 or admission.state == 404 then v3.tipslide(p1.board, v6, p2, admission.velocity, admission.category, p1.flags_2476, p1.flags_2472, p1.ground_frames, p1.balance, p1.reference_right, admission)
            elseif admission.state == 400 then slide()
            elseif admission.state == 405 and v8 ~= nil then v3.darkslide(p1.board, v8, p2[v8.primitive + 1], admission.velocity, admission.category, p1.low_wheel_frames, admission)
            else nil

        if not v12 then
            v12 = fifty()

            if not v12 then
                v12 = v3.five_o(p1.board, v5, p2, admission.velocity, p1.flags_2476, p1.flags_2472, p1.ground_frames, p1.translation, admission)

                if not v12 then
                    v12 = v3.tipslide(p1.board, v6, p2, admission.velocity, admission.category, p1.flags_2476, p1.flags_2472, p1.ground_frames, p1.balance, p1.reference_right, admission)

                    if not v12 then
                        v12 = slide()

                        if not v12 then
                            v12 = if v8 ~= nil then v3.darkslide(p1.board, v8, p2[v8.primitive + 1], admission.velocity, admission.category, p1.low_wheel_frames, admission) else nil
                        end
                    end
                end
            end
        end

        if v12 ~= nil then
            return {
                proximity = nil,
                candidate = v12
            }
        end
    end

    return {
        candidate = nil,
        proximity = v4(v5, v7, v8, v6)
    }
end

v4 = function(p3, p4, p5, p6) -- line: 178
    -- upvalues: rt (copy)
    local v13 = p3[1] or p3[2]

    if v13 ~= nil then
        return {
            deck_contact = false,
            contact = rt.copy(v13)
        }
    end

    if p4 ~= nil then
        return {
            deck_contact = true,
            contact = rt.copy(p4)
        }
    end

    p5 = p5 or p6[1] or p6[2]

    return if p5 ~= nil then {
        deck_contact = false,
        contact = rt.copy(p5)
    } else nil
end

t1.fallback = v4

return t1
