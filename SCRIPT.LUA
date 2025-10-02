-- BatterySteve PSP
-- by Koutsie
-- Homeage: https://the-sauna.icu/BatterySteve/
-- Fedi/Mastodon: https://layer8.space/@k
-- Report is saved as score.old.txt


-- special thanks to:
-- nuclearkommando - ideas guy & early beta tester
-- princessofsleeping - JP translation help
-- laamaa - banger soundtrack!
-- the entire PSP homebrew community for being awesome
-- you - for using this software - send me your test results @koutsie on discord or mastodon (see above)

function loading()
    screen.txtcolor(color.new(30, 30, 30))
    screen.consolexy(1, 1)
    screen.consoleprint("Loading...")
    screen.flip()
end

loading()

math.randomseed(133742069)

local logFileName = "score.txt"
local logFileNameBak = "score.bak.txt"
local logFileNameFinal = "score.final.txt"
local logMoveFolder = "logs"

local lastBackup = os.time()
local logInterval = 30

local eqA, eqB, eqD = 0.3, 0.2, 0.5
local battPct = 100
local battlifestimate = 0
local bc = 0
local cpuSpeed
local unreliablebattery

local cubeSize = 25
local cubePosX, cubePosY = 240, 136
local cubeRotX, cubeRotY, cubeRotZ = 0, 90, 24
local rotSpeedX, rotSpeedY, rotSpeedZ = 0.05, 0.03, 0.05

local particleCount = 300
local particleMinSpeed, particleMaxSpeed = -3, 3
local particleRadius = 1
local particles = {}
local gValues = {}

local intro, loop
local musicenabled = nil
local loopStarted = false
local graph = {}

-- we can just name our font onefont.pgf to load it.
-- Font = font.load("tiny.pgf")
-- font.setdefault(Font)

STEVE = false
if os.date("%d") == "01" and os.date("%m") == "04" then
    STEVE = true
end
TEST = false
BSV = "1.2.6-5"

-- config manager
config = require("modules/cmanager")

musicenabled = config.batterysteve.music
unreliablebattery = config.batterysteve.unreliablebattery
cpuSpeed = config.batterysteve.cpu
os.cpu(cpuSpeed)

-- we have to run nc, ball.
nc = require("modules/nc")
nc.run()
if TEST then BSV = BSV .. " [TEST]" end

-- modules
local graph = require("modules.graph")
local screenie = require("modules.screenie")
local splash = require("modules.splash")
local splashes = {
    "/images/splash.png", "/images/laamaa.png", "/images/pspunk.png", "/images/nuclear.png"
}
local fade_steps, delay = 6, 10
local display_time = 6000


if hw.getmodel() == "Vita" then
    screen.consoleprint("The PS Vita is NOT SUPPORTED!")
    screen.flip()
    os.delay(6500)
end

-- dumb but we ball
if BSV:find("-beta") then
    screen.txtcolor(color.new(255, 100, 100))
    screen.consolexy(3, 6)
    screen.consoleprint("BatterySteve BETA build!")
    screen.consolexy(3, 8)
    screen.consoleprint("model: " .. hw.getmodel() .. " / gen: " .. hw.gen() .. " / board: " .. hw.board())
    screen.consolexy(3, 9)
    screen.consoleprint("spock: " .. hw.spock() .. " / tachyon: " .. hw.tachyon())
    screen.consolexy(3, 10)
    screen.consoleprint("kirk: " .. hw.kirk() .. " / fusecfg: " .. hw.fusecfg() .. " / fuseid: " .. hw.fuseid())
    screen.consolexy(3, 11)
    screen.consoleprint("pommel: " .. hw.pommel() .. " / baryon: " .. hw.baryon())
    screen.consolexy(3, 12)
    screen.consoleprint("factory fw: " ..
        hw.ofwinitial() .. " / nandseed: " .. hw.nandseed() .. " / region: " .. hw.region())
    screen.consolexy(3, 13)
    screen.consoleprint("ram/total:" ..
        math.floor(os.totalram() / 1024 / 1024) .. "MB / " .. math.floor(os.ram() / 1024 / 1024) .. "MB")
    screen.txtcolor(color.new(255, 255, 25))
    screen.consolexy(3, 18)
    screen.consoleprint("this is FREE software, if you paid for this - you got scammed!")
    screen.txtcolor(color.new(10, 25, 10))
    screen.consolexy(0, 20)
    screen.consoleprint("Special thanks to:")
    screen.consolexy(0, 21)
    screen.consoleprint(
        "nuclearkommando, princessofsleeping, laamaa, krayzynez \nand the rest of the psp homebrew community \n\nlets try to keep the best portable \nconsole alive!"
    )
    screen.consolexy(0, 28)
    screen.txtcolor(color.new(12, 120, 75))
    screen.consoleprint("press start to continue")
    screen.flip()
    power.tick()
    buttons.homepopup(0)
    buttons.waitforkey(__START)
