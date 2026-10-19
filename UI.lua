local Event = require("Event")

local UI = {}
UI.__index = UI

function UI.new(maxHp, initialTime)
    local self = setmetatable({}, UI)
    self.hp = maxHp or 100
    self.maxHp = maxHp or 100
    self.displayedHp = self.hp
    self.timer = initialTime or 30
    self.kills = 0

    self.damageFlashAlpha = 0
    self.killPopScale = 1

    self:registerEvents()
    return self
end

function UI:registerEvents()
    Event.on("player_damaged", function(data)
        self.hp = math.max(0, data.currentHp)
        self.damageFlashAlpha = 0.6
    end)

    Event.on("enemy_killed", function()
        self.kills = self.kills + 1
        self.killPopScale = 1.5
    end)

    Event.on("timer_updated", function(data)
        self.timer = math.max(0, data.timeLeft)
    end)
end

function UI:update(dt)
    if self.displayedHp > self.hp then
        self.displayedHp = math.max(self.hp, self.displayedHp - 60 * dt)
    end

    if self.damageFlashAlpha > 0 then
        self.damageFlashAlpha = math.max(0, self.damageFlashAlpha - 1.5 * dt)
    end

    if self.killPopScale > 1 then
        self.killPopScale = math.max(1, self.killPopScale - 2.5 * dt)
    end
end

function UI:draw()
    -- Destello rojo en los bordes de pantalla al recibir daño
    if self.damageFlashAlpha > 0 then
        love.graphics.setColor(0.9, 0.1, 0.1, self.damageFlashAlpha)
        love.graphics.setLineWidth(12)
        love.graphics.rectangle("line", 0, 0, 800, 600)
        love.graphics.setLineWidth(1)
    end

    -- Panel superior del HUD
    love.graphics.setColor(0.08, 0.08, 0.12, 0.85)
    love.graphics.rectangle("fill", 10, 10, 780, 50, 8, 8)
    love.graphics.setColor(0.3, 0.35, 0.45, 1)
    love.graphics.rectangle("line", 10, 10, 780, 50, 8, 8)

    -- Barra de Salud 
    local barX, barY, barW, barH = 25, 22, 220, 26
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 4, 4)

    local delayedRatio = self.displayedHp / self.maxHp
    love.graphics.setColor(0.9, 0.8, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barW * delayedRatio, barH, 4, 4)

    local hpRatio = self.hp / self.maxHp
    if hpRatio > 0.5 then
        love.graphics.setColor(0.2, 0.8, 0.3, 1)
    elseif hpRatio > 0.25 then
        love.graphics.setColor(0.95, 0.6, 0.1, 1)
    else
        love.graphics.setColor(0.9, 0.15, 0.15, 1)
    end
    love.graphics.rectangle("fill", barX, barY, barW * hpRatio, barH, 4, 4)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", barX, barY, barW, barH, 4, 4)
    love.graphics.print("SALUD: " .. self.hp .. " / " .. self.maxHp, barX + 10, barY + 5)

    -- Temporizador de Extracción 
    local secondsLeft = math.ceil(self.timer)
    if secondsLeft <= 5 then
        local pulse = math.abs(math.sin(love.timer.getTime() * 8))
        love.graphics.setColor(1, pulse * 0.4, pulse * 0.4, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.print("EXTRACCIÓN EN: " .. secondsLeft .. "s", 340, 27)

    -- Contador de Bajas con animación 
    love.graphics.push()
    love.graphics.translate(650, 35)
    love.graphics.scale(self.killPopScale, self.killPopScale)
    love.graphics.setColor(1, 0.85, 0.2, 1)
    love.graphics.print("BAJAS: " .. self.kills, -40, -7)
    love.graphics.pop()

    love.graphics.setColor(1, 1, 1, 1)
end

return UI