local Event = {}
local listeners = {}

-- Suscribe una función a un evento específico
function Event.on(eventName, callback)
    if not listeners[eventName] then
        listeners[eventName] = {}
    end
    table.insert(listeners[eventName], callback)
end

-- Dispara un evento y envía datos opcionales a todos los suscriptores
function Event.dispatch(eventName, data)
    if listeners[eventName] then
        for _, callback in ipairs(listeners[eventName]) do
            callback(data)
        end
    end
end

-- Limpia todos los eventos registrados al cambiar de escena
function Event.clear()
    listeners = {}
end

return Event