local PlayState = {}
PlayState.__index = PlayState

local Tilemap = require("Tilemap")
local Enemigo = require("enemigo")
local Jugador = require("jugador")
local Event = require("Event")
local UI = require("UI")

function PlayState.new()
    return setmetatable({}, PlayState)
end

function PlayState:enter(params)
    Event.clear()

    self.mapa = Tilemap.new(25, 19, 32)
    self.jugador = Jugador.new()
    self.timer = 30
    self.shakeTimer = 0
    self.enemies = {}
    self.particles = {}

    self.hitSound = love.audio.newSource("assets/sound/hit.mp3", "static")
    self.shootSound = love.audio.newSource("assets/sound/shoot.wav", "static")

    Enemigo.loadAssets()
    self.ui = UI.new(self.jugador.maxHp, self.timer)

    self:registerEvents()
end

function PlayState:registerEvents()
    Event.on("player_shoot", function(data)
        self.shootSound:stop()
        self.shootSound:play()
    end)

    Event.on("player_damaged", function(data)
        self.shakeTimer = 0.25
        self.hitSound:clone():play()
        self:spawnParticles(data.x, data.y, {1, 0.2, 0.2})
    end)

    Event.on("enemy_killed", function(data)
        self.hitSound:clone():play()
        self:spawnParticles(data.x, data.y, {1, 0.8, 0.2})
    end)

    Event.on("player_died", function()
        gStateMachine:change('gameover', {
            victoria = false,
            kills = self.ui.kills
        })
    end)

    Event.on("extraction_complete", function()
        gStateMachine:change('gameover', {
            victoria = true,
            kills = self.ui.kills
        })
    end)
end

function PlayState:exit()
    Event.clear()
end

function PlayState:spawnParticles(x, y, color)
    for _ = 1, 8 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(40, 140)
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.35,
            maxLife = 0.35,
            color = color
        })
    end
end

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
        ey = math.random(70, 600)
    end
    table.insert(self.enemies, Enemigo.new(ex, ey))
end

function PlayState:update(dt)
    self.timer = self.timer - dt
    Event.dispatch("timer_updated", { timeLeft = self.timer })

    if self.timer <= 0 then
        Event.dispatch("extraction_complete")
        return
    end

    if self.shakeTimer > 0 then self.shakeTimer = self.shakeTimer - dt end
    if math.random() < 0.03 then self:spawnEnemy() end

    self.jugador:update(dt, self.mapa)
    self.ui:update(dt)

    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end

    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        e:update(dt, self.jugador.x, self.jugador.y, self.mapa)

        if self:checkCollision(self.jugador.x, self.jugador.y, self.jugador.radius, e.x, e.y, e.radius) then
            table.remove(self.enemies, i)
            self.jugador:takeDamage(10)
            if self.jugador.hp <= 0 then return end
        else
            for j = #self.jugador.bullets, 1, -1 do
                local b = self.jugador.bullets[j]
                if self:checkCollision(e.x, e.y, e.radius, b.x, b.y, b.radius) then
                    local ex, ey = e.x, e.y
                    table.remove(self.enemies, i)
                    table.remove(self.jugador.bullets, j)
                    Event.dispatch("enemy_killed", { x = ex, y = ey })
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
    end

    love.graphics.clear(0.05, 0.08, 0.05)

    self.mapa:draw()
    self.jugador:draw()
    for _, e in ipairs(self.enemies) do
        e:draw()
    end

    for _, p in ipairs(self.particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, 3)
    end

    love.graphics.pop()

    self.ui:draw()
end

function PlayState:mousepressed(x, y, button)
    if button == 1 then
        self.jugador:shoot(x, y)
    end
end

return PlayState