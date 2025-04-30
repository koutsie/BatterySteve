local config = {}

do
    local defaultConfig = {
        batterysteve = {
            splashes = true,
            eastergg = false,
            cpu = 333,
            music = true,
        },
        autotest = {
            enabled = false
        }
    }

    local function parseValue(value)
        if value == "yes" or value == "true" then
            return true
        elseif value == "no" or value == "false" then
            return false
        elseif tonumber(value) then
            return tonumber(value)
        else
            return value
        end
    end

    local function validateConfig(config, defaults)
        for section, options in pairs(defaults) do
            config[section] = config[section] or {}
            for key, defaultValue in pairs(options) do
                local value = config[section][key]
                local valueType = type(defaultValue)
                if type(value) ~= valueType then
                    config[section][key] = defaultValue
                elseif valueType == "number" and (key == "cpu" and (value ~= 222 and value ~= 333)) then
                    config[section][key] = defaultValue
                end
            end
        end
    end

    local function loadConfigFromFile()
        for section, options in pairs(defaultConfig) do
            config[section] = {}
            for key, defaultValue in pairs(options) do
                local value = ini.read("config.ini", section, key, tostring(defaultValue))
                config[section][key] = parseValue(value)
            end
        end
    end

    local function generateDefaultConfigFile()
        for section, options in pairs(defaultConfig) do
            for key, value in pairs(options) do
                ini.write("config.ini", section, key, tostring(value))
            end
        end
    end

    local file, err = io.open("config.ini", "r")
    if file then
        file:close()
        loadConfigFromFile()
    else
        generateDefaultConfigFile()
        loadConfigFromFile()
    end

    validateConfig(config, defaultConfig)

    if config.batterysteve and config.batterysteve.eastergg then
        STEVE = true
    end
end

return config
