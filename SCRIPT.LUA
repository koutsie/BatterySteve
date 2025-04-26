-- BatterySteve 1.0
-- by Koutsie
-- Homeage: https://the-sauna.icu/batterysteve/
-- Fedi/Mastodon: https://layer8.space/@k
-- Report is saved as score.old.txt

Font = font.load("tiny.pgf")
font.setdefault(Font)

-- custom splash
local splash = image.loadv("splash.png")
local fade_steps = 50
local alpha = 0
local direction = 1
local wait_time = 8000       -- Total wait time in milliseconds
local wait_start = os.time() -- Record the start time

while true do
    buttons.read()
    if buttons.start or buttons.cross or buttons.circle then
        break
    end

    alpha = alpha + direction * (255 / fade_steps)
    if alpha >= 255 then
        alpha = 255
        direction = 0
    elseif alpha <= 0 then
        break
    end

    image.blit(splash, 0, 0, alpha)
    if direction == 0 then
        screen.consolexy(31, 32)
        screen.consoleprint("Press START, X, or CIRCLE to skip")
        screen.flip()
        while os.time() - wait_start < wait_time do
            buttons.read()
            if buttons.start or buttons.cross or buttons.circle then
                break
            end
            os.delay(16)
        end
        break
    end
    screen.flip()
    os.delay(16)
end

if alpha == 255 then
    for i = 255, 0, -5 do
        image.blit(splash, 0, 0, i)
        screen.flip()
        os.delay(16)
    end
end


local batt                 = require("batt")
local draw                 = require("draw")
local screen               = require("screen")
local cam3d                = require("cam3d")
local model3d              = require("model3d")
local os, io, math, string = os, io, math, string

os.cpu(333)
collectgarbage()

local eqA, eqB, eqC, eqD                 = 3.14, -2.98743, 19.5, 100
local battPct                            = 100
local cubeSize                           = 50
local cubePosX, cubePosY                 = 240, 136
local cubeRotX, cubeRotY, cubeRotZ       = 0, 90, 24
local rotSpeedX, rotSpeedY, rotSpeedZ    = 0.05, 0.03, 0.05
local focalLength                        = 120
local particleCount                      = 300
local particleMinSpeed, particleMaxSpeed = -2, 2
local particleRadius                     = 1
local logInterval                        = 30
local logFileName                        = "score.txt"
local frameCounter                       = 0
local calcInterval                       = 5
local eqVal                              = 0

local half                               = cubeSize / 2
local baseVerts                          = {
    { -half, -half, -half }, { half, -half, -half },
    { half,  half,  -half }, { -half, half, -half },
    { -half, -half, half }, { half, -half, half },
    { half,  half,  half }, { -half, half, half }
}
local baseEdges                          = {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
    { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 }
}

local function rotatePoint(p, ax, ay, az)
    local x, y, z = p[1], p[2], p[3]
    local cx, sx = math.cos(ax), math.sin(ax)
    local y1, z1 = y * cx - z * sx, y * sx + z * cx
    local cy, sy = math.cos(ay), math.sin(ay)
    local x2, z2 = x * cy + z1 * sy, -x * sy + z1 * cy
    local cz, sz = math.cos(az), math.sin(az)
    return { x2 * cz - y1 * sz, x2 * sz + y1 * cz, z2 }
end

local function calculateEquation(b)
    if type(b) ~= "number" then error("Input b must be a number") end
    local x        = math.random() * math.pi
    local t1       = math.sin(x * eqA) * math.cos((b + 1) * eqB)
    local t2       = math.pow(x + b * 0.5 + 1, 2.73)
    local t3       = math.log(math.abs(x - b) + 1.234)
    local t4       = math.exp(math.sin(x + b * eqC))
    local combined = t1 + t2 + t3 + t4
    local t5       = math.sqrt(math.abs(combined) + 0.001)
    return math.sin(t5 * eqD)
end

--  3d
Camera = cam3d.new()
cam3d.position(Camera, { 0, 2, 10 })
cam3d.eye(Camera, { 0, 0, 0 })
amg.init()
amg.quality(__8888)
amg.perspective(40.0)
amg.typelight(1, __DIRECTIONAL)
amg.colorlight(1, color.new(100, 100, 100), color.new(100, 100, 100), color.new(100, 100, 100))
amg.poslight(1, { 0.5, 1, 0.5 })

