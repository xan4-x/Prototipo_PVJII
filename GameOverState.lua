local GameOverState = {}
GameOverState.__index = GameOverState

function GameOverState.new()
    local self = setmetatable({}, GameOverState)
    self.victoria = false
    return self
end

function GameOverState:enter(params)
    if params then
        self.victoria = params.victoria
    end
end

function GameOverState:exit() end
function GameOverState:update(dt) end

function GameOverState:draw()
    if self.victoria then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("¡VICTORIA! Sobreviviste.", 300, 250)
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("DERROTA.", 350, 250)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Haz clic para volver al Menú", 280, 320)
end

function GameOverState:mousepressed(x, y, button)
    if button == 1 then
        gStateMachine:change('menu')
    end
end

return GameOverState