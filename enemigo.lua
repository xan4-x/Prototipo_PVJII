local Enemigo = {}
Enemigo.__index = Enemigo

local sprite = nil
local quads = {}
local frameWidth = 48
local frameHeight = 48

local NUM_FRAMES = 6 

function Enemigo.loadAssets()
    sprite = love.graphics.newImage("assets/enemy.png")
    sprite:setFilter("nearest", "nearest")
    quads = {} -- Vaciamos la tabla para evitar duplicar quads al reiniciar la partida

    local imgW, imgH = sprite:getDimensions()
    frameWidth = imgW / NUM_FRAMES
    frameHeight = imgH

    for i = 0, NUM_FRAMES - 1 do
        table.insert(quads, love.graphics.newQuad(
            i * frameWidth, 0,
            frameWidth, frameHeight,
            imgW, imgH
        ))
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

function Enemigo:update(dt, playerX, playerY, mapa)
    local angleToPlayer = math.atan2(playerY - self.y, playerX - self.x)
    
    local nextX = self.x + math.cos(angleToPlayer) * self.speed * dt
    local nextY = self.y + math.sin(angleToPlayer) * self.speed * dt

    if not mapa:collides(nextX, self.y, self.radius) then
        self.x = nextX
    end
    if not mapa:collides(self.x, nextY, self.radius) then
        self.y = nextY
    end

    self.animTimer = self.animTimer + dt
    if self.animTimer > 0.12 then
        self.currentFrame = (self.currentFrame % #quads) + 1
        self.animTimer = 0
    end
end

function Enemigo:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        sprite,
        quads[self.currentFrame],
        self.x, self.y,
        0, 1, 1,
        frameWidth / 2, frameHeight / 2
    )
end

return Enemigo
