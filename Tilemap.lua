local Tilemap = {}
Tilemap.__index = Tilemap

function Tilemap.new(columns, rows, tileSize)
    local self = setmetatable({}, Tilemap)
    self.columns = columns
    self.rows = rows
    self.tileSize = tileSize
    self.grid = {}

    -- Generación Procedural
    for y = 1, self.rows do
        self.grid[y] = {}
        for x = 1, self.columns do
            if math.random() < 0.10 then
                self.grid[y][x] = 1 -- 10% de probabilidad de generar una roca/obstáculo
            else
                self.grid[y][x] = 0 -- Suelo normal
            end
        end
    end
    
    -- Área segura en el centro para el jugador
    self.grid[math.floor(rows/2)][math.floor(columns/2)] = 0
    return self
end

function Tilemap:draw()
    for y = 1, self.rows do
        for x = 1, self.columns do
            local px = (x - 1) * self.tileSize
            local py = (y - 1) * self.tileSize
            
            if self.grid[y][x] == 1 then
                love.graphics.setColor(0.4, 0.4, 0.4) -- Roca
                love.graphics.rectangle("fill", px, py, self.tileSize, self.tileSize)
            else
                love.graphics.setColor(0.1, 0.2, 0.1) -- Pasto
                love.graphics.rectangle("line", px, py, self.tileSize, self.tileSize)
            end
        end
    end
end

-- Convierte pixeles a coordenadas de la grilla para saber si hay un obstáculo
function Tilemap:isSolid(x, y)
    local gridX = math.floor(x / self.tileSize) + 1
    local gridY = math.floor(y / self.tileSize) + 1

    -- Previene errores si la posición está fuera de los límites de la pantalla
    if gridY < 1 or gridY > self.rows or gridX < 1 or gridX > self.columns then
        return false
    end

    return self.grid[gridY][gridX] == 1
end

-- Comprueba las 4 esquinas de la hitbox de un personaje
function Tilemap:collides(x, y, radius)
    return self:isSolid(x - radius, y - radius) or
           self:isSolid(x + radius, y - radius) or
           self:isSolid(x - radius, y + radius) or
           self:isSolid(x + radius, y + radius)
end

return Tilemap