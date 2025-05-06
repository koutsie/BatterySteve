local modelmod = {}

local models = {}

function modelmod.init(baseVerts, baseEdges, cubePosX, cubePosY, cubeRotX, cubeRotY, cubeRotZ, rotSpeedX, rotSpeedY,
                       rotSpeedZ)
    models[1] = {
        verts = baseVerts,
        edges = baseEdges,
        pos = { x = cubePosX, y = cubePosY, z = 0 },
        rot = { x = cubeRotX, y = cubeRotY, z = cubeRotZ },
        rotSpeed = { x = rotSpeedX * 0.5, y = rotSpeedY * 0.5, z = rotSpeedZ * 0.5 },
        scale = 0.425,
        colorBase = { 123, 223, 2 }
    }
end

function modelmod.addModel(vertices, edges)
    local scale = math.random(30, 60) * 0.01
    local position = { x = math.random(0, 480), y = math.random(0, 272), z = 0 }
    local velocity = { x = math.random() * 2 - 1, y = math.random() * 2 - 1 }
    local rotationSpeed = { x = math.random() * 0.06, y = math.random() * 0.06, z = math.random() * 0.036 }
    local colorBase = { math.random(50, 255), math.random(50, 255), math.random(50, 255) }

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

function modelmod.getModels()
    return models
end

return modelmod
