-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    STOCK_INPUT_PATH = "private/stock/data/config/input.cfg",
    StockGameplayConfig = {}
}

local function lines(p1) -- line: 21
    local t2 = {}
    local n1 = 1

    while true do
        if not (n1 <= #p1) then
            return t2
        end

        local v1 = string.find(p1, "\n", n1, true)

        if v1 == nil then
            break
        end

        local v3 = string.sub(p1, n1, v1 - 1)

        if string.sub(v3, -1) == "\r" then
            v3 = string.sub(v3, 1, -2)
        end

        table.insert(t2, v3)
        n1 = v1 + 1
    end

    table.insert(t2, (string.sub(p1, n1)))

    return t2
end

local function split(p2, p3) -- line: 41
    local t3 = {}
    local n2 = 1

    while true do
        local v5, v6 = string.find(p2, p3, n2, true)

        if v5 == nil then
            break
        end

        table.insert(t3, (string.sub(p2, n2, v5 - 1)))
        n2 = v6 + 1
    end

    table.insert(t3, (string.sub(p2, n2)))

    return t3
end

local function ascii_whitespace(p4) -- line: 56
    if string.find(p4, "[\194\225\226\227]") == nil then
        return p4
    end

    local v10 = string.gsub(p4, "\194[\133\160]", " ")
    local v11 = string.gsub(v10, " ", " ")
    local v12 = string.gsub(v11, "\226\128[\128-\138\168\169\175]", " ")
    local v13 = string.gsub(v12, " ", " ")

    return (string.gsub(v13, "　", " "))
end

function t1.StockGameplayConfig.load(_) -- line: 70
    -- upvalues: sim (copy), t1 (copy)
    local STOCK_INPUT_PATH = t1.STOCK_INPUT_PATH
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local input_cfg = sim_data and sim_data:FindFirstChild("input_cfg")

    if not input_cfg then
        error(string.format("Cannot read %s: ReplicatedStorage.Skate3.sim_data.input_cfg is not installed", STOCK_INPUT_PATH), 0)
    end

    local source = require(input_cfg).source
    local validate = t1.StockGameplayConfig.validate
    local ok, result = pcall(validate, source)

    if not ok then
        error(string.format("Input configuration %s: %s", STOCK_INPUT_PATH, (tostring(result))), 0)
    end

    return result
end

function t1.StockGameplayConfig.validate(p6) -- line: 89
    -- upvalues: t1 (copy), lines (copy), split (copy), ascii_whitespace (copy)
    local t4 = {}

    for _, v14 in lines(p6) do
        local v15 = string.find(v14, "//", 1, true)

        table.insert(t4, if v15 == nil then v14 else string.sub(v14, 1, v15 - 1))
    end

    local v18 = table.concat(t4, "\n")
    local t5 = {}

    for _, v19 in split(v18, ";") do
        local v20 = string.find(v19, "=", 1, true)

        if v20 ~= nil then
            local v22 = string.sub(v19, 1, v20 - 1)
            local v24 = string.sub(v19, v20 + 1)
            local v25 = string.match(ascii_whitespace(v22), "^%s*(.-)%s*$")
            local v26 = table.find(t1.BUTTON_NAMES, v25) ~= nil

            if not v26 then
                for _, v27 in t1.GAMEPLAY do
                    if v27[1] == v25 then
                        v26 = true
                        break
                    end
                end
            end

            if v26 then
                local v28 = string.gsub(ascii_whitespace(v24), "%s", "")
                local v29 = t5[v25]

                t5[v25] = v28

                if v29 ~= nil then
                    error(string.format("Duplicate gameplay input definition %s", v25), 0)
                end
            end
        end
    end

    for v30, v31 in t1.BUTTON_NAMES do
        t1.require(t5, v31, string.format("Button%d", v30 - 1))
    end

    for _, v32 in t1.GAMEPLAY do
        t1.require(t5, v32[1], v32[2])
    end

    return {}
end

function t1.require(p7, p8, p9) -- line: 136
    local v33 = p7[p8]

    if v33 == nil or v33 ~= p9 then
        if v33 ~= nil then
            error(string.format("Unsupported %s = %s; the implemented stock mapping requires %s", p8, v33, p9), 0)
        else
            error(string.format("Missing gameplay input definition %s", p8), 0)
        end
    end
end

t1.BUTTON_NAMES = {
    "DPadU",
    "DPadD",
    "DPadL",
    "DPadR",
    "Start",
    "Back",
    "LStick",
    "RStick",
    "LBumper",
    "RBumper",
    "LTrigger",
    "RTrigger",
    "A",
    "B",
    "X",
    "Y",
    "LStickR",
    "LStickL",
    "LStickU",
    "LStickD",
    "RStickR",
    "RStickL",
    "RStickU",
    "RStickD"
}
t1.GAMEPLAY = {
    { "GP_LStickX", "LStickR-LStickL" },
    { "GP_LStickY", "LStickU-LStickD" },
    { "GP_LStickIn", "LStick" },
    { "GP_RStickX", "RStickR-RStickL" },
    { "GP_RStickY", "RStickU-RStickD" },
    { "GP_RStickIn", "RStick" },
    { "GP_LTrigger", "LTrigger" },
    { "GP_RTrigger", "RTrigger" },
    { "GP_LBumper", "LBumper" },
    { "GP_RBumper", "RBumper" },
    { "GP_UDPad", "DPadU" },
    { "GP_DDPad", "DPadD" },
    { "GP_LDPad", "DPadL" },
    { "GP_RDPad", "DPadR" },
    { "GP_XFace", "X" },
    { "GP_YFace", "Y" },
    { "GP_AFace", "A" },
    { "GP_BFace", "B" }
}

return t1
