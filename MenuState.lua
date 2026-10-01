local MenuState = {}
MenuState.__index = MenuState

function MenuState.new()
    return setmetatable({}, MenuState)
end

function MenuState:enter(params) end
function MenuState:exit() end
function MenuState:update(dt) end

function MenuState:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("ESCAPE DE LA HORDA", 300, 250)
    love.graphics.print("Haz clic para jugar", 320, 300)
end

function MenuState:mousepressed(x, y, button)
    if button == 1 then
        gStateMachine:change('play')
    end
end

return MenuState