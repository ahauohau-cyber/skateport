-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    PreStatePacket = {}
}

t1.PreStatePacket.ZERO = {
    words = table.create(18, 0)
}

function t1.PreStatePacket.vector_48(p1) -- line: 20
    return {
        p1.words[13],
        p1.words[14],
        p1.words[15],
        p1.words[16]
    }
end

t1.PreStatePlayerFields = {}
t1.PreStateSkeletonFields = {}
t1.PreStateServices = {}

function t1.run_pre_state(p2, p3, p4) -- line: 51
    -- upvalues: rt (copy), t1 (copy)
    p2.frame_counter_1312 = rt.wrapping_add_u32(p2.frame_counter_1312, 1)

    local v1 = rt.copy(t1.PreStatePacket.ZERO)

    p4.fill_packet_vtable_24(p4, v1)
    p3.predicted_position_16112 = t1.PreStatePacket.vector_48(v1)
    p3.predicted_position_set_16416 = true
    p3.nested_flag_3184 = false

    if p2.component_1840_present then
        p4.update_component_1840_82d74270(p4)
    end

    p4.update_before_state_vtable_4(p4)
end

return t1