end

if not BSV:find("-beta") then
    splash.show(splashes, fade_steps, delay, display_time, config)
end

local utils = require("modules.utils")

-- funkie "cuboid"
local half = cubeSize / 2
local baseVerts = {}
for x = -1, 1, 2 do
    for y = -1, 1, 2 do
        for z = -1, 1, 2 do
            table.insert(baseVerts, { x * half, y * half, z * half })
        end
    end
end
local baseEdges = {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 }, { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 }
}

local function rotatePoint(p, ax, ay, az)
    return utils.rotatePoint(p, ax, ay, az)
end

local SteveImg
local d = os.date("*t")
local m, day = d.month, d.day

if STEVE then
    SteveImg = image.load("/images/stevee.png")
    image.fliph(SteveImg)
    -- one of the things of all time:
    -- Spring(4/20-27), Summer(7/13-20), Fall(10/5-12), Halloween(10/25-31), Thanksgiving(11/23-29), Christmas(12/8-25) & NewYear(12/26-1/1)
    -- And of course, MrMario2011 (8/12)
    local seasonal
    if m == 10 and day >= 25 then
        seasonal = "steve_halloween.png"
    elseif m == 11 and day >= 23 and day <= 29 then
        seasonal = "steve_thanksgiving.png" -- idea by juladdr
    elseif m == 12 and day >= 8 and day <= 25 then
        seasonal = "steve_christmas.png"
    elseif m == 4 and day >= 20 and day <= 27 then
        seasonal = "steve_spring.png"
    elseif m == 7 and day >= 13 and day <= 20 then
        seasonal = "steve_summer.png"
    elseif m == 10 and day >= 5 and day <= 12 then
        seasonal = "steve_fall.png"
    elseif (m == 12 and day >= 26) or (m == 1 and day == 1) then
        seasonal = "steve_newyear.png"
    elseif m == 8 and day == 12 then
        seasonal = "steve_mrmario.png"
        -- changed the name because its not the plumber from the popular video game series.
    end
    if seasonal then
        local temp = image.load("/images/" .. seasonal)
        if temp then
            image.destroy(SteveImg)
            SteveImg = temp
            image.fliph(SteveImg)
        end
    end
end

local function calculateEquation(b)
    return utils.calculateEquation(b, eqA, eqB, eqD, utils.constrainValue)
end

--  3d
local currentRotation = 0
amg.init()
Camera = cam3d.new()
amg.quality(__8888)
amg.perspective(46.0)
amg.typelight(1, __DIRECTIONAL)
amg.colorlight(1, color.new(50, 50, 50), color.new(100, 100, 100), color.new(200, 200, 200))
amg.poslight(1, { 1, 4, 1 })
Plane = model3d.load(files.cdir() .. "/3d/Data/Plane/plane.obj")
Ball = model3d.load(files.cdir() .. "/3d/Data/Ball/ball.obj")
local scaleValues = { 0.70, 0.70, 0.70 }
model3d.scaling(Ball, 1, scaleValues)
model3d.shading(Ball, 1)
model3d.position(Ball, 1, { 0, 1, 0 })
model3d.scaling(Plane, 1, { 0.5, 0.5, 0.5 })
model3d.position(Plane, 1, { 0, -0.55, 0 })
local BallRotX, BallRotY, BallRotZ = -360, 45, 32
local BallRotSpeedX, BallRotSpeedY, BallRotSpeedZ = 0.06, 0.06, 0.045

local modelmod = require("modules/modelmod")
modelmod.init(baseVerts, baseEdges, cubePosX, cubePosY, cubeRotX, cubeRotY, cubeRotZ, rotSpeedX, rotSpeedY, rotSpeedZ)

-- floaties
modelmod.addModel({
    { -30, -30, 0 }, { 0, -40, 0 }, { 30, -30, 0 }, { 40, 0, 0 },
    { 30,  30,  0 }, { 0, 40, 0 }, { -30, 30, 0 }, { -40, 0, 0 },
    { -20, 10, 5 }, { -10, 10, 5 }, { -10, 20, 5 }, { -20, 20, 5 },
    { 10,  10, 5 }, { 20, 10, 5 }, { 20, 20, 5 }, { 10, 20, 5 },
    { -20, -10, 5 }, { -10, -20, 5 }, { 10, -20, 5 }, { 20, -10, 5 }
}, {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 1 },
    { 9, 10 }, { 10, 11 }, { 11, 12 }, { 12, 9 },
    { 13, 14 }, { 14, 15 }, { 15, 16 }, { 16, 13 },
    { 17, 18 }, { 18, 19 }, { 19, 20 }
})

