-- tachyon model table fixerupper
local tachyon_to_mobo = {
    [0x00140000] = "TA-079v1/v2/v3", -- DEV/TEST
    [0x00200000] = "TA-079v4/v5",
    [0x00300000] = "TA-081v1/v2",
    [0x00400000] = "TA-082/TA-086",
    [0x00500000] = "TA-085v1/v2, TA-088v1/v2",
    [0x00600000] = "TA-088v3, TA-090v2/v3, TA-092",
    [0x00720000] = "TA-091",
    [0x00810000] = "TA-093v1/v2, TA-094v1, TA-095v1/v3, TA-096, TA-095v3",
    [0x00820000] = "TA-095v2/v4",
    [0x00900000] = "TA-096/TA-097",
}

local function tachyontoname(hexcode)
    return tachyon_to_mobo[hexcode] or "Unknown"
end

return tachyontoname
