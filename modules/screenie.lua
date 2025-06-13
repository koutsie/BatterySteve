    local screenie = {}

    local function copyFile(src, dst)
        local infile = io.open(src, "rb")
        if not infile then return false end
        local data = infile:read("*a")
        infile:close()
        local outfile = io.open(dst, "wb")
        if not outfile then return false end
        outfile:write(data)
        outfile:close()
        return true
    end

    function screenie.save_screenshot()
        os.delay(100)
        local screenshot_path = "screenshot.png"
        screen.shot(screenshot_path)
        os.delay(60)

        local logMoveFolder = "logs"
        local runIndex = 1
        local logFolder

        repeat
            logFolder = string.format("%s/run_%04d", logMoveFolder, runIndex)
            runIndex = runIndex + 1
        until not files.exists(logFolder) or runIndex > 1000

        files.mkdir(logFolder)
        os.delay(60)

        local newScreenshotPath = string.format("%s/screenshot_%04d.png", logFolder, runIndex - 1)
        if files.exists(screenshot_path) then
            if copyFile(screenshot_path, newScreenshotPath) then
                os.remove(screenshot_path)
                os.delay(60)
                os.message("Screenshot saved!")
            else
                os.message("Failed to save screenshot.")
            end
        else
            os.message("Screenshot file not found.")
        end
        os.delay(60)
    end

    return screenie