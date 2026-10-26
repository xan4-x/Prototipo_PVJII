local PlayState = {}
PlayState.__index = PlayState

local Tilemap = require("Tilemap")
local Enemigo = require("enemigo")
local Jugador = require("jugador")
local Event = require("Event")
local UI = require("UI")
local CoroutineManager = require("CoroutineManager")

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

    -- Zona de extracción controlada por corrutina
    self.extractionZone = { active = false, x = 400, y = 300, radius = 42 }
    self.isSequenceClosing = false

    self.hitSound = love.audio.newSource("assets/sound/hit.mp3", "static")
    self.shootSound = love.audio.newSource("assets/sound/shoot.wav", "static")

    Enemigo.loadAssets()
    self.ui = UI.new(self.jugador.maxHp, self.timer)
    self.coroutines = CoroutineManager.new()

    self:registerEvents()

    -- Iniciamos la corrutina principal que dirige las oleadas y la extracción
    self.coroutines:start(function()
        self:missionDirectorRoutine()
    end)
end

-- Corrutina maestra: coordina secuencias de eventos y esperas durante toda la partida
function PlayState:missionDirectorRoutine()
    Event.dispatch("wave_announcement", {
        text = "PREPARATE: LA HORDA SE ACERCA...",
        color = {1, 0.9, 0.3},
        duration = 2.0
    })
    CoroutineManager.wait(2.0)

    -- Oleada 1: Enemigos estándar espaciados
    Event.dispatch("wave_announcement", {
        text = "¡OLEADA 1 INICIADA!",
        color = {1, 0.7, 0.2},
        duration = 2.0
    })
    for _ = 1, 8 do
        self:spawnEnemy(1.0)
        CoroutineManager.wait(1.1)
    end

    CoroutineManager.wait(1.5)

    -- Oleada 2: Mayor frecuencia y velocidad
    Event.dispatch("wave_announcement", {
        text = "¡OLEADA 2: MÁS RÁPIDOS!",
        color = {1, 0.45, 0.2},
        duration = 2.2
    })
    for _ = 1, 12 do
        self:spawnEnemy(1.15)
        CoroutineManager.wait(0.8)
    end

    CoroutineManager.wait(1.2)

    -- Oleada 3: Asalto final hasta que el reloj llegue a cero
    Event.dispatch("wave_announcement", {
        text = "¡ALERTA: HORDA FINAL!",
        color = {1, 0.2, 0.2},
        duration = 2.5
    })
    while self.timer > 0 do
        self:spawnEnemy(1.25)
        CoroutineManager.wait(0.65)
    end

    -- Cuando el tiempo llega a 0, se habilita la zona de extracción en el centro
    self.extractionZone.active = true
    Event.dispatch("wave_announcement", {
        text = "¡DIRIGITE AL PUNTO VERDE CENTRAL PARA EXTRAER!",
        color = {0.2, 1, 0.4},
        duration = 4.0
    })

    -- Sigue generando presión moderada mientras el jugador corre hacia la extracción
    while not self.isSequenceClosing do
        self:spawnEnemy(1.1)
        CoroutineManager.wait(1.2)
    end
end

-- Corrutina para la secuencia de victoria al pisar la zona de extracción
function PlayState:extractionWinRoutine()
    self.isSequenceClosing = true
    self.enemies = {} -- Limpiamos los enemigos cercanos al asegurar la zona
    self:spawnParticles(self.jugador.x, self.jugador.y, {0.2, 1, 0.4})

    Event.dispatch("wave_announcement", {
        text = "¡ZONA ASEGURADA! EVACUANDO...",
        color = {0.2, 1, 0.4},
        duration = 1.5
    })
    CoroutineManager.wait(1.4)

    gStateMachine:change('gameover', {
        victoria = true,
        kills = self.ui.kills
    })
end

-- Corrutina para la secuencia dramática de derrota
function PlayState:playerDeathRoutine()
    self.isSequenceClosing = true
    self.shakeTimer = 0.6
    self:spawnParticles(self.jugador.x, self.jugador.y, {1, 0.15, 0.15})

    Event.dispatch("wave_announcement", {
        text = "¡SEÑAL PERDIDA! CAÍSTE EN COMBATE...",
        color = {1, 0.2, 0.2},
        duration = 1.5
    })
    CoroutineManager.wait(1.3)

    gStateMachine:change('gameover', {
        victoria = false,
        kills = self.ui.kills
    })
end

function PlayState:registerEvents()
    Event.on("player_shoot", function()
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
        if not self.isSequenceClosing then
            self.coroutines:start(function()
                self:playerDeathRoutine()
            end)
        end
    end)
end

function PlayState:exit()
    self.coroutines:clear()
    Event.clear()
end

function PlayState:spawnParticles(x, y, color)
    for _ = 1, 10 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(40, 150)
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.4,
            maxLife = 0.4,
            color = color
        })
    end
end

function PlayState:checkCollision(x1, y1, r1, x2, y2, r2)
    local distance = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
    return distance < (r1 + r2)
end

function PlayState:spawnEnemy(speedMultiplier)
    local ex, ey
    if math.random() > 0.5 then
        ex = math.random(0, 800)
        ey = math.random() > 0.5 and -20 or 620
    else
        ex = math.random() > 0.5 and -20 or 820
        ey = math.random(70, 600)
    end
    table.insert(self.enemies, Enemigo.new(ex, ey, speedMultiplier))
end

function PlayState:update(dt)
    self.coroutines:update(dt)
    self.ui:update(dt)

    if self.shakeTimer > 0 then self.shakeTimer = self.shakeTimer - dt end

    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end

    -- Si estamos en la cinemática final de victoria o derrota, congelamos el combate
    if self.isSequenceClosing then return end

    if self.timer > 0 then
        self.timer = math.max(0, self.timer - dt)
        Event.dispatch("timer_updated", { timeLeft = self.timer })
    end

    self.jugador:update(dt, self.mapa)

    -- Verificar si el jugador llegó a la zona de extracción activa
    if self.extractionZone.active then
        if self:checkCollision(
            self.jugador.x, self.jugador.y, self.jugador.radius,
            self.extractionZone.x, self.extractionZone.y, self.extractionZone.radius
        ) then
            self.coroutines:start(function()
                self:extractionWinRoutine()
            end)
            return
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

    -- Dibujar zona de extracción cuando la corrutina la activa
    if self.extractionZone.active then
        local pulse = math.abs(math.sin(love.timer.getTime() * 5))
        love.graphics.setColor(0.1, 0.9, 0.3, 0.25 + pulse * 0.2)
        love.graphics.circle("fill", self.extractionZone.x, self.extractionZone.y, self.extractionZone.radius)
        love.graphics.setColor(0.2, 1, 0.4, 0.9)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", self.extractionZone.x, self.extractionZone.y, self.extractionZone.radius)
        love.graphics.setLineWidth(1)
    end

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
    if button == 1 and not self.isSequenceClosing then
        self.jugador:shoot(x, y)
    end
end

return PlayState