modelmod.addModel({
    { 0, -30, 15 }, { 26, -15, 15 }, { 26, 15, 15 }, { 0, 30, 15 }, { -26, 15, 15 }, { -26, -15, 15 },
    { 0, -30, -15 }, { 26, -15, -15 }, { 26, 15, -15 }, { 0, 30, -15 }, { -26, 15, -15 }, { -26, -15, -15 }
}, {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 1 },
    { 7, 8 }, { 8, 9 }, { 9, 10 }, { 10, 11 }, { 11, 12 }, { 12, 7 },
    { 1, 7 }, { 2, 8 }, { 3, 9 }, { 4, 10 }, { 5, 11 }, { 6, 12 }
})

if config.batterysteve.extraload then
    for i = 1, 30 do
        modelmod.addModel({
            { -30, -30, 0 }, { 0, -40, 0 }, { 30, -30, 0 }, { 40, 0, 0 },
            { 30,  30,  0 }, { 0, 40, 0 }, { -30, 30, 0 }, { -40, 0, 0 },
            { -20, 20, 5 }, { -5, 0, 5 }, { -20, -20, 5 },
            { 20,  20, 5 }, { 5, 0, 5 }, { 20, -20, 5 }
        }, {
            { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 1 },
            { 9, 11 }, { 10, 9 }, { 10, 11 },
            { 12, 14 }, { 13, 12 }, { 13, 14 }
        })
    end
end

local models = modelmod.getModels()

local halfParticleSpeed = (particleMaxSpeed - particleMinSpeed) * 0.5
for i = 1, particleCount do
    local g = 222
    local speedX = (math.random() * 2 - 1) * halfParticleSpeed
    local speedY = (math.random() * 2 - 1) * halfParticleSpeed
    particles[i] = {
        x = math.random(0, 480),
        y = math.random(0, 272),
        vx = speedX,
        vy = speedY,
        radius = math.random(1, particleRadius),
        color = draw.newcolor and draw.newcolor(g, g, g) or color.new(g, g, g)
    }
end

collectgarbage()

if BSV:find("-beta") then
    bg = image.load("/images/beta.gif")
else
    bg = image.load("/images/bg.gif")
    -- 19:39:56 / 2.10.25: what the fuck was i thinking when i
    -- put .png instead of .gif on the god damn imageload right there
    -- lmao
    -- k
end
image.resize(bg, 480, 272)

-- wait for full charge

-- rahh:
local brightnessMap = {
    -- 01g
    ["TA-079v1"] = { 24, 40, 72, 100 },
    ["TA-079v2"] = { 24, 40, 72, 100 },
    ["TA-079v3"] = { 24, 40, 72, 100 },
    ["TA-079v4"] = { 24, 40, 72, 100 },
    ["TA-081v1"] = { 24, 40, 72, 100 },
    ["TA-081v2"] = { 24, 40, 72, 100 },
    ["TA-082"]   = { 24, 40, 72, 100 },
    ["TA-086"]   = { 36, 48, 72, 92 },
    ["TA-079v5"] = { 20, 40, 60, 80, 100 }, -- need data

    -- 02g
    ["TA-085v1"] = { 36, 44, 56, 68 },
    ["TA-085v2"] = { 36, 44, 56, 68 },
    ["TA-088v2"] = { 36, 44, 56, 68 },
    ["TA-088v3"] = { 36, 44, 56, 68 },
    ["TA-088v1"] = { 20, 40, 60, 80, 100 }, -- need data
    ["TA-090v1"] = { 20, 40, 60, 80, 100 }, -- need data

    -- 03g–09g
    ["TA-090v2"] = { 44, 60, 72, 84 },
    ["TA-090v3"] = { 44, 60, 72, 84 },
    ["TA-093v1"] = { 44, 60, 72, 84 },
    ["TA-093v2"] = { 44, 60, 72, 84 },
    ["TA-091"]   = { 44, 60, 72, 84 },
    ["TA-095v3"] = { 44, 60, 72, 84 },
    ["TA-095v2"] = { 44, 60, 72, 84 },
    ["TA-092"]   = { 20, 40, 60, 80, 100 }, -- need data
    ["TA-095v1"] = { 20, 40, 60, 80, 100 }, -- need data
    ["TA-095v4"] = { 20, 40, 60, 80, 100 }, -- need data

    -- 11g
    ["TA-096"]   = { 32, 40, 48 },
    ["TA-097"]   = { 32, 40, 48 },
}


