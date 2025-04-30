-- BatterySteve PSP
-- by Koutsie
-- Homeage: https://the-sauna.icu/BatterySteve/
-- Fedi/Mastodon: https://layer8.space/@k
-- Report is saved as score.old.txt
-- config
math.randomseed(os.time())

logFileName = "score.txt"
logFileNameBak = "score.bak.txt"
logFileNameFinal = "score.old.txt"

local lastBackup = os.time()
local logInterval = 30

local eqA, eqB, eqD = 0.3, 0.2, 0.5
local battPct = 100
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

-- we can just name our font onefont.pgf to load it.
-- Font = font.load("tiny.pgf")
-- font.setdefault(Font)

STEVE = false
TEST = false
BSV = "1.1.2"

-- run config manager
config = require("modules/cmanager")


musicenabled = config.batterysteve.music
unreliablebattery = config.batterysteve.unreliablebattery
cpuSpeed = config.batterysteve.cpu
os.cpu(cpuSpeed)

-- we have to run nc, can we runfile or?
nc = require("modules/nc")
nc.run()
if TEST then BSV = BSV .. " [TEST]" end

-- include tachyontoname from modules
--local tachyontoname = require("modules/tachyontoname")


-- custom splashes
local splashes = {
    "/images/splash.png", "/images/pspunk.png", "/images/laamaa.png"
}
local fade_steps, delay = 20, 16
local display_time = 4000

if not config.autotest.enabled and config.batterysteve.splashes then
    for i = 1, #splashes do
        local p = splashes[i]
        local img = image.load(p)
        if not img then
            os.message("Failed to load " .. p)
        else
            screen.clear(0)
            screen.flip()
            for j = 0, fade_steps do
                local a = math.floor((j / fade_steps) * 255)
                image.blit(img, 0, 0, a)
                screen.flip()
                os.delay(delay)
            end
            local start = os.time()
            while os.time() - start < display_time / 1000 do
                buttons.read()
                if buttons.cross or buttons.circle or buttons.triangle or
                    buttons.square or buttons.start or buttons.select then
                    break
                end
                image.blit(img, 0, 0, 255)
                screen.print(350, 10, "Press any button to skip.", 0.25,
                    color.new(255, 255, 255))
                screen.flip()
                os.delay(delay)
            end
            for j = fade_steps, 0, -1 do
                local a = math.floor((j / fade_steps) * 255)
                image.blit(img, 0, 0, a)
                screen.flip()
                os.delay(delay)
            end
        end
    end
end

if hw.getmodel() == "Vita" then
    screen.consoleprint("The PS Vita is not supported.")
    os.delay(5000)
    os.exit()
end

local function constrainValue(val, min, max)
    if val ~= val then return 0 end
    return math.min(math.max(val, min), max)
end

local half = cubeSize / 2
local baseVerts = {
    { -half, -half, -half }, { half, -half, -half }, { half, half, -half },
    { -half, half,  -half }, { -half, -half, half }, { half, -half, half },
    { half, half, half }, { -half, half, half }
}
local baseEdges = {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 }, { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 }, { 1, 5 },
    { 2, 6 }, { 3, 7 }, { 4, 8 }
}

local function rotatePoint(p, ax, ay, az)
    local x, y, z = p[1], p[2], p[3]
    local cx, sx = math.cos(ax), math.sin(ax)
    local cy, sy = math.cos(ay), math.sin(ay)
    local cz, sz = math.cos(az), math.sin(az)
    local y1, z1 = y * cx - z * sx, y * sx + z * cx
    local x2, z2 = x * cy + z1 * sy, z1 * cy - x * sy
    return { x2 * cz - y1 * sz, x2 * sz + y1 * cz, z2 }
end

local SteveImg
if STEVE then
    SteveImg = image.load("/images/stevee.png")
    image.fliph(SteveImg)
end

