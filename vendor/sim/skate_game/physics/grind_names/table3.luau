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
            skating_id = 5,
            attribute = "FS_TAILSLIDE",
            display = "FS Tailslide",
            scorable_id = 20
        },
        {
            skating_id = 7,
            attribute = "FS_5_O",
            display = "FS 5-0",
            scorable_id = 22
        },
        {
            skating_id = 31,
            attribute = "BS_BLUNT",
            display = "BS Bluntslide",
            scorable_id = 8
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
            skating_id = 2,
            attribute = "FS_BOARD",
            display = "FS Boardslide",
            scorable_id = 25
        },
        {
            skating_id = 14,
            attribute = "FS_BLUNT",
            display = "FS Bluntslide",
            scorable_id = 24
        },
        {
            skating_id = 7,
            attribute = "FS_5_O",
            display = "FS 5-0",
            scorable_id = 22
        },
        {
            skating_id = 14,
            attribute = "FS_BLUNT",
            display = "FS Bluntslide",
            scorable_id = 24
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
            skating_id = 1,
            attribute = "FS_LIP",
            display = "FS Lipslide",
            scorable_id = 28
        },
        {
            skating_id = 5,
            attribute = "FS_TAILSLIDE",
            display = "FS Tailslide",
            scorable_id = 20
        },
        {
            skating_id = 37,
            attribute = "BF_FS_5_O",
            display = "FS 5-0",
            scorable_id = 22
        },
        {
            skating_id = 31,
            attribute = "BS_BLUNT",
            display = "BS Bluntslide",
            scorable_id = 8
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
            skating_id = 2,
            attribute = "FS_BOARD",
            display = "FS Boardslide",
            scorable_id = 25
        },
        {
            skating_id = 14,
            attribute = "FS_BLUNT",
            display = "FS Bluntslide",
            scorable_id = 24
        },
        {
            skating_id = 37,
            attribute = "BF_FS_5_O",
            display = "FS 5-0",
            scorable_id = 22
        },
        {
            skating_id = 14,
            attribute = "FS_BLUNT",
            display = "FS Bluntslide",
            scorable_id = 24
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
            skating_id = 1,
            attribute = "FS_LIP",
            display = "FS Lipslide",
            scorable_id = 28
        },
        {
            skating_id = 5,
            attribute = "FS_TAILSLIDE",
            display = "FS Tailslide",
            scorable_id = 20
        },
        {
            skating_id = 9,
            attribute = "FS_SMITH",
            display = "FS Smith",
            scorable_id = 35
        },
        {
            skating_id = 31,
            attribute = "BS_BLUNT",
            display = "BS Bluntslide",
            scorable_id = 8
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
            skating_id = 2,
            attribute = "FS_BOARD",
            display = "FS Boardslide",
            scorable_id = 25
        },
        {
            skating_id = 14,
            attribute = "FS_BLUNT",
            display = "FS Bluntslide",
            scorable_id = 24
        },
        {
            skating_id = 10,
            attribute = "FS_FEEBLE",
            display = "FS Feeble",
            scorable_id = 27
        },
        {
            skating_id = 14,
            attribute = "FS_BLUNT",
            display = "FS Bluntslide",
            scorable_id = 24
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
            skating_id = 1,
            attribute = "FS_LIP",
            display = "FS Lipslide",
            scorable_id = 28
        },
        {
            skating_id = 5,
            attribute = "FS_TAILSLIDE",
            display = "FS Tailslide",
            scorable_id = 20
        },
        {
            skating_id = 39,
            attribute = "BF_FS_SMITH",
            display = "FS Smith",
            scorable_id = 35
        },
        {
            skating_id = 31,
            attribute = "BS_BLUNT",
            display = "BS Bluntslide",
            scorable_id = 8
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
            skating_id = 2,
            attribute = "FS_BOARD",
            display = "FS Boardslide",
            scorable_id = 25
        },
        {
            skating_id = 14,
            attribute = "FS_BLUNT",
            display = "FS Bluntslide",
            scorable_id = 24
        },
        {
            skating_id = 40,
            attribute = "BF_FS_FEEBLE",
            display = "FS Feeble",
            scorable_id = 27
        },
        {
            skating_id = 14,
            attribute = "FS_BLUNT",
            display = "FS Bluntslide",
            scorable_id = 24
        },
        {
            skating_id = 17,
            attribute = "FS_DARKSLIDE",
            display = "FS Darkslide",
            scorable_id = 270
        }
    }
}
