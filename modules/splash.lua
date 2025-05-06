local splash = {}

function splash.show(splashes, fade_steps, delay, display_time, config)
    if not config.autotest.enabled and config.batterysteve.splashes then
        for i = 1, #splashes do
            local p = splashes[i]
            local img = image.load(p)
            if not img then
                os.message("splash failed to load: " .. p)
            else
                screen.clear(0)
                screen.flip()
                for j = 0, fade_steps do
                    local a = math.floor((j / fade_steps) * 255)
                    image.blit(img, 0, 0, a)
                    screen.flip()
                    os.delay(delay)
                end
                local start = os.time()
                while os.time() - start < display_time / 1000 do
                    buttons.read()
                    if buttons.cross or buttons.circle or buttons.triangle or
                        buttons.square or buttons.start or buttons.select then
                        break
                    end
                    image.blit(img, 0, 0, 255)
                    screen.print(350, 10, "Press any button to skip.", 0.25,
                        color.new(255, 255, 255))
                    screen.flip()
                    os.delay(delay)
                end
                for j = fade_steps, 0, -1 do
                    local a = math.floor((j / fade_steps) * 255)
                    image.blit(img, 0, 0, a)
                    screen.flip()
                    os.delay(delay)
                end
            end
        end
    end
end

return splash