Plane = model3d.load(files.cdir() .. "/3d/Data/Plane/plane.obj")
Ball = model3d.load(files.cdir() .. "/3d/Data/Ball/ball.obj")
local scaleValues = { 1.55, 1.55, 1.55 }
model3d.scaling(Ball, 1, scaleValues)
model3d.shading(Ball, 1)
local BallRotX, BallRotY, BallRotZ = -90, 0, 0
local BallRotSpeedX, BallRotSpeedY, BallRotSpeedZ = 0.03, 0.05, 0.035

local models = {}
models[1] = {
    verts     = baseVerts,
    edges     = baseEdges,
    pos       = { x = cubePosX, y = cubePosY, z = 0 },
    rot       = { x = cubeRotX, y = cubeRotY, z = cubeRotZ },
    rotSpeed  = { x = rotSpeedX / 2, y = rotSpeedY / 2, z = rotSpeedZ / 2 },
    scale     = 0.85 / 2,
    colorBase = { 123, 223, 2 }
}

local function addModel(v, e)
    local s  = math.random(30, 60) / 100
    local x  = math.random(0, 480)
    local y  = math.random(0, 272)
    local vx = math.random(-2, 2) * 0.5
    local yv = math.random(-2, 2) * 0.5
    table.insert(models, {
        verts     = v,
        edges     = e,
        pos       = { x = x, y = y, z = 0 },
        rot       = { x = 0, y = 0, z = 0 },
        rotSpeed  = { x = math.random() * 0.02, y = math.random() * 0.02, z = math.random() * 0.02 },
        scale     = s,
        vel       = { x = vx, y = yv },
        colorBase = { math.random(100, 255), math.random(100, 255), math.random(100, 255) }
    })
end

addModel({ { 0, -40, 0 }, { 35, 20, 0 }, { -35, 20, 0 } }, { { 1, 2 }, { 2, 3 }, { 3, 1 } })
addModel({ { 0, 40, 0 }, { -40, -40, 40 }, { 40, -40, 40 }, { 40, -40, -40 }, { -40, -40, -40 } },
    { { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 5 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 2 } })
addModel({ { 0, 0, 40 }, { 40, 0, 0 }, { 0, 40, 0 }, { -40, 0, 0 }, { 0, -40, 0 }, { 0, 0, -40 } },
    { { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 5 }, { 1, 6 }, { 6, 2 }, { 6, 3 }, { 6, 4 }, { 6, 5 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 2 } })
addModel({ { 0, 0, 60 }, { 30, 30, 0 }, { -30, 30, 0 }, { -30, -30, 0 }, { 30, -30, 0 }, { 0, 0, -60 } },
    { { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 5 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 2 }, { 6, 2 }, { 6, 3 }, { 6, 4 }, { 6, 5 } })
addModel(
    { { 0, 0, 0 }, { 60, 0, 0 }, { -60, 0, 0 }, { 0, 60, 0 }, { 0, -60, 0 }, { 0, 0, 60 }, { 0, 0, -60 }, { 40, 40, 40 }, { -40, -40, -40 } },
    { { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 5 }, { 1, 6 }, { 1, 7 }, { 1, 8 }, { 1, 9 } })

local particles = {}
for i = 1, particleCount do
    local g = math.random(150, 200)
    particles[i] = {
        x      = math.random(0, 480),
        y      = math.random(0, 272),
        vx     = math.random(particleMinSpeed, particleMaxSpeed) * 0.5,
        vy     = math.random(particleMinSpeed, particleMaxSpeed) * 0.5,
        radius = math.random(1, particleRadius),
        color  = draw.newcolor and draw.newcolor(g, g, g) or color.new(g, g, g)
    }
end
screen.consoleprint("init done")
eqVal = calculateEquation(battPct)

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
    amg.mode2d(1)
    screen.clear(color.new(20, 20, 20))
    local pct = batt.lifepercent() or 0
    local isCharging = batt.charging()

    if pct < 100 then
        screen.print(240, 120, "Charge to 100%", 0.6, color.new(200, 200, 200))
    elseif pct >= 100 then
        if isCharging then
            screen.print(240, 150, "Unplug your charger!", 0.5, color.new(200, 200, 200))
        else
            screen.print(240, 180, "Press START to begin.", 0.5, color.new(200, 200, 200))
            buttons.read()
            if buttons.start then break end
        end
    end

    screen.consolexy(1, 1)
    screen.consoleprint("BatterySteve 1.0 by Koutsie")
    screen.consolexy(1, 2)
    screen.consoleprint("https://the-sauna.icu/BatterySteve/")
    screen.flip()
    os.delay(32)
