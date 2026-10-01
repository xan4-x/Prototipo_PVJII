local StateMachine = require("StateMachine")
local MenuState = require("MenuState")
local PlayState = require("PlayState")
local GameOverState = require("GameOverState")

function love.load()
    love.window.setMode(800, 600)
    love.window.setTitle("Escape de la Horda")
    
    gStateMachine = StateMachine.new({
        ['menu'] = function() return MenuState.new() end,
        ['play'] = function() return PlayState.new() end,
        ['gameover'] = function() return GameOverState.new() end
    })
    
    gStateMachine:change('menu')
end

function love.update(dt)
    gStateMachine:update(dt)
end

function love.draw()
    gStateMachine:draw()
end

function love.mousepressed(x, y, button, istouch, presses)
    gStateMachine:mousepressed(x, y, button)
end