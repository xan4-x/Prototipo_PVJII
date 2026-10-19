local Event = require("Event")

local Jugador = {}
Jugador.__index = Jugador

local NUM_FRAMES = 12

function Jugador.new()
    local self = setmetatable({}, Jugador)
    self.x = 400
    self.y = 300
    self.speed = 200
    self.radius = 12
    self.hp = 100
    self.maxHp = 100

    self.sprite = love.graphics.newImage("assets/player.png")
    self.sprite:setFilter("nearest", "nearest")

    local imgW, imgH = self.sprite:getDimensions()
    self.frameWidth = imgW / NUM_FRAMES
    self.frameHeight = imgH

    self.quads = {}
    for i = 0, NUM_FRAMES - 1 do
        table.insert(self.quads, love.graphics.newQuad(
            i * self.frameWidth, 0,
            self.frameWidth, self.frameHeight,
            imgW, imgH
        ))
    end

    self.currentFrame = 1
    self.animTimer = 0
    self.facingLeft = false
    self.hurtFlashTimer = 0
    self.bullets = {}

    return self
end

function Jugador:takeDamage(amount)
    self.hp = math.max(0, self.hp - amount)
    self.hurtFlashTimer = 0.25

    -- Comunica mediante evento que el jugador recibió daño
    Event.dispatch("player_damaged", {
        damage = amount,
        currentHp = self.hp,
        x = self.x,
        y = self.y
    })

    if self.hp <= 0 then
        Event.dispatch("player_died")
    end
end

function Jugador:update(dt, mapa)
    if self.hurtFlashTimer > 0 then
        self.hurtFlashTimer = self.hurtFlashTimer - dt
    end

    local dx, dy = 0, 0
    if love.keyboard.isDown("w") then dy = -1 end
    if love.keyboard.isDown("s") then dy = 1 end
    if love.keyboard.isDown("a") then dx = -1; self.facingLeft = true end
    if love.keyboard.isDown("d") then dx = 1; self.facingLeft = false end

    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx = dx / length
        dy = dy / length
    end

    local nextX = self.x + dx * self.speed * dt
    local nextY = self.y + dy * self.speed * dt

    if not mapa:collides(nextX, self.y, self.radius) then
        self.x = nextX
    end
    if not mapa:collides(self.x, nextY, self.radius) then
        self.y = nextY
    end

    self.x = math.max(self.radius, math.min(800 - self.radius, self.x))
    self.y = math.max(70 + self.radius, math.min(600 - self.radius, self.y))

    if dx ~= 0 or dy ~= 0 then
        self.animTimer = self.animTimer + dt
        if self.animTimer > 0.08 then
            self.currentFrame = (self.currentFrame % #self.quads) + 1
            self.animTimer = 0
        end
    else
        self.currentFrame = 1
    end

    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.x = b.x + math.cos(b.angle) * b.speed * dt
        b.y = b.y + math.sin(b.angle) * b.speed * dt

        if b.x < 0 or b.x > 800 or b.y < 0 or b.y > 600 or mapa:collides(b.x, b.y, b.radius) then
            table.remove(self.bullets, i)
        end
    end
end

function Jugador:draw()
    -- Respuesta visual: parpadeo rojo al recibir daño
    if self.hurtFlashTimer > 0 then
        love.graphics.setColor(1, 0.3, 0.3, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    local scaleX = self.facingLeft and -1 or 1
    love.graphics.draw(
        self.sprite,
        self.quads[self.currentFrame],
        self.x, self.y,
        0, scaleX, 1,
        self.frameWidth / 2, self.frameHeight / 2
    )

    love.graphics.setColor(1, 0.9, 0.3, 1)
    for _, b in ipairs(self.bullets) do
        love.graphics.circle("fill", b.x, b.y, b.radius)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Jugador:shoot(mx, my)
    local angle = math.atan2(my - self.y, mx - self.x)
    table.insert(self.bullets, {
        x = self.x,
        y = self.y,
        speed = 500,
        radius = 4,
        angle = angle
    })

    -- Comunica mediante evento que el jugador disparó
    Event.dispatch("player_shoot", { x = self.x, y = self.y })
end

return Jugador