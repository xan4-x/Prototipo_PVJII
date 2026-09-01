local Jugador = require("jugador")
local Game = require("game")

local jugador
local game

function love.load()
    love.window.setMode(800, 600)
    love.window.setTitle("Escape de la Horda")
    
    jugador = Jugador.new()
    game = Game.new(jugador)
end

function love.update(dt)
    if game.state == "playing" then
        jugador:update(dt)
    end
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 and game.state == "playing" then
        jugador:shoot(x, y)
    end
end