local nc = {}
-- for TC/NC


-- fuck it we define them twice, carbage collector will take....
local logFileName = "score.txt"
local logFileNameBak = "score.bak.txt"
local logFileNameFinal = "score.final.txt"
local logMoveFolder = "logs"

local COLORS = {
    text = color.new(2, 146, 199),
    background = color.new(0, 0, 0),
}
local SCREEN_DIMENSIONS = {
    width = 480,
    height = 272
}
local TEXT_SIZE = 2.0

function bigmsg(txt)
    local textWidth = screen.textwidth(tostring(txt), TEXT_SIZE)
    local textHeight = screen.textheight(TEXT_SIZE)
    local x = (SCREEN_DIMENSIONS.width - textWidth) / 2
    local y = (SCREEN_DIMENSIONS.height - textHeight) / 1.78
    screen.print(x, y, tostring(txt), TEXT_SIZE, COLORS.text)
end

function nc.run()
    local startTime = os.clock()

    while (os.clock() - startTime) * 1000 < 500 do
        buttons.read()
        if buttons.down then
            screen.clear(COLORS.background)
            screen.txtcolor(COLORS.text)

            local lastRun = 0
            local lastRunWithLog = 0
            local lastLogFile = nil

            for i = 1, 9999 do
                local folderName = string.format("logs/run_%04d", i)
                if files.exists(folderName) then
                    lastRun = i
                    local logPatterns = {
                        string.format("%s/log.final_%04d.txt", folderName, i),
                        string.format("%s/log_%04d.txt", folderName, i),
                        string.format("%s/log.bak_%04d.txt", folderName, i)
                    }
                    for _, fileName in ipairs(logPatterns) do
                        if files.exists(fileName) then
                            lastRunWithLog = i
                            lastLogFile = fileName
                        end
                    end
                else
                    break
                end
            end

            if lastRunWithLog > 0 and lastLogFile then
                local file = io.open(lastLogFile, "r")
                local lastLine = nil
                if file then
                    for line in file:lines() do
                        lastLine = line
                    end
                    file:close()
                end

                if lastLine then
                    local lastRT = lastLine:match("rt:%s*([%d:]+)") or "No data"
                    bigmsg(lastRT)
                    screen.txtcolor(COLORS.text)
                    screen.consolexy(1, 1)
                    screen.consoleprint("Last run log (" .. lastRunWithLog .. ")")
                    screen.consolexy(42, 1)
                    screen.consoleprint("Totally Nuclear Kommandos!")
                    screen.consolexy(55, 32)
                    screen.consoleprint("start to exit")
                    screen.flip()
                    while (buttons.waitforkey(__START)) do
                        os.delay(16)
                    end
                    os.exit()
                else
                    screen.consolexy(1, 1)
                    screen.consoleprint("Found run " .. lastRunWithLog .. " but couldn't read log file")
                    screen.consolexy(1, 3)
                    screen.consoleprint("Press START to continue...")
                    screen.flip()
                    buttons.waitforkey(__START)
                end
            else
                screen.consolexy(1, 1)
                screen.consoleprint("No previous runs found")
                screen.consolexy(1, 3)
                screen.consoleprint("Press START to continue...")
                screen.flip()
                while (buttons.waitforkey(__START)) do
                    os.delay(16)
                end
            end

            screen.clear(COLORS.background)
            return
        end

        os.delay(16)
    end

    screen.txtcolor(COLORS.text)
    screen.consolexy(1, 1)
    screen.consoleprint("hold down to check log")
    screen.flip()
end

function copyFile(source, dest)
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

function getLastLogFile()
    local logs = files.listfiles(logMoveFolder)
    if logs and #logs > 0 then
        table.sort(logs, function(a, b)
            return a.name > b.name
        end)
        return logs[1].path
    end
    return nil
end

local function moveLogsSequentially()
    local logFiles = {
        { name = logFileName,      prefix = "log_" },
        { name = logFileNameFinal, prefix = "log.final_" },
        { name = logFileNameBak,   prefix = "log.bak_" }
    }

    local anyFilesExist = false
    for _, logFile in ipairs(logFiles) do
        if files.exists(logFile.name) then
            anyFilesExist = true
            break
        end
    end

    if not anyFilesExist then
        return false
    end

    local runIndex = 1
    local logFolder
    repeat
        logFolder = string.format("%s/run_%04d", logMoveFolder, runIndex)
        runIndex = runIndex + 1
    until not files.exists(logFolder) or runIndex > 1000

    files.mkdir(logFolder)
    local filesProcessed = 0

    for _, logFile in ipairs(logFiles) do
        if files.exists(logFile.name) then
            local index = 1
            local newLogFileName

            repeat
                newLogFileName = string.format("%s/%s%04d.txt", logFolder, logFile.prefix, index)
                index = index + 1
            until not files.exists(newLogFileName)

            if copyFile(logFile.name, newLogFileName) then
                os.remove(logFile.name)
                filesProcessed = filesProcessed + 1
                screen.consolexy(5, 5)
                screen.consoleprint("Mov: " .. logFile.name)
                screen.flip()
                os.delay(500)
            else
                screen.consolexy(5, 5)
                screen.consoleprint("Fail: " .. logFile.name)
                screen.flip()
                os.delay(1000)
            end
        end
    end

    if filesProcessed > 0 then
        screen.consolexy(5, 5)
        screen.consoleprint(filesProcessed .. " logs to " .. logFolder)
        screen.flip()
        os.delay(2000)
    end

    return true
end

moveLogsSequentially()

return nc
