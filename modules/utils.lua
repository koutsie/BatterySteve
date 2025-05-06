local utils = {}
totalcals = 0

function utils.constrainValue(val, min, max)
    if val ~= val then return 0 end
    return math.min(math.max(val, min), max)
end

function utils.rotatePoint(p, ax, ay, az)
    local x, y, z = p[1], p[2], p[3]
    local cx, sx = math.cos(ax), math.sin(ax)
    local cy, sy = math.cos(ay), math.sin(ay)
    local cz, sz = math.cos(az), math.sin(az)
    local y1, z1 = y * cx - z * sx, y * sx + z * cx
    local x2, z2 = x * cy + z1 * sy, z1 * cy - x * sy
    return { x2 * cz - y1 * sz, x2 * sz + y1 * cz, z2 }
end

function utils.calculateEquation(b, eqA, eqB, eqD, constrainValue)
    if type(b) ~= "number" then error("Input b must be a number") end
    b = constrainValue(b, -256, 256)
    local x = (math.random() * 3.14 * math.sqrt(math.abs(b) + 0.1))
    x = constrainValue(x, -25, 25)
    local eqM = constrainValue(math.cos(b * 0.5) + 0.81, 0.1, 5)
    local t1 = constrainValue(math.sin(x * eqA) * math.cos((b + 2) * eqB), -5, 5)
    local t2 = constrainValue(math.pow(math.abs(x + b * 0.32), 1.5), 0.1, 10)
    local t3 = constrainValue(math.sqrt(b + 1) * eqM, 0.1, 10)
    local t4 = constrainValue(math.cos(x * b + 0.5) * t3, -5, 5)
    local t5 = constrainValue(math.log(math.abs(b) + 1) * eqA, -10, 10)
    local t6 = constrainValue(math.exp(-math.abs(x) * 0.1), 0.1, 10)
    local t7 = constrainValue(math.tan(b * 0.01) * eqD, -10, 10)
    local t8 = constrainValue(math.atan(x * 0.5) * eqM, -5, 5)
    local t9 = constrainValue(math.abs(math.sin(b * 0.25) * t6), 0.1, 10)
    local result = constrainValue(
        math.sin(t1 * eqD) * math.cos(t2 / 2) * eqM + t5 - t6 + t7 * t8 - t9,
        -2147483647, 2147483647
    )
    totalcals = totalcals + 1
    return result
end

function utils.drawTextWithShadow(x, y, text, size, color, shadowColor)
    local shadowOffset = 2
    screen.print(x + shadowOffset, y + shadowOffset, text, size, shadowColor)
    screen.print(x, y, text, size, color)
end

return utils