end

local aaa, lastLog, fps, elapsedSeconds, lastUpdateTime = os.time(), os.time(), 0, 0, os.time()
local o = 0 -- offset
while true do
    screen.clear(color.new(20, 20, 20))
    buttons.read()
    if buttons.select and buttons.start then break end

    cam3d.set(Camera)
    amg.light(1, 1)
    amg.light(1, 10)

    BallRotX, BallRotY, BallRotZ = BallRotX + BallRotSpeedX, BallRotY + BallRotSpeedY,
        BallRotZ + BallRotSpeedZ
    model3d.rotation(Ball, 1, { BallRotX * 10, BallRotY * 10, BallRotZ * 10 })
    o = (o + 0.5) % 360
    local h = o / 60
    local i = math.floor(h)
    local f = h - i
    local p = 0.2
    local q = 1 - 0.8 * f
    local t = 1 - 0.8 * (1 - f)
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
    r, g, b = math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
    amg.colorlight(1, color.new(r, g, b), color.new(b * 0.5, r * 0.5, g * 0.5), color.new((r + g) / 2, (g + b) / 2,
        (b + r) / 2))
    model3d.render(Plane)
    model3d.render(Ball)
    amg.light(1, 0)
    amg.mode2d(1)

    cubeRotX, cubeRotY, cubeRotZ = cubeRotX + rotSpeedX, cubeRotY + rotSpeedY, cubeRotZ + rotSpeedZ

    local now                    = os.time()
    local dt                     = now - lastUpdateTime
    if dt > 0 then elapsedSeconds, lastUpdateTime = elapsedSeconds + dt, now end

    local sec        = elapsedSeconds % 60
    local min        = math.floor(elapsedSeconds / 60) % 60
    local hour       = math.floor(elapsedSeconds / 3600) % 24
    local timeString = string.format("%02d:%02d:%02d", hour, min, sec)

    fps              = screen.fps()
    battPct          = batt.lifepercent() or 0
    battPct          = batt.lifepercent() or 0
    local battChg    = batt.charging() and "Yes" or "No"
    local battTemp   = batt.temp() or 0
    local remainCap  = batt.remaincap()
    local fullCap    = batt.fullcap()

    -- very bad way of testing if battery cap is done for lol
    if (battPct == 0 and (remainCap == "-" or remainCap == nil)) then
        local f = io.open(logFileName, "a")
        if f then
            f:write(os.date("%Y-%m-%d %H:%M:%S", os.time())
                .. ", rt:" .. timeString
                .. ", batt:" .. battPct
                .. ", eq:-/-"
                .. ", fps:" .. fps
                .. ", BATTERY_FAILURE" .. "\n"
            )
            f:close()
        end

        screen.clear(color.new(40, 10, 10))
        screen.print(240, 130, "BATTERY DIED", 0.7, color.new(255, 50, 50))
        screen.print(240, 160, "Total runtime: " .. timeString, 0.5, color.new(200, 200, 200))
        screen.print(240, 190, "Press any button to exit...", 0.5, color.new(200, 200, 200))
        screen.flip()

        while true do
            buttons.read()
            if buttons.cross or buttons.circle or buttons.triangle or buttons.square or
                buttons.start or buttons.select then
                if copyFile(logFileName, "score.old.txt") then
                    os.remove(logFileName)
                    screen.print(240, 220, "Score file backed up.", 0.4, color.new(150, 150, 150))
                    screen.flip()
                    os.delay(2000)
                end
                break
            end
            os.delay(100)
        end
        break
    end
    local battChg  = batt.charging() and "Yes" or "No"
    local battTemp = batt.temp() or 0

    frameCounter   = frameCounter + 1
    if frameCounter >= calcInterval then
        eqVal, frameCounter = calculateEquation(battPct), 0
    end

    draw.fillrect(0, 0, 480, 20, color.new(40, 40, 40))
    screen.print(5, 8,
        "BATT: " .. battPct .. " TEMP: " .. battTemp .. "*C | RAM: " ..
        string.format("%05.2f", os.ram() / 1048576) ..
        " MB / " ..
        string.format("%05.2f", os.totalram() / 1048576) ..
        " MB",
        0.5,
        color.new(200, 200, 200)
    )

    local battLevel = tonumber(string.match(battPct, "(%d+)") or "0")
    local barW = math.max(5, 256 * battLevel / 100)
    local barColor
    if battLevel > 45 then
        barColor = color.new(50, 200, 50)
    elseif battLevel > 20 then
        barColor = color.new(200, 200, 50)
    else
        barColor = color.new(200, 50, 50)
    end
    draw.fillrect(5, 25, 100, 3, color.new(50, 50, 50))
    draw.fillrect(5, 25, barW, 3, barColor)
    for _, p in ipairs(particles) do
        p.x, p.y = p.x + p.vx, p.y + p.vy
        if p.x < 0 or p.x > 480 then p.vx = -p.vx end
        if p.y < 0 or p.y > 272 then p.vy = -p.vy end
        draw.fillrect(p.x - 1, p.y - 1, 2, 2, p.color)
    end

    local verts2 = {}
    for i, v in ipairs(baseVerts) do
        local r = rotatePoint(v, cubeRotX, cubeRotY, cubeRotZ)
        local s = focalLength / (focalLength + r[3])
        verts2[i] = { x = r[1] * s + cubePosX, y = r[2] * s + cubePosY }
    end
    for _, e in ipairs(baseEdges) do
        local v1, v2 = verts2[e[1]], verts2[e[2]]
        draw.line(v1.x, v1.y, v2.x, v2.y, color.new(200, 200, 200))
    end

    for _, m in ipairs(models) do
        m.rot.x, m.rot.y, m.rot.z = m.rot.x + m.rotSpeed.x, m.rot.y + m.rotSpeed.y, m.rot.z + m.rotSpeed.z
        if m.vel then
            m.pos.x, m.pos.y = m.pos.x + m.vel.x, m.pos.y + m.vel.y
            if m.pos.x < 0 or m.pos.x > 480 then m.vel.x = -m.vel.x end
            if m.pos.y < 0 or m.pos.y > 272 then m.vel.y = -m.vel.y end
        end
        local cols = {
            (m.colorBase[1] + os.clock() * 50) % 255,
            (m.colorBase[2] + os.clock() * 50) % 255,
            (m.colorBase[3] + os.clock() * 50) % 255
        }
        local vertsM = {}
        for i, v in ipairs(m.verts) do
            local r = rotatePoint(v, m.rot.x, m.rot.y, m.rot.z)
            local s = focalLength / (focalLength + r[3]) * m.scale
            vertsM[i] = { x = r[1] * s + m.pos.x, y = r[2] * s + m.pos.y }
        end
        for _, e in ipairs(m.edges) do
            local v1, v2 = vertsM[e[1]], vertsM[e[2]]
            draw.line(v1.x, v1.y, v2.x, v2.y,
                draw.newcolor and draw.newcolor(cols[1], cols[2], cols[3]) or color.new(cols[1], cols[2], cols[3])
            )
        end
    end

    draw.fillrect(0, 250, 480, 22, color.new(40, 40, 40))
    local hwgen     = hw.gen()
    local cfw       = os.cfw()
    local model     = (cfw ~= "UNK") and tostring(hw.getmodel() .. " on " .. cfw) or tostring(hw.getmodel())
    local batremain = tostring(batt.remaincap()) .. "/" .. tostring(batt.fullcap())
    local batvolt   = batt.volt()
    screen.print(5, 258,
        string.format("FPS:%d RUN:%s BAT: %s (%s)| %s %s", fps, timeString, batremain, batvolt, hwgen, model),
        0.40,
        color.new(200, 200, 200)
    )

    if os.time() - lastLog >= logInterval then
        local f = io.open(logFileName, "a")
        if f then
            local remainCap = tostring(batt.remaincap())
            local fullCap = tostring(batt.fullcap())
            f:write(os.date("%Y-%m-%d %H:%M:%S", os.time())
                .. ", rt:" .. timeString
                .. ", batt:" .. battPct
                .. ", eq:" .. remainCap .. " mAh/" .. fullCap .. " mAh"
                .. ", fps:" .. fps .. "\n"
            )
            f:close()
            power.tick()
        end
        lastLog = os.time()
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
