local PlayState = {}
PlayState.__index = PlayState

local Enemigo = require("enemigo")
local Jugador = require("jugador")

function PlayState.new()
    return setmetatable({}, PlayState)
end

function PlayState:enter(params)
    self.jugador = Jugador.new()
    self.timer = 30
    self.shakeTimer = 0
    self.enemies = {}
    self.hitSound = love.audio.newSource("assets/sound/hit.mp3", "static")
    Enemigo.loadAssets()
end

function PlayState:exit() end

function PlayState:checkCollision(x1, y1, r1, x2, y2, r2)
    local distance = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
    return distance < (r1 + r2)
end

function PlayState:spawnEnemy()
    local ex, ey
    if math.random() > 0.5 then
        ex = math.random(0, 800)
        ey = math.random() > 0.5 and -20 or 620
    else
        ex = math.random() > 0.5 and -20 or 820
        ey = math.random(0, 600)
    end
    table.insert(self.enemies, Enemigo.new(ex, ey))
end

function PlayState:update(dt)
    self.timer = self.timer - dt
    
    -- Transiciones de estado dinámicas
    if self.timer <= 0 then 
        gStateMachine:change('gameover', {victoria = true}) 
    end
    
    if self.shakeTimer > 0 then self.shakeTimer = self.shakeTimer - dt end
    if math.random() < 0.03 then self:spawnEnemy() end

    self.jugador:update(dt)

    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        e:update(dt, self.jugador.x, self.jugador.y)

        if self:checkCollision(self.jugador.x, self.jugador.y, self.jugador.radius, e.x, e.y, e.radius) then
            self.jugador.hp = self.jugador.hp - 10
            self.shakeTimer = 0.2 
            self.hitSound:clone():play() -- Clonamos para evitar el bug de audio
            table.remove(self.enemies, i)
          
            if self.jugador.hp <= 0 then 
                gStateMachine:change('gameover', {victoria = false}) 
            end
        else
            for j = #self.jugador.bullets, 1, -1 do
                local b = self.jugador.bullets[j]
                if self:checkCollision(e.x, e.y, e.radius, b.x, b.y, b.radius) then
                    self.hitSound:clone():play() 
                    table.remove(self.enemies, i)
                    table.remove(self.jugador.bullets, j)
                    break
                end
            end
        end
    end
end

function PlayState:draw()
    love.graphics.push()
    if self.shakeTimer > 0 then
        local dx = love.math.random(-5, 5)
        local dy = love.math.random(-5, 5)
        love.graphics.translate(dx, dy)
        love.graphics.clear(0.3, 0, 0)
    else
        love.graphics.clear(0, 0, 0)
    end

    self.jugador:draw()
    for _, e in ipairs(self.enemies) do
        e:draw()
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Salud: " .. self.jugador.hp, 10, 10)
    love.graphics.print("Extracción en: " .. math.ceil(self.timer) .. "s", 10, 30)
    love.graphics.pop()
end

function PlayState:mousepressed(x, y, button)
    if button == 1 then
        self.jugador:shoot(x, y)
    end
end

return PlayState