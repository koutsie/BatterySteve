-- BatterySteve PSP
-- by Koutsie
-- Homeage: https://the-sauna.icu/BatterySteve/
-- Fedi/Mastodon: https://layer8.space/@k
-- Report is saved as score.old.txt
-- config

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
BSV = "1.2.5"


-- run config manager
config = require("modules/cmanager")

musicenabled = config.batterysteve.music
unreliablebattery = config.batterysteve.unreliablebattery
cpuSpeed = config.batterysteve.cpu
os.cpu(cpuSpeed)

-- we have to run nc
nc = require("modules/nc")
nc.run()
if TEST then BSV = BSV .. " [TEST]" end

-- graph module
local graph = require("modules.graph")
-- screenshot module
local screenie = require("modules.screenie")
-- custom splashes
local splash = require("modules.splash")
local splashes = {
    "/images/splash.png", "/images/laamaa.png", "/images/pspunk.png", "/images/nuclear.png"
}
local fade_steps, delay = 6, 10
local display_time = 6000

splash.show(splashes, fade_steps, delay, display_time, config)

if hw.getmodel() == "Vita" then
    screen.consoleprint("The PS Vita is not supported.")
    os.delay(6000)
    os.exit()
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
if STEVE then
    SteveImg = image.load("/images/stevee.png")
    image.fliph(SteveImg)
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

--[[ modelmod.addModel({
    { 0, -30, 0 }, { 26, -15, 0 }, { 26, 15, 0 }, { 0, 30, 0 }, { -26, 15, 0 }, { -26, -15, 0 },
    { 0, -30, -10 }, { 26, -15, -10 }, { 26, 15, -10 }, { 0, 30, -10 }, { -26, 15, -10 }, { -26, -15, -10 }
}, {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 1 },
    { 7, 8 }, { 8, 9 }, { 9, 10 }, { 10, 11 }, { 11, 12 }, { 12, 7 },
    { 1, 7 }, { 2, 8 }, { 3, 9 }, { 4, 10 }, { 5, 11 }, { 6, 12 }
}) ]]

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

-- load bg from images/bg.png
local bg = image.load("/images/bg.gif")
image.resize(bg, 480, 272)

-- wait for full charge
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
    if buttons.start and batt.lifepercent() >= 100 and not batt.charging() then
        break
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

    screen.txtcolor(color.new(200, 200, 200))
    screen.txtbgcolor(color.new(20, 20, 20))
    screen.consolexy(1, 1)
    screen.consoleprint("BatterySteve " .. BSV .. " by Koutsie")
    screen.consolexy(1, 2)
    screen.consoleprint("https://the-sauna.icu/BatterySteve/")

    utils.drawTextWithShadow(220, 200, "CPU: " .. cpuSpeed .. " MHz [L]", 0.5, color.new(200, 200, 200),
        color.new(50, 42, 24))
    utils.drawTextWithShadow(220, 220, "Music: " .. (musicenabled and "On" or "Off") .. " [R]", 0.5,
        color.new(200, 200, 200),
        color.new(50, 42, 24))
    utils.drawTextWithShadow(220, 240, "Basic bypass: " .. (unreliablebattery and "On" or "Off") .. " [TRIANGLE]", 0.5,
        color.new(200, 200, 200), color.new(50, 42, 24))

    local pct = batt.lifepercent() or 0
    local isCharging = batt.charging()
    if pct < 100 then
        utils.drawTextWithShadow(220, 120, "CHARGE TO 100%", 0.6, color.new(222, 222, 222), color.new(50, 42, 24))
        utils.drawTextWithShadow(200, 140, "FORCE START [" .. pct .. "%] BY SELECT", 0.4, color.new(222, 222, 222),
            color.new(50, 42, 24))
    elseif pct >= 100 then
        if isCharging then
            utils.drawTextWithShadow(220, 150, "UNPLUG YOUR CHARGER!", 0.5, color.new(200, 200, 200),
                color.new(50, 42, 24))
        else
            utils.drawTextWithShadow(220, 180, "PRESS START TO BEGIN", 0.5, color.new(200, 200, 200),
                color.new(50, 42, 24))
        end
    end

    if STEVE then
        image.blit(SteveImg, 0, 230)
    end

    screen.flip()
    os.delay(16)
end

collectgarbage()
loading()

-- shoutouts to laamaa for giving me the thumbsup to use he's music
-- go buy the track!
-- https://laamaa.bandcamp.com/track/gameboy-n-bass
-- https://laamaa.fi/
function laamaa()
    if not intro then
        intro = sound.load("audio/laamaa-intro.mp3")
        loop = sound.load("audio/laamaa-loop.mp3")
        sound.vol(intro, 70)
        sound.play(intro)
        return
    end
    if not loopStarted and sound.endstream(intro) then
        sound.vol(loop, 70)
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
while true do
    if config.batterysteve.showmspf then
        FrameE = os.clock()
    end
    amg.begin()
    if musicenabled then laamaa() end
    screen.clear(color.new(20, 20, 20))
    buttons.read()
    if buttons.select and buttons.start then break end

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
            os.delay(2200)
            graph.draw_from_file(logFileName)
            screen.flip()
            os.delay(100)
            screenie.save_screenshot()
            screen.flip()
            os.delay(100)
            graph.draw_from_file(logFileName)
            screen.flip()
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

    draw.fillrect(0, 0, 480, 20, color.new(TEST and 120 or 40,
        TEST and 60 or 40, TEST and 60 or 40))
    local tempStr
    if hw.getmodel() == "Go" then
        tempStr = ""
    elseif hw.getmodel() == "Street" then
        tempStr = ""
    else
        tempStr = " TEMP: " .. battTemp .. "*C"
    end

    screen.print(5, 8,
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

    draw.gradrect(5, 25, barWidth, 3, c[1], c[2], c[3], c[4])
    draw.fillrect(5 + barWidth, 25, 100 - barWidth, 3, color.new(50, 50, 50))

    screen.print(5, 30,
        string.format("LEFT: %s", batt.lifetime()), 0.25, color.new(200, 200, 200))

    if batt.charging() then
        local rectHeight = 272 * 0.33
        draw.fillrect(0, rectHeight, 480, rectHeight, color.new(200, 200, 50))
        local message = "CHARGER PLUGGED IN!"
        screen.print((480 - screen.textwidth(message, 1.0)) / 2, rectHeight + rectHeight / 2 - 1, message, 1.0,
            color.new(50, 50, 50))
    end

    draw.fillrect(0, 250, 480, 22, color.new(TEST and 120 or 40,
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

    screen.print(5, 258,
        string.format("FPS:%d RUN:%s %s| %s %s", fps, timeString,
            batteryStr, string.upper(hwgen), string.upper(model)), 0.40,
        color.new(200, 200, 200))

    if os.time() - lastLog >= logInterval then
        local logFile
        if not headerWritten then
            logFile = io.open(logFileName, "w")
            if logFile then
                local pspModel = hw.getmodel() .. "(" .. hw.gen() .. ", " .. hw.board() .. ")" or " "
                -- also gotta add cpu frequency and screen brightness to this:
                local brightness = screen.brightness()
                local cpufreq = os.cpu() .. "/" .. os.bus()
                local header = string.format("BatterySteve %s on %s CPU:[%s] B:[%s]\n",
                    BSV, pspModel, cpufreq, brightness)
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
        screen.print(5, 241,
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
