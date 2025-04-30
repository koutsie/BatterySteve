-- requested by Nuclear Kommando

local nc = {}

local function bigmsg(txt)
    local size, color_val = 2.0, color.new(2, 146, 199)
    screen.print(150, 136, tostring(txt), size, color_val)
end

function nc.run()
    local elapsed, interval = 0, 16
    local downPressed = false
    while elapsed < 128 do
        screen.consolexy(1, 1)
        screen.consoleprint("hold down to check log")
        screen.flip()
        buttons.read()
        if buttons.down then
            downPressed = true
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
            screen.consoleprint("v" .. BSV)
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
