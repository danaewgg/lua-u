local ConnectionManager = {
    connections = {}
}

-- Resolve whether it's a property change signal or normal event
local function _ResolveEventSignal(instance, eventOrProperty)
    -- Try to fetch the PropertyChangedSignal if it exists
    local pcallResult, errorOrEvent = pcall(instance.GetPropertyChangedSignal, instance, eventOrProperty) 

    if not pcallResult then
        -- If it's not a PropertyChangedSignal, check if it's a normal event
        assert(typeof(instance[eventOrProperty].Connect) == "function", "2nd argument (eventOrProperty) must translate to type 'RBXScriptSignal'")

        return instance[eventOrProperty] -- Normal event
    end
    return errorOrEvent -- PropertyChangedSignal (successfully fetched)
end

-- Check if a connection exists
function ConnectionManager.hasconnection(instance, event)
    return ConnectionManager.connections[instance] and (event and ConnectionManager.connections[instance][event] or true)
end

-- Get all connections for an instance
function ConnectionManager.getinstanceconnections(instance)
    assert(not instance or typeof(instance) == "Instance", "Passed argument must be of type 'Instance' or 'nil'")

    if not ConnectionManager.HasConnection(instance) then return false end

    return ConnectionManager.connections[instance]
end

-- Connect to an event
function ConnectionManager.connect(instance, eventOrProperty, callback)
    assert(typeof(instance) == "Instance", "1st argument (instance) must be of type 'Instance'")
    assert(typeof(eventOrProperty) == "string", "2nd argument (eventOrProperty) must be of type 'string'")
    assert(typeof(callback) == "function", "3rd argument (callback) must be of type 'function'")

    eventOrProperty = _ResolveEventSignal(instance, eventOrProperty)

    if ConnectionManager.HasConnection(instance, tostring(eventOrProperty)) then return false end -- Prevent duplicate connections (if needed...?)

    ConnectionManager.connections[instance] = ConnectionManager.connections[instance] or {} -- Initialize connections table if necessary
    ConnectionManager.connections[instance][tostring(eventOrProperty)] = eventOrProperty:Connect(callback)

    -- Handle deletion of the instance
    instance.Destroying:Once(function()
        --warn(`Connections under '{instance:GetFullName()}' are being disconnected as a result of its deletion...`)
        ConnectionManager.DisconnectInstance(instance)
    end)

    return ConnectionManager.connections[instance][tostring(eventOrProperty)]
end

-- Disconnect a specific event
function ConnectionManager.disconnect(instance, eventOrProperty)
    assert(typeof(instance) == "Instance", "1st argument (instance) must be of type 'Instance'")
    assert(typeof(eventOrProperty) == "string", "2nd argument (eventOrProperty) must be of type 'string'")

    eventOrProperty = tostring(_ResolveEventSignal(instance, eventOrProperty))

    if not ConnectionManager.HasConnection(instance, eventOrProperty) then return false end

    ConnectionManager.connections[instance][eventOrProperty]:Disconnect()
    ConnectionManager.connections[instance][eventOrProperty] = nil

    -- Clean up instance dictionary if no events are left
    if next(ConnectionManager.connections[instance]) == nil then
        ConnectionManager.connections[instance] = nil
    end

    return true
end

-- Disconnect all connections for an instance
function ConnectionManager.disconnectinstance(instance)
    assert(typeof(instance) == "Instance", "Passed argument must be of type 'Instance'")

    if not ConnectionManager.HasConnection(instance) then return false end

    for _, connection in ConnectionManager.connections[instance] do
        connection:Disconnect()
    end
    ConnectionManager.connections[instance] = nil

    return true
end

-- Disconnect all connections across all instances
function ConnectionManager.disconnectall()
    for instance, _ in ConnectionManager.connections do
        ConnectionManager.DisconnectInstance(instance)
    end

    return true
end

-- Make module functions case-insensitive
return setmetatable(ConnectionManager, {
    __index = function(_, index)
        return rawget(ConnectionManager, index:lower())
    end
})