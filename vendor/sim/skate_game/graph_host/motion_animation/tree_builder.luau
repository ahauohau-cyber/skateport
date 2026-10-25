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
local AttributeName = import("skate_core/animation/output/attributes").AttributeName
local PhaseBlend = import("skate_core/animation/phase_blend").PhaseBlend
local PlaybackClip = import("skate_core/animation/playback_clip").PlaybackClip
local encode = import("skate_core/animation/skeleton_input/name").encode
local AnimationMetadata = import("skate_data/animation_metadata").AnimationMetadata
local v2 = import("skate_core/animation/playback_tree/blend_space")
local v3 = import("skate_core/animation/playback_tree/selection_space")
local t1 = {}

local function floats(p2) -- line: 27
    -- upvalues: v1 (copy)
    local v4 = table.create(#p2)

    for v5, v6 in p2 do
        buffer.writeu32(v1, 0, v6)
        v4[v5] = buffer.readf32(v1, 0)
    end

    return v4
end

function t1.build(p3, p4, p5, p6) -- line: 37
    -- upvalues: rt (copy), v1 (copy), AttributeName (copy), PhaseBlend (copy), PlaybackClip (copy), encode (copy), AnimationMetadata (copy), v2 (copy), v3 (copy), t1 (copy)
    local v7 = string.upper(p4)

    if table.find(p6, v7) ~= nil then
        error(string.format("Cyclic authored animation tree %s", v7), 0)
    end

    table.insert(p6, v7)

    local v8 = AnimationMetadata.tree(p3, p4)
    local v9

    if v8.tag == "Clip" then
        local v10 = v8[1]
        local v11 = table.create(#v10.attributes)

        for _, v12 in v10.attributes do
            local t2 = {
                name = encode(v12.name),
                kind = v12.type_id
            }

            buffer.writeu32(v1, 0, v12.begin_bits)
            t2.begin = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v12.end_bits)
            t2["end"] = buffer.readf32(v1, 0)
            t2.payload = rt.copy(v12.payload_words)
            table.insert(v11, t2)
        end

        v9 = {
            tag = "Clip",
            name = v10.name
        }

        local new = PlaybackClip.new

        buffer.writeu32(v1, 0, v10.frames_bits)

        local v13 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v10.fps_bits)

        local v14 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v10.base_speed_bits)
        v9.clip = new(v13, v14, buffer.readf32(v1, 0), v10.flags_word, v11)
    elseif v8.tag == "BlendSpace" then
        local v15 = v8[1]
        local v16 = table.create(#v15.parameters)

        for _, v17 in v15.parameters do
            table.insert(v16, encode(v17))
        end

        local v18 = table.create(#v15.children)

        for _, v19 in v15.children do
            table.insert(v18, t1.build(p3, v19, p5, p6))
        end

        local v20 = table.create(#v15.simplexes)

        for _, v21 in v15.simplexes do
            local v22 = table.create(#v21.vertex_bits)

            for _, v23 in v21.vertex_bits do
                local v24 = table.create(#v23)

                for v25, v26 in v23 do
                    buffer.writeu32(v1, 0, v26)
                    v24[v25] = buffer.readf32(v1, 0)
                end

                table.insert(v22, v24)
            end

            local v27 = table.create(#v21.normal_bits)

            for _, v28 in v21.normal_bits do
                local v29 = table.create(#v28)

                for v30, v31 in v28 do
                    buffer.writeu32(v1, 0, v31)
                    v29[v30] = buffer.readf32(v1, 0)
                end

                table.insert(v27, v29)
            end

            local t3 = {
                children = rt.copy(v21.children),
                vertices = v22,
                normals = v27
            }
            local scale_bits = v21.scale_bits
            local v32 = table.create(#scale_bits)

            for v33, v34 in scale_bits do
                buffer.writeu32(v1, 0, v34)
                v32[v33] = buffer.readf32(v1, 0)
            end

            t3.scales = v32
            table.insert(v20, t3)
        end

        v9 = {
            tag = "BlendSpace",
            (v2.BlendSpace.new(v16, v18, v20))
        }
    elseif v8.tag == "PhaseBlend" then
        local v35 = v8[1]
        local v36 = encode(v35.parameter)
        local v37 = table.create(#v35.children)

        for _, v38 in v35.children do
            table.insert(v37, t1.build(p3, v38, p5, p6))
        end

        v9 = {
            tag = "PhaseBlend",
            (PhaseBlend.new(v36, v37))
        }
    elseif v8.tag == "SelectionSpace" then
        local v39 = v8[1]
        local v40 = table.create(#v39.parameters)

        for _, v41 in v39.parameters do
            local t4 = {
                name = encode(v41.name),
                mode = v41.mode
            }

            buffer.writeu32(v1, 0, v41.weight_bits)
            t4.weight = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v41.minimum_bits)
            t4.minimum = buffer.readf32(v1, 0)
            buffer.writeu32(v1, 0, v41.maximum_bits)
            t4.maximum = buffer.readf32(v1, 0)
            table.insert(v40, t4)
        end

        local v42 = table.create(#v39.candidates)

        for _, v43 in v39.candidates do
            local child, value_bits = v43.child, v43.value_bits
            local v44 = table.create(#value_bits)

            for v45, v46 in value_bits do
                buffer.writeu32(v1, 0, v46)
                v44[v45] = buffer.readf32(v1, 0)
            end

            table.insert(v42, {
                name = child,
                values = v44,
                tree = t1.build(p3, v43.child, p5, p6)
            })
        end

        v9 = {
            tag = "SelectionSpace",
            (v3.SelectionSpace.new(v40, v42))
        }
    else
        local v47 = v8[1]
        local v48

        for _, v49 in p5 do
            if AttributeName.eq(v49[1], encode(v47.parameter)) then
                v48 = v49[2]
                break
            end
        end

        local default = v47.default

        if v48 ~= nil then
            for v50, v51 in v47.values do
                if AttributeName.eq(encode(v51), v48) then
                    default = v47.children[v50]
                    break
                end
            end
        end

        v9 = t1.build(p3, default, p5, p6)
    end

    table.remove(p6)

    return v9
end

return t1