local function getBrightnessLevelsForModel()
    return brightnessMap[hw.board()] or { 20, 40, 60, 80, 100 }
end

local brightnessLevels = getBrightnessLevelsForModel()

local function level_to_percent(level)
    level = tonumber(level) or 5
    if level < 1 then level = 1 end
    if level > 5 then level = 5 end
    return brightnessLevels[level] or 100
end

local function percent_to_level(p)
    p = tonumber(p) or 100
    if p <= 20 then return 1 end
    if p <= 40 then return 2 end
    if p <= 60 then return 3 end
    if p <= 80 then return 4 end
    return 5
end

local current_hw_level = tonumber(screen.brightness()) or 5
if current_hw_level > 5 then
    current_hw_level = percent_to_level(current_hw_level)
end
if current_hw_level < 1 or current_hw_level > 5 then current_hw_level = 5 end

local brightnessIndex = current_hw_level
local brightnessPercent = level_to_percent(brightnessIndex)
screen.brightness(level_to_percent(brightnessIndex))


while true do
    buttons.read()
    if buttons.select then
        break
    end
    if buttons.l then
        cpuSpeed = (cpuSpeed == 333) and 222 or 333
        os.cpu(cpuSpeed)
        os.delay(16)
    end
    if buttons.r then
        musicenabled = not musicenabled
        os.delay(16)
    end
    if buttons.triangle then
        unreliablebattery = not unreliablebattery
        os.delay(16)
    end

    if buttons.square then
        screen.display(1)
        local fb = tonumber(screen.brightness()) or brightnessPercent
        local fl = percent_to_level(fb)
        brightnessIndex = fl + 1
        if brightnessIndex > #brightnessLevels then brightnessIndex = 1 end
        screen.brightness(level_to_percent(brightnessIndex))
        brightnessPercent = level_to_percent(brightnessIndex)
        os.delay(16)
        bc = 0
    else
        bc = bc + 1
        if bc >= 60 then
            local fb = tonumber(screen.brightness()) or brightnessPercent
            local fl = percent_to_level(fb)
            brightnessIndex = fl
            brightnessPercent = level_to_percent(fl)
            bc = 0
        end
    end

    if bg then
        image.blit(bg, 0, 0)
    else
        screen.clear(color.new(TEST and 120 or 20, TEST and 60 or 20, TEST and 60 or 20))
    end

    if config.autotest.enabled then
        local file = io.open(logFileName, "r")
        if file then
            file:close()
            if copyFile(logFileName, "score.autotest.protected.txt") then
                screen.clear(0)
                screen.consolexy(5, 5)
                screen.consoleprint("[AUTOTEST]: Log file copied to score.autotest.protected.txt")
                screen.flip()
                os.delay(2000)
            end
        end
        break
    end

    local lastLogFile = getLastLogFile()
    if lastLogFile then
        local file = io.open(lastLogFile, "r")
        if file then
            local lastLine = nil
            for line in file:lines() do
                lastLine = line
            end
            file:close()
            if lastLine then
                lastRT = lastLine:match("rt:%s*([%d:]+)")
                screen.consolexy(60, 1)
                screen.consoleprint(lastRT)
            end
        end
    end

    buttons.homepopup(1)
    screen.txtcolor(color.new(200, 200, 200))
    screen.txtbgcolor(color.new(93, 50, 43))
    -- 93, 50, 43 vs 20, 20, 20
    screen.consolexy(1, 1)
    screen.consoleprint("BatterySteve " .. BSV .. " by Koutsie")
    screen.consolexy(1, 2)
    screen.consoleprint("https://the-sauna.icu/BatterySteve/")
    screen.consolexy(1, 3)
    screen.consoleprint(hw.getmodel() .. " / gen: " .. hw.gen() .. " / board: " .. hw.board())

    utils.drawTextWithShadow(220, 170, "CPU: " .. cpuSpeed .. " MHz [L]", 0.5, color.new(200, 200, 200),
        color.new(50, 42, 24))
    utils.drawTextWithShadow(220, 190, "Music: " .. (musicenabled and "On" or "Off") .. " [R]", 0.5,
        color.new(200, 200, 200),
        color.new(50, 42, 24))
    utils.drawTextWithShadow(220, 210, "Basic bypass: " .. (unreliablebattery and "On" or "Off") .. " [TRIANGLE]", 0.5,
        color.new(200, 200, 200), color.new(50, 42, 24))
    utils.drawTextWithShadow(220, 230, "Brightness: " .. brightnessPercent .. "% [SQUARE]", 0.5,
        color.new(200, 200, 200), color.new(50, 42, 24))

    local barMax = 80
    local barHeight = 8
    local barX = 220
    local barY = 275
    local barFill = math.floor((brightnessPercent / 100) * barMax)
    draw.fillrect(barX, barY, barMax, barHeight, color.new(50, 50, 50))
    draw.fillrect(barX, barY, barFill, barHeight, color.new(200, 200, 80))

    local pct = batt.lifepercent() or 0
    local voltage = batt.volt() or 0
    local isCharging = batt.charging()
    -- due to popular request, show it twice
    local text = "Battery: " .. pct .. "%" .. " / " .. voltage .. "V | " .. (isCharging and "charging" or "not charging")
    utils.drawTextWithShadow(5, 260, text, 0.25, color.new(200, 200, 200), color.new(50, 42, 24))


    if pct < 100 then
        utils.drawTextWithShadow(220, 110, "CHARGE TO 100%", 0.6, color.new(222, 222, 222), color.new(50, 42, 24))
        utils.drawTextWithShadow(200, 130, "FORCE START [" .. pct .. "%] BY SELECT", 0.4, color.new(222, 222, 222),
            color.new(50, 42, 24))
    elseif pct >= 100 then
        if isCharging then
            utils.drawTextWithShadow(220, 140, "UNPLUG YOUR CHARGER!", 0.5, color.new(200, 200, 200),
                color.new(50, 42, 24))
        else
            local t = os.clock() * 66
            local hue = (t % 360)
            local r, g, b = utils.hsvToRgb(hue, 1, 1)
            utils.drawTextWithShadow(290, 15, "PRESS START TO BEGIN", 0.5, color.new(r, g, b), color.new(42, 42, 24))
            if buttons.start then
                break
            end
            os.delay(16)
        end
    end

    if STEVE then
        image.blit(SteveImg, 0, 230)
        -- STEVE
    end

    screen.flip()
    power.tick() -- keep the thing awake ffs :D
    os.delay(16)