local function calculateEquation(b)
    if type(b) ~= "number" then error("Input b must be a number") end
    b = constrainValue(b, -100, 100)
    local x = (math.random() * 3.14 * math.sqrt(math.abs(b) + 0.1))
    x = constrainValue(x, -10, 10)
    local eqM = constrainValue(math.cos(b * 0.5) * math.sin(x) + 0.81, 0.1, 5)
    local t1 =
        constrainValue(math.sin(x * eqA) * math.cos((b + 2) * eqB), -5, 5)
    local t2 = constrainValue(math.pow(math.abs(x + b * 0.32), 1.5) +
        math.log(x + 1.1), 0.1, 10)
    local t3 = constrainValue(math.sqrt(b + 1) * eqM, 0.1, 10)
    local t4 = constrainValue(math.cos(x * b + 0.5) * t3, -5, 5)
    local modifier = constrainValue(math.sin(t1 * 0.5) * 0.42 + 0.91, 0.5, 2)
    local t5 = constrainValue(math.sqrt(math.abs(t1 + t2 + t3 + t4) + 0.001),
        0.1, 10)
    local t6 = constrainValue(t5 * math.sin(t4 * 0.15), -5, 5)
    local t7 = constrainValue(math.atan(t6 / (t5 + 0.01)) * modifier, -5, 5)
    local result = constrainValue(math.sin(t6 * eqD) * math.cos(t6 / 2) * eqM,
        -100, 100)
    return result
end

--  3d
local currentRotation = 0
amg.init()
Camera = cam3d.new()
amg.quality(__8888)
amg.perspective(65.0)
amg.typelight(1, __DIRECTIONAL)
amg.colorlight(1, color.new(50, 50, 50), color.new(100, 100, 100), color.new(200, 200, 200))
amg.poslight(1, { 1, 5, 1 })
Plane = model3d.load(files.cdir() .. "/3d/Data/Plane/plane.obj")
Ball = model3d.load(files.cdir() .. "/3d/Data/Ball/ball.obj")
local scaleValues = { 0.75, 0.75, 0.75 }
model3d.scaling(Ball, 1, scaleValues)
model3d.shading(Ball, 1)
model3d.scaling(Plane, 1, { 0.5, 0.5, 0.5 })
model3d.position(Plane, 1, { 0, -0.5, 0 })
local BallRotX, BallRotY, BallRotZ = -743, 0, 0
local BallRotSpeedX, BallRotSpeedY, BallRotSpeedZ = 0.06, 0.06, 0.045

local models = {}
models[1] = {
    verts = baseVerts,
    edges = baseEdges,
    pos = { x = cubePosX, y = cubePosY, z = 0 },
    rot = { x = cubeRotX, y = cubeRotY, z = cubeRotZ },
    rotSpeed = { x = rotSpeedX / 2, y = rotSpeedY / 2, z = rotSpeedZ / 2 },
    scale = 0.85 / 2,
    colorBase = { 123, 223, 2 }
}

local function addModel(vertices, edges)
    local scale = math.random(30, 60) * 0.01
    local position = { x = math.random(0, 480), y = math.random(0, 272), z = 0 }
    local velocity = {
        x = math.random() * 2 - 1,
        y = math.random() * 2 - 1
    }
    local rotationSpeed = {
        x = math.random() * 0.06,
        y = math.random() * 0.06,
        z = math.random() * 0.036
    }
    local colorBase = {
        math.random(50, 255), math.random(50, 255), math.random(50, 255)
    }
    models[#models + 1] = {
        verts = vertices,
        edges = edges,
        pos = position,
        rot = { x = 0, y = 0, z = 0 },
        rotSpeed = rotationSpeed,
        scale = scale,
        vel = velocity,
        colorBase = colorBase
    }
end

-- floaties
addModel({
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

-- hexa
addModel({
    { 0, -30, 15 }, { 26, -15, 15 }, { 26, 15, 15 }, { 0, 30, 15 }, { -26, 15, 15 }, { -26, -15, 15 },
    { 0, -30, -15 }, { 26, -15, -15 }, { 26, 15, -15 }, { 0, 30, -15 }, { -26, 15, -15 }, { -26, -15, -15 }
}, {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 1 },
    { 7, 8 }, { 8, 9 }, { 9, 10 }, { 10, 11 }, { 11, 12 }, { 12, 7 },
    { 1, 7 }, { 2, 8 }, { 3, 9 }, { 4, 10 }, { 5, 11 }, { 6, 12 }
})
-- ECT
addModel({
    { 0, -30, 0 }, { 26, -15, 0 }, { 26, 15, 0 }, { 0, 30, 0 }, { -26, 15, 0 }, { -26, -15, 0 },
    { 0, -30, -10 }, { 26, -15, -10 }, { 26, 15, -10 }, { 0, 30, -10 }, { -26, 15, -10 }, { -26, -15, -10 }
}, {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 1 },
    { 7, 8 }, { 8, 9 }, { 9, 10 }, { 10, 11 }, { 11, 12 }, { 12, 7 },
    { 1, 7 }, { 2, 8 }, { 3, 9 }, { 4, 10 }, { 5, 11 }, { 6, 12 }
})

