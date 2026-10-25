-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

return {
    TABLE = {
        {
            skating_id = 20,
            attribute = "BS_50_50",
            display = "BS 50-50",
            scorable_id = 7
        },
        {
            skating_id = 19,
            attribute = "BS_BOARD",
            display = "BS Boardslide",
            scorable_id = 9
        },
        {
            skating_id = 21,
            attribute = "BS_NOSESLIDE",
            display = "BS Noseslide",
            scorable_id = 15
        },
        {
            skating_id = 23,
            attribute = "BS_NOSEGRIND",
            display = "BS Nosegrind",
            scorable_id = 14
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS_Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS_Darkslide",
            scorable_id = 269
        },
        {
            skating_id = 20,
            attribute = "BS_50_50",
            display = "BS 50-50",
            scorable_id = 7
        },
        {
            skating_id = 18,
            attribute = "BS_LIP",
            display = "BS Lipslide",
            scorable_id = 12
        },
        {
            skating_id = 30,
            attribute = "BS_NOSEBLUNT",
            display = "BS Noseblunt",
            scorable_id = 13
        },
        {
            skating_id = 23,
            attribute = "BS_NOSEGRIND",
            display = "BS Nosegrind",
            scorable_id = 14
        },
        {
            skating_id = 30,
            attribute = "BS_NOSEBLUNT",
            display = "BS Noseblunt",
            scorable_id = 13
        },
        {
            skating_id = 34,
            attribute = "BS_DARKSLIDE",
            display = "BS Darkslide",
            scorable_id = 269
        },
        {
            skating_id = 45,
            attribute = "BF_BS_50_50",
            display = "BS 50-50",
            scorable_id = 7
        },
        {
            skating_id = 19,
            attribute = "BS_BOARD",
            display = "BS Boardslide",
            scorable_id = 9
        },
        {
            skating_id = 21,
            attribute = "BS_NOSESLIDE",
            display = "BS Noseslide",
            scorable_id = 15
        },
        {
            skating_id = 46,
            attribute = "BF_BS_NOSEGRIND",
            display = "BS Nosegrind",
            scorable_id = 14
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS_Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS_Darkslide",
            scorable_id = 269
        },
        {
            skating_id = 45,
            attribute = "BF_BS_50_50",
            display = "BS 50-50",
            scorable_id = 7
        },
        {
            skating_id = 18,
            attribute = "BS_LIP",
            display = "BS Lipslide",
            scorable_id = 12
        },
        {
            skating_id = 30,
            attribute = "BS_NOSEBLUNT",
            display = "BS Noseblunt",
            scorable_id = 13
        },
        {
            skating_id = 46,
            attribute = "BF_BS_NOSEGRIND",
            display = "BS Nosegrind",
            scorable_id = 14
        },
        {
            skating_id = 30,
            attribute = "BS_NOSEBLUNT",
            display = "BS Noseblunt",
            scorable_id = 13
        },
        {
            skating_id = 34,
            attribute = "BS_DARKSLIDE",
            display = "BS Darkslide",
            scorable_id = 269
        },
        {
            skating_id = 20,
            attribute = "BS_50_50",
            display = "BS 50-50",
            scorable_id = 7
        },
        {
            skating_id = 19,
            attribute = "BS_BOARD",
            display = "BS Boardslide",
            scorable_id = 9
        },
        {
            skating_id = 21,
            attribute = "BS_NOSESLIDE",
            display = "BS Noseslide",
            scorable_id = 15
        },
        {
            skating_id = 28,
            attribute = "BS_WILLY",
            display = "BS Willy",
            scorable_id = 21
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS_Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS_Darkslide",
            scorable_id = 269
        },
        {
            skating_id = 20,
            attribute = "BS_50_50",
            display = "BS 50-50",
            scorable_id = 7
        },
        {
            skating_id = 18,
            attribute = "BS_LIP",
            display = "BS Lipslide",
            scorable_id = 12
        },
        {
            skating_id = 30,
            attribute = "BS_NOSEBLUNT",
            display = "BS Noseblunt",
            scorable_id = 13
        },
        {
            skating_id = 29,
            attribute = "BS_OVERWILLY",
            display = "BS Over Willy",
            scorable_id = 17
        },
        {
            skating_id = 30,
            attribute = "BS_NOSEBLUNT",
            display = "BS Noseblunt",
            scorable_id = 13
        },
        {
            skating_id = 34,
            attribute = "BS_DARKSLIDE",
            display = "BS Darkslide",
            scorable_id = 269
        },
        {
            skating_id = 45,
            attribute = "BF_BS_50_50",
            display = "BS 50-50",
            scorable_id = 7
        },
        {
            skating_id = 19,
            attribute = "BS_BOARD",
            display = "BS Boardslide",
            scorable_id = 9
        },
        {
            skating_id = 21,
            attribute = "BS_NOSESLIDE",
            display = "BS Noseslide",
            scorable_id = 15
        },
        {
            skating_id = 51,
            attribute = "BF_BS_WILLY",
            display = "BS Willy",
            scorable_id = 21
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS_Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS_Darkslide",
            scorable_id = 269
        },
        {
            skating_id = 45,
            attribute = "BF_BS_50_50",
            display = "BS 50-50",
            scorable_id = 7
        },
        {
            skating_id = 18,
            attribute = "BS_LIP",
            display = "BS Lipslide",
            scorable_id = 12
        },
        {
            skating_id = 30,
            attribute = "BS_NOSEBLUNT",
            display = "BS Noseblunt",
            scorable_id = 13
        },
        {
            skating_id = 52,
            attribute = "BF_BS_OVERWILLY",
            display = "BS Over Willy",
            scorable_id = 17
        },
        {
            skating_id = 30,
            attribute = "BS_NOSEBLUNT",
            display = "BS Noseblunt",
            scorable_id = 13
        },
        {
            skating_id = 34,
            attribute = "BS_DARKSLIDE",
            display = "BS Darkslide",
            scorable_id = 269
        }
    }
}
