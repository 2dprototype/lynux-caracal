-- src/core/event_bus.lua
local EventBus = {}
local listeners = {}

function EventBus.on(event, callback, key)
    if not listeners[event] then
        listeners[event] = {}
    end
    table.insert(listeners[event], { callback = callback, key = key })
    return function()
        EventBus.off(event, callback)
    end
end

function EventBus.off(event, callbackOrKey)
    if not listeners[event] then return end
    for i = #listeners[event], 1, -1 do
        local item = listeners[event][i]
        if item.callback == callbackOrKey or item.key == callbackOrKey then
            table.remove(listeners[event], i)
        end
    end
end

function EventBus.emit(event, ...)
    if not listeners[event] then return end
    for _, item in ipairs(listeners[event]) do
        local ok, err = pcall(item.callback, ...)
        if not ok then
            print("[EventBus Error] in event '" .. tostring(event) .. "': " .. tostring(err))
        end
    end
end

function EventBus.clear()
    listeners = {}
end

return EventBus
