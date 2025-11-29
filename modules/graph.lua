local graph = {}
local target_pcts = { 75, 60, 45, 30, 15 }
local last_x = -80
local marked_targets = {}
local target_color = color.new(180, 255, 180)
local time_color = color.new(180, 180, 255)


-- uuuuuuuuuuuuuuuuuuuuuuuuuuuhhhhgh????
-- local function checkdata()
--             if not sec or not file then
--             local rectHeight = 272 * 0.33
--             draw.fillrect(0, rectHeight, 480, rectHeight, color.new(230, 50, 50))
--             local message = "no test data, failed!"
--             screen.print((480 - screen.textwidth(message, 1.0)) / 2, rectHeight + rectHeight / 2 - 1, message, 1.0,
--                 color.new(50, 50, 50))
--             screen.flip()
--             os.delay(10000)
--             os.exit()
--         end
-- end

local function seconds_to_hhmm(sec)
    local h, m = math.floor(sec / 3600), math.floor((sec % 3600) / 60)
    return string.format("%02dh %02dm", h, m)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function draw_line_series(times, values, min_val, scale_y, color_fn, x0, y0, scale_x)
    for i = 2, #times do
        local x1, y1 = x0 + times[i - 1] * scale_x, y0 - ((values[i - 1] - min_val) * scale_y)
        local x2, y2 = x0 + times[i] * scale_x, y0 - ((values[i] - min_val) * scale_y)
        local color = color.new(color_fn(i, values[i]))
        draw.line(x1, y1, x2, y2, color)
    end
end

function graph.draw_from_file(fileName)
    screen.clear(color.new(20, 20, 10))
    local times, percents, voltages = {}, {}, {}
    local min_pct, max_pct = 100, 0
    local min_voltage, max_voltage = 5.0, 0.0

    local file = io.open(fileName, "r")
    if not file then
        os.message("The file: " .. fileName .. " does not exist.")
        return
    end

    for line in file:lines() do
        local t, p, v = line:match("rt:(%d+:%d+:%d+), batt:(%d+).*bV:([%d%.]+)V")
        if t and p and v then
            local h, m, s = t:match("(%d+):(%d+):(%d+)")
            local timeInSeconds = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
            local percent, voltage = tonumber(p), tonumber(v)

            table.insert(times, timeInSeconds)
            table.insert(percents, percent)
            table.insert(voltages, voltage)

            min_pct = math.min(min_pct, percent)
            max_pct = math.max(max_pct, percent)
            min_voltage = math.min(min_voltage, voltage)
            max_voltage = math.max(max_voltage, voltage)
        end
    end
    file:close()

    if #times < 2 then
        os.message("no test data, failed!?")
        os.message("if this happens, please ping @koutsie on the PSP homebrew Discord or The TotalKommando Discord!")
        os.message("file read: " .. fileName .. "\nentries found: " .. #times)
        os.message("min_pct: " .. tostring(min_pct) .. "\nmax_pct: " .. tostring(max_pct))
        screen.flip()
        os.delay(5000)
        return
    end

    if max_pct - min_pct < 5 then
        min_pct, max_pct = math.max(0, min_pct - 3), math.min(100, max_pct + 2)
    end

    local w, h = 400, 160
    local x0, y0 = 35, 215
    local max_time = times[#times] or 1
    local scale_x = w / max_time
    local scale_y = h / (max_pct - min_pct)
    local voltage_scale_y = h / (max_voltage - min_voltage)

    draw.fillrect(0, 0, 480, 272, color.new(20, 20, 20))
    draw.fillrect(x0, y0 - h, w, h, color.new(30, 30, 30))

    local axes_color = color.new(200, 200, 200)
    draw.line(x0, y0 - h, x0, y0, axes_color)
    draw.line(x0, y0, x0 + w, y0, axes_color)

    for pct = min_pct, max_pct, 25 do
        local y = y0 - ((pct - min_pct) * scale_y)
        draw.line(x0, y, x0 + w, y, color.new(60, 60, 60))
    end

    local battery_color_fn = function(_, pct)
        local factor = (pct - min_pct) / (max_pct - min_pct)
        return lerp(30, 60, factor), lerp(120, 250, factor), lerp(30, 100, factor)
    end

    local voltage_color_fn = function(i, _)
        local factor = 1 - ((i - 1) / (#times - 1))
        return lerp(120, 255, factor), lerp(60, 165, factor), 0
    end

    draw_line_series(times, percents, min_pct, scale_y, battery_color_fn, x0, y0, scale_x)
    draw_line_series(times, voltages, min_voltage, voltage_scale_y, voltage_color_fn, x0, y0, scale_x)

    local label_color = color.new(220, 220, 220)
    local voltage_color = color.new(255, 165, 0)

    screen.print(x0 - 30, y0 - h - 5, "100%", 0.4, label_color)
    screen.print(x0 - 30, y0 - (h / 2) - 5, "50%", 0.4, label_color)
    screen.print(x0 - 22, y0 - 5, "0%", 0.4, label_color)
    screen.print(x0 + w + 5, y0 - h - 5, string.format("%.2fV", max_voltage), 0.4, voltage_color)
    screen.print(x0 + w + 5, y0 - 5, string.format("%.2fV", min_voltage), 0.4, voltage_color)
    screen.print(x0, y0 + 8, seconds_to_hhmm(times[1]), 0.4, label_color)
    screen.print(x0 + w - 40, y0 + 8, seconds_to_hhmm(times[#times]), 0.4, label_color)
    -- defined here because uuuuuuuuuuuuuuuuuuuuuuuuuuuhhhhgh
    local function find_cross_point(target, i)
        local p1, p2 = percents[i - 1], percents[i]
        if (p1 >= target and p2 <= target) or (p1 <= target and p2 >= target) then
            local t1, t2 = times[i - 1], times[i]
            local v1, v2 = voltages[i - 1], voltages[i]
            local ratio = (target - p1) / (p2 - p1)
            return lerp(t1, t2, ratio), lerp(v1, v2, ratio)
        end
    end

    for _, target in ipairs(target_pcts) do
        for i = 2, #percents do
            local cross_time, cross_voltage = find_cross_point(target, i)
            if cross_time and cross_voltage then
                local x = x0 + cross_time * scale_x
                local y = y0 - ((target - min_pct) * scale_y)

                if x - last_x > 70 then
                    draw.circle(x, y, 3, target_color, 30)
                    screen.print(x - 12, y - 20, string.format("%d%%", target), 0.35, target_color)
                    screen.print(x - 16, y + 10, seconds_to_hhmm(cross_time), 0.35, time_color)
                    screen.print(x - 16, y + 25, string.format("%.2fV", cross_voltage), 0.35, voltage_color)
                    last_x = x
                    marked_targets[target] = true
                end
                break
            end
        end
    end

    local title = seconds_to_hhmm(max_time) .. " on BatterySteve v" .. BSV
    local titleX = (480 - screen.textwidth(title, 0.7)) / 2
    screen.print(titleX, 35, title, 0.7, color.new(255, 255, 255))

    local exitText = "Press start to exit..."
    local exitTextX = (480 - screen.textwidth(exitText, 0.4)) / 2
    screen.print(exitTextX, 240, exitText, 0.4, color.new(255, 255, 255))

    screen.print(40, 205, "Battery (%)", 0.4, color.new(30, 250, 30))
    screen.print(125, 205, "Voltage (V)", 0.4, voltage_color)
end

return graph
