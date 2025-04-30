-- requested by Nuclear Kommando

local nc = {}

function bigmsg(txt)
    local size, color_val = 2.0, color.new(2, 146, 199)
    local textWidth = screen.textwidth(tostring(txt), size)
    local textHeight = screen.textheight(size)
    local screenWidth, screenHeight = 480, 272
    local x = (screenWidth - textWidth) / 2
    -- screen height is not / 2 because thats too high
    local y = (screenHeight - textHeight) / 1.78
    screen.print(x, y, tostring(txt), size, color_val)
end

function nc.run()
    local elapsed, interval = 0, 16
    while elapsed < 128 do
        screen.consolexy(1, 1)
        screen.consoleprint("hold down to check log")
        screen.flip()
        buttons.read()
        if buttons.down then
            screen.clear(0, 0, 0)
            local lastLine = nil
            for _, filename in ipairs({
                logFileNameFinal, logFileName, logFileNameBak
            }) do
                local file = io.open(filename, "r")
                if file then
                    for line in file:lines() do
                        lastLine = line
                    end
                    file:close()
                    break
                end
            end

            local lastRT
            if lastLine then
                lastRT = lastLine:match("rt:%s*([%d:]+)")
            else
                lastRT = "No data"
            end
            bigmsg(lastRT)
            screen.consolexy(1, 1)
            screen.consoleprint("v" .. BSV .. " | " .. hw.getmodel() .. "(" .. hw.gen() .. ", " .. hw.board() .. ")" or
                " ")
            screen.consolexy(42, 1)
            screen.consoleprint("Totally Nuclear Kommandos!")
            screen.flip()
            -- halt the script forever, only exit on start.
            while true do
                buttons.read()
                if buttons.start then
                    screen.clear(0, 0, 0)
                    screen.flip()
                    break
                end
                os.delay(16)
            end
        end
        os.delay(interval)
        elapsed = elapsed + interval
    end
end

return nc
