local GameOverState = {}
GameOverState.__index = GameOverState

function GameOverState.new()
    local self = setmetatable({}, GameOverState)
    self.victoria = false
    self.kills = 0
    self.btn = { x = 280, y = 360, w = 240, h = 50, hovered = false }
    return self
end

function GameOverState:enter(params)
    if params then
        self.victoria = params.victoria
        self.kills = params.kills or 0
    end
end

function GameOverState:exit() end

function GameOverState:update(dt)
    local mx, my = love.mouse.getPosition()
    self.btn.hovered = mx >= self.btn.x and mx <= self.btn.x + self.btn.w and
                       my >= self.btn.y and my <= self.btn.y + self.btn.h
end

function GameOverState:draw()
    love.graphics.clear(0.08, 0.08, 0.1)

    if self.victoria then
        love.graphics.setColor(0.2, 0.9, 0.3)
        love.graphics.print("¡VICTORIA! EXTRACCIÓN COMPLETADA", 280, 220)
    else
        love.graphics.setColor(0.95, 0.2, 0.2)
        love.graphics.print("DERROTA - CAÍSTE ANTE LA HORDA", 290, 220)
    end

    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.print("Enemigos eliminados: " .. self.kills, 330, 270)

    if self.btn.hovered then
        love.graphics.setColor(0.3, 0.5, 0.85)
    else
        love.graphics.setColor(0.2, 0.35, 0.6)
    end
    love.graphics.rectangle("fill", self.btn.x, self.btn.y, self.btn.w, self.btn.h, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.btn.x, self.btn.y, self.btn.w, self.btn.h, 8, 8)
    love.graphics.print("VOLVER AL MENÚ", self.btn.x + 65, self.btn.y + 18)
end

function GameOverState:mousepressed(x, y, button)
    if button == 1 and self.btn.hovered then
        gStateMachine:change('menu')
    end
end

return GameOverState