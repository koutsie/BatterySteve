-- "testing with style" - Nuclear Kommando
local nc = {}

local COLORS = {
    text = color.new(2, 146, 199),
    background = color.new(0, 0, 0)
}
local SCREEN_DIMENSIONS = {
    width = 480,
    height = 272
}
local TEXT_SIZE = 2.0
local INTERVAL = 32
local MAX_ELAPSED = 128

function bigmsg(txt)
    local textWidth = screen.textwidth(tostring(txt), TEXT_SIZE)
    local textHeight = screen.textheight(TEXT_SIZE)
    local x = (SCREEN_DIMENSIONS.width - textWidth) / 2
    local y = (SCREEN_DIMENSIONS.height - textHeight) / 1.78
    screen.print(x, y, tostring(txt), TEXT_SIZE, COLORS.text)
end

function nc.run()
    local elapsed = 0
    while elapsed < MAX_ELAPSED do
        screen.txtcolor(COLORS.text)
        screen.consolexy(1, 1)
        screen.consoleprint("hold down to check log")
        screen.flip()
        buttons.read()
        if buttons.down then
            screen.clear(COLORS.background)
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

            local lastRT = lastLine and lastLine:match("rt:%s*([%d:]+)") or "No data"
            bigmsg(lastRT)
            screen.consolexy(1, 1)
            screen.consoleprint("v" .. BSV .. " | " .. hw.getmodel() .. "(" .. hw.gen() .. ", " .. hw.board() .. ")" or
                " ")
            screen.consolexy(42, 1)
            screen.consoleprint("Totally Nuclear Kommandos!")
            -- bottom right "start to exit" using consoleprint
            screen.consolexy(55, 32)
            screen.consoleprint("start to exit")
            screen.flip()
            while true do
                buttons.read()
                if buttons.start then
                    screen.clear(COLORS.background)
                    screen.flip()
                    break
                end
                os.delay(16)
            end
        end
        os.delay(INTERVAL)
        elapsed = elapsed + INTERVAL
    end
end

return nc
