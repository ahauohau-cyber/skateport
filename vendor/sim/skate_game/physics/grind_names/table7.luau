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
            skating_id = 31,
            attribute = "BS_BLUNT",
            display = "BS Bluntslide",
            scorable_id = 8
        },
        {
            skating_id = 24,
            attribute = "BS_5_O",
            display = "BS 5-0",
            scorable_id = 6
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
            skating_id = 22,
            attribute = "BS_TAILSLIDE",
            display = "BS Tailslide",
            scorable_id = 20
        },
        {
            skating_id = 24,
            attribute = "BS_5_O",
            display = "BS 5-0",
            scorable_id = 6
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
            skating_id = 31,
            attribute = "BS_BLUNT",
            display = "BS Bluntslide",
            scorable_id = 8
        },
        {
            skating_id = 47,
            attribute = "BF_BS_5_O",
            display = "BS 5-0",
            scorable_id = 6
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
            skating_id = 22,
            attribute = "BS_TAILSLIDE",
            display = "BS Tailslide",
            scorable_id = 20
        },
        {
            skating_id = 47,
            attribute = "BF_BS_5_O",
            display = "BS 5-0",
            scorable_id = 6
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
            skating_id = 31,
            attribute = "BS_BLUNT",
            display = "BS Bluntslide",
            scorable_id = 8
        },
        {
            skating_id = 27,
            attribute = "BS_FEEBLE",
            display = "BS Feeble",
            scorable_id = 11
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
            skating_id = 22,
            attribute = "BS_TAILSLIDE",
            display = "BS Tailslide",
            scorable_id = 20
        },
        {
            skating_id = 26,
            attribute = "BS_SMITH",
            display = "BS Smith",
            scorable_id = 19
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
            skating_id = 31,
            attribute = "BS_BLUNT",
            display = "BS Bluntslide",
            scorable_id = 8
        },
        {
            skating_id = 50,
            attribute = "BF_BS_FEEBLE",
            display = "BS Feeble",
            scorable_id = 11
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
            skating_id = 22,
            attribute = "BS_TAILSLIDE",
            display = "BS Tailslide",
            scorable_id = 20
        },
        {
            skating_id = 49,
            attribute = "BF_BS_SMITH",
            display = "BS Smith",
            scorable_id = 19
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
            scorable_id = 269
        }
    }
}
