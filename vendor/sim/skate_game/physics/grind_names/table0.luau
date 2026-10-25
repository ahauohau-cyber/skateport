-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

return {
    TABLE = {
        {
            skating_id = 3,
            attribute = "FS_50_50",
            display = "FS 50-50",
            scorable_id = 23
        },
        {
            skating_id = 1,
            attribute = "FS_LIP",
            display = "FS Lipslide",
            scorable_id = 28
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 16,
            attribute = "FS_OVERCROOK",
            display = "FS Overcrooks",
            scorable_id = 32
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS Darkslide",
            scorable_id = 270
        },
        {
            skating_id = 3,
            attribute = "FS_50_50",
            display = "FS 50-50",
            scorable_id = 23
        },
        {
            skating_id = 2,
            attribute = "FS_BOARD",
            display = "FS Boardslide",
            scorable_id = 25
        },
        {
            skating_id = 4,
            attribute = "FS_NOSESLIDE",
            display = "FS Noseslide",
            scorable_id = 31
        },
        {
            skating_id = 15,
            attribute = "FS_CROOK",
            display = "FS Crooked",
            scorable_id = 26
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
            scorable_id = 270
        },
        {
            skating_id = 35,
            attribute = "BF_FS_50_50",
            display = "FS 50-50",
            scorable_id = 23
        },
        {
            skating_id = 1,
            attribute = "FS_LIP",
            display = "FS Lipslide",
            scorable_id = 28
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 44,
            attribute = "BF_FS_OVERCROOK",
            display = "FS Overcrooks",
            scorable_id = 32
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS Darkslide",
            scorable_id = 270
        },
        {
            skating_id = 35,
            attribute = "BF_FS_50_50",
            display = "FS 50-50",
            scorable_id = 23
        },
        {
            skating_id = 2,
            attribute = "FS_BOARD",
            display = "FS Boardslide",
            scorable_id = 25
        },
        {
            skating_id = 4,
            attribute = "FS_NOSESLIDE",
            display = "FS Noseslide",
            scorable_id = 31
        },
        {
            skating_id = 43,
            attribute = "BF_FS_CROOK",
            display = "FS Crooked",
            scorable_id = 26
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
            scorable_id = 270
        },
        {
            skating_id = 3,
            attribute = "FS_50_50",
            display = "FS 50-50",
            scorable_id = 23
        },
        {
            skating_id = 1,
            attribute = "FS_LIP",
            display = "FS Lipslide",
            scorable_id = 28
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 12,
            attribute = "FS_OVERWILLY",
            display = "FS Over Willy",
            scorable_id = 33
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS Darkslide",
            scorable_id = 270
        },
        {
            skating_id = 3,
            attribute = "FS_50_50",
            display = "FS 50-50",
            scorable_id = 23
        },
        {
            skating_id = 2,
            attribute = "FS_BOARD",
            display = "FS Boardslide",
            scorable_id = 25
        },
        {
            skating_id = 4,
            attribute = "FS_NOSESLIDE",
            display = "FS Noseslide",
            scorable_id = 31
        },
        {
            skating_id = 11,
            attribute = "FS_WILLY",
            display = "FS Willy",
            scorable_id = 37
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
            scorable_id = 270
        },
        {
            skating_id = 35,
            attribute = "BF_FS_50_50",
            display = "FS 50-50",
            scorable_id = 23
        },
        {
            skating_id = 1,
            attribute = "FS_LIP",
            display = "FS Lipslide",
            scorable_id = 28
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 42,
            attribute = "BF_FS_OVERWILLY",
            display = "FS Over Willy",
            scorable_id = 33
        },
        {
            skating_id = 13,
            attribute = "FS_NOSEBLUNT",
            display = "FS Noseblunt",
            scorable_id = 29
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS Darkslide",
            scorable_id = 270
        },
        {
            skating_id = 35,
            attribute = "BF_FS_50_50",
            display = "FS 50-50",
            scorable_id = 23
        },
        {
            skating_id = 2,
            attribute = "FS_BOARD",
            display = "FS Boardslide",
            scorable_id = 25
        },
        {
            skating_id = 4,
            attribute = "FS_NOSESLIDE",
            display = "FS Noseslide",
            scorable_id = 31
        },
        {
            skating_id = 41,
            attribute = "BF_FS_WILLY",
            display = "FS Willy",
            scorable_id = 37
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
            scorable_id = 270
        }
    }
}
