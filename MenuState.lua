local MenuState = {}
MenuState.__index = MenuState

function MenuState.new()
    local self = setmetatable({}, MenuState)
    self.btn = { x = 280, y = 320, w = 240, h = 50, hovered = false }
    return self
end

function MenuState:enter(params) end
function MenuState:exit() end

function MenuState:update(dt)
    local mx, my = love.mouse.getPosition()
    self.btn.hovered = mx >= self.btn.x and mx <= self.btn.x + self.btn.w and
                       my >= self.btn.y and my <= self.btn.y + self.btn.h
end

function MenuState:draw()
    love.graphics.clear(0.08, 0.1, 0.14)

    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.printf("ESCAPE DE LA HORDA", 0, 150, 800, "center")

    love.graphics.setColor(0.8, 0.85, 0.9)
    love.graphics.printf("Sobreviví a las oleadas hasta que se active la Zona de Extracción central.", 0, 200, 800, "center")
    love.graphics.printf("Controles: WASD para moverte | Clic Izquierdo para disparar | ESC para salir", 0, 235, 800, "center")

    if self.btn.hovered then
        love.graphics.setColor(0.25, 0.75, 0.35)
    else
        love.graphics.setColor(0.15, 0.5, 0.25)
    end
    love.graphics.rectangle("fill", self.btn.x, self.btn.y, self.btn.w, self.btn.h, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.btn.x, self.btn.y, self.btn.w, self.btn.h, 8, 8)
    love.graphics.printf("INICIAR PARTIDA", self.btn.x, self.btn.y + 18, self.btn.w, "center")
end

function MenuState:mousepressed(x, y, button)
    if button == 1 and self.btn.hovered then
        gStateMachine:change('play')
    end
end

return MenuState