if config.batterysteve.extraload then
    -- for the brave
    for i = 1, 20 do
        addModel({
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

for i = 1, particleCount do gValues[i] = math.random(150, 200) end

for i = 1, particleCount do
    local g = gValues[i]
    particles[i] = {
        x = math.random(0, 480),
        y = math.random(0, 272),
        vx = math.random(particleMinSpeed, particleMaxSpeed) * 0.5,
        vy = math.random(particleMinSpeed, particleMaxSpeed) * 0.5,
        radius = math.random(1, particleRadius),
        color = draw.newcolor and draw.newcolor(g, g, g) or color.new(g, g, g)
    }
end

EqVal = calculateEquation(battPct)

local function copyFile(source, dest)
    local inFile = io.open(source, "rb")
    if inFile then
        local data = inFile:read("*all")
        inFile:close()

        local outFile = io.open(dest, "wb")
        if outFile then
            outFile:write(data)
            outFile:close()
            return true
        end
    end
    return false
end

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

    screen.clear(color.new(TEST and 120 or 20, TEST and 60 or 20, TEST and 60 or 20))

    local file = io.open(logFileName, "r")
    if file then
        file:close()
        if config.autotest.enabled then
            if copyFile(logFileName, "score.autotest.protected.txt") then
                screen.clear(0)
                screen.consolexy(5, 5)
                screen.consoleprint("[AUTOTEST]: Log file copied to score.autotest.protected.txt")
                screen.flip()
                os.delay(1000)
                break
            end
        end

        while true do
            screen.clear(0)
            screen.consolexy(5, 5)
            screen.consoleprint("Log file already exists. Do you want to delete it?")
            screen.consolexy(5, 6)
            screen.consoleprint("Press X to delete, O to quit")
            screen.flip()
            buttons.read()
            if buttons.cross then
                os.remove(logFileName)
                break
            elseif buttons.circle then
                os.exit()
            end
            os.delay(16)
        end
    end

    screen.consolexy(1, 1)
    screen.consoleprint("BatterySteve " .. BSV .. " by Koutsie")
    screen.consolexy(1, 2)
    screen.consoleprint("https://the-sauna.icu/BatterySteve/")
    screen.print(240, 200, "CPU: " .. cpuSpeed .. " MHz [L]", 0.5, color.new(200, 200, 200))
    screen.print(240, 220, "Music: " .. (musicenabled and "On" or "Off") .. " [R]", 0.5, color.new(200, 200, 200))
    screen.print(240, 240, "Basic Bypass: " .. (unreliablebattery and "On" or "Off") .. " [Triangle]", 0.5,
        color.new(200, 200, 200))

    local pct = batt.lifepercent() or 0
    local isCharging = batt.charging()
    if pct < 100 then
        screen.print(240, 120, "Charge to 100%", 0.6, color.new(222, 222, 222))
        screen.print(200, 140, "Force start [" .. pct .. "%] by pressing Select", 0.4, color.new(50, 42, 24))
    elseif pct >= 100 then
        if isCharging then
            screen.print(240, 150, "Unplug your charger!", 0.5, color.new(200, 200, 200))
        else
            screen.print(240, 180, "Press START to begin.", 0.5, color.new(200, 200, 200))
        end
    end

    if STEVE then
        image.blit(SteveImg, 0, 230)
    end

    screen.flip()
    os.delay(16)
end

-- shoutouts to laamaa for giving me the thumbsup to use he's music
-- go buy the track!
-- https://laamaa.bandcamp.com/track/gameboy-n-bass
-- https://laamaa.fi/
function laamaa()
    if not intro then
        intro = sound.load("audio/laamaa-intro.mp3")
        loop = sound.load("audio/laamaa-loop.mp3")
        sound.vol(intro, 60)
        sound.play(intro)
        return
    end
    if not loopStarted and sound.endstream(intro) then
        sound.vol(loop, 60)
        sound.play(loop)
        sound.loop(loop)
        loopStarted = true
    end
end

local lastLog, fps, elapsedSeconds, lastUpdateTime, headerWritten = os.time(), 0, 0, os.time(), false
local o = 0 -- offset

while true do
    amg.begin()
    if musicenabled then laamaa() end
    screen.clear(color.new(20, 20, 20))
    buttons.read()
    if buttons.select and buttons.start then break end

    BallRotX = BallRotX + BallRotSpeedX
    BallRotY = BallRotY + BallRotSpeedY
    BallRotZ = BallRotZ + BallRotSpeedZ
    model3d.rotation(Ball, 1, { BallRotX * 10, BallRotY * 10, BallRotZ * 10 })

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
    amg.light(1, 1);
    r, g, b = math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
    local avgR, avgG, avgB = (r + g) / 2, (g + b) / 2, (b + r) / 2
    amg.colorlight(1, color.new(r, g, b), color.new(b * 0.5, r * 0.5, g * 0.5),
        color.new(avgR, avgG, avgB))
    if not currentRotation then currentRotation = 0 end
    currentRotation = (currentRotation + 0.5) % 360
    local radius = 2.32
    local camX = math.cos(math.rad(currentRotation)) * radius
    local camZ = math.sin(math.rad(currentRotation)) * radius
    cam3d.position(Camera, { camX, 2, camZ })
    cam3d.set(Camera)
    model3d.render(Plane)

    model3d.render(Ball)
    amg.light(1, 0);


    cubeRotX, cubeRotY, cubeRotZ = cubeRotX + rotSpeedX, cubeRotY + rotSpeedY,
        cubeRotZ + rotSpeedZ

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
        collectgarbage()
        local f = io.open(logFileName, "a")
        if f then
            local logMessage = os.date("%Y-%m-%d %H:%M:%S", os.time()) .. ", rt:" ..
                timeString .. ", batt:" .. battPct .. ", eq:-/-" ..
                ", fps:" .. fps
            if config.batterysteve.unreliablebattery then
                logMessage = logMessage .. ", POSSIBLE_BATTERY_FAULT"
            else
                logMessage = logMessage .. ", BATTERY_FAILURE"
            end
            f:write(logMessage .. "\n")
            f:close()
        end

        if not config.batterysteve.unreliablebattery then
            screen.clear(color.new(40, 10, 10))
            screen.print(240, 130, "BATTERY DIED", 0.7, color.new(255, 50, 50))
            bigmsg(timeString)
            screen.print(240, 190, "Press any button to exit...", 0.5,
                color.new(200, 200, 200))
            screen.flip()
            amg.update()

            while true do
                buttons.read()
                if buttons.cross or buttons.circle or buttons.triangle or
                    buttons.square or buttons.start or buttons.select then
                    sound.stop(loop)
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
    local battLevel = tonumber(string.match(battPct, "(%d+)") or "0")
    local barColor
    if battLevel > 80 then
        barColor = color.new(50, 200, 50)
    elseif battLevel > 45 then
        barColor = color.new(200, 200, 50)
    else
        barColor = color.new(200, 50, 50)
    end
    draw.fillrect(5, 25, 100, 3, color.new(50, 50, 50))
    draw.fillrect(5, 25, battLevel, 3, barColor)
    for _, p in ipairs(particles) do
        p.x, p.y = p.x + p.vx, p.y + p.vy
        if p.x < 0 or p.x > 480 then p.vx = -p.vx end
        if p.y < 0 or p.y > 272 then p.vy = -p.vy end
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

    screen.print(5, 258,
        string.format("FPS:%d RUN:%s %s| %s %s", fps, timeString,
            batteryStr, hwgen, model), 0.40,
        color.new(200, 200, 200))

    if os.time() - lastLog >= logInterval then
        local logFile
        if not headerWritten then
            logFile = io.open(logFileName, "w")
            if logFile then
                local pspModel = hw.getmodel() .. "(" .. hw.gen() .. ", " .. hw.board() .. ")" or " "
                local header = string.format("BatterySteve %s on %s\n", BSV, pspModel)
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
            logFile:write(os.date("%Y-%m-%d %H:%M:%S", os.time()) .. ", rt:" ..
                timeString .. ", batt:" .. battPct .. ", eq:" ..
                remainCap .. " mAh/" .. fullCap .. " mAh" .. ", bV:" ..
                batvolt .. " v" .. ", fps:" .. fps .. "\n")
            logFile:close()
        end

        if power and power.tick then power.tick() end
        lastLog = os.time()
    end

    -- apparently some batteries will *die* randomly?
    -- lets keep a second copy for future reference
    if os.time() - lastBackup >= 31 then
        if copyFile(logFileName, "score.old.bak.txt") then end
        lastBackup = os.time()
    end

    screen.flip()
end

screen.clear(color.new(5, 60, 5))
screen.flip()
draw.fillrect(0, 0, 480, 272, color.new(40, 40, 40))
screen.print(240, 150, "Terminated", 0.5, color.new(200, 200, 200))
screen.print(240, 180, "Exiting in 5 seconds...", 0.5, color.new(200, 200, 200))
screen.flip()
os.delay(5000)
