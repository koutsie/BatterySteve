local unreliable = {}

local NUKE = false
local isPhat = false
local logFileName = "score.txt"
local cubeSize = 25
local cubePosX, cubePosY = 240, 136
local cubeRotX, cubeRotY, cubeRotZ = 0, 90, 24
local rotSpeedX, rotSpeedY, rotSpeedZ = 0.05, 0.03, 0.05

local particleCount = 300
local particleMinSpeed, particleMaxSpeed = -3, 3
local particleRadius = 1
local particles = {}

function unreliable.init(nukeMode, isPhatMode)
    NUKE = nukeMode or false
    isPhat = isPhatMode or false
    amg.init()
    Camera = cam3d.new()
    amg.quality(__8888)
    amg.perspective(46.0)
    amg.typelight(1, __DIRECTIONAL)
    amg.colorlight(1, color.new(50, 50, 50), color.new(100, 100, 100), color.new(200, 200, 200))
    amg.poslight(1, { 1, 4, 1 })

    if not NUKE then
        Plane = model3d.load(files.cdir() .. "/3d/Data/Plane/plane.obj")
    else
        Plane = model3d.load(files.cdir() .. "/3d/Data/NUKE/plane.obj")
    end
    Ball = model3d.load(files.cdir() .. "/3d/Data/Ball/ball.obj")

    if not Ball or not Plane then
        return false
    end

    local scaleValues = { 0.60, 0.60, 0.60 }
    model3d.scaling(Ball, 1, scaleValues)
    model3d.shading(Ball, 1)
    model3d.position(Ball, 1, { 0, 0.75, 0 })
    model3d.scaling(Plane, 1, { 0.25, 0.25, 0.25 })
    model3d.position(Plane, 1, { 0, -0.65, 0 })

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

    return true
end

