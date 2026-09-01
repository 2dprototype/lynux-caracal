function love.conf(t)
    t.window.width = 760
    t.window.height = 480
    t.window.minwidth = 480
    t.window.minheight = 320
    t.window.resizable = true
    t.window.title = "Daydream Newspaper Club"
    t.identity = "daydream_newspaper_club"
    t.console = true

    -- Mobile & Display Support
    t.window.highdpi = true
    t.window.usedpiscale = true
    t.modules.touch = true
    t.modules.keyboard = true
    t.modules.mouse = true
    t.modules.graphics = true
    t.modules.audio = true
    t.modules.sound = true
    t.modules.timer = true
    t.modules.event = true
    t.modules.filesystem = true
    t.externalstorage = true
end

