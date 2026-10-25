-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

return {
    Vector4 = {},
    GroundContactStateInput = {},
    update = function(p1, p2, p3) -- update | line: 39
        -- upvalues: rt (copy)
        if bit32.band(p2.flags_2476, 4194304) ~= 0 then
            local v1 = bit32.band(p2.flags_2480, 536870912) == 0
            local v2 = if v1 then bit32.band(p2.flags_2480, 268435456) == 0 else nil

            if not v1 or v2 then
                p1.tracked_contact_2760 = nil
                p1.differing_contact_frames_2756 = 0
            end

            if bit32.band(p2.flags_2480, 268435456) ~= 0 then
                if p2.axis_464[2] < 0.949999988079071 then
                    if p1.tracked_contact_2760 == nil then
                        p1.tracked_contact_2760 = p3.initial_contact_handle_1920(p3)
                    end

                    if p3.identify_contact_82d63c30(p3, p2) == p1.tracked_contact_2760 then
                        p1.differing_contact_frames_2756 = 0
                    else
                        p1.differing_contact_frames_2756 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.differing_contact_frames_2756), 1))
                    end

                    if p1.differing_contact_frames_2756 > p2.differing_contact_frame_limit then
                        p1.tracked_contact_2760 = nil
                    end
                else
                    p1.tracked_contact_2760 = nil
                end
            end

            return p3.publish_contact_82d61268(p3, p2, p1.tracked_contact_2760)
        end

        p3.stop_contact_tracking_82d62f20(p3)
        p3.clear_inactive_contact_output_3024(p3)
    end
}
