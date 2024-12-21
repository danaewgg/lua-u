local ConnectionManager = {
    connections = {}
}

local function _Log(functionToCall, ...)
    functionToCall("ConnectionManager |", ...)
end

-- Check if a connection exists
function ConnectionManager.HasConnection(instance, event)
    return ConnectionManager.connections[instance] and (event and ConnectionManager.connections[instance][event] or true)
end

-- Get all connections for an instance
function ConnectionManager.GetInstanceConnections(instance)
    assert(not instance or typeof(instance) == "Instance", "First argument must be of type 'Instance' or 'nil'")

    if not ConnectionManager.HasConnection(instance) then return false end

    return ConnectionManager.connections[instance]
end

-- Connect to an event
function ConnectionManager.Connect(instance, event, callback)
    assert(typeof(instance) == "Instance", "First argument must be of type 'Instance'")
    assert(typeof(event) == "string", "Second argument must be of type 'string'")
    assert(typeof(instance[event].Connect) == "function", "Second argument must translate to type 'RBXScriptSignal'")
    assert(typeof(callback) == "function", "Third argument must be of type 'function'")

    if ConnectionManager.HasConnection(instance, event) then return false end -- Prevent duplicate connections (unsure of use cases)

    ConnectionManager.connections[instance] = ConnectionManager.connections[instance] or {} -- Initialize connections table if necessary
    ConnectionManager.connections[instance][event] = instance[event]:Connect(callback)

    -- Handle deletion of the instance
    instance.Destroying:Once(function()
        --_Log(warn, `Connections under '{instance:GetFullName()}' are being disconnected as a result of its deletion...`)
        ConnectionManager.DisconnectInstance(instance)
    end)

    return ConnectionManager.connections[instance][event]
end

-- Disconnect a specific connection
function ConnectionManager.Disconnect(instance, event)
    assert(typeof(instance) == "Instance", "First argument must be of type 'Instance'")
    assert(typeof(event) == "string", "Second argument must be of type 'string'")

    if not ConnectionManager.HasConnection(instance, event) then return false end

    ConnectionManager.connections[instance][event]:Disconnect()
    ConnectionManager.connections[instance][event] = nil

    -- Clean up instance dictionary if no events are left
    if next(ConnectionManager.connections[instance]) == nil then
        ConnectionManager.connections[instance] = nil
    end

    return true
end

-- Disconnect all connections for an instance
function ConnectionManager.DisconnectInstance(instance)
    assert(typeof(instance) == "Instance", "Argument must be of type 'Instance'")

    if not ConnectionManager.HasConnection(instance) then return false end

    for _, connection in ConnectionManager.connections[instance] do
        connection:Disconnect()
    end
    ConnectionManager.connections[instance] = nil

    return true
end

-- Disconnect all connections across all instances
function ConnectionManager.DisconnectAll()
    for instance, _ in ConnectionManager.connections do
        ConnectionManager.DisconnectInstance(instance)
    end

    return true
end

return ConnectionManager
