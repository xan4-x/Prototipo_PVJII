local Jugador = {}
Jugador.__index = Jugador

function Jugador.new()
    local self = setmetatable({}, Jugador)
    self.x = 400
    self.y = 300
    self.speed = 200
    self.radius = 12
    self.hp = 100
    self.sprite = love.graphics.newImage("assets/player.png")
    self.quads = {}
    for i = 0, 3 do
        table.insert(self.quads, love.graphics.newQuad(i * 32, 0, 32, 32, self.sprite:getDimensions()))
    end
    self.currentFrame = 1
    self.animTimer = 0
    self.bullets = {}
    self.shootSound = love.audio.newSource("assets/sound/shoot.wav", "static")
    return self
end

function Jugador:update(dt, mapa)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w") then dy = -1 end
    if love.keyboard.isDown("s") then dy = 1 end
    if love.keyboard.isDown("a") then dx = -1 end
    if love.keyboard.isDown("d") then dx = 1 end

    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx*dx + dy*dy)
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

    -- Límites de la ventana
    self.x = math.max(self.radius, math.min(800 - self.radius, self.x))
    self.y = math.max(self.radius, math.min(600 - self.radius, self.y))

    if dx ~= 0 or dy ~= 0 then
        self.animTimer = self.animTimer + dt
        if self.animTimer > 0.1 then 
            self.currentFrame = self.currentFrame + 1
            if self.currentFrame > #self.quads then self.currentFrame = 1 end
            self.animTimer = 0
        end
    else
        self.currentFrame = 1 
    end

    -- Actualización de balas con colisión de terreno
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b.x = b.x + math.cos(b.angle) * b.speed * dt
        b.y = b.y + math.sin(b.angle) * b.speed * dt
        
        -- Si la bala sale de la pantalla o choca contra una roca, se elimina
        if b.x < 0 or b.x > 800 or b.y < 0 or b.y > 600 or mapa:collides(b.x, b.y, b.radius) then
            table.remove(self.bullets, i)
        end
    end
end

function Jugador:draw()
    love.graphics.setColor(1, 1, 1) 
    love.graphics.draw(self.sprite, self.quads[self.currentFrame], self.x, self.y, 0, 1, 1, 16, 16)
    
    love.graphics.setColor(1, 1, 1)
    for _, b in ipairs(self.bullets) do
        love.graphics.circle("fill", b.x, b.y, b.radius)
    end
end

function Jugador:shoot(mx, my)
    self.shootSound:stop()
    self.shootSound:play()
    local angle = math.atan2(my - self.y, mx - self.x)
    table.insert(self.bullets, {
        x = self.x,
        y = self.y,
        speed = 500,
        radius = 3,
        angle = angle
    })
end

return Jugador