end

collectgarbage()
loading()
buttons.homepopup(1)

-- shoutouts to laamaa for giving me the thumbsup to use he's music
-- go buy the track!
-- https://laamaa.bandcamp.com/track/gameboy-n-bass
-- https://laamaa.fi/
function laamaa()
    if not intro then
        intro = sound.load("audio/laamaa-intro.mp3")
        loop = sound.load("audio/laamaa-loop.mp3")
        sound.vol(intro, 100)
        -- so, the volume has been 70 this whole time, yeah.
        -- i literally do not know why.
        sound.play(intro)
        return
    end
    if not loopStarted and sound.endstream(intro) then
        sound.vol(loop, 100)
        sound.play(loop)
        sound.loop(loop)
        loopStarted = true
    end
end

local lastLog, fps, elapsedSeconds, lastUpdateTime, headerWritten = os.time(), 0, 0, os.time(), false
local o = 0 -- offset
if config.batterysteve.showmspf then
    FrameTime = 0
    FrameE = 0
end

local ui_visible = true
local ui_last_action = os.time()
local ui_timeout = 30


function drawrect_ui(...)
    if ui_visible then
        draw.fillrect(...)
    end
end

function screenprint_ui(...)
    if ui_visible then
        screen.print(...)
    end
end

while true do
    if config.batterysteve.showmspf then
        FrameE = os.clock()
    end
    amg.begin()
    if musicenabled then laamaa() end
    screen.clear(color.new(20, 20, 20))
    buttons.read()
    if buttons.select and buttons.start then break end

    local any_button = buttons.cross or buttons.circle or buttons.triangle or buttons.square or buttons.start or
        buttons.select or buttons.l or buttons.r
    if any_button then
        ui_visible = true
        ui_last_action = os.time()
    elseif os.time() - ui_last_action > ui_timeout then
        ui_visible = false
    end

    BallRotX = BallRotX + BallRotSpeedX
    BallRotY = BallRotY + BallRotSpeedY
    BallRotZ = BallRotZ + BallRotSpeedZ
    model3d.rotation(Ball, 1, { BallRotX * 15, BallRotY * 15, BallRotZ * 15 })

    o = (o + 0.5) % 360
    local h = o / 60
    local i = math.floor(h) % 6
    local f = h - i
    local p, q, t = 0.2, 1 - 0.8 * f, 1 - 0.8 * (1 - f)

    local r, g, b = 1, t, p
    if i == 1 then
        r, g, b = q, 1, p
    elseif i == 2 then
        r, g, b = p, 1, t
    elseif i == 3 then
        r, g, b = p, q, 1
    elseif i == 4 then
        r, g, b = t, p, 1
    elseif i == 5 then
        r, g, b = 1, p, q
    end

    -- render3d
    amg.light(1, 1)
    local minBrightness = 148
    r = math.max(math.floor(r * 255 + 0.5), minBrightness)
    g = math.max(math.floor(g * 255 + 0.5), minBrightness)
    b = math.max(math.floor(b * 255 + 0.5), minBrightness)
    local avgR = math.max(math.floor((r + g) / 2 + 0.5), minBrightness)
    local avgG = math.max(math.floor((g + b) / 2 + 0.5), minBrightness)
    local avgB = math.max(math.floor((b + r) / 2 + 0.5), minBrightness)
    local halfB = b * 0.5
    local halfR = r * 0.5
    local halfG = g * 0.5
    amg.colorlight(
        1,
        color.new(r, g, b, 255),
        color.new(halfB, halfR, halfG, 128),
        color.new(avgR, avgG, avgB, 192)
    )

    currentRotation = ((currentRotation or 0) + 0.5) % 360
    local radius = 4.4
    local rad = math.rad(currentRotation)
    local sinR, cosR = math.sin(rad), math.cos(rad)
    local camX = cosR * radius
    local camZ = sinR * radius
    local targetCamY = 4 + sinR * 0.35
    local smoothingFactor = 0.05
    camY = camY and (camY + (targetCamY - camY) * smoothingFactor) or targetCamY

    cam3d.position(Camera, { camX, camY, camZ })
    cam3d.eye(Camera, { 0, 0.85, 0 })
    cam3d.set(Camera)

    model3d.render(Plane)
    model3d.startreflection(Plane, 1)
    model3d.mirror(Ball, 1, 2)
    model3d.finishreflection()

    -- ball reflection model3d.blitshadow
    model3d.render(Ball)
    amg.light(1, 0);


    cubeRotX = (cubeRotX + rotSpeedX) % 360
    cubeRotY = (cubeRotY + rotSpeedY) % 360
    cubeRotZ = (cubeRotZ + rotSpeedZ) % 360

    local now = os.time()
    local dt = now - lastUpdateTime
    if dt > 0 then elapsedSeconds, lastUpdateTime = elapsedSeconds + dt, now end

    local sec = elapsedSeconds % 60
    local min = math.floor(elapsedSeconds / 60) % 60
    local hour = math.floor(elapsedSeconds / 3600) % 24
    local days = math.floor(elapsedSeconds / 86400)
    local timeString
    if days > 0 then
        timeString = string.format("%d day(s) %02d:%02d:%02d", days, hour, min, sec)
    else
        timeString = string.format("%02d:%02d:%02d", hour, min, sec)
    end

    fps = screen.fps()
    battPct = batt.lifepercent() or 0
    local remainCap = batt.remaincap()

    -- if we've ran out of battery and wake back up we conclude that
    -- we must've ran out of battery
    -- but if unreliablebattery is set to true we just ignore it (because some batteries report 0 / 0 anyway ??)
    if battPct == 0 and (remainCap == "-" or remainCap == nil) then
        if musicenabled then
            sound.stop(loop)
        end
        collectgarbage()
        local f = io.open(logFileName, "a")
        if f then
            local logMessage = "rt:" .. timeString .. ", batt:" .. battPct .. ", eq:-/-" .. ", fps:" .. fps
            if config.batterysteve.unreliablebattery then
                logMessage = logMessage .. ", POSSIBLE_BATTERY_FAULT"
            else
                logMessage = logMessage .. ", BATTERY_FAILURE"
            end
            f:write(logMessage .. "\n")
            f:close()
            os.delay(200)
        end
        if not config.batterysteve.unreliablebattery then
            -- believe me, this is the easiest way to
            -- fix slow memory cards/sd cards.
            -- a few reports were not saved because of that - so - we
            -- increased from 2200 to 2500.
            os.delay(2500)
            graph.draw_from_file(logFileName)
            screen.flip()
            os.delay(100)
            screenie.save_screenshot()
            screen.flip()
            os.delay(100)
            graph.draw_from_file(logFileName)
            screen.flip()
            buttons.homepopup(0)
            buttons.waitforkey(__START)
            while true do
                buttons.read()
                if buttons.cross or buttons.circle or buttons.triangle or
                    buttons.square or buttons.start or buttons.select then
                    if musicenabled then
                        sound.stop(loop)
                    end
                    if copyFile(logFileName, logFileNameFinal) then
                        os.remove(logFileName)
                        screen.print(240, 220, "Score file backed up.", 0.4,
                            color.new(150, 150, 150))
                        screen.flip()
                        buttons.homepopup(1)
                        os.delay(2000)
                    end
                    break
                end
            end
            break
        end
    end

    for _, p in ipairs(particles) do
        p.x = (p.x + p.vx) % 480
        p.y = (p.y + p.vy) % 272
        draw.fillrect(p.x - 1, p.y - 1, 2, 2, p.color)
    end

    local verts2 = {}
    for i, v in ipairs(baseVerts) do
        local r = rotatePoint(v, cubeRotX, cubeRotY, cubeRotZ)
        verts2[i] = { x = r[1] + cubePosX, y = r[2] + cubePosY }
    end
    for _, e in ipairs(baseEdges) do
        local v1, v2 = verts2[e[1]], verts2[e[2]]
        draw.line(v1.x, v1.y, v2.x, v2.y, color.new(200, 200, 200))
    end

    -- i wish id remember what i was cooking with this
    -- but i cant really touch this now, as that'd throw off the previous
    -- tests :D
    for _, m in ipairs(models) do
        m.rot.x, m.rot.y, m.rot.z = m.rot.x + m.rotSpeed.x,
            m.rot.y + m.rotSpeed.y,
            m.rot.z + m.rotSpeed.z
        if m.vel then
            m.pos.x, m.pos.y = m.pos.x + m.vel.x, m.pos.y + m.vel.y
            if m.pos.x < 0 or m.pos.x > 480 then
                m.vel.x = -m.vel.x + math.random(-0.3, 0.3)
                m.vel.y = m.vel.y + math.random(-0.2, 0.2)
                m.colorBase = {
                    math.random(100, 255), math.random(100, 255),
                    math.random(100, 255)
                }
            end
            if m.pos.y < 0 or m.pos.y > 272 then
                m.vel.y = -m.vel.y + math.random(-0.3, 0.3)
                m.vel.x = m.vel.x + math.random(-0.2, 0.2)
                m.colorBase = {
                    math.random(100, 255), math.random(100, 255),
                    math.random(100, 255)
                }
            end
            if math.abs(m.vel.x) < 0.5 then
                m.vel.x = m.vel.x + math.random(-0.5, 0.5)
            end
            if math.abs(m.vel.y) < 0.5 then
                m.vel.y = m.vel.y + math.random(-0.5, 0.5)
            end
        end
        local vertsM = {}
        for i, v in ipairs(m.verts) do
            local r = rotatePoint(v, m.rot.x, m.rot.y, m.rot.z)
            vertsM[i] = {
                x = r[1] * m.scale + m.pos.x,
                y = r[2] * m.scale + m.pos.y
            }
        end
        for _, e in ipairs(m.edges) do
            local v1, v2 = vertsM[e[1]], vertsM[e[2]]
            draw.line(v1.x, v1.y, v2.x, v2.y,
                draw.newcolor and
                draw.newcolor(m.colorBase[1], m.colorBase[2],
                    m.colorBase[3]) or
                color.new(m.colorBase[1], m.colorBase[2],
                    m.colorBase[3]))
        end
    end

    local battTemp = batt.temp() or 0

    if config.batterysteve.extraload then
        EqVal = calculateEquation(battPct)
    end

    drawrect_ui(0, 0, 480, 20, color.new(TEST and 120 or 40,
        TEST and 60 or 40, TEST and 60 or 40))
    local tempStr
    if hw.getmodel() == "Go" then
        tempStr = ""
    elseif hw.getmodel() == "Street" then
        tempStr = ""
    else
        tempStr = " TEMP: " .. battTemp .. "*C"
    end

    screenprint_ui(5, 8,
        "BATT: " .. battPct .. tempStr .. " | CPU: " .. os.cpu() .. "/" ..
        os.bus() .. " Mhz", 0.5, color.new(200, 200, 200))

    local battLevel = math.max(0, math.min(tonumber(battPct) or 0, 100))
    local barWidth = math.floor(battLevel)
    local colors = {
        { color.new(50, 200, 50),  color.new(50, 180, 50),  color.new(30, 150, 30),  color.new(30, 130, 30) },
        { color.new(200, 200, 50), color.new(180, 180, 50), color.new(150, 150, 30), color.new(130, 130, 30) },
        { color.new(200, 50, 50),  color.new(180, 50, 50),  color.new(150, 30, 30),  color.new(130, 30, 30) }
    }
    local c = battLevel > 75 and colors[1] or (battLevel > 50 and colors[2] or colors[3])

    drawrect_ui(5, 25, barWidth, 3, c[1], c[2], c[3], c[4])
    drawrect_ui(5 + barWidth, 25, 100 - barWidth, 3, color.new(50, 50, 50))

    screenprint_ui(5, 30,
        string.format("LEFT: %s", batt.lifetime()), 0.25, color.new(200, 200, 200))

    if batt.charging() then
        local rectHeight = 272 * 0.33
        draw.fillrect(0, rectHeight, 480, rectHeight, color.new(200, 200, 50))
        local message = "CHARGER PLUGGED IN!"
        screen.print((480 - screen.textwidth(message, 1.0)) / 2, rectHeight + rectHeight / 2 - 1, message, 1.0,
            color.new(50, 50, 50))
    end

    drawrect_ui(0, 250, 480, 22, color.new(TEST and 120 or 40,
        TEST and 60 or 40,
        TEST and 40 or 40))

    local hwgen = hw.gen()
    local cfw = os.cfw()
    local model = (cfw ~= "UNK") and tostring(hw.getmodel() .. " on " .. cfw) or
        tostring(hw.getmodel())
    local batremain = tostring(batt.remaincap()) .. "/" ..
        tostring(batt.fullcap())
    local batvolt = batt.volt()

    -- if model is Go, Street or Emulator we need to hide batremain
    -- those models do not have proper battery management
    local model = hw.getmodel()

    local batteryStr = ""
    if model ~= "Go" and model ~= "Street" and model ~= "Emulator" then
        batteryStr = string.format("BAT: %s (%s) ", batremain, batvolt)
    end
    if config.batterysteve.showmspf then
        FrameTime = os.clock() - FrameE
    end

    screenprint_ui(5, 258,
        string.format("FPS:%d RUN:%s %s| %s %s", fps, timeString,
            batteryStr, string.upper(hwgen), string.upper(model)), 0.40,
        color.new(200, 200, 200))

    if os.time() - lastLog >= logInterval then
        local logFile
        if not headerWritten then
            logFile = io.open(logFileName, "w")
            if logFile then
                local pspModel = hw.getmodel() .. "(" .. hw.gen() .. ", " .. hw.board() .. ")" or " "
                -- also gotta add cpu frequency and screen brightness to this - done?:
                local raw_hw_brightness = tonumber(screen.brightness()) or brightnessIndex
                local real_hw_level = raw_hw_brightness
                if raw_hw_brightness > 4 then
                    real_hw_level = percent_to_level(raw_hw_brightness)
                end
                if real_hw_level < 1 or real_hw_level > 4 then real_hw_level = brightnessIndex end
                local brightness_for_header = level_to_percent(real_hw_level)
                local cpufreq = os.cpu() .. "/" .. os.bus()
                local header = string.format("BatterySteve %s on %s CPU:[%s] B:[%s%%]\n",
                    BSV, pspModel, cpufreq, brightness_for_header)
                logFile:write(header)
                -- we write the header only once
                headerWritten = true
            end
        else
            logFile = io.open(logFileName, "a")
        end

        if logFile then
            local remainCap = tostring(batt and batt.remaincap() or "N/A")
            local fullCap = tostring(batt and batt.fullcap() or "N/A")
            local lifetime = tostring(batt and batt.lifetime() or "N/A")
            logFile:write("rt:" .. timeString .. ", batt:" .. battPct .. ", eq:" ..
                remainCap .. " /" .. fullCap .. " " .. ", bV:" ..
                batvolt .. " v" .. ", life:" .. lifetime .. " min" .. ", fps:" .. fps .. "\n")
            logFile:close()
        end

        if power and power.tick then power.tick() end
        lastLog = os.time()
    end

    -- apparently some batteries will *die* randomly?
    -- lets keep a second copy for future reference
    if os.time() - lastBackup >= 31 then
        if copyFile(logFileName, "score.old.bak.txt") then
            -- we do nothing here - just pass
            print("useless")
        end
        lastBackup = os.time()
    end
    if config.batterysteve.showmspf then
        local msPerFrame = string.format("%.2f", FrameTime * 1000)
        screenprint_ui(5, 241,
            string.format("MS: %s", msPerFrame), 0.25, color.new(200, 200, 200))
    end
    amg.update()
    screen.flip()
end

if musicenabled then
    sound.stop(intro)
    sound.stop(loop)
end

screen.clear(color.new(5, 60, 5))
screen.flip()

-- i mean this does nothing here but why not.
buttons.homepopup(1)
