local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new(states)
    local self = setmetatable({}, StateMachine)
    self.empty = {
        update = function() end,
        draw = function() end,
        enter = function() end,
        exit = function() end,
        mousepressed = function() end
    }
    self.states = states or {}
    self.current = self.empty
    return self
end

function StateMachine:change(stateName, enterParams)
    assert(self.states[stateName], "El estado no existe: " .. stateName)
    self.current:exit()
    self.current = self.states[stateName]()
    self.current:enter(enterParams)
end

function StateMachine:update(dt)
    self.current:update(dt)
end

function StateMachine:draw()
    self.current:draw()
end

function StateMachine:mousepressed(x, y, button)
    self.current:mousepressed(x, y, button)
end

return StateMachine