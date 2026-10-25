-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    PostInputPlayerFields = {},
    PostInputProcessedFields = {},
    PostInputPhysOutFields = {},
    CandidatePublicationFields = {},
    CandidateRegistration = {},
    PostInputServices = {},
    PostInputContext = {}
}

function t1.run_post_input(p1, p2) -- line: 65
    -- upvalues: rt (copy), t1 (copy)
    local player, processed, phys_out, candidates = p1.player, p1.processed, p1.phys_out, p1.candidates

    p2.update_grind_manager_82d8ab08(p2)

    if phys_out.reset_state_frames_316 then
        player.state_frames_1304 = 0
    end

    player.state_frames_1304 = rt.wrapping_add_u32(player.state_frames_1304, 1)

    local flags_2480 = processed.flags_2480

    if bit32.band(flags_2480, 8192) ~= 0 or bit32.band(processed.flags_2468, 4194304) ~= 0 and bit32.band(player.flags_1296, 1073741824) ~= 0 then
        player.state_frames_1304 = 0
        player.flags_1296 = bit32.band(player.flags_1296, 3221225471)
    else
        player.flags_1296 = t1.replace_bit(player.flags_1296, 30, bit32.band(processed.flags_2468, 4194304) == 0 and 1 or 0)
        processed.flags_2468 = bit32.band(processed.flags_2468, 4290772991)
    end

    processed.state_frames_2572 = player.state_frames_1304

    if phys_out.capture_jump_reference_442 then
        player.jump_fix_frames_1308 = 1
        player.jump_reference_1264 = rt.copy(phys_out.jump_reference_128)
    else
        player.jump_fix_frames_1308 = rt.wrapping_add_u32(player.jump_fix_frames_1308, 1)
    end

    processed.jump_fix_frames_2576 = player.jump_fix_frames_1308
    processed.jump_reference_848 = rt.copy(player.jump_reference_1264)
    processed.flags_2468 = t1.replace_bit(processed.flags_2468, 10, (bit32.band(p2.update_trajectory_selector_82d68800(p2), 1)))
    processed.scalar_2740 = p2.calculate_scalar_2740_82db5e10(p2)
    processed.flags_2484 = t1.replace_bit(processed.flags_2484, 25, (bit32.band(bit32.rshift(player.flags_1296, 24), 1)))

    if bit32.band(processed.flags_2484, 2048) == 0 then
        if processed.current_state_2508 == 103 then
            processed.flags_2484 = t1.replace_bit(processed.flags_2484, 11, (bit32.band(bit32.rshift(player.flags_1296, 21), 1)))
        else
            player.flags_1296 = bit32.band(player.flags_1296, 4292870143)
        end
    else
        player.flags_1296 = bit32.bor(player.flags_1296, 2097152)
    end

    t1.update_flag_latches_82db5cf8(player, processed)
    t1.publish_candidates_82d740f8(candidates, processed, p2)
    phys_out.complete_76 = true
end

function t1.update_flag_latches_82db5cf8(p3, p4) -- line: 119
    -- upvalues: rt (copy), t1 (copy)
    if bit32.band(p4.flags_2468, 2097152) ~= 0 then
        p3.latch_frames_1320 = 0
        p3.flags_1296 = bit32.bor(p3.flags_1296, 33554432)
    end

    if not (bit32.band(p4.flags_2472, 32) == 0 and bit32.band(p4.flags_2468, 4194304) == 0) then
        p3.latch_frames_1320 = 0
        p3.flags_1296 = bit32.bor(p3.flags_1296, 100663296)
    end

    local flags_1296 = p3.flags_1296

    if bit32.band(flags_1296, 33554432) ~= 0 then
        if bit32.band(p4.flags_2472, 16) == 0 then
            if bit32.band(flags_1296, 134217728) ~= 0 and bit32.band(p4.flags_2472, 32768) == 0 then
                p3.flags_1296 = bit32.band(p3.flags_1296, 4194303999)
            end
        else
            p3.flags_1296 = bit32.band(p3.flags_1296, 4194303999)
        end

        local latch_frames_1320 = p3.latch_frames_1320

        if latch_frames_1320 > 20 and bit32.band(p3.flags_1296, 134217728) == 0 then
            p3.flags_1296 = bit32.band(p3.flags_1296, 4194303999)
        end

        p3.latch_frames_1320 = rt.wrapping_add_u32(latch_frames_1320, 1)
    end

    p3.flags_1296 = t1.replace_bit(p3.flags_1296, 28, (bit32.band(bit32.rshift(p4.flags_2472, 4), 1)))
    p3.flags_1296 = t1.replace_bit(p3.flags_1296, 27, (bit32.band(bit32.rshift(p4.flags_2472, 15), 1)))
    p3.flags_1296 = t1.replace_bit(p3.flags_1296, 17, (bit32.band(bit32.rshift(p4.flags_2480, 17), 1)))
    p4.flags_2472 = t1.replace_bit(p4.flags_2472, 3, (bit32.band(bit32.rshift(p3.flags_1296, 26), 1)))
    p4.flags_2472 = t1.replace_bit(p4.flags_2472, 2, (bit32.band(bit32.rshift(p3.flags_1296, 25), 1)))
end

function t1.publish_candidates_82d740f8(p5, p6, p7) -- line: 152
    -- upvalues: t1 (copy)
    local v12 = p5.first_pending_288 and p5.first_object_present_196

    if v12 then
        p7.register_candidate_82762ab0(p7, "First1888")
    end

    p6.flags_2480 = t1.replace_bit(p6.flags_2480, 22, v12 and 1 or 0)
    p5.first_pending_288 = false

    local v13 = p5.second_pending_592 and p5.second_object_present_500

    if v13 then
        p7.register_candidate_82762ab0(p7, "Second2176")
    end

    p6.flags_2480 = t1.replace_bit(p6.flags_2480, 21, v13 and 1 or 0)
    p5.second_pending_592 = false

    if p5.staged_pending_12780 then
        p5.staged_latched_12776 = 0

        if p5.staged_valid_12772 == 0 then
            p6.flags_2480 = bit32.band(p6.flags_2480, 4293918719)
        else
            p5.staged_latched_12776 = 1
            p6.flags_2480 = bit32.bor(p6.flags_2480, 1048576)
            p6.word_2464 = p5.staged_word_12768
        end
    end

    p5.staged_pending_12780 = false
end

function t1.replace_bit(p8, p9, p10) -- line: 181
    return (bit32.bor(bit32.band(p8, (bit32.bnot((bit32.lshift(1, p9))))), (bit32.lshift(bit32.band(p10, 1), p9))))
end

function t1.copy_grab_record_82762ab0(p11, p12) -- line: 187
    for i = 0, 49 do
        p11[i + 1] = p12[i + 1]
    end

    p11[51] = bit32.bor(bit32.band(p11[51], 536870911), (bit32.band(p12[51], 3758096384)))
    p11[52] = p12[52]
    p11[53] = p12[53]
    p11[54] = p12[54]
    p11[55] = p12[55]
    p11[57] = p12[57]
    p11[58] = p12[58]
    p11[59] = p12[59]
    p11[60] = p12[60]
    p11[61] = p12[61]
    p11[62] = p12[62]
    p11[63] = p12[63]
    p11[64] = p12[64]
    p11[65] = p12[65]
    p11[66] = p12[66]
    p11[69] = p12[69]
end

return t1
