-- main.lua
-- Lynux Caracal: Hybrid Visual Novel & Simulated Desktop Engine
pcall(function() io.stdout:setvbuf("no") end)

local GameManager = require("src.core.game_manager")

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setTextInput(true)
    love.keyboard.setKeyRepeat(true)
    
    GameManager.init()
end

function love.update(dt)
    GameManager.update(dt)
end

function love.draw()
    GameManager.draw()
end

function love.mousepressed(x, y, button)
    GameManager.mousepressed(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    GameManager.mousemoved(x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    GameManager.mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
    GameManager.wheelmoved(x, y)
end

function love.textinput(text)
    GameManager.textinput(text)
end

function love.keypressed(key)
    GameManager.keypressed(key)
end

function love.resize(w, h)
    GameManager.resize(w, h)
end