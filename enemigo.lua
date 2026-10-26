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
    quads = {}

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

function Enemigo.new(x, y, speedMultiplier)
    local self = setmetatable({}, Enemigo)
    self.x = x
    self.y = y
    self.baseSpeed = math.random(75, 115) * (speedMultiplier or 1)
    self.currentSpeed = self.baseSpeed
    self.radius = 12
    self.currentFrame = 1
    self.animTimer = 0

    self.state = "chase"
    self.targetX = x
    self.targetY = y
    self.dashAngle = 0
    self.waitTimer = 0
    self.co = coroutine.create(function()
        self:behaviorLoop()
    end)

    return self
end


function Enemigo:wait(seconds)
    coroutine.yield(seconds)
end

function Enemigo:behaviorLoop()
    -- Espera inicial aleatoria para que no todos embistan al mismo tiempo
    self:wait(math.random(10, 25) / 10)

    while true do
        -- Fase 1: Persecución normal hacia el jugador
        self.state = "chase"
        self.currentSpeed = self.baseSpeed
        self:wait(math.random(20, 35) / 10)

        -- Fase 2: Preparación 
        self.state = "charge"
        self.currentSpeed = 0
        self.dashAngle = math.atan2(self.targetY - self.y, self.targetX - self.x)
        self:wait(0.55)

        -- Fase 3: Embestida veloz
        self.state = "dash"
        self.currentSpeed = self.baseSpeed * 2.8
        self:wait(0.35)

        -- Fase 4: Recuperación breve tras la embestida
        self.state = "cooldown"
        self.currentSpeed = self.baseSpeed * 0.4
        self:wait(0.6)
    end
end

function Enemigo:update(dt, playerX, playerY, mapa)
    self.targetX = playerX
    self.targetY = playerY

    -- Actualizar corrutina de comportamiento del enemigo
    if coroutine.status(self.co) ~= "dead" then
        if self.waitTimer > 0 then
            self.waitTimer = self.waitTimer - dt
        end
        if self.waitTimer <= 0 then
            local ok, yieldedWait = coroutine.resume(self.co)
            if ok and type(yieldedWait) == "number" then
                self.waitTimer = yieldedWait
            end
        end
    end

    -- Determinar ángulo según el estado actual de la corrutina
    local moveAngle
    if self.state == "dash" then
        moveAngle = self.dashAngle
    else
        moveAngle = math.atan2(playerY - self.y, playerX - self.x)
    end

    local nextX = self.x + math.cos(moveAngle) * self.currentSpeed * dt
    local nextY = self.y + math.sin(moveAngle) * self.currentSpeed * dt

    if not mapa:collides(nextX, self.y, self.radius) then
        self.x = nextX
    end
    if not mapa:collides(self.x, nextY, self.radius) then
        self.y = nextY
    end

    self.animTimer = self.animTimer + dt
    local animSpeed = (self.state == "dash") and 0.05 or 0.12
    if self.animTimer > animSpeed then
        self.currentFrame = (self.currentFrame % #quads) + 1
        self.animTimer = 0
    end
end

function Enemigo:draw()
    -- Feedback visual según la fase de la corrutina
    if self.state == "charge" then
        local flash = math.abs(math.sin(love.timer.getTime() * 20))
        love.graphics.setColor(1, 0.3 + flash * 0.5, 0.2, 1)
    elseif self.state == "dash" then
        love.graphics.setColor(1, 0.25, 0.25, 1)
    elseif self.state == "cooldown" then
        love.graphics.setColor(0.6, 0.7, 1, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.draw(
        sprite,
        quads[self.currentFrame],
        self.x, self.y,
        0, 1, 1,
        frameWidth / 2, frameHeight / 2
    )
    love.graphics.setColor(1, 1, 1, 1)
end

return Enemigo
