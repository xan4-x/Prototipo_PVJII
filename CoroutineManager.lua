local CoroutineManager = {}
CoroutineManager.__index = CoroutineManager

function CoroutineManager.new()
    local self = setmetatable({}, CoroutineManager)
    self.routines = {}
    return self
end

-- Inicia y registra una nueva corrutina pasando una función
function CoroutineManager:start(func)
    local co = coroutine.create(func)
    table.insert(self.routines, { co = co, waitTimer = 0 })
    return co
end

-- Pausa la corrutina actual durante 'seconds' segundos
function CoroutineManager.wait(seconds)
    coroutine.yield(seconds or 0)
end

-- Actualiza todas las corrutinas activas en cada frame
function CoroutineManager:update(dt)
    for i = #self.routines, 1, -1 do
        local r = self.routines[i]
        if coroutine.status(r.co) == "dead" then
            table.remove(self.routines, i)
        else
            if r.waitTimer > 0 then
                r.waitTimer = r.waitTimer - dt
            end
            if r.waitTimer <= 0 then
                local ok, yieldedWait = coroutine.resume(r.co, dt)
                if not ok then
                    print("Error en corrutina: " .. tostring(yieldedWait))
                    table.remove(self.routines, i)
                elseif type(yieldedWait) == "number" then
                    r.waitTimer = yieldedWait
                end
            end
        end
    end
end

function CoroutineManager:clear()
    self.routines = {}
end

return CoroutineManager