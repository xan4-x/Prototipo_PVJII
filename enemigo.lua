local Enemigo = {}
Enemigo.__index = Enemigo

local sprite = nil
local quads = {}

function Enemigo.loadAssets()
    sprite = love.graphics.newImage("assets/enemy.png")
    for i = 0, 3 do
        table.insert(quads, love.graphics.newQuad(i * 32, 0, 32, 32, sprite:getDimensions()))
    end
end

function Enemigo.new(x, y)
    local self = setmetatable({}, Enemigo)
    self.x = x
    self.y = y
    self.speed = math.random(70, 120)
    self.radius = 12
    self.currentFrame = 1
    self.animTimer = 0
    return self
end

function Enemigo:update(dt, playerX, playerY)
    local angleToPlayer = math.atan2(playerY - self.y, playerX - self.x)
    self.x = self.x + math.cos(angleToPlayer) * self.speed * dt
    self.y = self.y + math.sin(angleToPlayer) * self.speed * dt

    self.animTimer = self.animTimer + dt
    if self.animTimer > 0.1 then
        self.currentFrame = self.currentFrame + 1
        if self.currentFrame > #quads then self.currentFrame = 1 end
        self.animTimer = 0
    end
end

function Enemigo:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(sprite, quads[self.currentFrame], self.x, self.y, 0, 1, 1, 16, 16)
end

return Enemigo