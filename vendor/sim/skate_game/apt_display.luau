-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Control = {},
    Placement = {}
}

function t1.Placement.eq(p1, p2) -- line: 37
    if p1.character ~= p2.character or p1.ratio ~= p2.ratio or p1.name ~= p2.name or p1.clip_depth ~= p2.clip_depth or p1.blend_mode ~= p2.blend_mode then
        return false
    end

    for i = 1, 6 do
        if p1.matrix[i] ~= p2.matrix[i] then
            return false
        end
    end

    for i = 1, 8 do
        if p1.color[i] ~= p2.color[i] then
            return false
        end
    end

    return true
end

t1.DisplayList = {}

function t1.DisplayList.default() -- line: 65
    return {
        depths = {}
    }
end

function t1.DisplayList.apply(p3, p4) -- line: 70
    -- upvalues: rt (copy)
    local type_name = p4.type_name

    if type_name == "remove_object2" or type_name == "remove_object3" then
        p3.depths[p4.depth or 0] = nil
    elseif type_name == "place_object2" or type_name == "place_object3" then
        local v1 = p4.flags or 0
        local v2 = p4.depth or 0

        if (p4.filter_pointer or 0) ~= 0 then
            error("APT placement filter is not implemented", 0)
        end

        if bit32.band(v1, 128) ~= 0 and (p4.actions_offset or 0) ~= 0 then
            error("APT placement clip actions are not implemented", 0)
        end

        local v3

        if bit32.band(v1, 1) == 0 then
            local character_id = p4.character_id

            if bit32.band(v1, 2) == 0 then
                character_id = nil
            end

            if character_id == nil then
                error("APT new placement lacks character", 0)
            end

            v3 = {
                ratio = 0,
                name = "",
                clip_depth = -1,
                blend_mode = -1,
                character = character_id,
                matrix = { 1, 0, 0, 1, 0, 0 },
                color = { 255, 255, 255, 255, 0, 0, 0, 0 }
            }
        else
            local v4 = p3.depths[v2]

            if v4 == nil then
                error(("APT move references empty depth %*"):format(v2), 0)
            end

            v3 = rt.copy(v4)
        end

        if bit32.band(v1, 2) ~= 0 then
            if p4.character_id == nil then
                error("APT character flag lacks value", 0)
            end

            v3.character = p4.character_id
        end

        if bit32.band(v1, 4) ~= 0 then
            if p4.matrix == nil then
                error("APT matrix flag lacks value", 0)
            end

            v3.matrix = rt.copy(p4.matrix)
        end

        if bit32.band(v1, 8) ~= 0 then
            if p4.color_transform == nil then
                error("APT color flag lacks value", 0)
            end

            v3.color = rt.copy(p4.color_transform)
        end

        if bit32.band(v1, 16) ~= 0 then
            if p4.ratio == nil then
                error("APT ratio flag lacks value", 0)
            end

            v3.ratio = p4.ratio
        end

        if bit32.band(v1, 32) ~= 0 then
            if p4.name == nil then
                error("APT name flag lacks value", 0)
            end

            v3.name = p4.name
        end

        if bit32.band(v1, 64) ~= 0 then
            if p4.clip_depth == nil then
                error("APT clip-depth flag lacks value", 0)
            end

            v3.clip_depth = p4.clip_depth
        end

        if type_name == "place_object3" then
            local blend_mode = p4.blend_mode

            if blend_mode == nil then
                blend_mode = -1
            end

            v3.blend_mode = blend_mode
        end

        p3.depths[v2] = v3
    elseif type_name ~= "do_action" and type_name ~= "do_init_action" and type_name ~= "frame_label" then
        if type_name == "background_color" then
            return
        end

        error(("Unsupported APT control %*"):format(type_name), 0)
    end
end

return t1