function unreliable.run(musicenabled, intro, loop, loopStarted, utils)
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

    local centerSpinVerts = {
        { 0, -30, 15 }, { 26, -15, 15 }, { 26, 15, 15 }, { 0, 30, 15 }, { -26, 15, 15 }, { -26, -15, 15 },
        { 0, -30, -15 }, { 26, -15, -15 }, { 26, 15, -15 }, { 0, 30, -15 }, { -26, 15, -15 }, { -26, -15, -15 }
    }
    local centerSpinEdges = {
        { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 5 }, { 5, 6 }, { 6, 1 },
        { 7, 8 }, { 8, 9 }, { 9, 10 }, { 10, 11 }, { 11, 12 }, { 12, 7 },
        { 1, 7 }, { 2, 8 }, { 3, 9 }, { 4, 10 }, { 5, 11 }, { 6, 12 }
    }
    local centerSpinRotX, centerSpinRotY, centerSpinRotZ = 0, 0, 0
    local centerSpinRotSpeedX, centerSpinRotSpeedY, centerSpinRotSpeedZ = 0.04, 0.05, 0.03

    local currentRotation = 0
    local BallRotX, BallRotY, BallRotZ = -360, 45, 32
    local BallRotSpeedX, BallRotSpeedY, BallRotSpeedZ = 0.06, 0.06, 0.045

    local lastLog = os.time()
    local logInterval = 30
    local elapsedSeconds = 0
    local lastUpdateTime = os.time()
    local headerWritten = false
    local o = 0
    local ui_visible = true
    local ui_last_action = os.time()
    local ui_timeout = 30
    local sysModel = hw.getmodel()
    local sysGen = hw.gen()
    local sysBoard = hw.board()

    while true do
        amg.begin()
        if musicenabled then
            if not intro then
                intro = sound.load("audio/laamaa-intro.mp3")
                loop = sound.load("audio/laamaa-loop.mp3")
                sound.vol(intro, 100)
                sound.play(intro)
            end
            if not loopStarted and intro and sound.endstream(intro) then
                sound.vol(loop, 100)
                sound.play(loop)
                sound.loop(loop)
                loopStarted = true
            end
        end

        buttons.read()
        if buttons.select and buttons.start then
            break
        end

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
            NUKE and color.new(128, 128, 128, 255) or color.new(r, g, b, 255),
            NUKE and color.new(128, 128, 128, 128) or color.new(halfB, halfR, halfG, 128),
            NUKE and color.new(128, 128, 128, 192) or color.new(avgR, avgG, avgB, 192)
        )

        currentRotation = ((currentRotation or 0) + 0.5) % 360
        local radius = 4.75
        local ballY = 0.75
        local camX = math.cos(math.rad(currentRotation)) * radius
        local camZ = math.sin(math.rad(currentRotation)) * radius
        cam3d.position(Camera, { camX, ballY + 1.85, camZ })
        cam3d.eye(Camera, { 0, ballY - 2, 0 })
        cam3d.set(Camera)
        model3d.render(Plane)

        if isPhat then
            model3d.render(Ball)
        else
            model3d.startreflection(Plane, 1)
            model3d.mirror(Ball, 1, NUKE and 0 or 2)
            model3d.finishreflection()
            model3d.render(Ball)
        end

        amg.light(1, 0)

        cubeRotX = (cubeRotX + rotSpeedX) % 360
        cubeRotY = (cubeRotY + rotSpeedY) % 360
        cubeRotZ = (cubeRotZ + rotSpeedZ) % 360

        centerSpinRotX = (centerSpinRotX + centerSpinRotSpeedX) % 360
        centerSpinRotY = (centerSpinRotY + centerSpinRotSpeedY) % 360
        centerSpinRotZ = (centerSpinRotZ + centerSpinRotSpeedZ) % 360

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

        local fps = screen.fps()

        for _, part in ipairs(particles) do
            part.x = (part.x + part.vx) % 480
            part.y = (part.y + part.vy) % 272
            draw.fillrect(part.x - 1, part.y - 1, 2, 2, part.color)
        end

        local verts2 = {}
        for idx, v in ipairs(baseVerts) do
            local rot = rotatePoint(v, cubeRotX, cubeRotY, cubeRotZ)
            verts2[idx] = { x = rot[1] + cubePosX, y = rot[2] + cubePosY }
        end
        for _, e in ipairs(baseEdges) do
            local v1, v2 = verts2[e[1]], verts2[e[2]]
            draw.line(v1.x, v1.y, v2.x, v2.y, color.new(200, 200, 200))
        end

        local centerVerts2 = {}
        for idx, v in ipairs(centerSpinVerts) do
            local rot = rotatePoint(v, centerSpinRotX, centerSpinRotY, centerSpinRotZ)
            centerVerts2[idx] = { x = rot[1] + 240, y = rot[2] + 136 }
        end
        for _, e in ipairs(centerSpinEdges) do
            local v1, v2 = centerVerts2[e[1]], centerVerts2[e[2]]
            draw.line(v1.x, v1.y, v2.x, v2.y, color.new(150, 150, 150))
        end

        if ui_visible then
            local barBgColor = NUKE and color.new(0, 0, 0) or color.new(40, 40, 40)
            draw.fillrect(0, 0, 480, 20, barBgColor)
            screen.print(5, 8, "UNRELIABLE MODE | TIME: " .. timeString .. " | FPS: " .. fps, 0.5,
                color.new(200, 200, 200))
        end

        if ui_visible then
            local barBgColor = NUKE and color.new(0, 0, 0) or color.new(40, 40, 40)
            draw.fillrect(0, 252, 480, 20, barBgColor)
            local cpuFreq = os.cpu() .. "/" .. os.bus()
            local ramUsed = math.floor(os.ram() / 1024 / 1024)
            local ramTotal = math.floor(os.totalram() / 1024 / 1024)
            screen.print(5, 258,
                string.format("CPU: %s MHz | RAM: %d/%d MB | %s (%s, %s)", cpuFreq, ramUsed, ramTotal, sysModel, sysGen,
                    sysBoard), 0.40, color.new(200, 200, 200))
        end

        if os.time() - lastLog >= logInterval then
            local logFile
            if not headerWritten then
                logFile = io.open(logFileName, "w")
                if logFile then
                    logFile:write("BS UNRELIABLE MODE - NUKED\n")
                    headerWritten = true
                end
            else
                logFile = io.open(logFileName, "a")
            end

            if logFile then
                logFile:write("rt:" .. timeString .. ", fps:" .. fps .. "\n")
                logFile:close()
            end

            if power and power.tick then power.tick() end
            lastLog = os.time()
        end

        amg.update()
        screen.flip()
        os.delay(16)
    end

    if musicenabled then
        if intro then sound.stop(intro) end
        if loop then sound.stop(loop) end
    end
end

return unreliable
